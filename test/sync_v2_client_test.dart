import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado/features/cloud/data/sync_v2_candidate.dart';
import 'package:mercado/features/cloud/data/sync_v2_client.dart';
import 'package:mercado/features/cloud/data/sync_v2_review.dart';

void main() {
  group('sync v2 client', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(
          uid: 'owner-uid',
          email: 'owner@example.com',
          displayName: 'Owner',
        ),
      );
    });

    test('re-adicao posterior a remoção recebe nova identidade', () {
      final review = SyncV2Review(
        itemSyncId: 'planned-item:old',
        action: SyncV2ReviewAction.remove,
        reviewedByUid: 'owner-uid',
        reviewedByName: 'Owner',
        decidedAt: DateTime.utc(2026, 11, 25, 18, 55, 18),
        authorUid: 'member-uid',
        authorName: 'Member',
      );
      final payload = {
        'plannedItems': [
          {
            'syncId': 'planned-item:old',
            'logicalKey': 'planned-item:plan:product',
            'reviewState': 'pending_review',
            'isRemoved': false,
            'deletedAt': null,
            'updatedAt': '2026-11-25T20:07:11.000',
            'syncRevision': 14,
          },
        ],
      };

      final separated = separateReaddedPendingItems(payload, [review]);
      final row = (separated['plannedItems'] as List).single as Map;
      expect(row['syncId'], isNot('planned-item:old'));
      expect(row['syncId'], startsWith('planned-item:'));

      final reviewed = applySyncV2Reviews(separated, [review]);
      final reviewedRow = (reviewed['plannedItems'] as List).single as Map;
      expect(reviewedRow['reviewState'], 'pending_review');
      expect(reviewedRow['isRemoved'], isFalse);
    });

    test('divide, publica e recompõe uma tabela grande', () async {
      final rows = [
        for (var index = 0; index < 3; index++)
          {
            'id': index,
            'name': 'produto-${index.toString().padLeft(4, '0')}',
            'description': 'x' * 350000,
          },
      ];
      final client = SyncV2Client(
        firestore: firestore,
        auth: auth,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/publishSyncV2');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          final manifest = SyncV2Manifest.fromMap(
            Map<String, dynamic>.from(data['manifest'] as Map),
          );
          expect(manifest.areas['catalog']!.chunks.length, greaterThan(1));
          return http.Response(
            jsonEncode({
              'result': {'status': 'committed', 'generation': 1},
            }),
            200,
          );
        }),
      );

      final result = await client.publish(
        householdId: 'casa',
        publicationId: 'publication-1',
        areas: {
          'catalog': {
            'products': rows,
            'categories': const <Object?>[],
            'formatVersion': 6,
          },
        },
        authorUid: 'owner-uid',
        authorName: 'Owner',
        deviceId: 'device-1',
        baseGeneration: 0,
        expectedManifestHash: null,
      );

      expect(result.status, SyncV2PublishStatus.committed);
      final chunks = await firestore
          .collection('syncV2')
          .doc('casa')
          .collection('candidates')
          .doc('publication-1')
          .collection('areas')
          .doc('catalog')
          .collection('parts')
          .get();
      expect(chunks.docs.length, greaterThan(1));
      expect(
        chunks.docs
            .map((doc) => doc.get('count') as int)
            .reduce((a, b) => a + b),
        rows.length + 1,
      );
    });

    test('envia moderação para a callable do backend', () async {
      final client = SyncV2Client(
        firestore: firestore,
        auth: auth,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/moderatePlannedItem');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          expect(data['householdId'], 'casa');
          expect(data['itemSyncId'], 'planned-item-1');
          expect(data['action'], 'approve');
          return http.Response(
            jsonEncode({
              'result': {'status': 'recorded'},
            }),
            200,
          );
        }),
      );

      await client.moderatePlannedItem(
        householdId: 'casa',
        itemSyncId: 'planned-item-1',
        action: SyncV2ReviewAction.approve,
      );
    });

    test('reutiliza chunks imutáveis no retry da publication', () async {
      final client = SyncV2Client(
        firestore: firestore,
        auth: auth,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'result': {'status': 'alreadyCommitted', 'generation': 1},
            }),
            200,
          );
        }),
      );
      final payload = {
        'products': [
          {'id': 1, 'name': 'Leite'},
        ],
        'formatVersion': 6,
      };

      await client.publish(
        householdId: 'casa',
        publicationId: 'publication-retry',
        areas: {'catalog': payload},
        authorUid: 'owner-uid',
        authorName: 'Owner',
        deviceId: 'device-1',
        baseGeneration: 0,
        expectedManifestHash: null,
      );
      final partRef = firestore
          .collection('syncV2')
          .doc('casa')
          .collection('candidates')
          .doc('publication-retry')
          .collection('areas')
          .doc('catalog')
          .collection('parts')
          .doc('0');
      final before = await partRef.get();

      await client.publish(
        householdId: 'casa',
        publicationId: 'publication-retry',
        areas: {'catalog': payload},
        authorUid: 'owner-uid',
        authorName: 'Owner',
        deviceId: 'device-1',
        baseGeneration: 0,
        expectedManifestHash: null,
      );
      final after = await partRef.get();
      expect(after.get('hash'), before.get('hash'));
      expect(after.get('payload'), before.get('payload'));
    });
  });
}
