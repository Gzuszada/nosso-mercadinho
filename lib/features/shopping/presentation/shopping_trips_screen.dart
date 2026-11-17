import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_calculations.dart';
import '../domain/shopping_history.dart';
import 'shopping_dialogs.dart';

class ShoppingTripsScreen extends ConsumerWidget {
  const ShoppingTripsScreen({required this.onOpenTrip, super.key});

  final ValueChanged<int> onOpenTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(shoppingTripsProvider);
    final plans = ref.watch(shoppingPlansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: [
          IconButton(
            tooltip: 'Compra sem lista',
            onPressed: () => _createStandaloneTrip(context, ref),
            icon: const Icon(Icons.add_shopping_cart),
          ),
        ],
      ),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TripsError(
          message: 'Não foi possível carregar as compras: $error',
        ),
        data: (tripRows) => plans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _TripsError(
            message: 'Não foi possível carregar as listas: $error',
          ),
          data: (planRows) => _buildTripList(context, ref, tripRows, planRows),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createStandaloneTrip(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Compra sem lista'),
      ),
    );
  }

  Widget _buildTripList(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingTrip> trips,
    List<ShoppingPlan> plans,
  ) {
    final planById = {for (final plan in plans) plan.id: plan.name};
    final active = trips.where((trip) => trip.status == 'in_progress').toList();
    final completed = trips
        .where((trip) => trip.status == 'completed')
        .toList();
    final canceled = trips.where((trip) => trip.status == 'canceled').toList();
    if (trips.isEmpty) {
      return const _TripsEmpty();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        if (active.isNotEmpty) ...[
          const _SectionHeading(title: 'Em andamento'),
          for (final trip in active)
            _TripCard(
              trip: trip,
              planName: trip.originPlanNameSnapshot ?? planById[trip.planId],
              onTap: () => onOpenTrip(trip.id),
            ),
        ],
        if (completed.isNotEmpty) ...[
          Card(
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text('Compras concluídas (${completed.length})'),
              children: [
                for (final trip in completed)
                  _TripCard(
                    trip: trip,
                    planName:
                        trip.originPlanNameSnapshot ?? planById[trip.planId],
                    onTap: () => onOpenTrip(trip.id),
                  ),
              ],
            ),
          ),
        ],
        if (canceled.isNotEmpty) ...[
          Card(
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text('Compras canceladas (${canceled.length})'),
              children: [
                for (final trip in canceled)
                  _TripCard(
                    trip: trip,
                    planName:
                        trip.originPlanNameSnapshot ?? planById[trip.planId],
                    onTap: () => onOpenTrip(trip.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _createStandaloneTrip(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final draft = await showCreateTripDialog(context);
    if (draft == null || !context.mounted) {
      return;
    }
    try {
      final tripId = await ref
          .read(shoppingRepositoryProvider)
          .createTrip(
            purchaseDate: draft.purchaseDate,
            marketName: draft.marketName,
          );
      if (context.mounted) {
        onOpenTrip(tripId);
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }
}

class ShoppingTripDetailScreen extends ConsumerWidget {
  const ShoppingTripDetailScreen({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(shoppingTripProvider(tripId));
    final lines = ref.watch(purchaseLinesProvider(tripId));
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final subcategories = ref.watch(subcategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        actions: [
          trip.asData?.value?.status == 'in_progress'
              ? PopupMenuButton<String>(
                  tooltip: 'Ações da compra',
                  onSelected: (action) {
                    if (action == 'cancel') {
                      _cancelTrip(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancelar compra'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: trip.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _TripsError(message: 'Não foi possível carregar a compra: $error'),
        data: (tripRow) {
          if (tripRow == null) {
            return const _TripsError(message: 'Esta compra não existe mais.');
          }
          return lines.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _TripsError(
              message: 'Não foi possível carregar o carrinho: $error',
            ),
            data: (lineRows) => products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _TripsError(
                message: 'Não foi possível carregar os produtos: $error',
              ),
              data: (productRows) => categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _TripsError(
                  message: 'Não foi possível carregar as categorias: $error',
                ),
                data: (categoryRows) => subcategories.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _TripsError(
                    message:
                        'Não foi possível carregar as subcategorias: $error',
                  ),
                  data: (subcategoryRows) => _buildTrip(
                    context,
                    ref,
                    tripRow,
                    lineRows,
                    productRows,
                    categoryRows,
                    subcategoryRows,
                    tripRow.planId != null
                        ? (ref
                                  .watch(plannedItemsProvider(tripRow.planId!))
                                  .asData
                                  ?.value ??
                              [])
                        : const <PlannedItem>[],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrip(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    List<PurchaseLine> lines,
    List<Product> products,
    List<Category> categories,
    List<Subcategory> subcategories,
    List<PlannedItem> plannedItems,
  ) {
    final productById = {for (final product in products) product.id: product};
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final subcategoryById = {
      for (final subcategory in subcategories) subcategory.id: subcategory,
    };
    final completed = trip.status == 'completed';
    final canceled = trip.status == 'canceled';
    final pendingCount = lines.where((line) => line.totalCents == null).length;
    final totalCents = ShoppingCalculations.sumCents(
      lines.map((line) => line.totalCents).whereType<int>(),
    );
    final projection = ref.watch(tripProjectionProvider(trip.id));

    // Mapear itens pendentes da lista
    final inCartQuantityByPlannedItem = <int, int>{};
    for (final line in lines) {
      if (line.plannedItemId != null) {
        inCartQuantityByPlannedItem[line.plannedItemId!] =
            (inCartQuantityByPlannedItem[line.plannedItemId!] ?? 0) +
            line.quantity;
      }
    }

    final pendingPlannedItems = plannedItems.where((item) {
      if (item.isRemoved) return false;
      final inCart = inCartQuantityByPlannedItem[item.id] ?? 0;
      return inCart < item.quantity;
    }).toList();

    // Agrupar itens pendentes por categoria
    final pendingByCategory = <int?, List<PlannedItem>>{};
    for (final item in pendingPlannedItems) {
      final product = productById[item.productId];
      pendingByCategory.putIfAbsent(product?.categoryId, () => []).add(item);
    }
    final sortedPendingCategoryIds = pendingByCategory.keys.toList()
      ..sort((a, b) {
        if (a == null) return b == null ? 0 : 1;
        if (b == null) return -1;
        final catA = categoryById[a];
        final catB = categoryById[b];
        final orderComp = (catA?.sortOrder ?? 0).compareTo(
          catB?.sortOrder ?? 0,
        );
        if (orderComp != 0) return orderComp;
        return compareNormalized(catA?.name ?? '', catB?.name ?? '');
      });

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: Icon(
              completed
                  ? Icons.check_circle_outline
                  : canceled
                  ? Icons.cancel_outlined
                  : Icons.shopping_cart_outlined,
            ),
            title: Text(_formatDate(trip.purchaseDate)),
            subtitle: Text(
              [
                if (trip.marketName != null) trip.marketName!,
                if (completed) 'Compra concluída',
                if (canceled) 'Compra cancelada',
                if (!completed && !canceled) 'Compra em andamento',
              ].join(' · '),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: [
              if (trip.planId != null &&
                  !completed &&
                  !canceled &&
                  pendingPlannedItems.isNotEmpty) ...[
                _CartGroupHeading(
                  title: '📋 A pegar na lista (${pendingPlannedItems.length})',
                ),
                for (final categoryId in sortedPendingCategoryIds) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                    child: Text(
                      categoryById[categoryId]?.name ?? 'Sem categoria',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final item in pendingByCategory[categoryId]!) ...[
                    _buildPendingItemCard(
                      context,
                      ref,
                      trip: trip,
                      item: item,
                      product: productById[item.productId],
                      alreadyInCart: inCartQuantityByPlannedItem[item.id] ?? 0,
                    ),
                  ],
                ],
                const SizedBox(height: 12),
              ],
              if (lines.isNotEmpty) ...[
                if (trip.planId != null &&
                    !completed &&
                    !canceled &&
                    pendingPlannedItems.isNotEmpty)
                  const _CartGroupHeading(title: '🛒 Já no carrinho'),
                for (final categoryGroup in _groupLinesByCategory(
                  lines: lines,
                  productsById: productById,
                  categoryById: categoryById,
                  subcategoryById: subcategoryById,
                  completed: completed,
                )) ...[
                  _CartGroupHeading(title: categoryGroup.name),
                  for (final subcategoryGroup in _sortedSubcategories(
                    categoryGroup,
                  )) ...[
                    if (subcategoryGroup.name != null)
                      _CartSubcategoryHeading(title: subcategoryGroup.name!),
                    for (final line in subcategoryGroup.lines)
                      _buildLineCard(
                        context,
                        ref,
                        trip,
                        line,
                        products,
                        productById[line.productId],
                        completed: completed,
                        canceled: canceled,
                      ),
                  ],
                ],
              ] else if (pendingPlannedItems.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      completed
                          ? 'Compra sem linhas registradas.'
                          : 'Carrinho vazio. Adicione o primeiro produto.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              if (!completed && !canceled)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _addLine(
                      context,
                      ref,
                      trip,
                      products,
                      selection: trip.planId == null
                          ? PurchaseLineSelection.all
                          : PurchaseLineSelection.outsidePlan,
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      trip.planId == null
                          ? 'Adicionar produto'
                          : 'Adicionar outro produto (fora da lista)',
                    ),
                  ),
                ),
            ],
          ),
        ),
        _TripTotalFooter(
          trip: trip,
          totalCents: totalCents,
          pendingCount: pendingCount,
          lineCount: lines.length,
          projection: projection,
          onAddPlannedLine: trip.status == 'in_progress' && trip.planId != null
              ? () => _addLine(
                  context,
                  ref,
                  trip,
                  products,
                  selection: PurchaseLineSelection.planned,
                )
              : null,
          onAddOtherLine: trip.status == 'in_progress'
              ? () => _addLine(
                  context,
                  ref,
                  trip,
                  products,
                  selection: trip.planId == null
                      ? PurchaseLineSelection.all
                      : PurchaseLineSelection.outsidePlan,
                )
              : null,
          onComplete: () =>
              _completeTrip(context, ref, trip, totalCents, lines.length),
        ),
      ],
    );
  }

  Widget _buildPendingItemCard(
    BuildContext context,
    WidgetRef ref, {
    required ShoppingTrip trip,
    required PlannedItem item,
    required Product? product,
    required int alreadyInCart,
  }) {
    final mode = _mode(item.measurementMode);
    final remaining = item.quantity - alreadyInCart;
    String? lastPriceText;
    if (item.estimatePriceNumeratorCents != null &&
        item.estimateQuantityDenominator != null) {
      final unitPrice = ShoppingHistoryCalculations.displayUnitPriceCents(
        mode: mode,
        amountCents: item.estimatePriceNumeratorCents!,
        quantityBasis: item.estimateQuantityDenominator!,
      );
      lastPriceText =
          '${ShoppingCalculations.formatMoney(unitPrice)}/${mode.priceUnit}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ListTile(
        leading: Icon(
          Icons.playlist_add_check,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          product?.name ?? 'Produto indisponível',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Faltam: ${ShoppingCalculations.formatQuantity(mode, remaining)} · Planejado: ${ShoppingCalculations.formatQuantity(mode, item.quantity)}'
          '${lastPriceText != null ? '\nÚltimo pago: $lastPriceText' : ''}',
        ),
        trailing: FilledButton.tonal(
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('Pegar'),
          onPressed: () => _quickAddPlannedItem(
            context,
            ref,
            trip,
            item,
            product,
            remaining,
          ),
        ),
        onTap: () =>
            _quickAddPlannedItem(context, ref, trip, item, product, remaining),
      ),
    );
  }

  Future<void> _quickAddPlannedItem(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    PlannedItem item,
    Product? product,
    int remainingQuantity,
  ) async {
    if (product == null) return;
    final mode = _mode(item.measurementMode);
    final lastPrice = await ref
        .read(shoppingRepositoryProvider)
        .getLatestPaidUnitPriceCents(productId: item.productId, mode: mode);
    if (!context.mounted) return;
    final lastPriceText = lastPrice == null
        ? null
        : '${ShoppingCalculations.formatMoney(lastPrice)}/${mode.priceUnit}';

    final draft = await showQuickAddToCartSheet(
      context: context,
      product: product,
      plannedItem: item,
      initialQuantity: remainingQuantity,
      mode: mode,
      lastPricePaidText: lastPriceText,
    );

    if (draft == null || !context.mounted) return;

    try {
      await ref
          .read(shoppingRepositoryProvider)
          .addPurchaseLine(
            tripId: trip.id,
            productId: draft.productId,
            plannedItemId: draft.plannedItemId,
            mode: draft.mode,
            quantity: draft.quantity,
            unitPriceCents: draft.unitPriceCents,
            labelTotalCents: draft.labelTotalCents,
          );
      ref.invalidate(productsProvider);
      if (trip.planId != null) {
        ref.invalidate(plannedItemsProvider(trip.planId!));
      }
      ref.invalidate(planItemProgressProvider(item.id));
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  List<_CartCategoryGroup> _groupLinesByCategory({
    required List<PurchaseLine> lines,
    required Map<int, Product> productsById,
    required Map<int, Category> categoryById,
    required Map<int, Subcategory> subcategoryById,
    required bool completed,
  }) {
    final grouped = <String, _CartCategoryGroup>{};
    for (final line in lines) {
      final product = productsById[line.productId];
      final categoryId = product?.categoryId;
      final subcategoryId = product?.subcategoryId;
      final category = categoryById[categoryId];
      final categoryName = completed
          ? line.categoryNameSnapshot ?? category?.name ?? 'Sem categoria'
          : category?.name ?? 'Sem categoria';
      final categoryGroup = grouped.putIfAbsent(
        categoryName,
        () => _CartCategoryGroup(
          name: categoryName,
          sortOrder: category?.sortOrder ?? 0,
        ),
      );
      final subcategory = subcategoryById[subcategoryId];
      final subcategoryName = completed
          ? line.subcategoryNameSnapshot ?? subcategory?.name
          : subcategory?.name;
      final subcategoryGroup = categoryGroup.subcategories.putIfAbsent(
        subcategoryName,
        () => _CartSubcategoryGroup(
          name: subcategoryName,
          sortOrder: subcategory?.sortOrder ?? 0,
        ),
      );
      subcategoryGroup.lines.add(line);
    }

    final categoryGroups = grouped.values.toList()
      ..sort((first, second) {
        final order = first.sortOrder.compareTo(second.sortOrder);
        return order == 0 ? compareNormalized(first.name, second.name) : order;
      });
    for (final category in categoryGroups) {
      for (final subcategory in category.subcategories.values) {
        subcategory.lines.sort((first, second) {
          final firstProduct =
              productsById[first.productId]?.name ??
              first.productNameSnapshot ??
              'Produto';
          final secondProduct =
              productsById[second.productId]?.name ??
              second.productNameSnapshot ??
              'Produto';
          return compareNormalized(firstProduct, secondProduct);
        });
      }
    }
    return categoryGroups;
  }

  Widget _buildLineCard(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    PurchaseLine line,
    List<Product> products,
    Product? product, {
    required bool completed,
    required bool canceled,
  }) {
    final productName = completed
        ? line.productNameSnapshot ?? product?.name ?? 'Produto'
        : product?.name ?? 'Produto indisponível';
    final quantity = ShoppingCalculations.formatQuantity(
      _mode(line.measurementMode),
      line.quantity,
    );
    final subtitle = line.totalCents == null
        ? '$quantity · Preço pendente; não entra no total'
        : '$quantity · ${ShoppingCalculations.formatMoney(line.totalCents!)}'
              ' (${ShoppingCalculations.formatMoney(line.unitPriceCents!)} / ${_mode(line.measurementMode).priceUnit})';
    final fromPlan = trip.planId != null && line.plannedItemId != null;
    return Card(
      color: fromPlan
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 4,
          end: 4,
          top: 4,
          bottom: 8,
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(productName),
              subtitle: Text(
                trip.planId != null
                    ? '$subtitle\n${fromPlan ? 'Da lista' : 'Fora da lista'}'
                    : subtitle,
              ),
              isThreeLine: trip.planId != null,
              onTap: completed || canceled
                  ? null
                  : () => _editLine(context, ref, trip, line, products),
              trailing: completed || canceled
                  ? null
                  : PopupMenuButton<String>(
                      tooltip: 'Ações da linha',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _editLine(context, ref, trip, line, products);
                        } else if (action == 'remove') {
                          _removeLine(context, ref, line);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'remove', child: Text('Remover')),
                      ],
                    ),
            ),
            if (!completed && !canceled && product != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => _addLine(
                    context,
                    ref,
                    trip,
                    products,
                    initialProductId: line.productId,
                    initialPlannedItemId: line.plannedItemId,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Outra compra deste item'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLine(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    List<Product> products, {
    PurchaseLineSelection selection = PurchaseLineSelection.all,
    int? initialProductId,
    int? initialPlannedItemId,
  }) async {
    try {
      final planItems = trip.planId == null
          ? <PlannedItem>[]
          : await ref
                .read(shoppingRepositoryProvider)
                .getPlannedItems(trip.planId!);
      final quantitiesByPlannedItem = await ref
          .read(shoppingRepositoryProvider)
          .getTripPlannedQuantities(trip.id);
      if (!context.mounted) {
        return;
      }
      final categories = await ref
          .read(databaseProvider)
          .select(ref.read(databaseProvider).categories)
          .get();
      if (!context.mounted) {
        return;
      }
      final draft = await showPurchaseLineDialog(
        context: context,
        products: products,
        plannedItems: planItems,
        categories: categories,
        quantitiesByPlannedItem: quantitiesByPlannedItem,
        planId: trip.planId,
        selection: selection,
        initialProductId: initialProductId,
        initialPlannedItemId: initialPlannedItemId,
      );
      if (draft == null || !context.mounted) {
        return;
      }
      await ref
          .read(shoppingRepositoryProvider)
          .addPurchaseLine(
            tripId: trip.id,
            productId: draft.productId,
            plannedItemId: draft.plannedItemId,
            mode: draft.mode,
            quantity: draft.quantity,
            unitPriceCents: draft.unitPriceCents,
            labelTotalCents: draft.labelTotalCents,
          );
      ref.invalidate(productsProvider);
      if (trip.planId != null) {
        ref.invalidate(plannedItemsProvider(trip.planId!));
      }
      if (draft.plannedItemId != null) {
        ref.invalidate(planItemProgressProvider(draft.plannedItemId!));
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _editLine(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    PurchaseLine line,
    List<Product> products,
  ) async {
    try {
      final product = products
          .where((item) => item.id == line.productId)
          .firstOrNull;
      if (product == null) {
        throw const FormatException('O produto não está mais disponível.');
      }
      final planItems = trip.planId == null
          ? <PlannedItem>[]
          : await ref
                .read(shoppingRepositoryProvider)
                .getPlannedItems(trip.planId!);
      final plannedItem = line.plannedItemId == null
          ? null
          : planItems
                .where((item) => item.id == line.plannedItemId)
                .firstOrNull;
      final mode = _mode(line.measurementMode);
      final lastPrice = await ref
          .read(shoppingRepositoryProvider)
          .getLatestPaidUnitPriceCents(productId: line.productId, mode: mode);
      if (!context.mounted) return;
      final draft = await showQuickAddToCartSheet(
        context: context,
        product: product,
        plannedItem: plannedItem,
        initialQuantity: line.quantity,
        mode: mode,
        lastPricePaidText: lastPrice == null
            ? null
            : '${ShoppingCalculations.formatMoney(lastPrice)}/${mode.priceUnit}',
        existingLine: line,
      );
      if (draft == null || !context.mounted) return;
      await ref
          .read(shoppingRepositoryProvider)
          .updatePurchaseLine(
            lineId: line.id,
            quantity: draft.quantity,
            unitPriceCents: draft.unitPriceCents,
            labelTotalCents: draft.labelTotalCents,
          );
      if (line.plannedItemId != null) {
        ref.invalidate(planItemProgressProvider(line.plannedItemId!));
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _removeLine(
    BuildContext context,
    WidgetRef ref,
    PurchaseLine line,
  ) async {
    if (!await confirmRemoveLine(context) || !context.mounted) {
      return;
    }
    try {
      await ref.read(shoppingRepositoryProvider).removePurchaseLine(line.id);
      if (line.plannedItemId != null) {
        ref.invalidate(planItemProgressProvider(line.plannedItemId!));
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _completeTrip(
    BuildContext context,
    WidgetRef ref,
    ShoppingTrip trip,
    int totalCents,
    int lineCount,
  ) async {
    if (!await confirmCompleteTrip(
      context: context,
      totalCents: totalCents,
      lineCount: lineCount,
    )) {
      return;
    }

    try {
      final repository = ref.read(shoppingRepositoryProvider);
      await repository.completeTrip(trip.id, closePlan: false);
      ref.invalidate(shoppingTripsProvider);

      var remainingCount = 0;
      if (trip.planId != null) {
        final plannedItems = await repository.getPlannedItems(trip.planId!);
        final purchasedMap = await repository.getPlanItemPurchasedQuantities(
          trip.planId!,
        );
        remainingCount = plannedItems
            .where(
              (item) =>
                  !item.isRemoved &&
                  (purchasedMap[item.id] ?? 0) < item.quantity,
            )
            .length;
      }

      if (trip.planId == null || remainingCount == 0) {
        if (trip.planId != null) {
          await repository.finalizePlanAfterPurchase(
            planId: trip.planId!,
            keepOpen: false,
          );
        }
      } else {
        if (!context.mounted) return;
        final action = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Itens não comprados'),
            content: Text(
              'Ainda restam $remainingCount produto(s) planejados que não foram comprados.\n\n'
              'O que deseja fazer com os itens que faltaram?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'keepOpen'),
                child: const Text('Manter lista aberta'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, 'newList'),
                child: const Text('Mover restante para nova lista'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (action == null || action == 'keepOpen') {
          await repository.finalizePlanAfterPurchase(
            planId: trip.planId!,
            keepOpen: true,
          );
        } else {
          final plan = await ref.read(
            shoppingPlanProvider(trip.planId!).future,
          );
          final planName = plan?.name ?? 'Lista';
          final newPlanName = '$planName (Restante)';
          await repository.createPlanFromRemainingItems(
            sourcePlanId: trip.planId!,
            newPlanName: newPlanName,
          );
          await repository.finalizePlanAfterPurchase(
            planId: trip.planId!,
            keepOpen: false,
          );
          ref.invalidate(shoppingPlansProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Nova lista "$newPlanName" criada com o restante.',
                ),
              ),
            );
          }
        }
      }

      if (trip.planId != null) {
        ref.invalidate(plannedItemsProvider(trip.planId!));
        final lines = await repository.watchPurchaseLines(trip.id).first;
        for (final line in lines) {
          if (line.plannedItemId != null) {
            ref.invalidate(planItemProgressProvider(line.plannedItemId!));
          }
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra concluída e salva no histórico.'),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _cancelTrip(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancelar esta compra?'),
            content: const Text(
              'As linhas permanecerão salvas, mas não contarão como gasto nem histórico.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cancelar compra'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(shoppingRepositoryProvider).cancelTrip(tripId);
      ref.invalidate(shoppingTripsProvider);
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }
}

List<_CartSubcategoryGroup> _sortedSubcategories(_CartCategoryGroup category) {
  final groups = category.subcategories.values.toList()
    ..sort((first, second) {
      final order = first.sortOrder.compareTo(second.sortOrder);
      return order == 0
          ? compareNormalized(first.name ?? '', second.name ?? '')
          : order;
    });
  return groups;
}

class _CartCategoryGroup {
  _CartCategoryGroup({required this.name, required this.sortOrder});

  final String name;
  final int sortOrder;
  final Map<String?, _CartSubcategoryGroup> subcategories = {};
}

class _CartSubcategoryGroup {
  _CartSubcategoryGroup({required this.name, required this.sortOrder});

  final String? name;
  final int sortOrder;
  final List<PurchaseLine> lines = [];
}

class _CartGroupHeading extends StatelessWidget {
  const _CartGroupHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CartSubcategoryHeading extends StatelessWidget {
  const _CartSubcategoryHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _TripTotalFooter extends StatefulWidget {
  const _TripTotalFooter({
    required this.trip,
    required this.totalCents,
    required this.pendingCount,
    required this.lineCount,
    required this.projection,
    required this.onAddPlannedLine,
    required this.onAddOtherLine,
    required this.onComplete,
  });

  final ShoppingTrip trip;
  final int totalCents;
  final int pendingCount;
  final int lineCount;
  final AsyncValue<TripProjection> projection;
  final VoidCallback? onAddPlannedLine;
  final VoidCallback? onAddOtherLine;
  final VoidCallback onComplete;

  @override
  State<_TripTotalFooter> createState() => _TripTotalFooterState();
}

class _TripTotalFooterState extends State<_TripTotalFooter> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final lineCount = widget.lineCount;
    final pendingCount = widget.pendingCount;
    final totalCents = widget.totalCents;
    final theme = Theme.of(context);

    final totalText = lineCount == 0
        ? '—'
        : pendingCount == lineCount
        ? 'Sem preço informado'
        : ShoppingCalculations.formatMoney(totalCents);

    final canComplete = lineCount > 0 && pendingCount == 0;

    return Material(
      elevation: 6,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra compacta (sempre visível)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trip.status == 'completed'
                                  ? 'Total da compra'
                                  : 'Total no carrinho',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    totalText,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$pendingCount s/ preço',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (trip.status == 'in_progress') ...[
                        FilledButton(
                          onPressed: canComplete ? widget.onComplete : null,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Concluir'),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_more : Icons.expand_less,
                        ),
                        tooltip: _isExpanded
                            ? 'Recolher detalhes'
                            : 'Ver projeção e ações',
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                      ),
                    ],
                  ),
                ),
              ),

              // Conteúdo expandido
              if (_isExpanded) ...[
                const Divider(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pendingCount > 0) ...[
                          Text(
                            '$pendingCount linha(s) sem preço; o total é parcial e a compra não pode ser concluída.',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (trip.status == 'in_progress') ...[
                          widget.projection.when(
                            loading: () => const Text('Calculando projeção…'),
                            error: (error, _) =>
                                Text('Projeção indisponível: $error'),
                            data: (value) {
                              final noKnownValues =
                                  value.knownCartLineCount == 0 &&
                                  value.estimatedItemsCount == 0;
                              if (noKnownValues &&
                                  value.pendingCartLineCount == 0 &&
                                  value.itemsWithoutEstimate == 0) {
                                return const Text(
                                  'Adicione itens para calcular a projeção.',
                                );
                              }
                              if (value.isPartial && noKnownValues) {
                                return const Text(
                                  'Projeção incompleta: nenhum preço conhecido ou estimativa disponível.',
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${value.isPartial ? 'Projeção parcial' : 'Projeção total'}: '
                                    '${ShoppingCalculations.formatMoney(value.projectedCents)}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (trip.planId != null)
                                    Text(
                                      'Total da lista: ${ShoppingCalculations.formatMoney(value.plannedProjectionCents)}'
                                      ' (carrinho ${ShoppingCalculations.formatMoney(value.plannedCartCents)}'
                                      ' + restante estimado ${ShoppingCalculations.formatMoney(value.estimatedRemainingCents)})',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  Text(
                                    'Fora da lista (preços conhecidos): ${ShoppingCalculations.formatMoney(value.outsidePlanCartCents)}'
                                    '${value.pendingCartLineCount == 0 ? '' : ' · ${value.pendingCartLineCount} linha(s) pendente(s)'}'
                                    '${value.itemsWithoutEstimate == 0 ? '' : ' · ${value.itemsWithoutEstimate} item(ns) sem estimativa'}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (widget.onAddPlannedLine != null) ...[
                            OutlinedButton.icon(
                              onPressed: widget.onAddPlannedLine,
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('Adicionar item da lista'),
                            ),
                            const SizedBox(height: 4),
                          ],
                          OutlinedButton.icon(
                            onPressed: widget.onAddOtherLine,
                            icon: Icon(
                              widget.onAddPlannedLine == null
                                  ? Icons.add
                                  : Icons.add_shopping_cart,
                            ),
                            label: Text(
                              widget.onAddPlannedLine == null
                                  ? 'Adicionar item'
                                  : 'Adicionar outro item',
                            ),
                          ),
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: canComplete ? widget.onComplete : null,
                            child: const Text('Conferir e concluir compra'),
                          ),
                        ] else if (trip.status == 'canceled')
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Compra cancelada: não entra no histórico de gastos.',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({
    required this.trip,
    required this.planName,
    required this.onTap,
  });

  final ShoppingTrip trip;
  final String? planName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(_tripTotalProvider(trip.id));
    return Card(
      child: ListTile(
        leading: Icon(
          trip.status == 'in_progress'
              ? Icons.shopping_cart_outlined
              : trip.status == 'completed'
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
        ),
        title: Text(_formatDate(trip.purchaseDate)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (planName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Da lista · $planName'),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue.shade900
                      : Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade50
                        : Colors.blue.shade900,
                  ),
                ),
              ),
            Text(
              [
                if (trip.marketName != null) trip.marketName!,
                if (trip.status == 'in_progress') 'Em andamento',
                if (trip.status == 'canceled') 'Cancelada',
                if (trip.status == 'completed')
                  total.when(
                    loading: () => 'Calculando total…',
                    error: (error, _) => 'Total indisponível: $error',
                    data: (value) => value == null
                        ? 'Sem preço informado'
                        : ShoppingCalculations.formatMoney(value),
                  ),
              ].join(' · '),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

final _tripTotalProvider = FutureProvider.family<int?, int>((ref, tripId) {
  return ref.watch(shoppingRepositoryProvider).totalForTrip(tripId);
});

class _TripsEmpty extends StatelessWidget {
  const _TripsEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48),
          SizedBox(height: 12),
          Text('Nenhuma compra registrada'),
          SizedBox(height: 8),
          Text(
            'Inicie uma compra por uma lista planejada ou crie uma compra sem lista.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _TripsError extends StatelessWidget {
  const _TripsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

MeasurementMode _mode(String value) => MeasurementMode.values.firstWhere(
  (mode) => mode.name == value,
  orElse: () => MeasurementMode.pending,
);

String _formatDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateFormat.yMMMd('pt_BR')
      .format(DateTime(parts[0], parts[1], parts[2]));
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Não foi possível concluir: $error')));
}
