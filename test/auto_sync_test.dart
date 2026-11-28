import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/cloud/data/auto_sync_coordinator.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/cloud/data/sync_v2_candidate.dart';
import 'package:mercado/features/cloud/data/sync_v2_client.dart';
import 'package:mercado/features/cloud/data/sync_v2_manifest.dart';
import 'package:mercado/features/cloud/data/sync_v2_review.dart';
import 'package:mercado/features/cloud/presentation/flutter_test_environment.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';

void main() {
  group('classificação conservadora das áreas', () {
    test('igual é Em dia e não provoca escrita', () {
      expect(
        CloudSyncService.classifyAreaState(
          localHash: 'igual',
          remoteHash: 'igual',
          baseHash: 'base',
          remoteError: null,
        ),
        CloudSyncAreaState.inSync,
      );
    });

    test('somente local e somente remoto são distinguidos pela base', () {
      expect(
        CloudSyncService.classifyAreaState(
          localHash: 'local',
          remoteHash: 'base',
          baseHash: 'base',
          remoteError: null,
        ),
        CloudSyncAreaState.localOnly,
      );
      expect(
        CloudSyncService.classifyAreaState(
          localHash: 'base',
          remoteHash: 'remoto',
          baseHash: 'base',
          remoteError: null,
        ),
        CloudSyncAreaState.remoteOnly,
      );
    });

    test(
      'ambos alterados é divergente e base ausente também é conservador',
      () {
        expect(
          CloudSyncService.classifyAreaState(
            localHash: 'local',
            remoteHash: 'remoto',
            baseHash: 'base',
            remoteError: null,
          ),
          CloudSyncAreaState.divergent,
        );
        expect(
          CloudSyncService.classifyAreaState(
            localHash: 'local',
            remoteHash: 'remoto',
            baseHash: null,
            remoteError: null,
          ),
          CloudSyncAreaState.divergent,
        );
      },
    );
  });

  group('coordenador de sincronização automática', () {
    test('não sincroniza quando já está em dia', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.inSync),
        onSynchronize: () async => calls += 1,
      );

      expect(
        await coordinator.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.upToDate,
      );
      expect(calls, 0);
    });

    test('não sincroniza nem sobrescreve quando há conflito', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.divergent),
        onSynchronize: () async => calls += 1,
      );

      expect(
        await coordinator.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.skippedConflict,
      );
      expect(calls, 0);
    });

    test('publica quando somente o lado local mudou', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        onSynchronize: () async => calls += 1,
      );

      expect(
        await coordinator.run(AutoSyncTrigger.localChange),
        AutoSyncOutcome.synchronized,
      );
      expect(calls, 1);
    });

    test('aplica o remoto quando somente o lado remoto mudou', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.remoteOnly),
        onSynchronize: () async => calls += 1,
      );

      expect(
        await coordinator.run(AutoSyncTrigger.webFocus),
        AutoSyncOutcome.synchronized,
      );
      expect(calls, 1);
    });

    test('respeita rede, sessão e casa selecionada', () async {
      final noNetwork = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        hasNetwork: false,
      );
      expect(
        await noNetwork.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.skippedNoNetwork,
      );

      final noSession = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        hasSession: false,
      );
      expect(
        await noSession.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.skippedNoSession,
      );

      final noHousehold = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        householdId: null,
      );
      expect(
        await noHousehold.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.skippedNoHousehold,
      );
    });

    test('uma segunda execução concorrente é ignorada', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        onSynchronize: () async {
          calls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
      );

      final first = coordinator.run(AutoSyncTrigger.foreground);
      final second = await coordinator.run(AutoSyncTrigger.foreground);
      expect(second, AutoSyncOutcome.skippedAlreadyRunning);
      await first;
      expect(calls, 1);
    });

    test('ignora novo gatilho local durante o cooldown', () async {
      var calls = 0;
      final coordinator = _coordinator(
        status: _status(CloudSyncAreaState.localOnly),
        onSynchronize: () async => calls += 1,
      );

      expect(
        await coordinator.run(AutoSyncTrigger.foreground),
        AutoSyncOutcome.synchronized,
      );
      expect(
        await coordinator.run(AutoSyncTrigger.localChange),
        AutoSyncOutcome.skippedCooldown,
      );
      expect(calls, 1);
    });
  });

  test('o runner Flutter é reconhecido e isola os gatilhos', () {
    expect(isFlutterTestProcess, isTrue);
  });

  test(
    'a fingerprint local muda quando uma tabela sincronizável muda',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final fingerprints = database.watchSyncRelevantFingerprint();

      final initial = await fingerprints.first;
      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Produto novo',
              measurementMode: const Value('unit'),
            ),
          );
      final changed = await fingerprints
          .firstWhere((value) => value != initial)
          .timeout(const Duration(seconds: 2));

      expect(changed, isNot(initial));
    },
  );

  test(
    'piloto automático não faz merge quando os dois lados mudaram',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final settings = SettingsRepository(database);
      await settings.selectCloudHousehold('casa');
      await settings.saveCloudSyncSettings(
        householdId: 'casa',
        remoteRevision: 1,
        lastSyncedHash: jsonEncode({
          'semantic:catalog': 'base',
          'semantic:imports': 'base',
          'semantic:shopping': 'base',
        }),
      );
      await database
          .into(database.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Local',
              measurementMode: const Value('unit'),
            ),
          );

      final client = _FakePilotClient();
      final service = CloudSyncService(
        database: database,
        settingsRepository: settings,
        firestore: FakeFirebaseFirestore(),
        syncV2Client: client,
      );

      await expectLater(
        service.synchronize(householdId: 'casa', conservative: true),
        throwsA(isA<CloudSyncConflictException>()),
      );
      expect(client.publishCalls, 0);
      expect(
        (await database.select(database.products).getSingle()).name,
        'Local',
      );
    },
  );
}

