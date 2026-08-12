# FEAT-0057 - Explicit SDLC and GitHub-Native Backlog Governance

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed current-main re-intake; Definition of Ready incomplete; implementation not authorized |
| Target version | Unassigned; select only after refreshed Gate 1 review |
| Issue | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) |
| Parent epic | [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
| Pull request | Draft [PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) |
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
  publication, and the delivered subject's operation, maintenance,
  deprecation, and retirement to existing protocol authorities.
- Define non-linear follow-up through bugs, findings, recurrence, recovery,
  maintenance, and changed evidence, including when a new linked identity is
  required and when invalid completion evidence permits an explicit reopen.
- Define the exact meanings, entry/exit conditions, and transitions for
  proposed, planned, ready, active, review, blocked, completed, cancelled, and
  superseded work.
- Separate work identity from issue, pull request, label, command, workflow
  run, agent, and optional project projection; forbid automatic parent/child
  state propagation.
- Define candidate-inventory, committed-backlog, active-work, and lifecycle-
  catalog projections without making any projection a second authority.
- Define backlog membership, hierarchy, dependencies, priority, maintainer
  ordering, refinement, stale review, and closure.
- Keep the existing `Blocking` finding remediation queue as a specialized
  subset with its existing convergence contract.
- Align protocol text, templates, issue forms, labels, adoption guidance, and
  project-neutral structural evidence only in later authorized slices.
- Define separate new-consumer and existing-consumer transition routes that
  preserve consumer-owned records and configuration, and keep upstream
  release work separate from each consumer adoption, update, or recovery.

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
- Treating issue open/closed state, labels, or project metadata as lifecycle
  semantics or sufficient transition evidence.
- Reopening a completed work identity for an ordinary later bug, maintenance
  change, recovery, or enhancement.
- Rewriting completed historical records or overwriting consumer-owned issue
  forms, labels, records, or project-management configuration.
- Treating upstream completion or publication as consumer adoption, or a
  compatible pin update as authority to create consumer product-backlog state.
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
| `RISK-0322` <a name="risk-0322"></a> | Work identity, lifecycle, readiness, review, finding, merge, publication, operation, or parent/child projection is conflated, producing false transition, completion, or reopen. | Lifecycle owner / precise state meanings, separate axes and identities, explicit post-completion work boundary in proposed [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md), and [TEST-0224](test-cases.md#test-0224). |
| `RISK-0323` <a name="risk-0323"></a> | Labels or forms overwrite consumer-owned customization, or upstream release and ordinary pin updates falsely imply consumer adoption/backlog state. | Adoption owner / preserve [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md), require explicit transition under [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), and prove [TEST-0226](test-cases.md#test-0226). |
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
| `SUBF-0157` <a name="subf-0157"></a> | SDLC map, separate work/release/operational axes, completed-work follow-up boundary, deprecation, and retirement | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0224](test-cases.md#test-0224); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0158` <a name="subf-0158"></a> | Work identity and state meanings, blocking/resumption, candidate/catalog/backlog membership, dependency, and ordering semantics | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0225](test-cases.md#test-0225); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |
| `SUBF-0159` <a name="subf-0159"></a> | GitHub-native tracking and fail-closed projection, plus upstream/new/existing-consumer work boundaries | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0226](test-cases.md#test-0226); planned | Records-scope review `0 Blocking / 0 Important / 0 Minor`; not Gate 5 | Proposed |

## Decisions and relationships

- Proposed decision: [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md).
- Parent: [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179).
- Sibling: [FEAT-0070](../FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
  may consume this lifecycle projection only after the relevant proposal is
  accepted; it separately owns workflow and agent execution.
- Historical record: [closed draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151)
  is evidence only; its obsolete decision, risk, test, and subfeature identity
  allocations are not current authority.
- Related-work disposition: the
  [successor delivery plan](../../architecture/agentic-sdlc-workflows/delivery-plan.md#related-work-reconciliation)
  records that completed
  [BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149) /
  [FEAT-0058](../FEAT-0058-v0156-completed-historical-adoption-issues/README.md)
  and [FIND-0120 / issue #44](https://github.com/hasanmanzak/meAndAI/issues/44)
  remain historical evidence, while open
  [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139)
  remains a separate backlog item. This feature resumes none of those work
  scopes.

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, non-goals, and measurable acceptance criteria.
- [x] Preliminary domain axes, dependencies, risks, proposed decision, slices,
  and numbered scenario intent.
- [x] Test-code and baseline states recorded honestly.
- [x] Prior-art and recurrence evidence recorded.
- [ ] Complete then-current inventory of every lifecycle/status/label/form/
  template/index/automation and consumer projection.
- [ ] Maintainer acceptance of work-identity, state, backlog-membership,
  post-completion follow-up, operational-subject, projection-drift, ordering,
  and consumer-transition semantics.
- [ ] Target version and executable test owners selected.
- [ ] Exact expected-red design and validation budget accepted.
- [ ] Separate explicit implementation directive for one dependency-closed
  slice.

## Acceptance criteria

1. The SDLC maps discovery through retirement to existing authorities without
   restating their detailed rules.
2. `Proposed` is a refinement candidate, `Planned` is maintainer-selected but
   may be unready and unauthorized, `Ready` proves Definition of Ready without
   granting authority, and `InProgress` requires authority plus actual start.
3. Every remaining supported state has one meaning, entry, exit, and allowed
   transition set; blocking preserves blocker, owner, return state, and
   re-entry condition.
4. `Complete` evidences the work identity's Definition of Done but cannot imply
   merge, publication, operation, deprecation, or retirement.
5. A later bug, maintenance change, recovery, or enhancement normally creates
   a new linked work identity; completed work is reopened only when its own
   completion evidence is proven false or invalid and the rationale is recorded.
6. The delivered subject's operational state is named and evidenced separately
   from the work item, merge, and immutable publication.
7. Epic, feature, subfeature, task, bug, and owned-finding identities remain
   distinct from issues, pull requests, labels, commands, workflow runs,
   agents, and project metadata; parent/child state never propagates implicitly.
8. Candidate inventory, committed backlog, active work, and the lifecycle
   catalog are distinct; the catalog retains non-terminal and terminal records.
9. GitHub Issues is the live work-item tracker and state store; protocol and
   accepted decisions own lifecycle/workflow semantics, while repository
   records preserve durable specification and evidence.
10. Issue open/closed state, labels, and optional project metadata cannot alone
    advance lifecycle state; missing or ambiguous identity/link evidence and
    tracker/record drift fail closed.
11. No second canonical backlog is introduced; optional projections remain
    rebuildable.
12. Ideas remain outside actionable backlog membership until promotion;
    dependencies gate readiness and priority cannot bypass them.
13. The existing finding queue remains a specialized stricter subset, while
    refinement and stale review mandate no planning methodology.
14. Protocol text, templates, issue forms, labels, adoption guidance, and
    structural evidence use consistent semantics.
15. Upstream capability/release work and each consumer adoption, update, or
    recovery remain separate linked work identities and authorities; neither
    side's completion implies the other's state.
16. New and existing consumer routes are deterministic, preserve ownership,
    and change ordinary compatible pins without inventing consumer backlog
    work unless a reviewed release-declared migration requires it.

## Implementation and verification approach

After separate authorization, refresh the complete surface inventory; finalize
the decision; bind the three scenarios to existing executable owners; capture
expected-red evidence; deliver each subfeature tests-first and one at a time;
perform its focused verification and fresh-diff review; then run the existing
bounded structure/link and consumer-boundary checks. Publication remains a
separate immutable release operation.

## Self-review

The 2026-08-12 records-only packet, including the prior-delivery
reconciliation and explicit state/projection/consumer boundaries, received a
bounded architecture/link/scope fresh-diff review after its corrections:
`0 Blocking / 0 Important / 0 Minor`, with no accepted residual,
external/legacy follow-up, or optional improvement. One review observation
about tracker-versus-authority wording was corrected before closure. This is
not Gate 5 implementation review and completes no subfeature. No finding
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
