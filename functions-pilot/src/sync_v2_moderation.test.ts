import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {
  findModerationViolation,
  isHouseholdOwner,
} from './sync_v2_moderation.js';

describe('hierarquia de moderação do owner', () => {
  it('reconhece o owner confirmado pela casa', () => {
    assert.equal(isHouseholdOwner('owner-1', 'owner-1'), true);
    assert.equal(isHouseholdOwner('owner-1', 'member-1'), false);
    assert.equal(isHouseholdOwner(null, 'owner-1'), false);
  });

  it('permite o owner remover um item de outro membro', () => {
    const violation = findModerationViolation({
      householdOwnerUid: 'owner-1',
      requesterUid: 'owner-1',
      publishedItem: {
        syncId: 'planned-item:1',
        authorUid: 'member-1',
        authorName: 'Membro',
      },
    });
    assert.equal(violation, null);
  });

  it('recusa um membro que não é o owner da casa', () => {
    const violation = findModerationViolation({
      householdOwnerUid: 'owner-1',
      requesterUid: 'member-2',
      publishedItem: {
        syncId: 'planned-item:1',
        authorUid: 'member-1',
      },
    });
    assert.equal(violation, 'not_owner');
  });

  it('recusa a remoção quando o item não está publicado', () => {
    const violation = findModerationViolation({
      householdOwnerUid: 'owner-1',
      requesterUid: 'owner-1',
      publishedItem: null,
    });
    assert.equal(violation, 'item_not_found');
  });

  it('recusa um item legado sem autoria verificável', () => {
    const violation = findModerationViolation({
      householdOwnerUid: 'owner-1',
      requesterUid: 'owner-1',
      publishedItem: {syncId: 'planned-item:1'},
    });
    assert.equal(violation, 'item_without_author');
  });

  it('recusa o owner moderando um item próprio', () => {
    const violation = findModerationViolation({
      householdOwnerUid: 'owner-1',
      requesterUid: 'owner-1',
      publishedItem: {
        syncId: 'planned-item:1',
        authorUid: 'owner-1',
      },
    });
    assert.equal(violation, 'own_item');
  });
});