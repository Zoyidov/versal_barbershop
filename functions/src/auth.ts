import { randomBytes, scryptSync, timingSafeEqual } from 'crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { REGION } from './config';
import type { UserDoc } from './types';

const db = getFirestore();

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
  };
});
