import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_calculations.dart';
import '../domain/shopping_history.dart';
import 'plan_item_picker_screen.dart';
import 'shopping_dialogs.dart';

class ShoppingPlansScreen extends ConsumerWidget {
  const ShoppingPlansScreen({required this.onOpenTrip, super.key});

  final ValueChanged<int> onOpenTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(shoppingPlansProvider);
    final trips = ref.watch(shoppingTripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Listas planejadas')),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _PlansError(message: 'Não foi possível carregar: $error'),
        data: (rows) => trips.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PlansError(
            message: 'Não foi possível carregar as compras: $error',
          ),
          data: (tripRows) => _buildPlanList(context, rows, tripRows),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlan(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova lista'),
      ),
    );
  }

  Widget _buildPlanList(
    BuildContext context,
    List<ShoppingPlan> plans,
    List<ShoppingTrip> trips,
  ) {
    if (plans.isEmpty) {
      return const _PlansEmpty();
    }
    final activeTrips = trips.where((t) => t.status == 'in_progress').toList();
    final grouped = <ShoppingPlanListStatus, List<ShoppingPlan>>{
      for (final status in ShoppingPlanListStatus.values)
        status: plans
            .where((plan) => shoppingPlanListStatus(plan, trips) == status)
            .toList(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        if (activeTrips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Compra em andamento${activeTrips.first.marketName != null ? ' · ${activeTrips.first.marketName}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Toque para continuar no carrinho'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => onOpenTrip(activeTrips.first.id),
              ),
            ),
          ),
        _planSection(
          context,
          'Em andamento',
          grouped[ShoppingPlanListStatus.inProgress]!,
          trips,
          Icons.shopping_cart_outlined,
        ),
        _planSection(
          context,
          'Listas abertas',
          grouped[ShoppingPlanListStatus.openList]!,
          trips,
          Icons.playlist_add_check_circle_outlined,
        ),
        _planSection(
          context,
          'Novas',
          grouped[ShoppingPlanListStatus.newList]!,
          trips,
          Icons.fiber_new_outlined,
        ),
        if (grouped[ShoppingPlanListStatus.completed]!.isNotEmpty)
          Card(
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(
                'Listas realizadas (${grouped[ShoppingPlanListStatus.completed]!.length})',
              ),
              children: [
                for (final plan in grouped[ShoppingPlanListStatus.completed]!)
                  _planCard(
                    context,
                    plan,
                    ShoppingPlanListStatus.completed,
                    trips,
                  ),
              ],
            ),
          ),
        if (grouped[ShoppingPlanListStatus.canceled]!.isNotEmpty)
          Card(
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Text(
                'Listas canceladas (${grouped[ShoppingPlanListStatus.canceled]!.length})',
              ),
              children: [
                for (final plan in grouped[ShoppingPlanListStatus.canceled]!)
                  _planCard(
                    context,
                    plan,
                    ShoppingPlanListStatus.canceled,
                    trips,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _planSection(
    BuildContext context,
    String title,
    List<ShoppingPlan> plans,
    List<ShoppingTrip> trips,
    IconData icon,
  ) {
    if (plans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final plan in plans)
          _planCard(
            context,
            plan,
            shoppingPlanListStatus(plan, trips),
            trips,
            icon: icon,
          ),
      ],
    );
  }

  Widget _planCard(
    BuildContext context,
    ShoppingPlan plan,
    ShoppingPlanListStatus status,
    List<ShoppingTrip> trips, {
    IconData? icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon ??
              switch (status) {
                ShoppingPlanListStatus.newList => Icons.fiber_new_outlined,
                ShoppingPlanListStatus.inProgress =>
                  Icons.shopping_cart_outlined,
                ShoppingPlanListStatus.openList =>
                  Icons.playlist_add_check_circle_outlined,
                ShoppingPlanListStatus.completed => Icons.task_alt,
                ShoppingPlanListStatus.canceled => Icons.cancel_outlined,
              },
        ),
        title: Text(plan.name),
        subtitle: Text(
          'Planejada para ${_formatMonth(plan.monthKey)}'
          ' · ${_planStatusLabel(status)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ShoppingPlanDetailScreen(
              planId: plan.id,
              onOpenTrip: onOpenTrip,
            ),
          ),
        ),
      ),
    );
  }

  String _planStatusLabel(ShoppingPlanListStatus status) => switch (status) {
    ShoppingPlanListStatus.newList => 'Nova',
    ShoppingPlanListStatus.inProgress => 'Em andamento',
    ShoppingPlanListStatus.openList => 'Aberta',
    ShoppingPlanListStatus.completed => 'Realizada',
    ShoppingPlanListStatus.canceled => 'Cancelada',
  };

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final draft = await showCreatePlanDialog(context);
    if (draft == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .createPlan(monthKey: draft.monthKey, name: draft.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lista criada.')));
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }
}

