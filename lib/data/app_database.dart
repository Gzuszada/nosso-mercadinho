import 'package:drift/drift.dart';
import 'package:mercado/data/database_connection.dart';

part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Subcategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get subcategoryId => integer().nullable().references(
    Subcategories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get measurementMode =>
      text().withDefault(const Constant('pending'))();
  BoolColumn get needsCategoryReview =>
      boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();
  TextColumn get logicalKey => text().nullable()();
  TextColumn get authorUid => text().nullable()();
  TextColumn get authorName => text().nullable()();
  TextColumn get reviewState =>
      text().withDefault(const Constant('approved'))();
  TextColumn get reviewedByUid => text().nullable()();
  TextColumn get reviewedByName => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncRevision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ImportBatch')
class ImportBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceKey => text().unique()();
  TextColumn get sourceName => text()();
  IntColumn get entryCount => integer()();
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();
}

class ImportEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get batchId =>
      integer().references(ImportBatches, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceSheet => text()();
  IntColumn get sourceRow => integer()();
  IntColumn get sourceNumber => integer()();
  TextColumn get sourceName => text()();
  TextColumn get suggestedCategory => text().nullable()();
  BoolColumn get needsCategoryReview =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => text()();
  IntColumn get productId => integer().nullable().references(
    Products,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {batchId, sourceSheet, sourceRow},
  ];
}

class ShoppingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get monthKey => text().withLength(min: 7, max: 7)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get syncId => text().nullable()();
  TextColumn get logicalKey => text().nullable()();
  TextColumn get authorUid => text().nullable()();
  TextColumn get authorName => text().nullable()();
  TextColumn get reviewState =>
      text().withDefault(const Constant('approved'))();
  TextColumn get reviewedByUid => text().nullable()();
  TextColumn get reviewedByName => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncRevision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PlannedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(ShoppingPlans, #id, onDelete: KeyAction.restrict)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  TextColumn get measurementMode => text()();
  IntColumn get quantity => integer()();
  BoolColumn get isRemoved => boolean().withDefault(const Constant(false))();
  IntColumn get estimatePriceNumeratorCents => integer().nullable()();
  IntColumn get estimateQuantityDenominator => integer().nullable()();
  TextColumn get estimateSource => text().nullable()();
  TextColumn get estimateReferenceDate => text().nullable()();
  IntColumn get estimateReferenceTripId => integer().nullable().references(
    ShoppingTrips,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get syncId => text().nullable()();
  TextColumn get logicalKey => text().nullable()();
  TextColumn get authorUid => text().nullable()();
  TextColumn get authorName => text().nullable()();
  TextColumn get reviewState =>
      text().withDefault(const Constant('approved'))();
  TextColumn get reviewedByUid => text().nullable()();
  TextColumn get reviewedByName => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncRevision => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ShoppingTrips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().nullable().references(
    ShoppingPlans,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get originPlanNameSnapshot => text().nullable()();
  TextColumn get purchaseDate => text().withLength(min: 10, max: 10)();
  TextColumn get marketName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('in_progress'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class PurchaseLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId =>
      integer().references(ShoppingTrips, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get plannedItemId => integer().nullable().references(
    PlannedItems,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get measurementMode => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPriceCents => integer().nullable()();
  IntColumn get totalCents => integer().nullable()();
  BoolColumn get isLabelTotal => boolean().withDefault(const Constant(false))();
  TextColumn get status =>
      text().withDefault(const Constant('pending_price'))();
  TextColumn get productNameSnapshot => text().nullable()();
  TextColumn get categoryNameSnapshot => text().nullable()();
  TextColumn get subcategoryNameSnapshot => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class AppPreferences extends Table {
  IntColumn get id => integer()();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CloudSyncSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get householdId => text().nullable()();
  IntColumn get remoteRevision => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncedHash => text().nullable()();

  /// Last owner UID confirmed by the backend. It lets a signed-in member
  /// remain conservative (pending review) while temporarily offline.
  TextColumn get householdOwnerUid => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Categories,
    Subcategories,
    Products,
    ImportBatches,
    ImportEntries,
    ShoppingPlans,
    PlannedItems,
    ShoppingTrips,
    PurchaseLines,
    AppPreferences,
    CloudSyncSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openAppDatabase());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(shoppingPlans);
        await migrator.createTable(plannedItems);
        await migrator.createTable(shoppingTrips);
        await migrator.createTable(purchaseLines);
      } else if (from < 3) {
        await migrator.addColumn(
          plannedItems,
          plannedItems.estimatePriceNumeratorCents,
        );
        await migrator.addColumn(
          plannedItems,
          plannedItems.estimateQuantityDenominator,
        );
        await migrator.addColumn(plannedItems, plannedItems.estimateSource);
        await migrator.addColumn(
          plannedItems,
          plannedItems.estimateReferenceDate,
        );
        await migrator.addColumn(
          plannedItems,
          plannedItems.estimateReferenceTripId,
        );
      }
      if (from < 4) {
        if (from >= 2) {
          await migrator.addColumn(
            shoppingTrips,
            shoppingTrips.originPlanNameSnapshot,
          );
          await customStatement('''
            UPDATE shopping_trips
            SET origin_plan_name_snapshot = (
              SELECT name FROM shopping_plans
              WHERE shopping_plans.id = shopping_trips.plan_id
            )
            WHERE plan_id IS NOT NULL
          ''');
        }
        await migrator.createTable(appPreferences);
      }
      if (from >= 2 && from < 6) {
        await customStatement(
          'ALTER TABLE purchase_lines '
          'ADD COLUMN is_label_total INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (from < 7) {
        await migrator.createTable(cloudSyncSettings);
      }
      if (from < 8) {
        await _ensureCollaborationColumns();

        // Existing rows receive deterministic IDs so an upgrade does not
        // manufacture a different identity on every device.
        await customStatement(
          "UPDATE products SET sync_id = 'legacy:product:' || id "
          'WHERE sync_id IS NULL',
        );
        await customStatement(
          "UPDATE products SET logical_key = 'product:' || lower(trim(name)) || ':' || lower(measurement_mode) "
          'WHERE logical_key IS NULL',
        );
        await customStatement(
          "UPDATE shopping_plans SET sync_id = 'legacy:plan:' || id "
          'WHERE sync_id IS NULL',
        );
        await customStatement(
          "UPDATE shopping_plans SET logical_key = 'plan:' || month_key || ':' || lower(trim(name)) "
          'WHERE logical_key IS NULL',
        );
        await customStatement(
          "UPDATE planned_items SET sync_id = 'legacy:planned-item:' || id "
          'WHERE sync_id IS NULL',
        );
        await customStatement('''UPDATE planned_items SET logical_key =
            'planned-item:' || (
              SELECT sync_id FROM shopping_plans
              WHERE shopping_plans.id = planned_items.plan_id
            ) || ':' || (
              SELECT sync_id FROM products
              WHERE products.id = planned_items.product_id
            )
            WHERE logical_key IS NULL''');
      }
      if (from < 9) {
        await _ensureCloudSyncOwnerColumn();
      }
    },
  );

  Future<void> _ensureCloudSyncOwnerColumn() async {
    final rows = await customSelect(
      'PRAGMA table_info(cloud_sync_settings)',
      readsFrom: {},
    ).get();
    final existing = rows.map((row) => row.read<String>('name')).toSet();
    if (!existing.contains('household_owner_uid')) {
      await customStatement(
        'ALTER TABLE cloud_sync_settings ADD COLUMN household_owner_uid TEXT',
      );
    }
  }

  Future<void> _ensureCollaborationColumns() async {
    const definitions = <String, List<String>>{
      'products': [
        'sync_id TEXT',
        'logical_key TEXT',
        'author_uid TEXT',
        'author_name TEXT',
        "review_state TEXT NOT NULL DEFAULT 'approved'",
        'reviewed_by_uid TEXT',
        'reviewed_by_name TEXT',
        'reviewed_at INTEGER',
        'deleted_at INTEGER',
        'sync_revision INTEGER NOT NULL DEFAULT 0',
      ],
      'shopping_plans': [
        'sync_id TEXT',
        'logical_key TEXT',
        'author_uid TEXT',
        'author_name TEXT',
        "review_state TEXT NOT NULL DEFAULT 'approved'",
        'reviewed_by_uid TEXT',
        'reviewed_by_name TEXT',
        'reviewed_at INTEGER',
        'deleted_at INTEGER',
        'sync_revision INTEGER NOT NULL DEFAULT 0',
      ],
      'planned_items': [
        'sync_id TEXT',
        'logical_key TEXT',
        'author_uid TEXT',
        'author_name TEXT',
        "review_state TEXT NOT NULL DEFAULT 'approved'",
        'reviewed_by_uid TEXT',
        'reviewed_by_name TEXT',
        'reviewed_at INTEGER',
        'deleted_at INTEGER',
        'sync_revision INTEGER NOT NULL DEFAULT 0',
      ],
    };
    for (final entry in definitions.entries) {
      final rows = await customSelect(
        'PRAGMA table_info(${entry.key})',
        readsFrom: {},
      ).get();
      final existing = rows.map((row) => row.read<String>('name')).toSet();
      for (final definition in entry.value) {
        final name = definition.split(' ').first;
        if (existing.contains(name)) continue;
        await customStatement(
          'ALTER TABLE ${entry.key} ADD COLUMN $definition',
        );
      }
    }
  }

  Stream<List<Category>> watchCategories() {
    return (select(categories)..orderBy([
          (table) => OrderingTerm.asc(table.sortOrder),
          (table) => OrderingTerm.asc(table.name),
        ]))
        .watch();
  }

  Stream<List<Subcategory>> watchSubcategories() {
    return (select(subcategories)..orderBy([
          (table) => OrderingTerm.asc(table.sortOrder),
          (table) => OrderingTerm.asc(table.name),
        ]))
        .watch();
  }

  Stream<List<Product>> watchProducts() {
    return (select(products)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }
}
