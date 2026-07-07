#!/usr/bin/env node
/**
 * One-off script to create a barber login account. There is no public
 * sign-up screen in the app by design - accounts are provisioned by
 * whoever manages the shop, using this script.
 *
 * Usage:
 *   node scripts/createBarber.js "+998901234567" "StrongPassword123" "Aziz" [role]
 *
 * Requires Google Application Default Credentials for the target Firebase
 * project. Either:
 *   - drop a service account key at functions/serviceAccountKey.json
 *     (Firebase console > Project settings > Service accounts > Generate
 *     new private key) - picked up automatically below, or
 *   - run `gcloud auth application-default login` once, or
 *   - set GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json yourself.
 *
 * Run from the functions/ directory after `npm install`.
 */
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');
const crypto = require('crypto');

const [, , phoneNumber, password, name, role] = process.argv;

if (!phoneNumber || !password || !name) {
  console.error('Usage: node scripts/createBarber.js <phoneNumber e.g. +998901234567> <password> <name> [role]');
  process.exit(1);
}

if (!/^\+998\d{9}$/.test(phoneNumber)) {
  console.error('Phone number must be in +998XXXXXXXXX format.');
  process.exit(1);
}

if (password.length < 6) {
  console.error('Password must be at least 6 characters.');
  process.exit(1);
}

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
if (fs.existsSync(serviceAccountPath)) {
  admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
} else {
  // Falls back to Application Default Credentials (gcloud login or
  // GOOGLE_APPLICATION_CREDENTIALS env var).
  admin.initializeApp();
}

function hashPassword(plainPassword, salt) {
  return crypto.scryptSync(plainPassword, salt, 64).toString('hex');
}

async function main() {
  const db = admin.firestore();

  const existing = await db.collection('users').where('phoneNumber', '==', phoneNumber).limit(1).get();
  if (!existing.empty) {
    console.error(`A user with phone number ${phoneNumber} already exists (uid: ${existing.docs[0].id}).`);
    process.exit(1);
  }

  const salt = crypto.randomBytes(16).toString('hex');
  const passwordHash = hashPassword(password, salt);

  // Creates a bare Firebase Auth user purely to get a stable uid to key
  // the Firestore profile on; the app never uses this record's email/phone
  // fields, only the uid, via signInWithCustomToken.
  const userRecord = await admin.auth().createUser({ displayName: name });

  await db.collection('users').doc(userRecord.uid).set({
    phoneNumber,
    passwordHash,
    passwordSalt: salt,
    name,
    role: role || 'barber',
    active: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Created barber account for "${name}" (${phoneNumber}) with uid ${userRecord.uid}.`);
  process.exit(0);
}

main().catch((error) => {
  console.error('Failed to create barber account:', error);
  process.exit(1);
});
