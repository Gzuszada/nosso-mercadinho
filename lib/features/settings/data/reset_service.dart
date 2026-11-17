import 'package:drift/drift.dart';

import '../../../data/app_database.dart';

class ResetSelection {
  const ResetSelection({
    this.lists = false,
    this.unfinishedPurchases = false,
    this.history = false,
    this.products = false,
    this.categories = false,
    this.all = false,
  });

  final bool lists;
  final bool unfinishedPurchases;
  final bool history;
  final bool products;
  final bool categories;
  final bool all;

  bool get isEmpty =>
      !lists &&
      !unfinishedPurchases &&
      !history &&
      !products &&
      !categories &&
      !all;

  List<String> get labels {
    if (all) {
      return ['Todos os dados'];
    }
    return [
      if (lists) 'Listas',
      if (unfinishedPurchases) 'Carrinhos',
      if (history) 'Histórico',
      if (products) 'Produtos',
      if (categories) 'Categorias',
    ];
  }

  String get confirmationPhrase {
    if (all) {
      return 'LIMPAR TUDO';
    }
    return labels.length == 1
        ? 'LIMPAR ${labels.single.toUpperCase()}'
        : 'LIMPAR SELEÇÃO';
  }
}

class ResetPreview {
  const ResetPreview({
    required this.lists,
    required this.plannedItems,
    required this.inProgressPurchases,
    required this.canceledPurchases,
    required this.completedPurchases,
    required this.products,
    required this.referencedProducts,
    required this.categories,
    required this.subcategories,
    required this.importBatches,
    required this.importEntries,
  });

  final int lists;
  final int plannedItems;
  final int inProgressPurchases;
  final int canceledPurchases;
  final int completedPurchases;
  final int products;
  final int referencedProducts;
  final int categories;
  final int subcategories;
  final int importBatches;
  final int importEntries;

  int get totalPurchases =>
      inProgressPurchases + canceledPurchases + completedPurchases;
}

class ResetService {
  const ResetService(this._database);

  final AppDatabase _database;

  Future<ResetPreview> getPreview() async {
    final products = await _database.select(_database.products).get();
    final plannedItems = await _database.select(_database.plannedItems).get();
    final purchaseLines = await _database.select(_database.purchaseLines).get();
    final referencedProductIds = <int>{
      ...plannedItems.map((item) => item.productId),
      ...purchaseLines.map((line) => line.productId),
    };
    final trips = await _database.select(_database.shoppingTrips).get();

    return ResetPreview(
      lists: (await _database.select(_database.shoppingPlans).get()).length,
      plannedItems: plannedItems.length,
      inProgressPurchases: trips
          .where((trip) => trip.status == 'in_progress')
          .length,
      canceledPurchases: trips
          .where((trip) => trip.status == 'canceled')
          .length,
      completedPurchases: trips
          .where((trip) => trip.status == 'completed')
          .length,
      products: products.length,
      referencedProducts: products
          .where((product) => referencedProductIds.contains(product.id))
          .length,
      categories: (await _database.select(_database.categories).get()).length,
      subcategories:
          (await _database.select(_database.subcategories).get()).length,
      importBatches:
          (await _database.select(_database.importBatches).get()).length,
      importEntries:
          (await _database.select(_database.importEntries).get()).length,
    );
  }

  Future<void> clear(ResetSelection selection) async {
    if (selection.isEmpty) {
      throw const FormatException('Selecione pelo menos uma área para limpar.');
    }

    await _database.transaction(() async {
      if (selection.all) {
        await _clearAllData();
        return;
      }

      if (selection.lists) {
        final now = DateTime.now();
        await (_database.update(
          _database.shoppingTrips,
        )..where((row) => row.planId.isNotNull())).write(
          ShoppingTripsCompanion(
            planId: const Value(null),
            updatedAt: Value(now),
          ),
        );
        await (_database.update(
          _database.purchaseLines,
        )..where((row) => row.plannedItemId.isNotNull())).write(
          PurchaseLinesCompanion(
            plannedItemId: const Value(null),
            updatedAt: Value(now),
          ),
        );
        await _database.delete(_database.plannedItems).go();
        await _database.delete(_database.shoppingPlans).go();
      }

      final statusesToRemove = <String>[
        if (selection.unfinishedPurchases) 'in_progress',
        if (selection.unfinishedPurchases) 'canceled',
        if (selection.history) 'completed',
      ];
      if (statusesToRemove.isNotEmpty) {
        final trips = await (_database.select(
          _database.shoppingTrips,
        )..where((row) => row.status.isIn(statusesToRemove))).get();
        final tripIds = trips.map((trip) => trip.id).toList();
        if (tripIds.isNotEmpty) {
          await (_database.update(
            _database.plannedItems,
          )..where((row) => row.estimateReferenceTripId.isIn(tripIds))).write(
            const PlannedItemsCompanion(
              estimatePriceNumeratorCents: Value(null),
              estimateQuantityDenominator: Value(null),
              estimateSource: Value(null),
              estimateReferenceDate: Value(null),
              estimateReferenceTripId: Value(null),
            ),
          );
          await (_database.delete(
            _database.purchaseLines,
          )..where((row) => row.tripId.isIn(tripIds))).go();
          await (_database.delete(
            _database.shoppingTrips,
          )..where((row) => row.id.isIn(tripIds))).go();
        }
      }

      if (selection.products) {
        await _clearProducts();
      }

      if (selection.categories) {
        final now = DateTime.now();
        await (_database.update(_database.products)..where(
              (row) =>
                  row.categoryId.isNotNull() | row.subcategoryId.isNotNull(),
            ))
            .write(
              ProductsCompanion(
                categoryId: const Value(null),
                subcategoryId: const Value(null),
                needsCategoryReview: const Value(true),
                updatedAt: Value(now),
              ),
            );
        await _database.delete(_database.subcategories).go();
        await _database.delete(_database.categories).go();
      }
    });
  }

  Future<void> _clearProducts() async {
    final plannedItems = await _database.select(_database.plannedItems).get();
    final purchaseLines = await _database.select(_database.purchaseLines).get();
    final referencedProductIds = <int>{
      ...plannedItems.map((item) => item.productId),
      ...purchaseLines.map((line) => line.productId),
    };
    final now = DateTime.now();
    if (referencedProductIds.isNotEmpty) {
      await (_database.update(
        _database.products,
      )..where((row) => row.id.isIn(referencedProductIds))).write(
        ProductsCompanion(isArchived: const Value(true), updatedAt: Value(now)),
      );
    }
    if (referencedProductIds.length <
        (await _database.select(_database.products).get()).length) {
      await (_database.delete(
        _database.products,
      )..where((row) => row.id.isNotIn(referencedProductIds))).go();
    }
  }

  Future<void> _clearAllData() async {
    await _database.delete(_database.purchaseLines).go();
    await _database.delete(_database.plannedItems).go();
    await _database.delete(_database.shoppingTrips).go();
    await _database.delete(_database.shoppingPlans).go();
    await _database.delete(_database.importEntries).go();
    await _database.delete(_database.importBatches).go();
    await _database.delete(_database.products).go();
    await _database.delete(_database.subcategories).go();
    await _database.delete(_database.categories).go();
  }
}
