import {getAuth, ListUsersResult} from 'firebase-admin/auth';
import {Timestamp} from 'firebase-admin/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {hashEmail} from './allowlist.js';
import {
  AllowlistEntry,
  countAllowlistAdmins,
  findAllowlistEntry,
  isValidEmail,
  maskEmail,
  parseAllowlistEntries,
  removeAllowlistEntry,
  upsertAllowlistEntry,
} from './allowlist_admin.js';
import {db} from './firebase_app.js';

const ALLOWLIST_DOCUMENT = 'privateConfig/registrationAllowlist';
const AUDIT_COLLECTION = 'privateConfig/registrationAllowlist/audit';

interface AllowlistDocument {
  emailHashes: string[];
  entries: AllowlistEntry[];
  updatedAt?: string;
  updatedByMask?: string;
}

async function loadAllowlist(): Promise<AllowlistDocument> {
  const snapshot = await db.doc(ALLOWLIST_DOCUMENT).get();
  const hashes = snapshot.get('emailHashes');
  const entries = parseAllowlistEntries(snapshot.get('entries'));
  const updatedAt = snapshot.get('updatedAt');
  return {
    emailHashes: Array.isArray(hashes)
      ? hashes.filter((value): value is string => typeof value === 'string')
      : [],
    entries,
    updatedAt:
      typeof updatedAt === 'string'
        ? updatedAt
        : updatedAt instanceof Timestamp
          ? updatedAt.toDate().toISOString()
          : undefined,
    updatedByMask:
      typeof snapshot.get('updatedByMask') === 'string'
        ? (snapshot.get('updatedByMask') as string)
        : undefined,
  };
}

/**
 * Completa metadados mascarados de hashes legados usando as contas Auth do
 * projeto. E-mails completos nunca são persistidos; somente a máscara.
 */
async function migrateLegacyEntries(
  current: AllowlistDocument,
): Promise<AllowlistDocument> {
  const knownHashes = new Set(current.entries.map((entry) => entry.emailHash));
  const missingHashes = current.emailHashes.filter(
    (hash) => !knownHashes.has(hash),
  );
  if (missingHashes.length === 0) return current;

  const missing = new Set(missingHashes);
  const migrated: AllowlistEntry[] = [];
  let page: ListUsersResult | undefined;
  do {
    page = await getAuth().listUsers(1000, page?.pageToken);
    for (const user of page.users) {
      const email = user.email?.trim().toLowerCase();
      if (!email) continue;
      const hash = hashEmail(email);
      if (!missing.has(hash)) continue;
      migrated.push({
        emailHash: hash,
        emailMask: maskEmail(email),
        role: 'member',
        addedAt: user.metadata.creationTime,
        updatedAt: user.metadata.creationTime,
        updatedByMask: 'migração automática',
      });
      missing.delete(hash);
    }
  } while (page?.pageToken && missing.size > 0);

  return {...current, entries: [...current.entries, ...migrated]};
}

async function persistMigratedEntries(current: AllowlistDocument): Promise<void> {
  await db.doc(ALLOWLIST_DOCUMENT).set(
    {
      emailHashes: current.emailHashes,
      entries: current.entries,
    },
    {merge: true},
  );
}


function requireAdmin(
  current: AllowlistDocument,
  requestAuth: {uid: string; token: {email?: string}},
): {entry: AllowlistEntry; actorMask: string} {
  const email = requestAuth.token.email?.trim().toLowerCase();
  if (!email) {
    throw new HttpsError(
      'unauthenticated',
      'A conta administrativa precisa ter um e-mail válido.',
    );
  }
  const entry = findAllowlistEntry(current.entries, email);
  if (!entry || entry.role !== 'admin') {
    throw new HttpsError(
      'permission-denied',
      'Somente um administrador pode gerenciar a allowlist.',
    );
  }
  return {entry, actorMask: entry.emailMask};
}

/**
 * API administrativa da allowlist do piloto. A autorização é feita no
 * servidor a partir do e-mail da conta autenticada e do papel admin.
 */
