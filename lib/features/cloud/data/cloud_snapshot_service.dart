import 'dart:convert';

import '../../../data/app_database.dart';
import '../../backup/data/backup_service.dart';

class CloudSnapshotService {
  const CloudSnapshotService(this._database);

  final AppDatabase _database;

  Future<Map<String, dynamic>> readLocalPayload() async {
    final backup = await BackupService(_database).createBackup(
      exportedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    final decoded = jsonDecode(backup) as Map<String, dynamic>;
    return {
      for (final key in const [
        'categories',
        'subcategories',
        'products',
        'importBatches',
        'importEntries',
        'shoppingPlans',
        'plannedItems',
        'shoppingTrips',
        'purchaseLines',
        'formatVersion',
      ])
        key: decoded[key],
    };
  }

  Future<void> restoreRemotePayload(Map<String, dynamic> payload) async {
    await BackupService(_database).restoreValidatedPayload({
      ...payload,
      'formatVersion': payload['formatVersion'] ?? 6,
    });
  }
}
