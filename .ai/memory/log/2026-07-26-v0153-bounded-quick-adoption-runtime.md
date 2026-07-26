# v0.15.3 Bounded Quick-Adoption Runtime Handoff

## Authority

- Feature: [FEAT-0054](../../../docs/features/FEAT-0054-v0153-bounded-quick-adoption-runtime/README.md)
- Delivery issue: [issue #135](https://github.com/hasanmanzak/meAndAI/issues/135)
- Parent task: [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
- Baseline: immutable [v0.15.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.2)
  at [`9bc12e3`](https://github.com/hasanmanzak/meAndAI/commit/9bc12e394725a86d29efb745cbdfa26407ffd3d2)

## Current contract

- Keep every credential containment and TOCTOU checkpoint.
- A successful scan executes exactly one shallow-repository query, one
  combined tracked/staged query, and one combined all-ref/reflog query for the
  two ordered canonical pathspecs.
- All seven [TEST-0107](../../../docs/features/FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
  inputs call the exact private production parser. Only
  `older` and `exact-floor` also execute the full launcher.
- Existing [TEST-0055](../../../docs/features/FEAT-0010-protocol-stability-invariants/test-cases.md#test-0055),
  [TEST-0107](../../../docs/features/FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107),
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159),
  and [TEST-0160](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0160)
  identities remain the
  canonical authorities; no scenario, capability, framework, or consumer
  asset is added.
- Deterministic operation counts gate closure. Elapsed time is observational.

## Verification state

- Test-first credential probe: expected red at five processes versus maximum
  three.
- Focused Windows PowerShell 5.1 ContractsPreflight: passing after correction.
- Focused Windows PowerShell 7 ContractsPreflight: passing after correction.
- [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158),
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159),
  and [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162)
  operation-contract owner: passing.
- Final suite, hosted PR checks, merge, release, and post-publication evidence:
  pending.

## Safe continuation

Finish only the bounded diff review, version/link validation, one final full
suite, ordinary PR validation, immutable v0.15.3 publication, external
verification, and exact owned-branch cleanup. Do not reopen the other five
potential direct-contract families or add another runtime-hardening pass in
this delivery.
