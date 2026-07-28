# FEAT-0027 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0123` <a name="test-0123"></a> | [SUBF-0049](README.md#subf-0049) | Classify real Git diffs containing Markdown-only changes, sensitive modifications, deletions, renames, more than 300 paths, malformed/unavailable commit identities, empty diffs, pull-request/push events, manual dispatch, and merge-queue events. | Markdown-only evidence selects `WindowsNative`; every sensitive or ambiguous case selects `Full`; rename classification sees both paths; no classifier error silently narrows coverage. | Unit / integration / boundary / negative | Passing | `tests/capabilities/windows-validation/windows-validation-profile.tests.ps1` |
| `TEST-0124` <a name="test-0124"></a> | [SUBF-0049](README.md#subf-0049), [SUBF-0050](README.md#subf-0050) | Inspect ordinary, superseded-PR, main, manual, merge-queue, and post-publication workflow routing; execute the focused Windows profile, vary partial evidence output, and verify that the Windows job timeout covers the measured serial `Full` budget. | One Linux full job and one actual Windows job retain stable identities; only same-PR runs are cancellable; release-only dispatch is isolated; `WindowsNative` covers the declared native contracts and emits exactly compatibility-only evidence; `Full` retains canonical authority and a bounded upper limit sufficient for its measured serial execution. | Structure / hosted integration / compatibility / negative | Passing locally with the 60-minute correction; replacement Windows hosted run pending | `tests/protocol.tests.ps1`, `tests/capabilities/initial-adoption/quick-adoption.tests.ps1`, `tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`, and `.github/workflows/protocol-tests.yml` |

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
- A 60-minute bound on the single Windows job, with Linux remaining at 20
  minutes and post-publication remaining at 5 minutes.

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
| 2026-07-28 | [`39d6a0790e967293249dff2e32f5197a149added`](https://github.com/hasanmanzak/meAndAI/commit/39d6a0790e967293249dff2e32f5197a149added) | GitHub-hosted Ubuntu / Windows PowerShell 5.1 expected red | [Protocol validation run `30366875189`](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189) | `Full` selected correctly; [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266387) passed and the release verifier skipped as expected, while the [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266379) was canceled at its exact 35-minute whole-job ceiling with no authoritative test verdict. [FIND-0366](../FEAT-0060-any-consumer-governance-cli/README.md#find-0366) owns the repeat of historical [FIND-0160](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160). |
| 2026-07-28 | Test-first correction working tree | PowerShell 7 | `tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Expected red in 201 s with only `TEST-0124 Windows full validation timeout does not cover the measured serial-suite budget` while the workflow remained at 35 minutes; passed in 176.9 s after only the Windows ceiling changed to 60, with Linux 20 and post-publication 5 unchanged. |
| 2026-07-28 | Correction candidate working tree | PowerShell 7 / Windows PowerShell 5.1 / actionlint v1.7.12 | Selector owner, Windows-native streaming owner, both workflow definitions, and `tests/protocol.tests.ps1 -StructureOnly` | [TEST-0123](#test-0123) passed in 17.9 s; the unchanged [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) owner passed in 10 / 13 s; checksummed actionlint passed; candidate StructureOnly passed in 187.8 / 279 s with protocol-governance observations of 185685 / 276067 ms. [FIND-0366](../FEAT-0060-any-consumer-governance-cli/README.md#find-0366) remains pending exact-commit and hosted evidence. |
