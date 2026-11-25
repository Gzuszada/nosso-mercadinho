import 'sync_v2_manifest.dart';

enum SyncV2PublishStatus { committed, alreadyCommitted, conflict }

class SyncV2PublishResult {
  const SyncV2PublishResult({
    required this.status,
    required this.generation,
    this.conflictId,
  });

  final SyncV2PublishStatus status;
  final int generation;
  final String? conflictId;
}

class SyncV2RemoteState {
  const SyncV2RemoteState({
    required this.generation,
    required this.manifestHash,
    required this.manifest,
  });

  final int generation;
  final String? manifestHash;
  final SyncV2Manifest manifest;
}

class SyncV2Manifest {
  const SyncV2Manifest({
    required this.publicationId,
    required this.baseGeneration,
    required this.authorUid,
    required this.authorName,
    required this.deviceId,
    required this.areas,
    required this.createdAt,
  });

  static const protocolVersion = 2;

  final String publicationId;
  final int baseGeneration;
  final String authorUid;
  final String authorName;
  final String deviceId;
  final Map<String, SyncV2AreaManifest> areas;
  final DateTime createdAt;

  String get snapshotHash => canonicalHash(toMap());

  Map<String, dynamic> toMap() => {
    'protocolVersion': protocolVersion,
    'publicationId': publicationId,
    'baseGeneration': baseGeneration,
    'authorUid': authorUid,
    'authorName': authorName,
    'deviceId': deviceId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'areas': {
      for (final entry in areas.entries) entry.key: entry.value.toMap(),
    },
  };

  factory SyncV2Manifest.fromMap(Map<String, dynamic> map) {
    if (map['protocolVersion'] != protocolVersion) {
      throw const FormatException('Versão de sincronização não suportada.');
    }
    final rawAreas = map['areas'];
    if (rawAreas is! Map) {
      throw const FormatException('Manifesto sem áreas.');
    }
    return SyncV2Manifest(
      publicationId: _string(map, 'publicationId'),
      baseGeneration: _integer(map, 'baseGeneration'),
      authorUid: _string(map, 'authorUid'),
      authorName: _string(map, 'authorName'),
      deviceId: _string(map, 'deviceId'),
      areas: {
        for (final entry in rawAreas.entries)
          entry.key: SyncV2AreaManifest.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
      createdAt: DateTime.parse(_string(map, 'createdAt')).toUtc(),
    );
  }
}

int _integer(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('Campo "$key" inválido.');
  return value;
}

String _string(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Campo "$key" inválido.');
  }
  return value;
}
