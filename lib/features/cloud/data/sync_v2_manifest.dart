import 'dart:convert';

import 'package:crypto/crypto.dart';

enum SyncV2Area { catalog, imports, shopping }

extension SyncV2AreaKey on SyncV2Area {
  String get key => switch (this) {
    SyncV2Area.catalog => 'catalog',
    SyncV2Area.imports => 'imports',
    SyncV2Area.shopping => 'shopping',
  };
}

class SyncV2ChunkDescriptor {
  const SyncV2ChunkDescriptor({
    required this.index,
    required this.path,
    required this.hash,
    required this.count,
  });

  final int index;
  final String path;
  final String hash;
  final int count;

  Map<String, dynamic> toMap() => {
    'index': index,
    'path': path,
    'hash': hash,
    'count': count,
  };

  factory SyncV2ChunkDescriptor.fromMap(Map<String, dynamic> map) {
    return SyncV2ChunkDescriptor(
      index: _requiredInt(map, 'index'),
      path: _requiredString(map, 'path'),
      hash: _requiredString(map, 'hash'),
      count: _requiredInt(map, 'count'),
    );
  }
}

class SyncV2AreaManifest {
  const SyncV2AreaManifest({
    required this.hash,
    required this.counts,
    required this.chunks,
  });

  final String hash;
  final Map<String, int> counts;
  final List<SyncV2ChunkDescriptor> chunks;

  Map<String, dynamic> toMap() => {
    'hash': hash,
    'counts': counts,
    'chunks': [for (final chunk in chunks) chunk.toMap()],
  };

  factory SyncV2AreaManifest.fromMap(Map<String, dynamic> map) {
    final rawChunks = map['chunks'];
    final rawCounts = map['counts'];
    if (rawChunks is! List || rawCounts is! Map) {
      throw const FormatException('Manifesto de área incompleto.');
    }
    final chunks =
        rawChunks
            .map(
              (value) => SyncV2ChunkDescriptor.fromMap(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    if (chunks.isEmpty || chunks.length > 256) {
      throw const FormatException('Quantidade inválida de chunks.');
    }
    for (var index = 0; index < chunks.length; index++) {
      if (chunks[index].index != index) {
        throw const FormatException('Chunks do manifesto não são contíguos.');
      }
    }
    return SyncV2AreaManifest(
      hash: _requiredString(map, 'hash'),
      counts: {
        for (final entry in rawCounts.entries)
          entry.key.toString(): entry.value is int
              ? entry.value as int
              : _requiredInt(
                  Map<String, dynamic>.from(entry.value as Map),
                  'value',
                ),
      },
      chunks: chunks,
    );
  }
}

String canonicalHash(Object? value) {
  return sha256
      .convert(utf8.encode(jsonEncode(_canonicalize(value))))
      .toString();
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalize(value[key])};
  }
  if (value is List) {
    return value.map(_canonicalize).toList();
  }
  return value;
}

int _requiredInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('Campo "$key" inválido.');
  return value;
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Campo "$key" inválido.');
  }
  return value;
}
