import 'dart:convert';

import 'package:crypto/crypto.dart';

enum CloudSyncConflictArea { catalog, imports, shopping }

enum CloudSyncAreaState { inSync, localOnly, remoteOnly, divergent, invalid }

class CloudAreaCounts {
  const CloudAreaCounts(this.values);

  final Map<String, int> values;

  int get total => values.values.fold(0, (sum, count) => sum + count);

  String get summary =>
      values.entries.map((entry) => '${entry.value} ${entry.key}').join(', ');
}

class CloudSyncAreaStatus {
  const CloudSyncAreaStatus({
    required this.area,
    required this.state,
    required this.localCounts,
    required this.remoteCounts,
    required this.localHash,
    required this.remoteHash,
    this.message,
  });

  final CloudSyncConflictArea area;
  final CloudSyncAreaState state;
  final CloudAreaCounts localCounts;
  final CloudAreaCounts remoteCounts;
  final String? localHash;
  final String? remoteHash;
  final String? message;

  bool get needsSynchronization => state != CloudSyncAreaState.inSync;
}

/// Identifies the deployed synchronization build in diagnostics.
const cloudSyncBuildLabel = '2026-11-18-sync-v2';

class CloudSyncStatus {
  const CloudSyncStatus({
    required this.householdId,
    required this.remoteRevision,
    required this.areas,
  });

  final String householdId;
  final int remoteRevision;
  final Map<CloudSyncConflictArea, CloudSyncAreaStatus> areas;

  bool get needsSynchronization =>
      areas.values.any((area) => area.needsSynchronization);
}

class CloudHousehold {
  const CloudHousehold({required this.id, required this.name});

  final String id;
  final String name;
}

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

extension CloudSyncAreaStateLabel on CloudSyncAreaState {
  String get label => switch (this) {
    CloudSyncAreaState.inSync => 'Em dia',
    CloudSyncAreaState.localOnly => 'Somente neste dispositivo',
    CloudSyncAreaState.remoteOnly => 'Somente no Firebase',
    CloudSyncAreaState.divergent => 'Divergente',
    CloudSyncAreaState.invalid => 'Dados remotos inválidos',
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
  });

  final bool pulled;
  final bool pushed;
  final int revision;
}
