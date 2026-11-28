import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {db} from './firebase_app.js';

export function validResourceId(value: string): boolean {
  return value.length > 0 && value.length <= 128 && !value.includes('/');
}

export interface OwnershipTransferContext {
  requesterUid: string;
  targetUid: string;
  currentOwnerUid: string | null;
  targetExists: boolean;
  targetRole: string | null;
}

export function findOwnershipTransferViolation(
  context: OwnershipTransferContext,
): string | null {
  if (!context.requesterUid) return 'unauthenticated';
  if (context.currentOwnerUid !== context.requesterUid) return 'not_owner';
  if (!context.targetUid || context.targetUid === context.requesterUid) {
    return 'invalid_target';
  }
  if (!context.targetExists) return 'target_not_member';
  if (context.targetRole !== 'member') return 'invalid_target_role';
  return null;
}

/**
 * Transfers household ownership using privileged writes in one transaction.
 * Clients cannot update ownerUid or member roles directly under Firestore rules.
 */
export const transferHouseholdOwnership = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Entre na sua conta para transferir a casa.');
  }

  const data = request.data as {householdId?: unknown; targetUid?: unknown} | null;
  const householdId =
    typeof data?.householdId === 'string' ? data.householdId.trim() : '';
  const targetUid = typeof data?.targetUid === 'string' ? data.targetUid.trim() : '';
  if (!validResourceId(householdId) || !validResourceId(targetUid)) {
    throw new HttpsError('invalid-argument', 'Informe a casa e o novo owner.');
  }

  await db.runTransaction(async (transaction) => {
    const householdRef = db.doc(`households/${householdId}`);
    const currentOwnerRef = db.doc(
      `households/${householdId}/members/${request.auth!.uid}`,
    );
    const targetRef = db.doc(`households/${householdId}/members/${targetUid}`);
    const [household, currentOwner, target] = await Promise.all([
      transaction.get(householdRef),
      transaction.get(currentOwnerRef),
      transaction.get(targetRef),
    ]);

    const violation = findOwnershipTransferViolation({
      requesterUid: request.auth!.uid,
      targetUid,
      currentOwnerUid: household.exists
        ? (household.get('ownerUid') as string | undefined) ?? null
        : null,
      targetExists: target.exists,
      targetRole: target.exists
        ? (target.get('role') as string | undefined) ?? null
        : null,
    });
    if (violation) {
      const messages: Record<string, string> = {
        not_owner: 'Somente o owner atual pode transferir a casa.',
        invalid_target: 'Escolha um membro diferente como novo owner.',
        target_not_member: 'O novo owner precisa pertencer à casa.',
        invalid_target_role: 'O novo owner precisa ser um membro da casa.',
        unauthenticated: 'Entre na sua conta para transferir a casa.',
      };
      const message = messages[violation] ?? 'Transferência de propriedade inválida.';
      throw new HttpsError(
        violation === 'not_owner' ? 'permission-denied' : 'invalid-argument',
        message,
      );
    }

    if (!household.exists || !currentOwner.exists) {
      throw new HttpsError('failed-precondition', 'A casa não existe mais.');
    }

    transaction.update(householdRef, {ownerUid: targetUid});
    transaction.update(currentOwnerRef, {role: 'member'});
    transaction.update(targetRef, {role: 'owner'});
  });

  return {status: 'transferred', householdId, ownerUid: targetUid};
});
