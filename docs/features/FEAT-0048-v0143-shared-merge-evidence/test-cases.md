# FEAT-0048 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0179` <a name="test-0179"></a> | [SUBF-0092](README.md#subf-0092) | Resolve empty, single exact, duplicate, wrong-event, missing-property, null, uppercase, short, and non-string merged-event collections | Exactly one lowercase 40-character `merged.commit_id` is returned; every absent, ambiguous, malformed, or wrong-case collection throws without transport or mutation dependencies | Pure resolver / boundary / negative | Passed locally on PowerShell 7 and Windows PowerShell 5.1 | [Consumer-update pure resolver suite](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1) |
| `TEST-0180` <a name="test-0180"></a> | [SUBF-0092](README.md#subf-0092) | Run publication verification with an API-2026 pull-request payload that omits `merge_commit_sha`, place the exact merged event beyond page 1, vary zero/duplicate/malformed event evidence, inventory every API-2026 production reader, and inspect the current-verifier/detached-target workflow lifecycle | Complete pagination plus the shared resolver proves the exact released commit; negative event sets fail closed; no API-2026 production reader accesses the removed PR field; API-2022 callers remain allowed; historical verification executes exact current authority from a clean detached immutable target and removes it in `finally` | Publication integration / pagination / structural compatibility | Passed locally on PowerShell 7 and Windows PowerShell 5.1, including the corrected historical-authority lifecycle; live v0.14.2 rerun pending publication | [Publication-evidence suite](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) |

## Required coverage

- Pure exact success and zero, duplicate, malformed, wrong-case, null, and
  wrong-event negatives.
- API-2026 PR payload with the removed property absent.
- Exact merged event after 100 unrelated first-page events.
- Publication exact-commit comparison and fail-closed negative evidence.
- Existing updater [TEST-0155](../FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md#test-0155)
  pagination, containment, mutation ordering, and idempotency.
- Version-qualified raw-field inventory across production scripts, modules,
  verifier, and managed workflow YAML that preserves API-2022 compatibility.
- Exact current workflow authority, detached immutable target worktree, target
  working directory, absolute current verifier path, and unconditional cleanup.
- Exact 4,096-edge boundary and 4,097-edge rejection, plus the ordinary
  2,061-edge meAndAI candidate self-consumer graph.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-24 | Immutable `v0.14.2` commit [`671f678c8811ea715caceaabf2fd73b0933e8515`](https://github.com/hasanmanzak/meAndAI/commit/671f678c8811ea715caceaabf2fd73b0933e8515) | GitHub-hosted Ubuntu / API `2026-03-10` | [Post-publication run 30104971376](https://github.com/hasanmanzak/meAndAI/actions/runs/30104971376) | Expected red: [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) fails because the verifier directly reads the removed PR response field |
| 2026-07-24 | `v0.14.3` test-first working tree before the production correction | PowerShell 7 and Windows PowerShell 5.1 | `protocol-update.tests.ps1 -PureResolverOnly` | Expected red: [TEST-0179](#test-0179) reported the missing shared resolver |
| 2026-07-24 | `v0.14.3` reviewed working tree | PowerShell 7 and Windows PowerShell 5.1 | `protocol-update.tests.ps1` | Passed all declared consumer-update scenarios, including [TEST-0179](#test-0179) and existing [TEST-0155](../FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md#test-0155) |
| 2026-07-24 | `v0.14.3` reviewed working tree | PowerShell 7 and Windows PowerShell 5.1 | `post-publication-evidence.tests.ps1` | Passed [TEST-0180](#test-0180), including second-page success and missing, duplicate, malformed, and wrong-commit negatives |
| 2026-07-24 | `v0.14.3` reviewed working tree | PowerShell 7 and Windows PowerShell 5.1 | `managed-merge-finalization.tests.ps1` | Passed existing [TEST-0155](../FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md#test-0155) without changing containment, finalization, or cleanup semantics |
| 2026-07-24 | `v0.14.3` reviewed working tree | PowerShell 7 | `tests/protocol.tests.ps1 -StructureOnly` | Passed the complete structure contract after reconciling current-version and record-registry surfaces |
| 2026-07-24 | `v0.14.3` reviewed working tree | PowerShell 7 | `quick-adoption.tests.ps1 -Shard RepositoryRoutes` | Passed current v0.14.3, legacy v0.9.2, and future v0.14.4 repository routes after correcting the release-fixture expectation exposed by the aggregate run |
| 2026-07-24 | [`859cda431e6d429928afbe9a7c49bedc5eca7296`](https://github.com/hasanmanzak/meAndAI/commit/859cda431e6d429928afbe9a7c49bedc5eca7296) | GitHub-hosted Ubuntu and Windows | [PR run 30111807614](https://github.com/hasanmanzak/meAndAI/actions/runs/30111807614) | Expected red follow-up: both jobs reached the same [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) 2,048-edge capacity failure; no billing or quota warning occurred |
| 2026-07-24 | Corrected `v0.14.3` candidate tree | PowerShell 7 / Windows PowerShell 5.1 | `instruction-graph-discovery.tests.ps1` | Passed [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151), [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152), and [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) in 103.8 / 180.1 seconds with exact 4,096/4,097 boundary evidence and the ordinary 2,061-edge self-consumer graph |
| 2026-07-24 | Corrected `v0.14.3` candidate tree | PowerShell 7 / Windows PowerShell 5.1 | `post-publication-evidence.tests.ps1` | Passed [TEST-0180](#test-0180) in 74.6 / 133.2 seconds with current verifier authority, detached immutable target, and unconditional cleanup source contract |
| 2026-07-24 | Corrected `v0.14.3` candidate tree | PowerShell 7 | `tests/protocol.tests.ps1 -StructureOnly` | Passed the complete discovered structure contract in 77.5 seconds after the hosted blocker corrections |
| 2026-07-24 | Immutable `v0.14.3` commit [`2d6cfc27418209c26cf9c27225c37938bac14dd9`](https://github.com/hasanmanzak/meAndAI/commit/2d6cfc27418209c26cf9c27225c37938bac14dd9) | GitHub-hosted Ubuntu / API `2026-03-10` | [Post-publication run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612) | Expected red follow-up: real `Invoke-RestMethod` returned one unenumerated top-level array and the pagination adapter passed it as one nested event; correction moved to [TEST-0181](../FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181) |
