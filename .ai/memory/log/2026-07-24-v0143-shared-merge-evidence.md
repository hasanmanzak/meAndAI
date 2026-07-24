# v0.14.3 Shared API-2026 Merge Evidence

## Scope

- [FEAT-0048](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md)
- [BUG-0031 / issue #117](https://github.com/hasanmanzak/meAndAI/issues/117)
- [SUBF-0092](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md#subf-0092)
- [TEST-0179](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0179)
- [TEST-0180](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180)

## Current state

- The candidate protocol version is `0.14.3`; immutable
  [v0.14.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.2)
  targets commit [`671f678c8811ea715caceaabf2fd73b0933e8515`](https://github.com/hasanmanzak/meAndAI/commit/671f678c8811ea715caceaabf2fd73b0933e8515).
- The v0.14.2 post-publication gate failed in
  [run 30104971376](https://github.com/hasanmanzak/meAndAI/actions/runs/30104971376)
  because one verifier still read the API `2026-03-10` pull-request
  `merge_commit_sha` field removed by the provider.
- [FEAT-0038](../../../docs/features/FEAT-0038-v0127-api-safe-merge-finalization/README.md)
  had already established the correct evidence: exactly one paginated merged
  issue event with a lowercase 40-character `commit_id`. This correction is a
  `PropagationGap`, not a new design.
- The shared pure resolver belongs to the existing managed protocol-update
  module. Updater and publication-verifier transports retain their own
  pagination and caller-specific comparison or mutation boundaries.
- Consumer repositories and named-consumer fixtures remain outside this work.
- Focused resolver, updater, managed-finalization, publication, structure, and
  quick-adoption repository-route gates pass. The one local aggregate run
  exposed a stale future-release fixture expectation after the version bump;
  the exact current/legacy/future shard passes after its bounded correction.

## Continuation

1. Complete focused pure, updater-finalization, and publication-verifier tests
   on both supported PowerShell runtimes, then run structure and one final full
   validation after the bounded review.
2. Publish one reviewed pull request and immutable `v0.14.3` under
   [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117).
3. Rerun the failed v0.14.2 publication evidence with the corrected verifier;
   close [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) only
   after the corrected gate passes.
4. Delete only the exact owned branch after merge and verification.

## Boundaries

- Do not change API-2022 callers solely because they may still expose the old
  field under their pinned contract.
- Do not add a new managed release asset; reuse the already projected updater
  module.
- Do not combine the later prior-art and test-harness modularity mandate with
  this revision correction.
