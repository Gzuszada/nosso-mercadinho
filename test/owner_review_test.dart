import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/cloud/data/sync_v2_client.dart';
import 'package:mercado/features/cloud/data/sync_v2_manifest.dart';
import 'package:mercado/features/cloud/data/sync_v2_review.dart';
import 'package:mercado/features/cloud/domain/collaboration.dart';
import 'package:mercado/features/cloud/domain/collaboration_service.dart';
import 'package:mercado/features/cloud/presentation/owner_review_panel.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('membro cria item pendente e owner recebe a revisão', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final owner = CollaborationActor(
      uid: 'owner-1',
      displayName: 'Owner',
      role: CollaborationRole.owner,
    );
    final member = CollaborationActor(
      uid: 'member-1',
      displayName: 'Membro',
      role: CollaborationRole.member,
    );
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

    final reviews = await CollaborationService(
      database,
      actorResolver: () async => owner,
    ).watchPendingPlanReviews().first;
    expect(reviews, hasLength(1));
    expect(reviews.single.product.name, 'Arroz');
    expect(reviews.single.item.authorName, 'Membro');
    expect(reviews.single.item.reviewState, 'pending_review');
  });

  test('aprovação e remoção autoritativas alteram o payload', () {
    final payload = {
      'plannedItems': [
        {
          'id': 1,
          'syncId': 'planned-item:1',
          'authorUid': 'member-1',
          'reviewState': 'pending_review',
          'syncRevision': 0,
          'isRemoved': false,
        },
      ],
    };
    SyncV2Review review(SyncV2ReviewAction action) => SyncV2Review(
      itemSyncId: 'planned-item:1',
      action: action,
      reviewedByUid: 'owner-1',
      reviewedByName: 'Owner',
      decidedAt: DateTime.utc(2026, 11, 25, 12),
      authorUid: 'member-1',
      authorName: 'Membro',
    );
    final approved = applySyncV2Reviews(payload, [
      review(SyncV2ReviewAction.approve),
    ]);
    final row = (approved['plannedItems'] as List).single as Map;
    expect(row['reviewState'], 'approved');
    expect(row['reviewedByUid'], 'owner-1');
    expect(row['syncRevision'], 1);

    final removed = applySyncV2Reviews(payload, [
      review(SyncV2ReviewAction.remove),
    ]);
    final removedRow = (removed['plannedItems'] as List).single as Map;
    expect(removedRow['reviewState'], 'rejected');
    expect(removedRow['isRemoved'], isTrue);
    expect(removedRow['deletedAt'], isNotNull);
  });

  test('membro não remove item de outra pessoa, mas owner remove', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final owner = CollaborationActor(
      uid: 'owner-1',
      displayName: 'Owner',
      role: CollaborationRole.owner,
    );
    final member = CollaborationActor(
      uid: 'member-1',
      displayName: 'Membro',
      role: CollaborationRole.member,
    );
    final otherMember = CollaborationActor(
      uid: 'member-2',
      displayName: 'Outro membro',
      role: CollaborationRole.member,
    );
    final productId =
        await CatalogRepository(
          database,
          actorResolver: () async => owner,
        ).saveProduct(
          name: 'Leite',
          measurementMode: MeasurementMode.unit,
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
      mode: MeasurementMode.unit,
      quantity: 1,
    );
    final item = await database.select(database.plannedItems).getSingle();

    await expectLater(
      ShoppingRepository(
        database,
        actorResolver: () async => otherMember,
      ).removePlannedItem(item.id),
      throwsFormatException,
    );
    await ShoppingRepository(
      database,
      actorResolver: () async => owner,
    ).removePlannedItem(item.id);
    expect(
      (await database.select(database.plannedItems).getSingle()).isRemoved,
      isTrue,
    );
  });

  test(
    'moderação aplica a decisão localmente sem sincronizar toda a casa',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final owner = CollaborationActor(
        uid: 'owner-1',
        displayName: 'Owner',
        role: CollaborationRole.owner,
      );
      final member = CollaborationActor(
        uid: 'member-1',
        displayName: 'Membro',
        role: CollaborationRole.member,
      );
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
      final decidedAt = DateTime.utc(2026, 11, 25, 19, 30);

      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('syncV2')
          .doc('casa')
          .collection('reviews')
          .doc(item.syncId!)
          .set({
            'itemSyncId': item.syncId,
            'action': 'approve',
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
        action: SyncV2ReviewAction.approve,
      );

      final updated = await database.select(database.plannedItems).getSingle();
      expect(moderationCalls, 1);
      expect(updated.reviewState, 'approved');
      expect(updated.reviewedByUid, 'owner-1');
      expect(updated.reviewedByName, 'Owner');
      expect(updated.reviewedAt!.toUtc(), decidedAt);
      expect(updated.syncRevision, item.syncRevision + 1);
      expect(updated.isRemoved, isFalse);
    },
  );

  test(
    'owner encontra pendência publicada que ainda não está no banco local',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final firestore = FakeFirebaseFirestore();
      final catalogPayload = {
        'products': [
          {'syncId': 'product-1', 'name': 'Arroz'},
        ],
      };
      final shoppingPayload = {
        'shoppingPlans': [
          {'syncId': 'plan-1', 'name': 'Compras'},
        ],
        'plannedItems': [
          {
            'syncId': 'item-1',
            'productSyncId': 'product-1',
            'planSyncId': 'plan-1',
            'reviewState': 'pending_review',
            'authorUid': 'member-1',
            'authorName': 'Membro',
            'createdAt': '2026-11-25T19:30:00.000Z',
            'isRemoved': false,
          },
          {
            'syncId': 'item-2',
            'productSyncId': 'product-1',
            'planSyncId': 'plan-1',
            'reviewState': 'pending_review',
            'authorUid': 'member-1',
            'authorName': 'Membro',
            'createdAt': '2026-11-25T19:31:00.000Z',
            'isRemoved': false,
          },
        ],
      };
      final catalogPath = 'syncV2/casa/chunks/catalog-0';
      final shoppingPath = 'syncV2/casa/chunks/shopping-0';
      await firestore.doc(catalogPath).set({
        'payload': catalogPayload,
        'hash': canonicalHash(catalogPayload),
      });
      await firestore.doc(shoppingPath).set({
        'payload': shoppingPayload,
        'hash': canonicalHash(shoppingPayload),
      });
      await firestore.doc('syncV2/casa/state/current').set({
        'generation': 6,
        'manifestHash': 'manifest-hash',
        'manifest': {
          'protocolVersion': 2,
          'publicationId': 'publication-1',
          'baseGeneration': 5,
          'authorUid': 'member-1',
          'authorName': 'Membro',
          'deviceId': 'android-pilot',
          'createdAt': '2026-11-25T19:30:00.000Z',
          'areas': {
            'catalog': {
              'hash': 'catalog-hash',
              'counts': {'products': 1},
              'chunks': [
                {
                  'index': 0,
                  'path': catalogPath,
                  'hash': canonicalHash(catalogPayload),
                  'count': 1,
                },
              ],
            },
            'shopping': {
              'hash': 'shopping-hash',
              'counts': {'shoppingPlans': 1, 'plannedItems': 2},
              'chunks': [
                {
                  'index': 0,
                  'path': shoppingPath,
                  'hash': canonicalHash(shoppingPayload),
                  'count': 3,
                },
              ],
            },
          },
        },
      });
      await firestore
          .collection('syncV2')
          .doc('casa')
          .collection('reviews')
          .doc('item-2')
          .set({
            'itemSyncId': 'item-2',
            'action': 'approve',
            'authorUid': 'member-1',
            'authorName': 'Membro',
            'reviewedByUid': 'owner-1',
            'reviewedByName': 'Owner',
            'decidedAt': '2026-11-25T19:32:00.000Z',
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

      final pending = await service.readPublishedPendingPlanReviews(
        householdId: 'casa',
      );

      expect(pending, hasLength(1));
      expect(pending.single.itemSyncId, 'item-1');
      expect(pending.single.productName, 'Arroz');
      expect(pending.single.planName, 'Compras');
      expect(pending.single.authorName, 'Membro');
    },
  );

  testWidgets('painel mostra autoria e ações do owner', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final owner = CollaborationActor(
      uid: 'owner-1',
      displayName: 'Owner',
      role: CollaborationRole.owner,
    );
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
      actorResolver: () async => owner,
    ).addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.package,
      quantity: 1,
    );
    await database
        .update(database.plannedItems)
        .write(
          PlannedItemsCompanion(
            authorUid: const Value('member-1'),
            authorName: const Value('Membro'),
            reviewState: const Value('pending_review'),
          ),
        );
    final item = await database.select(database.plannedItems).getSingle();
    final product = await database.select(database.products).getSingle();
    final plan = await database.select(database.shoppingPlans).getSingle();
    final pending = [
      PlanReviewItem(
        itemSyncId: item.syncId!,
        productName: product.name,
        planName: plan.name,
        authorName: item.authorName,
        authorUid: item.authorUid,
        createdAt: item.createdAt,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OwnerReviewPanel(
            reviews: pending,
            isOwner: true,
            busy: false,
            onApprove: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Revisão do owner'), findsOneWidget);
    expect(find.textContaining('Adicionado por Membro'), findsOneWidget);
    expect(find.text('Confirmar item'), findsOneWidget);
    expect(find.text('Remover da lista'), findsOneWidget);
  });
}
