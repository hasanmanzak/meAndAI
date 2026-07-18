# FEAT-0027 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0123` | `SUBF-0049` | Classify real Git diffs containing Markdown-only changes, sensitive modifications, deletions, renames, more than 300 paths, malformed/unavailable commit identities, empty diffs, pull-request/push events, manual dispatch, and merge-queue events. | Markdown-only evidence selects `WindowsNative`; every sensitive or ambiguous case selects `Full`; rename classification sees both paths; no classifier error silently narrows coverage. | Unit / integration / boundary / negative | Passing | `tests/windows-validation-profile.tests.ps1` |
| `TEST-0124` | `SUBF-0049`, `SUBF-0050` | Inspect ordinary, superseded-PR, main, manual, merge-queue, and post-publication workflow routing; execute the focused Windows profile and vary partial evidence output. | One Linux full job and one actual Windows job retain stable identities; only same-PR runs are cancellable; release-only dispatch is isolated; `WindowsNative` covers the declared native contracts and emits exactly compatibility-only evidence; `Full` retains canonical authority. | Structure / hosted integration / compatibility / negative | Passing locally; hosted pending | `tests/protocol.tests.ps1`, `tests/quick-adoption.tests.ps1`, `tests/quick-adoption-streaming.tests.ps1`, and `.github/workflows/protocol-tests.yml` |

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
