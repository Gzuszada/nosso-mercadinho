import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app_environment.dart';
import 'cloud_models.dart';

class AuthAccount {
  const AuthAccount({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

class CloudAuthService {
  CloudAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<AuthAccount?> get authStateChanges => _auth.userChanges().map(
    (user) => user == null
        ? null
        : AuthAccount(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          ),
  );

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ensureDisplayName();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final requestedName = displayName?.trim();
    final validatedName = requestedName != null && requestedName.isNotEmpty
        ? validateDisplayName(requestedName)
        : null;
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

    if (validatedName != null) {
      await updateDisplayName(validatedName);
    } else {
      await ensureDisplayName();
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Envia o e-mail de redefinição de senha usando o template do Firebase.
  ///
  /// A URL permite que a página de ação do Firebase conclua a troca e
  /// devolva a pessoa ao site depois que a nova senha for salva.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw StateError('Informe um e-mail válido.');
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: normalizedEmail,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://nosso-mercado-casa.web.app',
          handleCodeInApp: false,
        ),
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-email':
          throw StateError('Informe um e-mail válido.');
        case 'user-not-found':
          // Não revela se o e-mail pertence a uma conta. O chamador mostra
          // a mesma confirmação usada quando o envio é realizado com sucesso.
          return;
        case 'too-many-requests':
          throw StateError(
            'Muitas tentativas foram enviadas. Aguarde alguns minutos e '
            'tente novamente.',
          );
        case 'operation-not-allowed':
        case 'internal-error':
          throw StateError(
            'A recuperação de senha está temporariamente indisponível. '
            'Tente novamente mais tarde.',
          );
        case 'network-request-failed':
          throw StateError(
            'Não foi possível conectar à internet. Verifique sua conexão e '
            'tente novamente.',
          );
        default:
          rethrow;
      }
    }
  }

  /// Garante que contas criadas antes da criação do nome de usuário tenham um
  /// nome utilizável, sem precisar apagar ou recriar a conta.
  Future<void> ensureDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final existing = user.displayName?.trim();
    if (existing != null && existing.isNotEmpty) {
      try {
        await _syncDisplayNameToMemberships(existing);
      } on FirebaseException {
        // O perfil já existe no Firebase Auth; o espelho é best-effort.
      }
      return;
    }
    await updateDisplayName(defaultDisplayName(user.email));
  }

  /// Atualiza o nome de usuário e o espelho nos registros de membros das casas
  /// às quais o usuário pertence.
  Future<void> updateDisplayName(String value) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta antes de editar o nome.');
    }
    final displayName = validateDisplayName(value);
    await user.updateProfile(displayName: displayName);
    try {
      await _syncDisplayNameToMemberships(displayName);
    } on FirebaseException {
      // O perfil nativo já foi salvo. O espelho nos membros é uma melhoria
      // best-effort e não deve impedir o usuário de editar o próprio nome.
    }
  }

  static String defaultDisplayName(String? email) {
    final localPart = email?.trim().split('@').first ?? '';
    final sanitized = localPart
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.length < 2) {
      return 'Usuário';
    }
    return sanitized.length <= 40
        ? sanitized
        : sanitized.substring(0, 40).trim();
  }

  static String validateDisplayName(String value) {
    final displayName = value.trim();
    if (displayName.length < 2 || displayName.length > 40) {
      throw ArgumentError('O nome deve ter entre 2 e 40 caracteres.');
    }
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(displayName)) {
      throw ArgumentError('O nome contém caracteres inválidos.');
    }
    return displayName;
  }

  Future<void> _syncDisplayNameToMemberships(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final memberships = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: user.uid)
        .get();
    if (memberships.docs.isEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final membership in memberships.docs) {
      batch.set(membership.reference, {
        'displayName': displayName,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<CloudHousehold>> discoverHouseholds() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const [];
    }

    final membershipSnapshot = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: user.uid)
        .get();

    final households = <CloudHousehold>[];
    for (final membership in membershipSnapshot.docs) {
      final householdId = membership.reference.parent.parent?.id;
      if (householdId == null) {
        continue;
      }
      if (households.any((household) => household.id == householdId)) {
        continue;
      }

      final household = await _firestore
          .collection('households')
          .doc(householdId)
          .get();
      final name = household.data()?['name'];
      if (name is String && name.trim().isNotEmpty) {
        households.add(CloudHousehold(id: householdId, name: name.trim()));
      }
    }

    households.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return households;
  }

  Future<bool> isHouseholdOwner(String householdId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final household = await _firestore
        .collection('households')
        .doc(householdId)
        .get();
    return household.data()?['ownerUid'] == user.uid;
  }

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
        'displayName': user.displayName,
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });
    return householdRef.id;
  }

  /// Deletes the household and all of its shared data from Firestore.
  ///
  /// Only the owner can call this operation according to the Firestore rules.
  Future<void> deleteHousehold({required String householdId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta antes de excluir a casa.');
    }
    final household = _firestore.collection('households').doc(householdId);
    final snapshot = await household.get();
    if (!snapshot.exists) {
      return;
    }
    if (snapshot.data()?['ownerUid'] != user.uid) {
      throw StateError('Somente o dono da casa pode excluí-la.');
    }

    for (final collectionName in const ['tables', 'metadata', 'inviteClaims']) {
      final documents = await household.collection(collectionName).get();
      for (final document in documents.docs) {
        await document.reference.delete();
      }
    }
    if (isPilotBuild) {
      await _deletePilotSyncData(householdId);
    }
    // Remove a casa e seus membros no mesmo commit. As regras avaliam o
    // estado anterior do documento da casa; excluí-lo antes deixaria a
    // remoção dos membros sem autorização e produziria membros órfãos.
    final members = await household.collection('members').get();
    final batch = _firestore.batch();
    for (final member in members.docs) {
      batch.delete(member.reference);
    }
    batch.delete(household);
    await batch.commit();
  }

  Future<void> _deletePilotSyncData(String householdId) async {
    final root = _firestore.doc('syncV2/$householdId');
    final candidates = await root.collection('candidates').get();
    for (final candidate in candidates.docs) {
      final areas = await candidate.reference.collection('areas').get();
      for (final area in areas.docs) {
        final parts = await area.reference.collection('parts').get();
        for (final part in parts.docs) {
          await part.reference.delete();
        }
        await area.reference.delete();
      }
      await candidate.reference.delete();
    }
    for (final collectionName in const ['conflicts', 'state']) {
      final documents = await root.collection(collectionName).get();
      for (final document in documents.docs) {
        await document.reference.delete();
      }
    }
    await root.delete();
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
      'displayName': user.displayName,
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
