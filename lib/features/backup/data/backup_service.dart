import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../../cloud/domain/collaboration.dart';
import '../../shopping/domain/shopping_calculations.dart';

const _backupAppVersion = '1.0.0+7';

class BackupService {
  const BackupService(this._database);

  final AppDatabase _database;

  void validateBackup(String contents) {
    _validatedPayload(contents);
  }

  Future<String> createBackup({DateTime? exportedAt}) {
    return _database.transaction(() async {
      final categories = await _database.select(_database.categories).get();
      final subcategories = await _database
          .select(_database.subcategories)
          .get();
      final products = await _database.select(_database.products).get();
      final batches = await _database.select(_database.importBatches).get();
      final entries = await _database.select(_database.importEntries).get();
      final plans = await _database.select(_database.shoppingPlans).get();
      final plannedItems = await _database.select(_database.plannedItems).get();
      final trips = await _database.select(_database.shoppingTrips).get();
      final purchaseLines = await _database
          .select(_database.purchaseLines)
          .get();
      final productSyncIds = {
        for (final row in products)
          row.id: row.syncId ?? 'legacy:product:${row.id}',
      };
      final planSyncIds = {
        for (final row in plans) row.id: row.syncId ?? 'legacy:plan:${row.id}',
      };
      final plannedItemSyncIds = {
        for (final row in plannedItems)
          row.id: row.syncId ?? 'legacy:planned-item:${row.id}',
      };

      return const JsonEncoder.withIndent('  ').convert({
        'formatVersion': 7,
        'appVersion': _backupAppVersion,
        'schemaVersion': _database.schemaVersion,
        'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
        'currency': 'BRL',
        'categories': categories.map(_categoryToJson).toList(),
        'subcategories': subcategories.map(_subcategoryToJson).toList(),
        'products': products.map(_productToJson).toList(),
        'importBatches': batches.map(_batchToJson).toList(),
        'importEntries': entries
            .map((row) => _entryToJson(row, productSyncIds[row.productId]))
            .toList(),
        'shoppingPlans': plans.map(_planToJson).toList(),
        'plannedItems': plannedItems
            .map(
              (row) => _plannedItemToJson(
                row,
                planSyncIds[row.planId],
                productSyncIds[row.productId],
              ),
            )
            .toList(),
        'shoppingTrips': trips.map(_tripToJson).toList(),
        'purchaseLines': purchaseLines
            .map(
              (row) => _purchaseLineToJson(
                row,
                productSyncIds[row.productId],
                row.plannedItemId == null
                    ? null
                    : plannedItemSyncIds[row.plannedItemId],
              ),
            )
            .toList(),
      });
    });
  }

  Future<void> restoreBackup(String contents) async {
    final payload = _validatedPayload(contents);
    await restoreValidatedPayload(payload);
  }

