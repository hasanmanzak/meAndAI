# v0.15.2 Distinct Test Intent and Meta-Test Boundaries

Date: 2026-07-26
Status: Implementation complete; PR validation and immutable publication pending
Feature: [FEAT-0053](../../../docs/features/FEAT-0053-v0152-distinct-test-intent/README.md)
Issue: [issue #133](https://github.com/hasanmanzak/meAndAI/issues/133)
Pull request: [PR #134](https://github.com/hasanmanzak/meAndAI/pull/134)

## Baseline

Immutable [v0.15.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.1)
is published at
[`c1a41d8fb633321ddf9725c1a00d829f006693a8`](https://github.com/hasanmanzak/meAndAI/commit/c1a41d8fb633321ddf9725c1a00d829f006693a8).
[PR #132](https://github.com/hasanmanzak/meAndAI/pull/132) and closed
[issue #131](https://github.com/hasanmanzak/meAndAI/issues/131) retain the
[FEAT-0052](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/README.md)
delivery and publication evidence.

## Accepted scope

- [DEC-0030](../../../docs/decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md)
  requires explicit nearest-sibling review and one of four relationship
  dispositions without creating a semantic detector or second registry.
- [TEST-0190](../../../docs/features/FEAT-0053-v0152-distinct-test-intent/test-cases.md#test-0190)
  remains in the existing role-boundary owner and uses inert declarative inputs.
- Contract-equivalent
  [TEST-0081](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0081)
  is superseded by canonical
  [TEST-0069](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0069),
  and [TEST-0082](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0082)
  is superseded by canonical
  [TEST-0070](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0070).
- Material marker, contention, ownership-change, and rerun fixtures remain; the
  source-row oracle is removed.
- Released capability definitions and consumer repositories remain unchanged.

## Current evidence

- The finite review covered all 23 canonical executable suite owners and proved
  exactly two duplicate identity pairs.
- [TEST-0190](../../../docs/features/FEAT-0053-v0152-distinct-test-intent/test-cases.md#test-0190)
  reached its final focused pass in 25.2 seconds after resolving the test-first
  harness findings and fresh-review scope, order, case, and operation-cost
  blockers.
- The retained
  [TEST-0070](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0070)
  AdoptionLifecycle shard passed in 202.0 seconds.
- The retained
  [TEST-0069](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0069)
  IntegrityManifestIssue shard passed in 152.2 seconds.
- The first final suite stopped after 1,587.9 seconds only because the exact
  self-consumer graph used 16,883 bytes against the nearly exhausted 16,384-byte
  path-inventory ceiling. [FIND-0299](../../../docs/features/FEAT-0053-v0152-distinct-test-intent/README.md#find-0299)
  records the measured 32,768-byte current-policy correction while preserving
  every independent graph bound and older immutable limit.
- The corrected canonical instruction-graph owner then passed in 195.6 seconds,
  including deterministic identity, exact N/N+1 aggregate and per-path limits,
  self-consumer evidence, two batch processes, and four blob requests.
- The exact reviewed commit
  [`dcd040b52ebcb8510568f2661814bb708d17f37f`](https://github.com/hasanmanzak/meAndAI/commit/dcd040b52ebcb8510568f2661814bb708d17f37f)
  passed all discovered protocol suites in 1,970.8 seconds. This is the final
  local full-suite authority; the following commit adds only this durable
  result and will be validated by the hosted exact-head gate.

## Continuation

1. Complete the exact-head hosted gate for
   [PR #134](https://github.com/hasanmanzak/meAndAI/pull/134).
2. Publish the owned PR and immutable `v0.15.2` release, verify its exact
   assets and current-authority evidence, close
   [issue #133](https://github.com/hasanmanzak/meAndAI/issues/133), and clean the owned
   branch.
3. Reevaluate [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
   against the completed architecture and deliver one separately measured
   runtime reduction.
