# FEAT-0039 Test Scenarios

Ownership: capability catalog and review behavior under
[`tests/capabilities/capability-adoption`](../../../tests/capabilities/capability-adoption),
strict observation mechanics and budget policy under
`tests/capabilities/test-runtime-efficiency` owner, and real fixture/boundary
evidence under the existing capability owners.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0157` | `SUBF-0073` | Append the `test-runtime-efficiency` Semantic capability to an unchanged predecessor catalog; evaluate an existing one-entry terminal ledger, applicable/non-applicable repositories, and missing, rewritten, reordered, duplicated, or malformed definitions and ledger prefixes. | The predecessor entry remains byte-identical and a valid terminal prefix; only the appended capability becomes pending; applicability supports reviewed `NotApplicable`; incompatible catalog or ledger state fails before proposal mutation. | Contract / catalog / lifecycle / negative | Passed | Capability-catalog owner; capability-review lifecycle support |
| `TEST-0158` | `SUBF-0074` through `SUBF-0076` | Repeatedly request the exact quick-adoption and bootstrap prepared-seed families, provision fresh mutable derivatives, retain shape-defining special fixtures, and exercise baseline fingerprints, byte isolation, distinct roots, remotes, links/reparse points, and cleanup. | Each equivalent owner-specific family builds once and records reuse; every mutable case has an isolated derivative and remote; immutable mutation, shared Git state, unsafe links, ambiguous identity, or cleanup leakage blocks before success evidence. | Runtime contract / fixture integration / isolation / security | Passed | Test-runtime-efficiency guardrails plus existing quick/bootstrap owners |
| `TEST-0159` | `SUBF-0074` through `SUBF-0076` | Load the owner/route/runtime budget and run declared wrappers plus direct/aliased Git, launcher, adapter, child-process, graph-acquisition, and cleanup construction; add another equivalent fixture request and an extra expensive operation. | One sorted machine-readable observation is emitted; equivalent requests increase reuse rather than builds; missing/duplicate/malformed observations, unknown routes, undeclared construction, alias bypass, duplicate builds, and counts above the reviewed maximum fail before canonical scenario success. | Runtime / policy / AST preflight / integration / regression / negative | Passed | New test-runtime-efficiency owner plus hotspot wrappers |
| `TEST-0160` | `SUBF-0077` | Execute direct focused owners, parent-runner Full and `WindowsNative`, Windows PowerShell 5.1/7, Linux PowerShell 7, and the existing hosted topology while comparing exact-base and candidate operation budgets, suite authority, job count, runner consumption, and elapsed observations. | Every active scenario retains one owner; operation budgets and lower closure targets pass; one Windows and one Ubuntu job remain with no fan-out; elapsed time remains observational; missed soft goals receive explicit disposition and an owned successor. | Structural / compatibility / cross-platform / workflow / performance observation | Automated / local and structural green; candidate hosted gates pending | Focused owners, stable runner, workflow-efficiency owner, and hosted validation |

## Required coverage

- Append-only capability definition, predecessor blob identity, catalog-prefix
  compatibility, applicability, proposal boundary, and malformed catalog/ledger
  failures.
- Owner/key/builder/scope/input-digest identity; one build plus reuse; alias and
  conflict rejection.
- Distinct mutable derivatives, immutable before/after fingerprint, dirty-ref,
  byte/mode mutation, link/reparse, reset, cleanup, and leak behavior.
- Exact operation kinds for immutable build/reuse, mutable provision, Git
  init/clone/bundle/worktree, launcher/adapter, child process, graph acquisition,
  cleanup, and leak.
- Missing, duplicate, malformed, random-data-bearing, wrong owner/route/runtime,
  undeclared, direct, aliased, duplicate-build, and over-budget observations.
- Recursive AST preflight without source-string-only behavioral evidence.
- Direct focused execution and nested-process aggregation without weakening the
  final scenario-result authority or separate suite-process boundary.
- Quick-adoption, capabilities-bootstrap, instruction-graph, existing security,
  recovery, TOCTOU, credential, link/reparse, Codex/process, and native-Windows
  vertical slices.
- Exact-base versus candidate operation counts, same-topology runner
  consumption, one-Windows/one-Ubuntu topology, and non-gating timing evidence.

## Baseline evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-22 | `327a832f24c981c9f55c34a8ec8d9859667ffb06` | Windows PowerShell 5.1 / exact detached PR #94 tree | Measurement-only command-discovery plus Git Trace2 over the hotspot owners | Stopped: observer overhead was prohibitive; hosted PR #94 durations remain trigger evidence only |
| 2026-07-22 | `6b01299cfe484c900944b7435d4fef43b11fc38d` | Windows PowerShell 5.1 / immutable v0.12.7 task base | Low-overhead breakpoint plus Git Trace2 observer `sha256:ed9a8290b24b191274f35c4bef2cd9af14157e2927be94848a2561a54294e04b` | Quick `All` hit the bounded 30-minute ceiling after 15,026 Git starts; diagnostic lower bound was 85 init, 65 clone, 368 ls-tree, and 330 cat-file; no success authority was published |
| 2026-07-22 | `6b01299cfe484c900944b7435d4fef43b11fc38d` | Exact committed executable routes | Owner-level fixture and graph construction inventory | Frozen baselines/targets: quick init 47/11; bootstrap init 38/3, clone 72/2, bundle 2/2, push 36/36; graph child process 6/4 and isolated acquisition 5/3 |

## Implementation evidence

Structure-only validation on 2026-07-22 initially failed for exactly the four
planned IDs because they had no canonical executable authority; it reported no
other problem. `TEST-0157` then produced the planned red catalog-count failure
(`expected 2, observed 1`) and passed after the immutable capability/catalog
append plus ledger-prefix and review-lifecycle changes. The exact logical
budgets and lower closure targets are frozen. Focused test-runtime-efficiency
validation and structure-only parent validation pass on Windows PowerShell
5.1. Quick-adoption `RepositoryRoutes` passes in 173.8 seconds with its three
immutable family identities and isolated derivatives. The final local Windows
PowerShell 5.1 Full route passes in 1,340.2 seconds: quick-adoption `All` takes
776.2 seconds with init 11, bootstrap `All` takes 267.6 seconds with init 3,
clone 2, bundle 2, push 36, child process 4, and graph acquisition 3, and the
instruction-graph owner takes 135.9 seconds. The final `WindowsNative` rerun
passes in 341.0 seconds, including a 329.2-second native quick-adoption route. The unchanged
one-Windows/one-Ubuntu workflow adds one focused Windows PowerShell 7 contract
step to the existing Windows job; Linux retains the PowerShell 7 Full route.

The first fresh-diff review found incomplete bypass inventory, cleanup leakage,
mode-blind fingerprints, and an under-bound input digest. Expected-red
negatives reproduced these failures. The final ratchets inventory every owner-
source Git/launcher/adapter/process/recursive-cleanup call site, reject aliases,
verify no bootstrap cleanup survivor, bind owner source and committed modes,
and fail on input or mode drift. A final independent review also found and
closed a recovery-root survivor bypass, a known-owner/unknown-route budget
bypass, and an unclassified dynamically assembled direct Git operation.
Remediation re-review reports no unresolved blocking finding. `TEST-0158` and `TEST-0159` pass, and the local/structural
portion of `TEST-0160` is green. Candidate hosted execution remains external delivery evidence;
historical and candidate same-topology timing is recorded through
[issue #95](https://github.com/hasanmanzak/meAndAI/issues/95). The missed soft
goals are non-gating and owned by
[`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).
