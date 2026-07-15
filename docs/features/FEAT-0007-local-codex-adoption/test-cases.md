# FEAT-0007 Test Scenarios

Test implementation: [`tests/quick-adoption.tests.ps1`](../../../tests/quick-adoption.tests.ps1)
and the existing repository suites.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0038` | `SUBF-0013` | Inspect the local runner, fallback, prompt, timeout, and permission boundary. | Installed Codex is preferred; fallback is pinned and temporary; execution is ephemeral, finite, workspace-scoped, network-disabled for spawned commands, and free of Cloud delegation or token values. | Structural / security boundary | Passed | PowerShell AST and source assertions |
| `TEST-0039` | `SUBF-0013` | Complete a deterministic adoption draft with a mocked local Codex command. | The launcher creates the required labels and adoption issue; Codex runs only in the isolated clone at the exact PR head, sees no credential files, removes the manifest, and the launcher commits and lease-pushes only to the adoption branch. | Real-Git integration | Passed | Mock CLI plus bare remote |
| `TEST-0040` | `SUBF-0013` | Present missing authentication, unchanged manifest, Codex-created commit, a concurrent remote-head change, or a manifest-free unverified draft. | The launcher blocks before publication and does not merge, overwrite, delete remote state, or promote an unverified draft. | Negative / concurrency | Passed | Mock CLI and remote-race fixtures |
| `TEST-0041` | `SUBF-0014` | Exercise seed/secrets/lifecycle/idempotency and inspect v0.6.1 documentation. | Existing guarantees remain green, the old skip switch aliases the new local switch, no active Cloud instruction remains, and version/link metadata is consistent. | Regression / documentation | Passed | Full PowerShell suite |
| `TEST-0042` | `BUG-0001` | Run quick adoption when both mapped Actions secrets exist, when only one exists, when an optional source path exists only in Git history, and when a new repository has neither. | Existing mapped names are never passed to `gh secret set`; only missing secrets are created; `FG_PAT.txt` is not required or read when its mapped secret exists; historical credential paths still block; new-repository provisioning remains unchanged. | Regression / credential boundary | Passed | Mock GitHub CLI plus real-Git fixtures |
| `TEST-0043` | `BUG-0002` | Run an existing-target rerun with both mapped secrets present and both local files absent, then remove one secret and exercise failure/recovery; also run the new-repository path. | Existing secret names make their files optional; exact source is fetched through authenticated local `gh` when the protocol file is absent; a missing secret still requires its mapped file; new repositories still require both files. | Regression / source-auth boundary | Passed | Mock GitHub CLI plus real-Git fixtures |

## Required coverage

- Installed CLI and pinned temporary fallback contracts.
- Local saved-authentication check and synchronous result capture.
- Exact PR head, isolated clone, token-file absence, and unchanged Codex head.
- Manifest removal, non-empty valid diff, launcher-owned commit, and exact lease.
- Remote-head race and semantic-incompletion failures.
- No Cloud comment, auto-approval, or merge.
- Existing repository, new repository, credential, lifecycle, bootstrap, and
  updater regression behavior.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.6.0` before FEAT-0007 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing TEST-0001 through TEST-0037 baseline |
| 2026-07-15 | FEAT-0007 pre-delivery working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0041` in 94.4 seconds |
| 2026-07-15 | PR #22 commit `9191cb0` | GitHub-hosted Ubuntu and Windows plus GitGuardian | [Protocol validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29418825486) | Pass: Ubuntu, Windows, and secret scan |
| 2026-07-15 | PR #22 completion commit `f1a8fb6` | GitHub-hosted Ubuntu and Windows plus GitGuardian | [Completion validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29419002180) | Pass: Ubuntu, Windows, and secret scan before merge |
| 2026-07-15 | BUG-0001 pre-implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red: launcher lacked the `gh secret list` contract |
| 2026-07-15 | BUG-0001 convergence working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0042` in 91.7 seconds after `FIND-0060` remediation |
| 2026-07-15 | BUG-0001 post-review working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass: `TEST-0033` through `TEST-0042` in 44.9 seconds after `FIND-0061` remediation |
| 2026-07-15 | BUG-0002 pre-implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red: an existing configured target still required absent `MEANDAI_RO_FG_PAT.txt` before secret-name reconciliation |
| 2026-07-15 | BUG-0002 focused working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass: `TEST-0033` through `TEST-0043` in 66.3 seconds, including file-free semantic adoption through authenticated local `gh` |
| 2026-07-15 | BUG-0002 post-review working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0043` in 103.8 seconds; no unresolved blocker remained in the bounded fresh-diff review |
