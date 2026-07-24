# FEAT-0049 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0181` <a name="test-0181"></a> | [SUBF-0093](README.md#subf-0093) | Make the publication test transport emit each GitHub page as one unenumerated top-level `System.Object[]`, place the exact merge event on page 2, then exercise missing, duplicate, malformed, wrong-commit, null, and page-bound behavior through the real verifier entry point | The pre-fix pagination helper sees one nested array and fails; the corrected helper enumerates exact page items once, preserves bounds and null filtering, resolves one exact merge commit, and keeps every negative fail closed | Publication integration / PowerShell transport shape / regression | Passed locally on PowerShell 7 and Windows PowerShell 5.1 | [Publication-evidence suite](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) |

## Required coverage

- Real `Invoke-RestMethod` top-level JSON-array pipeline shape reproduced by
  the test double rather than by a verifier-only shortcut.
- Page-two exact merge-event success through the existing shared resolver.
- Missing, duplicate, malformed, wrong-commit, null, termination, and maximum-
  page behavior retained.
- PowerShell 7 and Windows PowerShell 5.1 execution.
- Existing API-2026 reader inventory and historical current-verifier authority
  lifecycle unchanged.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-24 | Immutable `v0.14.3` commit [`2d6cfc27418209c26cf9c27225c37938bac14dd9`](https://github.com/hasanmanzak/meAndAI/commit/2d6cfc27418209c26cf9c27225c37938bac14dd9) | GitHub-hosted Ubuntu / API `2026-03-10` | [Post-publication run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612) | Expected red: real page response remains one nested array and [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) reports no exact merged event |
| 2026-07-24 | Test-first `v0.14.4` working tree before the production correction | PowerShell 7 | `post-publication-evidence.tests.ps1` | Expected red in 59.9 seconds: 229 scenarios converged on the exact missing merged-event failure after the fixture began emitting real unenumerated arrays |
| 2026-07-24 | Corrected `v0.14.4` working tree | PowerShell 7 / Windows PowerShell 5.1 | `post-publication-evidence.tests.ps1` | Passed in 72.5 / 129.9 seconds with source-bound `TEST-0181`, exact two-page and `null` response evidence, bounded 100-page overflow rejection, and all existing publication negatives |
| 2026-07-24 | Corrected `v0.14.4` working tree | PowerShell 7 | `tests/protocol.tests.ps1 -StructureOnly` | Passed in 77.3 seconds after registering [BUG-0032](https://github.com/hasanmanzak/meAndAI/issues/119), separating post-publication closure from DoD, and reconciling current-version metadata |
| 2026-07-24 | Corrected `v0.14.4` working tree | PowerShell 7 / native local Git | `quick-adoption-bundle.tests.ps1`; `capabilities-bootstrap.tests.ps1`; `quick-adoption.tests.ps1 -Shard RepositoryRoutes` | Passed [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147), every declared bootstrap scenario including [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153), and the current/legacy/future repository routes in 167.7 seconds for the final shard; hidden managed-template pins and the two-asset runtime remain version-consistent |
