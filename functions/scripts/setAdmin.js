#!/usr/bin/env node
/**
 * One-off migration: promotes the single pre-existing login account to
 * admin, so it can approve new self-registrations and manage SMS limits
 * from the in-app user-management screen.
 *
 * Usage:
 *   node scripts/setAdmin.js "+998993697002"
 *
 * Requires the same credentials as scripts/createBarber.js (see that file's
 * header comment) - a service account key at functions/serviceAccountKey.json,
 * or `gcloud auth application-default login`, or GOOGLE_APPLICATION_CREDENTIALS.
 *
 * Run from the functions/ directory after `npm install`.
 */
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');

const [, , phoneNumber] = process.argv;

if (!phoneNumber) {
  console.error('Usage: node scripts/setAdmin.js <phoneNumber e.g. +998993697002>');
  process.exit(1);
}

const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
if (fs.existsSync(serviceAccountPath)) {
  admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
} else {
  admin.initializeApp();
}

async function main() {
  const db = admin.firestore();

  const snapshot = await db.collection('users').where('phoneNumber', '==', phoneNumber).limit(1).get();
  if (snapshot.empty) {
    console.error(`No user found with phone number ${phoneNumber}.`);
    process.exit(1);
  }

  const doc = snapshot.docs[0];
  await doc.ref.update({
    role: 'admin',
    approved: true,
    active: true,
  });

  console.log(`Promoted uid ${doc.id} (${phoneNumber}) to admin.`);
  process.exit(0);
}

main().catch((error) => {
  console.error('Failed to promote account to admin:', error);
  process.exit(1);
});
