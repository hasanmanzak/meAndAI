# FEAT-0011 Test Scenarios

Implementations:

- [Quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1)
- [Updater adapter Case](../../../tests/capabilities/consumer-update/protocol-update-adapter.case.ps1)
- [Lifecycle structural tests](../../../tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1)
- [Repository validator](../../../tests/protocol.tests.ps1)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0060` <a name="test-0060"></a> | [SUBF-0024](README.md#subf-0024) | Run a connected GitHub.com consumer while GitHub CLI has another default host. | Repository metadata, secret writes, workflow runs, issues, and pull requests remain qualified to `github.com`; a mismatched host blocks. | Security boundary / integration | Passed | Mock multi-host GitHub CLI fixture |
| `TEST-0061` <a name="test-0061"></a> | [SUBF-0024](README.md#subf-0024) | Discover a private protocol update with separate source-read and consumer-write tokens; move a tag before immutable publication. | Source metadata uses the protocol credential, and only the locked remote tag commit is accepted for proposal planning and mutation. | Supply chain / adapter | Passed | Workflow assertions plus mock API/Git fixture |
| `TEST-0062` <a name="test-0062"></a> | [SUBF-0024](README.md#subf-0024) | Rename an unrelated consumer file into an expected full or manifest-only bootstrap destination. | Both source and destination are observed and the proposal is rejected without mutation. | Path provenance / real Git | Passed | Bootstrap adapter fixture |
| `TEST-0063` <a name="test-0063"></a> | [SUBF-0024](README.md#subf-0024) | Dispatch two runs for the same commit and race two canonical issue creators. | Only the matching correlation ID is awaited; issue reconciliation converges to one identity or blocks ambiguity. | Concurrency / boundary | Passed | Mock Actions and issue inventory fixture |
| `TEST-0064` <a name="test-0064"></a> | [SUBF-0025](README.md#subf-0025) | Classify blocking, accepted residual, external/legacy follow-up, optional improvement, and unchanged observations. | Exactly one disposition controls whether implementation reopens, completion blocks, or work is linked without another scan. | Process contract / structural | Passed | Protocol and decision assertions |
| `TEST-0065` <a name="test-0065"></a> | [SUBF-0025](README.md#subf-0025) | Inspect a published release after merge and owned branch deletion through the external evidence authority. | The immutable release/tag resolves to the exact default-branch commit, the owned branch is absent, and the closed issue links the feature, release, and commit. | Governance / external integration | External post-publication evidence; not a pre-merge gate | [Read-only verifier](../../../tests/capabilities/publication-evidence/Verify-PostPublicationEvidence.ps1); the v0.8.1 link gap is recorded by [FIND-0108](../FEAT-0012-v082-correction/README.md#find-0108) |
| `TEST-0066` <a name="test-0066"></a> | [SUBF-0026](README.md#subf-0026) | Compare exact bootstrap assets with executable inventory and exercise zero/delayed timeout modes. | Exact assets are complete and bounded timeout paths run without a blanket range claim. Scenario authority is now owned separately by [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074). | Test evidence / integration | Passed for asset and timeout scope | Source inventory plus focused behavior fixtures |
| `TEST-0067` <a name="test-0067"></a> | [SUBF-0026](README.md#subf-0026) | Parse the consumer workflow and run supported PowerShell engines. | YAML parses and Windows PowerShell 5.1 plus PowerShell 7 remain covered where available. Workflow-semantic linting is now owned separately by [TEST-0075](../FEAT-0012-v082-correction/test-cases.md#test-0075). | Compatibility / CI | Passed for historical YAML/runtime scope | YAML parser and hosted CI matrix |
| `TEST-0068` <a name="test-0068"></a> | [SUBF-0026](README.md#subf-0026) | Run cleanup beside an unrelated same-prefix temp directory and inspect root checkout. | Only run-owned paths are removed and checkout credentials are not persisted. | Isolation / security | Passed | Temp fixture plus workflow assertion |

## Required coverage

- Qualified external identity and credential separation
- Exact immutable-release commit evidence
- Complete rename provenance and consumer file preservation
- Dispatch and issue causality under concurrency
- One bounded finding-disposition taxonomy
- External post-publication state and durable-link convergence
- Timeout, exact-asset, YAML, and runtime evidence; scenario ownership and
  workflow semantics continue under [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) and [TEST-0075](../FEAT-0012-v082-correction/test-cases.md#test-0075)
- Run-owned cleanup and least-privilege checkout
- Existing updater, bootstrap, launcher, and protocol regression behavior

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.8.0` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Baseline pass in 203.7 seconds before FEAT-0011; new scenarios not yet implemented |
| 2026-07-15 | FEAT-0011 publication candidate; exact commit retained by [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All discovered suites passed in 225.3 seconds. This did not constitute external `TEST-0065` evidence or semantic scenario-ownership proof; those overclaims are corrected by [FEAT-0012](../FEAT-0012-v082-correction/README.md). |
| 2026-07-15 | FEAT-0011 publication candidate | actionlint 1.7.12 plus Windows PowerShell 5.1 | `actionlint .github/workflows/protocol-tests.yml`; `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Zero workflow errors; protocol structure pass after replacing unsupported dynamic shell context |
