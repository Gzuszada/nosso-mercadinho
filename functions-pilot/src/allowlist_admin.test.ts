import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {hashEmail} from './allowlist.js';
import {
  AllowlistEntry,
  countAllowlistAdmins,
  isValidEmail,
  maskEmail,
  parseAllowlistEntries,
  removeAllowlistEntry,
  upsertAllowlistEntry,
} from './allowlist_admin.js';

function entry(
  email: string,
  role: 'admin' | 'member',
): AllowlistEntry {
  const emailMask = maskEmail(email);
  return {
    emailHash: hashEmail(email),
    emailMask,
    role,
    addedAt: '2026-11-28T12:00:00.000Z',
    updatedAt: '2026-11-28T12:00:00.000Z',
    updatedByMask: 'a***@example.com',
  };
}

describe('administração da allowlist', () => {
  it('valida e-mails e mascara sem expor o valor completo', () => {
    assert.equal(isValidEmail('pessoa@example.com'), true);
    assert.equal(isValidEmail(' PESSOA@example.com '), true);
    assert.equal(isValidEmail('pessoa@example'), false);
    assert.equal(isValidEmail('pessoa @example.com'), false);
    assert.equal(isValidEmail('duplicada@@example.com'), false);
    assert.equal(maskEmail('pessoa@example.com'), 'p***@example.com');
    assert.equal(
      maskEmail('pessoa+mercado-admin@example.com'),
      'p***+m***@example.com',
    );
  });

  it('adiciona e promove entradas com autoria e instante', () => {
    const added = upsertAllowlistEntry(
      [],
      'pessoa@example.com',
      'member',
      'admin***@example.com',
      '2026-11-28T12:00:00.000Z',
    );
    assert.equal(added.action, 'added');
    assert.equal(added.entries[0].emailMask, 'p***@example.com');
    assert.equal(added.entries[0].role, 'member');
    assert.equal(added.entries[0].updatedByMask, 'admin***@example.com');

    const promoted = upsertAllowlistEntry(
      added.entries,
      'pessoa@example.com',
      'admin',
      'admin***@example.com',
      '2026-11-28T13:00:00.000Z',
    );
    assert.equal(promoted.action, 'promoted');
    assert.equal(promoted.entries[0].role, 'admin');
  });

  it('impede remover o último administrador', () => {
    const admin = entry('admin@example.com', 'admin');
    assert.throws(
      () => removeAllowlistEntry([admin], 'admin@example.com'),
      /último administrador/,
    );
  });

  it('permite remover administrador quando existe outro', () => {
    const first = entry('admin@example.com', 'admin');
    const second = entry('outro@example.com', 'admin');
    const result = removeAllowlistEntry([first, second], 'admin@example.com');
    assert.equal(result.entries.length, 1);
    assert.equal(countAllowlistAdmins(result.entries), 1);
  });

  it('ignora entradas malformadas e falha fechado', () => {
    const parsed = parseAllowlistEntries([
      {emailHash: 'invalido', role: 'admin'},
      null,
    ]);
    assert.deepEqual(parsed, []);
  });
});
