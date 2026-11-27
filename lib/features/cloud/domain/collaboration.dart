import 'dart:convert';
import 'dart:math';

import 'sync_v2_canonical.dart';

/// The role is resolved from the selected household. It is deliberately kept
/// out of the repositories so local/offline use does not require Firebase.
enum CollaborationRole { owner, member, local }

class CollaborationActor {
  const CollaborationActor({
    required this.uid,
    required this.displayName,
    required this.role,
  });

  const CollaborationActor.local([this.displayName = 'Uso local'])
    : uid = 'local',
      role = CollaborationRole.local;

  final String uid;
  final String displayName;
  final CollaborationRole role;

  bool get isOwner => role == CollaborationRole.owner;
}

typedef CollaborationActorResolver = Future<CollaborationActor?> Function();

/// A review entry shown in the owner panel. It can originate from the local
/// database or from the authoritative published state of the household.
class PlanReviewItem {
  const PlanReviewItem({
    required this.itemSyncId,
    required this.productName,
    required this.planName,
    required this.createdAt,
    this.authorName,
    this.authorUid,
  });

  final String itemSyncId;
  final String productName;
  final String planName;
  final DateTime createdAt;
  final String? authorName;
  final String? authorUid;
}

class CollaborationMetadata {
  const CollaborationMetadata._();

  static const pendingReview = 'pending_review';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static String newSyncId(String entity) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$entity:$hex';
  }

  static String productLogicalKey({
    required String name,
    required String measurementMode,
  }) => 'product:${normalize(name)}:${normalize(measurementMode)}';

  static String planLogicalKey({
    required String monthKey,
    required String name,
  }) => 'plan:$monthKey:${normalize(name)}';

  static String plannedItemLogicalKey({
    required String planSyncId,
    required String productSyncId,
  }) => 'planned-item:$planSyncId:$productSyncId';

  static String normalize(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return normalized.isEmpty ? 'unknown' : normalized;
  }
}

/// A compact, revision-aware representation used by the per-item merge.
class CollaborativeItem {
  const CollaborativeItem({
    required this.syncId,
    required this.logicalKey,
    required this.revision,
    required this.deletedAt,
    required this.value,
    required this.table,
  });

  factory CollaborativeItem.fromJson(
    Map<String, dynamic> json, {
    required String table,
  }) {
    final deletedAt = json['deletedAt'];
    return CollaborativeItem(
      syncId: json['syncId'] as String? ?? '',
      logicalKey: json['logicalKey'] as String? ?? '',
      revision: (json['syncRevision'] as num?)?.toInt() ?? 0,
      deletedAt: deletedAt is String ? DateTime.tryParse(deletedAt) : null,
      value: json,
      table: table,
    );
  }

  final String syncId;
  final String logicalKey;
  final int revision;
  final DateTime? deletedAt;
  final Map<String, dynamic> value;

  /// Table the row belongs to, used to know which fields are device-local.
  final String table;

  bool get isTombstone => deletedAt != null;

  /// Content of the row, as every device describes it.
  ///
  /// The same rule used by the area comparison is applied here: the instants
  /// are normalized and the device-local fields are ignored, so the same item
  /// published by two devices is not reported as a concurrent edit.
  ///
  /// `deletedAt` is left out because a tombstone is compared through
  /// [isTombstone], which always wins over a live value.
  String get _stableValue {
    final canonical = canonicalSyncV2Row(table, value)..remove('deletedAt');
    return jsonEncode(_canonicalize(canonical));
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonicalize(value[key])};
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}

enum ItemMergeKind { unchanged, local, remote, merged, conflict }

enum CollaborativeItemType { product, shoppingPlan, plannedItem }

enum CollaborativeReviewState { approved, rejected }

class ItemMergeResult {
  const ItemMergeResult({
    required this.kind,
    required this.item,
    this.local,
    this.remote,
    required this.reason,
  });

  final ItemMergeKind kind;
  final CollaborativeItem? item;
  final CollaborativeItem? local;
  final CollaborativeItem? remote;
  final String reason;
}

/// Three-way merge for a single item.
///
/// Tombstones always win over a live value with the same identity, which
/// prevents an old publication from resurrecting an owner deletion. A
/// concurrent edit of the same identity is never silently resolved.
class CollaborativeAreaMergeResult {
  const CollaborativeAreaMergeResult({
    required this.payload,
    required this.conflicts,
  });

  final Map<String, dynamic> payload;
  final List<ItemMergeResult> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
}

class CollaborativeAreaMerger {
  const CollaborativeAreaMerger({
    this.itemMerger = const CollaborativeItemMerger(),
  });

