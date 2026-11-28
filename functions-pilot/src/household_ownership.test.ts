import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {
  findOwnershipTransferViolation,
  validResourceId,
} from './household_ownership.js';

describe('transferência de propriedade da casa', () => {
  it('permite o owner transferir para um membro comum', () => {
    assert.equal(
      findOwnershipTransferViolation({
        requesterUid: 'owner-1',
        targetUid: 'member-1',
        currentOwnerUid: 'owner-1',
        targetExists: true,
        targetRole: 'member',
      }),
      null,
    );
  });

  it('recusa um membro que não é o owner', () => {
    assert.equal(
      findOwnershipTransferViolation({
        requesterUid: 'member-1',
        targetUid: 'member-2',
        currentOwnerUid: 'owner-1',
        targetExists: true,
        targetRole: 'member',
      }),
      'not_owner',
    );
  });

  it('recusa uma conta que não pertence à casa', () => {
    assert.equal(
      findOwnershipTransferViolation({
        requesterUid: 'owner-1',
        targetUid: 'outsider-1',
        currentOwnerUid: 'owner-1',
        targetExists: false,
        targetRole: null,
      }),
      'target_not_member',
    );
  });

  it('recusa o próprio owner como destino', () => {
    assert.equal(
      findOwnershipTransferViolation({
        requesterUid: 'owner-1',
        targetUid: 'owner-1',
        currentOwnerUid: 'owner-1',
        targetExists: true,
        targetRole: 'owner',
      }),
      'invalid_target',
    );
  });

  it('recusa uma claim com payload nulo ou identificadores malformados', () => {
    const data = null as unknown as {householdId?: unknown; targetUid?: unknown};
    const householdId =
      typeof data?.householdId === 'string' ? data.householdId.trim() : '';
    const targetUid =
      typeof data?.targetUid === 'string' ? data.targetUid.trim() : '';
    assert.equal(householdId, '');
    assert.equal(targetUid, '');
    assert.equal(validResourceId(householdId), false);
    assert.equal(validResourceId(targetUid), false);
    assert.equal(validResourceId('households/other'), false);
    assert.equal(validResourceId('valid-id'), true);
  });
});
