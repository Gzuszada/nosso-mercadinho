import {createHash} from 'node:crypto';
import {FieldValue} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {db} from './firebase_app.js';
import {decideCas} from './sync_v2_cas.js';
const MAX_CHUNKS = 256;
const MAX_CHUNK_BYTES = 700 * 1024;

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

function integer(value: unknown, name: string): number {
  if (typeof value !== 'number' || !Number.isSafeInteger(value)) {
    throw new HttpsError('invalid-argument', `${name} inválido.`);
  }
  return value;
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === 'object') {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(record).sort().map((key) => [key, canonicalize(record[key])]),
    );
  }
  return value;
}

export function hashManifest(value: unknown): string {
  return createHash('sha256')
    .update(JSON.stringify(canonicalize(value)))
    .digest('hex');
}

function rowCount(value: unknown): number {
  if (Array.isArray(value)) {
    return value.length;
  }
  if (value && typeof value === 'object') {
    return Object.values(value as Record<string, unknown>).reduce<number>(
      (total, entry) => total + rowCount(entry),
      0,
    );
  }
  return 1;
}

async function assertMember(householdId: string, uid: string): Promise<void> {
  const member = await db.doc(`households/${householdId}/members/${uid}`).get();
  if (!member.exists) {
    throw new HttpsError('permission-denied', 'Você não pertence a esta casa.');
  }
}

async function assertOwner(householdId: string, uid: string): Promise<void> {
  const household = await db.doc(`households/${householdId}`).get();
  if (household.get('ownerUid') !== uid) {
    throw new HttpsError(
      'permission-denied',
      'Somente o dono da casa pode decidir este conflito.',
    );
  }
}


async function assertChunks(
  householdId: string,
  publicationId: string,
  area: string,
  descriptors: Record<string, unknown>[],
): Promise<void> {
  if (descriptors.length === 0 || descriptors.length > MAX_CHUNKS) {
    throw new HttpsError('invalid-argument', `Chunks inválidos em ${area}.`);
  }
  const sorted = [...descriptors].sort(
    (left, right) => integer(left.index, 'index') - integer(right.index, 'index'),
  );
  for (let index = 0; index < sorted.length; index += 1) {
    const descriptor = sorted[index];
    const chunkIndex = integer(descriptor.index, 'index');
    const path = string(descriptor.path, 'path');
    const expectedPath =
      `syncV2/${householdId}/candidates/${publicationId}` +
      `/areas/${area}/parts/${index}`;
    if (chunkIndex !== index || path !== expectedPath) {
      throw new HttpsError('invalid-argument', `Chunks incompletos em ${area}.`);
    }
    const chunk = await db.doc(path).get();
    if (!chunk.exists || chunk.get('payload') === undefined) {
      throw new HttpsError(
        'failed-precondition',
        `A publicação ainda está incompleta (${area}).`,
      );
    }
    const payload = chunk.get('payload');
    if (Buffer.byteLength(JSON.stringify(payload), 'utf8') > MAX_CHUNK_BYTES) {
      throw new HttpsError('invalid-argument', `Chunk grande demais em ${area}.`);
    }
    if (hashManifest(payload) !== string(descriptor.hash, 'hash')) {
      throw new HttpsError(
        'data-loss',
        `A integridade do chunk ${area}/${index} não confere.`,
      );
    }
    if (rowCount(payload) !== integer(descriptor.count, 'count')) {
      throw new HttpsError(
        'invalid-argument',
        `A contagem do chunk ${area}/${index} não confere.`,
      );
    }
  }
}


/**
 * Commits an immutable candidate using compare-and-swap.
 *
 * Chunks are written by the member before this callable is invoked. The
 * transaction only changes the official manifest pointer. A concurrent loser
 * remains stored as a candidate and is attached to a conflict document.
 */
