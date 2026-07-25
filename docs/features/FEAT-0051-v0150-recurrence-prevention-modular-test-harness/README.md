# FEAT-0051 - Recurrence Prevention and Modular Test Harness

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed |
| Target version | 0.15.0 |
| Issue | [Issue #124](https://github.com/hasanmanzak/meAndAI/issues/124) |
| Pull request | Pending planning pull request; tracked through [issue #124](https://github.com/hasanmanzak/meAndAI/issues/124) |
| Decisions | [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md) |
| Tests | [Test scenarios](test-cases.md) |

This record registers approved planning scope. It does not authorize
implementation, change the current `0.14.5` protocol, or publish `0.15.0`.

## Problem

Confirmed tooling and implementation failures can recur because prior safe
solutions, unsafe retry paths, canonical owners, and sibling call sites are not
consulted through one explicit gate. Durable facts exist in dated records, but
there is no compact active signature index that routes later work to the
canonical correction and regression.

The test tree also repeats generic-looking mechanics inside capability suites,
while several large files mix runner, harness, scenario, assertion, support,
and fixture responsibilities. A name match alone does not prove logical
duplication, but the current planning baseline warrants contract-level
classification:

- `Add-Failure`: 17 definitions;
- `Assert-Equal`: 8 definitions;
- `Assert-True`: 7 definitions;
- `Assert-ThrowsLike`: 6 definitions; and
- `Assert-SequenceEqual`: 4 definitions.

The first migration candidates currently contain 3,297 lines in the
protocol-update adapter fixture, 3,152 lines in the capabilities-bootstrap
adapter fixture, and 11,227 lines in the quick-adoption suite. These counts are
baseline signals, not automatic duplication findings or size targets.

## Outcome

Before selecting a tool, adding a helper, or correcting a defect, an agent
checks prior safe work, active failure signatures, canonical owners, and all
related call sites. Confirmed recurrence knowledge is compact, portable, and
freshness-aware, while executable regression evidence remains authoritative.

Generic test mechanics gain focused canonical owners. The stable runner remains
thin; runtime cases, harness mechanics, capability support, documented
scenarios, and inert fixture state have explicit non-overlapping roles. The
architecture is applied to three declared hotspots through reviewable slices
without changing existing scenario identities, behavior, isolation, supported
runtimes, or workflow topology.

## Scope

- Add a prior-art and known-failure gate to protocol readiness, defect/finding
  correction, templates, the optional stability prompt, and project-memory
  guidance.
- Define a small recurring-failure signature contract containing the failure
  signature, affected contract, applicability, cause, canonical
  feature/decision/test, fixed release, required response, unsafe retry
  boundary, freshness, supersession, and review condition.
- Prohibit repeating the same failed tooling operation without new evidence or
  a materially different route.
- Require same-contract sibling inventory and canonical-owner classification
  before implementing a correction or helper.
- Inventory repeated helper families by semantics and centralize only proven
  generic failure collection, assertions, Git/blob/hash/byte mechanics,
  temporary-workspace mechanics, Markdown/link parsing, and runtime evidence.
- Replace caller-scope-dependent failure mutation with an explicit test context.
- Publish a bounded canonical-helper ownership list plus an AST guard against
  unauthorized local redefinitions and a narrowly reviewed allowlist.
- Separate root runner, common harness, executable case/scenario, capability
  support, fixture, mock, and runtime-evidence roles.
- Stop treating source substrings, TEST constants, or assertion names as proof
  that a runtime test executed.
- Migrate, in order, the protocol-update adapter, capabilities-bootstrap
  adapter, and quick-adoption suite.
- Append a `test-harness-modularity` semantic capability under
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
  during implementation without rewriting predecessor capabilities.

## Non-goals

- No AI-memory validator, background daemon, autonomous scan loop,
  validator-for-validator chain, universal clone detector, or raw conversation
  archive.
- No name-only helper merge or wholesale test-tree rewrite.
- No memory lookup as a substitute for executable regression evidence.
- No vendor-specific Codex memory as the portable authority.
- No production-module copy inside a fixture and no consumer-local copy of a
  protocol test, fixture, or helper.
- No shared mutable fixture, removal of process isolation, new workflow, job,
  matrix, runner fan-out, or elapsed-time-only gate.
- No absorption of [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
  and no reopening of completed issues
  [#114](https://github.com/hasanmanzak/meAndAI/issues/114),
  [#117](https://github.com/hasanmanzak/meAndAI/issues/117),
  [#119](https://github.com/hasanmanzak/meAndAI/issues/119), or
  [#121](https://github.com/hasanmanzak/meAndAI/issues/121).

## Readiness evidence

- Domain and contracts: recurrence signature, canonical owner, sibling surface,
  test context, runner, harness, executable case, documented scenario,
  capability support, fixture, mock, and runtime evidence are distinct concepts.
- Invariants: memory routes work but cannot complete a TEST; a TEST completes
  only when its exact runtime case executes and passes exactly once; fixtures
  cannot assert, aggregate, or complete scenarios; similar names are not
  duplication proof.
- Errors: missing, stale, superseded, ambiguous, duplicate, inferred, or
  unexecuted evidence fails closed unless the protocol explicitly permits a
  documented NotApplicable result.
- Compatibility: preserve every active TEST ID, result, public behavior,
  process boundary, fixture isolation rule, supported runtime, immutable
  predecessor capability, and workflow topology.
- Consumers and dependencies: common reusable behavior stays upstream;
  consumers provide only project-specific applicability and semantic evidence.
- Verification: one focused validation per implementation slice, one final full
  suite, one bounded confirmation scan, and no added hosted fan-out.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0228` <a name="risk-0228"></a> | Stale memory becomes permanent authority or substitutes for regression evidence. | [SUBF-0095](#subf-0095) / [issue #128](https://github.com/hasanmanzak/meAndAI/issues/128): require evidence, freshness, supersession, and an executable prevention barrier or explicit NotApplicable result. |
| `RISK-0229` <a name="risk-0229"></a> | A broad duplication detector yields false positives or grows into another validator framework. | [SUBF-0096](#subf-0096) / [issue #125](https://github.com/hasanmanzak/meAndAI/issues/125): classify contracts first and guard only the declared helper-owner list with a reviewed allowlist. |
| `RISK-0230` <a name="risk-0230"></a> | Harness consolidation changes scenario coverage, runtime results, or process isolation. | [SUBF-0096](#subf-0096) / [issue #125](https://github.com/hasanmanzak/meAndAI/issues/125) and [SUBF-0098](#subf-0098) / [issue #127](https://github.com/hasanmanzak/meAndAI/issues/127): preserve exact scenario/result ledgers and prove equivalence per slice. |
| `RISK-0231` <a name="risk-0231"></a> | Role separation hides integration behavior or turns shared infrastructure into a god harness. | [SUBF-0097](#subf-0097) / [issue #126](https://github.com/hasanmanzak/meAndAI/issues/126): allow only generic mechanics in the harness and keep capability semantics local. |
| `RISK-0232` <a name="risk-0232"></a> | Migration expands hosted-runner consumption or workflow topology. | [SUBF-0098](#subf-0098) / [issue #127](https://github.com/hasanmanzak/meAndAI/issues/127): no new workflow/job/matrix; use focused slice runs and one final full run. |
| `RISK-0233` <a name="risk-0233"></a> | Consumers without an automated test surface are forced into artificial assets. | [SUBF-0095](#subf-0095) / [issue #128](https://github.com/hasanmanzak/meAndAI/issues/128): permit explicit, reviewed NotApplicable evidence. |
| `RISK-0234` <a name="risk-0234"></a> | The work expands into a full test-framework rewrite. | [Issue #124](https://github.com/hasanmanzak/meAndAI/issues/124): enforce the four-slice ledger and three declared migration hotspots. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0183](test-cases.md#test-0183), [TEST-0184](test-cases.md#test-0184), [TEST-0185](test-cases.md#test-0185), [TEST-0186](test-cases.md#test-0186), [TEST-0187](test-cases.md#test-0187), and [TEST-0188](test-cases.md#test-0188) |
| Test code | Not started | Exact executable owners are established in the owning subfeature before implementation. |
| Baseline run | Planning structure passed; planned behavior not run | `tests/protocol.tests.ps1 -StructureOnly` passed on 2026-07-25; no v0.15.0 executable test code exists. |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0095` <a name="subf-0095"></a> | Recurrence-prevention and durable prior-solution gate | [Issue #128](https://github.com/hasanmanzak/meAndAI/issues/128) | [TEST-0183](test-cases.md#test-0183); not started | Required after the slice | Proposed |
| `SUBF-0096` <a name="subf-0096"></a> | Canonical shared test-harness and helper ownership | [Issue #125](https://github.com/hasanmanzak/meAndAI/issues/125) | [TEST-0184](test-cases.md#test-0184); not started | Required after the slice | Proposed |
| `SUBF-0097` <a name="subf-0097"></a> | Runner, harness, case/scenario, support, fixture, and runtime-evidence separation | [Issue #126](https://github.com/hasanmanzak/meAndAI/issues/126) | [TEST-0185](test-cases.md#test-0185), [TEST-0186](test-cases.md#test-0186); not started | Required after the slice | Proposed |
| `SUBF-0098` <a name="subf-0098"></a> | Staged self-application, duplicate-family consolidation, append-only capability, and compatibility closure | [Issue #127](https://github.com/hasanmanzak/meAndAI/issues/127) | [TEST-0187](test-cases.md#test-0187), [TEST-0188](test-cases.md#test-0188); not started | Required after the slice | Proposed |

## Decisions and relationships

- Decision: [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md).
- Dependencies: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md),
  [FEAT-0039](../FEAT-0039-v0130-test-runtime-efficiency/README.md),
  [FEAT-0046](../FEAT-0046-v0141-consumer-nonduplication-mandate/README.md),
  [DEC-0002](../../decisions/DEC-0002-project-local-memory.md),
  [DEC-0015](../../decisions/DEC-0015-event-triggered-stability-cycles.md),
  [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md),
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md),
  and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md).
- Concrete propagation precedent: [FEAT-0048](../FEAT-0048-v0143-shared-merge-evidence/README.md).
- Separate runtime residual: [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Acceptance criteria.
- [x] Domain/boundary contracts, consumers, and dependencies.
- [x] Numbered risks and proposed decision.
- [x] Reviewable decomposition with a linked issue for every slice.
- [x] Numbered test scenarios and verification approach.
- [x] Test-code and baseline-run states recorded.

Gate 1 is documented for future implementation. A separate maintainer directive
is still required before executable work begins.

## Acceptance criteria

1. A prior-art and known-failure gate resolves matching active signatures,
   canonical owners, sibling surfaces, and unsafe retry boundaries before work.
2. Durable recurrence entries are compact, evidence-linked, freshness-aware,
   secret-free, correctly partitioned, and never treated as runtime proof.
3. Every corrected defect or finding records an executable recurrence barrier or
   a reviewed NotApplicable rationale.
4. Truly generic helper families have one canonical owner; same-name but
   semantically distinct helpers remain local and documented.
5. The redefinition guard is bounded to the reviewed owner list and allowlist.
6. Test context is explicit and runtime TEST completion is exact-once; missing,
   duplicate, inferred, and unexecuted evidence fails closed.
7. Runner, harness, case/scenario, capability support, fixture, and mock roles
   satisfy their declared boundaries.
8. The three declared hotspots migrate in order without changing active TEST
   identities, results, behavior, isolation, or supported runtimes.
9. `test-harness-modularity` is appended without rewriting predecessor
   capabilities or invalidating compatible terminal ledgers.
10. No workflow, job, matrix, hosted fan-out, consumer-local common asset, or
    unbounded validation loop is introduced.

## Self-review

Planning review date: 2026-07-25.

Declared review scope is this planning record, its decision, scenarios, indexes,
issue links, and project-memory handoff. Production code, capability blobs,
workflows, version files, and release state are excluded because implementation
has not been authorized. The finite validation budget is `git diff --check`, one
`StructureOnly` run, link/ID consistency, and one fresh-diff review.

The first `StructureOnly` run exposed one pre-existing planning-integrity gap:

| ID | Severity | Disposition | Finding | Resolution |
| --- | --- | --- | --- | --- |
| `FIND-0243` <a name="find-0243"></a> | Medium | `Blocking` | The canonical scenario registry had no non-executable evidence kind for numbered scenarios that Gate 1 requires before their test code exists, so the six new planned scenarios could not be registered honestly. | Extended existing [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) with `PlannedDocumentation`: the exact owner must be a feature `test-cases.md`, its declaration must remain `Planned`, and no active `.ps1` may assert the ID. `StructureOnly` passed after the correction. Implementation must atomically replace this authority with the exact executable suite. |
| `FIND-0244` <a name="find-0244"></a> | Medium | `Blocking` | The first `PlannedDocumentation` guard draft re-read the entire test tree once per planned ID and duplicated the historical-supersession scan family. | Built one source-to-scenario inventory and reused it for planned and superseded checks; exact source-path diagnostics remain, and [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) passed through the final `StructureOnly` confirmation. |

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test commands and successful results recorded.
- [ ] Bounded self-review and required convergence scan complete.
- [ ] No unresolved Blocking finding; all other dispositions have evidence.
- [ ] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #124](https://github.com/hasanmanzak/meAndAI/issues/124) |
| Release authority | Pending implementation and immutable v0.15.0 publication |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
