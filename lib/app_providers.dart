import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';
import 'data/app_database.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/cloud/data/auto_sync_coordinator.dart';
import 'features/cloud/data/cloud_auth_service.dart';
import 'features/cloud/data/cloud_models.dart';
import 'features/cloud/data/cloud_sync_service.dart';
import 'features/cloud/data/pilot_household_administration_service.dart';
import 'features/cloud/data/sync_v2_client.dart';
import 'features/cloud/domain/collaboration.dart';
import 'features/cloud/domain/collaboration_service.dart';
import 'features/settings/data/reset_service.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/shopping/data/shopping_repository.dart';

Future<CollaborationActor?> _resolveCollaborationActor(Ref ref) async {
  final settings = await ref
      .read(settingsRepositoryProvider)
      .getCloudSyncSettings();
  final householdId = settings?.householdId;
  if (householdId == null) {
    // No household was selected: this is ordinary local/offline use.
    return null;
  }

  try {
    final user = ref.read(cloudAuthServiceProvider).currentUser;
    if (user == null) {
      return const CollaborationActor(
        uid: 'offline:unknown',
        displayName: 'Membro',
        role: CollaborationRole.member,
      );
    }

    var ownerUid = settings?.householdOwnerUid;
    try {
      final confirmedOwnerUid = await ref
          .read(cloudAuthServiceProvider)
          .householdOwnerUid(householdId);
      if (confirmedOwnerUid != null) {
        ownerUid = confirmedOwnerUid;
        await ref
            .read(settingsRepositoryProvider)
            .cacheHouseholdOwner(householdId, confirmedOwnerUid);
      }
    } on Object {
      // Keep using the last confirmed owner. If it is unknown, the actor is
      // treated as a member so new items remain pending instead of being
      // silently approved while offline.
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : CloudAuthService.defaultDisplayName(user.email);
    if (ownerUid == null) {
      return CollaborationActor(
        uid: user.uid,
        displayName: displayName,
        role: CollaborationRole.member,
      );
    }
    return CollaborationActor(
      uid: user.uid,
      displayName: displayName,
      role: ownerUid == user.uid
          ? CollaborationRole.owner
          : CollaborationRole.member,
    );
  } on Object {
    // Firebase may be unavailable in a local-only build or in an offline
    // process. In a selected household this must remain conservative.
    return const CollaborationActor(
      uid: 'offline:unknown',
      displayName: 'Membro',
      role: CollaborationRole.member,
    );
  }
}

final collaborationActorProvider = FutureProvider<CollaborationActor?>(
  (ref) => _resolveCollaborationActor(ref),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    ref.watch(databaseProvider),
    actorResolver: () => _resolveCollaborationActor(ref),
  ),
);

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(
    ref.watch(databaseProvider),
    actorResolver: () => _resolveCollaborationActor(ref),
  ),
);

final collaborationServiceProvider = Provider<CollaborationService>(
  (ref) => CollaborationService(
    ref.watch(databaseProvider),
    actorResolver: () => _resolveCollaborationActor(ref),
  ),
);

final pendingPlanReviewsProvider = StreamProvider<List<PendingPlanReview>>(
  (ref) => ref.watch(collaborationServiceProvider).watchPendingPlanReviews(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final cloudAuthServiceProvider = Provider<CloudAuthService>(
  (ref) => CloudAuthService(),
);

final pilotHouseholdAdministrationServiceProvider =
    Provider<PilotHouseholdAdministrationService>(
      (ref) => PilotHouseholdAdministrationService(),
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

  await ref.read(cloudAuthServiceProvider).ensureDisplayName();
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
    syncV2Client: isPilotBuild ? SyncV2Client() : null,
  ),
);

final autoSyncCoordinatorProvider = Provider<AutoSyncCoordinator>((ref) {
  final auth = ref.watch(cloudAuthServiceProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final sync = ref.watch(cloudSyncServiceProvider);
  return AutoSyncCoordinator(
    hasNetwork: AutoSyncCoordinator.probeNetworkWithHttp,
    hasValidSession: auth.hasValidSession,
    selectedHouseholdId: () async =>
        (await settings.getCloudSyncSettings())?.householdId,
    inspectStatus: sync.inspectStatus,
    synchronize: (householdId) =>
        sync.synchronize(householdId: householdId, conservative: true),
  );
});

final publishedPendingPlanReviewsProvider =
    FutureProvider<List<PlanReviewItem>>((ref) async {
      final household = await ref.watch(selectedCloudHouseholdProvider.future);
      if (household == null) return const [];
      return ref
          .watch(cloudSyncServiceProvider)
          .readPublishedPendingPlanReviews(householdId: household.id);
    });

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
