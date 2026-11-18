import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';

void main() {
  group('sincronização completa da casa', () {
    late AppDatabase databaseA;
    late AppDatabase databaseB;
    late SettingsRepository settingsA;
    late SettingsRepository settingsB;
    late FakeFirebaseFirestore firestore;
    late CloudSyncService serviceA;
    late CloudSyncService serviceB;
    late bool previousWarning;

    setUpAll(() {
      previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    tearDownAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
    });

    setUp(() async {
      databaseA = AppDatabase(NativeDatabase.memory());
      databaseB = AppDatabase(NativeDatabase.memory());
      settingsA = SettingsRepository(databaseA);
      settingsB = SettingsRepository(databaseB);
      firestore = FakeFirebaseFirestore();
      serviceA = CloudSyncService(
        database: databaseA,
        settingsRepository: settingsA,
        firestore: firestore,
      );
      serviceB = CloudSyncService(
        database: databaseB,
        settingsRepository: settingsB,
        firestore: firestore,
      );
      await settingsA.selectCloudHousehold('casa');
      await settingsB.selectCloudHousehold('casa');
      for (final area in CloudSyncConflictArea.values) {
        await firestore
            .collection('households')
            .doc('casa')
            .collection('tables')
            .doc(area.name)
            .set({
              'payload': {
                for (final key in CloudSyncService.areaKeys(area))
                  key: <Object?>[],
                'formatVersion': 6,
              },
              'hash': '',
              'updatedAt': DateTime.now(),
            });
      }
    });

    tearDown(() async {
      await databaseA.close();
      await databaseB.close();
    });

    test('recupera todas as áreas da casa no primeiro vínculo', () async {
      await databaseA
          .into(databaseA.categories)
          .insert(CategoriesCompanion.insert(name: 'Bebidas'));
      await databaseA
          .into(databaseA.subcategories)
          .insert(
            SubcategoriesCompanion.insert(categoryId: 1, name: 'Refrigerantes'),
          );
      await databaseA
          .into(databaseA.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Água',
              categoryId: const Value<int?>(1),
              subcategoryId: const Value<int?>(1),
              measurementMode: const Value('unit'),
            ),
          );
      await databaseA
          .into(databaseA.shoppingPlans)
          .insert(
            ShoppingPlansCompanion.insert(monthKey: '2026-11', name: 'Lista'),
          );
      await databaseA
          .into(databaseA.shoppingTrips)
          .insert(ShoppingTripsCompanion.insert(purchaseDate: '2026-11-17'));

      await serviceA.synchronize(householdId: 'casa');
      expect(
        (await serviceA.inspectStatus('casa')).needsSynchronization,
        isFalse,
      );

      await serviceB.synchronize(
        householdId: 'casa',
        resolutions: {
          CloudSyncConflictArea.catalog: await _remoteArea(
            firestore,
            CloudSyncConflictArea.catalog,
          ),
        },
      );

      expect(await databaseB.select(databaseB.categories).get(), hasLength(1));
      expect(
        await databaseB.select(databaseB.subcategories).get(),
        hasLength(1),
      );
      expect(await databaseB.select(databaseB.products).get(), hasLength(1));
      expect(
        await databaseB.select(databaseB.shoppingPlans).get(),
        hasLength(1),
      );
      expect(
        await databaseB.select(databaseB.shoppingTrips).get(),
        hasLength(1),
      );
      expect(
        (await serviceB.inspectStatus('casa')).needsSynchronization,
        isFalse,
      );
    });

    test('relata divergência por área sem alterar dados', () async {
      await databaseA
          .into(databaseA.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Leite',
              measurementMode: const Value('unit'),
            ),
          );
      await databaseB
          .into(databaseB.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Café',
              measurementMode: const Value('unit'),
            ),
          );

      final status = await serviceA.inspectStatus('casa');
      final catalog = status.areas[CloudSyncConflictArea.catalog]!;
      expect(catalog.state, CloudSyncAreaState.divergent);
      expect(catalog.localCounts.values['products'], 1);
      expect(catalog.remoteCounts.values['products'], 0);
      expect(catalog.needsSynchronization, isTrue);
    });

    test('propaga exclusão local para os outros dispositivos', () async {
      await databaseA
          .into(databaseA.products)
          .insert(
            ProductsCompanion.insert(
              name: 'Leite',
              measurementMode: const Value('unit'),
            ),
          );
      await serviceA.synchronize(householdId: 'casa');
      await serviceB.synchronize(
        householdId: 'casa',
        resolutions: {
          CloudSyncConflictArea.catalog: await _remoteArea(
            firestore,
            CloudSyncConflictArea.catalog,
          ),
        },
      );
      expect(await databaseB.select(databaseB.products).get(), hasLength(1));

      await databaseA.delete(databaseA.products).go();
      await serviceA.publishLocalArea(
        householdId: 'casa',
        area: CloudSyncConflictArea.catalog,
      );

      await serviceB.synchronize(householdId: 'casa');
      expect(await databaseB.select(databaseB.products).get(), isEmpty);
      expect(
        (await serviceB.inspectStatus('casa')).needsSynchronization,
        isFalse,
      );
    });
  });
}

Future<CloudSyncResolution> _remoteArea(
  FakeFirebaseFirestore firestore,
  CloudSyncConflictArea area,
) async {
  final snapshot = await firestore
      .collection('households')
      .doc('casa')
      .collection('tables')
      .doc(area.name)
      .get();
  return CloudSyncResolution(
    payload: Map<String, dynamic>.from(snapshot.data()!['payload'] as Map),
    source: CloudSyncResolutionSource.remote,
  );
}
