import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'mercado',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 7;

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
    },
  );

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
    return (select(
      products,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).watch();
  }
}
