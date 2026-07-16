# FEAT-0006 Test Scenarios

Implementations: `tests/quick-adoption.tests.ps1` and the existing
repository suites.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0033` | `SUBF-0011` | Inspect the launcher and guide credential/source contracts. | Exact v0.6.0 source, fixed token/secret names, stdin-only secret transfer, redacted output, bounded dispatch, no merge, and PowerShell AST validity are enforced. | Structural / security boundary | Automated | Source assertions and AST parse |
| `TEST-0034` | `SUBF-0011` | Run in a clean populated consumer on its connected default branch. | Both secrets precede one workflow-only commit/push; the exact run succeeds; the application tree and history remain unchanged otherwise. | Real-Git integration | Automated | Mock GitHub API/CLI plus bare remote |
| `TEST-0035` | `SUBF-0012` | Run in a directory without its own Git repository or origin. | The launcher initializes `main`, creates a private owner/directory-name remote, pushes only the workflow, and leaves unrelated local files untracked. | Real-Git integration | Automated | Mock GitHub API/CLI plus bare remote |
| `TEST-0036` | `SUBF-0011` | Rerun an exact seed, resume after a selected-repository grant failure, then present seed drift. | Exact and empty-remote recovery create no duplicate commit or task; ambiguous state blocks before later mutation. | Negative / recovery | Automated | Integration fixtures |
| `TEST-0037` | `SUBF-0012` | Historical v0.6.0 Codex Cloud handoff; this behavior was removed by FEAT-0007. | Historical evidence remains attributable to v0.6.0 and the identifier is never reused for local Codex behavior. Active local behavior is covered by [TEST-0038 through TEST-0041](../FEAT-0007-local-codex-adoption/test-cases.md). | Historical documentation / handoff | Superseded (never reuse) | Historical v0.6.0 evidence only |

## Required coverage

- Success in an existing populated repository and a new local directory.
- Token confidentiality and tracked/history exposure failure.
- Exact source/tag/blob and workflow collision behavior.
- Repository/default-branch identity and dirty-state failure.
- Exact-seed rerun and partial-operation recovery.
- Historical bounded lifecycle dispatch and Codex Cloud delegation at v0.6.0;
  active local completion is owned by FEAT-0007 and its distinct TEST IDs.
- Regression of the v0.5 lifecycle and updater suites.

## Evidence

`TEST-0037` passed for the historical v0.6.0 behavior recorded below. FEAT-0007
then removed that behavior. Supersession preserves the evidence but permanently
retires the identifier from active executable assertions.

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.5.0` before FEAT-0006 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing `TEST-0001` through `TEST-0032` baseline |
| 2026-07-15 | FEAT-0006 pre-delivery working tree | Windows PowerShell 5.1, Turkish locale | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass: `TEST-0033` through `TEST-0037` |
| 2026-07-15 | FEAT-0006 pre-delivery working tree | Windows PowerShell 5.1, Turkish locale | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0037` in 99.5 seconds |
| 2026-07-15 | PR #20 commit `31563a3` | GitHub-hosted Ubuntu and Windows plus GitGuardian | [Protocol validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29413498953) | Pass: Ubuntu, Windows, and secret scan |
