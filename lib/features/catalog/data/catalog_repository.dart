import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../cloud/domain/collaboration.dart';
import 'catalog_import.dart';

enum CategoryDeletionResult { deleted, hasProducts, notFound }

enum ProductDeletionResult {
  ready,
  deleted,
  hasCompletedPurchases,
  hasPlannedItems,
  hasInProgressPurchases,
  hasCanceledPurchases,
  notFound,
}

class CatalogRepository {
  const CatalogRepository(this._database, {this.actorResolver});

  final AppDatabase _database;
  final CollaborationActorResolver? actorResolver;

  Future<CollaborationActor> _actor() async =>
      await actorResolver?.call() ?? const CollaborationActor.local();

  Future<int> saveCategory({int? id, required String name}) async {
    final normalizedName = _requiredName(name, maxLength: 100);
    final allCategories = await _database.select(_database.categories).get();
    if (allCategories.any(
      (category) =>
          category.id != id &&
          category.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw const FormatException('Já existe uma categoria com esse nome.');
    }

    final now = DateTime.now();
    if (id == null) {
      final nextOrder = allCategories.isEmpty
          ? 0
          : allCategories
                    .map((category) => category.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      return _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(
              name: normalizedName,
              sortOrder: Value(nextOrder),
            ),
          );
    }

    final updated =
        await (_database.update(
          _database.categories,
        )..where((category) => category.id.equals(id))).write(
          CategoriesCompanion(
            name: Value(normalizedName),
            updatedAt: Value(now),
          ),
        );
    if (updated == 0) {
      throw StateError('A categoria não existe mais.');
    }
    return id;
  }

  Future<void> archiveCategory(int id) async {
    await setCategoryArchived(id, true);
  }

  Future<void> setCategoryArchived(int id, bool archived) async {
    await (_database.update(
      _database.categories,
    )..where((category) => category.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> hasProductsInCategory(int id) {
    return _hasProductsInCategory(id);
  }

  Future<CategoryDeletionResult> deleteCategoryIfUnused(int id) {
    return _database.transaction(() async {
      final category = await (_database.select(
        _database.categories,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (category == null) {
        return CategoryDeletionResult.notFound;
      }
      if (await _hasProductsInCategory(id)) {
        return CategoryDeletionResult.hasProducts;
      }

      await (_database.delete(
        _database.subcategories,
      )..where((row) => row.categoryId.equals(id))).go();
      await (_database.delete(
        _database.categories,
      )..where((row) => row.id.equals(id))).go();
      return CategoryDeletionResult.deleted;
    });
  }

  Future<bool> _hasProductsInCategory(int id) async {
    final subcategoryIds = await (_database.select(
      _database.subcategories,
    )..where((row) => row.categoryId.equals(id))).map((row) => row.id).get();
    final query = _database.selectOnly(_database.products)
      ..addColumns([_database.products.id])
      ..limit(1);
    if (subcategoryIds.isEmpty) {
      query.where(_database.products.categoryId.equals(id));
    } else {
      query.where(
        _database.products.categoryId.equals(id) |
            _database.products.subcategoryId.isIn(subcategoryIds),
      );
    }
    return (await query.get()).isNotEmpty;
  }

  Future<void> reorderCategories(List<int> orderedIds) async {
    final categories =
        await (_database.select(_database.categories)..orderBy([
              (row) => OrderingTerm.asc(row.sortOrder),
              (row) => OrderingTerm.asc(row.name),
            ]))
            .get();
    _validateOrder(orderedIds, categories.map((row) => row.id).toList());

    await _database.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_database.update(
          _database.categories,
        )..where((row) => row.id.equals(orderedIds[index]))).write(
          CategoriesCompanion(
            sortOrder: Value(index),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<int> saveSubcategory({
    int? id,
    required int categoryId,
    required String name,
  }) async {
    final normalizedName = _requiredName(name, maxLength: 100);
    final category = await (_database.select(
      _database.categories,
    )..where((row) => row.id.equals(categoryId))).getSingleOrNull();
    if (category == null || category.isArchived) {
      throw const FormatException(
        'Escolha uma categoria existente e não arquivada.',
      );
    }

    final allSubcategories = await (_database.select(
      _database.subcategories,
    )..where((row) => row.categoryId.equals(categoryId))).get();
    if (allSubcategories.any(
      (subcategory) =>
          subcategory.id != id &&
          subcategory.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw const FormatException(
        'Já existe uma subcategoria com esse nome nessa categoria.',
      );
    }

    final now = DateTime.now();
    if (id == null) {
      final nextOrder = allSubcategories.isEmpty
          ? 0
          : allSubcategories
                    .map((subcategory) => subcategory.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      return _database
          .into(_database.subcategories)
          .insert(
            SubcategoriesCompanion.insert(
              categoryId: categoryId,
              name: normalizedName,
              sortOrder: Value(nextOrder),
            ),
          );
    }

    final updated =
        await (_database.update(
          _database.subcategories,
        )..where((subcategory) => subcategory.id.equals(id))).write(
          SubcategoriesCompanion(
            categoryId: Value(categoryId),
            name: Value(normalizedName),
            updatedAt: Value(now),
          ),
        );
    if (updated == 0) {
      throw StateError('A subcategoria não existe mais.');
    }
    return id;
  }

  Future<void> archiveSubcategory(int id) async {
    await setSubcategoryArchived(id, true);
  }

  Future<void> setSubcategoryArchived(int id, bool archived) async {
    await (_database.update(
      _database.subcategories,
    )..where((subcategory) => subcategory.id.equals(id))).write(
      SubcategoriesCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> reorderSubcategories(
    int categoryId,
    List<int> orderedIds,
  ) async {
    final subcategories =
        await (_database.select(_database.subcategories)
              ..where((row) => row.categoryId.equals(categoryId))
              ..orderBy([
                (row) => OrderingTerm.asc(row.sortOrder),
                (row) => OrderingTerm.asc(row.name),
              ]))
            .get();
    _validateOrder(orderedIds, subcategories.map((row) => row.id).toList());

    await _database.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_database.update(
          _database.subcategories,
        )..where((row) => row.id.equals(orderedIds[index]))).write(
          SubcategoriesCompanion(
            sortOrder: Value(index),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<int> saveProduct({
    int? id,
    required String name,
    int? categoryId,
    int? subcategoryId,
    required MeasurementMode measurementMode,
    required bool needsCategoryReview,
    String? description,
  }) async {
    final normalizedName = _requiredName(name, maxLength: 160);
    Product? existingProduct;
    if (id != null) {
      existingProduct = await (_database.select(
        _database.products,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (existingProduct == null) {
        throw StateError('O produto não existe mais.');
      }
    }
    if (categoryId == null && subcategoryId != null) {
      throw const FormatException(
        'Uma subcategoria precisa pertencer a uma categoria.',
      );
    }
    if (categoryId != null) {
      final category = await (_database.select(
        _database.categories,
      )..where((row) => row.id.equals(categoryId))).getSingleOrNull();
      if (category == null) {
        throw const FormatException('A categoria selecionada não existe.');
      }
    }
    if (subcategoryId != null) {
      final subcategory = await (_database.select(
        _database.subcategories,
      )..where((row) => row.id.equals(subcategoryId))).getSingleOrNull();
      if (subcategory == null || subcategory.categoryId != categoryId) {
        throw const FormatException(
          'A subcategoria não pertence à categoria selecionada.',
        );
      }
    }

    final actor = await _actor();
    final now = DateTime.now();
    if (id == null) {
      return _database
          .into(_database.products)
          .insert(
            ProductsCompanion.insert(
              name: normalizedName,
              categoryId: Value(categoryId),
              subcategoryId: Value(subcategoryId),
              measurementMode: Value(measurementMode.name),
              needsCategoryReview: Value(needsCategoryReview),
              description: Value(_optionalText(description)),
              syncId: Value(CollaborationMetadata.newSyncId('product')),
              logicalKey: Value(
                CollaborationMetadata.productLogicalKey(
                  name: normalizedName,
                  measurementMode: measurementMode.name,
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

    final existing = existingProduct!;
    final values = ProductsCompanion(
      name: Value(normalizedName),
      categoryId: Value(categoryId),
      subcategoryId: Value(subcategoryId),
      measurementMode: Value(measurementMode.name),
      needsCategoryReview: Value(needsCategoryReview),
      description: Value(_optionalText(description)),
      logicalKey: Value(
        CollaborationMetadata.productLogicalKey(
          name: normalizedName,
          measurementMode: measurementMode.name,
        ),
      ),
      reviewState: Value(
        actor.role == CollaborationRole.member
            ? CollaborationMetadata.pendingReview
            : CollaborationMetadata.approved,
      ),
      syncRevision: Value(existing.syncRevision + 1),
      updatedAt: Value(now),
    );

    final updated = await (_database.update(
      _database.products,
    )..where((row) => row.id.equals(id))).write(values);
    if (updated == 0) {
      throw StateError('O produto não existe mais.');
    }
    return id;
  }

  Future<void> archiveProduct(int id) async {
    await setProductArchived(id, true);
  }

  Future<void> setProductArchived(int id, bool archived) async {
    await (_database.update(
      _database.products,
    )..where((product) => product.id.equals(id))).write(
      ProductsCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<ProductDeletionResult> checkProductDeletion(int id) {
    return _productDeletionStatus(id);
  }

  Future<ProductDeletionResult> deleteProductIfUnused(int id) {
    return _database.transaction(() async {
      final status = await _productDeletionStatus(id);
      if (status != ProductDeletionResult.ready) {
        return status;
      }

      final now = DateTime.now();
      await (_database.update(_database.plannedItems)..where(
            (row) => row.productId.equals(id) & row.isRemoved.equals(true),
          ))
          .write(
            PlannedItemsCompanion(
              deletedAt: Value(now),
              syncRevision: const Value(1),
              updatedAt: Value(now),
            ),
          );
      final product = await (_database.select(
        _database.products,
      )..where((row) => row.id.equals(id))).getSingle();
      await (_database.update(
        _database.products,
      )..where((row) => row.id.equals(id))).write(
        ProductsCompanion(
          isArchived: const Value(true),
          deletedAt: Value(now),
          syncRevision: Value(product.syncRevision + 1),
          updatedAt: Value(now),
        ),
      );
      return ProductDeletionResult.deleted;
    });
  }

  Future<ProductDeletionResult> _productDeletionStatus(int id) async {
    final product = await (_database.select(
      _database.products,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (product == null || product.deletedAt != null) {
      return ProductDeletionResult.notFound;
    }

    final purchaseLines = await (_database.select(
      _database.purchaseLines,
    )..where((row) => row.productId.equals(id))).get();
    final tripStatusById = <int, String>{};
    if (purchaseLines.isNotEmpty) {
      final trips =
          await (_database.select(_database.shoppingTrips)..where(
                (row) => row.id.isIn(purchaseLines.map((line) => line.tripId)),
              ))
              .get();
      tripStatusById.addEntries(
        trips.map((trip) => MapEntry(trip.id, trip.status)),
      );
      if (purchaseLines.any(
        (line) => tripStatusById[line.tripId] == 'completed',
      )) {
        return ProductDeletionResult.hasCompletedPurchases;
      }
    }

    final plannedItems = await (_database.select(
      _database.plannedItems,
    )..where((row) => row.productId.equals(id))).get();
    if (plannedItems.any((item) => !item.isRemoved)) {
      return ProductDeletionResult.hasPlannedItems;
    }

    if (purchaseLines.any(
      (line) => tripStatusById[line.tripId] == 'in_progress',
    )) {
      return ProductDeletionResult.hasInProgressPurchases;
    }
    if (purchaseLines.any(
      (line) => tripStatusById[line.tripId] == 'canceled',
    )) {
      return ProductDeletionResult.hasCanceledPurchases;
    }
    return ProductDeletionResult.ready;
  }

  Future<int> importCatalog(CatalogImport catalog) async {
    final actor = await _actor();
    return _database.transaction(() async {
      const sourceKey = 'catalogo-inicial-v1';
      final previousBatch = await (_database.select(
        _database.importBatches,
      )..where((batch) => batch.sourceKey.equals(sourceKey))).getSingleOrNull();
      if (previousBatch != null) {
        throw const FormatException('O catálogo inicial já foi importado.');
      }

      final categoryRows = await _database.select(_database.categories).get();
      final categoryIds = {
        for (final category in categoryRows)
          category.name.toLowerCase(): category.id,
      };
      final categoryOrder = categoryRows.isEmpty
          ? 0
          : categoryRows
                    .map((category) => category.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      final suggestedNames =
          catalog.items
              .map((item) => item.suggestedCategory)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();

      for (final name in suggestedNames) {
        final key = name.toLowerCase();
        if (categoryIds.containsKey(key)) {
          continue;
        }
        final categoryId = await _database
            .into(_database.categories)
            .insert(
              CategoriesCompanion.insert(
                name: name,
                sortOrder: Value(categoryOrder + categoryIds.length),
              ),
            );
        categoryIds[key] = categoryId;
      }

      final batchId = await _database
          .into(_database.importBatches)
          .insert(
            ImportBatchesCompanion.insert(
              sourceKey: sourceKey,
              sourceName: catalog.source,
              entryCount: catalog.items.length,
            ),
          );

      for (final item in catalog.items) {
        final categoryId = item.suggestedCategory == null
            ? null
            : categoryIds[item.suggestedCategory!.toLowerCase()];
        final productId = await _database
            .into(_database.products)
            .insert(
              ProductsCompanion.insert(
                name: item.name,
                categoryId: Value(categoryId),
                measurementMode: Value(item.measurementMode.name),
                needsCategoryReview: Value(item.needsCategoryReview),
                syncId: Value(CollaborationMetadata.newSyncId('product')),
                logicalKey: Value(
                  CollaborationMetadata.productLogicalKey(
                    name: item.name,
                    measurementMode: item.measurementMode.name,
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
        await _database
            .into(_database.importEntries)
            .insert(
              ImportEntriesCompanion.insert(
                batchId: batchId,
                sourceSheet: item.sourceSheet,
                sourceRow: item.sourceRow,
                sourceNumber: item.sourceNumber,
                sourceName: item.name,
                suggestedCategory: Value(item.suggestedCategory),
                needsCategoryReview: Value(item.needsCategoryReview),
                status: 'imported',
                productId: Value(productId),
              ),
            );
      }

      return catalog.items.length;
    });
  }

  static String _requiredName(String value, {required int maxLength}) {
    final name = value.trim();
    if (name.isEmpty) {
      throw const FormatException('Informe um nome.');
    }
    if (name.length > maxLength) {
      throw FormatException('Use no máximo $maxLength caracteres.');
    }
    return name;
  }

  static String? _optionalText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static void _validateOrder(List<int> requested, List<int> current) {
    if (requested.length != current.length ||
        requested.toSet().length != requested.length ||
        !requested.toSet().containsAll(current)) {
      throw const FormatException(
        'A ordenação precisa conter todos os itens atuais uma única vez.',
      );
    }
  }
}
