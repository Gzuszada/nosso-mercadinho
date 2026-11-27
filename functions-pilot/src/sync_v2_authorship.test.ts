import assert from 'node:assert/strict';
import {test} from 'node:test';

import {
  findAuthorshipViolation,
  findReviewDecisionViolation,
} from './sync_v2_authorship.js';

test('rejects a new item whose author differs from the publisher', () => {
  const violation = findAuthorshipViolation(
    [],
    [{syncId: 'item-1', authorUid: 'member-2'}],
    'member-1',
    false,
  );
  assert.equal(violation?.reason, 'new_item_author_mismatch');
});

test('rejects an attempt to change the author of a published item', () => {
  const violation = findAuthorshipViolation(
    [{syncId: 'item-1', authorUid: 'member-1'}],
    [{syncId: 'item-1', authorUid: 'owner-1'}],
    'owner-1',
    true,
  );
  assert.equal(violation?.reason, 'author_changed');
});

test('accepts an owner publishing a member-authored item unchanged', () => {
  const violation = findAuthorshipViolation(
    [{syncId: 'item-1', authorUid: 'member-1'}],
    [{syncId: 'item-1', authorUid: 'member-1'}],
    'owner-1',
    true,
  );
  assert.equal(violation, null);
});

test('rejects a stale payload that resurrects an owner removal', () => {
  const violation = findReviewDecisionViolation(
    {
      itemSyncId: 'item-1',
      action: 'remove',
      reviewedByUid: 'owner-1',
    },
    {
      syncId: 'item-1',
      reviewState: 'approved',
      reviewedByUid: 'owner-1',
      isRemoved: false,
    },
  );
  assert.equal(violation?.reason, 'review_state_mismatch');
});

test('accepts an absent row after an authoritative removal', () => {
  const violation = findReviewDecisionViolation(
    {
      itemSyncId: 'item-1',
      action: 'remove',
      reviewedByUid: 'owner-1',
    },
    null,
  );
  assert.equal(violation, null);
});

test('accepts a payload carrying the owner tombstone decision', () => {
  const violation = findReviewDecisionViolation(
    {
      itemSyncId: 'item-1',
      action: 'remove',
      reviewedByUid: 'owner-1',
    },
    {
      syncId: 'item-1',
      reviewState: 'rejected',
      reviewedByUid: 'owner-1',
      isRemoved: true,
    },
  );
  assert.equal(violation, null);
});

test('does not allow a member to introduce an unattributed row', () => {
  const violation = findAuthorshipViolation(
    [],
    [{syncId: 'legacy-1', authorUid: null}],
    'member-1',
    false,
  );
  assert.equal(violation?.reason, 'new_item_without_author');
});
