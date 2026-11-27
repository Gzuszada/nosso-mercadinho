import {FieldValue} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {db} from './firebase_app.js';

const REVIEW_ACTIONS = new Set(['approve', 'reject', 'remove', 'restore']);

/** Reason why an owner decision cannot be recorded. */
export type ModerationViolationReason =
  | 'not_owner'
  | 'item_not_found'
  | 'item_without_author'
  | 'own_item';

export interface ModerationContext {
  /** Owner confirmed by `households/{householdId}.ownerUid`. */
  householdOwnerUid: string | null;
  /** Authenticated caller. */
  requesterUid: string;
  /** Published row of the item, or null when it is not published. */
  publishedItem: Record<string, unknown> | null;
}

/** The owner of the household is the only one allowed to decide. */
export function isHouseholdOwner(
  householdOwnerUid: string | null,
  requesterUid: string,
): boolean {
  return householdOwnerUid !== null && householdOwnerUid === requesterUid;
}

/**
 * Decides whether the owner may record a decision about a published item.
 *
 * The owner decides about the items of the other members, so an item written
 * by the owner itself is rejected: there is nothing to moderate. The check is
 * pure so the hierarchy can be covered by tests without a Firestore emulator.
 */
export function findModerationViolation(
  context: ModerationContext,
): ModerationViolationReason | null {
  if (!isHouseholdOwner(context.householdOwnerUid, context.requesterUid)) {
    return 'not_owner';
  }
  if (context.publishedItem === null) {
    return 'item_not_found';
  }
  const authorUid = context.publishedItem.authorUid;
  if (typeof authorUid !== 'string' || authorUid.length === 0) {
    return 'item_without_author';
  }
  if (authorUid === context.requesterUid) {
    return 'own_item';
  }
  return null;
}

function object(value: unknown, name: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `${name} inválido.`);
  }
  return value as Record<string, unknown>;
}

function string(value: unknown, name: string): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw new HttpsError('invalid-argument', `${name} inválido.`);
  }
  return value;
}

async function householdOwnerUid(householdId: string): Promise<string | null> {
  const household = await db.doc(`households/${householdId}`).get();
  const ownerUid = household.get('ownerUid');
  return typeof ownerUid === 'string' && ownerUid.length > 0 ? ownerUid : null;
}

async function publishedPlannedItems(
  householdId: string,
): Promise<Array<Record<string, unknown>>> {
  const state = await db.doc(`syncV2/${householdId}/state/current`).get();
  if (!state.exists) {
    throw new HttpsError(
      'failed-precondition',
      'A casa ainda não possui uma publicação oficial.',
    );
  }
  const manifest = object(state.get('manifest'), 'manifesto');
  const areas = object(manifest.areas, 'áreas');
  const shopping = object(areas.shopping, 'área de listas');
  const chunks = shopping.chunks;
  if (!Array.isArray(chunks)) {
    throw new HttpsError('data-loss', 'A publicação oficial está incompleta.');
  }

  const rows: Array<Record<string, unknown>> = [];
  for (const rawChunk of chunks) {
    const descriptor = object(rawChunk, 'chunk');
    const path = string(descriptor.path, 'path');
    const chunk = await db.doc(path).get();
    if (!chunk.exists) {
      throw new HttpsError('data-loss', 'A publicação oficial está incompleta.');
    }
    const payload = object(chunk.get('payload'), 'payload');
    const plannedItems = payload.plannedItems;
    if (Array.isArray(plannedItems)) {
      for (const rawRow of plannedItems) {
        if (rawRow && typeof rawRow === 'object' && !Array.isArray(rawRow)) {
          rows.push(rawRow as Record<string, unknown>);
        }
      }
    }
  }
  return rows;
}

/** Records an owner-only decision using the authorship of the published row. */
export const moderatePlannedItem = onCall(async (request) => {
  const data = object(request.data, 'Solicitação');
  const householdId = string(data.householdId, 'householdId');
  const itemSyncId = string(data.itemSyncId, 'itemSyncId');
  const action = string(data.action, 'action');
  if (!REVIEW_ACTIONS.has(action)) {
    throw new HttpsError('invalid-argument', 'Decisão de revisão inválida.');
  }
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Entre na sua conta para revisar.');
  }

  const rows = await publishedPlannedItems(householdId);
  const item = rows.find((row) => row.syncId === itemSyncId) ?? null;
  const violation = findModerationViolation({
    householdOwnerUid: await householdOwnerUid(householdId),
    requesterUid: request.auth.uid,
    publishedItem: item,
  });
  if (violation === 'not_owner') {
    throw new HttpsError(
      'permission-denied',
      'Somente o dono da casa pode revisar itens.',
    );
  }
  if (violation === 'item_not_found') {
    throw new HttpsError(
      'not-found',
      'O item não existe no estado publicado da casa.',
    );
  }
  if (violation === 'item_without_author') {
    throw new HttpsError(
      'failed-precondition',
      'Este item legado não possui autoria verificável.',
    );
  }
  if (violation === 'own_item') {
    throw new HttpsError(
      'invalid-argument',
      'O owner não precisa revisar um item próprio.',
    );
  }
  const publishedItem = item!;
  const authorUid = publishedItem.authorUid as string;

  const reviewRef = db.doc(
    `syncV2/${householdId}/reviews/${itemSyncId}`,
  );
  const state = await db.doc(`syncV2/${householdId}/state/current`).get();
  await reviewRef.set(
    {
      itemSyncId,
      action,
      authorUid,
      authorName: publishedItem.authorName ?? 'Membro',
      reviewedByUid: request.auth.uid,
      reviewedByName:
        request.auth.token.name ?? request.auth.token.email ?? 'Owner',
      generation: state.get('generation') ?? 0,
      decidedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  return {status: 'recorded', itemSyncId, action};
});
