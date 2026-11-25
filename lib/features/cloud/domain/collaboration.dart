import 'dart:convert';
import 'dart:math';

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
  });

  factory CollaborativeItem.fromJson(Map<String, dynamic> json) {
    final deletedAt = json['deletedAt'];
    return CollaborativeItem(
      syncId: json['syncId'] as String? ?? '',
      logicalKey: json['logicalKey'] as String? ?? '',
      revision: (json['syncRevision'] as num?)?.toInt() ?? 0,
      deletedAt: deletedAt is String ? DateTime.tryParse(deletedAt) : null,
      value: json,
    );
  }

  final String syncId;
  final String logicalKey;
  final int revision;
  final DateTime? deletedAt;
  final Map<String, dynamic> value;

  bool get isTombstone => deletedAt != null;

  String get _stableValue => jsonEncode(_withoutVolatileMergeFields(value));

  Map<String, dynamic> _withoutVolatileMergeFields(
    Map<String, dynamic> source,
  ) {
    return Map<String, dynamic>.from(source)
      ..remove('id')
      ..remove('syncRevision')
      ..remove('deletedAt');
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
      final duplicateIdentity = _duplicateSyncId(localRows, remoteRows);
      if (duplicateIdentity != null) {
        conflicts.add(duplicateIdentity);
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
              local: localGroup.isEmpty ? null : _item(localGroup.first),
              remote: remoteGroup.isEmpty ? null : _item(remoteGroup.first),
              reason: 'duplicate_logical_key',
            ),
          );
          continue;
        }
        final localItem = localGroup.isEmpty ? null : _item(localGroup.first);
        final remoteItem = remoteGroup.isEmpty
            ? null
            : _item(remoteGroup.first);
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

  static List<Map<String, dynamic>> _rows(Object? value) => [
    for (final row in (value as List<Object?>? ?? const []))
      if (row is Map) Map<String, dynamic>.from(row),
  ];

  static Map<String, List<Map<String, dynamic>>> _group(
    List<Map<String, dynamic>> rows,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final key =
          row['logicalKey'] as String? ??
          row['syncId'] as String? ??
          'id:${row['id']}';
      groups.putIfAbsent(key, () => []).add(row);
    }
    return groups;
  }

  static ItemMergeResult? _duplicateSyncId(
    List<Map<String, dynamic>> localRows,
    List<Map<String, dynamic>> remoteRows,
  ) {
    final localBySyncId = <String, Map<String, dynamic>>{};
    for (final row in localRows) {
      final syncId = row['syncId'] as String?;
      if (syncId == null) continue;
      final existing = localBySyncId[syncId];
      if (existing != null && existing['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(existing, row);
      }
      localBySyncId[syncId] = row;
    }
    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final row in remoteRows) {
      final syncId = row['syncId'] as String?;
      if (syncId == null) continue;
      final existing = remoteBySyncId[syncId];
      if (existing != null && existing['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(existing, row);
      }
      remoteBySyncId[syncId] = row;
      final local = localBySyncId[syncId];
      if (local != null && local['logicalKey'] != row['logicalKey']) {
        return _duplicateSyncIdConflict(local, row);
      }
    }
    return null;
  }

  static ItemMergeResult _duplicateSyncIdConflict(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) => ItemMergeResult(
    kind: ItemMergeKind.conflict,
    item: null,
    local: _item(first),
    remote: _item(second),
    reason: 'duplicate_sync_id',
  );

  static CollaborativeItem _item(Map<String, dynamic> row) =>
      CollaborativeItem.fromJson(row);
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