class ShoppingPlanDetailScreen extends ConsumerWidget {
  const ShoppingPlanDetailScreen({
    required this.planId,
    required this.onOpenTrip,
    super.key,
  });

  final int planId;
  final ValueChanged<int> onOpenTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(shoppingPlanProvider(planId));
    final trips = ref.watch(shoppingTripsProvider);
    final plannedItems = ref.watch(plannedItemsProvider(planId));
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final allPlans = ref.watch(shoppingPlansProvider);
    final planRow = plan.asData?.value;
    final tripRows = trips.asData?.value;
    final status = planRow == null || tripRows == null
        ? null
        : shoppingPlanListStatus(planRow, tripRows);

    return Scaffold(
      appBar: AppBar(
        title: Text(planRow?.name ?? 'Lista'),
        actions: [
          if (status != null &&
              status != ShoppingPlanListStatus.canceled &&
              status != ShoppingPlanListStatus.completed)
            IconButton(
              tooltip: 'Iniciar compra',
              onPressed: () => _startTrip(context, ref),
              icon: const Icon(Icons.shopping_cart_checkout),
            ),
          PopupMenuButton<String>(
            tooltip: 'Ações da lista',
            onSelected: (action) {
              if (action == 'cancel') {
                _cancelPlan(context, ref);
              } else if (action == 'copyFromPlan') {
                _copyFromPlan(context, ref, allPlans.asData?.value ?? []);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copyFromPlan',
                child: Text('Copiar itens de lista anterior'),
              ),
              if (status != null &&
                  status != ShoppingPlanListStatus.canceled &&
                  status != ShoppingPlanListStatus.completed)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('Cancelar lista'),
                ),
            ],
          ),
        ],
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _PlansError(message: 'Não foi possível carregar a lista: $error'),
        data: (planRow) {
          if (planRow == null) {
            return const _PlansError(message: 'Esta lista não existe mais.');
          }
          return trips.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _PlansError(
              message: 'Não foi possível carregar o status da lista: $error',
            ),
            data: (tripData) => plannedItems.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _PlansError(
                message: 'Não foi possível carregar os itens: $error',
              ),
              data: (items) => products.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _PlansError(
                  message: 'Não foi possível carregar os produtos: $error',
                ),
                data: (productRows) => _buildPlan(
                  context,
                  ref,
                  planRow,
                  shoppingPlanListStatus(planRow, tripData),
                  items,
                  productRows,
                  categories.asData?.value ?? [],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton:
          status != null &&
              status != ShoppingPlanListStatus.canceled &&
              status != ShoppingPlanListStatus.completed &&
              products.asData?.value.any((product) => !product.isArchived) ==
                  true
          ? FloatingActionButton.extended(
              onPressed: () => _addPlanItem(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar produto'),
            )
          : null,
      bottomNavigationBar:
          status != null &&
              status != ShoppingPlanListStatus.canceled &&
              status != ShoppingPlanListStatus.completed
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: () => _startTrip(context, ref),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Abrir / iniciar compra'),
              ),
            )
          : null,
    );
  }

