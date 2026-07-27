# FEAT-0057 - Explicit Development Lifecycle and GitHub-Native Backlog Governance

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed |
| Target version | 0.16.0 |
| Issue | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) |
| Pull request | Pending; [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) is the stable indirection until a records pull request exists |
| Decisions | [DEC-0032](../../decisions/DEC-0032-explicit-lifecycle-and-github-native-backlog.md) (Proposed) |
| Tests | [TEST-0191](test-cases.md#test-0191), [TEST-0192](test-cases.md#test-0192), and [TEST-0193](test-cases.md#test-0193) (Planned) |

This record is selected planning scope. It authorizes the linked records-only
proposal, not protocol implementation. Implementation requires a later explicit
maintainer directive after the remaining Definition of Ready items are complete.

## Problem

The protocol already defines delivery gates, stable work identifiers,
repository-native features and decisions, GitHub issue tracking, idea
incubation, and a dependency-first remediation queue. Those parts do not yet
form one explicit software-development lifecycle, shared work-item state model,
or complete product-backlog contract.

The current gaps create three related ambiguities:

1. The delivery lifecycle is strong but is not mapped into one SDLC from
   discovery through operation, deprecation, and retirement.
2. Feature records expose a status field and the feature index exposes a status
   column, but allowed non-terminal states, transitions, and catalog semantics
   are not defined.
3. GitHub Issues is the default tracker, but general backlog membership,
   authority, ordering, refinement, stale review, and consumer-adoption
   boundaries remain implicit. The specialized `Blocking` finding queue is
   defined more precisely than the general backlog and can be mistaken for it.

## Outcome

meAndAI and repositories adopting its pinned protocol share one compact,
project-neutral lifecycle and backlog model. Existing delivery gates remain the
detailed authority; the new model makes their SDLC position visible, gives work
items reproducible state semantics, and makes GitHub Issues the live backlog
and workflow authority while repository records remain the durable
specification and evidence authority.

The model represents work selected for delivery but not started, distinguishes
readiness from implementation authorization, keeps completion separate from
release publication, preserves the idea boundary, and supports consumer
adoption without a second manually synchronized backlog file.

## Scope

- Define the SDLC stages and map them to the existing idea, Gate 0 through Gate
  7, post-merge release, maintenance, deprecation, and retirement authorities.
- Define non-linear lifecycle re-entry through bugs, findings, recurrence,
  changed evidence, maintenance, and recovery.
- Define allowed work-item lifecycle states, entry and exit conditions,
  transitions, blocking and resumption, cancellation, and supersession.
- Define feature-index semantics for proposed, planned, active, terminal, and
  historical feature records.
- Define backlog membership, hierarchy, dependencies, priority, maintainer
  ordering, refinement, stale review, and closure.
- Preserve the dependency-first finding remediation queue as a specialized
  subset with its existing convergence contract.
- Align protocol text, templates, issue forms, labels, adoption guidance, and
  project-neutral structural evidence.
- Define separate safe routes for new consumers and existing consumers whose
  issue forms, labels, or records are consumer-owned.

## Non-goals

- Mandating Scrum, Kanban, sprints, iteration length, story points, velocity,
  deadlines, assignees, milestones, or GitHub Projects.
- Creating `BACKLOG.md`, a backlog service, or another canonical tracker that
  must be synchronized with GitHub Issues.
- Implementing an automatic scheduler, agent work selector, automatic
  implementation authorization, or autonomous roadmap decision maker.
- Replacing the existing finding disposition or remediation ordering contract.
- Turning [idea records](../FEAT-0008-idea-incubation/README.md) into delivery
  commitments before promotion.
- Rewriting completed historical feature records in bulk.
- Combining work-item state, finding disposition, review state, and release
  evidence into one overloaded label.
- Overwriting customized consumer-owned issue forms, labels, feature records,
  or project-management configuration.
- Implementing protocol, test, automation, migration, or consumer changes in
  this records-only proposal.

## Readiness evidence

- Domain and contracts: the feature owns lifecycle and backlog governance, not
  product-domain scheduling. Work identity, lifecycle state, readiness,
  implementation authorization, review state, finding disposition, and release
  evidence are distinct semantic axes.
- Prior art: [FEAT-0001](../FEAT-0001-common-development-protocol/README.md)
  owns the portable delivery and tracking baseline;
  [FEAT-0015](../FEAT-0015-stability-consistency-mandate/README.md) owns the
  event-triggered stability cycle and specialized remediation queue;
  [FEAT-0008](../FEAT-0008-idea-incubation/README.md) and
  [DEC-0009](../../decisions/DEC-0009-repository-native-idea-incubation.md) own
  the pre-work idea boundary; [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md)
  owns pinned consumer integration; and
  [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
  owns deterministic existing-consumer transitions.
- Same-contract sibling inventory: the current Gate 0 through Gate 7 lifecycle,
  full-project scan queue, GitHub tracking section, feature and decision
  templates, issue forms, label bootstrap surfaces, feature index, and adoption
  guide are known owners. The implementation task must refresh their exact
  complete call-site and projection inventory before mutation.
- Recurrence: the lifecycle/backlog feature contract itself has no matching
  active entry (`None`); the planned project-neutral structural scenarios are
  its recurrence barriers. The records packet separately matches the active
  [untracked governance packet route](../../../.ai/memory/project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph):
  the staged structural pass is not exact committed-tree graph evidence. Commit
  the complete packet, then require focused exact-commit graph evidence on both
  supported PowerShell runtimes before treating the records proposal as
  publication-ready.
- Compatibility: a new mandatory governance contract is prospective for
  consumers that adopt `0.16.0`. Existing pins remain valid. Existing
  consumer-owned projections require either reviewed deterministic transition
  authority or explicit opt-in; current planning does not choose one silently.
- Verification: use the existing protocol-governance owner where its contract
  fits, extend current real consumer fixtures only when an adoption boundary
  requires it, and do not introduce another validator framework.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0274` <a name="risk-0274"></a> | Lifecycle state, readiness, review, finding disposition, and publication evidence are conflated, producing false transitions or completion claims. | [DEC-0032](../../decisions/DEC-0032-explicit-lifecycle-and-github-native-backlog.md) must define separate axes; [TEST-0191](test-cases.md#test-0191) proves the boundaries. |
| `RISK-0275` <a name="risk-0275"></a> | New labels or forms overwrite consumer-owned customization or imply that ordinary protocol pin updates manage consumer backlog content. | Preserve [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md) ownership and choose any required existing-consumer transition under [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md); [TEST-0193](test-cases.md#test-0193). |
| `RISK-0276` <a name="risk-0276"></a> | A universal ordering algorithm displaces maintainer product judgment or lets priority bypass dependencies. | Keep dependency readiness and maintainer-owned ordering explicit; retain deterministic ordering only where a bounded specialized queue requires it; [TEST-0192](test-cases.md#test-0192). |
| `RISK-0277` <a name="risk-0277"></a> | The protocol grows into a project-management framework rather than a compact quality-control surface. | Require every field or automation to enforce a demonstrated recurring rule; keep optional projections optional and reject a second canonical backlog; [DEC-0032](../../decisions/DEC-0032-explicit-lifecycle-and-github-native-backlog.md). |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0191](test-cases.md#test-0191), [TEST-0192](test-cases.md#test-0192), and [TEST-0193](test-cases.md#test-0193) |
| Test code | Planned / not started | `PlannedDocumentation` authority in [scenario ownership](../../../tests/scenario-ownership.psd1); implementation owner selection remains part of the refreshed inventory |
| Baseline run | Not run in records-only scope | Future authorized implementation must capture the exact pre-change baseline and expected-red evidence before production changes |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0115` <a name="subf-0115"></a> | SDLC model, Gate mapping, non-linear re-entry, operation, deprecation, and retirement boundaries | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0191](test-cases.md#test-0191); planned / not started | Fresh-diff review pending; findings allocated only when observed | Proposed |
| `SUBF-0116` <a name="subf-0116"></a> | Work-item states, transitions, blocking/resumption, readiness/authorization, completion/publication, and feature-catalog semantics | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0191](test-cases.md#test-0191) and [TEST-0192](test-cases.md#test-0192); planned / not started | Fresh-diff review pending; findings allocated only when observed | Proposed |
| `SUBF-0117` <a name="subf-0117"></a> | GitHub-native backlog authority, refinement, ordering, labels/forms/templates, and new/existing consumer adoption | [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | [TEST-0192](test-cases.md#test-0192) and [TEST-0193](test-cases.md#test-0193); planned / not started | Fresh-diff review pending; findings allocated only when observed | Proposed |

## Decisions and relationships

- Proposed decision: [DEC-0032](../../decisions/DEC-0032-explicit-lifecycle-and-github-native-backlog.md)
- Tracking and stable planning authority: [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150)
- Parent epic: N/A; the three slices form one shared, independently valuable
  protocol capability rather than separately released features.
- Dependencies: existing authorities listed under readiness evidence; no
  implementation dependency has yet been accepted.
- Related open delivery work: [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139)
  and [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149)
  remain separately owned and do not authorize, block, or become part of this
  planning scope. Release order must be refreshed before implementation.

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [ ] Complete current-main inventory of every status, label, form, template,
  index, automation, and consumer projection boundary.
- [x] Preliminary numbered risks and proposed process decision.
- [x] Three reviewable slices with a gate ledger.
- [x] Numbered scenario intent and planned verification approach.
- [x] Test-code and baseline-run states recorded honestly.
- [x] Prior-art ownership, feature-contract recurrence `None`, and the active
  governance-packet exact-commit route recorded.
- [ ] Maintainer review of the proposed state model, backlog ordering contract,
  and new-versus-existing consumer transition choice.
- [ ] Separate explicit implementation authorization.

## Acceptance criteria

1. The SDLC is defined from discovery through retirement and maps to existing
   gates without duplicating their detailed rules.
2. The lifecycle is explicitly non-linear and identifies re-entry through
   bugs, findings, maintenance, recurrence, recovery, and changed evidence.
3. Every supported work-item state has one meaning, entry condition, exit
   condition, and allowed transition set.
4. The model represents selected but not started work and Ready work whose
   implementation has not been authorized.
5. A blocked item records its blocker, owner, preserved return state, and
   re-entry condition rather than erasing lifecycle history.
6. Feature completion, pull-request merge, release publication, operational
   maintenance, deprecation, and retirement remain distinct evidence points.
7. The feature index is explicitly a lifecycle catalog and includes
   non-terminal features alongside completed history.
8. GitHub Issues is the canonical live backlog/workflow authority, while
   repository records are the durable specification, decision, test, risk, and
   evidence authority.
9. No second manually synchronized canonical backlog is introduced; GitHub
   Projects, milestones, and other projections remain optional.
10. Backlog membership covers actionable epics, features, subfeatures, tasks,
    bugs, and separately owned findings while preserving the idea boundary.
11. Dependencies determine readiness; priority does not override dependency
    order; maintainer-owned ordering and any bounded fallback are explicit.
12. The existing `Blocking` finding queue remains a specialized backlog subset
    with its existing stricter convergence rules.
13. Refinement and stale-review triggers are defined without imposing one
    iteration methodology or estimation system.
14. Protocol text, templates, issue forms, labels, adoption guidance, and
    structural evidence use one lifecycle vocabulary.
15. New-consumer installation and existing-consumer transition paths are
    distinct, deterministic, and preserve consumer ownership.
16. Project-neutral structural evidence proves lifecycle mapping, transitions,
    catalog semantics, backlog authority, tracking-surface consistency, and
    consumer boundaries.

## Implementation and verification approach

After separate authorization:

1. Refresh and classify every current lifecycle/status/backlog surface and
   confirm the proposed decision against actual repository and consumer state.
2. Convert the three planned scenarios to their narrowest existing executable
   owners and demonstrate intended expected-red evidence.
3. Implement [SUBF-0115](#subf-0115), run focused evidence, and perform its
   fresh-diff review before the next independent slice.
4. Repeat that gate for [SUBF-0116](#subf-0116) and [SUBF-0117](#subf-0117).
5. Run the existing structure/link checks, any required real consumer fixture,
   supported-runtime evidence, and one bounded final convergence scan.
6. Publish only through the normal reviewed branch, immutable release, and
   post-publication evidence lifecycle.

## Planning review state

The records-only diff must be checked for stable-ID uniqueness, exact links,
honest planned test authority, scope consistency, and the implementation
authorization boundary. This is not the Gate 5 implementation self-review and
does not complete any subfeature.

No `FIND-NNNN` identity is preallocated. Review observations receive identities
only when they exist.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory executable test code and scenario mapping complete.
- [ ] Test commands, environments, and results recorded.
- [ ] Every subfeature review and required convergence scan complete.
- [ ] No unresolved `Blocking` finding.
- [ ] Protocol, templates, adoption guidance, indexes, links, version,
  changelog, and project memory current.
- [ ] Issue and delivery pull request cross-link the canonical records.
- [ ] Required CI and review gates pass.
- [ ] Residual risks are classified, owned, and linked.

## Release gate

Feature completion is a pre-merge gate. Immutable `v0.16.0` publication is a
separate post-merge gate. Exact release identity, target commit, immutable
state, checks, and post-publication verification remain `Pending` and must be
written to [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) only
after those external facts exist.
