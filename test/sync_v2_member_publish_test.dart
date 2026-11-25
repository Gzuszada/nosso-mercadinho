import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/cloud/data/sync_v2_client.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';

void main() {
  test('membro da casa pode publicar sem exigir moderação do owner', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settings = SettingsRepository(database);
    await settings.selectCloudHousehold('casa');

    await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            name: 'Leite',
            measurementMode: const Value('unit'),
          ),
        );

    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'member-uid',
        email: 'member@example.com',
        displayName: 'Membro',
      ),
    );
    var ownerModerationRequested = true;
    final client = SyncV2Client(
      firestore: firestore,
      auth: auth,
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        ownerModerationRequested =
            data['requiresOwnerModeration'] as bool? ?? false;
        return http.Response(
          jsonEncode({
            'result': {'status': 'committed', 'generation': 1},
          }),
          200,
        );
      }),
    );
    final service = CloudSyncService(
      database: database,
      settingsRepository: settings,
      firestore: firestore,
      syncV2Client: client,
    );

    final result = await service.publishAllLocalAreas(householdId: 'casa');

    expect(result.pushed, isTrue);
    expect(ownerModerationRequested, isFalse);
  });
}
