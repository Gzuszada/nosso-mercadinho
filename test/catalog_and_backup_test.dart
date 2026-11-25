import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/backup/data/backup_service.dart';
import 'package:mercado/features/backup/presentation/backup_actions.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/catalog/presentation/catalog_dialogs.dart';
import 'package:mercado/features/catalog/presentation/catalog_screen.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';

void main() {
  late AppDatabase database;
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

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'catálogo revisável preserva origem sem inventar unidades ou compras',
    () async {
      final contents = await File('assets/catalogo-inicial.json')
          .readAsString();
      final catalog = CatalogImport.fromJson(contents);

      expect(catalog.items, hasLength(139));
      expect(
        catalog.items
            .map((item) => item.suggestedCategory)
            .whereType<String>()
            .toSet(),
        hasLength(9),
      );

      expect(catalog.productsWithoutCategory, 13);
      expect(
        catalog.items.every(
          (item) => item.measurementMode == MeasurementMode.pending,
        ),
        isTrue,
      );

      await CatalogRepository(database).importCatalog(catalog);

      final products = await database.select(database.products).get();
      final categories = await database.select(database.categories).get();
      final entries = await database.select(database.importEntries).get();
      final batches = await database.select(database.importBatches).get();

      expect(products, hasLength(139));
      expect(categories, hasLength(9));
      expect(entries, hasLength(139));
      expect(batches, hasLength(1));
      expect(
        products.where((product) => product.needsCategoryReview),
        hasLength(13),
      );
      expect(
        products.every((product) => product.measurementMode == 'pending'),
        isTrue,
      );
      expect(products.every((product) => product.categoryId != null), isFalse);
      expect(
        await database
            .select(database.products)
            .get()
            .then((rows) => rows.where((row) => row.categoryId == null).length),
        13,
      );
    },
  );

  test(
    'catálogo inicial continua disponível após restaurar backup vazio',
    () async {
      final emptyDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(emptyDatabase.close);
      final emptyBackup = await BackupService(emptyDatabase).createBackup();
      final repository = CatalogRepository(database);
      await repository.saveProduct(
        name: 'Produto anterior à restauração',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );

      await BackupService(database).restoreBackup(emptyBackup);
      final bundledCatalog = CatalogImport.fromJson(
        await File('assets/catalogo-inicial.json').readAsString(),
      );
      await repository.importCatalog(bundledCatalog);

      expect(await database.select(database.products).get(), hasLength(139));
      expect(await database.select(database.categories).get(), hasLength(9));
      expect(
        await database
            .select(database.products)
            .get()
            .then(
              (products) => products.any(
                (product) => product.name == 'Produto anterior à restauração',
              ),
            ),
        isFalse,
      );
    },
  );

  test('salva backup Android pelo seletor nativo de documentos', () async {
    const channel = MethodChannel('br.com.nocorre.mercado/backup_files');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveJson');
      expect(call.arguments, {
        'fileName': 'mercado-backup.json',
        'contents': '{"formatVersion":5}',
        'disallowSameUri': null,
      });
      return true;
    });

    try {
      expect(
        await saveBackupJson('{"formatVersion":5}', 'mercado-backup.json'),
        isTrue,
      );
    } finally {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  test('backup vazio mostra erro específico', () {
    expect(
      () => BackupService(database).validateBackup(''),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('O arquivo selecionado está vazio'),
        ),
      ),
    );
  });

  testWidgets('restaurar backup pede confirmação e cópia de segurança', (
    tester,
  ) async {
    final targetDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDatabase.close);
    await CatalogRepository(database).saveProduct(
      name: 'Produto local',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    await CatalogRepository(targetDatabase).saveProduct(
      name: 'Produto do backup',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final targetBackup = await BackupService(targetDatabase).createBackup();
    const channel = MethodChannel('br.com.nocorre.mercado/backup_files');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final previousPlatform = debugDefaultTargetPlatformOverride;
    String? savedSafetyBackup;
    const selectedBackupUri = 'content://documents/backup';
    Future<bool>? restoreFuture;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'openJson') {
        return {'contents': targetBackup, 'uri': selectedBackupUri};
      }
      if (call.method == 'saveJson') {
        final arguments = call.arguments as Map<Object?, Object?>;
        expect(arguments['fileName'], 'mercado-backup-seguranca.json');
        expect(arguments['disallowSameUri'], selectedBackupUri);
        savedSafetyBackup = arguments['contents'] as String;
        return true;
      }
      fail('Unexpected backup channel method: ${call.method}');
    });

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  restoreFuture = restoreBackupFromFile(context, database);
                },
                child: const Text('Restaurar arquivo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Restaurar arquivo'));
      await tester.pumpAndSettle();
      expect(find.text('Substituir os dados atuais?'), findsOneWidget);
      expect(
        find.textContaining('O que existe apenas neste aparelho será perdido.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('O catálogo inicial continua incluído no app'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await restoreFuture, isFalse);
      expect(savedSafetyBackup, isNull);
      expect(await database.select(database.products).get(), hasLength(1));

      await tester.tap(find.text('Restaurar arquivo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(await restoreFuture, isTrue);
      expect(savedSafetyBackup, contains('Produto local'));
      expect(savedSafetyBackup, isNot(contains('Produto do backup')));
      final restoredProducts = await database.select(database.products).get();
      expect(restoredProducts, hasLength(1));
      expect(restoredProducts.single.name, 'Produto do backup');
      expect(tester.takeException(), isNull);
    } finally {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets('edita forma de compra de peso para unidade', (tester) async {
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Amaciante teste',
      measurementMode: MeasurementMode.weight,
      needsCategoryReview: false,
    );
    final product = await (database.select(
      database.products,
    )..where((row) => row.id.equals(productId))).getSingle();
    ProductDraft? savedDraft;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                savedDraft = await showProductDialog(
                  context: context,
                  categories: const [],
                  subcategories: const [],
                  product: product,
                );
              },
              child: const Text('Editar produto teste'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar produto teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MeasurementMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Por unidade').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedDraft?.measurementMode, MeasurementMode.unit);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite escolher compra por pacote no cadastro', (tester) async {
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Guardanapos teste',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final product = await (database.select(
      database.products,
    )..where((row) => row.id.equals(productId))).getSingle();
    ProductDraft? savedDraft;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                savedDraft = await showProductDialog(
                  context: context,
                  categories: const [],
                  subcategories: const [],
                  product: product,
                );
              },
              child: const Text('Editar produto teste'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar produto teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<MeasurementMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Por pacote').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedDraft?.measurementMode, MeasurementMode.package);
    expect(tester.takeException(), isNull);
  });

  test('reimportação do catálogo inicial não duplica registros', () async {
    final catalog = CatalogImport.fromJson(
      await File('assets/catalogo-inicial.json').readAsString(),
    );
    final repository = CatalogRepository(database);

    await repository.importCatalog(catalog);
    await expectLater(
      repository.importCatalog(catalog),
      throwsA(isA<FormatException>()),
    );

    expect(await database.select(database.products).get(), hasLength(139));
  });

  test('ordena categorias e subcategorias sem alterar vínculos', () async {
    final repository = CatalogRepository(database);
    final firstCategory = await repository.saveCategory(name: 'A');
    final secondCategory = await repository.saveCategory(name: 'B');
    final thirdCategory = await repository.saveCategory(name: 'C');
    final firstSubcategory = await repository.saveSubcategory(
      categoryId: firstCategory,
      name: 'Uma',
    );
    final secondSubcategory = await repository.saveSubcategory(
      categoryId: firstCategory,
      name: 'Duas',
    );

    await repository.reorderCategories([
      thirdCategory,
      secondCategory,
      firstCategory,
    ]);
    await repository.reorderSubcategories(firstCategory, [
      secondSubcategory,
      firstSubcategory,
    ]);

    expect(
      (await database.watchCategories().first).map((category) => category.id),
      [thirdCategory, secondCategory, firstCategory],
    );
    expect(
      (await database.watchSubcategories().first).map(
        (subcategory) => subcategory.id,
      ),
      [secondSubcategory, firstSubcategory],
    );
    await expectLater(
      repository.reorderCategories([firstCategory, firstCategory]),
      throwsA(isA<FormatException>()),
    );
  });

  test('apaga categoria sem produtos e suas subcategorias', () async {
    final repository = CatalogRepository(database);
    final categoryId = await repository.saveCategory(name: 'Bebidas');
    await repository.saveSubcategory(categoryId: categoryId, name: 'Sucos');

    expect(await repository.hasProductsInCategory(categoryId), isFalse);
    expect(
      await repository.deleteCategoryIfUnused(categoryId),
      CategoryDeletionResult.deleted,
    );
    expect(await database.select(database.categories).get(), isEmpty);
    expect(await database.select(database.subcategories).get(), isEmpty);
    expect(
      await repository.deleteCategoryIfUnused(categoryId),
      CategoryDeletionResult.notFound,
    );
  });

  test('não apaga categoria com produto vinculado', () async {
    final repository = CatalogRepository(database);
    final categoryId = await repository.saveCategory(name: 'Limpeza');
    final productId = await repository.saveProduct(
      name: 'Detergente',
      categoryId: categoryId,
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    await repository.setProductArchived(productId, true);

    expect(await repository.hasProductsInCategory(categoryId), isTrue);
    expect(
      await repository.deleteCategoryIfUnused(categoryId),
      CategoryDeletionResult.hasProducts,
    );
    expect(await database.select(database.categories).get(), hasLength(1));
  });

  testWidgets('avisa e não oferece confirmação se categoria tem produtos', (
    tester,
  ) async {
    final repository = CatalogRepository(database);
    final categoryId = await repository.saveCategory(name: 'Higiene');
    await repository.saveProduct(
      name: 'Sabonete',
      categoryId: categoryId,
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final categories = await database.select(database.categories).get();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          categoriesProvider.overrideWith((_) => Stream.value(categories)),
          subcategoriesProvider.overrideWith(
            (_) => Stream.value(<Subcategory>[]),
          ),
        ],
        child: const MaterialApp(home: CatalogScreen(initialTab: 1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Higiene'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Categoria não pode ser apagada'), findsOneWidget);
    expect(find.text('Apagar categoria?'), findsNothing);
    expect(await database.select(database.categories).get(), hasLength(1));
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('pede confirmação antes de apagar categoria sem produtos', (
    tester,
  ) async {
    final categoryId = await CatalogRepository(database)
        .saveCategory(name: 'Padaria');
    await CatalogRepository(database)
        .saveSubcategory(categoryId: categoryId, name: 'Pães');
    final categories = await database.select(database.categories).get();
    final subcategories = await database.select(database.subcategories).get();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          categoriesProvider.overrideWith((_) => Stream.value(categories)),
          subcategoriesProvider.overrideWith(
            (_) => Stream.value(subcategories),
          ),
        ],
        child: const MaterialApp(home: CatalogScreen(initialTab: 1)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Padaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Apagar categoria?'), findsOneWidget);
    expect(await database.select(database.categories).get(), hasLength(1));
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    expect(await database.select(database.categories).get(), isEmpty);
    expect(await database.select(database.subcategories).get(), isEmpty);
    expect(find.text('Categoria apagada.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('apaga produto sem vínculos', () async {
    final repository = CatalogRepository(database);
    final productId = await repository.saveProduct(
      name: 'Produto descartável',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );

    expect(
      await repository.checkProductDeletion(productId),
      ProductDeletionResult.ready,
    );
    expect(
      await repository.deleteProductIfUnused(productId),
      ProductDeletionResult.deleted,
    );
    final tombstone = await database.select(database.products).getSingle();
    expect(tombstone.deletedAt, isNotNull);
    expect(tombstone.isArchived, isTrue);
    expect(await database.watchProducts().first, isEmpty);
    expect(
      await repository.deleteProductIfUnused(productId),
      ProductDeletionResult.notFound,
    );
  });

  test('bloqueia produto com compra concluída', () async {
    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto comprado',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final shopping = ShoppingRepository(database);
    final tripId = await shopping.createTrip(
      purchaseDate: DateTime(2026, 11, 2),
    );
    await shopping.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 100,
    );
    await shopping.completeTrip(tripId);

    expect(
      await catalog.checkProductDeletion(productId),
      ProductDeletionResult.hasCompletedPurchases,
    );
    expect(
      await catalog.deleteProductIfUnused(productId),
      ProductDeletionResult.hasCompletedPurchases,
    );
    expect(await database.select(database.products).get(), hasLength(1));
  });

  test(
    'preserva linhas de compras não concluídas ao bloquear exclusão',
    () async {
      final catalog = CatalogRepository(database);
      final shopping = ShoppingRepository(database);
      final activeProductId = await catalog.saveProduct(
        name: 'Produto no carrinho',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final activeTripId = await shopping.createTrip(
        purchaseDate: DateTime(2026, 11, 2),
      );
      final activeLineId = await shopping.addPurchaseLine(
        tripId: activeTripId,
        productId: activeProductId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );

      expect(
        await catalog.deleteProductIfUnused(activeProductId),
        ProductDeletionResult.hasInProgressPurchases,
      );
      expect(await database.select(database.purchaseLines).get(), hasLength(1));
      await shopping.removePurchaseLine(activeLineId);
      expect(
        await catalog.deleteProductIfUnused(activeProductId),
        ProductDeletionResult.deleted,
      );
      await shopping.cancelTrip(activeTripId);

      final canceledProductId = await catalog.saveProduct(
        name: 'Produto em compra cancelada',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final canceledTripId = await shopping.createTrip(
        purchaseDate: DateTime(2026, 11, 2),
      );
      await shopping.addPurchaseLine(
        tripId: canceledTripId,
        productId: canceledProductId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );
      await shopping.cancelTrip(canceledTripId);

      expect(
        await catalog.deleteProductIfUnused(canceledProductId),
        ProductDeletionResult.hasCanceledPurchases,
      );
      expect(await database.select(database.purchaseLines).get(), hasLength(1));
      final products = await database.select(database.products).get();
      expect(products, hasLength(2));
      expect(
        products.where((product) => product.deletedAt != null),
        hasLength(1),
      );
      expect(
        products.where((product) => product.deletedAt == null),
        hasLength(1),
      );
    },
  );

  test('pede retirada da lista antes de apagar produto', () async {
    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto planejado',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final shopping = ShoppingRepository(database);
    final planId = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Lista de teste',
    );
    final itemId = await shopping.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
    );

    expect(
      await catalog.deleteProductIfUnused(productId),
      ProductDeletionResult.hasPlannedItems,
    );
    expect(await database.select(database.products).get(), hasLength(1));

    await shopping.removePlannedItem(itemId);
    expect(
      await catalog.deleteProductIfUnused(productId),
      ProductDeletionResult.deleted,
    );
    final products = await database.select(database.products).get();
    expect(products, hasLength(1));
    expect(products.single.deletedAt, isNotNull);
    final items = await database.select(database.plannedItems).get();
    expect(items, hasLength(1));
    expect(items.single.deletedAt, isNotNull);
    expect(items.single.isRemoved, isTrue);
  });

  testWidgets('avisa se produto ainda está na lista e depois permite apagar', (
    tester,
  ) async {
    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto da lista',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final shopping = ShoppingRepository(database);
    final planId = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Lista de teste',
    );
    final itemId = await shopping.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
    );
    final products = await database.select(database.products).get();
    final categories = await database.select(database.categories).get();
    final subcategories = await database.select(database.subcategories).get();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          productsProvider.overrideWith((_) => Stream.value(products)),
          categoriesProvider.overrideWith((_) => Stream.value(categories)),
          subcategoriesProvider.overrideWith(
            (_) => Stream.value(subcategories),
          ),
        ],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações do produto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Produto não pode ser apagado'), findsOneWidget);
    expect(find.textContaining('Retire-o da lista primeiro'), findsOneWidget);
    expect(find.text('Apagar produto?'), findsNothing);
    expect(await database.select(database.products).get(), hasLength(1));

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    await shopping.removePlannedItem(itemId);
    await tester.tap(find.byTooltip('Ações do produto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('Apagar produto?'), findsOneWidget);
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();
    final deletedProducts = await database.select(database.products).get();
    expect(deletedProducts, hasLength(1));
    expect(deletedProducts.single.deletedAt, isNotNull);
    expect(find.text('Produto apagado.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test(
    'CRUD e backup/restauração preservam vínculos e revisão pendente',
    () async {
      final repository = CatalogRepository(database);
      final categoryId = await repository.saveCategory(name: 'Mercearia');
      final subcategoryId = await repository.saveSubcategory(
        categoryId: categoryId,
        name: 'Massas',
      );
      final productId = await repository.saveProduct(
        name: 'Macarrão',
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );

      final backup = await BackupService(database)
          .createBackup(exportedAt: DateTime.utc(2026, 10, 31));
      final restoredDatabase = AppDatabase(NativeDatabase.memory());
      addTearDown(restoredDatabase.close);
      await BackupService(restoredDatabase).restoreBackup(backup);

      final restoredProduct = await (restoredDatabase.select(
        restoredDatabase.products,
      )..where((product) => product.id.equals(productId))).getSingle();
      final restoredSubcategory =
          await (restoredDatabase.select(restoredDatabase.subcategories)
                ..where((subcategory) => subcategory.id.equals(subcategoryId)))
              .getSingle();

      expect(restoredProduct.name, 'Macarrão');
      expect(restoredProduct.measurementMode, 'pending');
      expect(restoredProduct.categoryId, categoryId);
      expect(restoredProduct.subcategoryId, subcategoryId);
      expect(restoredSubcategory.categoryId, categoryId);

      await expectLater(
        BackupService(restoredDatabase).restoreBackup(
          backup.replaceFirst('"formatVersion": 7', '"formatVersion": 99'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        await restoredDatabase.select(restoredDatabase.products).get(),
        hasLength(1),
      );
    },
  );

  test('catálogo permanece após fechar e reabrir o arquivo SQLite', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mercado-persistence-test-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}catalog.sqlite',
    );
    AppDatabase? fileDatabase;

    try {
      fileDatabase = AppDatabase(NativeDatabase(file));
      final repository = CatalogRepository(fileDatabase);
      final categoryId = await repository.saveCategory(name: 'Hortifruti');
      await repository.saveProduct(
        name: 'Tomate',
        categoryId: categoryId,
        measurementMode: MeasurementMode.weight,
        needsCategoryReview: false,
      );
      await fileDatabase.close();
      fileDatabase = null;

      fileDatabase = AppDatabase(NativeDatabase(file));
      final products = await fileDatabase.select(fileDatabase.products).get();
      expect(products, hasLength(1));
      expect(products.single.name, 'Tomate');
      expect(products.single.measurementMode, 'weight');
      expect(
        await fileDatabase.select(fileDatabase.categories).get(),
        hasLength(1),
      );
    } finally {
      await fileDatabase?.close();
      await directory.delete(recursive: true);
    }
  });

  test('backup completo preserva lote, entradas e arquivamento', () async {
    final catalog = CatalogImport.fromJson(
      await File('assets/catalogo-inicial.json').readAsString(),
    );
    await CatalogRepository(database).importCatalog(catalog);
    final products = await database.select(database.products).get();
    await CatalogRepository(database).archiveProduct(products.first.id);

    final backup = await BackupService(database).createBackup();
    final restoredDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(restoredDatabase.close);
    await BackupService(restoredDatabase).restoreBackup(backup);

    final restoredProducts = await restoredDatabase
        .select(restoredDatabase.products)
        .get();
    expect(restoredProducts, hasLength(139));
    expect(
      await restoredDatabase.select(restoredDatabase.categories).get(),
      hasLength(9),
    );
    expect(
      await restoredDatabase.select(restoredDatabase.importBatches).get(),
      hasLength(1),
    );
    expect(
      await restoredDatabase.select(restoredDatabase.importEntries).get(),
      hasLength(139),
    );
    expect(
      restoredProducts.where((product) => product.isArchived),
      hasLength(1),
    );
  });

  test('restauração com erro durante transação preserva banco atual', () async {
    final catalog = CatalogImport.fromJson(
      await File('assets/catalogo-inicial.json').readAsString(),
    );
    await CatalogRepository(database).importCatalog(catalog);
    final service = BackupService(database);
    final backup = await service.createBackup();
    final payload = jsonDecode(backup) as Map<String, dynamic>;
    final batches = payload['importBatches'] as List<dynamic>;
    final duplicateBatch = Map<String, dynamic>.from(batches.single as Map);
    duplicateBatch['id'] = 9999;
    batches.add(duplicateBatch);

    await expectLater(
      service.restoreBackup(jsonEncode(payload)),
      throwsA(isA<Exception>()),
    );
    expect(await database.select(database.products).get(), hasLength(139));
    expect(await database.select(database.categories).get(), hasLength(9));
    expect(await database.select(database.importBatches).get(), hasLength(1));
  });
}
