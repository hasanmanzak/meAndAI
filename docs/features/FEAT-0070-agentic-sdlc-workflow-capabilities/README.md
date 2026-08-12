# FEAT-0070 - Protocol-Owned Workflow Contracts and Bounded Agent Execution

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed; Definition of Ready incomplete; implementation not authorized |
| Target version | Unassigned; depends on accepted architecture and predecessor review |
| Issue | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) |
| Parent epic | [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
| Pull request | Draft [PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) |
| Decisions | Proposed [DEC-0038](../../decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md) and proposed [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md) |
| Architecture | [Agentic SDLC Workflow Architecture](../../architecture/agentic-sdlc-workflows/README.md) and [delivery plan](../../architecture/agentic-sdlc-workflows/delivery-plan.md) |
| Originating idea | [IDEA-0001](../../ideas/IDEA-0001-role-based-multi-agent-protocol.md) |
| Tests | [TEST-0227](test-cases.md#test-0227) through [TEST-0233](test-cases.md#test-0233) |

## Problem

Repository work currently receives rich protocol and project directives, but
there is no reusable contract that resolves a user intent or command to one
bounded workflow, selects applicable rules without copying them, assigns a
specialist role without inventing authority, packages exact context, and
returns evidence to the canonical SDLC.

Hard-coding DDD, Rich Entity Model, TDD, SOLID, documentation links, review,
test, and release behavior into `/develop`, `/review`, `/document`, or another
command would make aliases semantic owners and create drift. Treating analyst,
developer, reviewer, tester, documenter, or orchestrator names as standing
permissions would bypass the grant model in
[DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md).

The existing multi-agent idea also needs explicit activation, concurrency,
single-writer, recursion, context, handoff, evidence, and cost limits before it
can move from possibility to executable behavior.

## Outcome

meAndAI publishes an inspectable, release-bound Workflow Contract Catalog,
Execution Role Contract Catalog, resolver, Context/Handoff Router, and optional
bounded orchestrator. Natural language, CLI, workflow, service, and slash
commands are thin aliases over the same contracts. Applicable canonical rules
and project overlays are referenced rather than copied. Roles bound work but
do not grant it. Evidence, not actor claims, drives the existing SDLC.

Small work remains single-agent. Larger work may use at most a bounded team,
one writer per slice, read-heavy parallel lanes, exact handoffs, and no
recursive delegation in the first release.

## Scope

- Define workflow identity, schema/revision, classes, admission, inputs,
  outputs, effects, grants, directive references, roles, context, evidence,
  concurrency, recovery, and alias bindings.
- Resolve command and natural-language aliases many-to-many without making
  aliases semantic owners.
- Select canonical rules/practices by task and domain applicability, including
  project overlays and explicit non-applicability.
- Keep workflow-run state separate from Gate 0 through Gate 7 and existing
  adoption/update/release application state machines.
- Define execution roles as responsibility and maximum effect envelopes,
  separate from actor identity and real grants.
- Define exact outbound and return handoff envelopes with base, scope,
  authority, recurrence, acceptance, tests, budget, expiry, and stop evidence.
- Default to one agent; define bounded activation, read-heavy parallelism,
  single-writer ownership, stale/overlap rejection, and recursive-delegation
  denial.
- Provide phased read-only, single-agent, multi-agent, delivery, and immutable
  consumer-adoption routes only after their prerequisites and directives.

## Non-goals

- A closed command list or one workflow per command.
- Copying protocol rules, project instructions, practices, or tests into every
  workflow or consumer.
- Treating skills, personas, roles, prompts, or agent output as normative
  acceptance or grant authority.
- Replacing the semantic capability or compiled policy catalogs.
- Running a mandatory analyst/developer/reviewer/tester chain for every task.
- Parallel writers, recursive worker delegation, unbounded context loading, or
  autonomous roadmap selection in the first release.
- Bypassing mandatory repository-instruction, recurrence, readiness,
  test-first, review, merge, release, or consumer-adoption gates.
- Implementing production code, tests, workflows, prompts, provider effects,
  consumers, releases, or authority transfer in this records-only proposal.

## Readiness evidence

- Domain and contracts: command alias, Workflow Contract, workflow run,
  directive reference, applicability, project overlay, skill, role assignment,
  actor identity, real grant, writer lease, context envelope, result envelope,
  gate assessment, and protocol application are distinct semantic types.
- Current authorities:
  [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
  owns product/host/grant boundaries;
  [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
  owns semantic adoption capabilities;
  [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md)
  owns recurrence/evidence routing; and
  [FEAT-0057](../FEAT-0057-explicit-sdlc-backlog-governance/README.md)
  owns the proposed explicit SDLC projection.
- DRN prior art: exact-current examples are evaluated in the
  [architecture disposition](../../architecture/agentic-sdlc-workflows/README.md#11-drn-prior-art-disposition).
  The reusable ideas are thin routing, workflow ownership, focused skills,
  explicit state, and bounded subagent use; copied command rules, mandatory
  artifact chains, long personas, and routine approval envelopes are rejected.
- Conditional delegated-execution recurrence: the
  [small-context packet advancement](../../../.ai/memory/project.md#small-context-packet-advancement-outruns-the-canonical-ledger)
  rule is not feature-wide authority. It applies only when a future delegated
  worker operates from a frozen packet brief under that recurrence's recorded
  conditions; that handoff must carry its safe response and unsafe retry
  boundary under Gate 0. The current records packet separately follows the
  [untracked governance packet route](../../../.ai/memory/project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph)
  and [canonical-link route](../../../.ai/memory/project.md#record-synchronization-reintroduces-noncanonical-cross-record-links).
- Consumers and compatibility: released definitions are upstream-owned and
  pinned. Consumers may supply project-specific configuration and evidence but
  cannot shadow common workflow, role, router, or regression assets.
- Dependencies: accepted lifecycle semantics, exact workflow schema, runtime
  state owner, applicability contract, pilot selection, and the relevant
  [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
  execution/evidence foundations remain open.
- Verification: tests must prove behavior through canonical runtime and
  structural owners. Do not create validator-for-validator or agent-self-
  certification chains.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0326` <a name="risk-0326"></a> | Command-local copies of protocol or project rules drift across development, review, tests, and documentation. | Workflow owner / canonical directive references, applicability resolution, and [TEST-0228](test-cases.md#test-0228). |
| `RISK-0327` <a name="risk-0327"></a> | Role or persona names are treated as repository, provider, merge, or release grants. | Authority owner / distinct actor-role-grant types, non-transitive checks, and [TEST-0230](test-cases.md#test-0230). |
| `RISK-0328` <a name="risk-0328"></a> | Two writers overlap or a stale writer overwrites another slice. | Orchestration owner / single writer, exact base/lease, overlap rejection, and [TEST-0230](test-cases.md#test-0230). |
| `RISK-0329` <a name="risk-0329"></a> | Recursive delegation or fixed agent chains create unbounded cost, latency, and unclear ownership. | Orchestration owner / hard first-release topology and [TEST-0232](test-cases.md#test-0232). |
| `RISK-0330` <a name="risk-0330"></a> | Minimum-context routing omits required authority, recurrence, or acceptance evidence, or includes unnecessary sensitive content. | Router owner / typed required fields, reference-first redaction, mandatory rereads, expiry, and [TEST-0231](test-cases.md#test-0231). |
| `RISK-0331` <a name="risk-0331"></a> | A completed workflow or reviewer statement advances a gate without canonical evidence. | Lifecycle owner / evidence-derived assessment and [TEST-0229](test-cases.md#test-0229). |
| `RISK-0332` <a name="risk-0332"></a> | Multi-agent ceremony makes small work slower or noisier. | Resolver owner / single-agent default, material activation threshold, bounded budget, and [TEST-0232](test-cases.md#test-0232). |
| `RISK-0333` <a name="risk-0333"></a> | A consumer copies catalogs or a delivery alias performs provider/release effects before execution-authority prerequisites exist. | Protocol/distribution owner / pinned upstream assets, exact grants, held provider slice, and [TEST-0233](test-cases.md#test-0233). |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0227](test-cases.md#test-0227) through [TEST-0233](test-cases.md#test-0233) |
| Test code | Planned / not started | Future protocol runtime and existing structural owners; exact allocation is a DoR gap |
| Baseline run | Not run | Records-only scope; expected-red design is required before each executable slice |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0160` <a name="subf-0160"></a> | Workflow Contract schema, catalog, family, revision, immutable binding, and command/natural-language aliases | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) | [TEST-0227](test-cases.md#test-0227); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0161` <a name="subf-0161"></a> | Read-only SDLC admission plus canonical rule/practice and project-overlay applicability resolution | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) | [TEST-0228](test-cases.md#test-0228), [TEST-0229](test-cases.md#test-0229); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0162` <a name="subf-0162"></a> | Execution role contracts, exact context/handoff compiler, result assessment, and one single-agent pilot | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) | [TEST-0230](test-cases.md#test-0230), [TEST-0231](test-cases.md#test-0231); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0163` <a name="subf-0163"></a> | Material activation, bounded team selection, read-heavy parallelism, one writer, stale/overlap rejection, and recursive-delegation denial | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) | [TEST-0232](test-cases.md#test-0232); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0164` <a name="subf-0164"></a> | Exact-grant delivery/protocol-lifecycle integration and immutable consumer distribution | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) | [TEST-0233](test-cases.md#test-0233); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed / dependency-held |

## Decisions and relationships

- Proposed architecture decision:
  [DEC-0038](../../decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md).
- Proposed lifecycle decision:
  [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md).
- Parent: [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179).
- Lifecycle predecessor/sibling:
  [FEAT-0057](../FEAT-0057-explicit-sdlc-backlog-governance/README.md).
- Technical context: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
  remains the accepted protocol platform authority; this feature does not edit
  its active [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md)
  delivery ledger.

## Definition of Ready

- [x] Stable ID, linked issue, parent, problem, outcome, scope, non-goals, and
  measurable acceptance criteria.
- [x] Preliminary semantic boundaries, risks, proposed decisions, slices, and
  numbered scenario intent.
- [x] DRN prior art, canonical owners, recurrence applicability, consumer
  boundary, and not-run states recorded.
- [ ] Maintainer acceptance of proposed [DEC-0038](../../decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md)
  and required parts of proposed [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md).
- [ ] Workflow identity, schema format, immutable binding, applicability,
  ambiguity, state persistence, expiry, redaction, retry, and recovery frozen.
- [ ] First pilot and exact accepted predecessor selected.
- [ ] Worker ceiling, parallel-writer ban, activation threshold, and mandatory
  independent-review classes accepted.
- [ ] Relevant execution-authority/evidence predecessors resolved.
- [ ] Target version, exact executable owners, baseline, expected-red matrix,
  and validation budgets accepted.
- [ ] Separate explicit implementation directive names one slice and effect
  boundary.

## Acceptance criteria

1. Natural-language and command aliases resolve to one versioned Workflow
   Contract without owning its semantics.
2. Alias changes cannot alter workflow behavior, gates, directives, effects,
   or authority.
3. Every workflow declares complete admission, input/output, effect, grant,
   directive, role, context, evidence, concurrency, recovery, and adapter
   metadata or fails closed.
4. Workflow families remain extensible and do not become grants.
5. Canonical rules and practices are referenced, not copied into commands,
   roles, or consumers.
6. Domain development selects DDD/Rich Entity/TDD/SOLID as applicable;
   non-domain work records non-applicability; every record-emitting workflow
   selects documentation-graph rules.
7. Gate 0 through Gate 7, workflow-run state, and protocol application state
   remain distinct; a completed run cannot self-advance a gate.
8. Missing readiness, ambiguous recurrence, stale base, missing authority, or
   incomplete evidence denies admission or assessment as designed.
9. Actor identity, role assignment, writer lease, and real grant are separate;
   roles cannot broaden authority.
10. Outbound/return handoffs bind exact base, scope, paths, authority,
    directives, recurrence, acceptance, tests, budget, expiry, result, findings,
    and stale-state evidence.
11. Context minimization cannot bypass mandatory instruction and recurrence
    reads and does not disclose unnecessary sensitive content.
12. One agent is selected for small work; multi-agent activation requires a
    material recorded signal and budget.
13. The first release uses at most one orchestrator and two workers, no
    parallel writers, and no recursive delegation.
14. Reviewer/tester evidence remains independent and cannot self-approve or
    replace writer self-review.
15. Overlapping, stale, expired, unowned, or recursively delegated work fails
    before mutation.
16. Delivery, merge, publication, and release effects require exact
    non-transitive grants and accepted predecessors.
17. Released catalogs and roles are protocol-owned and pinned; consumers do not
    shadow them.
18. Single-agent and multi-agent paths produce equivalent canonical gate
    evidence for the same admitted workflow outcome.

## Implementation and verification approach

After separate authorization, freeze the schema and expected-red matrix; build
the declarative catalog and resolver first; add read-only gate/directive
resolution; then compile exact handoffs and prove a single-agent read-only or
low-risk records pilot. Only that path's closure can admit the bounded
multi-agent topology. Provider/delivery integration and immutable consumer
distribution remain final dependency-held slices. Every slice uses one writer,
test-first evidence, focused verification, and fresh-diff review.

## Self-review

The 2026-08-12 packet and its current draft-PR linkage received a bounded
architecture/link/scope fresh-diff review after corrections: `0 Blocking / 0
Important / 0 Minor`, with no accepted residual, external/legacy follow-up, or
optional improvement. It is not Gate 5 implementation review and completes no
subfeature. No finding identity was required.

## Definition of Done

- [ ] Acceptance criteria and executable scenario mapping complete.
- [ ] Test commands, environments, and successful results recorded.
- [ ] Every slice review and required convergence scan complete.
- [ ] No unresolved `Blocking` finding.
- [ ] Protocol, runtime, schemas, distribution, docs, indexes, links, version,
  changelog, and project memory current.
- [ ] Issue and delivery pull request cross-link canonical records.
- [ ] Required CI, independent review, and security/authority gates pass.
- [ ] Residual risks are classified, owned, and linked.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180) |
| Release authority | Pending; no target version or publication authorized |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
