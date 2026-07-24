# FEAT-0006 Test Scenarios

Implementations: `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` and the existing
repository suites.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0033` <a name="test-0033"></a> | [SUBF-0011](README.md#subf-0011) | Inspect the launcher and guide credential/source contracts. | Exact v0.6.0 source, fixed token/secret names, stdin-only secret transfer, redacted output, bounded dispatch, no merge, and PowerShell AST validity are enforced. | Structural / security boundary | Automated | Source assertions and AST parse |
| `TEST-0034` <a name="test-0034"></a> | [SUBF-0011](README.md#subf-0011) | Run in a clean populated consumer on its connected default branch. | Both secrets precede one workflow-only commit/push; the exact run succeeds; the application tree and history remain unchanged otherwise. | Real-Git integration | Automated | Mock GitHub API/CLI plus bare remote |
| `TEST-0035` <a name="test-0035"></a> | [SUBF-0012](README.md#subf-0012) | Run in a directory without its own Git repository or origin. | The launcher initializes `main`, creates a private owner/directory-name remote, pushes only the workflow, and leaves unrelated local files untracked. | Real-Git integration | Automated | Mock GitHub API/CLI plus bare remote |
| `TEST-0036` <a name="test-0036"></a> | [SUBF-0011](README.md#subf-0011) | Rerun an exact seed, resume after a selected-repository grant failure, then present seed drift. | Exact and empty-remote recovery create no duplicate commit or task; ambiguous state blocks before later mutation. | Negative / recovery | Automated | Integration fixtures |
| `TEST-0037` <a name="test-0037"></a> | [SUBF-0012](README.md#subf-0012) | Historical v0.6.0 Codex Cloud handoff; this behavior was removed by [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md). | Historical evidence remains attributable to v0.6.0 and the identifier is never reused for local Codex behavior. Active local behavior is covered by [TEST-0038](../FEAT-0007-local-codex-adoption/test-cases.md#test-0038), [TEST-0039](../FEAT-0007-local-codex-adoption/test-cases.md#test-0039), [TEST-0040](../FEAT-0007-local-codex-adoption/test-cases.md#test-0040), and [TEST-0041](../FEAT-0007-local-codex-adoption/test-cases.md#test-0041). | Historical documentation / handoff | Superseded (never reuse) | Historical v0.6.0 evidence only |

## Required coverage

- Success in an existing populated repository and a new local directory.
- Token confidentiality and tracked/history exposure failure.
- Exact source/tag/blob and workflow collision behavior.
- Repository/default-branch identity and dirty-state failure.
- Exact-seed rerun and partial-operation recovery.
- Historical bounded lifecycle dispatch and Codex Cloud delegation at v0.6.0;
  active local completion is owned by [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md) and its distinct TEST IDs.
- Regression of the v0.5 lifecycle and updater suites.

## Evidence

`TEST-0037` passed for the historical v0.6.0 behavior recorded below. [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md)
then removed that behavior. Supersession preserves the evidence but permanently
retires the identifier from active executable assertions.

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.5.0` before FEAT-0006 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), and [TEST-0027](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032) baseline |
| 2026-07-15 | FEAT-0006 pre-delivery working tree | Windows PowerShell 5.1, Turkish locale | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass: `TEST-0033` through `TEST-0037` |
| 2026-07-15 | FEAT-0006 pre-delivery working tree | Windows PowerShell 5.1, Turkish locale | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: [complete protocol suite](../../../tests/protocol.tests.ps1) in 99.5 seconds |
| 2026-07-15 | [PR #20](https://github.com/hasanmanzak/meAndAI/pull/20) commit [`31563a3`](https://github.com/hasanmanzak/meAndAI/commit/31563a3c2b1b4566818ec49d52c9d03149c75006) | GitHub-hosted Ubuntu and Windows plus GitGuardian | [Protocol validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/29413498953) | Pass: Ubuntu, Windows, and secret scan |
