import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mercado/features/cloud/data/pilot_household_administration_service.dart';

void main() {
  group('administração de pessoas da casa no piloto', () {
    test('lista owner, membros, papéis e data de entrada', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await _household(firestore, ownerUid: owner.uid);
      await firestore
          .collection('households')
          .doc('casa')
          .collection('members')
          .doc('membro')
          .set({
            'uid': 'membro',
            'email': 'membro@example.com',
            'displayName': 'Ana',
            'role': 'member',
            'joinedAt': DateTime.utc(2026, 11, 20),
          });

      final roster = await service.readRoster('casa');

      expect(roster.ownerUid, 'owner');
      expect(roster.peopleCount, 2);
      expect(roster.members.first.isOwner, isTrue);
      expect(roster.members.last.displayName, 'Ana');
      expect(roster.members.last.joinedAt, isNotNull);
      expect(
        roster.members.last.joinedAt!
            .toUtc()
            .difference(DateTime.utc(2026, 11, 20))
            .abs(),
        lessThan(const Duration(hours: 12)),
      );
    });

    test('owner remove membro comum e a claim de entrada', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      final household = await _household(firestore, ownerUid: owner.uid);
      await household.collection('members').doc('membro').set({
        'uid': 'membro',
        'role': 'member',
      });
      await household.collection('inviteClaims').doc('membro').set({
        'uid': 'membro',
      });

      await service.removeMember(householdId: 'casa', memberUid: 'membro');

      expect(
        (await household.collection('members').doc('membro').get()).exists,
        isFalse,
      );
      expect(
        (await household.collection('inviteClaims').doc('membro').get()).exists,
        isFalse,
      );
    });

    test('owner não pode remover a si mesmo sem transferir a casa', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await _household(firestore, ownerUid: owner.uid);

      await expectLater(
        service.removeMember(householdId: 'casa', memberUid: 'owner'),
        throwsA(isA<StateError>()),
      );
    });

    test('membro comum não pode remover outra pessoa', () async {
      final member = MockUser(uid: 'membro', email: 'membro@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: member);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await _household(firestore, ownerUid: 'owner');

      await expectLater(
        service.removeMember(householdId: 'casa', memberUid: 'outro'),
        throwsA(isA<StateError>()),
      );
    });

    test('owner lista e revoga convite da própria casa', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await _household(firestore, ownerUid: owner.uid);
      await firestore.collection('householdInvites').doc('ABCD1234').set({
        'householdId': 'casa',
        'email': 'convite@example.com',
        'createdAt': DateTime.utc(2026, 11, 21),
      });

      final invites = await service.readInvites('casa');
      expect(invites.single.email, 'convite@example.com');

      await service.revokeInvite(householdId: 'casa', code: 'ABCD1234');
      expect(
        (await firestore.collection('householdInvites').doc('ABCD1234').get())
            .exists,
        isFalse,
      );
    });

    test('transferência preserva a mensagem de erro da Function', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Escolha um membro diferente.'},
            }),
            400,
          ),
        ),
      );
      await _household(firestore, ownerUid: owner.uid);

      await expectLater(
        service.transferOwnership(householdId: 'casa', targetUid: 'membro'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Escolha um membro diferente.'),
          ),
        ),
      );
    });

    test('transferência chama a Function do projeto piloto', () async {
      final owner = MockUser(uid: 'owner', email: 'owner@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
      final firestore = FakeFirebaseFirestore();
      late http.Request captured;
      final service = PilotHouseholdAdministrationService(
        auth: auth,
        firestore: firestore,
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'data': {'status': 'transferred'},
            }),
            200,
          );
        }),
      );
      await _household(firestore, ownerUid: owner.uid);

      await service.transferOwnership(householdId: 'casa', targetUid: 'membro');

      expect(
        captured.url.host,
        'us-central1-nosso-mercado-casa-pilot.cloudfunctions.net',
      );
      expect(captured.url.path, '/transferHouseholdOwnership');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['data'], {'householdId': 'casa', 'targetUid': 'membro'});
    });
  });
}

Future<dynamic> _household(
  FakeFirebaseFirestore firestore, {
  required String ownerUid,
}) async {
  final household = firestore.collection('households').doc('casa');
  await household.set({'name': 'Casa', 'ownerUid': ownerUid});
  await household.collection('members').doc(ownerUid).set({
    'uid': ownerUid,
    'email': 'owner@example.com',
    'displayName': 'Owner',
    'role': 'owner',
    'joinedAt': DateTime.utc(2026, 11, 19),
  });
  return household;
}
