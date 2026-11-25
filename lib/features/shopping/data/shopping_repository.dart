import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../../cloud/domain/collaboration.dart';
import '../domain/shopping_calculations.dart';
import '../domain/shopping_history.dart';

class PlanItemProgress {
  const PlanItemProgress({
    required this.purchasedQuantity,
    required this.inCartQuantity,
  });

  final int purchasedQuantity;
  final int inCartQuantity;

  int remainingFor(int plannedQuantity) {
    final remaining = plannedQuantity - purchasedQuantity - inCartQuantity;
    return remaining > 0 ? remaining : 0;
  }
}

enum ShoppingPlanListStatus {
  newList,
  inProgress,
  openList,
  completed,
  canceled,
}

ShoppingPlanListStatus shoppingPlanListStatus(
  ShoppingPlan plan,
  Iterable<ShoppingTrip> trips,
) {
  if (plan.status == 'canceled') {
    return ShoppingPlanListStatus.canceled;
  }
  if (plan.status == 'completed') {
    return ShoppingPlanListStatus.completed;
  }
  if (plan.status == 'open') {
    return ShoppingPlanListStatus.openList;
  }
  final planTrips = trips.where((trip) => trip.planId == plan.id);
  if (planTrips.any((trip) => trip.status == 'in_progress')) {
    return ShoppingPlanListStatus.inProgress;
  }
  if (plan.status == 'completed' ||
      planTrips.any((trip) => trip.status == 'completed')) {
    return ShoppingPlanListStatus.completed;
  }
  return ShoppingPlanListStatus.newList;
}

class PurchaseHistoryEvent {
  const PurchaseHistoryEvent({
    required this.trip,
    required this.lines,
    required this.quantity,
    required this.totalCents,
    required this.unitPriceCents,
  });

  final ShoppingTrip trip;
  final List<PurchaseLine> lines;
  final int quantity;
  final int totalCents;
  final int unitPriceCents;
}

class MonthlyProductHistory {
  const MonthlyProductHistory({
    required this.productId,
    required this.productName,
    required this.mode,
    required this.quantity,
    required this.totalCents,
    required this.previousMonthQuantity,
    required this.previousMonthTotalCents,
    required this.latestPurchase,
  });

  final int productId;
  final String productName;
  final MeasurementMode mode;
  final int quantity;
  final int totalCents;
  final int previousMonthQuantity;
  final int previousMonthTotalCents;
  final PurchaseHistoryEvent? latestPurchase;
}

class MonthlyHistoryReport {
  const MonthlyHistoryReport({
    required this.monthKey,
    required this.trips,
    required this.products,
    required this.totalCents,
  });

  final String monthKey;
  final List<PurchaseHistoryEvent> trips;
  final List<MonthlyProductHistory> products;
  final int totalCents;
}

class ProductPurchaseHistory {
  const ProductPurchaseHistory({
    required this.productName,
    required this.mode,
    required this.events,
    required this.observedMonths,
    required this.daysSinceLastPurchase,
    required this.medianIntervalDays,
  });

  final String productName;
  final MeasurementMode mode;
  final List<PurchaseHistoryEvent> events;
  final List<String> observedMonths;
  final int? daysSinceLastPurchase;
  final int? medianIntervalDays;
}

class TripProjection {
  const TripProjection({
    required this.knownCartCents,
    required this.plannedCartCents,
    required this.outsidePlanCartCents,
    required this.knownCartLineCount,
    required this.pendingCartLineCount,
    required this.estimatedRemainingCents,
    required this.estimatedItemsCount,
    required this.itemsWithoutEstimate,
    required this.projectedCents,
  });

  final int knownCartCents;
  final int plannedCartCents;
  final int outsidePlanCartCents;
  final int knownCartLineCount;
  final int pendingCartLineCount;
  final int estimatedRemainingCents;
  final int estimatedItemsCount;
  final int itemsWithoutEstimate;
  final int projectedCents;

  int get plannedProjectionCents => ShoppingCalculations.sumCents([
    plannedCartCents,
    estimatedRemainingCents,
  ]);

  bool get isPartial => pendingCartLineCount > 0 || itemsWithoutEstimate > 0;
}

class _EstimateSnapshot {
  const _EstimateSnapshot({
    required this.priceNumeratorCents,
    required this.quantityDenominator,
    required this.source,
    required this.referenceDate,
    required this.referenceTripId,
  });

  final int priceNumeratorCents;
  final int quantityDenominator;
  final String source;
  final String referenceDate;
  final int? referenceTripId;
}

class _ProductLineAggregate {
  const _ProductLineAggregate({
    required this.productId,
    required this.mode,
    required this.lines,
    required this.quantity,
    required this.totalCents,
  });

  factory _ProductLineAggregate.fromLines(List<PurchaseLine> lines) {
    final mode = MeasurementMode.values.firstWhere(
      (value) => value.name == lines.first.measurementMode,
    );
    return _ProductLineAggregate(
      productId: lines.first.productId,
      mode: mode,
      lines: lines,
      quantity: ShoppingRepository._sumQuantitiesChecked(
        lines.map((line) => line.quantity),
      ),
      totalCents: ShoppingCalculations.sumCents(
        lines.map((line) => line.totalCents!),
      ),
    );
  }

  final int productId;
  final MeasurementMode mode;
  final List<PurchaseLine> lines;
  final int quantity;
  final int totalCents;
}

class ShoppingRepository {
  const ShoppingRepository(this._database, {this.actorResolver});

  final AppDatabase _database;
  final CollaborationActorResolver? actorResolver;

  Future<CollaborationActor> _actor() async =>
      await actorResolver?.call() ?? const CollaborationActor.local();

  Stream<List<ShoppingPlan>> watchPlans() {
    return (_database.select(_database.shoppingPlans)..orderBy([
          (plan) => OrderingTerm.desc(plan.monthKey),
          (plan) => OrderingTerm.desc(plan.updatedAt),
        ]))
        .watch();
  }

