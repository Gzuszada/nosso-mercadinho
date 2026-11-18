import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/cloud_auth_service.dart';

void main() {
  test('exclui a casa, tabelas, metadados e membros do Firebase', () async {
    final owner = MockUser(uid: 'owner', email: 'owner@example.com');
    final auth = MockFirebaseAuth(signedIn: true, mockUser: owner);
    final firestore = FakeFirebaseFirestore();
    final service = CloudAuthService(auth: auth, firestore: firestore);
    final household = firestore.collection('households').doc('casa');
    await household.set({'name': 'Casa', 'ownerUid': owner.uid});
    await household.collection('tables').doc('catalog').set({'payload': {}});
    await household.collection('metadata').doc('sync').set({'revision': 1});
    await household.collection('members').doc(owner.uid).set({
      'uid': owner.uid,
      'role': 'owner',
    });

    await service.deleteHousehold(householdId: 'casa');

    expect((await household.get()).exists, isFalse);
    expect((await household.collection('tables').get()).docs, isEmpty);
    expect((await household.collection('metadata').get()).docs, isEmpty);
    expect((await household.collection('members').get()).docs, isEmpty);
  });

  test('somente o dono pode excluir a casa', () async {
    final owner = MockUser(uid: 'owner');
    final member = MockUser(uid: 'member');
    final auth = MockFirebaseAuth(signedIn: true, mockUser: member);
    final firestore = FakeFirebaseFirestore();
    final service = CloudAuthService(auth: auth, firestore: firestore);
    await firestore.collection('households').doc('casa').set({
      'name': 'Casa',
      'ownerUid': owner.uid,
    });

    await expectLater(
      service.deleteHousehold(householdId: 'casa'),
      throwsA(isA<StateError>()),
    );
    expect(
      (await firestore.collection('households').doc('casa').get()).exists,
      isTrue,
    );
  });
}
