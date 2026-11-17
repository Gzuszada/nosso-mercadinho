import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {HttpsError} from 'firebase-functions/v2/https';
import {beforeUserCreated} from 'firebase-functions/v2/identity';

import {
  REGISTRATION_ALLOWLIST_DOCUMENT,
  isEmailAllowed,
  parseEmailHashes,
} from './allowlist.js';

initializeApp();

const db = getFirestore();

async function loadAllowedEmailHashes(): Promise<Set<string>> {
  const snapshot = await db.doc(REGISTRATION_ALLOWLIST_DOCUMENT).get();
  if (!snapshot.exists) {
    return new Set<string>();
  }
  return parseEmailHashes(snapshot.get('emailHashes'));
}

/**
 * Identity Platform blocking function. It runs before an account is created
 * and rejects every e-mail that is not present in the private allowlist.
 */
export const beforeCreateUser = beforeUserCreated(async (event) => {
  const email = event.data?.email;
  if (typeof email !== 'string' || email.trim() === '') {
    throw new HttpsError(
      'invalid-argument',
      'A conta exige um e-mail válido.',
    );
  }

  const allowedHashes = await loadAllowedEmailHashes();
  if (!isEmailAllowed(email, allowedHashes)) {
    throw new HttpsError(
      'permission-denied',
      'Este e-mail não está autorizado a criar uma conta.',
    );
  }

  // Libera a criação sem modificar os dados fornecidos pelo usuário.
});
