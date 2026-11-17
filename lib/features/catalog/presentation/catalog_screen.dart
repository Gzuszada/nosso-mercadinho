import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../data/app_database.dart';
import '../../backup/presentation/backup_actions.dart';
import '../../shopping/presentation/product_purchase_history_screen.dart';
import '../data/catalog_import.dart';
import '../data/catalog_repository.dart';
import '../../shopping/domain/shopping_calculations.dart';
import 'catalog_dialogs.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({
    this.initialTab = 0,
    this.showNavigationBar = true,
    super.key,
  });

  final int initialTab;
  final bool showNavigationBar;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showArchived = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_basket_outlined), text: 'Produtos'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categorias'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              tooltip: _showArchived
                  ? 'Ocultar arquivados'
                  : 'Mostrar arquivados',
              onPressed: () => setState(() => _showArchived = !_showArchived),
              icon: Icon(
                _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'Dados e backup',
            onSelected: (action) => _runOptionalAction(
              () => _handleMenuAction(action, database),
              action == 'import'
                  ? 'Catálogo inicial importado.'
                  : action == 'export'
                  ? 'Backup salvo.'
                  : 'Backup restaurado; os dados anteriores foram substituídos.',
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'import',
                child: Text('Importar catálogo inicial'),
              ),
              PopupMenuItem(value: 'export', child: Text('Exportar backup')),
              PopupMenuItem(value: 'restore', child: Text('Restaurar backup')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProductsView(
            showArchived: _showArchived,
            searchQuery: _searchQuery,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onImportCatalog: () => _runOptionalAction(
              () => _handleMenuAction('import', database),
              'Catálogo inicial importado.',
            ),
          ),
          const CategoriesView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0
            ? () => _runOptionalAction(() => _createProduct(), 'Produto salvo.')
            : () => _runOptionalAction(
                () => _createCategory(),
                'Categoria salva.',
              ),
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Produto' : 'Categoria'),
      ),
    );
  }

  Future<bool> _handleMenuAction(String action, AppDatabase database) async {
    switch (action) {
      case 'import':
        final contents = await rootBundle.loadString(
          'assets/catalogo-inicial.json',
        );
        final catalog = CatalogImport.fromJson(contents);
        if (!mounted) {
          return false;
        }
        final approved = await showCatalogImportPreview(context, catalog);
        if (!mounted || !approved) {
          return false;
        }
        await ref.read(catalogRepositoryProvider).importCatalog(catalog);
        return true;
      case 'export':
        return exportBackup(context, database);
      case 'restore':
        return restoreBackupFromFile(context, database);
      default:
        throw ArgumentError.value(action, 'action', 'Ação desconhecida.');
    }
  }

  Future<bool> _createProduct() async {
    final categories = await ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).categories)
        .get();
    final subcategories = await ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).subcategories)
        .get();
    if (!mounted) {
      return false;
    }
    final draft = await showProductDialog(
      context: context,
      categories: categories,
      subcategories: subcategories,
    );
    if (draft == null) {
      return false;
    }
    await ref
        .read(catalogRepositoryProvider)
        .saveProduct(
          name: draft.name,
          categoryId: draft.categoryId,
          subcategoryId: draft.subcategoryId,
          measurementMode: draft.measurementMode,
          needsCategoryReview: draft.needsCategoryReview,
          description: draft.description,
        );
    return true;
  }

  Future<bool> _createCategory() async {
    final name = await showNameDialog(
      context: context,
      title: 'Nova categoria',
    );
    if (name == null) {
      return false;
    }
    await ref.read(catalogRepositoryProvider).saveCategory(name: name);
    return true;
  }

  Future<void> _runOptionalAction(
    Future<bool> Function() action,
    String successMessage,
  ) async {
    try {
      final changed = await action();
      if (changed && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $error')),
        );
      }
    }
  }
}

class ProductsView extends ConsumerWidget {
  const ProductsView({
    required this.showArchived,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onImportCatalog,
    super.key,
  });

