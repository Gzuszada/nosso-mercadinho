import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/backup/data/backup_service.dart';
import 'package:mercado/features/settings/data/reset_service.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';
import 'package:mercado/features/settings/presentation/settings_screen.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';
import 'package:mercado/main.dart';

void main() {
  late AppDatabase database;
  late ResetService resetService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    resetService = ResetService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'limpar listas preserva compras e mantém fotografia da origem',
    () async {
      final catalog = CatalogRepository(database);
      final productId = await catalog.saveProduct(
        name: 'Produto de teste',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final shopping = ShoppingRepository(database);
      final planId = await shopping.createPlan(
        monthKey: '2026-11',
        name: 'Lista preservada no histórico',
      );
      final plannedItemId = await shopping.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 3,
      );
      final tripId = await shopping.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await shopping.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.unit,
        quantity: 2,
        unitPriceCents: 500,
      );
      await shopping.completeTrip(tripId);

      await resetService.clear(const ResetSelection(lists: true));

      expect(await database.select(database.shoppingPlans).get(), isEmpty);
      expect(await database.select(database.plannedItems).get(), isEmpty);
      final trip = (await database.select(database.shoppingTrips).get()).single;
      expect(trip.planId, isNull);
      expect(trip.originPlanNameSnapshot, 'Lista preservada no histórico');
      final line = (await database.select(database.purchaseLines).get()).single;
      expect(line.plannedItemId, isNull);
      expect(line.productNameSnapshot, 'Produto de teste');

      final backup = await BackupService(database).createBackup();
      await BackupService(database).restoreBackup(backup);
      final restoredTrip =
          (await database.select(database.shoppingTrips).get()).single;
      expect(
        restoredTrip.originPlanNameSnapshot,
        'Lista preservada no histórico',
      );
    },
  );

  test(
    'limpar histórico preserva carrinhos e remove estimativas dependentes',
    () async {
      final productId = await CatalogRepository(database).saveProduct(
        name: 'Produto histórico',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final shopping = ShoppingRepository(database);
      final completedTrip = await shopping.createTrip(
        purchaseDate: DateTime(2026, 10, 10),
      );
      await shopping.addPurchaseLine(
        tripId: completedTrip,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 700,
      );
      await shopping.completeTrip(completedTrip);
      final planId = await shopping.createPlan(
        monthKey: '2026-11',
        name: 'Plano com referência histórica',
      );
      final itemId = await shopping.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 2,
      );
      final canceledTrip = await shopping.createTrip(
        purchaseDate: DateTime(2026, 11, 2),
      );
      await shopping.cancelTrip(canceledTrip);
      final activeTrip = await shopping.createTrip(
        purchaseDate: DateTime(2026, 11, 1),
      );

      await resetService.clear(const ResetSelection(history: true));

      final trips = await database.select(database.shoppingTrips).get();
      expect(trips.map((trip) => trip.id).toSet(), {activeTrip, canceledTrip});
      expect(await database.select(database.purchaseLines).get(), isEmpty);
      final item = await (database.select(
        database.plannedItems,
      )..where((row) => row.id.equals(itemId))).getSingle();
      expect(item.estimateSource, isNull);
      expect(item.estimatePriceNumeratorCents, isNull);
    },
  );

  test('limpar carrinhos preserva compras concluídas e o histórico', () async {
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto de compras',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final shopping = ShoppingRepository(database);
    final completedTrip = await shopping.createTrip(
      purchaseDate: DateTime(2026, 10, 10),
    );
    await shopping.addPurchaseLine(
      tripId: completedTrip,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 500,
    );
    await shopping.completeTrip(completedTrip);
    final activePlan = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Lista em andamento',
    );
    final activeTrip = await shopping.createTrip(
      planId: activePlan,
      purchaseDate: DateTime(2026, 11, 1),
    );
    final canceledPlan = await shopping.createPlan(
      monthKey: '2026-11',
      name: 'Lista cancelada',
    );
    final canceledTrip = await shopping.createTrip(
      planId: canceledPlan,
      purchaseDate: DateTime(2026, 11, 2),
    );
    await shopping.cancelTrip(canceledTrip);

    await resetService.clear(const ResetSelection(unfinishedPurchases: true));

    final trips = await database.select(database.shoppingTrips).get();
    expect(trips.map((trip) => trip.id), [completedTrip]);
    expect(await database.select(database.purchaseLines).get(), hasLength(1));
    expect(
      await (database.select(
        database.shoppingTrips,
      )..where((row) => row.id.equals(activeTrip))).get(),
      isEmpty,
    );
  });

  test(
    'limpar produtos arquiva os vinculados e exclui os sem vínculos',
    () async {
      final catalog = CatalogRepository(database);
      final usedProductId = await catalog.saveProduct(
        name: 'Produto usado',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final unusedProductId = await catalog.saveProduct(
        name: 'Produto sem vínculo',
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );
      final shopping = ShoppingRepository(database);
      final planId = await shopping.createPlan(
        monthKey: '2026-11',
        name: 'Lista com produto',
      );
      await shopping.addPlannedItem(
        planId: planId,
        productId: usedProductId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );

      await resetService.clear(const ResetSelection(products: true));

      final products = await database.select(database.products).get();
      expect(products, hasLength(1));
      expect(products.single.id, usedProductId);
      expect(products.single.isArchived, isTrue);
      expect(
        await (database.select(
          database.products,
        )..where((row) => row.id.equals(unusedProductId))).get(),
        isEmpty,
      );
      expect(await database.select(database.plannedItems).get(), hasLength(1));
    },
  );

  test('limpar categorias desclassifica produtos sem apagá-los', () async {
    final catalog = CatalogRepository(database);
    final categoryId = await catalog.saveCategory(name: 'Categoria teste');
    final subcategoryId = await catalog.saveSubcategory(
      categoryId: categoryId,
      name: 'Subcategoria teste',
    );
    final productId = await catalog.saveProduct(
      name: 'Produto classificado',
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );

    await resetService.clear(const ResetSelection(categories: true));

    final product = await (database.select(
      database.products,
    )..where((row) => row.id.equals(productId))).getSingle();
    expect(product.categoryId, isNull);
    expect(product.subcategoryId, isNull);
    expect(await database.select(database.categories).get(), isEmpty);
    expect(await database.select(database.subcategories).get(), isEmpty);
  });

  test('limpar tudo remove dados do app, mas mantém modo escuro', () async {
    await SettingsRepository(database).setDarkMode(true);
    await CatalogRepository(database).saveCategory(name: 'Categoria teste');
    await ShoppingRepository(database)
        .createPlan(monthKey: '2026-11', name: 'Lista teste');

    await resetService.clear(const ResetSelection(all: true));

    expect(await database.select(database.categories).get(), isEmpty);
    expect(await database.select(database.shoppingPlans).get(), isEmpty);
    expect(await database.select(database.products).get(), isEmpty);
    final preference = await (database.select(
      database.appPreferences,
    )..where((row) => row.id.equals(1))).getSingle();
    expect(preference.isDarkMode, isTrue);
  });

  testWidgets('preferência de modo escuro é persistida e aplicada', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MercadoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final preference = await (database.select(
      database.appPreferences,
    )..where((row) => row.id.equals(1))).getSingle();
    expect(preference.isDarkMode, isTrue);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('reset seletivo exige revisão e confirmação digitada', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
    await ShoppingRepository(database)
        .createPlan(monthKey: '2026-11', name: 'Lista para limpar');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resetar base'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listas').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continuar para confirmação'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continuar para confirmação'));
    await tester.pumpAndSettle();
    expect(find.text('Confira o que será apagado'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('LIMPAR LISTAS'), findsOneWidget);
    final clearButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Apagar dados'),
    );
    expect(clearButton.onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'LIMPAR LISTAS');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apagar dados'));
    await tester.pumpAndSettle();

    expect(await database.select(database.shoppingPlans).get(), isEmpty);
    expect(find.text('Configurações'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
