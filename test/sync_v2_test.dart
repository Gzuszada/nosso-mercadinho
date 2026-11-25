import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/sync_v2_candidate.dart';
import 'package:mercado/features/cloud/data/sync_v2_manifest.dart';

void main() {
  group('sync v2 manifest', () {
    test('hash canônico independe da ordem das chaves', () {
      expect(
        canonicalHash({
          'b': 2,
          'a': {'y': 1, 'x': 2},
        }),
        canonicalHash({
          'a': {'x': 2, 'y': 1},
          'b': 2,
        }),
      );
    });

    test('manifesto preserva a ordem contígua dos chunks', () {
      final manifest = SyncV2Manifest(
        publicationId: 'publication',
        baseGeneration: 3,
        authorUid: 'uid',
        authorName: 'Pessoa',
        deviceId: 'device',
        areas: {
          'shopping': SyncV2AreaManifest(
            hash: 'hash',
            counts: {'rows': 1},
            chunks: [
              SyncV2ChunkDescriptor(
                index: 0,
                path: 'path/0',
                hash: 'chunk-hash',
                count: 1,
              ),
            ],
          ),
        },
        createdAt: DateTime.utc(2026, 11, 24),
      );

      final decoded = SyncV2Manifest.fromMap(manifest.toMap());
      expect(decoded.publicationId, 'publication');
      expect(decoded.baseGeneration, 3);
      expect(decoded.areas['shopping']!.chunks.single.index, 0);
      expect(decoded.areas['shopping']!.counts['rows'], 1);
      expect(decoded.snapshotHash, manifest.snapshotHash);
    });

    test('hash do manifesto usa o mesmo vetor do backend', () {
      final manifest = SyncV2Manifest(
        publicationId: 'publication-1',
        baseGeneration: 3,
        authorUid: 'owner-uid',
        authorName: 'Owner',
        deviceId: 'device-1',
        areas: {
          'catalog': SyncV2AreaManifest(
            hash: 'area-hash',
            counts: {'products': 1},
            chunks: [
              SyncV2ChunkDescriptor(
                index: 0,
                path: 'syncV2/casa/candidates/publication-1/areas/catalog/parts/0',
                hash: 'chunk-hash',
                count: 1,
              ),
            ],
          ),
        },
        createdAt: DateTime.utc(2026, 11, 24, 12),
      );

      expect(
        manifest.snapshotHash,
        '1e1fdd38cd4db67cbddfb15a0537a42da9e8c82aaf36ff7be9b1739067893307',
      );
    });

    test('hash de área ignora o caminho específico da publication', () {
      final first = SyncV2AreaManifest(
        hash: canonicalHash([
          {'index': 0, 'hash': 'content', 'count': 1},
        ]),
        counts: {'rows': 1},
        chunks: [
          SyncV2ChunkDescriptor(
            index: 0,
            path: 'publication-a/path/0',
            hash: 'content',
            count: 1,
          ),
        ],
      );
      final second = SyncV2AreaManifest(
        hash: first.hash,
        counts: first.counts,
        chunks: [
          SyncV2ChunkDescriptor(
            index: 0,
            path: 'publication-b/path/0',
            hash: 'content',
            count: 1,
          ),
        ],
      );

      expect(first.hash, second.hash);
    });
  });
}
