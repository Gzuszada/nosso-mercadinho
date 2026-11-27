export type AuthorshipRow = Record<string, unknown>;

export interface AuthorshipViolation {
  syncId: string;
  reason: string;
}

export function findReviewDecisionViolation(
  review: Record<string, unknown>,
  candidate: Record<string, unknown> | null,
): AuthorshipViolation | null {
  const syncId = typeof review.itemSyncId === 'string' ? review.itemSyncId : '';
  const action = typeof review.action === 'string' ? review.action : '';
  if (!candidate) {
    // A tombstone authoritative decision is also satisfied when the row is
    // absent from the candidate payload. If a stale row reappears later, the
    // checks below reject it.
    return action === 'remove'
      ? null
      : {syncId, reason: 'reviewed_item_missing'};
  }
  const expectedState =
    action === 'approve' || action === 'restore' ? 'approved' : 'rejected';
  if (candidate.reviewState !== expectedState) {
    return {syncId, reason: 'review_state_mismatch'};
  }
  if (candidate.reviewedByUid !== review.reviewedByUid) {
    return {syncId, reason: 'reviewer_mismatch'};
  }
  if (action === 'remove' && candidate.isRemoved !== true) {
    return {syncId, reason: 'review_tombstone_missing'};
  }
  if (action === 'restore' && candidate.isRemoved === true) {
    return {syncId, reason: 'reviewed_item_not_restored'};
  }
  return null;
}

/**
 * Verifies that authorship is immutable and that a newly introduced row
 * belongs to the publisher. The owner may publish legacy rows without an
 * author, but a member may not introduce an unattributed row.
 */
export function findAuthorshipViolation(
  currentRows: AuthorshipRow[],
  candidateRows: AuthorshipRow[],
  publisherUid: string,
  publisherIsOwner: boolean,
): AuthorshipViolation | null {
  const currentBySyncId = new Map<string, AuthorshipRow>();
  for (const row of currentRows) {
    const syncId = typeof row.syncId === 'string' ? row.syncId : '';
    if (!syncId) {
      return {syncId: '', reason: 'stable_sync_id_missing'};
    }
    if (currentBySyncId.has(syncId)) {
      return {syncId, reason: 'duplicate_sync_id'};
    }
    currentBySyncId.set(syncId, row);
  }

  const candidateIds = new Set<string>();
  for (const row of candidateRows) {
    const syncId = typeof row.syncId === 'string' ? row.syncId : '';
    if (!syncId) {
      return {syncId: '', reason: 'stable_sync_id_missing'};
    }
    if (candidateIds.has(syncId)) {
      return {syncId, reason: 'duplicate_sync_id'};
    }
    candidateIds.add(syncId);

    const current = currentBySyncId.get(syncId);
    const candidateAuthor =
      typeof row.authorUid === 'string' && row.authorUid.length > 0
        ? row.authorUid
        : null;
    if (current) {
      const currentAuthor =
        typeof current.authorUid === 'string' && current.authorUid.length > 0
          ? current.authorUid
          : null;
      if (candidateAuthor !== currentAuthor) {
        return {syncId, reason: 'author_changed'};
      }
      continue;
    }

    if (candidateAuthor === null) {
      if (!publisherIsOwner) {
        return {syncId, reason: 'new_item_without_author'};
      }
      continue;
    }
    if (candidateAuthor !== publisherUid) {
      return {syncId, reason: 'new_item_author_mismatch'};
    }
  }
  return null;
}