AutoSyncCoordinator _coordinator({
  required CloudSyncStatus status,
  bool hasNetwork = true,
  bool hasSession = true,
  String? householdId = 'casa',
  Future<void> Function()? onSynchronize,
}) {
  return AutoSyncCoordinator(
    hasNetwork: () async => hasNetwork,
    hasValidSession: () async => hasSession,
    selectedHouseholdId: () async => householdId,
    inspectStatus: (id) async => status,
    synchronize: (id) async {
      await onSynchronize?.call();
      return const CloudSyncResult(pulled: false, pushed: true, revision: 1);
    },
  );
}

CloudSyncStatus _status(CloudSyncAreaState state) {
  return CloudSyncStatus(
    householdId: 'casa',
    remoteRevision: 1,
    areas: {
      for (final area in CloudSyncConflictArea.values)
        area: CloudSyncAreaStatus(
          area: area,
          state: state,
          localCounts: const CloudAreaCounts({}),
          remoteCounts: const CloudAreaCounts({}),
          localHash: 'local',
          remoteHash: 'remoto',
        ),
    },
  );
}

class _FakePilotClient extends SyncV2Client {
  _FakePilotClient()
    : super(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'member-1', email: 'member@example.com'),
        ),
      );

  int publishCalls = 0;

  final Map<String, Map<String, dynamic>> _areas = {
    'catalog': {
      'categories': <Object?>[],
      'subcategories': <Object?>[],
      'products': [
        {
          'id': 1,
          'name': 'Remoto',
          'measurementMode': 'unit',
          'syncId': 'product:remote',
          'logicalKey': 'product:remoto:unit',
          'authorUid': 'member-2',
          'authorName': 'Outro membro',
          'reviewState': 'approved',
          'isRemoved': false,
          'syncRevision': 1,
        },
      ],
      'formatVersion': 7,
    },
    'imports': {
      'importBatches': <Object?>[],
      'importEntries': <Object?>[],
      'formatVersion': 7,
    },
    'shopping': {
      'shoppingPlans': <Object?>[],
      'plannedItems': <Object?>[],
      'shoppingTrips': <Object?>[],
      'purchaseLines': <Object?>[],
      'formatVersion': 7,
    },
  };

  @override
  Future<SyncV2RemoteState?> readCurrentState(String householdId) async {
    final descriptor = SyncV2AreaManifest(
      hash: 'hash',
      counts: const {},
      chunks: const [],
    );
    return SyncV2RemoteState(
      generation: 2,
      manifestHash: 'manifest',
      manifest: SyncV2Manifest(
        publicationId: 'publication',
        baseGeneration: 1,
        authorUid: 'member-2',
        authorName: 'Outro membro',
        deviceId: 'other-device',
        areas: {for (final area in _areas.keys) area: descriptor},
        createdAt: DateTime.utc(2026, 11, 27),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> readArea({
    required String householdId,
    required String area,
    required SyncV2Manifest manifest,
  }) async => Map<String, dynamic>.from(_areas[area]!);

  @override
  Future<List<SyncV2Review>> readReviews(String householdId) async => const [];

  @override
  String areaSemanticHash(Map<String, dynamic> payload) {
    final products = payload['products'] as List<Object?>? ?? const [];
    final first = products.isEmpty ? null : products.first;
    final name = first is Map ? first['name'] : null;
    return name == 'Remoto' ? 'remote' : 'local';
  }

  @override
  Future<SyncV2PublishResult> publish({
    required String householdId,
    required String publicationId,
    required Map<String, dynamic> areas,
    required String authorUid,
    required String authorName,
    required String deviceId,
    required int baseGeneration,
    required String? expectedManifestHash,
    bool requiresOwnerModeration = false,
  }) async {
    publishCalls += 1;
    return const SyncV2PublishResult(
      status: SyncV2PublishStatus.conflict,
      generation: 0,
    );
  }
}
