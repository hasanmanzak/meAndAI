# FEAT-0039 - Reusable Test Fixtures and Runtime-Cost Guardrails

| Field | Value |
| --- | --- |
| Classification | Common-protocol semantic capability and test-runtime correction / `TASK-0001` |
| Status | Complete |
| Target version | 0.13.0 |
| Issue | [#95](https://github.com/hasanmanzak/meAndAI/issues/95) |
| Pull request | Recorded through [issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) after creation |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| Tests | [TEST-0157 through TEST-0160](test-cases.md) |

## Problem

The common test-architecture contract requires capability-local mutable state
and explicitly owned immutable fixtures, but it does not mechanically require
equivalent expensive setup to be reused or make an unreviewed increase in Git,
launcher, adapter, or child-process construction fail. A feature can therefore
remain structurally green while repeatedly rebuilding equivalent repositories,
remotes, archives, or process boundaries.

The regression is material. The exact hosted pull-request evidence that
triggered this work increased the Windows test step to 20 minutes 37 seconds
and the Ubuntu test step to 6 minutes 55 seconds. The increase is not explained
by fixture copying alone: instruction-graph acquisition added one `ls-tree` and
per-blob `cat-file` process work to a pre-existing broad launcher and adapter
matrix. Runtime cost is therefore a logical boundary-ownership problem as well
as a fixture-lifecycle problem.

## Outcome

Repositories with expensive repeatable test setup can adopt one release-
declared `test-runtime-efficiency` semantic capability. Equivalent immutable
inputs build once at the narrowest safe lifecycle scope, every case receives an
isolated mutable derivative, and owner-bound machine-readable operation
budgets prevent silent fixture or boundary-count regressions.

Elapsed time remains observational. Deterministic operation identity and count
are the review gate: merely green tests cannot close this feature while the
known expensive operation inventory is unchanged.

## Scope

- Append one immutable Semantic `test-runtime-efficiency` capability without
  changing the existing `test-architecture` definition or catalog entry.
- Extend the existing test runtime only with strict contract import, route
  resolution, observation formatting, and parent-authoritative parsing.
- Keep fixture identity, reuse, derivative isolation, cleanup, budgets,
  wrappers, evidence-level decisions, and assertions under their actual
  capability owners.
- Bind each immutable fixture to one canonical owner, stable key, builder
  identity, `SuiteProcess` lifecycle, input digest, and before/after
  fingerprint.
- Provision distinct mutable derivatives without sharing worktrees, refs,
  remotes, mock state, credentials, or environment state between cases.
- Inventory and budget immutable builds/reuse, mutable provisioning, Git
  `init`/`clone`/`bundle`/`worktree`, launcher/adapter calls, child processes,
  graph acquisition, cleanup, and leaks.
- Reject undeclared construction, conflicting or aliased identity, duplicate
  equivalent builds, immutable mutation, cleanup leaks, missing observations,
  and unreviewed budget increases before authoritative success publication.
- Optimize in measured order: quick-adoption, capabilities-bootstrap,
  instruction-graph discovery, then any remaining materially expensive owner.
- Retain representative real Git, launcher, process, security, recovery,
  TOCTOU, credential, path/link/reparse, and native-Windows vertical slices.
- Amend the common protocol so reuse-first provisioning, evidence-level
  justification, and operation-budget review are normative.

## Non-goals

- Removing, renaming, or weakening active `TEST-NNNN` scenarios, declared
  variants, supported runtimes, security negatives, or fail-closed evidence.
- Sharing mutable repositories, worktrees, refs, remotes, mock state,
  credentials, or environment state between cases.
- Replacing behavioral evidence with source-string assertions or mocks that do
  not implement the production contract.
- Adding a persistent fixture service, hosted fan-out, self-hosted runner,
  cross-runner cache, or elapsed-time pass/fail threshold.
- Introducing runner-scoped or cross-process immutable sharing in this
  feature. Material residual duplication would require a separate decision.
- Changing instruction-graph semantics or performing a production
  `cat-file --batch` optimization before fixture and evidence-level reductions
  are measured. That I/O change requires its own risk review if still needed.

## Contracts and readiness evidence

### Fixture identity

- `Owner` is one normalized repository-relative canonical suite identity.
- `Key` is a stable lowercase slash-separated semantic identity; random paths,
  GUIDs, and runtime-specific temporary locations are forbidden.
- `Builder` identifies the one construction contract for the fixture.
- `Scope` is `SuiteProcess` for this feature.
- `InputDigest` is `sha256:` plus the digest of builder identity, canonical
  scalar inputs, and ordered committed Git mode/blob inputs. Checkout-smudged
  bytes are not an independent committed-input authority.
- `FingerprintBefore` and `FingerprintAfter` cover the immutable bytes, modes,
  refs, and clean-state invariants declared by the owner.
- The same owner/key/builder/digest request builds exactly once and increments
  reuse thereafter. A changed owner or digest, an alias key for the same
  builder/digest, mutation, link/reparse escape, or unknown scope fails closed.

### Mutable derivative and cleanup

Every request that may mutate state receives a distinct path and derivative
identity bound to its immutable parent. Reset means a fresh or verified-clean
mutable derivative, never an implicit immutable rebuild. Cleanup records every
owned resource exactly once; failed cleanup or a surviving owned resource
blocks the suite's operation observation and canonical success record.

### Operation observation and budget

Each applicable suite emits exactly one owner/route/runtime-bound operation
observation immediately before its existing final scenario or compatibility
result. Counters are sorted by stable kind and identity and contain no random
path data. Nested support processes contribute one bounded stdout summary to
their owning suite rather than writing once per operation or maintaining a
shared fixture service.

The repository budget declares the regression trigger, exact measurement-base
commit, observer digest, owner, route, runtime class, baseline count, maximum,
and closure target. An absent route, missing/duplicate/malformed observation,
undeclared operation, or count above the maximum fails before authoritative
success publication. A budget increase requires explicit linked review;
measured reductions lower the budget in the same change.

### Consumers, dependencies, and compatibility

The affected consumers are the stable parent runner, direct focused-suite
entry points, common test runtime, capability catalog and review lifecycle,
initial-adoption suites, instruction-graph suite, scenario authority, Windows
PowerShell 5.1, PowerShell 7 on Windows/Linux, Git, and the existing one-
Windows/one-Ubuntu hosted topology. Suite processes, scenario-result schemas,
stable job identities, routes, and exact-tree reuse remain intact.

The current `test-architecture` capability is immutable under DEC-0022 and is
not edited. Existing one-entry consumer ledgers remain valid catalog prefixes;
only the appended capability requires new semantic review. Applicability is an
automated validation surface with expensive deterministic repository, archive,
process, container, service, or equivalent setup. A reviewed repository with
no such setup may record `NotApplicable`.

### Baseline state

- Regression trigger: PR #94 head
  `327a832f24c981c9f55c34a8ec8d9859667ffb06` and hosted run
  [29874703292](https://github.com/hasanmanzak/meAndAI/actions/runs/29874703292).
- Measurement base: immutable v0.12.7 commit
  `6b01299cfe484c900944b7435d4fef43b11fc38d`.
- Historical PR #94 full command-discovery capture was stopped because the
  observer itself produced prohibitive overhead. The hosted durations remain
  regression-trigger evidence; they are not operation-count authority.
- A lower-overhead exact-base observer is identified by
  `sha256:ed9a8290b24b191274f35c4bef2cd9af14157e2927be94848a2561a54294e04b`.
  Its bootstrap/graph owner completed, but the parallel parent timed out before
  publishing that result. The quick-adoption `All` owner reached the bounded
  30-minute measurement ceiling without completing.
- The interrupted quick-adoption capture produced a diagnostic lower bound of
  15,026 Git process-start events, including at least 85 `init`, 65 `clone`,
  368 `ls-tree`, and 330 `cat-file` starts. These raw Trace2 counts include Git
  child plumbing and are intentionally not the enforcement identity.
- Exact owner-owned construction counts were then frozen from the immutable
  base's executable fixture and graph routes. The implementation gate uses
  these logical counts and targets; focused dynamic observations must reproduce
  them after owner instrumentation exists.

| Owner / operation | Exact-base logical count | Closure maximum | Rationale |
| --- | ---: | ---: | --- |
| Quick-adoption owner fixture `git init`, including protocol history | 47 | 11 | Three repeated normal seed shapes build once; special security/history/link/race shapes remain fresh |
| Bootstrap owner fixture `git init` | 38 | 3 | Consumer, protocol, and empty-remote prepared owners build once |
| Bootstrap owner fixture `git clone` | 72 | 2 | Only the two prepared checkout owners clone; every case receives an isolated copied derivative |
| Bootstrap owner `bundle create` | 2 | 2 | Immutable bundle identity remains real evidence |
| Bootstrap owner publication `push` | 36 | 36 | Per-case empty-remote publication remains real integration evidence |
| Bootstrap-owned instruction-graph child PowerShell process | 6 | 4 | Count/projection drift move to the production-owned identity contract; success/base/digest retain isolated evidence |
| Bootstrap-owned instruction-graph isolated adapter acquisition | 5 | 3 | The same two pure identity drifts no longer reprovision an adapter boundary |

Quick-adoption's reusable request identities are exactly connected seed with
workflow (`5` requests to `1` build), connected seed without workflow (`10` to
`1`), and the candidate's current managed consumer at v0.13.0 (`6` to `1`).
The exact-base inventory used v0.12.7 for that current shape. v0.9.2, v0.13.1,
empty/no-head, completed-adoption, shallow/history, link, hook, race, and other
shape-defining fixtures remain fresh. Bootstrap retains every existing case;
only immutable preparation is shared.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0157 through TEST-0160](test-cases.md) |
| Test code | Complete | `TEST-0157` passed after its planned catalog-count red result; `TEST-0158` and `TEST-0159` pass with owner-specific fixture identity/isolation, cleanup, strict observation parsing, recursive bypass preflight, and parent-authoritative budget evidence; the local/structural portion of `TEST-0160` is green while candidate hosted execution remains external delivery evidence |
| Baseline run | Ready | Exact logical construction baselines and lower targets are frozen above; the 30-minute observer ceiling and diagnostic Trace2 lower bound are recorded without turning elapsed time or raw child plumbing into authority |

### Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0184` | Evidence integrity | Moving variants below real infrastructure removes material Git/process/security evidence | Test maintainer / explicit evidence-level inventory plus retained representative vertical slices in `TEST-0159` and existing scenarios |
| `RISK-0185` | Fixture isolation | Reuse leaks mutable refs, bytes, paths, mock state, credentials, or environment between cases | Fixture owner / immutable fingerprint, distinct derivative identity, link-safe cleanup, and mutation/isolation negatives in `TEST-0158` |
| `RISK-0186` | Instrumentation bypass | Direct construction or an alias wrapper avoids the budget | Test-runtime maintainer / canonical wrappers, recursive AST preflight, declared identities, and bypass negatives in `TEST-0159` |
| `RISK-0187` | Budget validity | A stale commit, route, or runtime class makes the ratchet misleading | Workflow maintainer / exact base and observer digest, explicit owner/route/runtime keys, deterministic focused rerun, and review-required deltas |
| `RISK-0188` | Capability applicability | A simple consumer is burdened with infrastructure it does not need | Protocol maintainer / narrow expensive-setup applicability and reviewed `NotApplicable` evidence under DEC-0022 |
| `RISK-0189` | Observer cost and gaming | Per-operation I/O slows tests or broad counters conceal expensive substitutions | Test-runtime maintainer / in-memory counters, one nested-process summary, stable logical identities, focused overhead observation, and exact negative coverage |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0073` | Protocol/capability contract and append-only catalog entry | [Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) | `TEST-0157`; planned red (`expected 2, observed 1`), then capability-catalog and capability-review green | Existing tuple/blob preserved; one-entry ledger remains a valid prefix; applicability and immutable definition reviewed | Complete |
| `SUBF-0074` | Minimal operation contract, owner observations, parent enforcement, and bypass guardrails | [Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) | `TEST-0158`, `TEST-0159`; focused runtime and negative checks passed on Windows PowerShell 5.1 | Generic fixture framework rejected; strict route/counter schema, canonical observation order, and parent authority reviewed | Complete |
| `SUBF-0075` | Quick-adoption reuse-first conversion and evidence-level reduction | [Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) | `RepositoryRoutes` passed in 173.8 seconds; final `All` passed in 776.2 seconds with init 11 | Security/recovery/TOCTOU/link/native evidence retained; repeated family init reduced from 47 to its reviewed maximum of 11 | Complete |
| `SUBF-0076` | Capabilities-bootstrap, instruction-graph, and remaining expensive-owner conversion | [Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) | Final bootstrap `All` passed in 267.6 seconds with exact owner observation | Adapter/graph fidelity retained; exact closure was init 3, clone 2, bundle 2, push 36, child process 4, and graph acquisition 3 | Complete |
| `SUBF-0077` | Cross-runtime, hosted-topology, protocol, documentation, and measured closure | [Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) | `TEST-0160`; local Full passed in 1,340.2 seconds and the final `WindowsNative` rerun passed in 341.0 seconds | Same-job Windows PowerShell 7 focused coverage and existing Linux PowerShell 7 Full coverage are configured without hosted fan-out; candidate hosted execution remains delivery evidence; residual wall time is owned by issue #98 | Complete |

## Decisions and relationships

- Hosted runner and exact-tree reuse authority:
  [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md).
- Append-only semantic capability and reviewed consumer adoption authority:
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md).
- Immutable-fixture precedent:
  [FEAT-0024](../FEAT-0024-v0101-parallel-windows-validation/README.md).
- Corrective parent and evidence-level precedent:
  [FEAT-0035](../FEAT-0035-test-runtime-efficiency/README.md).
- Regression-triggering instruction-graph work:
  [FEAT-0037](../FEAT-0037-v0126-instruction-graph-adoption-containment/README.md).
- Tracking and future post-publication authority:
  [issue #95](https://github.com/hasanmanzak/meAndAI/issues/95).
- Residual wall-clock optimization successor:
  [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

No new decision is required while reuse remains capability/process-local and
DEC-0022's append-only catalog model is unchanged. Runner-scoped or cross-
process sharing, or a different catalog-evolution model, requires a new
decision before implementation.

## Definition of Ready

- [x] Stable `FEAT-0039`, `TASK-0001`, `SUBF-0073` through `SUBF-0077`, and linked issue #95 exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria and failure behavior are measurable without an elapsed-time gate.
- [x] Fixture, derivative, observation, budget, ownership, lifecycle, error, and compatibility contracts are explicit.
- [x] Consumers, dependencies, existing decisions, related features, and version boundary are identified.
- [x] `RISK-0184` through `RISK-0189` have owners and responses.
- [x] Five independently reviewable slices and gates are defined.
- [x] `TEST-0157` through `TEST-0160` and the verification approach are defined.
- [x] Exact `6b01299...` owner-owned logical counts, the bounded dynamic observer result, per-owner budgets, and lower quick-adoption/bootstrap closure targets are frozen.
- [x] Test-code state, the initial four-ID structural red result, and the `TEST-0157` red-to-green result are recorded; implementation is authorized by the satisfied numeric baseline gate.

## Acceptance criteria

1. The capability catalog appends exactly one immutable Semantic
   `test-runtime-efficiency` definition; the existing entry remains byte-
   identical, historical ledger prefixes remain valid, and only the new entry
   requires review.
2. Every applicable expensive immutable fixture has one owner, stable key,
   builder, scope, input digest, and before/after fingerprint. Equivalent
   requests in one suite process produce exactly one build and observed reuse.
3. Mutable derivatives have distinct identities and cannot mutate another
   derivative or the immutable baseline; dirty refs, mode/hash drift,
   link/reparse escape, reset failure, and cleanup leaks fail closed.
4. Every applicable suite emits one valid operation observation before its
   unchanged final result. Missing, duplicate, malformed, undeclared, aliased,
   or over-budget evidence blocks authoritative success.
5. Direct focused-suite execution and the parent runner use the same owner,
   route, runtime, fixture, and budget contracts while preserving separate
   suite processes and canonical scenario authority.
6. Adding another case that requests an equivalent baseline increases reuse,
   not build count. Adding an undeclared Git/launcher/process construction or
   raising a budget without linked review fails mechanically.
7. Every active scenario and variant retains one executable owner and a
   faithful evidence level; real infrastructure remains wherever filesystem
   identity, process behavior, credentials, recovery, TOCTOU, or OS-native
   semantics supply material evidence.
8. Quick-adoption and capabilities-bootstrap each close with at least one
   measured expensive-boundary count below its exact-base baseline; unchanged
   expensive counts cannot satisfy Definition of Done.
9. Windows PowerShell 5.1, PowerShell 7 on Windows/Linux, `WindowsNative`,
   focused owners, full local validation, and the existing one-Windows/one-
   Ubuntu hosted topology pass without weakened evidence or added fan-out.
10. Closure records same-topology before/after runner consumption and hotspot
    duration observations. Missed 2/3-minute soft goals require maintainer
    disposition and a concrete successor owner; elapsed time alone never
    changes a correct result.

## Verification approach

Freeze exact-base counts with a measurement-only observer whose digest and
source commit are recorded. Add scenario authority and expected-red tests
before each contract. Validate every slice with its focused owner, then run
PowerShell 5.1 and 7 focused routes, one Windows and one Linux full suite, the
existing `WindowsNative` profile, structural validation, one fresh-diff self-
review, and the protocol's single bounded post-development scan. Hosted
closure compares total runner consumption and operation budgets as well as
observational elapsed time.

## Self-review

The first fresh-diff review found four blocking gaps: incomplete operation-
bypass inventory, silently accepted bootstrap cleanup leakage, mode-blind
fixture fingerprints, and an under-bound quick-adoption input digest. Test-
first negatives reproduced each gap before remediation. A confirmation review
then found missing `worktree`, launcher/adapter variable-invocation, and
recursive-cleanup call-site inventory. The ratchets now cover the complete
owner sources, bootstrap cleanup verifies no surviving resource, fingerprints
include Windows attributes or Unix modes, and the quick-adoption digest binds
its owner source plus canonical committed inputs. A final independent review
then found one recovery root whose best-effort cleanup lacked a survivor gate,
one known-owner/unknown-route budget bypass, and one dynamically assembled
direct `git clone` missed by the static operation inventory. The recovery root
now fails before success if it survives, every known owner requires an explicit
reviewed route, `WindowsNative` is explicitly non-observing, and unclassified
Git splats are exactly inventoried with a negative. Remediation re-review
reported no unresolved blocking finding.

## Definition of Done

- [x] Implemented acceptance criteria pass locally and structurally; hosted and publication facts remain external delivery evidence.
- [x] Mandatory test code and exact scenario mapping complete.
- [x] Focused, Windows PowerShell 5.1 Full, `WindowsNative`, and workflow-semantic evidence recorded.
- [ ] Candidate Windows/Ubuntu hosted execution and same-topology timing recorded.
- [x] Every subfeature review and the bounded completion scan have no unresolved `Blocking` finding.
- [x] No fixture/process budget increase or evidence-level reduction lacks explicit review evidence.
- [x] Protocol, capability catalog, version, changelog, links, and project memory are current.
- [ ] Pull request, hosted run, merge, release, and external evidence authority are cross-linked after those facts exist.

## Post-merge release evidence

[Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) is the stable
external authority. Pull request, converged push, hosted checks, merge,
immutable release, asset digests, exact target commit, branch cleanup, and
post-publication verification remain `Pending` until those facts exist. The
missed 2/3-minute soft goals are explicitly accepted as non-gating here and
assigned to [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
without weakening this feature's evidence or operation-count ratchets.
