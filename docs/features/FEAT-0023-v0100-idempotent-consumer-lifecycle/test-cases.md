# FEAT-0023 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0111` | `SUBF-0039` | Discover an update with no prepared issue, repeat discovery, supersede it with a newer immutable target, then merge the replacement. | Exactly one marker-owned issue per target is created or reused; the pull request has one exact tracking line and backlink; supersession and merge close only their owned issue after branch convergence. | Integration / state transition | Passed | Mock GitHub CLI and Git fixture |
| `TEST-0112` | `SUBF-0040` | Present a merged installing update from a legacy workflow with missing or placeholder tracking evidence, then vary repository, marker, head, base, paths, gitlink, and ambiguity. | The one exact qualified proposal is repaired and finalized idempotently; every foreign, partial, moved, or ambiguous state fails before mutation. | Integration / compatibility / negative | Passed | Mock GitHub CLI and Git fixture |
| `TEST-0113` | `SUBF-0040` | Re-run the latest launcher for an unadopted repository, current complete installation, older same-major complete installation, partial/drifted installation, newer installation, and cross-major installation. | Initial adoption remains unchanged; current is a successful no-op; older same-major dispatches the installed updater without rewriting the seed; every unsupported state fails before secrets or managed repository-content mutation. | Integration / routing / negative | Passed | Temporary repositories and mock GitHub CLI fixture |
| `TEST-0114` | `SUBF-0041` | Validate the prospective reusable consumer templates and common-protocol authority rule. | Current templates use the gitlink and `.ai/protocol/VERSION` as the only live pin and contain no literal current tag/SHA. | Structural / prospective compatibility | Passed; historical-fixture overclaim corrected by [TEST-0119](../FEAT-0026-v0103-v092-live-pin-migration/test-cases.md) | Repository structure |

## Correction recorded 2026-07-17

The original TEST-0114 description claimed a synthetic consumer across two
same-major gitlinks. Its executable assertions inspected only five current
templates and the protocol wording; they did not instantiate the v0.9.2
consumer shape. [FEAT-0026](../FEAT-0026-v0103-v092-live-pin-migration/README.md)
adds that missing historical bridge and negative evidence as TEST-0119 and
TEST-0120. The prospective template assertions remain valid.

## Required coverage

- Marker-owned issue creation, reuse, duplicate/foreign rejection, label
  creation-only behavior, pull-request backlink, and exact tracking line.
- Replacement-first supersession ordering and issue closure evidence.
- New and legacy managed merge finalization with idempotent recovery.
- Complete installation footprint, installed immutable release mapping, workflow
  and script blob equality, no-op, compatible dispatch, and fail-closed states.
- No secret overwrite when repository secrets already exist.
- Version-neutral memory, documentation, prompt, and test templates.
- PowerShell parsing, workflow permissions/routing, scenario ownership, and
  complete repository validation.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | Baseline `v0.9.7` | Windows PowerShell 5.1 | Complete repository suite from FEAT-0022 | Green published baseline; see [issue #61](https://github.com/hasanmanzak/meAndAI/issues/61). |
| 2026-07-17 | Expected-red working tree | Windows PowerShell 5.1 | Focused FEAT-0023 fixtures | Failed at the five intended `TEST-0114` assertions before implementation. |
| 2026-07-17 | Final working tree | Windows PowerShell 5.1 | `tests/protocol-update.tests.ps1`; `tests/managed-merge-finalization.tests.ps1`; `tests/quick-adoption.tests.ps1`; `tests/capabilities-bootstrap.tests.ps1` | Passed. TEST-0111 and TEST-0112 passed in their focused suites; TEST-0113 and all existing launcher scenarios passed in 448.3 seconds; the bootstrap suite passed in 149.7 seconds. Git-heavy Windows runs used the allowed host context after the sandbox produced the environmental `signal pipe / Win32 error 5`. |
| 2026-07-17 | Pre-publication commit `316e1fd` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 615.1 seconds; all discovered suites and declared scenarios through `TEST-0114` passed, including current no-op, installed-updater dispatch, automatic issue lifecycle, legacy repair, and version-neutral template validation. |
