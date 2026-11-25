import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {
  hashEmail,
  isEmailAllowed,
  normalizeEmail,
  parseEmailHashes,
} from './allowlist.js';

describe('registration allowlist', () => {
  it('normalizes e-mail before hashing', () => {
    assert.equal(normalizeEmail('  Pessoa@Example.COM '), 'pessoa@example.com');
    assert.equal(
      hashEmail('Pessoa@Example.com'),
      hashEmail(' pessoa@example.COM '),
    );
  });

  it('accepts only e-mails whose hash is configured', () => {
    const allowed = parseEmailHashes([
      hashEmail('dono@example.com'),
      'not-a-valid-hash',
    ]);

    assert.equal(isEmailAllowed('DONO@example.com', allowed), true);
    assert.equal(isEmailAllowed('outro@example.com', allowed), false);
  });

  it('fails closed when configuration is missing or malformed', () => {
    assert.equal(isEmailAllowed('dono@example.com', parseEmailHashes(null)), false);
    assert.equal(
      isEmailAllowed('dono@example.com', parseEmailHashes(['email-em-plano'])),
      false,
    );
  });
});
