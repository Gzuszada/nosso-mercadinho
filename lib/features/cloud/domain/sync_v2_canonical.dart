/// Canonical representation of the timestamps exchanged by the sync v2
/// protocol.
///
/// The local database and the published payload can describe the very same
/// instant with different strings: the database keeps local time without a
/// timezone marker and truncates the millisecond fraction, while the owner
/// decisions are stored in UTC with full precision. Comparing those strings
/// directly makes two identical states look different, which shows up as a
/// false "not equal to Firebase" indicator and as a false conflict during the
/// merge.
///
/// Every timestamp is therefore normalized to UTC with whole-second precision
/// before it is serialized, compared, merged or restored.
library;

import 'dart:convert';

/// Payload fields that carry an instant.
const syncV2TimestampFields = <String>{
  'createdAt',
  'updatedAt',
  'reviewedAt',
  'deletedAt',
  'importedAt',
  'completedAt',
};

/// Truncates [value] to whole seconds in UTC.
///
/// The database stores instants with second precision, so this is the finest
/// precision that survives a round-trip through the local database.
DateTime canonicalSyncV2Instant(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
  );
}

/// Formats [value] as a canonical instant, for example
/// `2026-11-25T21:56:11.000Z`.
String canonicalSyncV2Timestamp(DateTime value) =>
    canonicalSyncV2Instant(value).toIso8601String();

/// Reads an instant from a payload value and normalizes it.
///
/// Returns `null` when the value is not a recognizable instant, so fields
/// that only look like a date (such as the date-only `purchaseDate`) are
/// preserved untouched.
DateTime? canonicalSyncV2ParsedInstant(Object? value) {
  final parsed = switch (value) {
    DateTime date => date,
    String text => DateTime.tryParse(text),
    _ => null,
  };
  if (parsed == null) return null;
  return canonicalSyncV2Instant(parsed);
}

/// Normalizes every timestamp of a single payload row.
Map<String, dynamic> canonicalizeSyncV2Row(Map<String, dynamic> row) {
  final result = Map<String, dynamic>.from(row);
  for (final field in syncV2TimestampFields) {
    if (!result.containsKey(field)) continue;
    final value = result[field];
    if (value == null) continue;
    final canonical = canonicalSyncV2ParsedInstant(value);
    if (canonical != null) result[field] = canonical.toIso8601String();
  }
  return result;
}

/// Normalizes every timestamp of a payload.
Map<String, dynamic> canonicalizeSyncV2Payload(Map<String, dynamic> payload) {
  final result = <String, dynamic>{};
  for (final entry in payload.entries) {
    final value = entry.value;
    if (value is List) {
      result[entry.key] = value
          .map(
            (row) => row is Map
                ? canonicalizeSyncV2Row(Map<String, dynamic>.from(row))
                : row,
          )
          .toList();
      continue;
    }
    result[entry.key] = value;
  }
  return result;
}

/// Canonical JSON of any payload value.
///
/// The keys are sorted, so the representation does not depend on the order
/// used when the payload was reconstructed.
String syncV2CanonicalJson(Object? value) => jsonEncode(_canonicalize(value));

/// Compares two payloads by content.
///
/// Key order and the textual representation of the timestamps are ignored,
/// because they describe the same data. Every other difference is real and
/// keeps the payloads different.
bool syncV2PayloadsSemanticallyEqual(
  Map<String, dynamic> left,
  Map<String, dynamic> right,
) =>
    syncV2CanonicalJson(canonicalizeSyncV2Payload(left)) ==
    syncV2CanonicalJson(canonicalizeSyncV2Payload(right));

