import {hashEmail, normalizeEmail} from './allowlist.js';

export interface AllowlistEntry {
  emailHash: string;
  emailMask: string;
  role: 'admin' | 'member';
  addedAt: string;
  updatedAt: string;
  updatedByMask: string;
}

export interface AllowlistAuditEntry {
  action: 'added' | 'removed' | 'promoted';
  targetMask: string;
  actorMask: string;
  at: string;
}

export function isValidEmail(email: string): boolean {
  const normalized = normalizeEmail(email);
  if (normalized.length < 6 || normalized.length > 254) return false;
  if (/\s/.test(normalized)) return false;
  const parts = normalized.split('@');
  if (parts.length !== 2) return false;
  const [local, domain] = parts;
  if (!local || !domain || local.length > 64) return false;
  if (!domain.includes('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return false;
  }
  if (domain.includes('..')) return false;
  return /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$/.test(local) &&
    /^[a-z0-9.-]+$/.test(domain);
}

export function maskEmail(email: string): string {
  const normalized = normalizeEmail(email);
  const separator = normalized.lastIndexOf('@');
  if (separator <= 0 || separator === normalized.length - 1) {
    return '***';
  }
  const local = normalized.slice(0, separator);
  const domain = normalized.slice(separator + 1);
  const [base, ...tags] = local.split('+');
  const tagMask = tags.length
    ? `+${tags.join('+').slice(0, 1)}***`
    : '';
  return `${base.slice(0, 1)}***${tagMask}@${domain}`;
}

export function parseAllowlistEntries(value: unknown): AllowlistEntry[] {
  if (!Array.isArray(value)) return [];
  return value.filter((entry): entry is AllowlistEntry => {
    if (!entry || typeof entry !== 'object') return false;
    const candidate = entry as Partial<AllowlistEntry>;
    return (
      typeof candidate.emailHash === 'string' &&
      /^[a-f0-9]{64}$/.test(candidate.emailHash) &&
      typeof candidate.emailMask === 'string' &&
      candidate.emailMask.length > 0 &&
      (candidate.role === 'admin' || candidate.role === 'member') &&
      typeof candidate.addedAt === 'string' &&
      typeof candidate.updatedAt === 'string' &&
      typeof candidate.updatedByMask === 'string'
    );
  });
}

export function findAllowlistEntry(
  entries: readonly AllowlistEntry[],
  email: string,
): AllowlistEntry | undefined {
  const hash = hashEmail(email);
  return entries.find((entry) => entry.emailHash === hash);
}

export function countAllowlistAdmins(
  entries: readonly AllowlistEntry[],
): number {
  return entries.filter((entry) => entry.role === 'admin').length;
}

export function upsertAllowlistEntry(
  entries: readonly AllowlistEntry[],
  email: string,
  role: 'admin' | 'member',
  actorMask: string,
  now: string,
): {entries: AllowlistEntry[]; action: AllowlistAuditEntry['action']} {
  const normalized = normalizeEmail(email);
  const emailHash = hashEmail(normalized);
  const emailMask = maskEmail(normalized);
  const existing = entries.find((entry) => entry.emailHash === emailHash);
  if (!existing) {
    return {
      entries: [
        ...entries,
        {
          emailHash,
          emailMask,
          role,
          addedAt: now,
          updatedAt: now,
          updatedByMask: actorMask,
        },
      ],
      action: 'added',
    };
  }
  if (existing.role === role) {
    throw new Error('O e-mail já está autorizado com esse mesmo papel.');
  }
  if (role === 'member') {
    throw new Error('O e-mail já é administrador e não pode ser rebaixado.');
  }
  return {
    entries: entries.map((entry) =>
      entry.emailHash === emailHash
        ? {...entry, role, updatedAt: now, updatedByMask: actorMask}
        : entry,
    ),
    action: 'promoted',
  };
}

export function removeAllowlistEntry(
  entries: readonly AllowlistEntry[],
  email: string,
): {entries: AllowlistEntry[]; removed: AllowlistEntry} {
  const normalized = normalizeEmail(email);
  const emailHash = hashEmail(normalized);
  const existing = entries.find((entry) => entry.emailHash === emailHash);
  if (!existing) throw new Error('O e-mail não está autorizado.');
  if (existing.role === 'admin' && countAllowlistAdmins(entries) <= 1) {
    throw new Error('Não é possível remover o último administrador.');
  }
  return {
    entries: entries.filter((entry) => entry.emailHash !== existing.emailHash),
    removed: existing,
  };
}
