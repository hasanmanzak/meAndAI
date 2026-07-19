# FEAT-0035 - Bounded Full-Suite Runtime Without Evidence Loss

| Field | Value |
| --- | --- |
| Classification | Test-architecture and performance correction / `BUG-0017` |
| Status | Ready |
| Target version | 0.12.3 |
| Issue | [#87](https://github.com/hasanmanzak/meAndAI/issues/87) |
| Pull request | Recorded through [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) after creation |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| Tests | [TEST-0144 through TEST-0146](test-cases.md) |

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
  fixture ownership required by DEC-0022.
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
| Scenarios | Defined | [TEST-0144 through TEST-0146](test-cases.md) |
| Test code | Planned / not started | Expected-red ownership will be added first on the implementation machine |
| Baseline run | Established; stronger-machine refresh required | Hosted `v0.12.0`: Ubuntu 6m57s, Windows 31m26s; local `v0.12.2` Windows: 1609.5s; this machine's WSL hotspot sequence exceeded its 15-minute diagnostic shell budget before quick-adoption completed |

### Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0158` | Evidence integrity | Moving variants below end-to-end execution weakens behavior evidence | Test maintainer / exact variant-to-level inventory, production-owned contracts, and retained representative vertical slices in `TEST-0145` |
| `RISK-0159` | Boundary fidelity | Injected Git, GitHub, Codex, or process adapters diverge from production behavior | Launcher maintainer / typed production-owned boundaries plus real success/failure integration slices on PowerShell 5.1 and 7 |
| `RISK-0160` | Measurement | Host noise turns elapsed time into a flaky gate | Workflow maintainer / monotonic observations, same-host comparisons, soft 2/3-minute goals, and no elapsed-only failure or cancellation |
| `RISK-0161` | Fixture isolation | Shared baselines leak mutable state or conceal link/identity drift | Test maintainer / fingerprinted immutable owner, fresh scenario copy, link-safe verification, and cleanup evidence |
| `RISK-0162` | Runner consumption | A workflow-only shortcut reintroduces fan-out or hides incomplete coverage | Workflow maintainer / retain DEC-0019 topology, exact scenario ownership, and report both job count and runner consumption in `TEST-0146` |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0064` | Suite/boundary observability and same-commit baseline inventory | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | `TEST-0144`; focused runtime contract on PowerShell 5.1/7 | Schema, monotonic duration, output authority, and non-gating behavior review | Ready |
| `SUBF-0065` | Quick-adoption/bootstrap contract extraction and immutable fixture reuse | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | `TEST-0145`; focused hotspot owners and retained real slices | Variant mapping, adapter fidelity, fixture identity, security/recovery paths | Ready after `SUBF-0064` baseline |
| `SUBF-0066` | Cross-runtime full proof, hosted topology, and documentation closure | [Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) | `TEST-0146`; Windows 5.1/7, WSL Ubuntu, full suites, hosted jobs | Coverage authority, total runner use, soft goals, final scan | Ready after `SUBF-0065` |

## Decisions and relationships

- Hosted single-runner authority: [FEAT-0027](../FEAT-0027-v0104-runner-minute-efficiency/README.md) / [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md)
- Capability-owned test architecture: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Exact-tree reuse: [FEAT-0034](../FEAT-0034-ci-evidence-hygiene/README.md)
- Tracking and post-publication authority: [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87)

No new architectural decision is required: this correction implements the
existing DEC-0019 review condition after measured full-suite consumption became
materially worse, while preserving DEC-0022's separate-suite and fixture
ownership contracts.

## Definition of Ready

- [x] Stable `FEAT-0035`, `BUG-0017`, `SUBF-0064` through `SUBF-0066`, and linked issue #87 exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable without turning elapsed time into a gate.
- [x] Observation, evidence-level, boundary, fixture, compatibility, and lifecycle contracts are explicit.
- [x] Consumers, dependencies, governing decisions, and related features are identified.
- [x] `RISK-0158` through `RISK-0162` have owners and required evidence.
- [x] Three independently reviewable slices and gates are defined.
- [x] `TEST-0144` through `TEST-0146` and the verification approach are defined.
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

Pending implementation. The required post-development scan scope is the full
tracked repository with generated/binary/external surfaces explicitly listed;
the finite default budget is one initial scan and one confirmation scan only if
remediation changes the tree.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test commands and successful results recorded.
- [ ] Every subfeature review and the bounded post-development scan complete.
- [ ] No unresolved `Blocking` finding.
- [ ] Documentation, links, version, changelog, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable local and hosted CI gates pass.

## Post-merge release evidence

[Issue #87](https://github.com/hasanmanzak/meAndAI/issues/87) is the stable
external authority. Pull request, converged push, hosted checks, merge,
immutable release, cleanup, and post-publication verification remain `Pending`
until those facts exist and will be recorded externally without an
evidence-only candidate commit.
