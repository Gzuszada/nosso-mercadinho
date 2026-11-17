import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/app_database.dart';
import '../../settings/data/settings_repository.dart';
import 'cloud_models.dart';
import 'cloud_snapshot_service.dart';

class CloudSyncService {
  CloudSyncService({
    required this.database,
    required this.settingsRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _areas = {
    CloudSyncConflictArea.catalog: ['categories', 'subcategories', 'products'],
    CloudSyncConflictArea.imports: ['importBatches', 'importEntries'],
    CloudSyncConflictArea.shopping: [
      'shoppingPlans',
      'plannedItems',
      'shoppingTrips',
      'purchaseLines',
    ],
  };

  final AppDatabase database;
  final SettingsRepository settingsRepository;
  final FirebaseFirestore _firestore;

  Future<CloudSyncResult> synchronize({
    required String householdId,
    Map<CloudSyncConflictArea, CloudSyncResolution>? resolutions,
  }) async {
    final settings = await settingsRepository.getCloudSyncSettings();
    var localPayload = await CloudSnapshotService(database).readLocalPayload();
    final baseHashes = _decodeHashes(settings?.lastSyncedHash);
    final remoteMetadata = await _firestore
        .collection('households')
        .doc(householdId)
        .collection('metadata')
        .doc('sync')
        .get();
    final remoteHashes = _decodeHashes(
      remoteMetadata.data()?['hashes'] as String?,
    );
    final remoteRevision = (remoteMetadata.data()?['revision'] as int?) ?? 0;
    final resolved = resolutions ?? const {};

    var pulled = false;
    var pushed = false;
    final newHashes = Map<String, String?>.of(baseHashes);
    final newRemoteHashes = Map<String, String?>.of(remoteHashes);

    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      final localHash = CloudSnapshot.hashPayload(localArea);
      final baseHash = baseHashes[area.name];
      final remoteHash = remoteHashes[area.name];

      if (resolved.containsKey(area)) {
        final resolution = resolved[area]!;
        final chosen = resolution.payload;
        if (resolution.source == CloudSyncResolutionSource.remote) {
          localPayload = mergeArea(localPayload, area, chosen);
          await CloudSnapshotService(database)
              .restoreRemotePayload(localPayload);
          pulled = true;
        } else {
          await _writeArea(householdId, area, chosen);
          pushed = true;
        }
        newHashes[area.name] = CloudSnapshot.hashPayload(chosen);
        newRemoteHashes[area.name] = CloudSnapshot.hashPayload(chosen);
        continue;
      }

      final localChanged = baseHash == null || baseHash != localHash;
      final remoteChanged = remoteHash == null || remoteHash != baseHash;
      if (remoteHash != null && remoteHash == localHash) {
        newHashes[area.name] = localHash;
        newRemoteHashes[area.name] = localHash;
        continue;
      }
      if (localChanged && remoteChanged && remoteHash != null) {
        await _persistState(
          householdId: householdId,
          revision: remoteRevision + (pushed ? 1 : 0),
          hashes: newRemoteHashes,
          localHashes: newHashes,
        );
        throw CloudSyncConflictException(
          CloudSyncConflict(
            area: area,
            localPayload: localArea,
            remotePayload: await _readArea(householdId, area),
            remoteRevision: remoteRevision,
          ),
        );
      }
      if (remoteChanged && !localChanged && remoteHash != null) {
        final remotePayload = await _readArea(householdId, area);
        await CloudSnapshotService(database)
            .restoreRemotePayload(mergeArea(localPayload, area, remotePayload));
        newHashes[area.name] = remoteHash;
        newRemoteHashes[area.name] = remoteHash;
        pulled = true;
        continue;
      }
      await _writeArea(householdId, area, localArea);
      newHashes[area.name] = localHash;
      newRemoteHashes[area.name] = localHash;
      pushed = true;
    }

    final revision = remoteRevision + (pushed ? 1 : 0);
    await _persistState(
      householdId: householdId,
      revision: revision,
      hashes: newRemoteHashes,
      localHashes: newHashes,
    );
    return CloudSyncResult(pulled: pulled, pushed: pushed, revision: revision);
  }

  Future<void> _persistState({
    required String householdId,
    required int revision,
    required Map<String, String?> hashes,
    required Map<String, String?> localHashes,
  }) async {
    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('metadata')
        .doc('sync')
        .set({
          'revision': revision,
          'hashes': jsonEncode(hashes),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    await settingsRepository.saveCloudSyncSettings(
      householdId: householdId,
      remoteRevision: revision,
      lastSyncedHash: jsonEncode(localHashes),
    );
  }

  Future<void> _writeArea(
    String householdId,
    CloudSyncConflictArea area,
    Map<String, dynamic> payload,
  ) async {
    final encoded = jsonEncode(payload);
    if (encoded.length > 900000) {
      throw const FormatException(
        'A área sincronizada excede o limite do Firestore. Divida os dados e tente novamente.',
      );
    }
    await _firestore
        .collection('households')
        .doc(householdId)
        .collection('tables')
        .doc(area.name)
        .set({
          'payload': payload,
          'hash': CloudSnapshot.hashPayload(payload),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<Map<String, dynamic>> _readArea(
    String householdId,
    CloudSyncConflictArea area,
  ) async {
    final snapshot = await _firestore
        .collection('households')
        .doc(householdId)
        .collection('tables')
        .doc(area.name)
        .get();
    final data = snapshot.data();
    if (data == null || data['payload'] is! Map) {
      throw StateError('A área remota "${area.name}" não está disponível.');
    }
    return Map<String, dynamic>.from(data['payload'] as Map);
  }

  static List<String> areaKeys(CloudSyncConflictArea area) =>
      List.unmodifiable(_areas[area]!);

  static Map<String, dynamic> selectArea(
    Map<String, dynamic> payload,
    CloudSyncConflictArea area,
  ) => {
    for (final key in _areas[area]!) key: payload[key],
    'formatVersion': payload['formatVersion'],
  };

  static Map<String, dynamic> mergeArea(
    Map<String, dynamic> payload,
    CloudSyncConflictArea area,
    Map<String, dynamic> replacement,
  ) => {...payload, for (final key in _areas[area]!) key: replacement[key]};

  static Map<String, String?> _decodeHashes(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String?));
  }
}

class CloudSyncConflictException implements Exception {
  const CloudSyncConflictException(this.conflict);

  final CloudSyncConflict conflict;

  @override
  String toString() => 'Conflito de sincronização em ${conflict.area.label}.';
}
