import 'package:drift/drift.dart';

import '../../../data/app_database.dart';

class SettingsRepository {
  const SettingsRepository(this._database);

  final AppDatabase _database;

  Stream<bool> watchDarkMode() {
    return (_database.select(_database.appPreferences)
          ..where((row) => row.id.equals(1)))
        .watchSingleOrNull()
        .map((preference) => preference?.isDarkMode ?? false);
  }

  Future<void> setDarkMode(bool enabled) async {
    await _database.transaction(() async {
      final preference = await (_database.select(
        _database.appPreferences,
      )..where((row) => row.id.equals(1))).getSingleOrNull();
      if (preference == null) {
        await _database
            .into(_database.appPreferences)
            .insert(
              AppPreferencesCompanion.insert(
                id: const Value(1),
                isDarkMode: Value(enabled),
              ),
            );
      } else {
        await (_database.update(_database.appPreferences)
              ..where((row) => row.id.equals(1)))
            .write(AppPreferencesCompanion(isDarkMode: Value(enabled)));
      }
    });
  }

  Future<CloudSyncSetting?> getCloudSyncSettings() async {
    return (_database.select(
      _database.cloudSyncSettings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
  }

  Future<void> saveCloudSyncSettings({
    String? householdId,
    required int remoteRevision,
    required String? lastSyncedHash,
    String? householdOwnerUid,
    bool resetHouseholdOwner = false,
  }) async {
    await _database.transaction(() async {
      final current = await getCloudSyncSettings();
      final ownerUid = resetHouseholdOwner
          ? null
          : householdOwnerUid ?? current?.householdOwnerUid;
      await _database
          .into(_database.cloudSyncSettings)
          .insert(
            CloudSyncSettingsCompanion.insert(
              id: const Value(1),
              householdId: Value(householdId),
              remoteRevision: Value(remoteRevision),
              lastSyncedHash: Value(lastSyncedHash),
              householdOwnerUid: Value(ownerUid),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Future<void> cacheHouseholdOwner(String householdId, String ownerUid) async {
    final current = await getCloudSyncSettings();
    if (current?.householdId != householdId ||
        current?.householdOwnerUid == ownerUid) {
      return;
    }
    await saveCloudSyncSettings(
      householdId: householdId,
      remoteRevision: current?.remoteRevision ?? 0,
      lastSyncedHash: current?.lastSyncedHash,
      householdOwnerUid: ownerUid,
    );
  }

  Future<void> selectCloudHousehold(String householdId) async {
    final current = await getCloudSyncSettings();
    if (current?.householdId == householdId) {
      return;
    }
    await saveCloudSyncSettings(
      householdId: householdId,
      remoteRevision: 0,
      lastSyncedHash: null,
      resetHouseholdOwner: true,
    );
  }
}