export const manageRegistrationAllowlist = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Entre na conta administrativa.');
  }

  const loaded = await loadAllowlist();
  const current = await migrateLegacyEntries(loaded);
  if (current.entries.length !== loaded.entries.length) {
    await persistMigratedEntries(current);
  }
  const {actorMask} = requireAdmin(current, {
    uid: request.auth.uid,
    token: request.auth.token,
  });
  const data = request.data as {
    action?: unknown;
    email?: unknown;
    role?: unknown;
  } | null;
  const action = typeof data?.action === 'string' ? data.action : '';
  const role =
    data?.role === 'admin' ? 'admin' : data?.role === 'member' ? 'member' : null;

  if (action === 'list') {
    return {
      entries: current.entries.map((entry) => ({
        emailMask: entry.emailMask,
        role: entry.role,
        addedAt: entry.addedAt,
        updatedAt: entry.updatedAt,
        updatedByMask: entry.updatedByMask,
      })),
      updatedAt: current.updatedAt ?? null,
      updatedByMask: current.updatedByMask ?? null,
      adminCount: countAllowlistAdmins(current.entries),
    };
  }

  if (action === 'history') {
    const snapshot = await db
      .collection(AUDIT_COLLECTION)
      .orderBy('at', 'desc')
      .limit(50)
      .get();
    return {
      entries: snapshot.docs.map((doc) => {
        const value = doc.data();
        return {
          action: value.action,
          targetMask: value.targetMask,
          actorMask: value.actorMask,
          at: value.at,
        };
      }),
    };
  }

  const email = typeof data?.email === 'string' ? data.email.trim() : '';
  if (!isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'Informe um e-mail válido.');
  }
  const normalized = email.toLowerCase();
  const now = new Date().toISOString();

  if (action === 'add' || action === 'promote') {
    if (action === 'promote' && role !== 'admin') {
      throw new HttpsError(
        'invalid-argument',
        'A promoção exige o papel admin.',
      );
    }
    if (action === 'promote') {
      try {
        await getAuth().getUserByEmail(normalized);
      } catch {
        throw new HttpsError(
          'failed-precondition',
          'A conta administrativa precisa existir no Identity Platform.',
        );
      }
    }
    let result!: ReturnType<typeof upsertAllowlistEntry>;
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(db.doc(ALLOWLIST_DOCUMENT));
      const entries = parseAllowlistEntries(snapshot.get('entries'));
      try {
        result = upsertAllowlistEntry(
          entries,
          normalized,
          action === 'promote' ? 'admin' : 'member',
          actorMask,
          now,
        );
      } catch (error) {
        throw new HttpsError(
          'failed-precondition',
          error instanceof Error ? error.message : 'Falha ao alterar o e-mail.',
        );
      }
      const existingHashes = snapshot.get('emailHashes');
      const preservedHashes = new Set(
        Array.isArray(existingHashes)
          ? existingHashes.filter(
              (value): value is string => typeof value === 'string',
            )
          : [],
      );
      for (const entry of result.entries) {
        if (entry.role === 'member') preservedHashes.add(entry.emailHash);
      }
      transaction.update(db.doc(ALLOWLIST_DOCUMENT), {
        emailHashes: [...preservedHashes].sort(),
        entries: result.entries,
        updatedAt: now,
        updatedByMask: actorMask,
      });
      transaction.create(db.collection(AUDIT_COLLECTION).doc(), {
        action: result.action,
        targetMask: maskEmail(normalized),
        actorMask,
        at: now,
      });
    });
    return {
      status: result.action,
      emailMask: maskEmail(normalized),
      updatedAt: now,
      updatedByMask: actorMask,
    };
  }

  if (action === 'remove') {
    let removed!: AllowlistEntry;
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(db.doc(ALLOWLIST_DOCUMENT));
      const entries = parseAllowlistEntries(snapshot.get('entries'));
      let result!: ReturnType<typeof removeAllowlistEntry>;
      try {
        result = removeAllowlistEntry(entries, normalized);
      } catch (error) {
        throw new HttpsError(
          'failed-precondition',
          error instanceof Error ? error.message : 'Falha ao remover o e-mail.',
        );
      }
      removed = result.removed;
      const existingHashes = snapshot.get('emailHashes');
      const preservedHashes = new Set(
        Array.isArray(existingHashes)
          ? existingHashes.filter(
              (value): value is string => typeof value === 'string',
            )
          : [],
      );
      preservedHashes.delete(removed.emailHash);
      transaction.update(db.doc(ALLOWLIST_DOCUMENT), {
        emailHashes: [...preservedHashes].sort(),
        entries: result.entries,
        updatedAt: now,
        updatedByMask: actorMask,
      });
      transaction.create(db.collection(AUDIT_COLLECTION).doc(), {
        action: 'removed',
        targetMask: removed.emailMask,
        actorMask,
        at: now,
      });
    });
    return {
      status: 'removed',
      emailMask: removed.emailMask,
      updatedAt: now,
      updatedByMask: actorMask,
    };
  }

  throw new HttpsError('invalid-argument', 'Ação administrativa inválida.');
});
