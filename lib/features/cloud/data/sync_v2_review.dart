import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;

import '../../../data/app_database.dart';
import '../domain/collaboration.dart';
import '../domain/sync_v2_canonical.dart';

/// An owner decision stored authoritatively by the pilot backend.
enum SyncV2ReviewAction { approve, reject, remove, restore }

extension SyncV2ReviewActionKey on SyncV2ReviewAction {
  String get key => switch (this) {
    SyncV2ReviewAction.approve => 'approve',
    SyncV2ReviewAction.reject => 'reject',
    SyncV2ReviewAction.remove => 'remove',
    SyncV2ReviewAction.restore => 'restore',
  };
}

class SyncV2Review {
  const SyncV2Review({
    required this.itemSyncId,
    required this.action,
    required this.reviewedByUid,
    required this.reviewedByName,
    required this.decidedAt,
    required this.authorUid,
    required this.authorName,
  });

  factory SyncV2Review.fromMap(Map<String, dynamic> map) {
    final action = switch (map['action']) {
      'approve' => SyncV2ReviewAction.approve,
      'reject' => SyncV2ReviewAction.reject,
      'remove' => SyncV2ReviewAction.remove,
      'restore' => SyncV2ReviewAction.restore,
      _ => throw const FormatException('Revisão desconhecida.'),
    };
    return SyncV2Review(
      itemSyncId: map['itemSyncId'] as String? ?? '',
      action: action,
      reviewedByUid: map['reviewedByUid'] as String? ?? '',
      reviewedByName: map['reviewedByName'] as String? ?? 'Owner',
      decidedAt: _date(map['decidedAt']) ?? DateTime.now().toUtc(),
      authorUid: map['authorUid'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Membro',
    );
  }

  final String itemSyncId;
  final SyncV2ReviewAction action;
  final String reviewedByUid;
  final String reviewedByName;
  final DateTime decidedAt;
  final String authorUid;
  final String authorName;

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is Timestamp) return value.toDate().toUtc();
    return null;
  }
}

/// Applies authoritative owner decisions to a backup-compatible payload.
///
/// The review document is the source of truth. Applying it before every merge
/// prevents an old publication from resurrecting an item removed by the owner.
///
/// The decision is applied idempotently: the same decision is never counted
/// twice, so repeated synchronizations do not inflate `syncRevision` and make
/// two devices that hold the same data look different.
Map<String, dynamic> applySyncV2Reviews(
  Map<String, dynamic> payload,
  Iterable<SyncV2Review> reviews,
) {
  final result = Map<String, dynamic>.from(payload);
  for (final table in const ['products', 'shoppingPlans', 'plannedItems']) {
    final rawRows = result[table];
    if (rawRows is! List) continue;
    final rows = rawRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    for (final review in reviews) {
      for (final row in rows) {
        if (row['syncId'] != review.itemSyncId) continue;
        final approved =
            review.action == SyncV2ReviewAction.approve ||
            review.action == SyncV2ReviewAction.restore;
        final nextState = approved ? 'approved' : 'rejected';
        final decidedAt = canonicalSyncV2Timestamp(review.decidedAt);
        final alreadyApplied =
            row['reviewState'] == nextState &&
            _sameInstant(row['reviewedAt'], review.decidedAt);
        row['reviewState'] = nextState;
        row['reviewedByUid'] = review.reviewedByUid;
        row['reviewedByName'] = review.reviewedByName;
        row['reviewedAt'] = decidedAt;
        if (!alreadyApplied) {
          row['syncRevision'] =
              ((row['syncRevision'] as num?)?.toInt() ?? 0) + 1;
        }
        if (review.action == SyncV2ReviewAction.remove) {
          row['isRemoved'] = true;
          row['deletedAt'] = decidedAt;
        } else if (review.action == SyncV2ReviewAction.restore) {
          row['isRemoved'] = false;
          row['deletedAt'] = null;
        }
      }
    }
    result[table] = rows;
  }
  return result;
}