  static const collaborativeTables = {
    'products',
    'shoppingPlans',
    'plannedItems',
  };

  final CollaborativeItemMerger itemMerger;

  CollaborativeAreaMergeResult merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);
    final conflicts = <ItemMergeResult>[];
    for (final table in local.keys) {
      if (collaborativeTables.contains(table) || table == 'formatVersion') {
        continue;
      }
      if (_equivalentSemanticRows(table, local[table], remote[table])) {
        // The same history can have different local integer IDs on each
        // device. Keep the remote row identities while comparing the
        // meaningful content only.
        merged[table] = remote[table];
        continue;
      }
      if (jsonEncode(local[table]) != jsonEncode(remote[table])) {
        conflicts.add(
          const ItemMergeResult(
            kind: ItemMergeKind.conflict,
            item: null,
            reason: 'non_collaborative_area_changed',
          ),
        );
      }
    }
    for (final table in collaborativeTables) {
      final localRows = _rows(local[table]);
      final remoteRows = _rows(remote[table]);
      final duplicateIdentity = _duplicateSyncId(localRows, remoteRows, table);
      if (duplicateIdentity != null) {
        conflicts.add(duplicateIdentity);
        continue;
      }
      final duplicateLogicalKey = _duplicateLiveLogicalKey(
        localRows,
        remoteRows,
        table,
      );
      if (duplicateLogicalKey != null) {
        conflicts.add(duplicateLogicalKey);
        continue;
      }
      final localGroups = _group(localRows);
      final remoteGroups = _group(remoteRows);
      final keys = {...localGroups.keys, ...remoteGroups.keys};
      final output = <Map<String, dynamic>>[];
      for (final key in keys) {
        final localGroup = localGroups[key] ?? const [];
        final remoteGroup = remoteGroups[key] ?? const [];
        if (localGroup.length > 1 || remoteGroup.length > 1) {
          conflicts.add(
            ItemMergeResult(
              kind: ItemMergeKind.conflict,
              item: null,
              local: localGroup.isEmpty ? null : _item(localGroup.first, table),
              remote: remoteGroup.isEmpty
                  ? null
                  : _item(remoteGroup.first, table),
              reason: 'duplicate_logical_key',
            ),
          );
          continue;
        }
        final localItem = localGroup.isEmpty
            ? null
            : _item(localGroup.first, table);
        final remoteItem = remoteGroup.isEmpty
            ? null
            : _item(remoteGroup.first, table);
        final result = itemMerger.merge(local: localItem, remote: remoteItem);
        if (result.kind == ItemMergeKind.conflict) {
          conflicts.add(result);
        } else if (result.item != null) {
          output.add(result.item!.value);
        }
      }
      merged[table] = output;
    }
    return CollaborativeAreaMergeResult(payload: merged, conflicts: conflicts);
  }

  static bool _equivalentSemanticRows(
    String table,
    Object? localValue,
    Object? remoteValue,
  ) {
    List<String> canonicalRows(Object? value) =>
        _rows(value)
            .map((row) => syncV2CanonicalJson(canonicalSyncV2Row(table, row)))
            .toList()
          ..sort();

    final local = canonicalRows(localValue);
    final remote = canonicalRows(remoteValue);
    return local.length == remote.length &&
        List.generate(
          local.length,
          (index) => local[index] == remote[index],
        ).every((equal) => equal);
  }

  static List<Map<String, dynamic>> _rows(Object? value) => [
    for (final row in (value as List<Object?>? ?? const []))
      if (row is Map) Map<String, dynamic>.from(row),
  ];

  static Map<String, List<Map<String, dynamic>>> _group(
    List<Map<String, dynamic>> rows,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      // The stable identity wins. logicalKey is a semantic duplicate detector,
      // not the identity of a tombstone or of a later re-add.
      final key =
          row['syncId'] as String? ??
          row['logicalKey'] as String? ??
          'id:${row['id']}';
      groups.putIfAbsent(key, () => []).add(row);
    }
    return groups;
  }

  static ItemMergeResult? _duplicateLiveLogicalKey(
    List<Map<String, dynamic>> localRows,
    List<Map<String, dynamic>> remoteRows,
    String table,
  ) {
    final byLogicalKey = <String, List<Map<String, dynamic>>>{};
    for (final row in [...localRows, ...remoteRows]) {
      final logicalKey = row['logicalKey'] as String?;
      if (logicalKey == null || logicalKey.isEmpty || !_isLive(row)) continue;
      byLogicalKey.putIfAbsent(logicalKey, () => []).add(row);
    }
    for (final rows in byLogicalKey.values) {
      final syncIds = {
        for (final row in rows)
          if (row['syncId'] != null) row['syncId'] as String,
      };
      if (syncIds.length > 1) {
        return ItemMergeResult(
          kind: ItemMergeKind.conflict,
          item: null,
          local:
              rows.where((row) => localRows.contains(row)).firstOrNull == null
              ? null
              : _item(rows.first, table),
          remote:
              rows.where((row) => remoteRows.contains(row)).firstOrNull == null
              ? null
              : _item(rows.last, table),
          reason: 'duplicate_logical_key',
        );
      }
    }
    return null;
  }

  static bool _isLive(Map<String, dynamic> row) =>
      row['deletedAt'] == null &&
      row['isRemoved'] != true &&
      row['reviewState'] != 'rejected';

  static ItemMergeResult? _duplicateSyncId(
    List<Map<String, dynamic>> localRows,
    List<Map<String, dynamic>> remoteRows,
    String table,
  ) {
    final localBySyncId = <String, Map<String, dynamic>>{};
    for (final row in localRows) {
      final syncId = row['syncId'] as String?;
      if (syncId == null) continue;
      final existing = localBySyncId[syncId];
      if (existing != null && existing['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(existing, row, table);
      }
      localBySyncId[syncId] = row;
    }
    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final row in remoteRows) {
      final syncId = row['syncId'] as String?;
      if (syncId == null) continue;
      final existing = remoteBySyncId[syncId];
      if (existing != null && existing['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(existing, row, table);
      }
      remoteBySyncId[syncId] = row;
      final local = localBySyncId[syncId];
      if (local != null && local['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(local, row, table);
      }
    }
    return null;
  }

  static ItemMergeResult _duplicateSyncIdConflict(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
    String table,
  ) => ItemMergeResult(
    kind: ItemMergeKind.conflict,
    item: null,
    local: _item(first, table),
    remote: _item(second, table),
    reason: 'duplicate_sync_id',
  );

  static CollaborativeItem _item(Map<String, dynamic> row, String table) =>
      CollaborativeItem.fromJson(row, table: table);
}

class CollaborativeIdentityNormalizer {
  const CollaborativeIdentityNormalizer._();

  /// Reuses local integer IDs for the same stable identity and remaps remote
  /// rows whose local IDs collide. References are updated by stable identity.
  static Map<String, dynamic> normalize(
    Map<String, dynamic> local,
    Map<String, dynamic> merged,
  ) {
    final result = Map<String, dynamic>.from(merged);
    final productIds = _normalizeTable(local, result, 'products');
    final planIds = _normalizeTable(local, result, 'shoppingPlans');
    final itemIds = _normalizeTable(local, result, 'plannedItems');

    final rows = _rows(result['plannedItems']);
    for (final row in rows) {
      var planSyncId = row['planSyncId'] as String?;
      var productSyncId = row['productSyncId'] as String?;
      final logicalKey = row['logicalKey'] as String?;
      if ((planSyncId == null || productSyncId == null) && logicalKey != null) {
        for (final planEntry in planIds.entries) {
          for (final productEntry in productIds.entries) {
            if (logicalKey ==
                CollaborationMetadata.plannedItemLogicalKey(
                  planSyncId: planEntry.key,
                  productSyncId: productEntry.key,
                )) {
              planSyncId = planEntry.key;
              productSyncId = productEntry.key;
              break;
            }
          }
          if (planSyncId != null && productSyncId != null) break;
        }
      }
      final planId = planIds[planSyncId];
      final productId = productIds[productSyncId];
      if (planId != null) row['planId'] = planId;
      if (productId != null) row['productId'] = productId;
    }
    result['plannedItems'] = rows;

    final entries = _rows(result['importEntries']);
    for (final row in entries) {
      final productSyncId = row['productSyncId'] as String?;
      final productId = productIds[productSyncId];
      if (productId != null) row['productId'] = productId;
    }
    result['importEntries'] = entries;

    final lines = _rows(result['purchaseLines']);
    for (final row in lines) {
      final productSyncId = row['productSyncId'] as String?;
      final plannedItemSyncId = row['plannedItemSyncId'] as String?;
      final productId = productIds[productSyncId];
      final plannedItemId = itemIds[plannedItemSyncId];
      if (productId != null) row['productId'] = productId;
      if (plannedItemId != null) row['plannedItemId'] = plannedItemId;
    }
    result['purchaseLines'] = lines;
    return result;
  }

  static Map<String, int?> _normalizeTable(
    Map<String, dynamic> local,
    Map<String, dynamic> merged,
    String table,
  ) {
    final localRows = _rows(local[table]);
    final mergedRows = _rows(merged[table]);
    final localIdBySyncId = <String, int>{};
    final localSyncIdById = <int, String>{};
    for (final row in localRows) {
      final id = _integer(row['id']);
      final syncId = row['syncId'] as String?;
      if (id != null && syncId != null) {
        localIdBySyncId[syncId] = id;
        localSyncIdById[id] = syncId;
      }
    }
    final usedIds = <int>{...localSyncIdById.keys};
    var nextId =
        (usedIds.isEmpty ? 0 : usedIds.reduce((a, b) => a > b ? a : b)) + 1;
    final idsBySyncId = <String, int?>{};
    for (final row in mergedRows) {
      final syncId = row['syncId'] as String?;
      final currentId = _integer(row['id']);
      int assignedId;
      if (syncId != null && localIdBySyncId.containsKey(syncId)) {
        assignedId = localIdBySyncId[syncId]!;
      } else if (currentId != null &&
          !usedIds.contains(currentId) &&
          (localSyncIdById[currentId] == null ||
              localSyncIdById[currentId] == syncId)) {
        assignedId = currentId;
      } else {
        while (usedIds.contains(nextId)) {
          nextId++;
        }
        assignedId = nextId++;
      }
      usedIds.add(assignedId);
      row['id'] = assignedId;
      if (syncId != null) idsBySyncId[syncId] = assignedId;
    }
    merged[table] = mergedRows;
    return idsBySyncId;
  }

  static int? _integer(Object? value) => value is int ? value : null;

  static List<Map<String, dynamic>> _rows(Object? value) => [
    for (final row in (value as List<Object?>? ?? const []))
      if (row is Map) Map<String, dynamic>.from(row),
  ];
}

class CollaborativeItemMerger {
  const CollaborativeItemMerger();

  ItemMergeResult merge({
    CollaborativeItem? base,
    CollaborativeItem? local,
    CollaborativeItem? remote,
  }) {
    if (local == null && remote == null) {
      return const ItemMergeResult(
        kind: ItemMergeKind.unchanged,
        item: null,
        reason: 'item_absent',
      );
    }
    if (local == null) {
      return ItemMergeResult(
        kind: ItemMergeKind.remote,
        item: remote,
        remote: remote,
        reason: 'added_remotely',
      );
    }
    if (remote == null) {
      return ItemMergeResult(
        kind: ItemMergeKind.local,
        item: local,
        local: local,
        reason: 'added_locally',
      );
    }

    if (local.syncId != remote.syncId) {
      return ItemMergeResult(
        kind: ItemMergeKind.conflict,
        item: null,
        local: local,
        remote: remote,
        reason: 'duplicate_logical_key',
      );
    }

    if (remote.isTombstone && !local.isTombstone) {
      return ItemMergeResult(
        kind: ItemMergeKind.remote,
        item: remote,
        local: local,
        remote: remote,
        reason: 'tombstone_prevents_resurrection',
      );
    }
    if (local.isTombstone && !remote.isTombstone) {
      return ItemMergeResult(
        kind: ItemMergeKind.local,
        item: local,
        local: local,
        remote: remote,
        reason: 'local_tombstone',
      );
    }

    final localChanged =
        base != null && local._stableValue != base._stableValue;
    final remoteChanged =
        base != null && remote._stableValue != base._stableValue;
    if (local._stableValue == remote._stableValue) {
      return ItemMergeResult(
        kind: ItemMergeKind.merged,
        item: local.revision >= remote.revision ? local : remote,
        local: local,
        remote: remote,
        reason: 'same_value',
      );
    }
    if (base == null) {
      return ItemMergeResult(
        kind: ItemMergeKind.conflict,
        item: null,
        local: local,
        remote: remote,
        reason: 'same_item_changed_without_base',
      );
    }
    if (!localChanged && remoteChanged) {
      return ItemMergeResult(
        kind: ItemMergeKind.remote,
        item: remote,
        local: local,
        remote: remote,
        reason: 'changed_remotely',
      );
    }
    if (localChanged && !remoteChanged) {
      return ItemMergeResult(
        kind: ItemMergeKind.local,
        item: local,
        local: local,
        remote: remote,
        reason: 'changed_locally',
      );
    }
    if (local.revision != remote.revision) {
      return ItemMergeResult(
        kind: ItemMergeKind.conflict,
        item: null,
        local: local,
        remote: remote,
        reason: 'concurrent_revision',
      );
    }
    return ItemMergeResult(
      kind: ItemMergeKind.conflict,
      item: null,
      local: local,
      remote: remote,
      reason: 'concurrent_edit',
    );
  }
}
