import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/app_database.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/collaboration.dart';
import '../domain/sync_v2_canonical.dart';
import 'cloud_models.dart';
import 'cloud_snapshot_service.dart';
import 'sync_v2_candidate.dart';
import 'sync_v2_client.dart';
import 'sync_v2_review.dart';
import 'sync_diagnostics.dart';

class CloudSyncService {
  CloudSyncService({
    required this.database,
    required this.settingsRepository,
    FirebaseFirestore? firestore,
    this.syncV2Client,
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
  final SyncV2Client? syncV2Client;

  Future<CloudSyncStatus> inspectStatus(String householdId) async {
    if (syncV2Client != null) {
      return _inspectPilotStatus(householdId);
    }
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
    final previous = await _readDiagnostics(householdId);
    await _saveDiagnostics(
      householdId,
      CloudSyncDiagnostics(
        lastAttemptAt: DateTime.now().toUtc(),
        lastSuccessfulAt: previous?.lastSuccessfulAt,
        lastOrigin: previous?.lastOrigin,
        lastOriginAt: previous?.lastOriginAt,
        lastOriginAuthor: previous?.lastOriginAuthor,
        areaResults: previous?.areaResults ?? const {},
      ),
    );
    try {
      final result = await _synchronizeUntracked(
        householdId: householdId,
        resolutions: resolutions,
      );
      final areas = {for (final area in _areas.keys) area.name: 'inSync'};
      await _saveDiagnostics(
        householdId,
        CloudSyncDiagnostics(
          lastAttemptAt: DateTime.now().toUtc(),
          lastSuccessfulAt: DateTime.now().toUtc(),
          lastOrigin: const CloudSyncDiagnostics().publicationDeviceId,
          lastOriginAt: DateTime.now().toUtc(),
          outcome: CloudSyncAttemptOutcome.success,
          areaResults: areas,
        ),
      );
      return result;
    } on Object catch (error) {
      final kind = classifyCloudSyncFailure(error);
      final failedArea = error is CloudSyncConflictException
          ? error.conflict.area.name
          : 'all';
      await _saveDiagnostics(
        householdId,
        CloudSyncDiagnostics(
          lastAttemptAt: DateTime.now().toUtc(),
          lastSuccessfulAt: previous?.lastSuccessfulAt,
          lastOrigin: previous?.lastOrigin,
          lastOriginAt: previous?.lastOriginAt,
          lastOriginAuthor: previous?.lastOriginAuthor,
          outcome: CloudSyncAttemptOutcome.failure,
          failureKind: kind,
          failedArea: failedArea,
          message: _safeErrorMessage(error),
          areaResults: previous?.areaResults ?? const {},
        ),
      );
      rethrow;
    }
  }

  Future<CloudSyncResult> _synchronizeUntracked({
    required String householdId,
    Map<CloudSyncConflictArea, CloudSyncResolution>? resolutions,
  }) async {
    if (syncV2Client != null) {
      return _synchronizePilot(
        householdId,
        resolutions: resolutions ?? const {},
      );
    }
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
    if (syncV2Client != null) {
      final remote = await syncV2Client!.readCurrentState(householdId);
      if (remote == null) {
        throw StateError('A área remota "${area.label}" não está disponível.');
      }
      final payload = await syncV2Client!.readArea(
        householdId: householdId,
        area: area.name,
        manifest: remote.manifest,
      );
      // As decisões do owner são autoritativas: restaurar a casa inteira não
      // pode ressuscitar um item que o owner removeu.
      final reviews = await syncV2Client!.readReviews(householdId);
      final selected = selectArea(
        syncV2Client!.applyReviews(payload, reviews),
        area,
      );
      _validateArea(selected, area);
      return selected;
    }
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
    try {
      final result = await _publishAllLocalAreasUntracked(householdId);
      await _recordSuccessfulAttempt(householdId);
      return result;
    } on Object catch (error) {
      await _recordFailedAttempt(householdId, error);
      rethrow;
    }
  }

  Future<CloudSyncResult> _publishAllLocalAreasUntracked(
    String householdId,
  ) async {
    if (syncV2Client != null) {
      return _publishPilotAreas(householdId, null);
    }
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
    try {
      final result = await _publishLocalAreaUntracked(householdId, area);
      await _recordSuccessfulAttempt(householdId, synchronizedArea: area);
      return result;
    } on Object catch (error) {
      await _recordFailedAttempt(householdId, error);
      rethrow;
    }
  }

  Future<CloudSyncResult> _publishLocalAreaUntracked(
    String householdId,
    CloudSyncConflictArea area,
  ) async {
    if (syncV2Client != null) {
      return _publishPilotAreas(householdId, area);
    }
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

  Future<CloudSyncStatus> _inspectPilotStatus(String householdId) async {
    final client = syncV2Client!;
    final settings = await settingsRepository.getCloudSyncSettings();
    final localPayload = await CloudSnapshotService(database)
        .readLocalPayload();
    final baseHashes = _decodeHashes(settings?.lastSyncedHash);
    final remote = await client.readCurrentState(householdId);
    // As decisões do owner são autoritativas: o estado publicado pode ainda
    // carregar o item como pendente, mas ele já está removido para a casa.
    final reviews = await client.readReviews(householdId);
    final areas = <CloudSyncConflictArea, CloudSyncAreaStatus>{};
    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      final localHash = client.areaSemanticHash(localArea);
      final remoteManifest = remote?.manifest.areas[area.name];
      String? remoteHash;
      String? remoteError;
      Map<String, dynamic>? remoteAreaPayload;
      if (remoteManifest != null && remote != null) {
        try {
          final remoteArea = client.applyReviews(
            await client.readArea(
              householdId: householdId,
              area: area.name,
              manifest: remote.manifest,
            ),
            reviews,
          );
          remoteAreaPayload = remoteArea;
          remoteHash = client.areaSemanticHash(remoteArea);
        } on Object catch (error) {
          remoteError = error.toString();
        }
      }
      final state = _stateFor(
        localHash: localHash,
        remoteHash: remoteHash,
        baseHash: baseHashes[_semanticBaseKey(area.name)],
        remoteError: remoteError,
      );
      areas[area] = CloudSyncAreaStatus(
        area: area,
        state: state,
        localCounts: _counts(localArea, area),
        remoteCounts: remoteAreaPayload != null
            ? _counts(remoteAreaPayload, area)
            : remoteManifest == null
            ? const CloudAreaCounts({})
            : CloudAreaCounts({
                for (final key in _areas[area]!)
                  key: remoteManifest.counts[key] ?? 0,
              }),
        localHash: localHash,
        remoteHash: remoteHash,
      );
    }
    final diagnostics = CloudSyncDiagnostics.decode(settings?.syncDiagnostics);
    return CloudSyncStatus(
      householdId: householdId,
      remoteRevision: remote?.generation ?? 0,
      areas: areas,
      diagnostics: diagnostics,
      remoteOrigin: remote?.manifest.deviceId,
      remoteOriginAt: remote?.manifest.createdAt,
      remoteOriginAuthor: remote?.manifest.authorName,
    );
  }

  Future<CloudSyncResult> _synchronizePilot(
    String householdId, {
    required Map<CloudSyncConflictArea, CloudSyncResolution> resolutions,
  }) async {
    final client = syncV2Client!;
    final settings = await settingsRepository.getCloudSyncSettings();
    var localPayload = await CloudSnapshotService(database).readLocalPayload();
    final baseHashes = _decodeHashes(settings?.lastSyncedHash);
    final remote = await client.readCurrentState(householdId);
    final reviews = await client.readReviews(householdId);
    localPayload = separateReaddedPendingItems(localPayload, reviews);
    final reviewedLocalPayload = client.applyReviews(localPayload, reviews);
    final reviewChangedLocally = !syncV2PayloadEquals(
      localPayload,
      reviewedLocalPayload,
    );
    localPayload = reviewedLocalPayload;
    final originalLocalPayload = Map<String, dynamic>.from(localPayload);
    final remoteAreas = <String, Map<String, dynamic>>{};
    final localHashes = <String, String?>{};
    final remoteHashes = <String, String?>{};
    var pulled = reviewChangedLocally;
    var pushed = false;
    var requiresOwnerModeration = false;

    for (final area in _areas.keys) {
      final localArea = selectArea(localPayload, area);
      final localHash = client.areaSemanticHash(localArea);
      final remoteArea = remote == null
          ? null
          : client.applyReviews(
              await client.readArea(
                householdId: householdId,
                area: area.name,
                manifest: remote.manifest,
              ),
              reviews,
            );
      final remoteHash = remoteArea == null
          ? null
          : client.areaSemanticHash(remoteArea);
      remoteAreas[area.name] = remoteArea ?? localArea;
      localHashes[area.name] = localHash;
      remoteHashes[area.name] = remoteHash;
      final baseHash = baseHashes[_semanticBaseKey(area.name)];
      final localIsEmpty = _counts(localArea, area).total == 0;
      // Without a semantic base the device cannot tell which side changed, so
      // the two sides are compared directly: equal areas are already in sync.
      final localChanged = baseHash == null
          ? (remoteHash == null ? !localIsEmpty : localHash != remoteHash)
          : baseHash != localHash;
      final remoteChanged = baseHash == null
          ? (remoteHash != null && localHash != remoteHash)
          : baseHash != remoteHash;
      final resolution = resolutions[area];

      if (resolution != null) {
        final chosen = selectArea(resolution.payload, area);
        if (resolution.source == CloudSyncResolutionSource.remote) {
          localPayload = mergeArea(localPayload, area, chosen);
          remoteAreas[area.name] = chosen;
          pulled = true;
        } else {
          remoteAreas[area.name] = chosen;
          pushed = true;
          requiresOwnerModeration = true;
        }
      } else if (localChanged && remoteChanged && remoteHash != localHash) {
        final merged = const CollaborativeAreaMerger().merge(
          localArea,
          remoteArea ?? const {},
        );
        if (merged.hasConflicts) {
          throw CloudSyncConflictException(
            CloudSyncConflict(
              area: area,
              localPayload: localArea,
              remotePayload: remoteArea ?? const {},
              remoteRevision: remote?.generation ?? 0,
            ),
          );
        }
        localPayload = mergeArea(localPayload, area, merged.payload);
        remoteAreas[area.name] = merged.payload;
        pulled = true;
        pushed = true;
      } else if (remoteChanged && !localChanged) {
        localPayload = mergeArea(localPayload, area, remoteAreas[area.name]!);
        pulled = true;
      } else if (localChanged && !remoteChanged) {
        remoteAreas[area.name] = localArea;
        pushed = true;
      } else if (remoteHash == localHash) {
        remoteAreas[area.name] = localArea;
      }
    }

    localPayload = CollaborativeIdentityNormalizer.normalize(
      originalLocalPayload,
      localPayload,
    );
    for (final area in _areas.keys) {
      remoteAreas[area.name] = selectArea(localPayload, area);
    }

    if (pulled) {
      await CloudSnapshotService(database).restoreRemotePayload(localPayload);
    }
    var generation = remote?.generation ?? 0;
    if (pushed) {
      final author = await client.currentAuthor();
      if (author == null) {
        throw StateError('Entre na sua conta antes de publicar.');
      }
      final publicationId = 'pub-${DateTime.now().microsecondsSinceEpoch}';
      final result = await client.publish(
        householdId: householdId,
        publicationId: publicationId,
        areas: remoteAreas,
        authorUid: author.uid,
        authorName: author.name,
        deviceId: const CloudSyncDiagnostics().publicationDeviceId,
        baseGeneration: generation,
        expectedManifestHash: remote?.manifestHash,
        requiresOwnerModeration: requiresOwnerModeration,
      );
      if (result.status == SyncV2PublishStatus.conflict) {
        throw CloudSyncConflictException(
          CloudSyncConflict(
            area: CloudSyncConflictArea.shopping,
            localPayload: localPayload,
            remotePayload: const {},
            remoteRevision: result.generation,
          ),
        );
      }
      generation = result.generation;
    }

    final finalHashes = <String, String?>{};
    for (final area in _areas.keys) {
      final areaPayload = selectArea(localPayload, area);
      finalHashes[area.name] = client.areaContentHash(areaPayload);
      // The semantic base is stored under its own key, so the legacy byte hash
      // keeps its meaning and the two comparisons never mix.
      finalHashes[_semanticBaseKey(area.name)] = client.areaSemanticHash(
        areaPayload,
      );
    }
    await _persistState(
      householdId: householdId,
      revision: generation,
      hashes: finalHashes,
      localHashes: finalHashes,
    );
    return CloudSyncResult(
      pulled: pulled,
      pushed: pushed,
      revision: generation,
    );
  }

  Future<CloudSyncResult> _publishPilotAreas(
    String householdId,
    CloudSyncConflictArea? changedArea,
  ) async {
    final client = syncV2Client!;
    var localPayload = await CloudSnapshotService(database).readLocalPayload();
    final reviews = await client.readReviews(householdId);
    // The owner decisions are authoritative. A publication that ignores them
    // is refused by the backend, so a member could not publish anything again
    // after the owner removed an item of their list.
    localPayload = separateReaddedPendingItems(localPayload, reviews);
    localPayload = client.applyReviews(localPayload, reviews);
    final remote = await client.readCurrentState(householdId);
    final areas = <String, Map<String, dynamic>>{};
    for (final area in _areas.keys) {
      if (changedArea == null || area == changedArea) {
        areas[area.name] = selectArea(localPayload, area);
      } else if (remote != null) {
        areas[area.name] = client.applyReviews(
          await client.readArea(
            householdId: householdId,
            area: area.name,
            manifest: remote.manifest,
          ),
          reviews,
        );
      } else {
        areas[area.name] = selectArea(localPayload, area);
      }
    }
    // The decision also reaches the database of this device, so the local
    // state and the published state describe the same item.
    for (final review in reviews) {
      await applySyncV2ReviewToLocalItem(database, review);
    }
    final author = await client.currentAuthor();
    if (author == null) {
      throw StateError('Entre na sua conta antes de publicar.');
    }
    final result = await client.publish(
      householdId: householdId,
      publicationId: 'pub-${DateTime.now().microsecondsSinceEpoch}',
      areas: areas,
      authorUid: author.uid,
      authorName: author.name,
      deviceId: const CloudSyncDiagnostics().publicationDeviceId,
      baseGeneration: remote?.generation ?? 0,
      expectedManifestHash: remote?.manifestHash,
      // Publishing is allowed to every household member. Owner moderation is
      // a future workflow over the preserved candidate; it must not prevent a
      // member from publishing a normal change.
      requiresOwnerModeration: false,
    );
    if (result.status == SyncV2PublishStatus.conflict) {
      throw CloudSyncConflictException(
        CloudSyncConflict(
          area: changedArea ?? CloudSyncConflictArea.shopping,
          localPayload: localPayload,
          remotePayload: const {},
          remoteRevision: result.generation,
        ),
      );
    }
    final hashes = {
      for (final area in _areas.keys)
        area.name: client.areaContentHash(areas[area.name]!),
    };
    await _persistState(
      householdId: householdId,
      revision: result.generation,
      hashes: hashes,
      localHashes: hashes,
    );
    return CloudSyncResult(
      pulled: false,
      pushed: true,
      revision: result.generation,
    );
  }

  /// Reads pending member-authored items directly from the authoritative
  /// published state. The owner panel uses this as a fallback when a full
  /// local pull is blocked by an unrelated conflict.
  Future<List<PlanReviewItem>> readPublishedPendingPlanReviews({
    required String householdId,
  }) async {
    final client = syncV2Client;
    if (client == null) return const [];
    final remote = await client.readCurrentState(householdId);
    if (remote == null) return const [];

    final shoppingManifest = remote.manifest.areas['shopping'];
    if (shoppingManifest == null) return const [];
    final shopping = await client.readArea(
      householdId: householdId,
      area: 'shopping',
      manifest: remote.manifest,
    );
    var catalog = const <String, dynamic>{};
    final catalogManifest = remote.manifest.areas['catalog'];
    if (catalogManifest != null) {
      catalog = await client.readArea(
        householdId: householdId,
        area: 'catalog',
        manifest: remote.manifest,
      );
    }

    final productNames = <String, String>{
      for (final row in _payloadRows(catalog['products']))
        if ((row['syncId'] as String?)?.isNotEmpty == true)
          row['syncId'] as String: (row['name'] as String?) ?? 'Produto',
    };
    final planNames = <String, String>{
      for (final row in _payloadRows(shopping['shoppingPlans']))
        if ((row['syncId'] as String?)?.isNotEmpty == true)
          row['syncId'] as String: (row['name'] as String?) ?? 'Lista',
    };
    final decidedIds = {
      for (final review in await client.readReviews(householdId))
        review.itemSyncId,
    };

    final pending = <PlanReviewItem>[];
    for (final row in _payloadRows(shopping['plannedItems'])) {
      final syncId = row['syncId'] as String?;
      if (syncId == null || syncId.isEmpty || decidedIds.contains(syncId)) {
        continue;
      }
      if (row['reviewState'] != CollaborationMetadata.pendingReview ||
          row['isRemoved'] == true ||
          row['deletedAt'] != null) {
        continue;
      }
      final productSyncId = row['productSyncId'] as String?;
      final planSyncId = row['planSyncId'] as String?;
      pending.add(
        PlanReviewItem(
          itemSyncId: syncId,
          productName: productNames[productSyncId] ?? 'Produto',
          planName: planNames[planSyncId] ?? 'Lista',
          authorName: row['authorName'] as String?,
          authorUid: row['authorUid'] as String?,
          createdAt:
              _payloadDate(row['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );
    }
    pending.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return pending;
  }

  static List<Map<String, dynamic>> _payloadRows(Object? value) => [
    for (final row in (value as List<Object?>? ?? const []))
      if (row is Map) Map<String, dynamic>.from(row),
  ];

  static DateTime? _payloadDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  Future<void> moderatePlannedItem({
    required String householdId,
    required String itemSyncId,
    required SyncV2ReviewAction action,
  }) async {
    final client = syncV2Client;
    if (client == null) {
      throw StateError(
        'A moderação está disponível somente no piloto Android.',
      );
    }
    await client.moderatePlannedItem(
      householdId: householdId,
      itemSyncId: itemSyncId,
      action: action,
    );

    // A review decision is authoritative on its own. Do not run a full
    // synchronization here: unrelated local/remote differences must remain a
    // separate, explicitly resolved conflict and must not make the review
    // action look like it failed.
    final reviews = await client.readReviews(householdId);
    final review = reviews
        .where((item) => item.itemSyncId == itemSyncId)
        .firstOrNull;
    if (review == null) {
      throw StateError(
        'A revisão foi registrada, mas ainda não pôde ser aplicada neste dispositivo.',
      );
    }
    await applySyncV2ReviewToLocalItem(database, review);
  }

  Future<CloudSyncDiagnostics?> _readDiagnostics(String householdId) async {
    final settings = await settingsRepository.getCloudSyncSettings();
    if (settings?.householdId != householdId) return null;
    return CloudSyncDiagnostics.decode(settings?.syncDiagnostics);
  }

  Future<void> _saveDiagnostics(
    String householdId,
    CloudSyncDiagnostics diagnostics,
  ) async {
    await settingsRepository.saveSyncDiagnostics(
      householdId,
      diagnostics.encode(),
    );
  }

  Future<void> _recordSuccessfulAttempt(
    String householdId, {
    CloudSyncConflictArea? synchronizedArea,
  }) async {
    final previous = await _readDiagnostics(householdId);
    final areaResults = synchronizedArea == null
        ? {for (final area in _areas.keys) area.name: 'inSync'}
        : {
            ...previous?.areaResults ?? const <String, String>{},
            synchronizedArea.name: 'inSync',
          };
    await _saveDiagnostics(
      householdId,
      CloudSyncDiagnostics(
        lastAttemptAt: DateTime.now().toUtc(),
        lastSuccessfulAt: DateTime.now().toUtc(),
        lastOrigin: const CloudSyncDiagnostics().publicationDeviceId,
        lastOriginAt: DateTime.now().toUtc(),
        outcome: CloudSyncAttemptOutcome.success,
        areaResults: areaResults,
      ),
    );
  }

  Future<void> _recordFailedAttempt(String householdId, Object error) async {
    final previous = await _readDiagnostics(householdId);
    final failedArea = error is CloudSyncConflictException
        ? error.conflict.area.name
        : 'all';
    await _saveDiagnostics(
      householdId,
      CloudSyncDiagnostics(
        lastAttemptAt: DateTime.now().toUtc(),
        lastSuccessfulAt: previous?.lastSuccessfulAt,
        lastOrigin: previous?.lastOrigin,
        lastOriginAt: previous?.lastOriginAt,
        lastOriginAuthor: previous?.lastOriginAuthor,
        outcome: CloudSyncAttemptOutcome.failure,
        failureKind: classifyCloudSyncFailure(error),
        failedArea: failedArea,
        message: _safeErrorMessage(error),
        areaResults: previous?.areaResults ?? const {},
      ),
    );
  }

  String _safeErrorMessage(Object error) {
    final kind = classifyCloudSyncFailure(error);
    return switch (kind) {
      CloudSyncFailureKind.network => 'Não foi possível acessar a internet.',
      CloudSyncFailureKind.permission =>
        'Este dispositivo não tem acesso à casa.',
      CloudSyncFailureKind.invalidData =>
        'Os dados recebidos da casa estão inválidos.',
      CloudSyncFailureKind.conflict =>
        'Há uma divergência que ainda precisa ser resolvida.',
      CloudSyncFailureKind.account => 'Entre na sua conta e tente novamente.',
      CloudSyncFailureKind.unknown => 'A sincronização não pôde ser concluída.',
    };
  }

  Future<void> _persistState({
    required String householdId,
    required int revision,
    required Map<String, String?> hashes,
    required Map<String, String?> localHashes,
  }) async {
    if (syncV2Client == null) {
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
    }
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
        throw FormatException(
          'A área "${area.label}" está incompleta: ${cloudTableLabel(key)}.',
        );
      }
    }
    final formatVersion = payload['formatVersion'];
    if (formatVersion is! int || formatVersion < 1 || formatVersion > 7) {
      throw const FormatException(
        'A área remota usa uma versão de backup inválida.',
      );
    }
  }

  static CloudAreaCounts _counts(
    Map<String, dynamic> payload,
    CloudSyncConflictArea area,
  ) {
    final values = <String, int>{};
    final removed = <String, int>{};
    final pending = <String, int>{};
    for (final key in _areas[area]!) {
      final rows = (payload[key] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      values[key] = rows.length;
      // A remoção preserva a linha como tombstone, então a contagem de linhas
      // continua igual e a diferença aparece só nestes contadores.
      removed[key] = rows
          .where((row) => row['isRemoved'] == true || row['deletedAt'] != null)
          .length;
      pending[key] = rows
          .where((row) => row['reviewState'] == 'pending_review')
          .length;
    }
    return CloudAreaCounts(values, removed: removed, pending: pending);
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

  /// Key that holds the semantic base hash of an area.
  static String _semanticBaseKey(String areaName) =>
      '$syncV2SemanticBaseKeyPrefix$areaName';
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
