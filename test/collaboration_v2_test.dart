import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/backup/data/backup_service.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/cloud/domain/collaboration.dart';
import 'package:mercado/features/cloud/domain/collaboration_service.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late bool previousMultipleDatabaseWarning;

  setUpAll(() {
    previousMultipleDatabaseWarning =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases =
        previousMultipleDatabaseWarning;
  });

  test('migracao 7 para 9 preenche IDs e logical keys legacy', () async {
    final file = File(
      '${Directory.systemTemp.path}/mercado-collaboration-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    addTearDown(() {
      try {
        if (file.existsSync()) file.deleteSync();
      } on FileSystemException {
        // O Windows pode liberar o handle do SQLite após o teste terminar.
      }
    });
    final seed = AppDatabase(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    await seed.close();
    final sqlite = sqlite3.open(file.path);
    for (final table in const ['products', 'shopping_plans', 'planned_items']) {
      for (final column in const [
        'sync_id',
        'logical_key',
        'author_uid',
        'author_name',
        'review_state',
        'reviewed_by_uid',
        'reviewed_by_name',
        'reviewed_at',
        'deleted_at',
        'sync_revision',
      ]) {
        sqlite.execute('ALTER TABLE $table DROP COLUMN $column');
      }
    }
    sqlite.execute('''
      INSERT INTO products (
        id, name, category_id, subcategory_id, measurement_mode,
        needs_category_review, description, is_archived, created_at, updated_at
      ) VALUES (7, 'Leite', NULL, NULL, 'unit', 0, NULL, 0, 0, 0);
      INSERT INTO shopping_plans (
        id, month_key, name, status, created_at, updated_at
      ) VALUES (3, '2026-11', 'Compras', 'active', 0, 0);
      INSERT INTO planned_items (
        id, plan_id, product_id, measurement_mode, quantity, is_removed,
        estimate_price_numerator_cents, estimate_quantity_denominator,
        estimate_source, estimate_reference_date, estimate_reference_trip_id,
        created_at, updated_at
      ) VALUES (5, 3, 7, 'unit', 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0);
      PRAGMA user_version = 7;
    ''');
    sqlite.dispose();

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final product = await database.select(database.products).getSingle();
    final plan = await database.select(database.shoppingPlans).getSingle();
    final item = await database.select(database.plannedItems).getSingle();

    expect(database.schemaVersion, 9);
    expect(product.syncId, 'legacy:product:7');
    expect(product.logicalKey, 'product:leite:unit');
    expect(plan.syncId, 'legacy:plan:3');
    expect(plan.logicalKey, 'plan:2026-11:compras');
    expect(item.syncId, 'legacy:planned-item:5');
    expect(item.logicalKey, 'planned-item:legacy:plan:3:legacy:product:7');
  });

  test('backup 7 preserva autoria, revisao e tombstone', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CatalogRepository(
      database,
      actorResolver: _actor(
        CollaborationRole.member,
        uid: 'member-1',
        name: 'Membro',
      ),
    );
    final productId = await repository.saveProduct(
      name: 'Café',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );

    final service = CollaborationService(
      database,
      actorResolver: _actor(
        CollaborationRole.owner,
        uid: 'owner-1',
        name: 'Owner',
      ),
    );
    await service.reviewItem(
      type: CollaborativeItemType.product,
      id: productId,
      state: CollaborativeReviewState.approved,
    );

    final backup = await BackupService(database).createBackup();
    final payload = jsonDecode(backup) as Map<String, dynamic>;
    expect(payload['formatVersion'], 7);
    expect(payload['schemaVersion'], 9);
    final row = (payload['products'] as List).single as Map<String, dynamic>;
    expect(row['syncId'], startsWith('product:'));
    expect(row['logicalKey'], 'product:café:unit');
    expect(row['authorUid'], 'member-1');
    expect(row['authorName'], 'Membro');
    expect(row['reviewState'], 'approved');
    expect(row['reviewedByUid'], 'owner-1');
    expect(row['syncRevision'], 1);

    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).restoreBackup(backup);
    final restoredRow = await restored.select(restored.products).getSingle();
    expect(restoredRow.authorUid, 'member-1');
    expect(restoredRow.reviewedByUid, 'owner-1');
    expect(restoredRow.reviewState, 'approved');
    expect(restoredRow.syncRevision, 1);
  });

  test('backup 6 sem metadados ainda restaura com IDs legacy', () async {
    final source = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    await CatalogRepository(source).saveProduct(
      name: 'Arroz',
      measurementMode: MeasurementMode.package,
      needsCategoryReview: false,
    );
    final payload = jsonDecode(
      await BackupService(source).createBackup(),
    ) as Map<String, dynamic>;
    payload['formatVersion'] = 6;
    for (final row in payload['products'] as List) {
      (row as Map<String, dynamic>).remove('syncId');
      row.remove('logicalKey');
      row.remove('authorUid');
      row.remove('authorName');
      row.remove('reviewState');
      row.remove('reviewedByUid');
      row.remove('reviewedByName');
      row.remove('reviewedAt');
      row.remove('deletedAt');
      row.remove('syncRevision');
    }

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await BackupService(target).restoreBackup(jsonEncode(payload));
    final row = await target.select(target.products).getSingle();
    expect(row.syncId, 'legacy:product:1');
    expect(row.logicalKey, 'product:arroz:package');
    expect(row.reviewState, 'approved');
    expect(row.syncRevision, 0);
  });

  test('membro cria item pendente e somente owner revisa', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final productId =
        await CatalogRepository(
          database,
          actorResolver: _actor(
            CollaborationRole.member,
            uid: 'member-1',
            name: 'Membro',
          ),
        ).saveProduct(
          name: 'Pão',
          measurementMode: MeasurementMode.unit,
          needsCategoryReview: false,
        );
    var row = await database.select(database.products).getSingle();
    expect(row.reviewState, 'pending_review');
    expect(row.authorUid, 'member-1');

    await expectLater(
      CollaborationService(
        database,
        actorResolver: _actor(
          CollaborationRole.member,
          uid: 'member-1',
          name: 'Membro',
        ),
      ).reviewItem(
        type: CollaborativeItemType.product,
        id: productId,
        state: CollaborativeReviewState.approved,
      ),
      throwsFormatException,
    );

    await CollaborationService(
      database,
      actorResolver: _actor(
        CollaborationRole.owner,
        uid: 'owner-1',
        name: 'Owner',
      ),
    ).reviewItem(
      type: CollaborativeItemType.product,
      id: productId,
      state: CollaborativeReviewState.rejected,
    );
    row = await database.select(database.products).getSingle();
    expect(row.reviewState, 'rejected');
    expect(row.reviewedByUid, 'owner-1');
    expect(row.reviewedAt, isNotNull);
    expect(row.syncRevision, 1);
  });

  test('importacao de catalogo cria metadados de autoria e revisao', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CatalogRepository(
      database,
      actorResolver: _actor(
        CollaborationRole.member,
        uid: 'member-import',
        name: 'Membro importador',
      ),
    );

    await repository.importCatalog(
      const CatalogImport(
        source: 'catálogo de teste',
        warning: '',
        items: [
          CatalogImportItem(
            sourceSheet: 'Sheet1',
            sourceRow: 1,
            sourceNumber: 1,
            name: 'Aveia',
            suggestedCategory: 'Cereais',
            needsCategoryReview: false,
            measurementMode: MeasurementMode.package,
          ),
        ],
      ),
    );

    final product = await database.select(database.products).getSingle();
    expect(product.syncId, startsWith('product:'));
    expect(product.logicalKey, 'product:aveia:package');
    expect(product.authorUid, 'member-import');
    expect(product.authorName, 'Membro importador');
    expect(product.reviewState, CollaborationMetadata.pendingReview);
  });

  test('recriacao de lista cria plano e item com metadados', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final catalog = CatalogRepository(
      database,
      actorResolver: _actor(
        CollaborationRole.member,
        uid: 'member-list',
        name: 'Membro da lista',
      ),
    );
    final shopping = ShoppingRepository(
      database,
      actorResolver: _actor(
        CollaborationRole.member,
        uid: 'member-list',
        name: 'Membro da lista',
      ),
    );
    final productId = await catalog.saveProduct(
      name: 'Lentejas',
      measurementMode: MeasurementMode.package,
      needsCategoryReview: false,
    );
    final sourcePlanId = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Lista original',
    );
    await shopping.addPlannedItem(
      planId: sourcePlanId,
      productId: productId,
      mode: MeasurementMode.package,
      quantity: 3,
    );

    final recreatedPlanId = await shopping.createPlanFromRemainingItems(
      sourcePlanId: sourcePlanId,
      newPlanName: 'Lista restante',
    );

    final plans = await database.select(database.shoppingPlans).get();
    final recreated = plans.singleWhere((plan) => plan.id == recreatedPlanId);
    final items = await database.select(database.plannedItems).get();
    final recreatedItem = items.singleWhere(
      (item) => item.planId == recreatedPlanId,
    );
    expect(recreated.syncId, startsWith('plan:'));
    expect(recreated.logicalKey, 'plan:2026-11:lista restante');
    expect(recreated.authorUid, 'member-list');
    expect(recreated.reviewState, CollaborationMetadata.pendingReview);
    expect(recreatedItem.syncId, startsWith('planned-item:'));
    expect(recreatedItem.logicalKey, contains(recreated.syncId));
    expect(recreatedItem.authorUid, 'member-list');
    expect(recreatedItem.reviewState, CollaborationMetadata.pendingReview);
  });

  test('re-adicao preserva tombstone e cria nova identidade', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final actor = _actor(
      CollaborationRole.member,
      uid: 'member-readd',
      name: 'Membro',
    );
    final productId = await CatalogRepository(database, actorResolver: actor)
        .saveProduct(
          name: 'Carne de Hambúrguer',
          measurementMode: MeasurementMode.unit,
          needsCategoryReview: false,
        );
    final shopping = ShoppingRepository(database, actorResolver: actor);
    final planId = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Compras',
    );
    final firstId = await shopping.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
    );
    final first = await (database.select(
      database.plannedItems,
    )..where((item) => item.id.equals(firstId))).getSingle();
    await shopping.removePlannedItem(firstId);
    final secondId = await shopping.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
    );

    final rows = await database.select(database.plannedItems).get();
    expect(rows, hasLength(2));
    final tombstone = rows.singleWhere((item) => item.id == firstId);
    final readded = rows.singleWhere((item) => item.id == secondId);
    expect(tombstone.isRemoved, isTrue);
    expect(tombstone.deletedAt, isNotNull);
    expect(readded.isRemoved, isFalse);
    expect(readded.deletedAt, isNull);
    expect(readded.syncId, isNot(first.syncId));
    expect(readded.logicalKey, first.logicalKey);
    expect(readded.reviewState, CollaborationMetadata.pendingReview);
  });

  test('normalizacao realoca PK remota e corrige referencias', () {
    final local = _fullPayload(
      products: [_row('product:local', 'product:local', 'Local')],
      plans: [_row('plan:local', 'plan:local', 'Lista local', id: 1)],
      items: [
        {
          ..._row(
            'planned-item:plan:local:product:local',
            'planned-item:local',
            'Item local',
            id: 1,
          ),
          'planId': 1,
          'productId': 1,
          'planSyncId': 'plan:local',
          'productSyncId': 'product:local',
        },
      ],
    );
    final merged = _fullPayload(
      products: [
        _row('product:local', 'product:local', 'Local'),
        _row('product:remote', 'product:remote', 'Remoto'),
      ],
      plans: [_row('plan:local', 'plan:local', 'Lista local', id: 1)],
      items: [
        {
          ..._row(
            'planned-item:plan:local:product:local',
            'planned-item:local',
            'Item local',
            id: 1,
          ),
          'planId': 1,
          'productId': 1,
          'planSyncId': 'plan:local',
          'productSyncId': 'product:local',
        },
      ],
    );

    final normalized = CollaborativeIdentityNormalizer.normalize(local, merged);
    final products = normalized['products'] as List;
    final localProduct = products.firstWhere(
      (row) => row['syncId'] == 'product:local',
    ) as Map<String, dynamic>;
    final remoteProduct = products.firstWhere(
      (row) => row['syncId'] == 'product:remote',
    ) as Map<String, dynamic>;
    expect(localProduct['id'], 1);
    expect(remoteProduct['id'], 2);
    expect((normalized['plannedItems'] as List).single['productId'], 1);
  });

  test('backup 7 rejeita syncId duplicado na mesma tabela', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = CatalogRepository(database);
    await repository.saveProduct(
      name: 'Arroz',
      measurementMode: MeasurementMode.package,
      needsCategoryReview: false,
    );
    await repository.saveProduct(
      name: 'Feijão',
      measurementMode: MeasurementMode.package,
      needsCategoryReview: false,
    );
    final payload = jsonDecode(
      await BackupService(database).createBackup(),
    ) as Map<String, dynamic>;
    final products = payload['products'] as List;
    (products.first as Map<String, dynamic>)['syncId'] =
        (products.last as Map<String, dynamic>)['syncId'];

    expect(
      () =>
          BackupService(database).validateAndDecodeBackup(jsonEncode(payload)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('identificador sincronizado duplicado'),
        ),
      ),
    );
  });

  group('merge por item', () {
    test('une alteracoes em logical keys diferentes', () {
      final result = const CollaborativeAreaMerger().merge(
        _area([_row('product:a', 'product:a', 'Arroz')]),
        _area([_row('product:b', 'product:b', 'Feijao')]),
      );

      expect(result.hasConflicts, isFalse);
      final rows = result.payload['products'] as List;
      expect(rows, hasLength(2));
    });

    test('mantem conflito quando a mesma chave muda dos dois lados', () {
      final result = const CollaborativeAreaMerger().merge(
        _area([_row('product:a', 'product:a', 'Arroz local')]),
        _area([_row('product:a', 'product:a', 'Arroz remoto')]),
      );

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.single.reason, 'same_item_changed_without_base');
    });

    test('mantem conflito quando logical key tem sync IDs diferentes', () {
      final result = const CollaborativeAreaMerger().merge(
        _area([_row('product:a', 'product:a', 'Arroz')]),
        _area([_row('product:a', 'product:other', 'Arroz')]),
      );

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.single.reason, 'duplicate_logical_key');
    });

    test('aceita item novo quando historico só difere em IDs locais', () {
      Map<String, dynamic> area({
        required int tripId,
        required int lineId,
        required int quantity,
      }) => {
        'formatVersion': 7,
        'products': const <Object?>[],
        'shoppingPlans': const <Object?>[],
        'plannedItems': [
          {
            'id': 5,
            'logicalKey': 'planned-item:plan:product',
            'syncId': 'planned-item:new',
            'name': 'Novo item',
            'syncRevision': 0,
          },
        ],
        'shoppingTrips': [
          {
            'id': tripId,
            'planId': tripId + 10,
            'originPlanNameSnapshot': 'Compras',
            'purchaseDate': '2026-11-25',
            'marketName': 'Mercado',
            'status': 'completed',
          },
        ],
        'purchaseLines': [
          {
            'id': lineId,
            'tripId': tripId,
            'productId': lineId + 20,
            'plannedItemId': lineId + 30,
            'productNameSnapshot': 'Arroz',
            'measurementMode': 'package',
            'quantity': quantity,
            'totalCents': 500,
            'status': 'purchased',
          },
        ],
      };

      final result = const CollaborativeAreaMerger().merge(
        area(tripId: 10, lineId: 20, quantity: 2),
        area(tripId: 90, lineId: 80, quantity: 2),
      );

      expect(result.hasConflicts, isFalse);
      expect(result.payload['plannedItems'], hasLength(1));
      expect((result.payload['shoppingTrips'] as List).single['id'], 90);
      expect((result.payload['purchaseLines'] as List).single['id'], 80);
    });

    test('mantem conflito quando historico muda semanticamente', () {
      Map<String, dynamic> area(int quantity) => {
        'formatVersion': 7,
        'products': const <Object?>[],
        'shoppingPlans': const <Object?>[],
        'plannedItems': const <Object?>[],
        'shoppingTrips': const <Object?>[],
        'purchaseLines': [
          {
            'id': 1,
            'tripId': 1,
            'productId': 1,
            'plannedItemId': null,
            'productNameSnapshot': 'Arroz',
            'measurementMode': 'package',
            'quantity': quantity,
            'totalCents': 500,
            'status': 'purchased',
          },
        ],
      };

      final result = const CollaborativeAreaMerger().merge(area(2), area(3));

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.single.reason, 'non_collaborative_area_changed');
    });

    test('ordem das chaves do Firestore nao cria falso conflito', () {
      final result = const CollaborativeAreaMerger().merge(
        _area([
          {
            'id': 1,
            'logicalKey': 'product:arroz:package',
            'syncId': 'product:arroz',
            'name': 'Arroz',
            'syncRevision': 1,
            'details': {'unit': 'package', 'brand': 'Marca'},
          },
        ]),
        _area([
          {
            'details': {'brand': 'Marca', 'unit': 'package'},
            'syncRevision': 1,
            'name': 'Arroz',
            'syncId': 'product:arroz',
            'logicalKey': 'product:arroz:package',
            'id': 99,
          },
        ]),
      );

      expect(result.hasConflicts, isFalse);
      expect(result.payload['products'], hasLength(1));
    });

    test('tombstone e re-adicao convivem com identidades diferentes', () {
      final result = const CollaborativeAreaMerger().merge(
        {
          'products': const <Object?>[],
          'shoppingPlans': const <Object?>[],
          'plannedItems': [
            {
              ..._row('planned-item:plan:product', 'planned-item:new', 'Carne'),
              'id': 2,
              'deletedAt': null,
            },
          ],
        },
        {
          'products': const <Object?>[],
          'shoppingPlans': const <Object?>[],
          'plannedItems': [
            {
              ..._row(
                'planned-item:plan:product',
                'planned-item:old',
                'Carne',
                id: 1,
              ),
              'deletedAt': '2026-11-25T18:55:18.000Z',
            },
          ],
        },
      );

      expect(result.hasConflicts, isFalse);
      expect(result.payload['plannedItems'], hasLength(2));
    });

    test('tombstone impede ressurreicao de item vivo', () {
      final result = const CollaborativeAreaMerger().merge(
        _area([_row('product:a', 'product:a', 'Arroz')]),
        _area([
          {
            ..._row('product:a', 'product:a', 'Arroz'),
            'deletedAt': '2026-11-25T12:00:00.000Z',
            'syncRevision': 2,
          },
        ]),
      );

      expect(result.hasConflicts, isFalse);
      final row = (result.payload['products'] as List).single as Map;
      expect(row['deletedAt'], '2026-11-25T12:00:00.000Z');
    });
  });
}

CollaborationActorResolver _actor(
  CollaborationRole role, {
  required String uid,
  required String name,
}) =>
    () async => CollaborationActor(uid: uid, displayName: name, role: role);

Map<String, dynamic> _area(List<Map<String, dynamic>> products) => {
  'formatVersion': 7,
  'products': products,
  'shoppingPlans': const <Object?>[],
  'plannedItems': const <Object?>[],
  'categories': const <Object?>[],
  'subcategories': const <Object?>[],
};

Map<String, dynamic> _row(
  String logicalKey,
  String syncId,
  String name, {
  int id = 1,
}) => {
  'id': id,
  'logicalKey': logicalKey,
  'syncId': syncId,
  'name': name,
  'syncRevision': 1,
};

Map<String, dynamic> _fullPayload({
  required List<Map<String, dynamic>> products,
  required List<Map<String, dynamic>> plans,
  required List<Map<String, dynamic>> items,
}) => {
  'formatVersion': 7,
  'products': products,
  'shoppingPlans': plans,
  'plannedItems': items,
  'importEntries': const <Object?>[],
  'purchaseLines': const <Object?>[],
};
