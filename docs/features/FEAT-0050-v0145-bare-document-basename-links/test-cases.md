# FEAT-0050 Test Scenarios

Canonical executable ownership remains in the
[publication-evidence suite](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1).
The new scenario extends the existing [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176)
owner; it does not create a second validator or fixture framework.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0182` <a name="test-0182"></a> | [SUBF-0094](README.md#subf-0094) | Put a bare [AGENTS.md](../../../AGENTS.md) label in the canonical nested decision fixture, vary its target basename and case, and retain the existing directory-bearing wrong-target fixture | The exact bare basename passes only when the resolved target basename matches ordinally and any visible fragment agrees; a different or case-mismatched basename fails; directory-bearing labels still require exact resolved-path equality | Protocol contract / publication evidence / false-positive regression | Passed | [Publication-evidence owner](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) |

## Evidence log

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-25 | Immutable `v0.14.3` commit [`2d6cfc27418209c26cf9c27225c37938bac14dd9`](https://github.com/hasanmanzak/meAndAI/commit/2d6cfc27418209c26cf9c27225c37938bac14dd9) with current `v0.14.4` verifier authority | PowerShell 7 / detached exact-release worktree | `Verify-PostPublicationEvidence.ps1` for `v0.14.3` | Expected pre-implementation failure: the valid nested [AGENTS.md](../../../AGENTS.md) decision link was rejected as a visible-path target mismatch |
| 2026-07-25 | Test-first `v0.14.5` working tree before the production correction | PowerShell 7 | `post-publication-evidence.tests.ps1` | Expected red in 67.5 seconds with one `TEST-0182` failure at the exact bare-basename mismatch boundary |
| 2026-07-25 | Corrected `v0.14.5` working tree | PowerShell 7 / Windows PowerShell 5.1 | `post-publication-evidence.tests.ps1` | Passed in 72.2 / 126.3 seconds; exact basename and matching fragment accepted; wrong basename, case, fragment, `%2F`, and `%5C` rejected; all existing publication scenarios remained green |
| 2026-07-25 | Corrected `v0.14.5` working tree | PowerShell 7 | `tests/protocol.tests.ps1 -StructureOnly` | Passed in 75.9 seconds after registering [BUG-0033](https://github.com/hasanmanzak/meAndAI/issues/121), source-bound `TEST-0182`, complete feature evidence, and exact local links |
| 2026-07-25 | Corrected `v0.14.5` working tree | PowerShell 7 / native local Git | `quick-adoption-bundle.tests.ps1`; `capabilities-bootstrap.tests.ps1`; `quick-adoption.tests.ps1 -Shard RepositoryRoutes` | Passed in 21.9 / 274.1 / 183.6 seconds; bundle identity, current/legacy bootstrap dispatch, and current/legacy/future repository routes remain version-consistent |
