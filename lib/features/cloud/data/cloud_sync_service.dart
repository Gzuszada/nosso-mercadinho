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

  Future<CloudSyncStatus> inspectStatus(String householdId) async {
    final settings = await settingsRepository.getCloudSyncSettings();
    final localPayload = await CloudSnapshotService(database)
        .readLocalPayload();
    final baseHashes = _decodeHashes(settings?.lastSyncedHash);
    final remoteMetadata = await _readMetadata(householdId);
    final areas = <CloudSyncConflictArea, CloudSyncAreaStatus>{};

    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      final localHash = CloudSnapshot.hashPayload(localArea);
      final remote = await _tryReadArea(householdId, area);
      final remoteHash = remote.payload == null
          ? null
          : CloudSnapshot.hashPayload(selectArea(remote.payload!, area));
      final baseHash = baseHashes[area.name];
      final state = _stateFor(
        localHash: localHash,
        remoteHash: remoteHash,
        baseHash: baseHash,
        remoteError: remote.error,
      );
      areas[area] = CloudSyncAreaStatus(
        area: area,
        state: state,
        localCounts: _counts(localArea, area),
        remoteCounts: remote.payload == null
            ? const CloudAreaCounts({})
            : _counts(selectArea(remote.payload!, area), area),
        localHash: localHash,
        remoteHash: remoteHash,
        message: remote.error,
      );
    }

    return CloudSyncStatus(
      householdId: householdId,
      remoteRevision: remoteMetadata.revision,
      areas: areas,
    );
  }

  Future<CloudSyncResult> synchronize({
    required String householdId,
    Map<CloudSyncConflictArea, CloudSyncResolution>? resolutions,
  }) async {
    final settings = await settingsRepository.getCloudSyncSettings();
    var localPayload = await CloudSnapshotService(database).readLocalPayload();
    final baseHashes = _decodeHashes(settings?.lastSyncedHash);
    final remoteMetadata = await _readMetadata(householdId);
    final remoteHashes = remoteMetadata.hashes;
    final resolved = resolutions ?? const {};

    var pulled = false;
    var pushed = false;
    var revision = remoteMetadata.revision;
    final newHashes = Map<String, String?>.of(baseHashes);
    final newRemoteHashes = Map<String, String?>.of(remoteHashes);

    // A resolution for one area represents the user's choice for the whole
    // house. Apply every area from that same source so the local database is
    // restored atomically and products/categories remain consistent with
    // shopping and import records.
    if (resolved.isNotEmpty) {
      final source = resolved.values.first.source;
      for (final area in _areas.keys) {
        final localArea = selectArea(localPayload, area);
        Map<String, dynamic> chosen;
        if (resolved.containsKey(area)) {
          chosen = selectArea(resolved[area]!.payload, area);
        } else {
          final remote = await _tryReadArea(householdId, area);
          if (remote.error != null && remote.present) {
            throw StateError(
              'A área remota "${area.label}" está inválida: ${remote.error}',
            );
          }
          chosen = remote.payload == null
              ? localArea
              : selectArea(remote.payload!, area);
        }
        _validateArea(chosen, area);
        if (source == CloudSyncResolutionSource.remote) {
          localPayload = mergeArea(localPayload, area, chosen);
        } else {
          await _writeArea(householdId, area, chosen);
          revision += 1;
        }
        final chosenHash = CloudSnapshot.hashPayload(chosen);
        newHashes[area.name] = chosenHash;
        newRemoteHashes[area.name] = chosenHash;
      }
      if (source == CloudSyncResolutionSource.remote) {
        await CloudSnapshotService(database).restoreRemotePayload(localPayload);
        pulled = true;
      } else {
        pushed = true;
      }
      await _persistState(
        householdId: householdId,
        revision: revision,
        hashes: newRemoteHashes,
        localHashes: newHashes,
      );
      return CloudSyncResult(
        pulled: pulled,
        pushed: pushed,
        revision: revision,
      );
    }

    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      final localHash = CloudSnapshot.hashPayload(localArea);
      final baseHash = baseHashes[area.name];
      final remote = await _tryReadArea(householdId, area);
      final remotePayload = remote.payload;
      final remoteHash = remotePayload == null
          ? null
          : CloudSnapshot.hashPayload(selectArea(remotePayload, area));

      if (remote.error != null && remote.present) {
        throw StateError(
          'A área remota "${area.label}" está inválida: ${remote.error}',
        );
      }
      if (remotePayload != null) {
        _validateArea(selectArea(remotePayload, area), area);
      }

      final localChanged = baseHash == null || baseHash != localHash;
      final remoteChanged = remoteHash != baseHash;
      if (baseHash == null) {
        await _writeArea(householdId, area, localArea);
        revision += 1;
        newHashes[area.name] = localHash;
        newRemoteHashes[area.name] = localHash;
        pushed = true;
        continue;
      }
      if (remoteHash == null) {
        await _writeArea(householdId, area, localArea);
        revision += 1;
        newHashes[area.name] = localHash;
        newRemoteHashes[area.name] = localHash;
        pushed = true;
        continue;
      }
      if (remoteHash == localHash) {
        newHashes[area.name] = localHash;
        newRemoteHashes[area.name] = localHash;
        continue;
      }
      if (localChanged && remoteChanged) {
        await _persistState(
          householdId: householdId,
          revision: revision,
          hashes: newRemoteHashes,
          localHashes: newHashes,
        );
        throw CloudSyncConflictException(
          CloudSyncConflict(
            area: area,
            localPayload: localArea,
            remotePayload: remotePayload!,
            remoteRevision: revision,
          ),
        );
      }
      if (remoteChanged && !localChanged) {
        final chosen = selectArea(remotePayload!, area);
        localPayload = mergeArea(localPayload, area, chosen);
        await CloudSnapshotService(database).restoreRemotePayload(localPayload);
        newHashes[area.name] = remoteHash;
        newRemoteHashes[area.name] = remoteHash;
        pulled = true;
        continue;
      }
      await _writeArea(householdId, area, localArea);
      revision += 1;
      newHashes[area.name] = localHash;
      newRemoteHashes[area.name] = localHash;
      pushed = true;
    }

    await _persistState(
      householdId: householdId,
      revision: revision,
      hashes: newRemoteHashes,
      localHashes: newHashes,
    );
    return CloudSyncResult(pulled: pulled, pushed: pushed, revision: revision);
  }

  /// Reads one complete remote area for an explicit whole-house resolution.
  Future<Map<String, dynamic>> readRemoteArea({
    required String householdId,
    required CloudSyncConflictArea area,
  }) async {
    final remote = await _tryReadArea(householdId, area);
    if (remote.payload == null) {
      throw StateError('A área remota "${area.label}" não está disponível.');
    }
    final selected = selectArea(remote.payload!, area);
    _validateArea(selected, area);
    return selected;
  }

  /// Publishes all three local areas, including empty areas.
  ///
  /// This is the explicit "send everything from this device" action shown by
  /// the synchronization status screen. It never silently replaces the remote
  /// data because the caller must explicitly request it.
  Future<CloudSyncResult> publishAllLocalAreas({
    required String householdId,
  }) async {
    final localPayload = await CloudSnapshotService(database)
        .readLocalPayload();
    final metadata = await _readMetadata(householdId);
    final revision = metadata.revision + 1;
    final hashes = Map<String, String?>.of(metadata.hashes);
    final localHashes = _decodeHashes(
      (await settingsRepository.getCloudSyncSettings())?.lastSyncedHash,
    );
    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      await _writeArea(householdId, area, localArea);
      final hash = CloudSnapshot.hashPayload(localArea);
      hashes[area.name] = hash;
      localHashes[area.name] = hash;
    }
    await _persistState(
      householdId: householdId,
      revision: revision,
      hashes: hashes,
      localHashes: localHashes,
    );
    return CloudSyncResult(pulled: false, pushed: true, revision: revision);
  }

  /// Publishes the current local contents of one area, including an empty area.
  ///
  /// This is used by a connected reset so deletions are propagated to other
  /// devices instead of being interpreted as "nothing changed".
  Future<CloudSyncResult> publishLocalArea({
    required String householdId,
    required CloudSyncConflictArea area,
  }) async {
    final localPayload = await CloudSnapshotService(database)
        .readLocalPayload();
    final localArea = selectArea(localPayload, area);
    _validateArea(localArea, area);
    final metadata = await _readMetadata(householdId);
    final revision = metadata.revision + 1;
    await _writeArea(householdId, area, localArea);
    final hashes = Map<String, String?>.of(metadata.hashes);
    final localHashes = _decodeHashes(
      (await settingsRepository.getCloudSyncSettings())?.lastSyncedHash,
    );
    final hash = CloudSnapshot.hashPayload(localArea);
    hashes[area.name] = hash;
    localHashes[area.name] = hash;
    await _persistState(
      householdId: householdId,
      revision: revision,
      hashes: hashes,
      localHashes: localHashes,
    );
    return CloudSyncResult(pulled: false, pushed: true, revision: revision);
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
    _validateArea(payload, area);
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
          'counts': _counts(payload, area).values,
          'complete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<_RemoteArea> _tryReadArea(
    String householdId,
    CloudSyncConflictArea area,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('tables')
          .doc(area.name)
          .get();
      if (!snapshot.exists) {
        return const _RemoteArea();
      }
      final data = snapshot.data();
      if (data == null || data['payload'] is! Map) {
        return const _RemoteArea(
          present: true,
          error: 'O documento remoto não contém um payload válido.',
        );
      }
      final payload = Map<String, dynamic>.from(data['payload'] as Map);
      try {
        _validateArea(selectArea(payload, area), area);
        return _RemoteArea(payload: payload, present: true);
      } on Object catch (error) {
        return _RemoteArea(present: true, error: error.toString());
      }
    } on Object catch (error) {
      return _RemoteArea(present: false, error: error.toString());
    }
  }

  Future<_RemoteMetadata> _readMetadata(String householdId) async {
    final snapshot = await _firestore
        .collection('households')
        .doc(householdId)
        .collection('metadata')
        .doc('sync')
        .get();
    final data = snapshot.data();
    return _RemoteMetadata(
      revision: (data?['revision'] as int?) ?? 0,
      hashes: _decodeHashes(data?['hashes'] as String?),
    );
  }

  static void _validateArea(
    Map<String, dynamic> payload,
    CloudSyncConflictArea area,
  ) {
    for (final key in _areas[area]!) {
      if (!payload.containsKey(key) || payload[key] is! List) {
        throw FormatException('A área "${area.label}" está incompleta: $key.');
      }
    }
    final formatVersion = payload['formatVersion'];
    if (formatVersion is! int || formatVersion < 1 || formatVersion > 6) {
      throw const FormatException(
        'A área remota usa uma versão de backup inválida.',
      );
    }
  }

  static CloudAreaCounts _counts(
    Map<String, dynamic> payload,
    CloudSyncConflictArea area,
  ) {
    return CloudAreaCounts({
      for (final key in _areas[area]!)
        key: (payload[key] as List? ?? const []).length,
    });
  }

  static CloudSyncAreaState _stateFor({
    required String localHash,
    required String? remoteHash,
    required String? baseHash,
    required String? remoteError,
  }) {
    if (remoteError != null) return CloudSyncAreaState.invalid;
    if (remoteHash == null) return CloudSyncAreaState.localOnly;
    if (remoteHash == localHash) return CloudSyncAreaState.inSync;
    return CloudSyncAreaState.divergent;
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

class _RemoteArea {
  const _RemoteArea({this.payload, this.error, this.present = false});

  final Map<String, dynamic>? payload;
  final String? error;
  final bool present;
}

class _RemoteMetadata {
  const _RemoteMetadata({required this.revision, required this.hashes});

  final int revision;
  final Map<String, String?> hashes;
}

class CloudSyncConflictException implements Exception {
  const CloudSyncConflictException(this.conflict);

  final CloudSyncConflict conflict;

  @override
  String toString() =>
      'Conflito de sincronização em ${conflict.area.label} '
      '(local=${CloudSnapshot.hashPayload(conflict.localPayload)}, '
      'remote=${CloudSnapshot.hashPayload(conflict.remotePayload)}, '
      'revision=${conflict.remoteRevision}).';
}
