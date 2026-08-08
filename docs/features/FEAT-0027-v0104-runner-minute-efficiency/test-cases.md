# FEAT-0027 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0123` <a name="test-0123"></a> | [SUBF-0049](README.md#subf-0049) | Classify real Git diffs containing Markdown-only changes, sensitive modifications, deletions, renames, more than 300 paths, malformed/unavailable commit identities, empty diffs, pull-request/push events, manual dispatch, and merge-queue events. | Markdown-only evidence selects `WindowsNative`; every sensitive or ambiguous case selects `Full`; rename classification sees both paths; no classifier error silently narrows coverage. | Unit / integration / boundary / negative | Passing | `tests/capabilities/windows-validation/windows-validation-profile.tests.ps1` |
| `TEST-0124` <a name="test-0124"></a> | [SUBF-0049](README.md#subf-0049), [SUBF-0050](README.md#subf-0050) | Inspect ordinary, superseded-PR, main, manual, merge-queue, and post-publication workflow routing; execute the focused Windows profile, vary partial evidence output, and verify that the Linux and Windows job timeout bounds cover their measured serial `Full` budgets. | One Linux full job and one actual Windows job retain stable identities; only same-PR runs are cancellable; release-only dispatch is isolated; `WindowsNative` covers the declared native contracts and emits exactly compatibility-only evidence; `Full` retains canonical authority; Linux is bounded at 25 minutes, Windows at 55 minutes, and post-publication at 5 minutes. | Structure / hosted integration / compatibility / negative | Passing | `tests/protocol.tests.ps1`, `tests/capabilities/initial-adoption/quick-adoption.tests.ps1`, `tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`, and `.github/workflows/protocol-tests.yml` |

## Required coverage

- One ordinary Windows runner and no matrix or aggregate-only runner.
- Stable `Validate on windows-latest` identity on the real Windows job.
- Exact Git base/head comparison with rename detection disabled.
- Project-neutral, PowerShell, workflow, command-wrapper, migration, deletion,
  rename, empty, oversized, malformed, and unavailable diff cases.
- Manual and merge-queue full validation; post-publication isolation.
- Same-PR-only cancellation and non-PR evidence isolation.
- `.cmd`/`ComSpec`, native sandbox fallback/failure/residue, process-tree
  cancellation, and junction/reparse containment on Windows PowerShell 5.1.
- Compatibility-only partial result with no canonical scenario leakage.
- Full PowerShell 5.1 escape hatch and unchanged Linux canonical full suite.
- A 55-minute bound on the single Windows job, a 25-minute bound on Linux,
  and a 5-minute bound on post-publication.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-18 | Immutable v0.10.3 baseline | GitHub-hosted Ubuntu/Windows | Run 29587912782 attempt 4 and main run 29621701869 | Green; ordinary PR used one Linux job, eight Windows jobs, and one Ubuntu aggregate before FEAT-0027 |
| 2026-07-18 | Test-first working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` | Expected red: 23 missing/new-topology assertions against the v0.10.3 matrix |
| 2026-07-18 | Implementation working tree | Windows PowerShell 5.1 | `tests/windows-validation-profile.tests.ps1` | Passed in 13.5 seconds: documentation/push native route plus sensitive, deletion, rename, empty, oversized, malformed, unavailable, manual, and merge-queue full routes |
| 2026-07-18 | Implementation working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` | Passed in 2.4 seconds |
| 2026-07-18 | Implementation working tree outside the restricted Git signal-pipe sandbox | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -ExecutionProfile WindowsNative` | Passed in 187.1 seconds; both child suites and root emitted compatibility-only evidence |
| 2026-07-18 | Implementation working tree outside the restricted Git signal-pipe sandbox | Windows PowerShell 5.1 | `tests/protocol.tests.ps1` | Passed in 577.7 seconds after the expected-red structure gate and two narrowly corrected fixture/document-state defects; every canonical suite passed once |
| 2026-07-18 | Implementation working tree | actionlint 1.7.12, checksummed Windows amd64 binary | `actionlint -shellcheck= -pyflakes= .github/workflows/protocol-tests.yml templates/project/.github/workflows/meandai-protocol-update.yml` | Passed for both repository and consumer workflow definitions |
| 2026-07-18 | [`cf818e5`](https://github.com/hasanmanzak/meAndAI/commit/cf818e5dbed086960f3c6301cbe6c15242db6d88) | GitHub-hosted Windows PowerShell 5.1 expected red | [Protocol validation run 29653339317](https://github.com/hasanmanzak/meAndAI/actions/runs/29653339317) | `Full` was selected correctly; capabilities and protocol-update, including [TEST-0126](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126), passed, then the still-running quick-adoption family was canceled at the stale 20-minute job limit without a test failure ([FIND-0160](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160)) |
| 2026-07-18 | Test-first correction working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` | Expected red in 2.6 seconds with one failure while the Windows limit remained 20 minutes; passed in 2.6 seconds after the Windows-only 35-minute bound, with Linux 20 and post-publication 5 unchanged |
| 2026-08-04 | Linux timeout-bound test-first working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Expected red in 479.8 seconds with exactly one timeout-bound failure while the workflow retained its prior 20-minute Linux bound; all preceding assertions in the protocol-governance owner passed |
| 2026-08-04 | Linux timeout-bound green working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Passed in 466.6 seconds after changing only ordinary Linux validation from 20 to 25 minutes; Windows remained 35, post-publication remained 5, and job identity, routing, cancellation, profiles, and scenario ownership were unchanged |
| 2026-08-04 | Windows timeout-bound second test-first working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Expected red in 454.0 seconds with exactly one Windows timeout-bound failure while the workflow retained 35 minutes; all preceding assertions passed |
| 2026-08-04 | Windows timeout-bound green working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Passed in 457.0 seconds after changing only ordinary Windows validation from 35 to 45 minutes; Linux remained 25, post-publication remained 5, and job identity, routing, cancellation, profiles, coverage, and scenario ownership were unchanged |
| 2026-08-04 | Exact correction head recorded in the canonical owning finding | GitHub-hosted Ubuntu and Windows | Exact replacement hosted validation | Passed: Ubuntu `11m50s`, Windows `44m13s`, publication verification correctly skipped; Linux 25, Windows 45, and post-publication 5 retained unchanged job identity, topology, routing, cancellation, profiles, and coverage |
| 2026-08-04 | Exact A-COMPLETE record-delivery closure recorded in the canonical owning finding | GitHub-hosted Ubuntu and Windows | Exact closure hosted validation | Ubuntu passed in `19m52s`; Windows reached the exact 45-minute job ceiling after all emitted child-suite evidence succeeded, while root Full/final harness evidence was not emitted and the three subsequent package/tree steps did not start |
| 2026-08-04 | Windows timeout-bound third test-first working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Expected red in `482.2s` with exactly one Windows timeout-bound failure while the workflow retained 45 minutes; all preceding assertions passed |
| 2026-08-04 | Windows 45-to-55 timeout-bound green working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Passed in `447.4s` after changing only ordinary Windows validation from 45 to 55 minutes; Linux remained 25, post-publication remained 5, and job identity, routing, cancellation, profiles, coverage, invocation count, and scenario ownership were unchanged |
