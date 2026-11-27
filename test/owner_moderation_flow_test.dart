import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/cloud_snapshot_service.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/cloud/data/sync_v2_client.dart';
import 'package:mercado/features/cloud/data/sync_v2_manifest.dart';
import 'package:mercado/features/cloud/data/sync_v2_review.dart';
import 'package:mercado/features/cloud/domain/collaboration.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';

void main() {
  const owner = CollaborationActor(
    uid: 'owner-1',
    displayName: 'Owner',
    role: CollaborationRole.owner,
  );
  const member = CollaborationActor(
    uid: 'member-1',
    displayName: 'Membro',
    role: CollaborationRole.member,
  );

  test('owner remove item de membro: decisão idempotente e canônica', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final productId =
        await CatalogRepository(
          database,
          actorResolver: () async => owner,
        ).saveProduct(
          name: 'Arroz',
          measurementMode: MeasurementMode.package,
          needsCategoryReview: false,
        );
    final planId = await ShoppingRepository(
      database,
      actorResolver: () async => owner,
    ).createPlan(monthKey: '2026-11', name: 'Compras');
    await ShoppingRepository(
      database,
      actorResolver: () async => member,
    ).addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.package,
      quantity: 1,
    );
    final item = await database.select(database.plannedItems).getSingle();
    expect(item.authorUid, 'member-1');
    expect(item.reviewState, 'pending_review');

    // A decisão do owner é posterior ao item pendente criado pelo membro.
    final now = DateTime.now().toUtc();
    final decidedAt = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    ).add(const Duration(hours: 1));
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('syncV2')
        .doc('casa')
        .collection('reviews')
        .doc(item.syncId!)
        .set({
          'itemSyncId': item.syncId,
          'action': 'remove',
          'authorUid': 'member-1',
          'authorName': 'Membro',
          'reviewedByUid': 'owner-1',
          'reviewedByName': 'Owner',
          'decidedAt': decidedAt.toIso8601String(),
        });
    var moderationCalls = 0;
    final client = SyncV2Client(
      firestore: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'owner-1',
          email: 'owner@example.com',
          displayName: 'Owner',
        ),
      ),
      httpClient: MockClient((request) async {
        moderationCalls += 1;
        expect(request.url.path, '/moderatePlannedItem');
        return http.Response('{"result":{"status":"recorded"}}', 200);
      }),
    );
    final service = CloudSyncService(
      database: database,
      settingsRepository: SettingsRepository(database),
      firestore: firestore,
      syncV2Client: client,
    );

    await service.moderatePlannedItem(
      householdId: 'casa',
      itemSyncId: item.syncId!,
      action: SyncV2ReviewAction.remove,
    );

    final removed = await database.select(database.plannedItems).getSingle();
    expect(moderationCalls, 1);
    expect(removed.reviewState, 'rejected');
    expect(removed.reviewedByUid, 'owner-1');
    expect(removed.reviewedByName, 'Owner');
    expect(removed.isRemoved, isTrue);
    // A decisão é gravada com a precisão que sobrevive ao banco local.
    expect(removed.reviewedAt!.toUtc(), decidedAt);
    expect(removed.deletedAt!.toUtc(), decidedAt);
    expect(removed.syncRevision, item.syncRevision + 1);

    // Repetir a mesma decisão não conta de novo.
    await service.moderatePlannedItem(
      householdId: 'casa',
      itemSyncId: item.syncId!,
      action: SyncV2ReviewAction.remove,
    );
    final repeated = await database.select(database.plannedItems).getSingle();
    expect(repeated.syncRevision, removed.syncRevision);
    expect(repeated.reviewedAt!.toUtc(), removed.reviewedAt!.toUtc());
  });

  test('publicação do membro carrega a remoção decidida pelo owner', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settings = SettingsRepository(database);
    await settings.selectCloudHousehold('casa');
    final productId =
        await CatalogRepository(
          database,
          actorResolver: () async => owner,
        ).saveProduct(
          name: 'Arroz',
          measurementMode: MeasurementMode.package,
          needsCategoryReview: false,
        );
    final planId = await ShoppingRepository(
      database,
      actorResolver: () async => owner,
    ).createPlan(monthKey: '2026-11', name: 'Compras');
    await ShoppingRepository(
      database,
      actorResolver: () async => member,
    ).addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.package,
      quantity: 1,
    );
    final item = await database.select(database.plannedItems).getSingle();

    final firestore = FakeFirebaseFirestore();
    final now = DateTime.now().toUtc();
    final decidedAt = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    ).add(const Duration(hours: 1));
    await firestore
        .collection('syncV2')
        .doc('casa')
        .collection('reviews')
        .doc(item.syncId!)
        .set({
          'itemSyncId': item.syncId,
          'action': 'remove',
          'authorUid': 'member-1',
          'authorName': 'Membro',
          'reviewedByUid': 'owner-1',
          'reviewedByName': 'Owner',
          'decidedAt': decidedAt.toIso8601String(),
        });
    Map<String, dynamic>? publishedManifest;
    final client = SyncV2Client(
      firestore: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'member-1',
          email: 'member@example.com',
          displayName: 'Membro',
        ),
      ),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/publishSyncV2');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        publishedManifest = Map<String, dynamic>.from(data['manifest'] as Map);
        return http.Response(
          jsonEncode({
            'result': {'status': 'committed', 'generation': 2},
          }),
          200,
        );
      }),
    );
    final service = CloudSyncService(
      database: database,
      settingsRepository: settings,
      firestore: firestore,
      syncV2Client: client,
    );

    final result = await service.publishAllLocalAreas(householdId: 'casa');
    expect(result.pushed, isTrue);

    // A publicação leva a decisão do owner, e não a versão pendente do item.
    final areas = publishedManifest!['areas'] as Map<String, dynamic>;
    final shopping = areas['shopping'] as Map<String, dynamic>;
    final chunks = (shopping['chunks'] as List).cast<Map>();
    expect(chunks, isNotEmpty);
    final published = <Map<String, dynamic>>[];
    for (final chunk in chunks) {
      final snapshot = await firestore.doc(chunk['path'] as String).get();
      expect(snapshot.exists, isTrue);
      final payload = Map<String, dynamic>.from(snapshot.get('payload') as Map);
      for (final row in (payload['plannedItems'] as List? ?? const [])) {
        published.add(Map<String, dynamic>.from(row as Map));
      }
    }
    expect(published, hasLength(1));
    expect(published.single['reviewState'], 'rejected');
    expect(published.single['isRemoved'], isTrue);
    expect(published.single['deletedAt'], isNotNull);

    // E o banco local do membro também deixa de mostrar o item removido.
    final local = await database.select(database.plannedItems).getSingle();
    expect(local.isRemoved, isTrue);
    expect(local.reviewState, 'rejected');
  });

  test('área com o mesmo conteúdo é reconhecida como em dia', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            name: 'Leite',
            measurementMode: const Value('unit'),
          ),
        );

    final localPayload = await CloudSnapshotService(database)
        .readLocalPayload();
    final localCatalog = CloudSyncService.selectArea(
      localPayload,
      CloudSyncConflictArea.catalog,
    );
    // A mesma área publicada por outro aparelho: identificadores locais,
    // contadores de revisão e instantes escritos de outra forma.
    final remoteCatalog = <String, dynamic>{
      for (final entry in localCatalog.entries)
        entry.key: entry.value is List
            ? [
                for (final row in (entry.value as List))
                  {
                    ...Map<String, dynamic>.from(row as Map),
                    'id': 999,
                    'updatedAt': '2020-01-01T00:00:00.000Z',
                    'syncRevision': 42,
                  },
              ]
            : entry.value,
    };

    final firestore = FakeFirebaseFirestore();
    const chunkPath = 'syncV2/casa/chunks/catalog-0';
    await firestore.doc(chunkPath).set({
      'payload': remoteCatalog,
      'hash': canonicalHash(remoteCatalog),
    });
    await firestore.doc('syncV2/casa/state/current').set({
      'generation': 3,
      'manifestHash': 'manifest-hash',
      'manifest': {
        'protocolVersion': 2,
        'publicationId': 'publication-1',
        'baseGeneration': 2,
        'authorUid': 'owner-1',
        'authorName': 'Owner',
        'deviceId': 'android-pilot',
        'createdAt': '2026-11-25T19:30:00.000Z',
        'areas': {
          'catalog': {
            'hash': 'catalog-hash',
            'counts': {'products': 1},
            'chunks': [
              {
                'index': 0,
                'path': chunkPath,
                'hash': canonicalHash(remoteCatalog),
                'count': 1,
              },
            ],
          },
        },
      },
    });
    final client = SyncV2Client(
      firestore: firestore,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'owner-1',
          email: 'owner@example.com',
          displayName: 'Owner',
        ),
      ),
    );
    final service = CloudSyncService(
      database: database,
      settingsRepository: SettingsRepository(database),
      firestore: firestore,
      syncV2Client: client,
    );

    final status = await service.inspectStatus('casa');

    expect(
      status.areas[CloudSyncConflictArea.catalog]!.state,
      CloudSyncAreaState.inSync,
    );
  });
}