  Widget _buildPlan(
    BuildContext context,
    WidgetRef ref,
    ShoppingPlan plan,
    ShoppingPlanListStatus status,
    List<PlannedItem> items,
    List<Product> products,
    List<Category> categories,
  ) {
    final productById = {for (final product in products) product.id: product};
    final categoryById = {for (final cat in categories) cat.id: cat};
    final visibleItems = items.where((item) => !item.isRemoved).toList();
    final estimatedItems = visibleItems
        .where(
          (item) =>
              item.estimatePriceNumeratorCents != null &&
              item.estimateQuantityDenominator != null,
        )
        .toList();
    final estimatedPlanTotal = ShoppingCalculations.sumCents(
      estimatedItems.map(
        (item) => ShoppingHistoryCalculations.estimateTotalCents(
          quantity: item.quantity,
          amountCents: item.estimatePriceNumeratorCents!,
          quantityBasis: item.estimateQuantityDenominator!,
        ),
      ),
    );
    final itemsWithoutEstimate = visibleItems.length - estimatedItems.length;

    // Agrupamento por categoria
    final itemsByCategory = <int?, List<PlannedItem>>{};
    for (final item in visibleItems) {
      final product = productById[item.productId];
      itemsByCategory.putIfAbsent(product?.categoryId, () => []).add(item);
    }
    final sortedCategoryIds = itemsByCategory.keys.toList()
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

    final isEditable =
        status == ShoppingPlanListStatus.newList ||
        status == ShoppingPlanListStatus.inProgress ||
        status == ShoppingPlanListStatus.openList;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text('Mês planejado: ${_formatMonth(plan.monthKey)}'),
            subtitle: const Text(
              'A data real será registrada separadamente ao iniciar uma compra.',
            ),
          ),
        ),
        if (visibleItems.isNotEmpty)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: Text(
                'Estimativa planejada: '
                '${estimatedItems.isEmpty ? 'incompleta' : ShoppingCalculations.formatMoney(estimatedPlanTotal)}',
              ),
              subtitle: Text(
                itemsWithoutEstimate == 0
                    ? 'Valores estimados e fotografados para este planejamento.'
                    : 'Parcial: $itemsWithoutEstimate item(ns) sem preço de referência.',
              ),
            ),
          ),
        if (status == ShoppingPlanListStatus.canceled)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.cancel_outlined),
              title: Text('Lista cancelada'),
              subtitle: Text(
                'O planejamento está preservado. Uma compra já iniciada é independente e deve ser cancelada separadamente.',
              ),
            ),
          ),
        if (status == ShoppingPlanListStatus.inProgress)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('Lista em andamento'),
              subtitle: Text(
                'Uma compra desta lista está aberta. Abra-a para continuar.',
              ),
            ),
          ),
        if (status == ShoppingPlanListStatus.openList)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.playlist_add_check_circle_outlined),
              title: Text('Lista aberta'),
              subtitle: Text(
                'A última compra foi concluída e os itens restantes continuam nesta lista.',
              ),
            ),
          ),
        if (status == ShoppingPlanListStatus.completed)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.task_alt),
              title: Text('Lista realizada'),
              subtitle: Text(
                'A compra foi concluída. Este planejamento está fechado.',
              ),
            ),
          ),
        Expanded(
          child: visibleItems.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Esta lista ainda não tem produtos. Toque em "Adicionar produtos" para montar sua lista.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: sortedCategoryIds.length,
                  itemBuilder: (context, catIndex) {
                    final categoryId = sortedCategoryIds[catIndex];
                    final category = categoryById[categoryId];
                    final categoryItems = itemsByCategory[categoryId]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                          child: Text(
                            category?.name ?? 'Sem categoria',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        for (final item in categoryItems)
                          _buildPlanItemTile(
                            context,
                            ref,
                            plan: plan,
                            item: item,
                            product: productById[item.productId],
                            isEditable: isEditable,
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlanItemTile(
    BuildContext context,
    WidgetRef ref, {
    required ShoppingPlan plan,
    required PlannedItem item,
    required Product? product,
    required bool isEditable,
  }) {
    final progress = ref.watch(planItemProgressProvider(item.id));
    final mode = _mode(item.measurementMode);
    final estimateDesc = _estimateDescription(item);

    final tile = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Produto indisponível',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (item.authorName != null || item.authorUid != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Adicionado por ${item.authorName ?? item.authorUid}'
                      '${item.createdAt.year < 2000 ? '' : ' · ${_formatReviewDate(item.createdAt)}'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (item.reviewState == 'pending_review') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Aguardando revisão do owner',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  progress.when(
                    loading: () => const Text(
                      'Calculando atendimento…',
                      style: TextStyle(fontSize: 12),
                    ),
                    error: (e, _) => Text(
                      'Progresso indisponível: $e',
                      style: const TextStyle(fontSize: 12),
                    ),
                    data: (val) {
                      final remaining = val.remainingFor(item.quantity);
                      if (val.purchasedQuantity == 0 &&
                          val.inCartQuantity == 0) {
                        return Text(
                          'Planejado: ${ShoppingCalculations.formatQuantity(mode, item.quantity)}'
                          '${estimateDesc != 'Sem preço estimado' ? ' · $estimateDesc' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        );
                      }
                      return Text(
                        'Comprado ${ShoppingCalculations.formatQuantity(mode, val.purchasedQuantity)}'
                        ' · carrinho ${ShoppingCalculations.formatQuantity(mode, val.inCartQuantity)}'
                        ' · faltam ${ShoppingCalculations.formatQuantity(mode, remaining)}'
                        '\n$estimateDesc',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
            ),
            if (isEditable) ...[
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Diminuir quantidade',
                onPressed: () {
                  final step = mode == MeasurementMode.weight ? 100 : 1;
                  if (item.quantity > step) {
                    ref
                        .read(shoppingRepositoryProvider)
                        .updatePlannedQuantity(item.id, item.quantity - step);
                  }
                },
              ),
              InkWell(
                onTap: () => _editQuantity(context, ref, item),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    ShoppingCalculations.formatQuantity(mode, item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Aumentar quantidade',
                onPressed: () {
                  final step = mode == MeasurementMode.weight ? 100 : 1;
                  ref
                      .read(shoppingRepositoryProvider)
                      .updatePlannedQuantity(item.id, item.quantity + step);
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações do item',
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  if (action == 'edit') {
                    _editQuantity(context, ref, item);
                  } else if (action == 'remove') {
                    _removeItem(context, ref, item);
                  } else if (action == 'refreshEstimate') {
                    _refreshEstimate(context, ref, item);
                  } else if (action == 'manualEstimate') {
                    _setManualEstimate(context, ref, item);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Digitar quantidade'),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remover da lista'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'refreshEstimate',
                    child: Text('Atualizar estimativa'),
                  ),
                  PopupMenuItem(
                    value: 'manualEstimate',
                    child: Text('Definir preço estimado'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!isEditable) return tile;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(shoppingRepositoryProvider).removePlannedItem(item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product?.name ?? "Produto"} removido.'),
              action: SnackBarAction(
                label: 'DESFAZER',
                onPressed: () async {
                  await ref
                      .read(shoppingRepositoryProvider)
                      .addPlannedItem(
                        planId: plan.id,
                        productId: item.productId,
                        mode: mode,
                        quantity: item.quantity,
                      );
                  ref.invalidate(plannedItemsProvider(plan.id));
                },
              ),
            ),
          );
        }
      },
      child: tile,
    );
  }

  String _formatReviewDate(DateTime value) {
    return DateFormat('d MMM, HH:mm', 'pt_BR').format(value.toLocal());
  }

  String _estimateDescription(PlannedItem item) {
    final source = item.estimateSource;
    final date = item.estimateReferenceDate;
    final numerator = item.estimatePriceNumeratorCents;
    final denominator = item.estimateQuantityDenominator;
    if (source == null ||
        date == null ||
        numerator == null ||
        denominator == null) {
      return 'Sem preço estimado';
    }
    final mode = _mode(item.measurementMode);
    final unitPrice = ShoppingHistoryCalculations.displayUnitPriceCents(
      mode: mode,
      amountCents: numerator,
      quantityBasis: denominator,
    );
    final unit = mode.priceUnit;
    final origin = source == 'history'
        ? 'Última compra'
        : 'Preço informado manualmente';
    return '$origin em ${_formatCivilDate(date)}: '
        '${ShoppingCalculations.formatMoney(unitPrice)}/$unit';
  }

  Future<void> _refreshEstimate(
    BuildContext context,
    WidgetRef ref,
    PlannedItem item,
  ) async {
    try {
      final found = await ref
          .read(shoppingRepositoryProvider)
          .refreshPlannedItemEstimate(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              found
                  ? 'Estimativa atualizada com a última compra anterior ao mês planejado.'
                  : 'Não há compra compatível anterior ao mês planejado.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _setManualEstimate(
    BuildContext context,
    WidgetRef ref,
    PlannedItem item,
  ) async {
    final cents = await showManualEstimateDialog(
      context: context,
      mode: _mode(item.measurementMode),
    );
    if (cents == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .setManualEstimate(itemId: item.id, unitPriceCents: cents);
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _cancelPlan(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancelar esta lista?'),
            content: const Text(
              'A lista e seus itens continuarão preservados em Listas canceladas. Uma compra já iniciada não será cancelada automaticamente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cancelar lista'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(shoppingRepositoryProvider).cancelPlan(planId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista cancelada e preservada.')),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _addPlanItem(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanItemPickerScreen(planId: planId),
      ),
    );
  }

  Future<void> _copyFromPlan(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingPlan> allPlans,
  ) async {
    final available = allPlans.where((p) => p.id != planId).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma outra lista para copiar.')),
      );
      return;
    }
    final selected = await showDialog<ShoppingPlan>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copiar lista anterior'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (context, index) {
              final p = available[index];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('Mês: ${_formatMonth(p.monthKey)}'),
                onTap: () => Navigator.pop(dialogContext, p),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    try {
      final count = await ref
          .read(shoppingRepositoryProvider)
          .copyPlannedItems(sourcePlanId: selected.id, targetPlanId: planId);
      ref.invalidate(plannedItemsProvider(planId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? '$count produto(s) copiado(s) de "${selected.name}".'
                  : 'Todos os produtos de "${selected.name}" já estão nesta lista.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _editQuantity(
    BuildContext context,
    WidgetRef ref,
    PlannedItem item,
  ) async {
    final formKey = GlobalKey<FormState>();
    var quantityText = '${item.quantity}';
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar quantidade planejada'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: quantityText,
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (value) => quantityText = value,
            decoration: InputDecoration(
              labelText:
                  'Quantidade (${_mode(item.measurementMode).quantityUnit})',
            ),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              return parsed == null || parsed <= 0
                  ? 'Informe um inteiro maior que zero.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, int.parse(quantityText.trim()));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (quantity == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .updatePlannedQuantity(item.id, quantity);
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _removeItem(
    BuildContext context,
    WidgetRef ref,
    PlannedItem item,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remover produto da lista?'),
            content: const Text(
              'O produto continuará no catálogo e compras já concluídas serão preservadas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(shoppingRepositoryProvider).removePlannedItem(item.id);
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }

  Future<void> _startTrip(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(shoppingRepositoryProvider);
      final activeTrip = await repository.getActiveTripForPlan(planId);
      if (activeTrip != null) {
        if (context.mounted) {
          Navigator.pop(context);
          onOpenTrip(activeTrip.id);
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
      final draft = await showCreateTripDialog(context);
      if (draft == null || !context.mounted) {
        return;
      }
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: draft.purchaseDate,
        marketName: draft.marketName,
      );
      if (context.mounted) {
        Navigator.pop(context);
        onOpenTrip(tripId);
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showError(context, error);
      }
    }
  }
}

class _PlansEmpty extends StatelessWidget {
  const _PlansEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined, size: 48),
          SizedBox(height: 12),
          Text('Nenhuma lista planejada'),
          SizedBox(height: 8),
          Text(
            'Crie uma lista para um mês e escolha os produtos e quantidades que deseja comprar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _PlansError extends StatelessWidget {
  const _PlansError({required this.message});

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

String _formatMonth(String monthKey) {
  final date = DateTime.parse('$monthKey-01');
  return DateFormat.yMMMM('pt_BR').format(date);
}

String _formatCivilDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateFormat.yMMMd('pt_BR')
      .format(DateTime(parts[0], parts[1], parts[2]));
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Não foi possível concluir: $error')));
}
