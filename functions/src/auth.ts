import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import { sendPushToAdmins, sendPushToUser } from './notifications';
import type { UserDoc } from './types';

const db = getFirestore();

const PHONE_PATTERN = /^\+998\d{9}$/;

/**
 * scrypt is Node's built-in, no-extra-dependency password hash - deliberately
 * used instead of a plain hash so a leaked `users` collection can't be
 * brute-forced with a rainbow table. Exported so `scripts/createBarber.js`
 * hashes new passwords identically to how login verifies them.
 */
export function hashPassword(password: string, salt: string): string {
  return scryptSync(password, salt, 64).toString('hex');
}

export function generateSalt(): string {
  return randomBytes(16).toString('hex');
}

function verifyPassword(password: string, salt: string, expectedHash: string): boolean {
  const actual = Buffer.from(hashPassword(password, salt), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  if (actual.length !== expected.length) return false;
  return timingSafeEqual(actual, expected);
}

/**
 * Verifies phone+password against `users/{uid}` (password is never sent to
 * or checked by the client) and, on success, mints a Firebase custom token.
 * The Flutter app exchanges that token via `signInWithCustomToken`, which
 * is what gives `request.auth` a real value in Firestore security rules -
 * this app never uses Firebase Auth's own phone/OTP sign-in flow.
 */
export const loginWithPhonePassword = onCall({ region: REGION }, async (request) => {
  const phoneNumber = String(request.data?.phoneNumber ?? '').trim();
  const password = String(request.data?.password ?? '');

  if (!phoneNumber || !password) {
    throw new HttpsError('invalid-argument', 'Phone number and password are required.');
  }

  const snapshot = await db.collection('users').where('phoneNumber', '==', phoneNumber).limit(1).get();
  if (snapshot.empty) {
    throw new HttpsError('not-found', 'Invalid phone number or password.');
  }

  const doc = snapshot.docs[0];
  const user = doc.data() as UserDoc;

  if (!user.active) {
    throw new HttpsError('permission-denied', 'This account has been disabled.');
  }

  if (!verifyPassword(password, user.passwordSalt, user.passwordHash)) {
    throw new HttpsError('unauthenticated', 'Invalid phone number or password.');
  }

  const token = await getAuth().createCustomToken(doc.id, { role: user.role });

  return {
    token,
    phoneNumber: user.phoneNumber,
    name: user.name,
    role: user.role,
    // Accounts created before this field existed (the original login-only
    // accounts) are grandfathered in as already approved, so this change
    // never locks out anyone who could already log in.
    approved: user.approved ?? true,
    smsLimit: user.smsLimit ?? 0,
  };
});

/**
 * Public sign-up: anyone can call this to create a barber account, but the
 * account starts `approved: false` and can't do anything gated on that flag
 * until an admin approves it (see `approveBarber`). `active` starts `true`
 * so `loginWithPhonePassword` still lets the account sign in immediately -
 * the client routes it to a "pending approval" screen based on `approved`.
 */
export const registerBarber = onCall({ region: REGION }, async (request) => {
  const phoneNumber = String(request.data?.phoneNumber ?? '').trim();
  const password = String(request.data?.password ?? '');
  const name = String(request.data?.name ?? '').trim();

  if (!phoneNumber || !password || !name) {
    throw new HttpsError('invalid-argument', 'Phone number, password and name are required.');
  }
  if (!PHONE_PATTERN.test(phoneNumber)) {
    throw new HttpsError('invalid-argument', 'Phone number must be in +998XXXXXXXXX format.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }

  const existing = await db.collection('users').where('phoneNumber', '==', phoneNumber).limit(1).get();
  if (!existing.empty) {
    throw new HttpsError('already-exists', 'This phone number is already registered.');
  }

  const salt = generateSalt();
  const passwordHash = hashPassword(password, salt);

  const userRecord = await getAuth().createUser({ displayName: name });

  const newUser: UserDoc = {
    phoneNumber,
    passwordHash,
    passwordSalt: salt,
    name,
    role: 'barber',
    active: true,
    approved: false,
    smsLimit: 0,
  };
  await db
    .collection('users')
    .doc(userRecord.uid)
    .set({ ...newUser, createdAt: FieldValue.serverTimestamp() });

  const token = await getAuth().createCustomToken(userRecord.uid, { role: newUser.role });

  await sendPushToAdmins({
    title: 'Yangi ro\'yxatdan o\'tish',
    body: `${name} tasdiqlashni kutmoqda`,
    data: { type: 'registration', uid: userRecord.uid },
  });

  return {
    token,
    phoneNumber: newUser.phoneNumber,
    name: newUser.name,
    role: newUser.role,
    approved: newUser.approved,
    smsLimit: newUser.smsLimit,
  };
});

/** Loads the caller's own `users/{uid}` doc and throws unless `role === 'admin'`. */
export async function requireAdmin(request: CallableRequest): Promise<void> {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const callerDoc = await db.collection('users').doc(request.auth.uid).get();
  const caller = callerDoc.data() as UserDoc | undefined;
  if (!caller || caller.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
}

/** Admin-only: approves a pending registration and sets its initial SMS credit. */
export const approveBarber = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);

  const uid = String(request.data?.uid ?? '').trim();
  const smsLimit = Number(request.data?.smsLimit ?? 0);
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  if (!Number.isFinite(smsLimit) || smsLimit < 0) {
    throw new HttpsError('invalid-argument', 'smsLimit must be a non-negative number.');
  }

  await db.collection('users').doc(uid).update({
    approved: true,
    active: true,
    smsLimit,
  });

  await sendPushToUser(uid, {
    title: 'Tasdiqlandingiz!',
    body: `Ro'yxatdan o'tishingiz tasdiqlandi. SMS limitingiz: ${smsLimit}`,
    data: { type: 'approved' },
  });

  return { success: true };
});

/** Admin-only: tops up (or reduces) a barber's remaining SMS credit. */
export const setSmsLimit = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);

  const uid = String(request.data?.uid ?? '').trim();
  const smsLimit = Number(request.data?.smsLimit ?? NaN);
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  if (!Number.isFinite(smsLimit) || smsLimit < 0) {
    throw new HttpsError('invalid-argument', 'smsLimit must be a non-negative number.');
  }

  await db.collection('users').doc(uid).update({ smsLimit });

  await sendPushToUser(uid, {
    title: 'SMS limiti yangilandi',
    body: `Yangi SMS limitingiz: ${smsLimit}`,
    data: { type: 'smsLimit' },
  });

  return { success: true };
});

/** Admin-only: enables/disables a barber account (e.g. to reject a registration). */
export const setUserActive = onCall({ region: REGION }, async (request) => {
  await requireAdmin(request);

  const uid = String(request.data?.uid ?? '').trim();
  const active = Boolean(request.data?.active);
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  await db.collection('users').doc(uid).update({ active });

  return { success: true };
});