/// Fields that only exist on one device.
///
/// The integer primary keys and their references are numbered independently
/// by each device, and `syncRevision` is a counter that each device advances
/// on its own. None of them describes the content of the row.
///
/// `updatedAt` records when a device last wrote the row, so two devices that
/// hold the same content can legitimately show different values.
///
/// The category of a product and the plan of a purchase are also described by
/// local integers. The payload does not carry a stable identifier for them,
/// so they are ignored as well: a difference there is reported by the change
/// of the category itself, never by the number the device happened to use.
const syncV2DeviceLocalFields = <String, Set<String>>{
  'categories': {'id', 'updatedAt'},
  'subcategories': {'id', 'categoryId', 'updatedAt'},
  'products': {
    'id',
    'categoryId',
    'subcategoryId',
    'syncRevision',
    'updatedAt',
  },
  'importBatches': {'id', 'updatedAt'},
  'importEntries': {'id', 'batchId', 'productId'},
  'shoppingPlans': {'id', 'syncRevision', 'updatedAt'},
  'plannedItems': {
    'id',
    'planId',
    'productId',
    'syncRevision',
    'updatedAt',
    'estimateReferenceTripId',
  },
  'shoppingTrips': {'id', 'planId', 'updatedAt'},
  'purchaseLines': {'id', 'tripId', 'productId', 'plannedItemId', 'updatedAt'},
};

/// Tables whose rows carry a stable identity across devices.
const syncV2IdentityTables = {'products', 'shoppingPlans', 'plannedItems'};

/// Tables that carry data in every payload.
const syncV2Tables = <String>[
  'categories',
  'subcategories',
  'products',
  'importBatches',
  'importEntries',
  'shoppingPlans',
  'plannedItems',
  'shoppingTrips',
  'purchaseLines',
];

/// Prefix of the stored key that holds the semantic base hash of an area.
///
/// The legacy byte hash of an area keeps its own key, so a device that
/// alternates between the old and the new comparison still finds a usable
/// base and never mixes two different meanings in the same entry.
const syncV2SemanticBaseKeyPrefix = 'semantic:';

/// Canonical description of an area, independent of the device that wrote it.
///
/// The rows are matched by their stable identity when the table has one, and
/// as an unordered set otherwise. The timestamps are normalized and the
/// device-local fields are ignored, so two devices that hold the same data
/// describe the same area even when the identifiers, the revision counters
/// and the textual representation of the instants differ.
///
/// This is the single definition used by the comparison, by the merge and by
/// the stored base hash. They must agree, otherwise a merged result would
/// still look different from the state it came from.
Map<String, dynamic> syncV2SemanticArea(Map<String, dynamic> area) {
  final result = <String, dynamic>{};
  for (final table in syncV2Tables) {
    final rows = _rows(area[table]);
    if (syncV2IdentityTables.contains(table)) {
      final byIdentity = <String, List<String>>{};
      for (final row in rows) {
        final identity = row['syncId'];
        final encoded = syncV2CanonicalJson(canonicalSyncV2Row(table, row));
        final key = identity is String && identity.isNotEmpty
            ? identity
            : encoded;
        (byIdentity[key] ??= <String>[]).add(encoded);
      }
      for (final values in byIdentity.values) {
        values.sort();
      }
      result[table] = byIdentity;
    } else {
      final encoded =
          rows
              .map((row) => syncV2CanonicalJson(canonicalSyncV2Row(table, row)))
              .toList()
            ..sort();
      result[table] = encoded;
    }
  }
  return result;
}

/// Compares two areas by content instead of by bytes.
///
/// Two areas are equal when they hold the same rows with the same content.
/// The timestamps are normalized and the device-local fields are ignored, so
/// the same state published by two devices is recognized as equal. Real
/// differences, such as a different quantity, a different review state or a
/// tombstone that exists only on one side, keep the areas different.
bool syncV2AreasSemanticallyEqual(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) =>
    syncV2CanonicalJson(syncV2SemanticArea(local)) ==
    syncV2CanonicalJson(syncV2SemanticArea(remote));

/// Canonical form of a single row of [table].
///
/// The timestamps are normalized and the device-local fields of the table are
/// removed, so the row describes the same content on every device. The keys
/// are sorted, so the order used by the database or by Firestore does not
/// change the result.
Map<String, dynamic> canonicalSyncV2Row(
  String table,
  Map<String, dynamic> row,
) {
  final ignored = syncV2DeviceLocalFields[table] ?? const <String>{};
  final result = canonicalizeSyncV2Row(Map<String, dynamic>.from(row))
    ..removeWhere((key, _) => ignored.contains(key));
  return {for (final key in result.keys.toList()..sort()) key: result[key]};
}

List<Map<String, dynamic>> _rows(Object? value) => [
  for (final row in (value as List<Object?>? ?? const []))
    if (row is Map) Map<String, dynamic>.from(row),
];

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
