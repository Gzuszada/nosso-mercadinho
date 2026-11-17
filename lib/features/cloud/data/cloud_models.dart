import 'dart:convert';

import 'package:crypto/crypto.dart';

enum CloudSyncConflictArea { catalog, imports, shopping }

enum CloudSyncResolutionSource { local, remote }

class CloudSyncResolution {
  const CloudSyncResolution({required this.payload, required this.source});

  final Map<String, dynamic> payload;
  final CloudSyncResolutionSource source;
}

extension CloudSyncConflictAreaLabel on CloudSyncConflictArea {
  String get label => switch (this) {
    CloudSyncConflictArea.catalog => 'catálogo',
    CloudSyncConflictArea.imports => 'importações',
    CloudSyncConflictArea.shopping => 'listas, compras e histórico',
  };
}

class CloudSnapshot {
  const CloudSnapshot({
    required this.revision,
    required this.hash,
    required this.payload,
  });

  final int revision;
  final String hash;
  final Map<String, dynamic> payload;

  static String hashPayload(Map<String, dynamic> payload) {
    final canonical = jsonEncode(_canonicalize(payload));
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonicalize(value[key])};
    }
    if (value is List) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }
}

class CloudSyncConflict {
  const CloudSyncConflict({
    required this.area,
    required this.localPayload,
    required this.remotePayload,
    required this.remoteRevision,
  });

  final CloudSyncConflictArea area;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final int remoteRevision;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.pulled,
    required this.pushed,
    required this.revision,
    this.conflict,
  });

  final bool pulled;
  final bool pushed;
  final int revision;
  final CloudSyncConflict? conflict;
}
