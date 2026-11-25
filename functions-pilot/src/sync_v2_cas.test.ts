import assert from 'node:assert/strict';
import {describe, it} from 'node:test';

import {decideCas} from './sync_v2_cas.js';
import {hashManifest} from './sync_v2.js';

describe('sync v2 compare-and-swap', () => {
  it('commits when generation and expected manifest match', () => {
    assert.equal(
      decideCas(
        {
          currentGeneration: 7,
          currentManifestHash: 'hash-7',
          candidateAlreadyCommitted: false,
        },
        7,
        'hash-7',
      ),
      'commit',
    );
  });

  it('rejects a stale generation as a conflict', () => {
    assert.equal(
      decideCas(
        {
          currentGeneration: 8,
          currentManifestHash: 'hash-8',
          candidateAlreadyCommitted: false,
        },
        7,
        'hash-7',
      ),
      'conflict',
    );
  });

  it('rejects a mismatched manifest even when generation matches', () => {
    assert.equal(
      decideCas(
        {
          currentGeneration: 7,
          currentManifestHash: 'hash-7',
          candidateAlreadyCommitted: false,
        },
        7,
        'other-hash',
      ),
      'conflict',
    );
  });

  it('mantém o hash canônico do manifesto igual ao vetor Dart', () => {
    const manifest = {
      protocolVersion: 2,
      publicationId: 'publication-1',
      baseGeneration: 3,
      authorUid: 'owner-uid',
      authorName: 'Owner',
      deviceId: 'device-1',
      createdAt: '2026-11-24T12:00:00.000Z',
      areas: {
        catalog: {
          hash: 'area-hash',
          counts: {products: 1},
          chunks: [
            {
              index: 0,
              path:
                'syncV2/casa/candidates/publication-1/areas/catalog/parts/0',
              hash: 'chunk-hash',
              count: 1,
            },
          ],
        },
      },
    };
    assert.equal(
      hashManifest(manifest),
      '1e1fdd38cd4db67cbddfb15a0537a42da9e8c82aaf36ff7be9b1739067893307',
    );
  });

  it('treats a retry of a committed candidate as idempotent', () => {
    assert.equal(
      decideCas(
        {
          currentGeneration: 8,
          currentManifestHash: 'hash-8',
          candidateAlreadyCommitted: true,
        },
        7,
        'hash-7',
      ),
      'alreadyCommitted',
    );
  });
});
