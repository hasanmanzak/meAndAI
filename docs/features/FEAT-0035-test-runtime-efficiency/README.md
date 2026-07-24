# FEAT-0035 - Bounded Full-Suite Runtime Without Evidence Loss

| Field | Value |
| --- | --- |
| Classification | Test-architecture and performance correction / [BUG-0017](https://github.com/hasanmanzak/meAndAI/issues/87) |
| Status | Complete |
| Target version | 0.12.3 |
| Issue | [#87](https://github.com/hasanmanzak/meAndAI/issues/87) |
| Pull request | Recorded through [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) after creation |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| Tests | [TEST-0144](test-cases.md#test-0144), [TEST-0145](test-cases.md#test-0145), and [TEST-0146](test-cases.md#test-0146) |

## Problem

The canonical validation topology now avoids hosted fan-out and can reuse an
exact already-green merge tree, but a full sensitive change still pays for a
large combinatorial policy matrix through repeated real launcher, child-process,
and Git-repository execution. The exact `v0.12.0` hosted candidate completed in
6 minutes 57 seconds on Ubuntu and 31 minutes 26 seconds on Windows. The final
`v0.12.2` local Windows PowerShell 5.1 full run still required 1609.5 seconds.

The dominant owners are
`tests/capabilities/initial-adoption/quick-adoption.tests.ps1` and
`tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1`.
Their exhaustive behavior variants are valuable, but many variants currently
obtain policy evidence only after rebuilding repositories and crossing the
same launcher/Git boundaries. Parallel hosted shards previously reduced wall
time by multiplying runner consumption and therefore cannot solve this defect.

## Outcome

Every active scenario identity, declared variant, supported runtime,
Windows-native contract, and fail-closed safety boundary remains covered while
each behavior is proven at the lowest faithful level. Combinatorial policy and
validation cases use production-owned in-process contracts or injected
boundaries. A small representative set of real Git and real launcher vertical
slices retains integration, security, recovery, and native-Windows evidence.

The canonical runner reports non-authoritative performance observations.
Linux full validation should ordinarily approach 2 minutes and Windows full
validation should ordinarily approach 3 minutes. These values are optimization
goals, not timing gates, timeout ceilings, or permission to cancel an otherwise
successful run that exceeds the goal by a small amount.

## Scope

- Add exact per-suite elapsed-time observations to the existing stable runner
  without changing scenario-result authority or child-process isolation.
- Inventory real launcher, Git, GitHub, and Codex boundary crossings in the two
  hotspot owners and make their retained integration budget reviewable.
- Extract behavior-preserving pure policy/validation contracts and typed
  injected boundaries where a real process or repository adds no evidence.
- Map every existing quick-adoption and capabilities-bootstrap variant to one
  faithful contract, boundary, or retained vertical-slice case.
- Share only explicitly fingerprinted immutable baseline fixtures and create a
  fresh mutable scenario state from them.
- Retain representative real success, failure, security, recovery, TOCTOU,
  manifest, credential, path/link, and native-Windows vertical slices.
- Validate on Windows PowerShell 5.1, Windows PowerShell 7, WSL Ubuntu
  PowerShell 7, and the existing hosted jobs.
- Keep one Ubuntu job and one Windows job, PR-only cancellation, exact-tree
  `main` reuse, and fail-safe `Full`/`WindowsNative` Windows routing.

## Non-goals

- Removing Windows, PowerShell 5.1, active `TEST-NNNN` identities, declared
  variants, security negatives, or canonical full-suite authority.
- Replacing behavior evidence with source-string assertions or mocks that do
  not implement production contracts.
- Making the 2/3-minute goals workflow timeouts or flaky pass/fail thresholds.
- Adding a hosted matrix, aggregate runner, reusable-workflow fan-out, cache
  service, scheduler, persistent fixture service, or self-hosted runner.
- Combining canonical suites into one process or weakening capability-local
  fixture ownership required by [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md).
- Changing consumer-visible adoption/updater behavior except for
  behavior-preserving boundary extraction required for testability.
- Changing repository visibility as part of the implementation. The temporary
  public period is maintainer-owned operational context.

## Readiness evidence

- Domain and contracts: a suite observation has one normalized canonical owner
  and a non-negative monotonic elapsed duration in integer milliseconds. It is
  emitted by the parent runner after child completion and cannot replace,
  alter, or validate the existing scenario result. Expensive-boundary counts
  are test observations tied to one exact hotspot owner and case inventory;
  they are not production behavior or hosted timing gates.
- Evidence levels: pure deterministic policy is owned by an in-process
  contract; injected adapters implement the same production-owned boundary;
  real Git/launcher slices remain mandatory wherever filesystem identity,
  process behavior, command resolution, credentials, TOCTOU, links/reparse
  points, recovery, or OS-native semantics supply material evidence.
- Fixture lifecycle: immutable baselines have one owner and fingerprint;
  mutation occurs only in a fresh scenario-local copy. A mismatch, linked
  fixture, unknown owner, or reset failure fails closed before the case runs.
- Consumers and dependencies: the stable runner, common test runtime,
  initial-adoption launchers/modules, two hotspot suites, scenario authority,
  execution profiles, workflow topology, Windows PowerShell 5.1, PowerShell 7,
  WSL Ubuntu, Git, and GitHub-hosted standard runners.
- Compatibility: suite processes remain separate; all existing result schemas,
  stable job names, triggers, routes, timeouts, and scenario authorities remain
  valid. Timing alone never changes an exit code.
- Verification approach: declare expected-red scenarios, capture a
  same-commit per-suite/boundary baseline on a sufficiently powerful machine,
  implement and review each subfeature independently, run focused owners on all
  applicable runtimes, then run one local full suite per OS and normal hosted
  validation. Compare total jobs and runner consumption as well as elapsed
  time.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0144](test-cases.md#test-0144), [TEST-0145](test-cases.md#test-0145), and [TEST-0146](test-cases.md#test-0146) |
| Test code | Implemented | Executable ownership for [TEST-0144](test-cases.md#test-0144), [TEST-0145](test-cases.md#test-0145), and [TEST-0146](test-cases.md#test-0146) is present in the capability-based architecture |
| Baseline run | Established and refreshed | Exact same-machine [`e6ff32d`](https://github.com/hasanmanzak/meAndAI/commit/e6ff32daa0ef655dd0a8881822fc5b75027b830b) Windows PowerShell 5.1 baselines: quick-adoption 1055.028 seconds and capabilities-bootstrap 444.284 seconds |

### Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0158` <a name="risk-0158"></a> | Evidence integrity | Moving variants below end-to-end execution weakens behavior evidence | Test maintainer / exact variant-to-level inventory, production-owned contracts, and retained representative vertical slices in [TEST-0145](test-cases.md#test-0145) |
| `RISK-0159` <a name="risk-0159"></a> | Boundary fidelity | Injected Git, GitHub, Codex, or process adapters diverge from production behavior | Launcher maintainer / typed production-owned boundaries plus real success/failure integration slices on PowerShell 5.1 and 7 |
| `RISK-0160` <a name="risk-0160"></a> | Measurement | Host noise turns elapsed time into a flaky gate | Workflow maintainer / monotonic observations, same-host comparisons, soft 2/3-minute goals, and no elapsed-only failure or cancellation |
| `RISK-0161` <a name="risk-0161"></a> | Fixture isolation | Shared baselines leak mutable state or conceal link/identity drift | Test maintainer / fingerprinted immutable owner, fresh scenario copy, link-safe verification, and cleanup evidence |
| `RISK-0162` <a name="risk-0162"></a> | Runner consumption | A workflow-only shortcut reintroduces fan-out or hides incomplete coverage | Workflow maintainer / retain [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md) topology, exact scenario ownership, and report both job count and runner consumption in [TEST-0146](test-cases.md#test-0146) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0064` <a name="subf-0064"></a> | Suite/boundary observability and same-commit baseline inventory | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | [TEST-0144](test-cases.md#test-0144); focused runtime and runner tests green | Observation schema is owner-bound and non-authoritative; timing cannot change result authority | Complete |
| `SUBF-0065` <a name="subf-0065"></a> | Quick-adoption/bootstrap contract extraction and immutable fixture reuse | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | [TEST-0145](test-cases.md#test-0145); focused hotspot owners and retained real slices green | Variant inventory, adapter fidelity, fixture identity, security/recovery paths reviewed; `FIND-0176` through `FIND-0183` resolved | Complete |
| `SUBF-0066` <a name="subf-0066"></a> | Cross-runtime full proof, hosted topology, and documentation closure | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | [TEST-0146](test-cases.md#test-0146); focused workflow topology and local final full candidate green; exact hosted revalidation tracked in [PR #88](https://github.com/hasanmanzak/meAndAI/pull/88) | One Ubuntu/one Windows ordinary topology retained with no matrix, fan-in, or timing gate | Complete / hosted gate pending |

## Decisions and relationships

- Hosted single-runner authority: [FEAT-0027](../FEAT-0027-v0104-runner-minute-efficiency/README.md) / [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md)
- Capability-owned test architecture: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Exact-tree reuse: [FEAT-0034](../FEAT-0034-ci-evidence-hygiene/README.md)
- Tracking and post-publication authority: [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87)

No new architectural decision is required: this correction implements the
existing [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md) review condition after measured full-suite consumption became
materially worse, while preserving [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)'s separate-suite and fixture
ownership contracts.

## Definition of Ready

- [x] Stable `FEAT-0035`, [BUG-0017](https://github.com/hasanmanzak/meAndAI/issues/87), `SUBF-0064` through `SUBF-0066`, and linked [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable without turning elapsed time into a gate.
- [x] Observation, evidence-level, boundary, fixture, compatibility, and lifecycle contracts are explicit.
- [x] Consumers, dependencies, governing decisions, and related features are identified.
- [x] `RISK-0158` through `RISK-0162` have owners and required evidence.
- [x] Three independently reviewable slices and gates are defined.
- [x] [TEST-0144](test-cases.md#test-0144), [TEST-0145](test-cases.md#test-0145), and [TEST-0146](test-cases.md#test-0146) and the verification approach are defined.
- [x] Test-code and baseline states are recorded before implementation.

## Acceptance criteria

1. Every active scenario identity and declared quick-adoption/bootstrap variant
   retains exactly one canonical executable owner and a documented faithful
   evidence level; no scenario is removed, renamed, or satisfied by an
   unstructured source assertion.
2. The parent runner reports one exact owner-bound, non-negative monotonic
   elapsed observation for every selected suite without changing child result
   parsing, exit authority, or final success semantics.
3. Pure policy and validation combinations execute in-process through
   production-owned contracts; injected boundaries preserve production types,
   errors, identity, and ordering.
4. Real launcher/Git vertical slices still prove representative success,
   fail-closed security, TOCTOU, credential, manifest, path/link, recovery,
   process, and Windows-native behavior.
5. Shared state is limited to fingerprinted immutable fixtures; every mutable
   case receives a fresh verified copy and cannot affect another case.
6. The workflow retains one Ubuntu and one Windows validation job, stable job
   names, existing triggers/routes, PR-only cancellation, no hosted fan-out,
   and the isolated publication path.
7. Windows PowerShell 5.1, Windows PowerShell 7, WSL Ubuntu PowerShell 7, local
   full suites, and applicable hosted validation pass with unchanged scenario
   authority.
8. Hosted Linux full validation ordinarily approaches 2 minutes and hosted
   Windows full validation ordinarily approaches 3 minutes. Deviations are
   reported and investigated but elapsed time alone does not fail or cancel a
   correct run.

## Self-review

The bounded implementation review resolved all identified findings. The final
full candidate validation and hosted CI remain mandatory gates; their exact
facts belong in [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87)
and the pull request after they exist.

| ID | Classification | Finding | Resolution |
| --- | --- | --- | --- |
| `FIND-0176` <a name="find-0176"></a> | Correctness | An unrelated empty Git configuration was rejected as adoption drift. | Preserve empty unrelated configuration while retaining exact managed-surface checks. |
| `FIND-0177` <a name="find-0177"></a> | Evidence integrity | Adapter-only proposal-tree, asset, and `.gitmodules` cases were over-collapsed. | Restore representative real adapter slices for those material boundaries. |
| `FIND-0178` <a name="find-0178"></a> | Correctness | Hybrid reconciliation decision enforcement was missing after extraction. | Enforce the exact Hybrid decision through the production-owned contract and retained adapter proof. |
| `FIND-0179` <a name="find-0179"></a> | Compatibility | `LegacyUnspecified` completion fallback drifted from the established behavior. | Restore the legacy fallback and lock it with executable contract coverage. |
| `FIND-0180` <a name="find-0180"></a> | Evidence integrity | Legacy marker validation no longer required the expected-surface list to be empty. | Restore the empty expected-surface requirement without changing newer marker schemas. |
| `FIND-0181` <a name="find-0181"></a> | Test reliability | Two independently selectable shard paths used the completion contract without shard-local initialization. | Initialize the contract in each shard before its first use. |
| `FIND-0182` <a name="find-0182"></a> | Test reliability | `RepositoryRoutes` resolved a contract before fixture initialization. | Initialize the fixture before resolving the contract and retain the focused shard proof. |
| `FIND-0183` <a name="find-0183"></a> | Cross-runtime contract reliability | PowerShell splatting can bind a semantically empty collection as null at predicate boundaries, causing negative completion evidence to throw instead of returning false. | Accept null-equivalent empty collections at both completion-predicate boundaries, normalize them inside the production-owned predicate, and retain direct plus adapter-level fail-closed regression cases. |

## Definition of Done

- [ ] Acceptance criteria fully evidenced; implementation, focused portions,
  and the local final full candidate are complete, while the exact hosted
  revalidation remains pending in [PR #88](https://github.com/hasanmanzak/meAndAI/pull/88).
- [x] Mandatory test code and scenario mapping complete.
- [x] Focused test commands and successful results recorded.
- [x] Every subfeature review and bounded implementation review complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current for the pre-merge candidate.
- [x] Issue, decisions, related work, and [PR #88](https://github.com/hasanmanzak/meAndAI/pull/88) cross-linked.
- [ ] Applicable local and hosted CI gates pass.

## Post-merge release evidence

[Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) is the stable
external authority. Pull request, converged push, hosted checks, merge,
immutable release, cleanup, and post-publication verification remain `Pending`
until those facts exist and will be recorded externally without an
evidence-only candidate commit.