export const publishSyncV2 = onCall(async (request) => {
  const data = object(request.data, 'Solicitação');
  const householdId = string(data.householdId, 'householdId');
  const publicationId = string(data.publicationId, 'publicationId');
  const baseGeneration = integer(data.baseGeneration, 'baseGeneration');
  const expectedManifestHash =
    data.expectedManifestHash == null
      ? null
      : string(data.expectedManifestHash, 'expectedManifestHash');
  const manifest = object(data.manifest, 'manifest');

  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Entre na sua conta para publicar.');
  }
  await assertMember(householdId, request.auth.uid);
  if (data.requiresOwnerModeration === true) {
    await assertOwner(householdId, request.auth.uid);
  }
  if (manifest.protocolVersion !== 2) {
    throw new HttpsError('invalid-argument', 'Versão de sincronização não suportada.');
  }
  if (manifest.publicationId !== publicationId) {
    throw new HttpsError('invalid-argument', 'Identificador da publicação divergente.');
  }
  if (manifest.baseGeneration !== baseGeneration) {
    throw new HttpsError('invalid-argument', 'Generation base divergente.');
  }
  if (manifest.authorUid !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Autoria da publicação inválida.');
  }

  const manifestAreas = object(manifest.areas, 'areas');
  for (const [area, rawArea] of Object.entries(manifestAreas)) {
    const areaManifest = object(rawArea, `Área ${area}`);
    const rawDescriptors = areaManifest.chunks;
    if (!Array.isArray(rawDescriptors)) {
      throw new HttpsError('invalid-argument', `Chunks inválidos em ${area}.`);
    }
    const descriptors = rawDescriptors.map((raw) => object(raw, 'chunk'));
    await assertChunks(householdId, publicationId, area, descriptors);
    const declaredHash = string(areaManifest.hash, `hash de ${area}`);
    const calculatedHash = hashManifest(
      descriptors
        .map((descriptor) => ({
          index: descriptor.index,
          hash: descriptor.hash,
          count: descriptor.count,
        }))
        .sort((left, right) => Number(left.index) - Number(right.index)),
    );
    if (declaredHash !== calculatedHash) {
      throw new HttpsError('data-loss', `O hash da área ${area} não confere.`);
    }
  }


  const candidateRef = db.doc(
    `syncV2/${householdId}/candidates/${publicationId}`,
  );
  const stateRef = db.doc(`syncV2/${householdId}/state/current`);
  const conflictId = `generation-${baseGeneration}-${publicationId}`;
  const conflictRef = db.doc(
    `syncV2/${householdId}/conflicts/${conflictId}`,
  );

  await db.runTransaction(async (transaction) => {
    const [stateSnapshot, candidateSnapshot] = await transaction.getAll(
      stateRef,
      candidateRef,
    );
    const state = stateSnapshot.data();
    const currentGeneration = state?.generation ?? 0;
    const currentManifestHash = state?.manifestHash ?? null;
    const decision = decideCas(
      {
        currentGeneration,
        currentManifestHash,
        candidateAlreadyCommitted:
          candidateSnapshot.exists &&
          candidateSnapshot.get('status') === 'committed',
      },
      baseGeneration,
      expectedManifestHash,
    );

    if (decision === 'alreadyCommitted') {
      return;
    }

    if (decision === 'commit') {
      const nextGeneration = currentGeneration + 1;
      transaction.set(
        stateRef,
        {
          generation: nextGeneration,
          manifestHash: hashManifest(manifest),
          publicationId,
          manifest,
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      transaction.set(
        candidateRef,
        {
          status: 'committed',
          generation: nextGeneration,
          committedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return;
    }

    transaction.set(
      candidateRef,
      {
        status: 'rejected',
        rejectedAt: FieldValue.serverTimestamp(),
        rejectedGeneration: currentGeneration,
      },
      {merge: true},
    );
    transaction.set(
      conflictRef,
      {
        baseGeneration,
        currentGeneration,
        currentManifestHash,
        rejectedPublicationId: publicationId,
        rejectedManifest: manifest,
        authorUid: request.auth!.uid,
        authorName: manifest.authorName,
        status: 'open',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });

  const stateAfter = await stateRef.get();
  if (stateAfter.get('publicationId') === publicationId) {
    return {
      status: 'committed',
      generation: stateAfter.get('generation') ?? baseGeneration + 1,
      conflictId: null,
    };
  }
  const candidate = await candidateRef.get();
  if (candidate.get('status') === 'committed') {
    return {
      status: 'alreadyCommitted',
      generation: candidate.get('generation'),
      conflictId: null,
    };
  }
  return {
    status: 'conflict',
    generation: stateAfter.get('generation') ?? 0,
    conflictId,
  };
});
