# FEAT-0035 Test Scenarios

Implemented ownership: common runtime evidence under
[`tests/infrastructure`](../../../tests/infrastructure), hotspot contracts and
fixtures under
[`tests/capabilities/initial-adoption`](../../../tests/capabilities/initial-adoption),
and workflow/topology coverage under
[`tests/capabilities/workflow-efficiency`](../../../tests/capabilities/workflow-efficiency).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0144` <a name="test-0144"></a> | [SUBF-0064](README.md#subf-0064) | Run successful, failed, full, partial, and structure-only suite processes through the stable parent runner; vary owner identity, elapsed duration representation, child output, and process exit while inspecting the observation and canonical result boundaries. | Every selected suite produces one normalized owner-bound non-negative monotonic elapsed observation; observations cannot replace or alter scenario/compatibility results; malformed identity or result evidence still fails; elapsed time alone never changes the exit code or cancels the run. | Unit / runtime contract / observability / negative | Automated / focused green | `MeAndAI.TestRuntime` and stable-runner focused tests |
| `TEST-0145` <a name="test-0145"></a> | [SUBF-0065](README.md#subf-0065) | Inventory every existing quick-adoption and capabilities-bootstrap variant, classify its material boundary, run combinatorial pure/injected cases and retained real Git/launcher vertical slices, and vary success, policy rejection, malformed evidence, TOCTOU, credential, manifest, path/link, recovery, Codex/process, and Windows-native behavior. | Every prior variant maps to exactly one faithful executable case; production-owned contract/boundary results match retained real slices; real integration remains where the boundary supplies evidence; explicit immutable fixtures cannot leak mutable state; active scenario IDs and declared variants are unchanged. | Unit / contract / boundary / integration / security / recovery / cross-platform | Automated / focused green | Initial-adoption hotspot owners plus production-owned contract modules |
| `TEST-0146` <a name="test-0146"></a> | [SUBF-0066](README.md#subf-0066) | Execute focused owners and complete discovery on Windows PowerShell 5.1, Windows PowerShell 7, WSL Ubuntu PowerShell 7, and hosted Ubuntu/Windows; inspect scenario authority, job topology, routes, cancellation, timeouts, and soft performance observations. | Every active scenario has one owner and all suites pass; hosted validation still uses one Ubuntu and one Windows job with no matrix/fan-in; the 2/3-minute goals are reported but are not timeout or pass/fail thresholds; total jobs and runner consumption do not increase. | Structural / integration / compatibility / workflow / performance observation | Automated / local [TEST-0146](#test-0146) and [SUBF-0153](../FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153) combined-route green; final full and hosted gates pending | Scenario ownership, workflow-efficiency owner, local full suites, and hosted validation |

## Required coverage

- Successful and failed suite observation without changing canonical evidence.
- Exact owner identity, integer-millisecond duration, duplicate/missing/malformed
  observations, and no elapsed-only failure.
- Complete existing quick-adoption/bootstrap variant inventory and one explicit
  evidence-level assignment per case.
- Pure policy success/failure/boundaries and typed injected adapter behavior.
- Representative real Git/launcher success, rejection, security, TOCTOU,
  credential, manifest, path/link/reparse, recovery, process, Codex, and native
  Windows slices.
- Fingerprinted immutable baseline ownership, fresh mutable copies, cleanup,
  and cross-case isolation.
- Exact active `TEST-NNNN` ownership and retained PowerShell 5.1/7 behavior.
- One-Linux/one-Windows hosted topology, stable identities, exact-tree reuse,
  `Full`/`WindowsNative`, PR-only cancellation, publication isolation, and
  non-gating performance goals.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-19 | [`773a415`](https://github.com/hasanmanzak/meAndAI/commit/773a415844d56ac3b96be99390dd3e17d1aa5140) | GitHub-hosted Ubuntu / Windows | [Run 29670698209](https://github.com/hasanmanzak/meAndAI/actions/runs/29670698209) | Green baseline: Ubuntu 6m57s, Windows 31m26s; hotspot test steps dominated both jobs |
| 2026-07-19 | [`3f1072d`](https://github.com/hasanmanzak/meAndAI/commit/3f1072da05636ab428430954dbf5dc5f31f9cc6b) | Windows PowerShell 5.1 outside restricted sandbox | Existing `v0.12.2` full-suite evidence recorded by [FEAT-0034](../FEAT-0034-ci-evidence-hygiene/README.md) | Green baseline in 1609.5 seconds |
| 2026-07-19 | [`3f1072d`](https://github.com/hasanmanzak/meAndAI/commit/3f1072da05636ab428430954dbf5dc5f31f9cc6b) | WSL2 Ubuntu 24.04.1 / PowerShell 7.6.3 / Git 2.43.0 / temporary ext4 clone | Sequential `capabilities-bootstrap.tests.ps1`, then `quick-adoption.tests.ps1` under a 15-minute diagnostic shell budget | Incomplete performance observation: bootstrap completed; quick-adoption was still active at about 10m28s when the outer diagnostic budget terminated it. Exact process group and `/tmp/meandai-perf.ymjzCp` clone were removed. This machine is unsuitable for the iterative optimization loop; refresh the same-commit baseline on the stronger machine before implementation. |
| 2026-07-19 | Planning tree on `codex/feat-0035-test-runtime-efficiency` | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` | Expected red in 41.8 seconds: exactly three [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) missing-canonical-authority problems for `TEST-0144`, `TEST-0145`, and `TEST-0146`; no other structure or link problem reported. |
| 2026-07-20 | [`e6ff32d`](https://github.com/hasanmanzak/meAndAI/commit/e6ff32daa0ef655dd0a8881822fc5b75027b830b) | Windows PowerShell 5.1, same machine | `capabilities-bootstrap.tests.ps1 -Shard All`; `quick-adoption.tests.ps1 -Shard All` | Exact pre-change baselines: 444.284 seconds and 1055.028 seconds; quick-adoption made 166 real launcher invocations. |
| 2026-07-20 | Current v0.12.3 candidate tree | Windows PowerShell 5.1 | Quick-adoption focused shards: `IntegrityCompletedGraph`, `IntegrityCodexFailure`, `IntegrityMetadataCredential`, `RepositoryRoutes` | Green in 53.3, 142.8, 170.4, and 160.5 seconds respectively. |
| 2026-07-20 | Current v0.12.3 candidate tree | Windows PowerShell 5.1 | `quick-adoption.tests.ps1 -Shard All` | Green in 643.7 seconds with 113 real launcher invocations: approximately 39.0 percent faster than the exact same-machine baseline. |
| 2026-07-20 | Current v0.12.3 candidate tree | Windows PowerShell 5.1 | Capabilities-bootstrap canonical/focused validation | Earlier canonical `All` green in 203.636 seconds before bounded review; after review, `Contracts` green in 2.0 seconds and retained `VerticalSlices` green in 245.9 seconds. |
| 2026-07-20 | Current v0.12.3 candidate tree | Windows PowerShell 5.1 | Runner-observation and workflow-topology focused owners | Green: observation remains non-authoritative; one Ubuntu and one Windows ordinary job plus isolated publication retained, with no matrix, fan-in, or timing gate. |
| 2026-07-30 | [SUBF-0153](../FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153) local candidate; implementation commit pending | Local existing Domain.Tests and workflow-efficiency route | Local [TEST-0146](#test-0146) owner/topology verification plus one existing Domain test invocation with the combined [TEST-0220](../FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)/[TEST-0221](../FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221) filter | [TEST-0146](#test-0146) local green and combined Domain route `98/98` passing, with no new job, testhost, restore invocation, solution/project/package/reference/dependency/lock graph edge, or timeout expansion; hosted Ubuntu/Windows exact-head proof remains pending. |

Executable ownership and focused implementation evidence are complete. One
final full candidate validation and normal hosted CI remain mandatory gates;
their exact results will be recorded through
[issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) and the pull
request after they exist.