  Stream<ShoppingPlan?> watchPlan(int id) {
    return (_database.select(
      _database.shoppingPlans,
    )..where((plan) => plan.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<PlannedItem>> watchPlannedItems(int planId) {
    return (_database.select(_database.plannedItems)
          ..where(
            (item) => item.planId.equals(planId) & item.isRemoved.equals(false),
          )
          ..orderBy([(item) => OrderingTerm.asc(item.id)]))
        .watch();
  }

  Future<List<PlannedItem>> getPlannedItems(int planId) {
    return (_database.select(_database.plannedItems)
          ..where(
            (item) => item.planId.equals(planId) & item.isRemoved.equals(false),
          )
          ..orderBy([(item) => OrderingTerm.asc(item.id)]))
        .get();
  }

  Stream<List<ShoppingTrip>> watchTrips() {
    return (_database.select(_database.shoppingTrips)..orderBy([
          (trip) => OrderingTerm.desc(trip.purchaseDate),
          (trip) => OrderingTerm.desc(trip.id),
        ]))
        .watch();
  }

  Stream<ShoppingTrip?> watchTrip(int id) {
    return (_database.select(
      _database.shoppingTrips,
    )..where((trip) => trip.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<PurchaseLine>> watchPurchaseLines(int tripId) {
    return (_database.select(_database.purchaseLines)
          ..where((line) => line.tripId.equals(tripId))
          ..orderBy([(line) => OrderingTerm.asc(line.id)]))
        .watch();
  }

  Future<ShoppingTrip?> getActiveTripForPlan(int? planId) async {
    final query = _database.select(_database.shoppingTrips)
      ..where(
        (trip) =>
            trip.status.equals('in_progress') &
            (planId == null
                ? trip.planId.isNull()
                : trip.planId.equals(planId)),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> createPlan({
    required String monthKey,
    required String name,
  }) async {
    if (!_isValidMonthKey(monthKey)) {
      throw const FormatException('Escolha um mês e ano válidos.');
    }
    final normalizedName = _requiredText(name, 'Informe o nome da lista.');
    if (normalizedName.length > 120) {
      throw const FormatException(
        'O nome da lista pode ter até 120 caracteres.',
      );
    }
    final actor = await _actor();
    return _database
        .into(_database.shoppingPlans)
        .insert(
          ShoppingPlansCompanion.insert(
            monthKey: monthKey,
            name: normalizedName,
            syncId: Value(CollaborationMetadata.newSyncId('plan')),
            logicalKey: Value(
              CollaborationMetadata.planLogicalKey(
                monthKey: monthKey,
                name: normalizedName,
              ),
            ),
            authorUid: Value(actor.uid),
            authorName: Value(actor.displayName),
            reviewState: Value(
              actor.role == CollaborationRole.member
                  ? CollaborationMetadata.pendingReview
                  : CollaborationMetadata.approved,
            ),
          ),
        );
  }

  Future<void> cancelPlan(int planId) async {
    await _database.transaction(() async {
      final plan = await _requirePlan(planId);
      if (!_isEditablePlanStatus(plan.status)) {
        throw const FormatException(
          'Somente listas ativas podem ser canceladas.',
        );
      }
      await _ensurePlanNotCompleted(planId);
      await (_database.update(
        _database.shoppingPlans,
      )..where((row) => row.id.equals(planId))).write(
        ShoppingPlansCompanion(
          status: const Value('canceled'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<int> addPlannedItem({
    required int planId,
    required int productId,
    MeasurementMode? mode,
    required int quantity,
  }) async {
    _validateQuantity(quantity);

    return _database.transaction(() async {
      final plan = await _requirePlan(planId);
      if (!_isEditablePlanStatus(plan.status)) {
        throw const FormatException('Esta lista não está ativa.');
      }
      await _ensurePlanNotCompleted(planId);
      final product = await _requireProduct(productId);
      if (product.isArchived) {
        throw const FormatException(
          'Não é possível adicionar produto arquivado.',
        );
      }
      final currentMode = MeasurementMode.values.firstWhere(
        (value) => value.name == product.measurementMode,
        orElse: () => MeasurementMode.pending,
      );
      if (currentMode == MeasurementMode.pending) {
        throw const FormatException(
          'Defina unidade, pacote ou peso no cadastro do produto antes de adicioná-lo à lista.',
        );
      }
      if (mode != null && currentMode != mode) {
        throw const FormatException(
          'A forma de compra deve corresponder ao cadastro do produto.',
        );
      }
      final estimate = await _findLatestEstimate(
        productId: productId,
        mode: currentMode,
        beforeDate: ShoppingHistoryCalculations.firstDayOfMonth(plan.monthKey),
      );
      final actor = await _actor();
      final planSyncId = plan.syncId ?? 'legacy:plan:${plan.id}';
      final productSyncId = product.syncId ?? 'legacy:product:${product.id}';
      final logicalKey = CollaborationMetadata.plannedItemLogicalKey(
        planSyncId: planSyncId,
        productSyncId: productSyncId,
      );
      final reviewState = actor.role == CollaborationRole.member
          ? CollaborationMetadata.pendingReview
          : CollaborationMetadata.approved;

      final existing =
          await (_database.select(_database.plannedItems)..where(
                (item) =>
                    item.planId.equals(planId) &
                    item.productId.equals(productId),
              ))
              .get();
      if (existing.any((item) => !item.isRemoved)) {
        throw const FormatException(
          'Este produto já está na lista. Edite a quantidade existente.',
        );
      }
      if (existing.isNotEmpty) {
        final item = existing.last;
        await (_database.update(
          _database.plannedItems,
        )..where((row) => row.id.equals(item.id))).write(
          PlannedItemsCompanion(
            measurementMode: Value(currentMode.name),
            quantity: Value(quantity),
            isRemoved: const Value(false),
            deletedAt: const Value(null),
            authorUid: Value(actor.uid),
            authorName: Value(actor.displayName),
            reviewState: Value(reviewState),
            syncRevision: Value(item.syncRevision + 1),
            estimatePriceNumeratorCents: Value(estimate?.priceNumeratorCents),
            estimateQuantityDenominator: Value(estimate?.quantityDenominator),
            estimateSource: Value(estimate?.source),
            estimateReferenceDate: Value(estimate?.referenceDate),
            estimateReferenceTripId: Value(estimate?.referenceTripId),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return item.id;
      }

      return _database
          .into(_database.plannedItems)
          .insert(
            PlannedItemsCompanion.insert(
              planId: planId,
              productId: productId,
              measurementMode: currentMode.name,
              quantity: quantity,
              syncId: Value(CollaborationMetadata.newSyncId('planned-item')),
              logicalKey: Value(logicalKey),
              authorUid: Value(actor.uid),
              authorName: Value(actor.displayName),
              reviewState: Value(reviewState),
              estimatePriceNumeratorCents: Value(estimate?.priceNumeratorCents),
              estimateQuantityDenominator: Value(estimate?.quantityDenominator),
              estimateSource: Value(estimate?.source),
              estimateReferenceDate: Value(estimate?.referenceDate),
              estimateReferenceTripId: Value(estimate?.referenceTripId),
            ),
          );
    });
  }

  Future<bool> refreshPlannedItemEstimate(int itemId) async {
    return _database.transaction(() async {
      final item = await (_database.select(
        _database.plannedItems,
      )..where((row) => row.id.equals(itemId))).getSingleOrNull();
      if (item == null || item.isRemoved) {
        throw StateError('O item planejado não existe mais.');
      }
      final plan = await _requirePlan(item.planId);
      if (!_isEditablePlanStatus(plan.status)) {
        throw const FormatException(
          'Somente listas ativas podem atualizar estimativas.',
        );
      }
      await _ensurePlanNotCompleted(plan.id);
      final estimate = await _findLatestEstimate(
        productId: item.productId,
        mode: MeasurementMode.values.firstWhere(
          (mode) => mode.name == item.measurementMode,
        ),
        beforeDate: ShoppingHistoryCalculations.firstDayOfMonth(plan.monthKey),
      );
      await (_database.update(_database.plannedItems)
            ..where((row) => row.id.equals(itemId)))
          .write(_estimateCompanion(estimate));
      return estimate != null;
    });
  }

  Future<void> setManualEstimate({
    required int itemId,
    required int unitPriceCents,
    DateTime? estimatedAt,
  }) async {
    if (unitPriceCents < 0) {
      throw const FormatException('O preço estimado não pode ser negativo.');
    }
    await _database.transaction(() async {
      final item = await (_database.select(
        _database.plannedItems,
      )..where((row) => row.id.equals(itemId))).getSingleOrNull();
      if (item == null || item.isRemoved) {
        throw StateError('O item planejado não existe mais.');
      }
      final plan = await _requirePlan(item.planId);
      if (!_isEditablePlanStatus(plan.status)) {
        throw const FormatException(
          'Somente listas ativas podem alterar estimativas.',
        );
      }
      await _ensurePlanNotCompleted(plan.id);
      final mode = MeasurementMode.values.firstWhere(
        (value) => value.name == item.measurementMode,
      );
      final now = estimatedAt ?? DateTime.now();
      final date = ShoppingHistoryCalculations.civilDate(now);
      await (_database.update(
        _database.plannedItems,
      )..where((row) => row.id.equals(itemId))).write(
        PlannedItemsCompanion(
          estimatePriceNumeratorCents: Value(unitPriceCents),
          estimateQuantityDenominator: Value(
            mode == MeasurementMode.weight ? 1000 : 1,
          ),
          estimateSource: const Value('manual'),
          estimateReferenceDate: Value(date),
          estimateReferenceTripId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  static PlannedItemsCompanion _estimateCompanion(
    _EstimateSnapshot? estimate,
  ) => PlannedItemsCompanion(
    estimatePriceNumeratorCents: Value(estimate?.priceNumeratorCents),
    estimateQuantityDenominator: Value(estimate?.quantityDenominator),
    estimateSource: Value(estimate?.source),
    estimateReferenceDate: Value(estimate?.referenceDate),
    estimateReferenceTripId: Value(estimate?.referenceTripId),
    updatedAt: Value(DateTime.now()),
  );

  Future<void> updatePlannedQuantity(int itemId, int quantity) async {
    _validateQuantity(quantity);
    final item = await (_database.select(
      _database.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingleOrNull();
    if (item == null || item.isRemoved) {
      throw StateError('O item planejado não existe mais.');
    }
    final plan = await _requirePlan(item.planId);
    if (!_isEditablePlanStatus(plan.status)) {
      throw const FormatException('Esta lista não está ativa.');
    }
    await _ensurePlanNotCompleted(plan.id);
    await (_database.update(
      _database.plannedItems,
    )..where((row) => row.id.equals(itemId))).write(
      PlannedItemsCompanion(
        quantity: Value(quantity),
        syncRevision: Value(item.syncRevision + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removePlannedItem(int itemId) async {
    final item = await (_database.select(
      _database.plannedItems,
    )..where((row) => row.id.equals(itemId))).getSingleOrNull();
    if (item == null || item.isRemoved) {
      throw StateError('O item planejado não existe mais.');
    }
    final plan = await _requirePlan(item.planId);
    if (!_isEditablePlanStatus(plan.status)) {
      throw const FormatException('Esta lista não está ativa.');
    }
    await _ensurePlanNotCompleted(plan.id);
    final updated =
        await (_database.update(
          _database.plannedItems,
        )..where((row) => row.id.equals(itemId))).write(
          PlannedItemsCompanion(
            isRemoved: const Value(true),
            deletedAt: Value(DateTime.now()),
            syncRevision: Value(item.syncRevision + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) {
      throw StateError('O item planejado não existe mais.');
    }
  }

  Future<void> updateProductMeasurementMode({
    required int productId,
    required MeasurementMode mode,
  }) async {
    await (_database.update(
      _database.products,
    )..where((product) => product.id.equals(productId))).write(
      ProductsCompanion(
        measurementMode: Value(mode.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updatePendingProductsMeasurementModeByCategory({
    required int? categoryId,
    required MeasurementMode mode,
  }) async {
    if (mode == MeasurementMode.pending) {
      throw const FormatException('Escolha unidade, pacote ou peso.');
    }
    final query = _database.update(_database.products)
      ..where(
        (product) =>
            product.measurementMode.equals(MeasurementMode.pending.name) &
            (categoryId == null
                ? product.categoryId.isNull()
                : product.categoryId.equals(categoryId)),
      );
    return query.write(
      ProductsCompanion(
        measurementMode: Value(mode.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int?> getLatestPaidUnitPriceCents({
    required int productId,
    required MeasurementMode mode,
  }) async {
    final query =
        _database.select(_database.shoppingTrips).join([
          innerJoin(
            _database.purchaseLines,
            _database.purchaseLines.tripId.equalsExp(
              _database.shoppingTrips.id,
            ),
          ),
        ])..where(
          _database.shoppingTrips.status.equals('completed') &
              _database.purchaseLines.productId.equals(productId) &
              _database.purchaseLines.measurementMode.equals(mode.name) &
              _database.purchaseLines.status.equals('included') &
              _database.purchaseLines.totalCents.isNotNull(),
        );
    query.orderBy([
      OrderingTerm.desc(_database.shoppingTrips.purchaseDate),
      OrderingTerm.desc(_database.shoppingTrips.id),
      OrderingTerm.desc(_database.purchaseLines.id),
    ]);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    final referenceLine = rows.first.readTable(_database.purchaseLines);
    final quantity = referenceLine.quantity;
    if (quantity <= 0) return null;
    return ShoppingHistoryCalculations.displayUnitPriceCents(
      mode: mode,
      amountCents: referenceLine.totalCents!,
      quantityBasis: quantity,
    );
  }

  Future<int> copyPlannedItems({
    required int sourcePlanId,
    required int targetPlanId,
  }) async {
    return _database.transaction(() async {
      await _ensurePlanNotCompleted(targetPlanId);
      final sourceItems =
          await (_database.select(_database.plannedItems)..where(
                (item) =>
                    item.planId.equals(sourcePlanId) &
                    item.isRemoved.equals(false),
              ))
              .get();
      final existingTargetItems =
          await (_database.select(_database.plannedItems)..where(
                (item) =>
                    item.planId.equals(targetPlanId) &
                    item.isRemoved.equals(false),
              ))
              .get();
      final existingProductIds = existingTargetItems
          .map((item) => item.productId)
          .toSet();

      var copiedCount = 0;
      for (final item in sourceItems) {
        if (!existingProductIds.contains(item.productId)) {
          final mode = MeasurementMode.values.firstWhere(
            (m) => m.name == item.measurementMode,
            orElse: () => MeasurementMode.unit,
          );
          await addPlannedItem(
            planId: targetPlanId,
            productId: item.productId,
            mode: mode,
            quantity: item.quantity,
          );
          copiedCount++;
        }
      }
      return copiedCount;
    });
  }

  Future<Map<int, int>> getPlanItemPurchasedQuantities(int planId) async {
    final items = await getPlannedItems(planId);
    final result = <int, int>{};
    for (final item in items) {
      final progress = await getPlanItemProgress(item.id);
      result[item.id] = progress.purchasedQuantity;
    }
    return result;
  }

  Future<int> createPlanFromRemainingItems({
    required int sourcePlanId,
    required String newPlanName,
  }) async {
    return _database.transaction(() async {
      final sourcePlan = await _requirePlan(sourcePlanId);
      final newPlanId = await createPlan(
        monthKey: sourcePlan.monthKey,
        name: newPlanName,
      );
      final planned = await getPlannedItems(sourcePlanId);
      final purchasedMap = await getPlanItemPurchasedQuantities(sourcePlanId);
      for (final item in planned) {
        final purchased = purchasedMap[item.id] ?? 0;
        final remaining = item.quantity - purchased;
        if (remaining > 0) {
          await addPlannedItem(
            planId: newPlanId,
            productId: item.productId,
            mode: MeasurementMode.values.firstWhere(
              (mode) => mode.name == item.measurementMode,
              orElse: () => MeasurementMode.unit,
            ),
            quantity: remaining,
          );
        }
      }
      return newPlanId;
    });
  }

  Future<int> createTrip({
    int? planId,
    required DateTime purchaseDate,
    String? marketName,
  }) async {
    final dateOnly = _formatDate(purchaseDate);
    final normalizedMarket = _optionalText(marketName);

    return _database.transaction(() async {
      String? originPlanNameSnapshot;
      if (planId != null) {
        final plan = await _requirePlan(planId);
        if (!_isEditablePlanStatus(plan.status)) {
          throw const FormatException('Esta lista não está ativa.');
        }
        await _ensurePlanNotCompleted(planId);
        originPlanNameSnapshot = plan.name;
      }
      final activeTrips =
          await (_database.select(_database.shoppingTrips)..where(
                (trip) =>
                    trip.status.equals('in_progress') &
                    (planId == null
                        ? trip.planId.isNull()
                        : trip.planId.equals(planId)),
              ))
              .get();
      if (activeTrips.isNotEmpty) {
        throw const FormatException(
          'Já existe uma compra em andamento para esta lista. Abra-a para continuar.',
        );
      }

      return _database
          .into(_database.shoppingTrips)
          .insert(
            ShoppingTripsCompanion.insert(
              planId: Value(planId),
              originPlanNameSnapshot: Value(originPlanNameSnapshot),
              purchaseDate: dateOnly,
              marketName: Value(normalizedMarket),
            ),
          );
    });
  }

  Future<int> addPurchaseLine({
    required int tripId,
    required int productId,
    int? plannedItemId,
    required MeasurementMode mode,
    required int quantity,
    int? unitPriceCents,
    int? labelTotalCents,
  }) async {
    _validateQuantity(quantity);
    if (mode == MeasurementMode.pending) {
      throw const FormatException(
        'Defina unidade, pacote ou peso antes de adicionar ao carrinho.',
      );
    }
    if (unitPriceCents != null && unitPriceCents < 0) {
      throw const FormatException('O preço não pode ser negativo.');
    }
    if (labelTotalCents != null) {
      if (mode != MeasurementMode.weight) {
        throw const FormatException(
          'O total da etiqueta só pode ser usado para produtos por peso.',
        );
      }
      if (labelTotalCents < 0) {
        throw const FormatException('O total não pode ser negativo.');
      }
      if (unitPriceCents == null) {
        throw const FormatException(
          'Informe o preço derivado para usar o total da etiqueta.',
        );
      }
    }

    final total =
        labelTotalCents ??
        (unitPriceCents == null
            ? null
            : ShoppingCalculations.calculateLineTotalCents(
                mode: mode,
                quantity: quantity,
                unitPriceCents: unitPriceCents,
              ));
    return _database.transaction(() async {
      final trip = await _requireTrip(tripId);
      if (trip.status != 'in_progress') {
        throw const FormatException('Esta compra não está em andamento.');
      }
      final product = await _requireProduct(productId);
      final productMode = MeasurementMode.values.firstWhere(
        (value) => value.name == product.measurementMode,
        orElse: () => MeasurementMode.pending,
      );
      PlannedItem? plannedItem;
      if (plannedItemId != null) {
        plannedItem = await (_database.select(
          _database.plannedItems,
        )..where((item) => item.id.equals(plannedItemId))).getSingleOrNull();
        if (plannedItem == null ||
            plannedItem.productId != productId ||
            plannedItem.measurementMode != mode.name ||
            plannedItem.planId != trip.planId) {
          throw const FormatException(
            'O item planejado não pertence a esta compra ou não é compatível.',
          );
        }
      } else if (productMode == MeasurementMode.pending) {
        throw const FormatException(
          'Defina unidade, pacote ou peso no cadastro do produto antes de comprar.',
        );
      } else if (productMode != mode) {
        throw const FormatException(
          'A forma de compra deve corresponder ao cadastro do produto.',
        );
      }
      if (product.isArchived && plannedItemId == null) {
        throw const FormatException(
          'Para comprar um produto arquivado, vincule-o a um item já planejado.',
        );
      }

      return _database
          .into(_database.purchaseLines)
          .insert(
            PurchaseLinesCompanion.insert(
              tripId: tripId,
              productId: productId,
              plannedItemId: Value(plannedItemId),
              measurementMode: mode.name,
              quantity: quantity,
              unitPriceCents: Value(unitPriceCents),
              totalCents: Value(total),
              isLabelTotal: Value(labelTotalCents != null),
              status: Value(
                unitPriceCents == null ? 'pending_price' : 'included',
              ),
            ),
          );
    });
  }

  Future<void> updatePurchaseLine({
    required int lineId,
    required int quantity,
    required int? unitPriceCents,
    int? labelTotalCents,
  }) async {
    _validateQuantity(quantity);
    if (unitPriceCents != null && unitPriceCents < 0) {
      throw const FormatException('O preço não pode ser negativo.');
    }
    if (labelTotalCents != null) {
      if (unitPriceCents == null) {
        throw const FormatException(
          'Informe o preço derivado para usar o total da etiqueta.',
        );
      }
      if (labelTotalCents < 0) {
        throw const FormatException('O total não pode ser negativo.');
      }
    }
    await _database.transaction(() async {
      final line = await (_database.select(
        _database.purchaseLines,
      )..where((row) => row.id.equals(lineId))).getSingleOrNull();
      if (line == null) {
        throw StateError('A linha de compra não existe mais.');
      }
      final trip = await _requireTrip(line.tripId);
      if (trip.status != 'in_progress') {
        throw const FormatException(
          'Compras concluídas não podem ser editadas.',
        );
      }
      final mode = MeasurementMode.values.firstWhere(
        (value) => value.name == line.measurementMode,
        orElse: () => MeasurementMode.pending,
      );
      final total =
          labelTotalCents ??
          (unitPriceCents == null
              ? null
              : ShoppingCalculations.calculateLineTotalCents(
                  mode: mode,
                  quantity: quantity,
                  unitPriceCents: unitPriceCents,
                ));
      await (_database.update(
        _database.purchaseLines,
      )..where((row) => row.id.equals(lineId))).write(
        PurchaseLinesCompanion(
          quantity: Value(quantity),
          unitPriceCents: Value(unitPriceCents),
          totalCents: Value(total),
          isLabelTotal: Value(labelTotalCents != null),
          status: Value(unitPriceCents == null ? 'pending_price' : 'included'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> removePurchaseLine(int lineId) async {
    await _database.transaction(() async {
      final line = await (_database.select(
        _database.purchaseLines,
      )..where((row) => row.id.equals(lineId))).getSingleOrNull();
      if (line == null) {
        throw StateError('A linha de compra não existe mais.');
      }
      final trip = await _requireTrip(line.tripId);
      if (trip.status != 'in_progress') {
        throw const FormatException(
          'Linhas de compra concluídas são preservadas.',
        );
      }
      await (_database.delete(
        _database.purchaseLines,
      )..where((row) => row.id.equals(lineId))).go();
    });
  }

  Future<bool> completeTrip(int tripId, {bool closePlan = true}) {
    return _database.transaction(() async {
      final trip = await _requireTrip(tripId);
      if (trip.status == 'completed') {
        return false;
      }
      if (trip.status != 'in_progress') {
        throw const FormatException('Esta compra não pode ser concluída.');
      }
      final lines = await (_database.select(
        _database.purchaseLines,
      )..where((line) => line.tripId.equals(tripId))).get();
      if (lines.isEmpty) {
        throw const FormatException(
          'Adicione ao menos um item antes de concluir.',
        );
      }
      if (lines.any(
        (line) =>
            line.status != 'included' ||
            line.unitPriceCents == null ||
            line.totalCents == null,
      )) {
        throw const FormatException(
          'Informe o preço real de todas as linhas antes de concluir.',
        );
      }

      for (final line in lines) {
        final product = await _requireProduct(line.productId);
        final category = product.categoryId == null
            ? null
            : await (_database.select(_database.categories)
                    ..where((row) => row.id.equals(product.categoryId!)))
                  .getSingleOrNull();
        final subcategory = product.subcategoryId == null
            ? null
            : await (_database.select(_database.subcategories)
                    ..where((row) => row.id.equals(product.subcategoryId!)))
                  .getSingleOrNull();
        await (_database.update(
          _database.purchaseLines,
        )..where((row) => row.id.equals(line.id))).write(
          PurchaseLinesCompanion(
            productNameSnapshot: Value(product.name),
            categoryNameSnapshot: Value(category?.name),
            subcategoryNameSnapshot: Value(subcategory?.name),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await (_database.update(
        _database.shoppingTrips,
      )..where((row) => row.id.equals(tripId))).write(
        ShoppingTripsCompanion(
          status: const Value('completed'),
          completedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (closePlan && trip.planId != null) {
        final plan = await _requirePlan(trip.planId!);
        if (_isEditablePlanStatus(plan.status)) {
          await (_database.update(
            _database.shoppingPlans,
          )..where((row) => row.id.equals(plan.id))).write(
            ShoppingPlansCompanion(
              status: const Value('completed'),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      return true;
    });
  }

  Future<void> finalizePlanAfterPurchase({
    required int planId,
    required bool keepOpen,
  }) async {
    await _database.transaction(() async {
      final plan = await _requirePlan(planId);
      if (!_isEditablePlanStatus(plan.status)) {
        throw const FormatException('Esta lista não está ativa.');
      }
      await (_database.update(
        _database.shoppingPlans,
      )..where((row) => row.id.equals(planId))).write(
        ShoppingPlansCompanion(
          status: Value(keepOpen ? 'open' : 'completed'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> cancelTrip(int tripId) async {
    await _database.transaction(() async {
      final trip = await _requireTrip(tripId);
      if (trip.status != 'in_progress') {
        throw const FormatException(
          'Somente compras em andamento podem ser canceladas.',
        );
      }
      await (_database.update(
        _database.shoppingTrips,
      )..where((row) => row.id.equals(tripId))).write(
        ShoppingTripsCompanion(
          status: const Value('canceled'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<MonthlyHistoryReport> getMonthlyHistory(String monthKey) async {
    ShoppingHistoryCalculations.parseMonthKey(monthKey);
    final start = ShoppingHistoryCalculations.civilDate(
      ShoppingHistoryCalculations.firstDayOfMonth(monthKey),
    );
    final endExclusive = ShoppingHistoryCalculations.civilDate(
      ShoppingHistoryCalculations.firstDayOfNextMonth(monthKey),
    );
    final endInclusive = ShoppingHistoryCalculations.civilDate(
      ShoppingHistoryCalculations.firstDayOfNextMonth(monthKey)
          .subtract(const Duration(days: 1)),
    );
    final previousMonthKey = ShoppingHistoryCalculations.previousMonthKey(
      monthKey,
    );
    final previousStart = ShoppingHistoryCalculations.civilDate(
      ShoppingHistoryCalculations.firstDayOfMonth(previousMonthKey),
    );
    final currentTrips =
        await (_database.select(_database.shoppingTrips)
              ..where(
                (trip) =>
                    trip.status.equals('completed') &
                    trip.purchaseDate.isBiggerOrEqualValue(start) &
                    trip.purchaseDate.isSmallerThanValue(endExclusive),
              )
              ..orderBy([
                (trip) => OrderingTerm.desc(trip.purchaseDate),
                (trip) => OrderingTerm.desc(trip.id),
              ]))
            .get();
    final previousTrips =
        await (_database.select(_database.shoppingTrips)..where(
              (trip) =>
                  trip.status.equals('completed') &
                  trip.purchaseDate.isBiggerOrEqualValue(previousStart) &
                  trip.purchaseDate.isSmallerThanValue(start),
            ))
            .get();
    final currentLines = await _includedLinesForTrips(currentTrips);
    final previousLines = await _includedLinesForTrips(previousTrips);
    final productRows = await _database.select(_database.products).get();
    final productNames = {
      for (final product in productRows) product.id: product.name,
    };
    final currentEvents = _eventsForTrips(currentTrips, currentLines);
    final previousByProduct = _aggregateProductLines(previousLines);
    final currentByProduct = _aggregateProductLines(currentLines);

    final products = <MonthlyProductHistory>[];
    for (final entry in currentByProduct.entries) {
      final productId = entry.value.productId;
      final previous = previousByProduct[entry.key];
      final latest = await _latestProductPurchase(
        productId: productId,
        onOrBefore: endInclusive,
      );
      products.add(
        MonthlyProductHistory(
          productId: productId,
          productName:
              entry.value.lines.first.productNameSnapshot ??
              productNames[productId] ??
              'Produto',
          mode: entry.value.mode,
          quantity: entry.value.quantity,
          totalCents: entry.value.totalCents,
          previousMonthQuantity: previous?.quantity ?? 0,
          previousMonthTotalCents: previous?.totalCents ?? 0,
          latestPurchase: latest,
        ),
      );
    }
    products.sort(
      (first, second) =>
          compareNormalized(first.productName, second.productName),
    );
    final total = ShoppingCalculations.sumCents(
      currentEvents.map((event) => event.totalCents),
    );
    return MonthlyHistoryReport(
      monthKey: monthKey,
      trips: currentEvents,
      products: products,
      totalCents: total,
    );
  }

  Future<ProductPurchaseHistory> getProductPurchaseHistory({
    required int productId,
    required DateTime asOf,
  }) async {
    final product = await _requireProduct(productId);
    final mode = MeasurementMode.values.firstWhere(
      (value) => value.name == product.measurementMode,
      orElse: () => MeasurementMode.pending,
    );
    final throughDate = ShoppingHistoryCalculations.civilDate(asOf);
    final query =
        _database.select(_database.shoppingTrips).join([
          innerJoin(
            _database.purchaseLines,
            _database.purchaseLines.tripId.equalsExp(
              _database.shoppingTrips.id,
            ),
          ),
        ])..where(
          _database.shoppingTrips.status.equals('completed') &
              _database.shoppingTrips.purchaseDate.isSmallerOrEqualValue(
                throughDate,
              ) &
              _database.purchaseLines.productId.equals(productId) &
              _database.purchaseLines.status.equals('included') &
              _database.purchaseLines.totalCents.isNotNull() &
              _database.purchaseLines.measurementMode.equals(mode.name),
        );
    query.orderBy([
      OrderingTerm.desc(_database.shoppingTrips.purchaseDate),
      OrderingTerm.desc(_database.shoppingTrips.id),
      OrderingTerm.asc(_database.purchaseLines.id),
    ]);
    final rows = await query.get();
    final events = _eventsFromJoinedRows(rows);
    final dates =
        events
            .map((event) => DateTime.parse(event.trip.purchaseDate))
            .toSet()
            .toList()
          ..sort();
    final observedMonths =
        dates.map(ShoppingHistoryCalculations.monthKey).toSet().toList()
          ..sort((first, second) => second.compareTo(first));
    final today = ShoppingHistoryCalculations.civilDateOnly(asOf);
    final lastDate = dates.isEmpty
        ? null
        : ShoppingHistoryCalculations.civilDateOnly(dates.last);
    return ProductPurchaseHistory(
      productName: product.name,
      mode: mode,
      events: events,
      observedMonths: observedMonths,
      daysSinceLastPurchase: lastDate == null
          ? null
          : today.difference(lastDate).inDays,
      medianIntervalDays: ShoppingHistoryCalculations.medianIntervalDays(dates),
    );
  }

  Future<TripProjection> getTripProjection(int tripId) async {
    final trip = await _requireTrip(tripId);
    final cartLines = await (_database.select(
      _database.purchaseLines,
    )..where((line) => line.tripId.equals(tripId))).get();
    final knownCartCents = ShoppingCalculations.sumCents(
      cartLines.map((line) => line.totalCents).whereType<int>(),
    );
    final plannedCartCents = ShoppingCalculations.sumCents(
      cartLines
          .where((line) => line.plannedItemId != null)
          .map((line) => line.totalCents)
          .whereType<int>(),
    );
    final outsidePlanCartCents = ShoppingCalculations.sumCents(
      cartLines
          .where((line) => line.plannedItemId == null)
          .map((line) => line.totalCents)
          .whereType<int>(),
    );
    final pendingCartLineCount = cartLines
        .where((line) => line.totalCents == null)
        .length;
    var estimatedRemainingCents = 0;
    var estimatedItemsCount = 0;
    var itemsWithoutEstimate = 0;
    if (trip.planId != null) {
      final items = await getPlannedItems(trip.planId!);
      for (final item in items) {
        final progress = await getPlanItemProgress(item.id);
        final remaining = progress.remainingFor(item.quantity);
        if (remaining == 0) {
          continue;
        }
        final numerator = item.estimatePriceNumeratorCents;
        final denominator = item.estimateQuantityDenominator;
        if (numerator == null || denominator == null) {
          itemsWithoutEstimate++;
          continue;
        }
        estimatedItemsCount++;
        estimatedRemainingCents = ShoppingCalculations.sumCents([
          estimatedRemainingCents,
          ShoppingHistoryCalculations.estimateTotalCents(
            quantity: remaining,
            amountCents: numerator,
            quantityBasis: denominator,
          ),
        ]);
      }
    }
    return TripProjection(
      knownCartCents: knownCartCents,
      plannedCartCents: plannedCartCents,
      outsidePlanCartCents: outsidePlanCartCents,
      knownCartLineCount: cartLines
          .where((line) => line.totalCents != null)
          .length,
      pendingCartLineCount: pendingCartLineCount,
      estimatedRemainingCents: estimatedRemainingCents,
      estimatedItemsCount: estimatedItemsCount,
      itemsWithoutEstimate: itemsWithoutEstimate,
      projectedCents: ShoppingCalculations.sumCents([
        plannedCartCents,
        outsidePlanCartCents,
        estimatedRemainingCents,
      ]),
    );
  }

  Future<_EstimateSnapshot?> _findLatestEstimate({
    required int productId,
    required MeasurementMode mode,
    required DateTime beforeDate,
  }) async {
    final cutoff = ShoppingHistoryCalculations.civilDate(beforeDate);
    final query =
        _database.select(_database.shoppingTrips).join([
          innerJoin(
            _database.purchaseLines,
            _database.purchaseLines.tripId.equalsExp(
              _database.shoppingTrips.id,
            ),
          ),
        ])..where(
          _database.shoppingTrips.status.equals('completed') &
              _database.shoppingTrips.purchaseDate.isSmallerThanValue(cutoff) &
              _database.purchaseLines.productId.equals(productId) &
              _database.purchaseLines.measurementMode.equals(mode.name) &
              _database.purchaseLines.status.equals('included') &
              _database.purchaseLines.totalCents.isNotNull(),
        );
    query.orderBy([
      OrderingTerm.desc(_database.shoppingTrips.purchaseDate),
      OrderingTerm.desc(_database.shoppingTrips.id),
    ]);
    final rows = await query.get();
    if (rows.isEmpty) {
      return null;
    }
    final referenceTrip = rows.first.readTable(_database.shoppingTrips);
    final referenceLines = rows
        .where(
          (row) =>
              row.readTable(_database.shoppingTrips).id == referenceTrip.id,
        )
        .map((row) => row.readTable(_database.purchaseLines))
        .toList();
    final amountCents = ShoppingCalculations.sumCents(
      referenceLines.map((line) => line.totalCents!),
    );
    final quantity = _sumQuantitiesChecked(
      referenceLines.map((line) => line.quantity),
    );
    return _EstimateSnapshot(
      priceNumeratorCents: amountCents,
      quantityDenominator: quantity,
      source: 'history',
      referenceDate: referenceTrip.purchaseDate,
      referenceTripId: referenceTrip.id,
    );
  }

  Future<List<PurchaseLine>> _includedLinesForTrips(
    List<ShoppingTrip> trips,
  ) async {
    if (trips.isEmpty) {
      return [];
    }
    return (_database.select(_database.purchaseLines)..where(
          (line) =>
              line.tripId.isIn(trips.map((trip) => trip.id)) &
              line.status.equals('included') &
              line.totalCents.isNotNull(),
        ))
        .get();
  }

  List<PurchaseHistoryEvent> _eventsForTrips(
    List<ShoppingTrip> trips,
    List<PurchaseLine> lines,
  ) {
    final linesByTrip = <int, List<PurchaseLine>>{};
    for (final line in lines) {
      linesByTrip.putIfAbsent(line.tripId, () => []).add(line);
    }
    return [
      for (final trip in trips)
        if (linesByTrip[trip.id]?.isNotEmpty ?? false)
          _historyEvent(trip, linesByTrip[trip.id]!),
    ];
  }

  List<PurchaseHistoryEvent> _eventsFromJoinedRows(List<TypedResult> rows) {
    final tripById = <int, ShoppingTrip>{};
    final linesByTrip = <int, List<PurchaseLine>>{};
    for (final row in rows) {
      final trip = row.readTable(_database.shoppingTrips);
      tripById[trip.id] = trip;
      linesByTrip
          .putIfAbsent(trip.id, () => [])
          .add(row.readTable(_database.purchaseLines));
    }
    final tripIds = tripById.keys.toList()
      ..sort((first, second) {
        final firstTrip = tripById[first]!;
        final secondTrip = tripById[second]!;
        final dateOrder = secondTrip.purchaseDate.compareTo(
          firstTrip.purchaseDate,
        );
        return dateOrder != 0 ? dateOrder : second.compareTo(first);
      });
    return [
      for (final id in tripIds) _historyEvent(tripById[id]!, linesByTrip[id]!),
    ];
  }

  PurchaseHistoryEvent _historyEvent(
    ShoppingTrip trip,
    List<PurchaseLine> lines,
  ) {
    final quantity = _sumQuantitiesChecked(lines.map((line) => line.quantity));
    final totalCents = ShoppingCalculations.sumCents(
      lines.map((line) => line.totalCents!),
    );
    final mode = MeasurementMode.values.firstWhere(
      (value) => value.name == lines.first.measurementMode,
    );
    return PurchaseHistoryEvent(
      trip: trip,
      lines: lines,
      quantity: quantity,
      totalCents: totalCents,
      unitPriceCents: ShoppingHistoryCalculations.displayUnitPriceCents(
        mode: mode,
        amountCents: totalCents,
        quantityBasis: quantity,
      ),
    );
  }

  Map<String, _ProductLineAggregate> _aggregateProductLines(
    List<PurchaseLine> lines,
  ) {
    final grouped = <String, List<PurchaseLine>>{};
    for (final line in lines) {
      grouped
          .putIfAbsent(
            _productModeKey(line.productId, line.measurementMode),
            () => [],
          )
          .add(line);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: _ProductLineAggregate.fromLines(entry.value),
    };
  }

  Future<PurchaseHistoryEvent?> _latestProductPurchase({
    required int productId,
    required String onOrBefore,
  }) async {
    final product = await _requireProduct(productId);
    final query =
        _database.select(_database.shoppingTrips).join([
          innerJoin(
            _database.purchaseLines,
            _database.purchaseLines.tripId.equalsExp(
              _database.shoppingTrips.id,
            ),
          ),
        ])..where(
          _database.shoppingTrips.status.equals('completed') &
              _database.shoppingTrips.purchaseDate.isSmallerOrEqualValue(
                onOrBefore,
              ) &
              _database.purchaseLines.productId.equals(productId) &
              _database.purchaseLines.measurementMode.equals(
                product.measurementMode,
              ) &
              _database.purchaseLines.status.equals('included') &
              _database.purchaseLines.totalCents.isNotNull(),
        );
    query.orderBy([
      OrderingTerm.desc(_database.shoppingTrips.purchaseDate),
      OrderingTerm.desc(_database.shoppingTrips.id),
    ]);
    final rows = await query.get();
    if (rows.isEmpty) {
      return null;
    }
    final latestTrip = rows.first.readTable(_database.shoppingTrips);
    final latestLines = rows
        .where(
          (row) => row.readTable(_database.shoppingTrips).id == latestTrip.id,
        )
        .map((row) => row.readTable(_database.purchaseLines))
        .toList();
    return _historyEvent(latestTrip, latestLines);
  }

  static String _productModeKey(int productId, String mode) =>
      '$productId:$mode';

  static int _sumQuantitiesChecked(Iterable<int> quantities) {
    var total = BigInt.zero;
    for (final quantity in quantities) {
      total += BigInt.from(quantity);
    }
    if (total > BigInt.from(9007199254740991)) {
      throw const FormatException('Quantidade acima do limite aceito.');
    }
    return total.toInt();
  }

  Future<PlanItemProgress> getPlanItemProgress(int itemId) async {
    final lines = await (_database.select(
      _database.purchaseLines,
    )..where((line) => line.plannedItemId.equals(itemId))).get();
    var purchased = 0;
    var inCart = 0;
    for (final line in lines) {
      final trip = await _requireTrip(line.tripId);
      if (trip.status == 'completed') {
        purchased = _checkedQuantitySum(purchased, line.quantity);
      } else if (trip.status == 'in_progress') {
        inCart = _checkedQuantitySum(inCart, line.quantity);
      }
    }
    return PlanItemProgress(
      purchasedQuantity: purchased,
      inCartQuantity: inCart,
    );
  }

  Future<Map<int, int>> getTripPlannedQuantities(int tripId) async {
    await _requireTrip(tripId);
    final lines = await (_database.select(
      _database.purchaseLines,
    )..where((line) => line.tripId.equals(tripId))).get();
    final quantitiesByItemId = <int, int>{};
    for (final line in lines) {
      final itemId = line.plannedItemId;
      if (itemId != null) {
        quantitiesByItemId[itemId] = _checkedQuantitySum(
          quantitiesByItemId[itemId] ?? 0,
          line.quantity,
        );
      }
    }
    return quantitiesByItemId;
  }

  Future<int?> totalForTrip(int tripId) async {
    final lines = await (_database.select(
      _database.purchaseLines,
    )..where((line) => line.tripId.equals(tripId))).get();
    final knownTotals = lines
        .map((line) => line.totalCents)
        .whereType<int>()
        .toList();
    if (knownTotals.isEmpty) {
      return null;
    }
    return ShoppingCalculations.sumCents(knownTotals);
  }

  Future<ShoppingPlan> _requirePlan(int id) async {
    final plan = await (_database.select(
      _database.shoppingPlans,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (plan == null) {
      throw StateError('A lista não existe mais.');
    }
    return plan;
  }

  Future<void> _ensurePlanNotCompleted(int planId) async {
    final plan = await _requirePlan(planId);
    if (plan.status == 'open') {
      return;
    }
    final completedTrip =
        await (_database.select(_database.shoppingTrips)
              ..where(
                (trip) =>
                    trip.planId.equals(planId) &
                    trip.status.equals('completed'),
              )
              ..limit(1))
            .getSingleOrNull();
    if (completedTrip != null) {
      throw const FormatException(
        'Esta lista já foi realizada e está fechada.',
      );
    }
  }

  static bool _isEditablePlanStatus(String status) =>
      status == 'active' || status == 'open';

  Future<ShoppingTrip> _requireTrip(int id) async {
    final trip = await (_database.select(
      _database.shoppingTrips,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (trip == null) {
      throw StateError('A compra não existe mais.');
    }
    return trip;
  }

  Future<Product> _requireProduct(int id) async {
    final product = await (_database.select(
      _database.products,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (product == null) {
      throw StateError('O produto não existe mais.');
    }
    return product;
  }

  static bool _isValidMonthKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }
    final month = int.parse(match[2]!);
    return month >= 1 && month <= 12;
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _requiredText(String value, String message) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw FormatException(message);
    }
    return normalized;
  }

  static String? _optionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static void _validateQuantity(int quantity) {
    if (quantity <= 0 || quantity > 9007199254740991) {
      throw const FormatException(
        'A quantidade precisa ser positiva e caber no banco local.',
      );
    }
  }

  static int _checkedQuantitySum(int first, int second) {
    final sum = BigInt.from(first) + BigInt.from(second);
    if (sum > BigInt.from(9007199254740991)) {
      throw const FormatException(
        'Quantidade acima do limite aceito pelo banco.',
      );
    }
    return sum.toInt();
  }
}