  final bool showArchived;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onImportCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);
    final subcategories = ref.watch(subcategoriesProvider);

    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(message: 'Produtos: $error'),
      data: (productRows) => categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(message: 'Categorias: $error'),
        data: (categoryRows) => subcategories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(message: 'Subcategorias: $error'),
          data: (subcategoryRows) => _buildList(
            context,
            ref,
            productRows,
            categoryRows,
            subcategoryRows,
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
    List<Category> categories,
    List<Subcategory> subcategories,
  ) {
    final visibleProducts = products.where((product) {
      if (!showArchived && product.isArchived) {
        return false;
      }
      return normalizeText(product.name).contains(normalizeText(searchQuery));
    }).toList()..sort((a, b) => compareNormalized(a.name, b.name));
    final categoryById = {for (final item in categories) item.id: item};
    final subcategoryById = {for (final item in subcategories) item.id: item};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar produto',
              labelText: 'Catálogo',
            ),
          ),
        ),
        if (products.isEmpty)
          Expanded(
            child: _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Seu catálogo está vazio',
              message: 'Revise a lista inicial antes de salvar os produtos. Nenhuma compra será criada.',
              actionLabel: 'Importar catálogo inicial',
              onPressed: onImportCatalog,
            ),
          )
        else if (visibleProducts.isEmpty)
          const Expanded(
            child: Center(child: Text('Nenhum produto encontrado.')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                final product = visibleProducts[index];
                final category = categoryById[product.categoryId];
                final subcategory = subcategoryById[product.subcategoryId];
                final categoryLabel =
                    product.needsCategoryReview ||
                        product.categoryId == null ||
                        category == null
                    ? 'A classificar'
                    : category.name;
                final classification = subcategory == null
                    ? categoryLabel
                    : '$categoryLabel · ${subcategory.name}';

                return Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '$classification · ${_measurementLabel(product.measurementMode)}'
                      '${product.isArchived ? ' · Arquivado' : ''}'
                      '${product.description == null ? '' : '\n${product.description}'}',
                    ),
                    isThreeLine: product.description != null,
                    onTap: () => _editProduct(
                      context,
                      ref,
                      product,
                      categories,
                      subcategories,
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações do produto',
                      onSelected: (action) => _productAction(
                        context,
                        ref,
                        product,
                        categories,
                        subcategories,
                        action,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Text('Ver histórico de compras'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Apagar',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: product.isArchived ? 'restore' : 'archive',
                          child: Text(
                            product.isArchived ? 'Reativar' : 'Arquivar',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _productAction(
    BuildContext context,
    WidgetRef ref,
    Product product,
    List<Category> categories,
    List<Subcategory> subcategories,
    String action,
  ) async {
    if (action == 'edit') {
      await _editProduct(context, ref, product, categories, subcategories);
      return;
    }
    if (action == 'history') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductPurchaseHistoryScreen(productId: product.id),
        ),
      );
      return;
    }
    if (action == 'delete') {
      await _deleteProduct(context, ref, product);
      return;
    }
    final confirmed = await confirmArchive(
      context: context,
      itemName: product.name,
      isArchived: product.isArchived,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .setProductArchived(product.id, !product.isArchived);
    }, product.isArchived ? 'Produto reativado.' : 'Produto arquivado.');
  }

  Future<void> _editProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
    List<Category> categories,
    List<Subcategory> subcategories,
  ) async {
    final draft = await showProductDialog(
      context: context,
      categories: categories,
      subcategories: subcategories,
      product: product,
    );
    if (draft == null || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .saveProduct(
            id: product.id,
            name: draft.name,
            categoryId: draft.categoryId,
            subcategoryId: draft.subcategoryId,
            measurementMode: draft.measurementMode,
            needsCategoryReview: draft.needsCategoryReview,
            description: draft.description,
          );
    }, 'Produto salvo.');
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final status = await repository.checkProductDeletion(product.id);
      if (status != ProductDeletionResult.ready) {
        if (context.mounted) {
          await _showProductDeletionWarning(context, product, status);
        }
        return;
      }
      if (!context.mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Apagar produto?'),
          content: Text(
            '“${product.name}” será apagado permanentemente do catálogo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Apagar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }

      final result = await repository.deleteProductIfUnused(product.id);
      if (!context.mounted) {
        return;
      }
      if (result == ProductDeletionResult.deleted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Produto apagado.')));
      } else if (result == ProductDeletionResult.notFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O produto não existe mais.')),
        );
      } else {
        await _showProductDeletionWarning(context, product, result);
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível apagar o produto: $error')),
        );
      }
    }
  }

  Future<void> _showProductDeletionWarning(
    BuildContext context,
    Product product,
    ProductDeletionResult status,
  ) async {
    final message = switch (status) {
      ProductDeletionResult.hasCompletedPurchases =>
        '“${product.name}” aparece em compras concluídas. Para preservar esse histórico, arquive o produto em vez de apagá-lo.',
      ProductDeletionResult.hasPlannedItems =>
        '“${product.name}” ainda está em uma lista. Retire-o da lista primeiro e tente apagá-lo novamente.',
      ProductDeletionResult.hasInProgressPurchases =>
        '“${product.name}” está em uma compra em andamento. Retire-o do carrinho antes de apagá-lo.',
      ProductDeletionResult.hasCanceledPurchases =>
        '“${product.name}” aparece em uma compra cancelada preservada. O registro precisa ser mantido; arquive o produto em vez de apagá-lo.',
      ProductDeletionResult.notFound =>
        'O produto não existe mais no catálogo.',
      ProductDeletionResult.ready || ProductDeletionResult.deleted => null,
    };
    if (message == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Produto não pode ser apagado'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

class CategoriesView extends ConsumerWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final subcategories = ref.watch(subcategoriesProvider);

    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadError(message: 'Categorias: $error'),
      data: (categoryRows) => subcategories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(message: 'Subcategorias: $error'),
        data: (subcategoryRows) {
          if (categoryRows.isEmpty) {
            return const _EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria cadastrada',
              message: 'Crie categorias e, se necessário, subcategorias para organizar o catálogo.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: categoryRows.length,
            itemBuilder: (context, index) {
              final category = categoryRows[index];
              final children = subcategoryRows
                  .where((item) => item.categoryId == category.id)
                  .toList();
              return Card(
                child: ExpansionTile(
                  key: PageStorageKey<int>(category.id),
                  title: Text(category.name),
                  subtitle: Text(
                    '${children.length} subcategorias'
                    '${category.isArchived ? ' · Arquivada' : ''}',
                  ),
                  childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                    16,
                    0,
                    16,
                    12,
                  ),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _editCategory(context, ref, category),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _toggleCategory(context, ref, category),
                            icon: Icon(
                              category.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                            ),
                            label: Text(
                              category.isArchived ? 'Reativar' : 'Arquivar',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _deleteCategory(context, ref, category),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Apagar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),
                          if (!category.isArchived)
                            TextButton.icon(
                              onPressed: () =>
                                  _createSubcategory(context, ref, category),
                              icon: const Icon(Icons.add),
                              label: const Text('Subcategoria'),
                            ),
                          IconButton(
                            tooltip: 'Mover categoria para cima',
                            onPressed: index == 0
                                ? null
                                : () => _moveCategory(
                                    context,
                                    ref,
                                    categoryRows,
                                    index,
                                    -1,
                                  ),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Mover categoria para baixo',
                            onPressed: index == categoryRows.length - 1
                                ? null
                                : () => _moveCategory(
                                    context,
                                    ref,
                                    categoryRows,
                                    index,
                                    1,
                                  ),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                        ],
                      ),
                    ),
                    for (
                      var subcategoryIndex = 0;
                      subcategoryIndex < children.length;
                      subcategoryIndex++
                    )
                      _buildSubcategoryTile(
                        context,
                        ref,
                        category,
                        children,
                        subcategoryIndex,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryTile(
    BuildContext context,
    WidgetRef ref,
    Category category,
    List<Subcategory> subcategories,
    int index,
  ) {
    final subcategory = subcategories[index];
    return ListTile(
      dense: true,
      title: Text(subcategory.name),
      subtitle: subcategory.isArchived ? const Text('Arquivada') : null,
      onTap: () => _editSubcategory(context, ref, category, subcategory),
      trailing: Wrap(
        spacing: 0,
        children: [
          IconButton(
            tooltip: 'Mover subcategoria para cima',
            onPressed: index == 0
                ? null
                : () => _moveSubcategory(
                    context,
                    ref,
                    category.id,
                    subcategories,
                    index,
                    -1,
                  ),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Mover subcategoria para baixo',
            onPressed: index == subcategories.length - 1
                ? null
                : () => _moveSubcategory(
                    context,
                    ref,
                    category.id,
                    subcategories,
                    index,
                    1,
                  ),
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            tooltip: subcategory.isArchived
                ? 'Reativar subcategoria'
                : 'Arquivar subcategoria',
            onPressed: () => _toggleSubcategory(context, ref, subcategory),
            icon: Icon(
              subcategory.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCategory(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    int index,
    int offset,
  ) async {
    final orderedIds = categories.map((item) => item.id).toList();
    final movedId = orderedIds.removeAt(index);
    orderedIds.insert(index + offset, movedId);
    await _runWithFeedback(context, () {
      return ref.read(catalogRepositoryProvider).reorderCategories(orderedIds);
    }, 'Ordem das categorias salva.');
  }

  Future<void> _moveSubcategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
    List<Subcategory> subcategories,
    int index,
    int offset,
  ) async {
    final orderedIds = subcategories.map((item) => item.id).toList();
    final movedId = orderedIds.removeAt(index);
    orderedIds.insert(index + offset, movedId);
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .reorderSubcategories(categoryId, orderedIds);
    }, 'Ordem das subcategorias salva.');
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await showNameDialog(
      context: context,
      title: 'Editar categoria',
      initialName: category.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .saveCategory(id: category.id, name: name);
    }, 'Categoria salva.');
  }

  Future<void> _toggleCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await confirmArchive(
      context: context,
      itemName: category.name,
      isArchived: category.isArchived,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .setCategoryArchived(category.id, !category.isArchived);
    }, category.isArchived ? 'Categoria reativada.' : 'Categoria arquivada.');
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final repository = ref.read(catalogRepositoryProvider);
    try {
      if (await repository.hasProductsInCategory(category.id)) {
        if (context.mounted) {
          await _showCategoryHasProductsWarning(context, category);
        }
        return;
      }
      if (!context.mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Apagar categoria?'),
          content: Text(
            'A categoria “${category.name}” e suas subcategorias serão apagadas permanentemente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Apagar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }

      final result = await repository.deleteCategoryIfUnused(category.id);
      if (!context.mounted) {
        return;
      }
      switch (result) {
        case CategoryDeletionResult.deleted:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Categoria apagada.')));
          break;
        case CategoryDeletionResult.hasProducts:
          await _showCategoryHasProductsWarning(context, category);
          break;
        case CategoryDeletionResult.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A categoria não existe mais.')),
          );
          break;
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível apagar a categoria: $error'),
          ),
        );
      }
    }
  }

  Future<void> _showCategoryHasProductsWarning(
    BuildContext context,
    Category category,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Categoria não pode ser apagada'),
        content: Text(
          'Existem produtos vinculados à categoria “${category.name}”. '
          'Reatribua ou remova esses produtos antes de apagar a categoria.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSubcategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await showNameDialog(
      context: context,
      title: 'Nova subcategoria',
    );
    if (name == null || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .saveSubcategory(categoryId: category.id, name: name);
    }, 'Subcategoria salva.');
  }

  Future<void> _editSubcategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
    Subcategory subcategory,
  ) async {
    final name = await showNameDialog(
      context: context,
      title: 'Editar subcategoria',
      initialName: subcategory.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await _runWithFeedback(context, () {
      return ref
          .read(catalogRepositoryProvider)
          .saveSubcategory(
            id: subcategory.id,
            categoryId: category.id,
            name: name,
          );
    }, 'Subcategoria salva.');
  }

  Future<void> _toggleSubcategory(
    BuildContext context,
    WidgetRef ref,
    Subcategory subcategory,
  ) async {
    final confirmed = await confirmArchive(
      context: context,
      itemName: subcategory.name,
      isArchived: subcategory.isArchived,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await _runWithFeedback(
      context,
      () {
        return ref
            .read(catalogRepositoryProvider)
            .setSubcategoryArchived(subcategory.id, !subcategory.isArchived);
      },
      subcategory.isArchived
          ? 'Subcategoria reativada.'
          : 'Subcategoria arquivada.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.preview_outlined),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

String _measurementLabel(String value) => switch (value) {
  'unit' => 'Por unidade',
  'package' => 'Por pacote',
  'weight' => 'Por peso',
  _ => 'Revisar forma de compra',
};

Future<void> _runWithFeedback(
  BuildContext context,
  Future<Object?> Function() action,
  String successMessage,
) async {
  try {
    await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    }
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível concluir: $error')),
      );
    }
  }
}
