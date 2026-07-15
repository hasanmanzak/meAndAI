# FEAT-0012 Test Scenarios

Planned implementations:

- [Quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities-bootstrap-adapter.tests.ps1)
- [Updater adapter fixtures](../../../tests/protocol-update-adapter.tests.ps1)
- [Repository validator](../../../tests/protocol.tests.ps1)
- [Protocol validation workflow](../../../.github/workflows/protocol-tests.yml)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0069` | `SUBF-0027` | Reconcile issue bodies containing one canonical ownership marker, quoted/example marker text, malformed markers, and duplicate canonical markers. | Only one exactly parsed canonical marker establishes ownership; incidental or ambiguous text blocks without mutating the wrong issue. | Ownership / boundary | Passed | Quick-adoption issue fixture |
| `TEST-0070` | `SUBF-0027` | Start concurrent secret reconciliation for the same repository while both launchers initially observe a missing canonical secret. | Repository-scoped serialization and a live in-boundary inventory ensure at most one write; the later launcher preserves the now-existing name. | Concurrency / credential boundary | Passed | Quick-adoption concurrent CLI fixture |
| `TEST-0071` | `SUBF-0027` | Rerun the lifecycle while an exact ready, manifest-free `Completed` adoption proposal remains open for maintainer review. | Bootstrap retains the valid completed proposal, creates no duplicate, and performs no unrelated mutation. | Lifecycle / integration | Passed | Bootstrap adapter fixture |
| `TEST-0072` | `SUBF-0027` | Leave an older reserved meAndAI automation branch outside the current target name, with owned and ambiguous variants. | The full reserved namespace is inventoried; only exact owned state is accepted and ambiguity blocks before proposal mutation. | Recovery / integration | Passed | Updater adapter fixture |
| `TEST-0073` | `SUBF-0028` | Exercise repository metadata, source download, and both secret mappings with distinct credentials and complete request capture. | Tests assert exact repository identity, authorization and API-version headers, source versus consumer token authority, secret name, and stdin value mapping without logging a token. | Security boundary / integration | Passed | Contract-bearing GitHub CLI mocks |
| `TEST-0074` | `SUBF-0028` | Compare every active documented TEST record with its canonical owner/evidence authority and historical supersession state. | Every active ID has one canonical declaration, one owning suite/evidence kind, and a successful owner-suite result; `TEST-0037` remains superseded and cannot appear as active executable evidence. Focused fixtures separately cover the declared path and dispatch variants. | Evidence ownership / structural | Passed | Scenario authority manifest and runner |
| `TEST-0075` | `SUBF-0028` | Validate the repository and consumer workflow through recurring CI. | A pinned, checksummed actionlint validates both workflow files and any semantic error fails the gate. | Workflow semantics / CI | Local semantic pass; recurring hosted check pending | Protocol workflow actionlint step plus structural assertion |
| `TEST-0076` | `SUBF-0029` | Inspect feature/template governance before publication and verify historical release evidence through its external authority. | Completion scan and disposition contracts are mandatory; current release-dependent fields stay pending pre-merge; the repository metadata request uses the exact root without a trailing slash; read-only external evidence verifies published facts without a predicted in-repository commit. | Governance / integration | Focused contract pass; external v0.8.3 publication evidence is a separate post-merge gate | Repository validator plus read-only release verifier |

## Required coverage

- Exact automation-owned issue identity and ambiguity rejection.
- Repository-scoped secret serialization without overwrite.
- Completed-proposal retention and full reserved-branch recovery inventory.
- Credential, API header, repository, token-authority, and stdin contracts.
- One canonical scenario declaration and owning suite/evidence kind, successful
  suite completion, focused variant fixtures, and permanent historical
  supersession.
- Workflow-semantic validation for both Actions files.
- Mandatory bounded scan/disposition contracts and two-stage release evidence.
- Existing launcher, bootstrap, updater, protocol, and documentation behavior.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | v0.8.1 commit `9b4060a98af65d2ff3102495b8b29719c831c7de` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Baseline passed in 232.8 seconds but did not prove `TEST-0069` through `TEST-0076`; ten blocking findings remained |
| 2026-07-16 | FEAT-0012 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/post-publication-evidence.tests.ps1` | Pass in 2.8 seconds: `TEST-0076` mocked the qualified verifier and negative boundaries without claiming a published v0.8.2 state |
| 2026-07-16 | FEAT-0012 working tree | actionlint 1.7.12 | `actionlint -shellcheck= -pyflakes= .github/workflows/protocol-tests.yml templates/project/.github/workflows/meandai-protocol-update.yml` | Local pass in 1.2 seconds for `TEST-0075`; recurring hosted check remains pending |
| 2026-07-16 | FEAT-0012 working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass in 136.6 seconds after the self-review corrected pre-lock read-token selection |
| 2026-07-16 | FEAT-0012 working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All discovered suites passed in 267.9 seconds; no unresolved local blocker remained |
| 2026-07-16 | Immutable v0.8.2 publication | GitHub Actions | [Post-publication run 29454981897](https://github.com/hasanmanzak/meAndAI/actions/runs/29454981897) | Expected retained failure for `BUG-0004`: repository metadata URL ended in `/` and GitHub returned 404 |
| 2026-07-16 | BUG-0004 v0.8.3 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/post-publication-evidence.tests.ps1` | Pass in 2.8 seconds; exact root accepted and trailing-slash root rejected |
| 2026-07-16 | BUG-0004 v0.8.3 working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All discovered suites passed in 264.4 seconds after exact plain and escaped active-pin reconciliation |
