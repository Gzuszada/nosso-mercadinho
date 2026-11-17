import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/cloud/data/cloud_auth_service.dart';
import 'features/cloud/data/cloud_models.dart';
import 'features/cloud/data/cloud_sync_service.dart';
import 'features/settings/data/reset_service.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/shopping/data/shopping_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(databaseProvider)),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final cloudAuthServiceProvider = Provider<CloudAuthService>(
  (ref) => CloudAuthService(),
);

final authStateProvider = StreamProvider<AuthAccount?>(
  (ref) => ref.watch(cloudAuthServiceProvider).authStateChanges,
);

final cloudHouseholdsProvider = FutureProvider<List<CloudHousehold>>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  if (authState.hasError) {
    throw authState.error!;
  }
  final account = authState.asData?.value;
  if (authState.isLoading || account == null) {
    return const [];
  }

  final households = await ref
      .read(cloudAuthServiceProvider)
      .discoverHouseholds();
  if (households.length == 1) {
    await ref
        .read(settingsRepositoryProvider)
        .selectCloudHousehold(households.single.id);
  }
  return households;
});

final selectedCloudHouseholdProvider = FutureProvider<CloudHousehold?>((
  ref,
) async {
  await ref.watch(cloudHouseholdsProvider.future);
  final settings = await ref
      .read(settingsRepositoryProvider)
      .getCloudSyncSettings();
  final selectedId = settings?.householdId;
  if (selectedId == null) {
    return null;
  }
  final households = await ref.watch(cloudHouseholdsProvider.future);
  for (final household in households) {
    if (household.id == selectedId) {
      return household;
    }
  }
  return null;
});

final firebaseInitializationErrorProvider = Provider<String?>((ref) => null);

final cloudSyncServiceProvider = Provider<CloudSyncService>(
  (ref) => CloudSyncService(
    database: ref.watch(databaseProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  ),
);

final resetServiceProvider = Provider<ResetService>(
  (ref) => ResetService(ref.watch(databaseProvider)),
);

final resetPreviewProvider = FutureProvider<ResetPreview>(
  (ref) => ref.watch(resetServiceProvider).getPreview(),
);

final darkModeProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDarkMode(),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(databaseProvider).watchCategories(),
);

final subcategoriesProvider = StreamProvider<List<Subcategory>>(
  (ref) => ref.watch(databaseProvider).watchSubcategories(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(databaseProvider).watchProducts(),
);

final shoppingPlansProvider = StreamProvider<List<ShoppingPlan>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchPlans(),
);

final shoppingPlanProvider = StreamProvider.family<ShoppingPlan?, int>(
  (ref, id) => ref.watch(shoppingRepositoryProvider).watchPlan(id),
);

final plannedItemsProvider = StreamProvider.family<List<PlannedItem>, int>(
  (ref, planId) =>
      ref.watch(shoppingRepositoryProvider).watchPlannedItems(planId),
);

final shoppingTripsProvider = StreamProvider<List<ShoppingTrip>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchTrips(),
);

final shoppingTripProvider = StreamProvider.family<ShoppingTrip?, int>(
  (ref, id) => ref.watch(shoppingRepositoryProvider).watchTrip(id),
);

final purchaseLinesProvider = StreamProvider.family<List<PurchaseLine>, int>(
  (ref, tripId) =>
      ref.watch(shoppingRepositoryProvider).watchPurchaseLines(tripId),
);

final planItemProgressProvider = FutureProvider.family<PlanItemProgress, int>(
  (ref, itemId) =>
      ref.watch(shoppingRepositoryProvider).getPlanItemProgress(itemId),
);

final monthlyHistoryProvider =
    FutureProvider.family<MonthlyHistoryReport, String>((ref, monthKey) {
      ref.watch(shoppingTripsProvider);
      return ref.watch(shoppingRepositoryProvider).getMonthlyHistory(monthKey);
    });

final productPurchaseHistoryProvider =
    FutureProvider.family<ProductPurchaseHistory, (int, DateTime)>((
      ref,
      request,
    ) {
      ref.watch(shoppingTripsProvider);
      ref.watch(productsProvider);
      return ref
          .watch(shoppingRepositoryProvider)
          .getProductPurchaseHistory(productId: request.$1, asOf: request.$2);
    });

final tripProjectionProvider = FutureProvider.family<TripProjection, int>((
  ref,
  tripId,
) {
  ref.watch(shoppingTripsProvider);
  ref.watch(purchaseLinesProvider(tripId));
  final trip = ref.watch(shoppingTripProvider(tripId)).asData?.value;
  if (trip?.planId != null) {
    ref.watch(plannedItemsProvider(trip!.planId!));
  }
  return ref.watch(shoppingRepositoryProvider).getTripProjection(tripId);
});
