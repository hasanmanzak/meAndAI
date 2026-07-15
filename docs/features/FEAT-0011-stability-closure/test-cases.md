# FEAT-0011 Test Scenarios

Implementations:

- [Quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities-bootstrap-adapter.tests.ps1)
- [Updater adapter fixtures](../../../tests/protocol-update-adapter.tests.ps1)
- [Lifecycle structural tests](../../../tests/capabilities-bootstrap.tests.ps1)
- [Repository validator](../../../tests/protocol.tests.ps1)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0060` | `SUBF-0024` | Run a connected GitHub.com consumer while GitHub CLI has another default host. | Repository metadata, secret writes, workflow runs, issues, and pull requests remain qualified to `github.com`; a mismatched host blocks. | Security boundary / integration | Passed | Mock multi-host GitHub CLI fixture |
| `TEST-0061` | `SUBF-0024` | Discover a private protocol update with separate source-read and consumer-write tokens; move a tag before immutable publication. | Source metadata uses the protocol credential, and only the locked remote tag commit is accepted for proposal planning and mutation. | Supply chain / adapter | Passed | Workflow assertions plus mock API/Git fixture |
| `TEST-0062` | `SUBF-0024` | Rename an unrelated consumer file into an expected full or manifest-only bootstrap destination. | Both source and destination are observed and the proposal is rejected without mutation. | Path provenance / real Git | Passed | Bootstrap adapter fixture |
| `TEST-0063` | `SUBF-0024` | Dispatch two runs for the same commit and race two canonical issue creators. | Only the matching correlation ID is awaited; issue reconciliation converges to one identity or blocks ambiguity. | Concurrency / boundary | Passed | Mock Actions and issue inventory fixture |
| `TEST-0064` | `SUBF-0025` | Classify blocking, accepted residual, external/legacy follow-up, optional improvement, and unchanged observations. | Exactly one disposition controls whether implementation reopens, completion blocks, or work is linked without another scan. | Process contract / structural | Passed | Protocol and decision assertions |
| `TEST-0065` | `SUBF-0025` | Inspect a published release after merge and owned branch deletion. | Feature/index/memory/issue status is reconciled and external records use durable main/tag/commit links. | Governance / integration | Passed | Canonical-state assertions plus GitHub evidence check |
| `TEST-0066` | `SUBF-0026` | Compare documented scenario IDs and exact bootstrap assets with executable tests; exercise zero/delayed timeout modes. | Every declared scenario has executable evidence, exact assets are complete, and bounded timeout paths run without a blanket range claim. | Test evidence / integration | Passed | Source inventory plus focused behavior fixtures |
| `TEST-0067` | `SUBF-0026` | Validate the consumer workflow and run supported PowerShell engines. | YAML parses as a workflow and Windows PowerShell 5.1 plus PowerShell 7 remain covered where available. | Compatibility / CI | Passed | YAML parser and CI matrix |
| `TEST-0068` | `SUBF-0026` | Run cleanup beside an unrelated same-prefix temp directory and inspect root checkout. | Only run-owned paths are removed and checkout credentials are not persisted. | Isolation / security | Passed | Temp fixture plus workflow assertion |

## Required coverage

- Qualified external identity and credential separation
- Exact immutable-release commit evidence
- Complete rename provenance and consumer file preservation
- Dispatch and issue causality under concurrency
- One bounded finding-disposition taxonomy
- Post-publication state and durable-link convergence
- Executable test-ID, timeout, asset, YAML, and runtime evidence
- Run-owned cleanup and least-privilege checkout
- Existing updater, bootstrap, launcher, and protocol regression behavior

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.8.0` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Baseline pass in 203.7 seconds before FEAT-0011; new scenarios not yet implemented |
| 2026-07-15 | FEAT-0011 publication candidate; exact commit retained by [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All discovered suites passed in 225.3 seconds, including `TEST-0060` through `TEST-0068` |
