import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../domain/shopping_calculations.dart';

class PlanItemPickerScreen extends ConsumerStatefulWidget {
  const PlanItemPickerScreen({required this.planId, super.key});

  final int planId;

  @override
  ConsumerState<PlanItemPickerScreen> createState() =>
      _PlanItemPickerScreenState();
}

class _PlanItemPickerScreenState extends ConsumerState<PlanItemPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final plannedItemsAsync = ref.watch(plannedItemsProvider(widget.planId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar à lista'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: const Text('Pronto'),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Erro ao carregar produtos: $error')),
        data: (products) => categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Erro ao carregar categorias: $error')),
          data: (categories) => subcategoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (subcategories) => plannedItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (plannedItems) => _buildBody(
                context,
                products: products.where((p) => !p.isArchived).toList(),
                categories: categories,
                subcategories: subcategories,
                plannedItems: plannedItems.where((i) => !i.isRemoved).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<Product> products,
    required List<Category> categories,
    required List<Subcategory> subcategories,
    required List<PlannedItem> plannedItems,
  }) {
    final normalizedQuery = normalizeText(_searchQuery);
    final filteredProducts = products.where((product) {
      if (normalizedQuery.isEmpty) return true;
      return normalizeText(product.name).contains(normalizedQuery);
    }).toList();

    filteredProducts.sort((a, b) => compareNormalized(a.name, b.name));

    final plannedByProductId = {
      for (final item in plannedItems) item.productId: item,
    };

    final categoryById = {for (final c in categories) c.id: c};
    final subcategoryById = {for (final s in subcategories) s.id: s};

    // Agrupamento por categoria
    final productsByCategory = <int?, List<Product>>{};
    for (final product in filteredProducts) {
      productsByCategory.putIfAbsent(product.categoryId, () => []).add(product);
    }

    final sortedCategoryIds = productsByCategory.keys.toList()
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

    final totalPlannedInList = plannedItems.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Buscar produto no catálogo...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$totalPlannedInList item(ns) na lista · ${filteredProducts.length} produtos disponíveis',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Nenhum produto encontrado.'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: sortedCategoryIds.length,
                  itemBuilder: (context, catIndex) {
                    final categoryId = sortedCategoryIds[catIndex];
                    final category = categoryById[categoryId];
                    final categoryProducts = productsByCategory[categoryId]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                category?.name ?? 'Sem categoria',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (categoryProducts.any(
                                (product) =>
                                    product.measurementMode ==
                                    MeasurementMode.pending.name,
                              )) ...[
                                _buildCategoryModeButton(
                                  categoryId,
                                  MeasurementMode.unit,
                                  'Unidade',
                                ),
                                _buildCategoryModeButton(
                                  categoryId,
                                  MeasurementMode.package,
                                  'Pacote',
                                ),
                                _buildCategoryModeButton(
                                  categoryId,
                                  MeasurementMode.weight,
                                  'Peso',
                                ),
                              ],
                            ],
                          ),
                        ),
                        for (final product in categoryProducts)
                          _buildProductTile(
                            context,
                            product: product,
                            subcategory: subcategoryById[product.subcategoryId],
                            plannedItem: plannedByProductId[product.id],
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductTile(
    BuildContext context, {
    required Product product,
    required Subcategory? subcategory,
    required PlannedItem? plannedItem,
  }) {
    final mode = MeasurementMode.values.firstWhere(
      (m) => m.name == product.measurementMode,
      orElse: () => MeasurementMode.pending,
    );

    final isInPlan = plannedItem != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isInPlan
          ? Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.25)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isInPlan
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (subcategory != null)
                        Text(
                          subcategory.name,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                    ],
                  ),
                ),
                if (mode != MeasurementMode.pending)
                  _buildQuantityControl(
                    context,
                    product: product,
                    plannedItem: plannedItem,
                    mode: mode,
                  ),
              ],
            ),
            if (mode == MeasurementMode.pending) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Forma de compra: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  _buildModeChip(product, MeasurementMode.unit, 'Unidade'),
                  const SizedBox(width: 4),
                  _buildModeChip(product, MeasurementMode.package, 'Pacote'),
                  const SizedBox(width: 4),
                  _buildModeChip(product, MeasurementMode.weight, 'Peso'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryModeButton(
    int? categoryId,
    MeasurementMode mode,
    String label,
  ) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      tooltip: 'Definir $label para os produtos pendentes da categoria',
      onPressed: () => _setCategoryMode(categoryId, mode),
    );
  }

  Future<void> _setCategoryMode(int? categoryId, MeasurementMode mode) async {
    final database = ref.read(databaseProvider);
    final categoryName = categoryId == null
        ? 'Sem categoria'
        : (await (database.select(database.categories)
                        ..where((row) => row.id.equals(categoryId)))
                      .getSingleOrNull())
                  ?.name ??
              'Categoria';
    final count = await ref
        .read(shoppingRepositoryProvider)
        .updatePendingProductsMeasurementModeByCategory(
          categoryId: categoryId,
          mode: mode,
        );
    ref.invalidate(productsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Nenhum produto pendente foi alterado em $categoryName.'
              : '$count produto(s) de $categoryName definido(s) como $mode.',
        ),
      ),
    );
  }

  Widget _buildModeChip(Product product, MeasurementMode mode, String label) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () async {
        final repo = ref.read(shoppingRepositoryProvider);
        await repo.updateProductMeasurementMode(
          productId: product.id,
          mode: mode,
        );
        ref.invalidate(productsProvider);
      },
    );
  }

  Widget _buildQuantityControl(
    BuildContext context, {
    required Product product,
    required PlannedItem? plannedItem,
    required MeasurementMode mode,
  }) {
    if (plannedItem == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Adicionar'),
        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: () => _addInitial(product, mode),
      );
    }

    final quantity = plannedItem.quantity;
    final step = mode == MeasurementMode.weight ? 100 : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            quantity <= step ? Icons.delete_outline : Icons.remove,
            size: 20,
            color: quantity <= step
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: quantity <= step ? 'Remover' : 'Diminuir',
          onPressed: () => _decrease(plannedItem, quantity, step),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 54),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            ShoppingCalculations.formatQuantity(mode, quantity),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 20),
          visualDensity: VisualDensity.compact,
          tooltip: 'Aumentar',
          onPressed: () => _increase(plannedItem, quantity, step),
        ),
      ],
    );
  }

  Future<void> _addInitial(Product product, MeasurementMode mode) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final initialQty = mode == MeasurementMode.weight ? 500 : 1;
    await repo.addPlannedItem(
      planId: widget.planId,
      productId: product.id,
      mode: mode,
      quantity: initialQty,
    );
    ref.invalidate(plannedItemsProvider(widget.planId));
  }

  Future<void> _increase(PlannedItem item, int currentQty, int step) async {
    final repo = ref.read(shoppingRepositoryProvider);
    await repo.updatePlannedQuantity(item.id, currentQty + step);
    ref.invalidate(plannedItemsProvider(widget.planId));
  }

  Future<void> _decrease(PlannedItem item, int currentQty, int step) async {
    final repo = ref.read(shoppingRepositoryProvider);
    if (currentQty <= step) {
      await repo.removePlannedItem(item.id);
    } else {
      await repo.updatePlannedQuantity(item.id, currentQty - step);
    }
    ref.invalidate(plannedItemsProvider(widget.planId));
  }
}
