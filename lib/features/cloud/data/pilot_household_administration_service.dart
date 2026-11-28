import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Administrative information about one household member.
class CloudHouseholdMember {
  const CloudHouseholdMember({
    required this.uid,
    required this.displayName,
    required this.role,
    this.email,
    this.joinedAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String role;
  final DateTime? joinedAt;

  bool get isOwner => role == 'owner';
}

/// A pending invitation created by the household owner.
class CloudHouseholdInvite {
  const CloudHouseholdInvite({
    required this.code,
    required this.email,
    this.createdAt,
    this.expiresAt,
  });

  final String code;
  final String email;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  int remainingDaysAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null || !expiry.isAfter(now)) return 0;
    final difference = expiry.difference(now);
    return (difference.inMicroseconds +
            const Duration(days: 1).inMicroseconds -
            1) ~/
        const Duration(days: 1).inMicroseconds;
  }
}

/// The authoritative people and owner state of a household.
class CloudHouseholdRoster {
  const CloudHouseholdRoster({
    required this.householdId,
    required this.ownerUid,
    required this.members,
  });

  final String householdId;
  final String ownerUid;
  final List<CloudHouseholdMember> members;

  int get peopleCount => members.length;
}

/// Pilot-only administration of household members and invitations.
///
/// Firestore rules remain the final authorization boundary. The explicit
/// owner checks here avoid accidental actions and produce understandable UI
/// errors before a request is sent.
class PilotHouseholdAdministrationService {
  PilotHouseholdAdministrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
    this.projectId = 'nosso-mercado-casa-pilot',
    this.region = 'us-central1',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;
  final String projectId;
  final String region;

  String? get currentUid => _auth.currentUser?.uid;

  Future<CloudHouseholdRoster> readRoster(String householdId) async {
    final household = _firestore.collection('households').doc(householdId);
    final snapshot = await household.get();
    if (!snapshot.exists) {
      throw StateError('A casa não existe mais.');
    }
    final ownerUid = snapshot.data()?['ownerUid'];
    if (ownerUid is! String || ownerUid.isEmpty) {
      throw StateError('A casa não possui um owner válido.');
    }
    final memberSnapshot = await household.collection('members').get();
    final members =
        memberSnapshot.docs.map((document) {
          final data = document.data();
          final email = _string(data['email']);
          final displayName = _string(data['displayName']);
          return CloudHouseholdMember(
            uid: document.id,
            displayName: displayName.isNotEmpty
                ? displayName
                : email.split('@').first.isNotEmpty
                ? email.split('@').first
                : 'Membro',
            email: email.isEmpty ? null : email,
            role: data['role'] == 'owner' ? 'owner' : 'member',
            joinedAt: _dateTime(data['joinedAt']),
          );
        }).toList()..sort((left, right) {
          if (left.isOwner != right.isOwner) return left.isOwner ? -1 : 1;
          final dateOrder = (left.joinedAt ?? DateTime(1970)).compareTo(
            right.joinedAt ?? DateTime(1970),
          );
          if (dateOrder != 0) return dateOrder;
          return left.displayName.toLowerCase().compareTo(
            right.displayName.toLowerCase(),
          );
        });
    return CloudHouseholdRoster(
      householdId: householdId,
      ownerUid: ownerUid,
      members: members,
    );
  }

  Future<List<CloudHouseholdInvite>> readInvites(String householdId) async {
    await _requireOwner(householdId);
    final snapshot = await _firestore
        .collection('householdInvites')
        .where('householdId', isEqualTo: householdId)
        .get();
    final invites =
        snapshot.docs.map((document) {
          final data = document.data();
          return CloudHouseholdInvite(
            code: document.id,
            email: _string(data['email']),
            createdAt: _dateTime(data['createdAt']),
            expiresAt: _dateTime(data['expiresAt']),
          );
        }).toList()..sort(
          (left, right) => (left.createdAt ?? DateTime(1970)).compareTo(
            right.createdAt ?? DateTime(1970),
          ),
        );
    return invites;
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    await _requireOwner(householdId);
    final memberRef = _firestore
        .collection('households')
        .doc(householdId)
        .collection('members')
        .doc(memberUid);
    final member = await memberRef.get();
    if (!member.exists) return;
    if (member.data()?['role'] == 'owner') {
      throw StateError(
        'O owner não pode ser removido antes de transferir a propriedade.',
      );
    }
    final claimRef = _firestore
        .collection('households')
        .doc(householdId)
        .collection('inviteClaims')
        .doc(memberUid);
    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.delete(claimRef);
    await batch.commit();
  }

  Future<void> revokeInvite({
    required String householdId,
    required String code,
  }) async {
    await _requireOwner(householdId);
    final inviteRef = _firestore.collection('householdInvites').doc(code);
    final invite = await inviteRef.get();
    if (!invite.exists) return;
    if (invite.data()?['householdId'] != householdId) {
      throw StateError('Este convite pertence a outra casa.');
    }
    await inviteRef.delete();
  }

  Future<void> transferOwnership({
    required String householdId,
    required String targetUid,
  }) async {
    await _requireOwner(householdId);
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('Entre na sua conta antes de transferir a casa.');
    }
    final response = await _httpClient.post(
      Uri.https(
        '$region-$projectId.cloudfunctions.net',
        'transferHouseholdOwnership',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'data': {'householdId': householdId, 'targetUid': targetUid},
      }),
    );
    if (response.statusCode != 200) {
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      } on FormatException {
        decoded = null;
      }
      final error = decoded?['error'] as Map<String, dynamic>?;
      throw StateError(
        error?['message'] as String? ??
            'Não foi possível transferir a propriedade da casa.',
      );
    }
  }

  Future<void> _requireOwner(String householdId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta para administrar esta casa.');
    }
    final ownerUid = await householdOwnerUid(householdId);
    if (ownerUid != user.uid) {
      throw StateError('Somente o dono da casa pode realizar esta ação.');
    }
  }

  Future<String?> householdOwnerUid(String householdId) async {
    final snapshot = await _firestore
        .collection('households')
        .doc(householdId)
        .get();
    final ownerUid = snapshot.data()?['ownerUid'];
    return ownerUid is String && ownerUid.isNotEmpty ? ownerUid : null;
  }

  static String _string(Object? value) => value is String ? value.trim() : '';

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
