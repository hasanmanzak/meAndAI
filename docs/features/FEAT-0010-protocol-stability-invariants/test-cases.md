# FEAT-0010 Test Scenarios

Implementations:

- [Quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1)
- [Updater adapter fixtures](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1)
- [Repository validator](../../../tests/protocol.tests.ps1)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0052` | `SUBF-0021` | Complete an adoption, fail between readiness and issue reconciliation, then rerun with the persisted PR body. Mutate PR metadata during Codex and before publication. | Completed marker/head and issue state converge idempotently; stale or changed live identity blocks before publication. | State transition / integration | Passed | Mock GitHub CLI plus bare remote |
| `TEST-0053` | `SUBF-0021` | Rename the protected updater workflow, case-move that workflow, or introduce a case-variant credential path while leaving an allowed-looking tree. | Rename source/destination paths and the ordinal credential path policy are evaluated; publication blocks. | Path policy / real Git | Passed | Staged name-status and local-Codex fixtures |
| `TEST-0054` | `SUBF-0021` | Return zero, one, or multiple unseen runs for the exact dispatched commit alongside older matching runs. | Exactly one unseen run is awaited; zero waits and multiple candidates block as ambiguous. | Concurrency / boundary | Passed | Mock Actions inventory |
| `TEST-0055` | `SUBF-0021` | Run history checks in complete, shallow, reset/reflog, and unavailable-remote-history repositories. | Reachable and reflog evidence blocks exposed credentials; shallow state fails closed and documentation makes no remote-completeness claim. | Security / real Git | Passed | Temporary Git repositories |
| `TEST-0056` | `SUBF-0022` | Request a canonical tag with no release, mutable release state, wrong tag metadata, or a published immutable release. | Source retrieval/execution and updater target selection accept only the exact immutable release. | Supply chain / structural | Passed | Mock GitHub Release API and workflow assertions |
| `TEST-0057` | `SUBF-0022` | Present draft/non-draft, missing-manifest, wrong-tree, moved-head, and post-create-race adoption proposals. | Only one exact live pending draft is retained; every mismatch blocks without mutation. | Ownership / integration | Passed | Bootstrap adapter fixture |
| `TEST-0058` | `SUBF-0022` | Change replacement identity after initial revalidation or during old PR cleanup, including failed compensation. | Old cleanup stops or reopens the old PR; ambiguous replacement never leaves silent supersession success. | Recovery / concurrency | Passed | Updater race fixture |
| `TEST-0059` | `SUBF-0023` | Inspect canonical indexes, release records, validator scope/cohesion, active pins, timeout, routing, templates, memory, and FIND-0048. | Required surfaces derive from canonical state, nested worktrees are excluded, validators stay bounded, and release evidence avoids self-reference. | Structural / governance | Passed | Repository validator |

## Required coverage

- Proposed-to-completed proposal state and rerun recovery.
- Live pre/post mutation identity and exact draft state.
- Source-and-destination rename provenance with ordinal paths.
- Dispatch-specific workflow-run uniqueness.
- Immutable-release source and update-target authority.
- Replacement continuity and compensation.
- Reachable/reflog/shallow credential-history capability boundaries.
- Canonical-index, release-evidence, timeout, routing, and memory consistency.
- Bounded bootstrap-validator responsibilities, canonical active pins, and
  external post-publication commit evidence.
- Regression of existing lifecycle, updater, quick-adoption, and protocol suites.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.7.3` before FEAT-0010 | Windows, Ubuntu, GitGuardian | Existing `TEST-0001` through `TEST-0051` delivery evidence | Pass |
| 2026-07-15 | FEAT-0010 test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red: launcher made no PR body transition, then the exact rerun failed because the persisted marker head no longer matched the live branch |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass through `TEST-0056` in 115 seconds; bounded fixture corrections are described in the feature review |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | `tests/capabilities-bootstrap-adapter.tests.ps1` and `tests/protocol-update-adapter.tests.ps1` | Pass through `TEST-0058` |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` | Pass, including `TEST-0059` |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | Bounded fresh-diff parse, credential-pattern, active-pin, function-cohesion, and nested-inventory checks | Three derivative risks found and resolved as `FIND-0089` through `FIND-0091`; parent and structure confirmations followed |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All lifecycle, updater, and launcher child suites passed; parent then reported only the over-broad `TEST-0006` active-pin predicate and its genuinely stale hidden bootstrap default |
| 2026-07-15 | FEAT-0010 working tree | Windows PowerShell 5.1 | `git diff --check`; `tests/protocol.tests.ps1 -StructureOnly` | Pass after the minimal active-pin correction, including `TEST-0059`; hosted matrix CI pending |
| 2026-07-15 | PR #35 commit `01d023b` | GitHub-hosted Ubuntu | [Protocol validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29441402804) | Expected portability blocker: `TEST-0055` fixture produced an empty `AbsoluteUri` from a POSIX path; resolved as `FIND-0092` |
| 2026-07-15 | PR #35 working tree after `FIND-0092` | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1`; `tests/protocol.tests.ps1 -StructureOnly` | Pass through `TEST-0059` in 119 seconds; hosted confirmation followed |
| 2026-07-15 | PR #35 commit `553d9e5` | GitHub-hosted Ubuntu, Windows, and GitGuardian | [Corrected protocol validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29441953315) | Pass: Ubuntu 1m05s, Windows 2m34s, and secret scan |
