import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/backup/data/backup_service.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';
import 'package:mercado/features/shopping/domain/shopping_calculations.dart';
import 'package:mercado/features/shopping/domain/shopping_history.dart';

void main() {
  late AppDatabase database;
  late ShoppingRepository repository;
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
    repository = ShoppingRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'converte valores pt-BR e calcula unidade, pacote e peso sem double',
    () {
      expect(ShoppingCalculations.parseMoneyToCents('12,34'), 1234);
      expect(ShoppingCalculations.parseMoneyToCents('1.234,56'), 123456);
      expect(ShoppingCalculations.parseMoneyToCents('1234.56'), 123456);
      expect(ShoppingCalculations.parseMoneyToCents('1.234'), 123400);
      expect(ShoppingCalculations.formatMoney(123456), 'R\$ 1.234,56');
      expect(
        ShoppingCalculations.calculateLineTotalCents(
          mode: MeasurementMode.unit,
          quantity: 2,
          unitPriceCents: 800,
        ),
        1600,
      );
      expect(MeasurementMode.package.label, 'Por pacote');
      expect(
        ShoppingCalculations.formatQuantity(MeasurementMode.package, 2),
        '2 pacotes',
      );
      expect(
        ShoppingCalculations.calculateLineTotalCents(
          mode: MeasurementMode.package,
          quantity: 3,
          unitPriceCents: 725,
        ),
        2175,
      );
      expect(
        ShoppingCalculations.parseWeightGrams(
          '0,750',
          WeightInputUnit.kilograms,
        ),
        750,
      );
      expect(
        ShoppingCalculations.calculateLineTotalCents(
          mode: MeasurementMode.weight,
          quantity: 750,
          unitPriceCents: 3990,
        ),
        2993,
      );
      expect(
        ShoppingCalculations.calculateLineTotalCents(
          mode: MeasurementMode.weight,
          quantity: 1200,
          unitPriceCents: 4290,
        ),
        5148,
      );
      expect(
        ShoppingCalculations.calculateLineTotalCents(
          mode: MeasurementMode.weight,
          quantity: 500,
          unitPriceCents: 1,
        ),
        1,
      );
      expect(ShoppingCalculations.sumCents([2993, 5148]), 8141);
      expect(
        () => ShoppingCalculations.parseMoneyToCents('1,234'),
        throwsFormatException,
      );
    },
  );

  test(
    'histórico mensal usa data real e compara só com o mês civil anterior',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Arroz do histórico',
        mode: MeasurementMode.unit,
      );
      await _completeTripWithLines(
        repository: repository,
        productId: productId,
        date: DateTime(2025, 12, 31),
        lines: [(1, 100)],
      );
      await _completeTripWithLines(
        repository: repository,
        productId: productId,
        date: DateTime(2026, 1, 31),
        lines: [(2, 200), (3, 150)],
        market: 'Compra de janeiro',
      );
      await _completeTripWithLines(
        repository: repository,
        productId: productId,
        date: DateTime(2026, 2, 1),
        lines: [(1, 999)],
      );
      final canceledTrip = await repository.createTrip(
        purchaseDate: DateTime(2026, 1, 15),
      );
      await repository.addPurchaseLine(
        tripId: canceledTrip,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 5000,
      );
      await repository.cancelTrip(canceledTrip);
      final activeTrip = await repository.createTrip(
        purchaseDate: DateTime(2026, 1, 20),
      );
      await repository.addPurchaseLine(
        tripId: activeTrip,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 6000,
      );

      final january = await repository.getMonthlyHistory('2026-01');
      expect(january.totalCents, 850);
      expect(january.trips, hasLength(1));
      expect(january.products.single.quantity, 5);
      expect(january.products.single.totalCents, 850);
      expect(january.products.single.previousMonthQuantity, 1);
      expect(january.products.single.previousMonthTotalCents, 100);
      expect(
        january.products.single.latestPurchase?.trip.purchaseDate,
        '2026-01-31',
      );
      expect(january.products.single.latestPurchase?.unitPriceCents, 170);

      final february = await repository.getMonthlyHistory('2026-02');
      expect(february.totalCents, 999);
      expect(february.products.single.previousMonthTotalCents, 850);
      expect(
        february.products.single.latestPurchase?.trip.purchaseDate,
        '2026-02-01',
      );
    },
  );

  test('estimativa fotografada não usa compra futura e projeção calcula somente restante', () async {
    final productId = await _createProduct(
      database,
      name: 'Feijão estimado',
      mode: MeasurementMode.unit,
    );
    await _completeTripWithLines(
      repository: repository,
      productId: productId,
      date: DateTime(2026, 10, 10),
      lines: [(2, 800), (3, 750)],
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista com estimativa',
    );
    final itemId = await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 5,
    );
    var item = await (database.select(
      database.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingle();
    expect(item.estimateSource, 'history');
    expect(item.estimatePriceNumeratorCents, 3850);
    expect(item.estimateQuantityDenominator, 5);
    expect(item.estimateReferenceDate, '2026-10-10');
    expect(
      ShoppingHistoryCalculations.estimateTotalCents(
        quantity: item.quantity,
        amountCents: item.estimatePriceNumeratorCents!,
        quantityBasis: item.estimateQuantityDenominator!,
      ),
      3850,
    );
    final backup = await BackupService(database).createBackup();
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).restoreBackup(backup);
    final restoredItem = await (restored.select(
      restored.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingle();
    expect(restoredItem.estimateReferenceTripId, item.estimateReferenceTripId);
    expect(restoredItem.estimateReferenceDate, '2026-10-10');

    await _completeTripWithLines(
      repository: repository,
      productId: productId,
      date: DateTime(2026, 10, 20),
      lines: [(1, 1000)],
    );
    item = await (database.select(
      database.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingle();
    expect(item.estimateReferenceDate, '2026-10-10');
    expect(await repository.refreshPlannedItemEstimate(itemId), isTrue);
    item = await (database.select(
      database.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingle();
    expect(item.estimateReferenceDate, '2026-10-20');
    expect(item.estimatePriceNumeratorCents, 1000);
    expect(item.estimateQuantityDenominator, 1);

    final purchasedTrip = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );
    await repository.addPurchaseLine(
      tripId: purchasedTrip,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 2,
      unitPriceCents: 850,
    );
    await repository.addPurchaseLine(
      tripId: purchasedTrip,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 3,
      unitPriceCents: 400,
    );
    final progressBeforeCompletion = await repository.getPlanItemProgress(
      itemId,
    );
    expect(progressBeforeCompletion.remainingFor(5), 3);
    final projection = await repository.getTripProjection(purchasedTrip);
    expect(projection.knownCartCents, 2900);
    expect(projection.plannedCartCents, 1700);
    expect(projection.outsidePlanCartCents, 1200);
    expect(projection.plannedProjectionCents, 4700);
    expect(projection.estimatedRemainingCents, 3000);
    expect(projection.projectedCents, 5900);
    await repository.completeTrip(purchasedTrip);
    final progress = await repository.getPlanItemProgress(itemId);
    expect(progress.purchasedQuantity, 2);
    expect(progress.remainingFor(5), 3);
    expect(
      shoppingPlanListStatus(
        (await repository.watchPlan(planId).first)!,
        await repository.watchTrips().first,
      ),
      ShoppingPlanListStatus.completed,
    );
    await expectLater(
      repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 2),
      ),
      throwsFormatException,
    );
  });

  test(
    'lista exige forma de compra cadastrada e usa o valor atual do produto',
    () async {
      final catalog = CatalogRepository(database);
      final productId = await catalog.saveProduct(
        name: 'Produto sem unidade definida',
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista com produto pendente',
      );

      await expectLater(
        repository.addPlannedItem(
          planId: planId,
          productId: productId,
          quantity: 2,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        (await (database.select(
              database.products,
            )..where((row) => row.id.equals(productId))).getSingle())
            .measurementMode,
        MeasurementMode.pending.name,
      );
      final tripId = await repository.createTrip(
        purchaseDate: DateTime(2026, 11, 1),
      );
      await expectLater(
        repository.addPurchaseLine(
          tripId: tripId,
          productId: productId,
          mode: MeasurementMode.unit,
          quantity: 1,
          unitPriceCents: 100,
        ),
        throwsA(isA<FormatException>()),
      );

      final product = await (database.select(
        database.products,
      )..where((row) => row.id.equals(productId))).getSingle();
      await catalog.saveProduct(
        id: productId,
        name: product.name,
        categoryId: product.categoryId,
        subcategoryId: product.subcategoryId,
        measurementMode: MeasurementMode.weight,
        needsCategoryReview: product.needsCategoryReview,
        description: product.description,
      );
      final itemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        quantity: 1500,
      );
      expect(
        (await (database.select(
          database.plannedItems,
        )..where((row) => row.id.equals(itemId))).getSingle()).measurementMode,
        MeasurementMode.weight.name,
      );
    },
  );

  test('carrinho em andamento persiste após reabrir o banco SQLite', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mercado-cart-recovery-test-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}cart.sqlite');
    AppDatabase? persistentDatabase;
    try {
      persistentDatabase = AppDatabase(NativeDatabase(file));
      final catalog = CatalogRepository(persistentDatabase);
      final productId = await catalog.saveProduct(
        name: 'Produto de recuperação',
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final shopping = ShoppingRepository(persistentDatabase);
      final planId = await shopping.createPlan(
        monthKey: '2026-11',
        name: 'Carrinho recuperável',
      );
      final plannedItemId = await shopping.addPlannedItem(
        planId: planId,
        productId: productId,
        quantity: 5,
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
        unitPriceCents: 750,
      );
      await shopping.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );
      await persistentDatabase.close();
      persistentDatabase = null;

      persistentDatabase = AppDatabase(NativeDatabase(file));
      final restoredShopping = ShoppingRepository(persistentDatabase);
      final trip = await (persistentDatabase.select(
        persistentDatabase.shoppingTrips,
      )..where((row) => row.id.equals(tripId))).getSingle();
      final lines = await restoredShopping.watchPurchaseLines(tripId).first;

      expect(trip.status, 'in_progress');
      expect(lines, hasLength(2));
      expect(lines.where((line) => line.totalCents == null), hasLength(1));
      expect(await restoredShopping.totalForTrip(tripId), 1500);
      expect(
        (await restoredShopping.getPlanItemProgress(plannedItemId))
            .inCartQuantity,
        3,
      );
      await expectLater(
        restoredShopping.completeTrip(tripId),
        throwsA(isA<FormatException>()),
      );

      final backup = await BackupService(persistentDatabase).createBackup();
      final isolatedDatabase = AppDatabase(
        NativeDatabase(
          File('${directory.path}${Platform.pathSeparator}restored.sqlite'),
        ),
      );
      try {
        await BackupService(isolatedDatabase).restoreBackup(backup);
        final restoredTrip = await (isolatedDatabase.select(
          isolatedDatabase.shoppingTrips,
        )..where((row) => row.id.equals(tripId))).getSingle();
        final restoredLines = await isolatedDatabase
            .select(isolatedDatabase.purchaseLines)
            .get();
        expect(restoredTrip.status, 'in_progress');
        expect(restoredLines, hasLength(2));
        expect(
          restoredLines.where((line) => line.totalCents == null),
          hasLength(1),
        );
      } finally {
        await isolatedDatabase.close();
      }
    } finally {
      await persistentDatabase?.close();
      await directory.delete(recursive: true);
    }
  });

  test('compra vinculada preserva a forma fotografada na lista', () async {
    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto com forma alterada',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista com forma original',
    );
    final itemId = await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      quantity: 2,
    );
    final product = await (database.select(
      database.products,
    )..where((row) => row.id.equals(productId))).getSingle();
    await catalog.saveProduct(
      id: productId,
      name: product.name,
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      measurementMode: MeasurementMode.weight,
      needsCategoryReview: product.needsCategoryReview,
      description: product.description,
    );
    final tripId = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );

    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 100,
    );
    final line = (await database.select(database.purchaseLines).get()).single;
    expect(line.measurementMode, MeasurementMode.unit.name);
    expect(
      (await (database.select(
        database.products,
      )..where((row) => row.id.equals(productId))).getSingle()).measurementMode,
      MeasurementMode.weight.name,
    );
  });

  test(
    'estimativa manual por kg e frequência usam apenas compras válidas',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Maçã de frequência',
        mode: MeasurementMode.weight,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-02',
        name: 'Estimativa manual',
      );
      final plannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.weight,
        quantity: 750,
      );
      await repository.setManualEstimate(
        itemId: plannedItemId,
        unitPriceCents: 3990,
        estimatedAt: DateTime(2026, 1, 5),
      );
      final plannedItem = await (database.select(
        database.plannedItems,
      )..where((row) => row.id.equals(plannedItemId))).getSingle();
      expect(plannedItem.estimateSource, 'manual');
      expect(plannedItem.estimateReferenceDate, '2026-01-05');
      expect(
        ShoppingHistoryCalculations.estimateTotalCents(
          quantity: 750,
          amountCents: plannedItem.estimatePriceNumeratorCents!,
          quantityBasis: plannedItem.estimateQuantityDenominator!,
        ),
        2993,
      );

      for (final (date, prices) in [
        (DateTime(2026, 1, 1), [800, 750]),
        (DateTime(2026, 1, 11), [900]),
        (DateTime(2026, 1, 31), [1000]),
        (DateTime(2026, 2, 20), [1200]),
      ]) {
        await _completeTripWithLines(
          repository: repository,
          productId: productId,
          mode: MeasurementMode.weight,
          date: date,
          lines: [for (final price in prices) (1000, price)],
        );
      }
      final canceled = await repository.createTrip(
        purchaseDate: DateTime(2026, 1, 21),
      );
      await repository.addPurchaseLine(
        tripId: canceled,
        productId: productId,
        mode: MeasurementMode.weight,
        quantity: 1000,
        unitPriceCents: 5000,
      );
      await repository.cancelTrip(canceled);

      final history = await repository.getProductPurchaseHistory(
        productId: productId,
        asOf: DateTime(2026, 2, 10),
      );
      expect(history.events, hasLength(3));
      expect(history.observedMonths, ['2026-01']);
      expect(history.daysSinceLastPurchase, 10);
      expect(history.medianIntervalDays, 15);
      final shortHistory = await repository.getProductPurchaseHistory(
        productId: productId,
        asOf: DateTime(2026, 1, 15),
      );
      expect(shortHistory.events, hasLength(2));
      expect(shortHistory.medianIntervalDays, isNull);

      final backup = await BackupService(database).createBackup();
      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).restoreBackup(backup);
      final restoredItem = await (restored.select(
        restored.plannedItems,
      )..where((row) => row.id.equals(plannedItemId))).getSingle();
      expect(restoredItem.estimateSource, 'manual');
      expect(restoredItem.estimatePriceNumeratorCents, 3990);
      expect(restoredItem.estimateQuantityDenominator, 1000);
    },
  );

  test('restauração aceita backup v2 sem estimativas fotografadas', () async {
    final productId = await _createProduct(
      database,
      name: 'Produto legado v2',
      mode: MeasurementMode.unit,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Plano do backup v2',
    );
    final itemId = await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 3,
    );
    await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );
    final payload = jsonDecode(
      await BackupService(database).createBackup(),
    ) as Map<String, dynamic>;
    payload['formatVersion'] = 2;
    payload['schemaVersion'] = 2;
    final trip =
        (payload['shoppingTrips'] as List<dynamic>).single
            as Map<String, dynamic>;
    trip.remove('originPlanNameSnapshot');
    final plannedItem =
        (payload['plannedItems'] as List<dynamic>).single
            as Map<String, dynamic>;
    plannedItem.remove('estimatePriceNumeratorCents');
    plannedItem.remove('estimateQuantityDenominator');
    plannedItem.remove('estimateSource');
    plannedItem.remove('estimateReferenceDate');
    plannedItem.remove('estimateReferenceTripId');

    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).restoreBackup(jsonEncode(payload));
    final restoredItem = await (restored.select(
      restored.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingle();
    expect(restoredItem.estimateSource, isNull);
    expect(restoredItem.estimatePriceNumeratorCents, isNull);
    final restoredTrip =
        (await restored.select(restored.shoppingTrips).get()).single;
    expect(restoredTrip.originPlanNameSnapshot, 'Plano do backup v2');
  });

  test(
    'restauração aceita backup v3 sem fotografia do nome da lista',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Produto legado v3',
        mode: MeasurementMode.unit,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista antiga',
      );
      final plannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 500,
      );
      await repository.completeTrip(tripId);
      final payload = jsonDecode(
        await BackupService(database).createBackup(),
      ) as Map<String, dynamic>;
      payload['formatVersion'] = 3;
      payload['schemaVersion'] = 3;
      final trip =
          (payload['shoppingTrips'] as List<dynamic>).single
              as Map<String, dynamic>;
      trip.remove('originPlanNameSnapshot');

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).restoreBackup(jsonEncode(payload));

      final restoredTrip =
          (await restored.select(restored.shoppingTrips).get()).single;
      expect(restoredTrip.originPlanNameSnapshot, 'Lista antiga');
    },
  );

  test('cancelar lista preserva itens e impede novas alterações', () async {
    final productId = await _createProduct(
      database,
      name: 'Feijão',
      mode: MeasurementMode.unit,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista preservada',
    );
    await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 2,
    );

    await repository.cancelPlan(planId);

    expect((await repository.watchPlan(planId).first)?.status, 'canceled');
    expect(await repository.getPlannedItems(planId), hasLength(1));
    await expectLater(
      repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
      ),
      throwsFormatException,
    );
    await expectLater(repository.cancelPlan(planId), throwsFormatException);
  });

  test('unidades permitem várias linhas e conclusão é idempotente', () async {
    final productId = await _createProduct(
      database,
      name: 'Arroz',
      mode: MeasurementMode.unit,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Compra novembro',
    );
    final itemId = await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 5,
    );
    final tripId = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
      marketName: 'Mercado fictício',
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 2,
      unitPriceCents: 800,
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 3,
      unitPriceCents: 750,
    );

    expect(await repository.totalForTrip(tripId), 3850);
    final removedLineId = await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 100,
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: itemId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 200,
    );
    expect(await database.select(database.purchaseLines).get(), hasLength(4));
    expect(await repository.totalForTrip(tripId), 4150);
    await repository.removePurchaseLine(removedLineId);
    expect(await repository.totalForTrip(tripId), 4050);
    expect(await repository.completeTrip(tripId), isTrue);
    expect(await repository.completeTrip(tripId), isFalse);
    expect((await repository.getPlanItemProgress(itemId)).purchasedQuantity, 6);
    expect(
      (await database.select(database.shoppingTrips).get()).single.status,
      'completed',
    );
    final plan = (await repository.watchPlan(planId).first)!;
    expect(plan.status, 'completed');
    expect(
      shoppingPlanListStatus(plan, await repository.watchTrips().first),
      ShoppingPlanListStatus.completed,
    );
    await expectLater(
      repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 2),
      ),
      throwsFormatException,
    );
    await expectLater(
      repository.updatePlannedQuantity(itemId, 10),
      throwsFormatException,
    );

    final product = await (database.select(
      database.products,
    )..where((row) => row.id.equals(productId))).getSingle();
    await CatalogRepository(database).saveProduct(
      id: productId,
      name: 'Arroz renomeado',
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: product.needsCategoryReview,
      description: product.description,
    );
    await CatalogRepository(database).saveProduct(
      id: productId,
      name: 'Arroz renomeado',
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      measurementMode: MeasurementMode.weight,
      needsCategoryReview: product.needsCategoryReview,
      description: product.description,
    );
    expect(
      (await database.select(database.plannedItems).get())
          .single
          .measurementMode,
      MeasurementMode.unit.name,
    );
    final lines = await database.select(database.purchaseLines).get();
    expect(lines.every((line) => line.measurementMode == 'unit'), isTrue);
    expect(lines.map((line) => line.productNameSnapshot), [
      'Arroz',
      'Arroz',
      'Arroz',
    ]);

    final backup = await BackupService(database).createBackup();
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).restoreBackup(backup);
    expect(await ShoppingRepository(restored).totalForTrip(tripId), 4050);
    expect(
      (await restored.select(restored.purchaseLines).get()).map(
        (line) => line.productNameSnapshot,
      ),
      ['Arroz', 'Arroz', 'Arroz'],
    );
    expect((jsonDecode(backup) as Map<String, dynamic>)['formatVersion'], 7);
  });

  test(
    'pacotes preservam preço por pacote no plano, histórico e backup',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Guardanapos',
        mode: MeasurementMode.package,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Pacotes planejados',
      );
      final plannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.package,
        quantity: 3,
      );
      await repository.setManualEstimate(
        itemId: plannedItemId,
        unitPriceCents: 725,
        estimatedAt: DateTime(2026, 10, 1),
      );
      final plannedItem = await (database.select(
        database.plannedItems,
      )..where((item) => item.id.equals(plannedItemId))).getSingle();
      expect(plannedItem.estimateQuantityDenominator, 1);

      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 2),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.package,
        quantity: 2,
        unitPriceCents: 1250,
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.package,
        quantity: 1,
        unitPriceCents: 1100,
      );
      await repository.completeTrip(tripId);

      expect(await repository.totalForTrip(tripId), 3600);
      final history = await repository.getProductPurchaseHistory(
        productId: productId,
        asOf: DateTime(2026, 11, 30),
      );
      expect(history.mode, MeasurementMode.package);
      expect(history.events.single.quantity, 3);
      expect(history.events.single.unitPriceCents, 1200);

      final backup = await BackupService(database).createBackup();
      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).restoreBackup(backup);
      expect(
        (await restored.select(restored.products).get()).single.measurementMode,
        MeasurementMode.package.name,
      );
      expect(await ShoppingRepository(restored).totalForTrip(tripId), 3600);
    },
  );

  test('peso é arredondado half-up por linha', () async {
    final productId = await _createProduct(
      database,
      name: 'Carne',
      mode: MeasurementMode.weight,
    );
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 11, 1),
    );
    for (final (quantity, price) in [(750, 3990), (1200, 4290)]) {
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        mode: MeasurementMode.weight,
        quantity: quantity,
        unitPriceCents: price,
      );
    }

    final lines = await database.select(database.purchaseLines).get();
    expect(lines.map((line) => line.totalCents), [2993, 5148]);
    expect(await repository.totalForTrip(tripId), 8141);
  });

  test(
    'lista fecha após compra parcial e carrinho avulso mantém pendência',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Leite',
        mode: MeasurementMode.unit,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista parcial',
      );
      final itemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 5,
      );
      final firstTrip = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await expectLater(
        repository.createTrip(
          planId: planId,
          purchaseDate: DateTime(2026, 11, 2),
        ),
        throwsA(isA<FormatException>()),
      );
      await repository.addPurchaseLine(
        tripId: firstTrip,
        productId: productId,
        plannedItemId: itemId,
        mode: MeasurementMode.unit,
        quantity: 2,
        unitPriceCents: 800,
      );
      await repository.completeTrip(firstTrip);

      final secondTrip = await repository.createTrip(
        purchaseDate: DateTime(2026, 11, 3),
      );
      final pendingLine = await repository.addPurchaseLine(
        tripId: secondTrip,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );
      final progress = await repository.getPlanItemProgress(itemId);
      expect(progress.purchasedQuantity, 2);
      expect(progress.inCartQuantity, 0);
      expect(progress.remainingFor(5), 3);
      expect(await repository.totalForTrip(secondTrip), isNull);
      await expectLater(
        repository.completeTrip(secondTrip),
        throwsA(isA<FormatException>()),
      );

      await repository.updatePurchaseLine(
        lineId: pendingLine,
        quantity: 1,
        unitPriceCents: 850,
      );
      expect(await repository.completeTrip(secondTrip), isTrue);
      final after = await repository.getPlanItemProgress(itemId);
      expect(after.purchasedQuantity, 2);
      expect(after.inCartQuantity, 0);
      expect(after.remainingFor(5), 3);
    },
  );

  test('restauração aceita backup de catálogo anterior à Etapa 2', () async {
    final service = BackupService(database);
    final current =
        jsonDecode(await service.createBackup()) as Map<String, dynamic>;
    current['formatVersion'] = 1;
    current['schemaVersion'] = 1;
    current.remove('shoppingPlans');
    current.remove('plannedItems');
    current.remove('shoppingTrips');
    current.remove('purchaseLines');

    await service.restoreBackup(jsonEncode(current));

    expect(await database.select(database.shoppingPlans).get(), isEmpty);
    expect(await database.select(database.purchaseLines).get(), isEmpty);
  });

  test('migra banco schema 1 sem perder catálogo', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mercado-migration-test-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}schema-v1.sqlite',
    );
    AppDatabase? versionOne;
    AppDatabase? versionTwo;
    try {
      versionOne = _VersionOneDatabase(NativeDatabase(file));
      final categoryId = await CatalogRepository(versionOne)
          .saveCategory(name: 'Fictícia');
      final productId = await CatalogRepository(versionOne).saveProduct(
        name: 'Produto de teste',
        categoryId: categoryId,
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );
      await versionOne.close();
      versionOne = null;

      versionTwo = AppDatabase(NativeDatabase(file));
      final product = await (versionTwo.select(
        versionTwo.products,
      )..where((row) => row.id.equals(productId))).getSingle();
      expect(product.name, 'Produto de teste');
      expect(await versionTwo.select(versionTwo.shoppingPlans).get(), isEmpty);
      final planId = await ShoppingRepository(versionTwo)
          .createPlan(monthKey: '2026-11', name: 'Lista após migração');
      expect(
        (await versionTwo.select(versionTwo.shoppingPlans).get()).single.id,
        planId,
      );
    } finally {
      await versionOne?.close();
      await versionTwo?.close();
      await directory.delete(recursive: true);
    }
  });

  test('migra banco schema 2 sem perder itens planejados', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mercado-migration-test-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}schema-v2.sqlite',
    );
    AppDatabase? versionThree;
    AppDatabase? migrated;
    try {
      versionThree = AppDatabase(NativeDatabase(file));
      final productId = await _createProduct(
        versionThree,
        name: 'Produto fictício',
        mode: MeasurementMode.unit,
      );
      final shopping = ShoppingRepository(versionThree);
      final planId = await shopping.createPlan(
        monthKey: '2026-11',
        name: 'Lista preservada',
      );
      await shopping.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 4,
      );
      await versionThree.close();
      versionThree = null;

      migrated = AppDatabase(
        NativeDatabase(
          file,
          setup: (db) {
            db.execute('PRAGMA foreign_keys = OFF');
            for (final column in [
              'estimate_reference_trip_id',
              'estimate_reference_date',
              'estimate_source',
              'estimate_quantity_denominator',
              'estimate_price_numerator_cents',
            ]) {
              db.execute('ALTER TABLE planned_items DROP COLUMN $column');
            }
            db.execute(
              'ALTER TABLE shopping_trips DROP COLUMN origin_plan_name_snapshot',
            );
            db.execute('DROP TABLE app_preferences');
            db.execute('ALTER TABLE purchase_lines DROP COLUMN is_label_total');
            db.execute('PRAGMA user_version = 2');
          },
        ),
      );

      final items = await migrated.select(migrated.plannedItems).get();
      expect(items, hasLength(1));
      expect(items.single.quantity, 4);
      expect(items.single.estimatePriceNumeratorCents, isNull);
      expect(
        (await migrated.select(migrated.shoppingPlans).get()).single.name,
        'Lista preservada',
      );
    } finally {
      await versionThree?.close();
      await migrated?.close();
      await directory.delete(recursive: true);
    }
  });

  test('total de etiqueta preserva valor pago e backup schema 6', () async {
    final productId = await _createProduct(
      database,
      name: 'Carne por peso',
      mode: MeasurementMode.weight,
    );
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 11, 8),
    );
    final lineId = await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.weight,
      quantity: 750,
      unitPriceCents: 1333,
      labelTotalCents: 1000,
    );

    final line = await (database.select(
      database.purchaseLines,
    )..where((row) => row.id.equals(lineId))).getSingle();
    expect(line.totalCents, 1000);
    expect(line.unitPriceCents, 1333);
    expect(line.isLabelTotal, isTrue);
    expect(await repository.totalForTrip(tripId), 1000);

    final backup = await BackupService(database).createBackup();
    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).restoreBackup(backup);
    final restoredLine = await (restored.select(
      restored.purchaseLines,
    )..where((row) => row.id.equals(lineId))).getSingle();
    expect(restoredLine.totalCents, 1000);
    expect(restoredLine.isLabelTotal, isTrue);
  });

  test('último pago usa total e quantidade da linha mais recente', () async {
    final productId = await _createProduct(
      database,
      name: 'Carne com duas linhas',
      mode: MeasurementMode.weight,
    );
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 11, 8),
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.weight,
      quantity: 500,
      unitPriceCents: 1000,
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.weight,
      quantity: 750,
      unitPriceCents: 1333,
      labelTotalCents: 1000,
    );
    await repository.completeTrip(tripId);

    expect(
      await repository.getLatestPaidUnitPriceCents(
        productId: productId,
        mode: MeasurementMode.weight,
      ),
      1333,
    );
  });

  test(
    'lista concluída pode permanecer aberta e iniciar nova compra',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Leite',
        mode: MeasurementMode.unit,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Compras da semana',
      );
      final itemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 6,
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 8),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: itemId,
        mode: MeasurementMode.unit,
        quantity: 2,
        unitPriceCents: 500,
      );
      await repository.completeTrip(tripId, closePlan: false);
      await repository.finalizePlanAfterPurchase(
        planId: planId,
        keepOpen: true,
      );

      final plan = (await repository.watchPlan(planId).first)!;
      expect(plan.status, 'open');
      final backup = await BackupService(database).createBackup();
      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).restoreBackup(backup);
      final restoredPlan = await (restored.select(
        restored.shoppingPlans,
      )..where((row) => row.id.equals(planId))).getSingle();
      expect(restoredPlan.status, 'open');
      expect(
        shoppingPlanListStatus(plan, await repository.watchTrips().first),
        ShoppingPlanListStatus.openList,
      );
      expect(
        (await repository.getPlanItemProgress(itemId)).purchasedQuantity,
        2,
      );

      final nextTripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 9),
      );
      await repository.addPurchaseLine(
        tripId: nextTripId,
        productId: productId,
        plannedItemId: itemId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 500,
      );
      await repository.completeTrip(nextTripId);
      expect(
        (await repository.getPlanItemProgress(itemId)).purchasedQuantity,
        3,
      );
    },
  );

  test(
    'lista restante usa compras concluídas e preserva forma original',
    () async {
      final productId = await _createProduct(
        database,
        name: 'Café',
        mode: MeasurementMode.weight,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista original',
      );
      final itemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.weight,
        quantity: 1000,
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 8),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        plannedItemId: itemId,
        mode: MeasurementMode.weight,
        quantity: 250,
        unitPriceCents: 4000,
      );
      await repository.completeTrip(tripId, closePlan: false);
      await repository.finalizePlanAfterPurchase(
        planId: planId,
        keepOpen: true,
      );
      expect((await repository.watchPlan(planId).first)!.status, 'open');

      final newPlanId = await repository.createPlanFromRemainingItems(
        sourcePlanId: planId,
        newPlanName: 'Lista original (Restante)',
      );
      final remaining = (await repository.getPlannedItems(newPlanId)).single;
      expect(remaining.quantity, 750);
      expect(remaining.measurementMode, MeasurementMode.weight.name);
    },
  );

  test(
    'forma de compra em lote afeta somente pendentes da categoria',
    () async {
      final catalog = CatalogRepository(database);
      final categoryId = await catalog.saveCategory(name: 'Mercearia');
      final pendingId = await catalog.saveProduct(
        name: 'Produto pendente',
        categoryId: categoryId,
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );
      final definedId = await catalog.saveProduct(
        name: 'Produto definido',
        categoryId: categoryId,
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final otherCategoryId = await catalog.saveCategory(name: ' outro setor');
      final otherPendingId = await catalog.saveProduct(
        name: 'Outro pendente',
        categoryId: otherCategoryId,
        measurementMode: MeasurementMode.pending,
        needsCategoryReview: false,
      );

      final changed = await repository
          .updatePendingProductsMeasurementModeByCategory(
            categoryId: categoryId,
            mode: MeasurementMode.package,
          );
      expect(changed, 1);
      final modes = {
        for (final row in await database.select(database.products).get())
          row.id: row.measurementMode,
      };
      expect(modes[pendingId], MeasurementMode.package.name);
      expect(modes[definedId], MeasurementMode.unit.name);
      expect(modes[otherPendingId], MeasurementMode.pending.name);
    },
  );

  test('migra banco schema 3 e fotografa a origem da compra', () async {
    final directory = await Directory.systemTemp.createTemp(
      'mercado-migration-test-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}schema-v3.sqlite',
    );
    AppDatabase? versionFour;
    AppDatabase? migrated;
    try {
      versionFour = AppDatabase(NativeDatabase(file));
      final productId = await _createProduct(
        versionFour,
        name: 'Produto schema 3',
        mode: MeasurementMode.unit,
      );
      final repository = ShoppingRepository(versionFour);
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista de origem',
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 500,
      );
      await repository.completeTrip(tripId);
      await versionFour.close();
      versionFour = null;

      migrated = AppDatabase(
        NativeDatabase(
          file,
          setup: (db) {
            db.execute('PRAGMA foreign_keys = OFF');
            db.execute(
              'ALTER TABLE shopping_trips DROP COLUMN origin_plan_name_snapshot',
            );
            db.execute('DROP TABLE app_preferences');
            db.execute('ALTER TABLE purchase_lines DROP COLUMN is_label_total');
            db.execute('PRAGMA user_version = 3');
          },
        ),
      );

      final trip = (await migrated.select(migrated.shoppingTrips).get()).single;
      expect(trip.planId, planId);
      expect(trip.originPlanNameSnapshot, 'Lista de origem');
      expect(trip.status, 'completed');
    } finally {
      await versionFour?.close();
      await migrated?.close();
      await directory.delete(recursive: true);
    }
  });
}

Future<int> _completeTripWithLines({
  required ShoppingRepository repository,
  required int productId,
  required DateTime date,
  required List<(int, int)> lines,
  MeasurementMode mode = MeasurementMode.unit,
  String? market,
}) async {
  final tripId = await repository.createTrip(
    purchaseDate: date,
    marketName: market,
  );
  for (final (quantity, priceCents) in lines) {
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: mode,
      quantity: quantity,
      unitPriceCents: priceCents,
    );
  }
  await repository.completeTrip(tripId);
  return tripId;
}

Future<int> _createProduct(
  AppDatabase database, {
  required String name,
  required MeasurementMode mode,
}) {
  return CatalogRepository(
    database,
  ).saveProduct(name: name, measurementMode: mode, needsCategoryReview: false);
}

class _VersionOneDatabase extends AppDatabase {
  _VersionOneDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createTable(categories);
      await migrator.createTable(subcategories);
      await migrator.createTable(products);
      await migrator.createTable(importBatches);
      await migrator.createTable(importEntries);
    },
  );
}