  Future<void> restoreValidatedPayload(Map<String, dynamic> payload) async {
    final categories = payload['categories']!;
    final subcategories = payload['subcategories']!;
    final products = payload['products']!;
    final batches = payload['importBatches']!;
    final entries = payload['importEntries']!;
    final plans = payload['shoppingPlans']!;
    final plannedItems = payload['plannedItems']!;
    final trips = payload['shoppingTrips']!;
    final purchaseLines = payload['purchaseLines']!;
    final formatVersion = payload['formatVersion']! as int;

    await _database.transaction(() async {
      await _database.delete(_database.purchaseLines).go();
      await _database.delete(_database.plannedItems).go();
      await _database.delete(_database.shoppingTrips).go();
      await _database.delete(_database.shoppingPlans).go();
      await _database.delete(_database.importEntries).go();
      await _database.delete(_database.importBatches).go();
      await _database.delete(_database.products).go();
      await _database.delete(_database.subcategories).go();
      await _database.delete(_database.categories).go();

      for (final row in categories) {
        await _database
            .into(_database.categories)
            .insert(
              CategoriesCompanion.insert(
                id: Value(_integer(row, 'id')),
                name: _string(row, 'name'),
                sortOrder: Value(_integer(row, 'sortOrder')),
                isArchived: Value(_boolean(row, 'isArchived')),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
      for (final row in subcategories) {
        await _database
            .into(_database.subcategories)
            .insert(
              SubcategoriesCompanion.insert(
                id: Value(_integer(row, 'id')),
                categoryId: _integer(row, 'categoryId'),
                name: _string(row, 'name'),
                sortOrder: Value(_integer(row, 'sortOrder')),
                isArchived: Value(_boolean(row, 'isArchived')),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
      for (final row in products) {
        await _database
            .into(_database.products)
            .insert(
              ProductsCompanion.insert(
                id: Value(_integer(row, 'id')),
                name: _string(row, 'name'),
                categoryId: Value(_nullableInteger(row, 'categoryId')),
                subcategoryId: Value(_nullableInteger(row, 'subcategoryId')),
                measurementMode: Value(_string(row, 'measurementMode')),
                needsCategoryReview: Value(
                  _boolean(row, 'needsCategoryReview'),
                ),
                description: Value(_nullableString(row, 'description')),
                isArchived: Value(_boolean(row, 'isArchived')),
                syncId: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'syncId')
                      : 'legacy:product:${_integer(row, 'id')}',
                ),
                logicalKey: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'logicalKey')
                      : CollaborationMetadata.productLogicalKey(
                          name: _string(row, 'name'),
                          measurementMode: _string(row, 'measurementMode'),
                        ),
                ),
                authorUid: Value(
                  formatVersion >= 7 ? _nullableString(row, 'authorUid') : null,
                ),
                authorName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'authorName')
                      : null,
                ),
                reviewState: Value(
                  formatVersion >= 7
                      ? _string(row, 'reviewState')
                      : CollaborationMetadata.approved,
                ),
                reviewedByUid: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByUid')
                      : null,
                ),
                reviewedByName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByName')
                      : null,
                ),
                reviewedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'reviewedAt') : null,
                ),
                deletedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'deletedAt') : null,
                ),
                syncRevision: Value(
                  formatVersion >= 7 ? _integer(row, 'syncRevision') : 0,
                ),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
      for (final row in batches) {
        await _database
            .into(_database.importBatches)
            .insert(
              ImportBatchesCompanion.insert(
                id: Value(_integer(row, 'id')),
                sourceKey: _string(row, 'sourceKey'),
                sourceName: _string(row, 'sourceName'),
                entryCount: _integer(row, 'entryCount'),
                importedAt: Value(_date(row, 'importedAt')),
              ),
            );
      }
      for (final row in entries) {
        await _database
            .into(_database.importEntries)
            .insert(
              ImportEntriesCompanion.insert(
                id: Value(_integer(row, 'id')),
                batchId: _integer(row, 'batchId'),
                sourceSheet: _string(row, 'sourceSheet'),
                sourceRow: _integer(row, 'sourceRow'),
                sourceNumber: _integer(row, 'sourceNumber'),
                sourceName: _string(row, 'sourceName'),
                suggestedCategory: Value(
                  _nullableString(row, 'suggestedCategory'),
                ),
                needsCategoryReview: Value(
                  _boolean(row, 'needsCategoryReview'),
                ),
                status: _string(row, 'status'),
                productId: Value(_nullableInteger(row, 'productId')),
              ),
            );
      }
      for (final row in plans) {
        await _database
            .into(_database.shoppingPlans)
            .insert(
              ShoppingPlansCompanion.insert(
                id: Value(_integer(row, 'id')),
                monthKey: _string(row, 'monthKey'),
                name: _string(row, 'name'),
                status: Value(_string(row, 'status')),
                syncId: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'syncId')
                      : 'legacy:plan:${_integer(row, 'id')}',
                ),
                logicalKey: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'logicalKey')
                      : CollaborationMetadata.planLogicalKey(
                          monthKey: _string(row, 'monthKey'),
                          name: _string(row, 'name'),
                        ),
                ),
                authorUid: Value(
                  formatVersion >= 7 ? _nullableString(row, 'authorUid') : null,
                ),
                authorName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'authorName')
                      : null,
                ),
                reviewState: Value(
                  formatVersion >= 7
                      ? _string(row, 'reviewState')
                      : CollaborationMetadata.approved,
                ),
                reviewedByUid: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByUid')
                      : null,
                ),
                reviewedByName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByName')
                      : null,
                ),
                reviewedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'reviewedAt') : null,
                ),
                deletedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'deletedAt') : null,
                ),
                syncRevision: Value(
                  formatVersion >= 7 ? _integer(row, 'syncRevision') : 0,
                ),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
      final planNamesById = {
        for (final row in plans) _integer(row, 'id'): _string(row, 'name'),
      };
      for (final row in trips) {
        final planId = _nullableInteger(row, 'planId');
        await _database
            .into(_database.shoppingTrips)
            .insert(
              ShoppingTripsCompanion.insert(
                id: Value(_integer(row, 'id')),
                planId: Value(planId),
                originPlanNameSnapshot: Value(
                  _nullableString(row, 'originPlanNameSnapshot') ??
                      (planId == null ? null : planNamesById[planId]),
                ),
                purchaseDate: _string(row, 'purchaseDate'),
                marketName: Value(_nullableString(row, 'marketName')),
                status: Value(_string(row, 'status')),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
                completedAt: Value(_nullableDate(row, 'completedAt')),
              ),
            );
      }
      for (final row in plannedItems) {
        await _database
            .into(_database.plannedItems)
            .insert(
              PlannedItemsCompanion.insert(
                id: Value(_integer(row, 'id')),
                planId: _integer(row, 'planId'),
                productId: _integer(row, 'productId'),
                measurementMode: _string(row, 'measurementMode'),
                quantity: _integer(row, 'quantity'),
                isRemoved: Value(_boolean(row, 'isRemoved')),
                estimatePriceNumeratorCents: Value(
                  _nullableInteger(row, 'estimatePriceNumeratorCents'),
                ),
                estimateQuantityDenominator: Value(
                  _nullableInteger(row, 'estimateQuantityDenominator'),
                ),
                estimateSource: Value(_nullableString(row, 'estimateSource')),
                estimateReferenceDate: Value(
                  _nullableString(row, 'estimateReferenceDate'),
                ),
                estimateReferenceTripId: Value(
                  _nullableInteger(row, 'estimateReferenceTripId'),
                ),
                syncId: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'syncId')
                      : 'legacy:planned-item:${_integer(row, 'id')}',
                ),
                logicalKey: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'logicalKey')
                      : 'planned-item:legacy:${_integer(row, 'planId')}:'
                            '${_integer(row, 'productId')}',
                ),
                authorUid: Value(
                  formatVersion >= 7 ? _nullableString(row, 'authorUid') : null,
                ),
                authorName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'authorName')
                      : null,
                ),
                reviewState: Value(
                  formatVersion >= 7
                      ? _string(row, 'reviewState')
                      : CollaborationMetadata.approved,
                ),
                reviewedByUid: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByUid')
                      : null,
                ),
                reviewedByName: Value(
                  formatVersion >= 7
                      ? _nullableString(row, 'reviewedByName')
                      : null,
                ),
                reviewedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'reviewedAt') : null,
                ),
                deletedAt: Value(
                  formatVersion >= 7 ? _nullableDate(row, 'deletedAt') : null,
                ),
                syncRevision: Value(
                  formatVersion >= 7 ? _integer(row, 'syncRevision') : 0,
                ),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
      for (final row in purchaseLines) {
        await _database
            .into(_database.purchaseLines)
            .insert(
              PurchaseLinesCompanion.insert(
                id: Value(_integer(row, 'id')),
                tripId: _integer(row, 'tripId'),
                productId: _integer(row, 'productId'),
                plannedItemId: Value(_nullableInteger(row, 'plannedItemId')),
                measurementMode: _string(row, 'measurementMode'),
                quantity: _integer(row, 'quantity'),
                unitPriceCents: Value(_nullableInteger(row, 'unitPriceCents')),
                totalCents: Value(_nullableInteger(row, 'totalCents')),
                isLabelTotal: Value(
                  formatVersion >= 6 ? _boolean(row, 'isLabelTotal') : false,
                ),
                status: Value(_string(row, 'status')),
                productNameSnapshot: Value(
                  _nullableString(row, 'productNameSnapshot'),
                ),
                categoryNameSnapshot: Value(
                  _nullableString(row, 'categoryNameSnapshot'),
                ),
                subcategoryNameSnapshot: Value(
                  _nullableString(row, 'subcategoryNameSnapshot'),
                ),
                createdAt: Value(_date(row, 'createdAt')),
                updatedAt: Value(_date(row, 'updatedAt')),
              ),
            );
      }
    });
  }

  Map<String, dynamic> validateAndDecodeBackup(String contents) {
    return _validatedPayload(contents);
  }

  static Map<String, Object?> _categoryToJson(Category row) => {
    'id': row.id,
    'name': row.name,
    'sortOrder': row.sortOrder,
    'isArchived': row.isArchived,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _subcategoryToJson(Subcategory row) => {
    'id': row.id,
    'categoryId': row.categoryId,
    'name': row.name,
    'sortOrder': row.sortOrder,
    'isArchived': row.isArchived,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _productToJson(Product row) => {
    'id': row.id,
    'name': row.name,
    'categoryId': row.categoryId,
    'subcategoryId': row.subcategoryId,
    'measurementMode': row.measurementMode,
    'needsCategoryReview': row.needsCategoryReview,
    'description': row.description,
    'isArchived': row.isArchived,
    'syncId': row.syncId ?? 'legacy:product:${row.id}',
    'logicalKey':
        row.logicalKey ??
        CollaborationMetadata.productLogicalKey(
          name: row.name,
          measurementMode: row.measurementMode,
        ),
    'authorUid': row.authorUid,
    'authorName': row.authorName,
    'reviewState': row.reviewState,
    'reviewedByUid': row.reviewedByUid,
    'reviewedByName': row.reviewedByName,
    'reviewedAt': row.reviewedAt?.toIso8601String(),
    'deletedAt': row.deletedAt?.toIso8601String(),
    'syncRevision': row.syncRevision,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _batchToJson(ImportBatch row) => {
    'id': row.id,
    'sourceKey': row.sourceKey,
    'sourceName': row.sourceName,
    'entryCount': row.entryCount,
    'importedAt': row.importedAt.toIso8601String(),
  };

  static Map<String, Object?> _entryToJson(
    ImportEntry row,
    String? productSyncId,
  ) => {
    'id': row.id,
    'batchId': row.batchId,
    'sourceSheet': row.sourceSheet,
    'sourceRow': row.sourceRow,
    'sourceNumber': row.sourceNumber,
    'sourceName': row.sourceName,
    'suggestedCategory': row.suggestedCategory,
    'needsCategoryReview': row.needsCategoryReview,
    'status': row.status,
    'productId': row.productId,
    'productSyncId': productSyncId,
  };

  static Map<String, Object?> _planToJson(ShoppingPlan row) => {
    'id': row.id,
    'monthKey': row.monthKey,
    'name': row.name,
    'status': row.status,
    'syncId': row.syncId ?? 'legacy:plan:${row.id}',
    'logicalKey':
        row.logicalKey ??
        CollaborationMetadata.planLogicalKey(
          monthKey: row.monthKey,
          name: row.name,
        ),
    'authorUid': row.authorUid,
    'authorName': row.authorName,
    'reviewState': row.reviewState,
    'reviewedByUid': row.reviewedByUid,
    'reviewedByName': row.reviewedByName,
    'reviewedAt': row.reviewedAt?.toIso8601String(),
    'deletedAt': row.deletedAt?.toIso8601String(),
    'syncRevision': row.syncRevision,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _plannedItemToJson(
    PlannedItem row,
    String? planSyncId,
    String? productSyncId,
  ) => {
    'id': row.id,
    'planId': row.planId,
    'productId': row.productId,
    'measurementMode': row.measurementMode,
    'quantity': row.quantity,
    'isRemoved': row.isRemoved,
    'estimatePriceNumeratorCents': row.estimatePriceNumeratorCents,
    'estimateQuantityDenominator': row.estimateQuantityDenominator,
    'estimateSource': row.estimateSource,
    'estimateReferenceDate': row.estimateReferenceDate,
    'estimateReferenceTripId': row.estimateReferenceTripId,
    'planSyncId': planSyncId,
    'productSyncId': productSyncId,
    'syncId': row.syncId ?? 'legacy:planned-item:${row.id}',
    'logicalKey':
        row.logicalKey ?? 'planned-item:legacy:${row.planId}:${row.productId}',
    'authorUid': row.authorUid,
    'authorName': row.authorName,
    'reviewState': row.reviewState,
    'reviewedByUid': row.reviewedByUid,
    'reviewedByName': row.reviewedByName,
    'reviewedAt': row.reviewedAt?.toIso8601String(),
    'deletedAt': row.deletedAt?.toIso8601String(),
    'syncRevision': row.syncRevision,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _tripToJson(ShoppingTrip row) => {
    'id': row.id,
    'planId': row.planId,
    'originPlanNameSnapshot': row.originPlanNameSnapshot,
    'purchaseDate': row.purchaseDate,
    'marketName': row.marketName,
    'status': row.status,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
    'completedAt': row.completedAt?.toIso8601String(),
  };

  static Map<String, Object?> _purchaseLineToJson(
    PurchaseLine row,
    String? productSyncId,
    String? plannedItemSyncId,
  ) => {
    'id': row.id,
    'tripId': row.tripId,
    'productId': row.productId,
    'plannedItemId': row.plannedItemId,
    'productSyncId': productSyncId,
    'plannedItemSyncId': plannedItemSyncId,
    'measurementMode': row.measurementMode,
    'quantity': row.quantity,
    'unitPriceCents': row.unitPriceCents,
    'totalCents': row.totalCents,
    'isLabelTotal': row.isLabelTotal,
    'status': row.status,
    'productNameSnapshot': row.productNameSnapshot,
    'categoryNameSnapshot': row.categoryNameSnapshot,
    'subcategoryNameSnapshot': row.subcategoryNameSnapshot,
    'createdAt': row.createdAt.toIso8601String(),
    'updatedAt': row.updatedAt.toIso8601String(),
  };

  static Map<String, dynamic> _validatedPayload(String contents) {
    if (contents.trim().isEmpty) {
      throw const FormatException(
        'O arquivo selecionado está vazio. Escolha um backup JSON completo.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw FormatException(
        'O arquivo não contém um JSON válido ou está incompleto: '
        '${error.message}',
      );
    }
    final root = _asMap(decoded, 'backup');
    final formatVersion = _integer(root, 'formatVersion');
    final schemaVersion = _integer(root, 'schemaVersion');
    if (!const {1, 2, 3, 4, 5, 6, 7}.contains(formatVersion) ||
        !const {1, 2, 3, 4, 5, 6, 7, 8}.contains(schemaVersion)) {
      throw const FormatException(
        'Versão de backup não compatível com esta versão do aplicativo.',
      );
    }
    _string(root, 'appVersion');
    if (_string(root, 'currency') != 'BRL') {
      throw const FormatException('O backup precisa usar moeda BRL.');
    }
    _date(root, 'exportedAt');

    final categories = _recordList(root, 'categories');
    final subcategories = _recordList(root, 'subcategories');
    final products = _recordList(root, 'products');
    final batches = _recordList(root, 'importBatches');
    final entries = _recordList(root, 'importEntries');
    final plans = formatVersion == 1
        ? <Map<String, Object?>>[]
        : _recordList(root, 'shoppingPlans');
    final plannedItems = formatVersion == 1
        ? <Map<String, Object?>>[]
        : _recordList(root, 'plannedItems');
    final trips = formatVersion == 1
        ? <Map<String, Object?>>[]
        : _recordList(root, 'shoppingTrips');
    final purchaseLines = formatVersion == 1
        ? <Map<String, Object?>>[]
        : _recordList(root, 'purchaseLines');

    final categoryIds = _validateIds(categories, 'categories');
    final subcategoryIds = _validateIds(subcategories, 'subcategories');
    final productIds = _validateIds(products, 'products');
    final batchIds = _validateIds(batches, 'importBatches');
    _validateIds(entries, 'importEntries');

    if (formatVersion >= 7) {
      _validateUniqueSyncIds(products, 'products');
      _validateUniqueSyncIds(plans, 'shoppingPlans');
      _validateUniqueSyncIds(plannedItems, 'plannedItems');
    }

    for (final row in categories) {
      _string(row, 'name');
      _integer(row, 'sortOrder');
      _boolean(row, 'isArchived');
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
    }
    for (final row in subcategories) {
      if (!categoryIds.contains(_integer(row, 'categoryId'))) {
        throw const FormatException(
          'Uma subcategoria referencia uma categoria ausente.',
        );
      }
      _string(row, 'name');
      _integer(row, 'sortOrder');
      _boolean(row, 'isArchived');
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
    }
    for (final row in products) {
      final categoryId = _nullableInteger(row, 'categoryId');
      final subcategoryId = _nullableInteger(row, 'subcategoryId');
      if (categoryId != null && !categoryIds.contains(categoryId)) {
        throw const FormatException(
          'Um produto referencia uma categoria ausente.',
        );
      }
      if (subcategoryId != null && !subcategoryIds.contains(subcategoryId)) {
        throw const FormatException(
          'Um produto referencia uma subcategoria ausente.',
        );
      }
      if (subcategoryId != null) {
        final matchingSubcategory = subcategories.firstWhere(
          (item) => _integer(item, 'id') == subcategoryId,
        );
        if (_integer(matchingSubcategory, 'categoryId') != categoryId) {
          throw const FormatException(
            'A subcategoria do produto não pertence à categoria informada.',
          );
        }
      }
      _string(row, 'name');
      if (!const {
        'pending',
        'unit',
        'package',
        'weight',
      }.contains(_string(row, 'measurementMode'))) {
        throw const FormatException('Forma de compra inválida no backup.');
      }
      _boolean(row, 'needsCategoryReview');
      _nullableString(row, 'description');
      _boolean(row, 'isArchived');
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
      if (formatVersion >= 7) {
        _validateCollaborationMetadata(row);
      }
    }
    for (final row in batches) {
      _string(row, 'sourceKey');
      _string(row, 'sourceName');
      if (_integer(row, 'entryCount') < 0) {
        throw const FormatException('Contagem de importação inválida.');
      }
      _date(row, 'importedAt');
    }
    for (final row in entries) {
      if (!batchIds.contains(_integer(row, 'batchId'))) {
        throw const FormatException(
          'Uma entrada de importação referencia lote ausente.',
        );
      }
      final productId = _nullableInteger(row, 'productId');
      if (productId != null && !productIds.contains(productId)) {
        throw const FormatException(
          'Uma entrada de importação referencia produto ausente.',
        );
      }
      _string(row, 'sourceSheet');
      _integer(row, 'sourceRow');
      _integer(row, 'sourceNumber');
      _string(row, 'sourceName');
      _nullableString(row, 'suggestedCategory');
      _boolean(row, 'needsCategoryReview');
      if (_string(row, 'status') != 'imported') {
        throw const FormatException('Estado de importação inválido.');
      }
    }

    if (formatVersion >= 2) {
      _validateShoppingData(
        plans: plans,
        plannedItems: plannedItems,
        trips: trips,
        purchaseLines: purchaseLines,
        formatVersion: formatVersion,
        productById: {
          for (final product in products) _integer(product, 'id'): product,
        },
      );
    }

    return {
      'categories': categories,
      'subcategories': subcategories,
      'products': products,
      'importBatches': batches,
      'importEntries': entries,
      'shoppingPlans': plans,
      'plannedItems': plannedItems,
      'shoppingTrips': trips,
      'purchaseLines': purchaseLines,
      'formatVersion': formatVersion,
    };
  }

  static void _validateUniqueSyncIds(
    List<Map<String, Object?>> rows,
    String table,
  ) {
    final seen = <String>{};
    for (final row in rows) {
      final syncId = _nullableString(row, 'syncId');
      if (syncId == null) continue;
      if (!seen.add(syncId)) {
        throw FormatException(
          'A tabela "$table" contém o identificador sincronizado duplicado "$syncId".',
        );
      }
    }
  }

  static void _validateShoppingData({
    required List<Map<String, Object?>> plans,
    required List<Map<String, Object?>> plannedItems,
    required List<Map<String, Object?>> trips,
    required List<Map<String, Object?>> purchaseLines,
    required Map<int, Map<String, Object?>> productById,
    required int formatVersion,
  }) {
    final planIds = _validateIds(plans, 'shoppingPlans');
    final plannedItemIds = _validateIds(plannedItems, 'plannedItems');
    final tripIds = _validateIds(trips, 'shoppingTrips');
    _validateIds(purchaseLines, 'purchaseLines');
    final planById = {for (final row in plans) _integer(row, 'id'): row};
    final plannedItemById = {
      for (final item in plannedItems) _integer(item, 'id'): item,
    };
    final tripById = {for (final trip in trips) _integer(trip, 'id'): trip};
    final completedLineCounts = <int, int>{};
    final activeTripPlans = <String>{};

    for (final row in plans) {
      final monthKey = _string(row, 'monthKey');
      if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(monthKey)) {
        throw const FormatException('Mês planejado inválido no backup.');
      }
      _string(row, 'name');
      if (!const {
        'active',
        'open',
        'archived',
        'canceled',
        'completed',
      }.contains(_string(row, 'status'))) {
        throw const FormatException('Estado de lista inválido no backup.');
      }
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
      if (formatVersion >= 7) {
        _validateCollaborationMetadata(row);
      }
    }

    for (final row in plannedItems) {
      final product = productById[_integer(row, 'productId')];
      if (!planIds.contains(_integer(row, 'planId')) || product == null) {
        throw const FormatException(
          'Um item planejado referencia lista ou produto ausente.',
        );
      }
      if (!const {
        'unit',
        'package',
        'weight',
      }.contains(_string(row, 'measurementMode'))) {
        throw const FormatException(
          'Forma de compra inválida em item planejado.',
        );
      }
      if (_integer(row, 'quantity') <= 0) {
        throw const FormatException('Quantidade planejada inválida.');
      }
      _boolean(row, 'isRemoved');
      final estimateNumerator = _nullableInteger(
        row,
        'estimatePriceNumeratorCents',
      );
      final estimateDenominator = _nullableInteger(
        row,
        'estimateQuantityDenominator',
      );
      final estimateSource = _nullableString(row, 'estimateSource');
      final estimateDate = _nullableString(row, 'estimateReferenceDate');
      final estimateTripId = _nullableInteger(row, 'estimateReferenceTripId');
      if (formatVersion >= 3) {
        if (estimateSource == null) {
          if (estimateNumerator != null ||
              estimateDenominator != null ||
              estimateDate != null ||
              estimateTripId != null) {
            throw const FormatException(
              'Fotografia de estimativa incompleta no backup.',
            );
          }
        } else {
          if (!const {'history', 'manual'}.contains(estimateSource) ||
              estimateNumerator == null ||
              estimateNumerator < 0 ||
              estimateDenominator == null ||
              estimateDenominator <= 0 ||
              estimateDate == null ||
              !_isValidCivilDate(estimateDate)) {
            throw const FormatException(
              'Fotografia de estimativa inválida no backup.',
            );
          }
          if (estimateSource == 'history') {
            if (estimateTripId == null || !tripIds.contains(estimateTripId)) {
              throw const FormatException(
                'Referência histórica de estimativa ausente no backup.',
              );
            }
            final referenceTrip = trips.firstWhere(
              (trip) => _integer(trip, 'id') == estimateTripId,
            );
            if (_string(referenceTrip, 'status') != 'completed' ||
                _string(referenceTrip, 'purchaseDate') != estimateDate) {
              throw const FormatException(
                'Data ou estado da referência histórica inválido.',
              );
            }
          } else if (estimateTripId != null ||
              estimateDenominator !=
                  (_string(row, 'measurementMode') == 'weight' ? 1000 : 1)) {
            throw const FormatException(
              'Estimativa manual incompatível com a forma de compra.',
            );
          }
        }
      } else if (estimateNumerator != null ||
          estimateDenominator != null ||
          estimateSource != null ||
          estimateDate != null ||
          estimateTripId != null) {
        throw const FormatException(
          'Backup anterior não pode conter campos de estimativa.',
        );
      }
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
      if (formatVersion >= 7) {
        _validateCollaborationMetadata(row);
      }
    }

    for (final row in trips) {
      final planId = _nullableInteger(row, 'planId');
      if (planId != null && !planIds.contains(planId)) {
        throw const FormatException('Uma compra referencia lista ausente.');
      }
      final purchaseDate = _string(row, 'purchaseDate');
      if (!_isValidCivilDate(purchaseDate)) {
        throw const FormatException('Data civil de compra inválida.');
      }
      _nullableString(row, 'marketName');
      final status = _string(row, 'status');
      if (!const {'in_progress', 'completed', 'canceled'}.contains(status)) {
        throw const FormatException('Estado de compra inválido no backup.');
      }
      if (formatVersion >= 4) {
        final originPlanName = _nullableString(row, 'originPlanNameSnapshot');
        if (planId != null && originPlanName == null) {
          throw const FormatException(
            'Compra ligada a lista sem fotografia da origem.',
          );
        }
      }
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
      final completedAt = _nullableDate(row, 'completedAt');
      if ((status == 'completed') != (completedAt != null)) {
        throw const FormatException(
          'Data de conclusão incompatível com o estado da compra.',
        );
      }
      if (status == 'in_progress') {
        final activePlanKey = planId?.toString() ?? 'no-plan';
        if (!activeTripPlans.add(activePlanKey)) {
          throw const FormatException(
            'Há mais de uma compra ativa para a mesma lista no backup.',
          );
        }
      }
    }

    for (final row in purchaseLines) {
      final tripId = _integer(row, 'tripId');
      final trip = tripById[tripId];
      final productId = _integer(row, 'productId');
      final product = productById[productId];
      if (trip == null || product == null) {
        throw const FormatException(
          'Uma linha de compra referencia compra ou produto ausente.',
        );
      }
      final plannedItemId = _nullableInteger(row, 'plannedItemId');
      if (plannedItemId != null) {
        if (!plannedItemIds.contains(plannedItemId)) {
          throw const FormatException(
            'Uma linha referencia item planejado ausente.',
          );
        }
        final plannedItem = plannedItemById[plannedItemId]!;
        if (_integer(plannedItem, 'productId') != productId ||
            _string(plannedItem, 'measurementMode') !=
                _string(row, 'measurementMode') ||
            _nullableInteger(trip, 'planId') !=
                _integer(plannedItem, 'planId')) {
          throw const FormatException(
            'Vínculo incompatível entre compra e item planejado.',
          );
        }
      }
      final mode = _string(row, 'measurementMode');
      if (!const {'unit', 'package', 'weight'}.contains(mode)) {
        throw const FormatException('Forma de compra inválida na linha.');
      }
      final quantity = _integer(row, 'quantity');
      final unitPriceCents = _nullableInteger(row, 'unitPriceCents');
      final totalCents = _nullableInteger(row, 'totalCents');
      final isLabelTotal = formatVersion >= 6
          ? _boolean(row, 'isLabelTotal')
          : false;
      if (quantity <= 0 ||
          (unitPriceCents != null && unitPriceCents < 0) ||
          (totalCents != null && totalCents < 0)) {
        throw const FormatException('Quantidade ou preço de linha inválido.');
      }
      if (isLabelTotal && mode != 'weight') {
        throw const FormatException(
          'Total de etiqueta em uma linha que não é comprada por peso.',
        );
      }
      final status = _string(row, 'status');
      if (status == 'included') {
        if (unitPriceCents == null || totalCents == null) {
          throw const FormatException('Linha incluída sem preço e total.');
        }
        final measurementMode = switch (mode) {
          'unit' => MeasurementMode.unit,
          'package' => MeasurementMode.package,
          'weight' => MeasurementMode.weight,
          _ => throw const FormatException(
            'Forma de compra inválida na linha.',
          ),
        };
        final expectedTotal = ShoppingCalculations.calculateLineTotalCents(
          mode: measurementMode,
          quantity: quantity,
          unitPriceCents: unitPriceCents,
        );
        if (!isLabelTotal && expectedTotal != totalCents) {
          throw const FormatException(
            'Total de linha inconsistente no backup.',
          );
        }
      } else if (status != 'pending_price' ||
          unitPriceCents != null ||
          totalCents != null ||
          isLabelTotal) {
        throw const FormatException('Estado de preço de linha inválido.');
      }
      if (_string(trip, 'status') == 'completed') {
        if (status != 'included' ||
            _nullableString(row, 'productNameSnapshot') == null) {
          throw const FormatException(
            'Compra concluída com linha sem preço ou descrição histórica.',
          );
        }
        completedLineCounts.update(
          tripId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      } else {
        _nullableString(row, 'productNameSnapshot');
      }
      _nullableString(row, 'categoryNameSnapshot');
      _nullableString(row, 'subcategoryNameSnapshot');
      _date(row, 'createdAt');
      _date(row, 'updatedAt');
    }

    for (final trip in trips) {
      if (_string(trip, 'status') == 'completed' &&
          !completedLineCounts.containsKey(_integer(trip, 'id'))) {
        throw const FormatException('Compra concluída sem linhas válidas.');
      }
    }
    if (formatVersion >= 3) {
      for (final item in plannedItems) {
        if (_nullableString(item, 'estimateSource') != 'history') {
          continue;
        }
        final plan = planById[_integer(item, 'planId')]!;
        final referenceTripId = _integer(item, 'estimateReferenceTripId');
        final referenceDate = _string(item, 'estimateReferenceDate');
        if (referenceDate.compareTo('${_string(plan, 'monthKey')}-01') >= 0) {
          throw const FormatException(
            'Estimativa histórica usa compra no mês planejado ou posterior.',
          );
        }
        final matchingLines = purchaseLines.where(
          (line) =>
              _integer(line, 'tripId') == referenceTripId &&
              _integer(line, 'productId') == _integer(item, 'productId') &&
              _string(line, 'measurementMode') ==
                  _string(item, 'measurementMode') &&
              _string(line, 'status') == 'included',
        );
        final referenceAmount = ShoppingCalculations.sumCents(
          matchingLines.map((line) => _integer(line, 'totalCents')),
        );
        var referenceQuantity = BigInt.zero;
        for (final line in matchingLines) {
          referenceQuantity += BigInt.from(_integer(line, 'quantity'));
        }
        if (referenceAmount != _integer(item, 'estimatePriceNumeratorCents') ||
            referenceQuantity !=
                BigInt.from(_integer(item, 'estimateQuantityDenominator'))) {
          throw const FormatException(
            'Valor fotografado não corresponde à compra de referência.',
          );
        }
      }
    }
  }

  static void _validateCollaborationMetadata(Map<String, Object?> row) {
    _string(row, 'syncId');
    _string(row, 'logicalKey');
    _nullableString(row, 'authorUid');
    _nullableString(row, 'authorName');
    if (!const {
      CollaborationMetadata.pendingReview,
      CollaborationMetadata.approved,
      CollaborationMetadata.rejected,
    }.contains(_string(row, 'reviewState'))) {
      throw const FormatException('Estado de revisão inválido no backup.');
    }
    _nullableString(row, 'reviewedByUid');
    _nullableString(row, 'reviewedByName');
    _nullableDate(row, 'reviewedAt');
    _nullableDate(row, 'deletedAt');
    if (_integer(row, 'syncRevision') < 0) {
      throw const FormatException(
        'Revisão de sincronização inválida no backup.',
      );
    }
  }

  static List<Map<String, Object?>> _recordList(
    Map<String, Object?> root,
    String key,
  ) {
    final value = root[key];
    if (value is! List<Object?>) {
      throw FormatException('A lista "$key" está ausente ou inválida.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        _asMap(value[index], '$key[$index]'),
    ];
  }

  static Set<int> _validateIds(
    List<Map<String, Object?>> records,
    String name,
  ) {
    final ids = <int>{};
    for (final record in records) {
      final id = _integer(record, 'id');
      if (id <= 0 || !ids.add(id)) {
        throw FormatException('Identificador inválido ou duplicado em $name.');
      }
    }
    return ids;
  }

  static Map<String, Object?> _asMap(Object? value, String field) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((key) => key is! String)) {
      throw FormatException('O campo "$field" precisa ser um objeto JSON.');
    }
    return value.map((key, value) => MapEntry(key! as String, value));
  }

  static String _string(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('O campo "$key" está ausente ou vazio.');
    }
    return value;
  }

  static String? _nullableString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value != null && value is! String) {
      throw FormatException('O campo "$key" precisa ser texto ou nulo.');
    }
    return value as String?;
  }

  static int _integer(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! int) {
      throw FormatException('O campo "$key" precisa ser inteiro.');
    }
    return value;
  }

  static int? _nullableInteger(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value != null && value is! int) {
      throw FormatException('O campo "$key" precisa ser inteiro ou nulo.');
    }
    return value as int?;
  }

  static bool _boolean(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! bool) {
      throw FormatException('O campo "$key" precisa ser booleano.');
    }
    return value;
  }

  static DateTime _date(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw FormatException('O campo "$key" precisa ser uma data ISO.');
    }
    final date = DateTime.tryParse(value);
    if (date == null) {
      throw FormatException('O campo "$key" contém uma data inválida.');
    }
    return date;
  }

  static DateTime? _nullableDate(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('O campo "$key" precisa ser data ISO ou nulo.');
    }
    final date = DateTime.tryParse(value);
    if (date == null) {
      throw FormatException('O campo "$key" contém uma data inválida.');
    }
    return date;
  }

  static bool _isValidCivilDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }
}
