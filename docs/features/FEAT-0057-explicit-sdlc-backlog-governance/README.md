# FEAT-0057 - Explicit SDLC and GitHub-Native Backlog Governance

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed current-main re-intake; Definition of Ready incomplete; implementation not authorized |
| Target version | Unassigned; select only after refreshed Gate 1 review |
| Issue | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) |
| Parent epic | [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
| Pull request | Pending; [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) is the stable authority until a records pull request exists |
| Decisions | Proposed [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md) |
| Architecture | [Agentic SDLC Workflow Architecture](../../architecture/agentic-sdlc-workflows/README.md) |
| Tests | [TEST-0224](test-cases.md#test-0224), [TEST-0225](test-cases.md#test-0225), and [TEST-0226](test-cases.md#test-0226) |

This record refreshes the distinct lifecycle/backlog scope retained by
[issue #150](https://github.com/hasanmanzak/meAndAI/issues/150). The obsolete
records on [closed draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151)
are prior art only and must not be merged or blindly rebased. This current-main
record preserves the feature identity while allocating unused decision,
subfeature, risk, and test identities.

## Problem

The protocol defines delivery gates, stable work identifiers, repository-native
records, GitHub issue tracking, idea incubation, and a dependency-first
remediation queue. Those parts do not yet form one explicit lifecycle from
discovery through operation and retirement, one shared work-item state model,
or one complete backlog contract.

This allows lifecycle, readiness, authorization, review, finding disposition,
completion, merge, publication, and retirement to be conflated. GitHub Issues
is the default tracker, but general backlog membership, blocking/resumption,
ordering, refinement, stale review, and consumer ownership remain implicit.

## Outcome

meAndAI and pinned consumers share one compact, project-neutral SDLC and
backlog model. Existing Gate 0 through Gate 7 rules remain detailed authority;
the feature makes their lifecycle positions and allowed evidence transitions
explicit. GitHub Issues remains the live work-item tracker and state store;
protocol and accepted decisions own lifecycle/workflow semantics, while
repository records preserve durable specification and evidence.

The model represents selected but not started work, separates Definition of
Ready from implementation authority, keeps completion separate from immutable
publication, preserves idea incubation, and supports consumers without a
second manually synchronized backlog.

## Scope

- Map discovery, planning, design, implementation, verification, delivery,
  publication, operation, maintenance, deprecation, and retirement to existing
  protocol authorities.
- Define non-linear re-entry through bugs, findings, recurrence, recovery,
  maintenance, and changed evidence.
- Define work-item states, entry/exit conditions, transitions, blocking,
  preserved return state, resumption, cancellation, and supersession.
- Define feature-index and backlog projections for proposed, planned, ready,
  active, review, blocked, and terminal records.
- Define backlog membership, hierarchy, dependencies, priority, maintainer
  ordering, refinement, stale review, and closure.
- Keep the existing `Blocking` finding remediation queue as a specialized
  subset with its existing convergence contract.
- Align protocol text, templates, issue forms, labels, adoption guidance, and
  project-neutral structural evidence only in later authorized slices.
- Define separate new-consumer and existing-consumer transition routes that
  preserve consumer-owned records and configuration.

## Non-goals

- Mandating Scrum, Kanban, sprints, story points, velocity, deadlines,
  assignees, milestones, or GitHub Projects.
- Creating a canonical backlog file, database, or service alongside GitHub
  Issues.
- Implementing an automatic scheduler, agent work selector, automatic
  authorization, or autonomous roadmap decision maker.
- Replacing the finding disposition or remediation ordering contract.
- Turning [idea incubation](../FEAT-0008-idea-incubation/README.md) into a
  delivery commitment before promotion.
- Combining lifecycle, review, finding, merge, publication, and operational
  state into one label.
- Rewriting completed historical records or overwriting consumer-owned issue
  forms, labels, records, or project-management configuration.
- Implementing protocol, test, workflow, label, migration, release, or
  consumer changes in this records-only proposal.

## Readiness evidence

- Domain and contracts: work identity, lifecycle state, readiness,
  implementation authority, workflow-run state, review state, finding
  disposition, merge, publication, and operational state are distinct axes.
- Prior art: [FEAT-0001](../FEAT-0001-common-development-protocol/README.md)
  owns the portable protocol/tracking baseline;
  [FEAT-0015](../FEAT-0015-stability-consistency-mandate/README.md) owns the
  stability cycle and specialized remediation queue;
  [FEAT-0008](../FEAT-0008-idea-incubation/README.md) and
  [DEC-0009](../../decisions/DEC-0009-repository-native-idea-incubation.md)
  own the idea boundary; [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md)
  owns pinned consumer integration; and
  [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
  owns deterministic existing-consumer transitions.
- Same-contract siblings: Gate 0 through Gate 7, full-project scans, GitHub
  tracking, feature/decision templates, issue forms, label bootstrap, feature
  index, and adoption guidance. The implementation intake must refresh this
  inventory from then-current `main` before mutation.
- Feature-contract recurrence: no matching active recurrence entry (`None`).
  The records packet separately matches the active
  [untracked governance packet route](../../../.ai/memory/project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph)
  and [canonical-link route](../../../.ai/memory/project.md#record-synchronization-reintroduces-noncanonical-cross-record-links).
  Dirty-worktree checks do not prove the committed instruction graph; the
  complete packet must be committed before exact-head evidence.
- Consumers and compatibility: existing pins remain valid. Any mandatory new
  projection requires a reviewed immutable transition; this proposal chooses
  no consumer mutation.
- Verification: extend existing canonical structural owners only when their
  contracts fit. Do not introduce a second validator or backlog engine.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0322` <a name="risk-0322"></a> | Lifecycle, readiness, review, finding, merge, publication, and operation are conflated, producing false completion. | Lifecycle owner / separate axes in proposed [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md) and [TEST-0224](test-cases.md#test-0224). |
| `RISK-0323` <a name="risk-0323"></a> | Labels or forms overwrite consumer-owned customization or imply ordinary pin updates own product backlog state. | Adoption owner / preserve [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md), require explicit transition under [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), and prove [TEST-0226](test-cases.md#test-0226). |
| `RISK-0324` <a name="risk-0324"></a> | A universal ordering algorithm displaces maintainer judgment or lets priority bypass dependencies. | Backlog owner / dependency-gated readiness, maintainer ordering, and [TEST-0225](test-cases.md#test-0225). |
| `RISK-0325` <a name="risk-0325"></a> | The protocol becomes a project-management framework rather than a compact quality-control surface. | Maintainers / require demonstrated recurring value, retain optional projections, reject a second canonical backlog, and prove the boundary in [TEST-0225](test-cases.md#test-0225). |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0224](test-cases.md#test-0224), [TEST-0225](test-cases.md#test-0225), and [TEST-0226](test-cases.md#test-0226) |
| Test code | Planned / not started | Executable owners must be selected from the refreshed current-main inventory |
| Baseline run | Not run | Records-only scope; future implementation must capture exact baseline and expected-red evidence |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0157` <a name="subf-0157"></a> | SDLC map, separate state axes, non-linear re-entry, operation, deprecation, and retirement | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0224](test-cases.md#test-0224); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0158` <a name="subf-0158"></a> | Work-item transitions, blocking/resumption, catalog, backlog membership, dependency, and ordering semantics | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0225](test-cases.md#test-0225); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0159` <a name="subf-0159"></a> | GitHub-native tracking state, optional projections, and new/existing consumer transitions | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0226](test-cases.md#test-0226); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |

## Decisions and relationships

- Proposed decision: [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md).
- Parent: [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179).
- Sibling: [FEAT-0070](../FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
  may consume this lifecycle projection only after the relevant proposal is
  accepted; it separately owns workflow and agent execution.
- Historical record: [closed draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151)
  is evidence only; its obsolete decision, risk, test, and subfeature identity
  allocations are not current authority.

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, non-goals, and measurable acceptance criteria.
- [x] Preliminary domain axes, dependencies, risks, proposed decision, slices,
  and numbered scenario intent.
- [x] Test-code and baseline states recorded honestly.
- [x] Prior-art and recurrence evidence recorded.
- [ ] Complete then-current inventory of every lifecycle/status/label/form/
  template/index/automation and consumer projection.
- [ ] Maintainer acceptance of the state vocabulary, allowed transitions,
  backlog ordering, and consumer transition choice.
- [ ] Target version and executable test owners selected.
- [ ] Exact expected-red design and validation budget accepted.
- [ ] Separate explicit implementation directive for one dependency-closed
  slice.

## Acceptance criteria

1. The SDLC maps discovery through retirement to existing authorities without
   restating their detailed rules.
2. Non-linear re-entry through bugs, findings, maintenance, recurrence,
   recovery, and changed evidence is explicit.
3. Each supported state has one meaning, entry, exit, and allowed transition
   set.
4. Selected-but-not-started and Ready-but-not-authorized work are representable.
5. Blocking preserves blocker, owner, return state, and re-entry condition.
6. Completion, merge, publication, maintenance, deprecation, and retirement
   remain separately evidenced.
7. The feature index is a lifecycle catalog containing non-terminal and
   completed records.
8. GitHub Issues is the live work-item tracker and state store; protocol and
   accepted decisions own lifecycle/workflow semantics, while repository
   records preserve durable specification and evidence.
9. No second canonical backlog is introduced; optional projections remain
   rebuildable.
10. Actionable epics, features, subfeatures, tasks, bugs, and owned findings
    can belong to the backlog while ideas remain outside until promotion.
11. Dependencies gate readiness and priority cannot bypass them.
12. The existing finding queue remains a specialized stricter subset.
13. Refinement and stale review do not mandate one planning methodology.
14. Protocol text, templates, issue forms, labels, adoption guidance, and
    structural evidence use consistent semantics.
15. New and existing consumer routes are deterministic and preserve ownership.

## Implementation and verification approach

After separate authorization, refresh the complete surface inventory; finalize
the decision; bind the three scenarios to existing executable owners; capture
expected-red evidence; deliver each subfeature tests-first and one at a time;
perform its focused verification and fresh-diff review; then run the existing
bounded structure/link and consumer-boundary checks. Publication remains a
separate immutable release operation.

## Self-review

The 2026-08-12 records-only packet received one bounded architecture/link/scope
fresh-diff review after its corrections: `0 Blocking / 0 Important / 0 Minor`,
with no accepted residual, external/legacy follow-up, or optional improvement.
It is not Gate 5 implementation review and completes no subfeature. No finding
identity was required.

## Definition of Done

- [ ] Acceptance criteria and executable scenarios complete.
- [ ] Test commands, environments, and successful results recorded.
- [ ] Every slice review and required convergence scan complete.
- [ ] No unresolved `Blocking` finding.
- [ ] Protocol, templates, guidance, indexes, links, version, changelog, and
  project memory current.
- [ ] Issue and delivery pull request cross-link canonical records.
- [ ] Required CI and review gates pass.
- [ ] Residual risks are classified, owned, and linked.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) |
| Release authority | Pending; no target version or publication authorized |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