/// Applies a review to the local row of the item it decided about.
///
/// The owner decides through the published state, but the decision must also
/// reach the database of the device that made it. The write is idempotent:
/// applying the same decision again does not advance `syncRevision` a second
/// time, which is what produced the off-by-one difference between devices.
Future<void> applySyncV2ReviewToLocalItem(
  AppDatabase database,
  SyncV2Review review,
) async {
  final row = await (database.select(
    database.plannedItems,
  )..where((item) => item.syncId.equals(review.itemSyncId))).getSingleOrNull();
  if (row == null) {
    // The published review is authoritative even when this device has not
    // completed the full pull yet. The next pull will materialize it.
    return;
  }

  final approved =
      review.action == SyncV2ReviewAction.approve ||
      review.action == SyncV2ReviewAction.restore;
  final removed = review.action == SyncV2ReviewAction.remove;
  final restored = review.action == SyncV2ReviewAction.restore;
  final nextState = approved ? 'approved' : 'rejected';
  final decidedAt = canonicalSyncV2Instant(review.decidedAt);
  final alreadyApplied =
      row.reviewState == nextState &&
      row.reviewedAt != null &&
      canonicalSyncV2Instant(row.reviewedAt!) == decidedAt;
  if (alreadyApplied) return;

  await (database.update(
    database.plannedItems,
  )..where((item) => item.id.equals(row.id))).write(
    PlannedItemsCompanion(
      reviewState: Value(nextState),
      reviewedByUid: Value(review.reviewedByUid),
      reviewedByName: Value(review.reviewedByName),
      reviewedAt: Value(decidedAt),
      isRemoved: Value(
        removed
            ? true
            : restored
            ? false
            : row.isRemoved,
      ),
      deletedAt: Value(
        removed
            ? decidedAt
            : restored
            ? null
            : row.deletedAt,
      ),
      syncRevision: Value(row.syncRevision + 1),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

/// Compares a serialized instant with a decision instant.
///
/// The same moment can be described with a local timezone marker or with `Z`,
/// and the database keeps a coarser precision than the review document. Both
/// describe the same decision and must not be counted twice.
bool _sameInstant(Object? value, DateTime instant) {
  final parsed = canonicalSyncV2ParsedInstant(value);
  if (parsed == null) return false;
  return parsed == canonicalSyncV2Instant(instant);
}

/// A pending item added after an owner removal is a new review, not a
/// resurrection of the old identity. Older pilot builds reused the tombstone
/// row; give those rows a fresh syncId before applying the previous decision.
Map<String, dynamic> separateReaddedPendingItems(
  Map<String, dynamic> payload,
  Iterable<SyncV2Review> reviews,
) {
  final result = Map<String, dynamic>.from(payload);
  final rawRows = result['plannedItems'];
  if (rawRows is! List) return result;
  final rows = rawRows
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
  for (final review in reviews.where(
    (review) => review.action == SyncV2ReviewAction.remove,
  )) {
    for (final row in rows.where((row) => row['syncId'] == review.itemSyncId)) {
      final updatedAt = canonicalSyncV2ParsedInstant(row['updatedAt']);
      final isPending =
          row['reviewState'] == CollaborationMetadata.pendingReview &&
          row['deletedAt'] == null &&
          row['isRemoved'] != true;
      if (!isPending ||
          updatedAt == null ||
          !updatedAt.isAfter(canonicalSyncV2Instant(review.decidedAt))) {
        continue;
      }
      row['syncId'] = CollaborationMetadata.newSyncId('planned-item');
      row['syncRevision'] = 0;
    }
  }
  result['plannedItems'] = rows;
  return result;
}

bool syncV2PayloadEquals(
  Map<String, dynamic> left,
  Map<String, dynamic> right,
) {
  return jsonEncode(_canonicalize(left)) == jsonEncode(_canonicalize(right));
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalize(value[key])};
  }
  if (value is List) {
    return value.map(_canonicalize).toList();
  }
  return value;
}
