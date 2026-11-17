import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthAccount {
  const AuthAccount({required this.uid, this.email});

  final String uid;
  final String? email;
}

class CloudAuthService {
  CloudAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<AuthAccount?> get authStateChanges => _auth.authStateChanges().map(
    (user) =>
        user == null ? null : AuthAccount(uid: user.uid, email: user.email),
  );

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'operation-not-allowed' ||
          error.code == 'internal-error') {
        throw StateError(
          'Este e-mail não está autorizado ou o cadastro seguro ainda não '
          'está disponível.',
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<String> createHousehold({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta antes de criar uma casa.');
    }
    final householdRef = _firestore.collection('households').doc();
    final memberRef = householdRef.collection('members').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      transaction.set(householdRef, {
        'name': name.trim(),
        'ownerUid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(memberRef, {
        'uid': user.uid,
        'email': user.email,
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });
    return householdRef.id;
  }

  Future<String> createInvite({
    required String householdId,
    required String invitedEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta antes de convidar alguém.');
    }
    final code = _randomCode();
    await _firestore.collection('householdInvites').doc(code).set({
      'code': code,
      'householdId': householdId,
      'email': invitedEmail.trim().toLowerCase(),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<String> joinHousehold({required String code}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta antes de entrar em uma casa.');
    }
    final normalized = code.trim().toUpperCase();
    final invitation = await _firestore
        .collection('householdInvites')
        .doc(normalized)
        .get();
    if (!invitation.exists) {
      throw StateError('Código de convite não encontrado.');
    }
    final invitedEmail = invitation.get('email') as String? ?? '';
    if (invitedEmail.isNotEmpty && invitedEmail != user.email?.toLowerCase()) {
      throw StateError('Este convite foi enviado para outro e-mail.');
    }
    final householdId = invitation.get('householdId') as String;
    final memberRef = _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .doc(user.uid);
    final claimRef = _firestore
        .collection('households')
        .doc(householdId)
        .collection('inviteClaims')
        .doc(user.uid);
    final batch = _firestore.batch();
    batch.set(claimRef, {
      'uid': user.uid,
      'email': user.email,
      'inviteCode': normalized,
      'claimedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'uid': user.uid,
      'email': user.email,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await invitation.reference.delete();
    return householdId;
  }

  static String _randomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
  }
}
