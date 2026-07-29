# 2026-07-29 - Domain-vocabulary planning

## Current state

- [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169) merged the accepted
  architecture at
  [`a2be672b91cb41b88597c5123a0d5b0e9a54d34e`](https://github.com/hasanmanzak/meAndAI/commit/a2be672b91cb41b88597c5123a0d5b0e9a54d34e).
- Its tree equals the PR-head tree exactly and passed both stable jobs in
  [main run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).
- Gate 2 superseded the unimplemented mixed [SUBF-0142](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0142)
  boundary without reusing its stable identity.
- The [corrected maintainer directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
  authorizes only [SUBF-0152](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
  and [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220).
- The [infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847)
  additionally permits only the matching assertion in existing
  [TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).

## Authorized boundary

- Create a fresh BCL-only `MeAndAI.Protocol.Domain` assembly, its sole xUnit
  owner, and the side-by-side `MeAndAI.Protocol.slnx` root.
- Implement only exact rule identity/revision and SHA-256 values, closed
  execution-profile and outcome values, immutable `SurfaceSet`, and
  `ExecutionProfile`.
- Route only [TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
  through both existing stable workflow jobs without
  changing triggers, filters, job names, or the Operations solution.
- Begin Gate 3 with fresh expected-red tests; no preserved WIP source or green
  evidence is inherited.

## Continuing holds

[SUBF-0153](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153),
[SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143),
[SUBF-0144](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0144),
[SUBF-0154](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0154),
their tests, WIP extraction, publication, release, consumer mutation,
self-consumption authority transfer, and PowerShell retirement remain
unauthorized. Preserved commit
[`1873c98638ba4960734aadb188eb8c8d70b4bc52`](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52)
is an oracle only.

## Next exact action

Commit the reviewed Gate 1 and Gate 2 packet on a branch based on the exact
merged main commit. Then create
[TEST-0220](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
and the empty target project graph,
run a fresh locked restore, and retain an expected-red result caused only by
the deliberately absent production contracts before implementing them.
