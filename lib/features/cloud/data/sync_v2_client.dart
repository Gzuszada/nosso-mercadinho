import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/sync_v2_canonical.dart';
import 'sync_v2_candidate.dart';
import 'sync_v2_manifest.dart';
import 'sync_v2_review.dart';

/// Publishes immutable candidates and asks the backend for an atomic commit.
class SyncV2Client {
  SyncV2Client({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
    this.projectId = 'nosso-mercado-casa-pilot',
    this.region = 'us-central1',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? http.Client();

  static const maxChunkBytes = 700 * 1024;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;
  final String projectId;
  final String region;

  Future<({String uid, String name})?> currentAuthor() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return (
      uid: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Usuário piloto',
    );
  }

  Future<List<SyncV2Review>> readReviews(String householdId) async {
    final snapshot = await _firestore
        .collection('syncV2')
        .doc(householdId)
        .collection('reviews')
        .get();
    return snapshot.docs
        .map(
          (doc) => SyncV2Review.fromMap(Map<String, dynamic>.from(doc.data())),
        )
        .where((review) => review.itemSyncId.isNotEmpty)
        .toList();
  }

  Future<void> moderatePlannedItem({
    required String householdId,
    required String itemSyncId,
    required SyncV2ReviewAction action,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('Entre na sua conta antes de revisar um item.');
    }
    final uri = Uri.https(
      '$region-$projectId.cloudfunctions.net',
      'moderatePlannedItem',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'data': {
          'householdId': householdId,
          'itemSyncId': itemSyncId,
          'action': action.key,
        },
      }),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw StateError(
        error?['message'] as String? ??
            'Não foi possível registrar a revisão do item.',
      );
    }
  }

  Future<SyncV2RemoteState?> readCurrentState(String householdId) async {
    final snapshot = await _firestore
        .doc('syncV2/$householdId/state/current')
        .get();
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    final manifestData = data['manifest'];
    if (manifestData is! Map) {
      throw const FormatException('Manifesto oficial inválido.');
    }
    return SyncV2RemoteState(
      generation: data['generation'] as int? ?? 0,
      manifestHash: data['manifestHash'] as String?,
      manifest: SyncV2Manifest.fromMap(Map<String, dynamic>.from(manifestData)),
    );
  }

  Future<Map<String, dynamic>> readArea({
    required String householdId,
    required String area,
    required SyncV2Manifest manifest,
  }) async {
    final areaManifest = manifest.areas[area];
    if (areaManifest == null) {
      throw FormatException('Área "$area" ausente no manifesto.');
    }
    final rowsByTable = <String, List<Object?>>{};
    for (final descriptor in areaManifest.chunks) {
      final snapshot = await _firestore.doc(descriptor.path).get();
      if (!snapshot.exists) {
        throw StateError('A publicação oficial está incompleta ($area).');
      }
      final payload = snapshot.data()?['payload'];
      if (payload is! Map) {
        throw StateError('Chunk inválido ($area).');
      }
      if (canonicalHash(payload) != descriptor.hash) {
        throw StateError('A integridade do chunk não confere ($area).');
      }
      for (final entry in payload.entries) {
        final value = entry.value;
        if (value is List) {
          (rowsByTable[entry.key] ??= []).addAll(value);
        } else if (entry.key == 'formatVersion') {
          rowsByTable[entry.key] = [value];
        } else {
          rowsByTable[entry.key] = [value];
        }
      }
    }
    return {
      for (final entry in rowsByTable.entries)
        entry.key: entry.key == 'formatVersion' && entry.value.length == 1
            ? entry.value.single
            : entry.value,
    };
  }

  String areaContentHash(Map<String, dynamic> payload) {
    final chunks = _splitPayload(payload);
    return canonicalHash([
      for (var index = 0; index < chunks.length; index++)
        {
          'index': index,
          'hash': canonicalHash(chunks[index]),
          'count': _payloadRowCount(chunks[index]),
        },
    ]);
  }

  /// Hash of the area content, independent of the device that produced it.
  ///
  /// The bytes of an area differ between devices even when the data is the
  /// same: the integer identifiers are numbered by each device, `syncRevision`
  /// is a counter that each device advances on its own and the same instant
  /// can be written with different timezones and precisions. This hash
  /// describes the content, so two devices that hold the same data produce the
  /// same value and are not reported as divergent.
  String areaSemanticHash(Map<String, dynamic> payload) {
    return canonicalHash(syncV2SemanticArea(payload));
  }

  Future<SyncV2PublishResult> publish({
    required String householdId,
    required String publicationId,
    required Map<String, dynamic> areas,
    required String authorUid,
    required String authorName,
    required String deviceId,
    required int baseGeneration,
    required String? expectedManifestHash,
    bool requiresOwnerModeration = false,
  }) async {
    final manifests = <String, SyncV2AreaManifest>{};
    for (final entry in areas.entries) {
      manifests[entry.key] = await _uploadArea(
        householdId: householdId,
        publicationId: publicationId,
        area: entry.key,
        payload: entry.value,
      );
    }
    final manifest = SyncV2Manifest(
      publicationId: publicationId,
      baseGeneration: baseGeneration,
      authorUid: authorUid,
      authorName: authorName,
      deviceId: deviceId,
      areas: manifests,
      createdAt: DateTime.now().toUtc(),
    );
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('Entre na sua conta antes de publicar.');
    }
    final uri = Uri.https(
      '$region-$projectId.cloudfunctions.net',
      'publishSyncV2',
    );
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'data': {
          'householdId': householdId,
          'publicationId': publicationId,
          'baseGeneration': baseGeneration,
          'expectedManifestHash': expectedManifestHash,
          'requiresOwnerModeration': requiresOwnerModeration,
          'manifest': manifest.toMap(),
        },
      }),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final error = decoded['error'] as Map<String, dynamic>?;
      throw StateError(
        error?['message'] as String? ??
            'Não foi possível publicar a sincronização.',
      );
    }
    final result = decoded['result'] as Map<String, dynamic>?;
    final data = Map<String, dynamic>.from(result ?? const {});

    return SyncV2PublishResult(
      status: switch (data['status']) {
        'committed' => SyncV2PublishStatus.committed,
        'alreadyCommitted' => SyncV2PublishStatus.alreadyCommitted,
        _ => SyncV2PublishStatus.conflict,
      },
      generation: data['generation'] as int? ?? baseGeneration,
      conflictId: data['conflictId'] as String?,
    );
  }

  Map<String, dynamic> applyReviews(
    Map<String, dynamic> payload,
    Iterable<SyncV2Review> reviews,
  ) => applySyncV2Reviews(payload, reviews);

  Future<SyncV2AreaManifest> _uploadArea({
    required String householdId,
    required String publicationId,
    required String area,
    required Map<String, dynamic> payload,
  }) async {
    final chunks = _splitPayload(payload);
    final descriptors = <SyncV2ChunkDescriptor>[];
    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      final path =
          'syncV2/$householdId/candidates/$publicationId/'
          'areas/$area/parts/$index';
      final rowCount = _payloadRowCount(chunk);
      final chunkRef = _firestore.doc(path);
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(chunkRef);
        if (existing.exists) {
          if (existing.get('hash') != canonicalHash(chunk)) {
            throw StateError('A publication já contém um chunk diferente.');
          }
          return;
        }
        transaction.set(chunkRef, {
          'payload': chunk,
          'hash': canonicalHash(chunk),
          'count': rowCount,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      descriptors.add(
        SyncV2ChunkDescriptor(
          index: index,
          path: path,
          hash: canonicalHash(chunk),
          count: rowCount,
        ),
      );
    }
    final contentDescriptors = [
      for (final item in descriptors)
        {'index': item.index, 'hash': item.hash, 'count': item.count},
    ];
    return SyncV2AreaManifest(
      hash: canonicalHash(contentDescriptors),
      counts: _payloadCounts(payload),
      chunks: descriptors,
    );
  }

  int _payloadRowCount(Map<String, dynamic> payload) {
    return payload.values.fold(0, (total, value) {
      if (value is List) return total + value.length;
      return total + 1;
    });
  }

  Map<String, int> _payloadCounts(Map<String, dynamic> payload) {
    return {
      for (final entry in payload.entries)
        entry.key: entry.value is List ? (entry.value as List).length : 1,
    };
  }

  List<Map<String, dynamic>> _splitPayload(Map<String, dynamic> payload) {
    final chunks = <Map<String, dynamic>>[];
    final entries = payload.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in entries) {
      final value = entry.value;
      if (value is! List) {
        _appendChunk(chunks, {entry.key: value});
        continue;
      }
      var rows = <Object?>[];
      for (final row in value) {
        final candidate = <String, dynamic>{
          entry.key: [...rows, row],
        };
        if (rows.isNotEmpty && _encodedSize(candidate) > maxChunkBytes) {
          _appendChunk(chunks, {entry.key: rows});
          rows = [row];
        } else {
          rows.add(row);
        }
      }
      if (rows.isNotEmpty) {
        _appendChunk(chunks, {entry.key: rows});
      } else {
        _appendChunk(chunks, {entry.key: const <Object?>[]});
      }
    }
    return chunks.isEmpty ? [const {}] : chunks;
  }

  void _appendChunk(
    List<Map<String, dynamic>> chunks,
    Map<String, dynamic> chunk,
  ) {
    if (chunks.isNotEmpty) {
      final last = chunks.last;
      final hasSameTable = last.keys.any(chunk.keys.contains);
      final merged = {...last, ...chunk};
      if (!hasSameTable && _encodedSize(merged) <= maxChunkBytes) {
        chunks[chunks.length - 1] = merged;
        return;
      }
    }
    chunks.add(chunk);
  }

  int _encodedSize(Map<String, dynamic> value) {
    return utf8.encode(jsonEncode(value)).length;
  }
}
