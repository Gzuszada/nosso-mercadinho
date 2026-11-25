import {createHash} from 'node:crypto';

export const REGISTRATION_ALLOWLIST_DOCUMENT = 'privateConfig/registrationAllowlist';

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function hashEmail(email: string): string {
  return createHash('sha256').update(normalizeEmail(email)).digest('hex');
}

export function parseEmailHashes(value: unknown): Set<string> {
  if (!Array.isArray(value)) {
    return new Set<string>();
  }

  return new Set(
    value.filter(
      (entry): entry is string =>
        typeof entry === 'string' && /^[a-f0-9]{64}$/.test(entry),
    ),
  );
}

export function isEmailAllowed(
  email: string,
  allowedHashes: ReadonlySet<string>,
): boolean {
  return allowedHashes.has(hashEmail(email));
}
