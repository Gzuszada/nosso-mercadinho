export type CasDecision = 'commit' | 'conflict' | 'alreadyCommitted';

export interface CasState {
  currentGeneration: number;
  currentManifestHash: string | null;
  candidateAlreadyCommitted: boolean;
}

export function decideCas(
  state: CasState,
  baseGeneration: number,
  expectedManifestHash: string | null,
): CasDecision {
  if (state.candidateAlreadyCommitted) {
    return 'alreadyCommitted';
  }
  if (
    state.currentGeneration === baseGeneration &&
    state.currentManifestHash === expectedManifestHash
  ) {
    return 'commit';
  }
  return 'conflict';
}
