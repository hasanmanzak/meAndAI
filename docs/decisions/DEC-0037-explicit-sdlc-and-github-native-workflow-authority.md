# DEC-0037 - Use an Explicit SDLC with GitHub-Native Tracking Authority

- Classification: Decision
- Status: Proposed; implementation authority withheld
- Date: 2026-08-12
- Decision owners: meAndAI maintainers
- Related features: [FEAT-0057](../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md) and [FEAT-0070](../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
- Related decisions: [DEC-0009](DEC-0009-repository-native-idea-incubation.md), [DEC-0015](DEC-0015-event-triggered-stability-cycles.md), [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md), and proposed [DEC-0038](DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md)
- Tracking: [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150)

## Context

The protocol already defines [Gate 0 through Gate 7](../../PROTOCOL.md#4-delivery-lifecycle-and-review-gates), idea incubation, stable work records, GitHub tracking, a dependency-first remediation queue, and a separate post-merge release gate. These authorities do not yet expose one compact lifecycle vocabulary from discovery through operation and retirement.

The absence of that projection creates ambiguity between lifecycle state,
Definition of Ready, implementation authority, review state, finding
disposition, merge, publication, and operational state. GitHub Issues is the
default live tracker, but backlog membership, refinement, ordering, blocking,
resumption, and stale-review semantics are not one explicit contract.

An earlier records proposal on [closed draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151) preserved the problem but was intentionally not merged. Its decision and test identifiers later collided with accepted work. [Issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) remained open for a fresh intake from current `main`; this decision is that current-main re-intake and does not treat the obsolete branch as merge authority.

## Decision

1. The existing protocol gates remain the canonical detailed delivery
   lifecycle. The explicit SDLC is a projection over those authorities, not a
   second gate system.
2. Work lifecycle, readiness, implementation authority, workflow-run state,
   review state, finding disposition, merge state, release evidence, and
   operational state are separate axes. A value on one axis never implies a
   transition on another.
3. An actionable work identity is an epic, feature, subfeature, task, bug, or
   owned finding. An issue, pull request, label, command, workflow run, agent,
   or project-board card is a tracker, projection, request, actor, or evidence
   carrier; it is not the work identity itself. Parent and child state never
   propagates automatically, and dependency or closure propagation requires an
   explicit contract.
4. Backlog membership is explicit rather than inferred from an open issue or a
   label. `Proposed` work is a stable candidate under refinement and may appear
   in a candidate inventory; `Planned` means the maintainer selected the work
   into the committed backlog even though Definition of Ready and authority
   may still be incomplete. `Ready` means Definition of Ready evidence is
   complete but grants no implementation, repository mutation, provider
   mutation, merge, or release authority.
5. The remaining target work-item meanings are: `InProgress` requires both an
   explicit implementation directive and actual start; `NeedsReview` means the
   bounded result and evidence await the required review; and `Complete` means
   the work identity's declared Definition of Done is evidenced. Exact names
   and transition schemas remain proposed until
   [FEAT-0057](../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
   closes design review.
6. `Blocked` is a resumable interruption that preserves the prior state,
   blocker, owner, and re-entry condition. `Cancelled` and `Superseded` are
   terminal. `Complete` is terminal for the identity's declared scope unless
   its completion evidence is proven false or invalid and an explicit reopen
   rationale is recorded. A later bug, maintenance change, recovery, or
   enhancement normally receives a new linked work identity rather than
   reopening the completed one.
7. Work-item completion, merge, immutable publication, and the delivered
   subject's operational lifecycle are separate. The operational subject, not
   its delivery work item, moves through proposed `NotOperational`,
   `Operational`, `Deprecated`, and `Retired` meanings with named subject or
   version, effective-date, support, migration, and successor evidence where
   applicable. Maintenance creates linked work and does not automatically
   change the completed delivery identity.
8. GitHub Issues is the live work-item tracker and state store. Protocol and
   accepted decision records own lifecycle and workflow semantics;
   repository-native feature, test, risk, idea, architecture, and memory
   records preserve durable specification and evidence. Issue open/closed
   state, labels, and optional project metadata are projections and cannot
   alone advance a lifecycle state. Missing or ambiguous stable identity,
   missing canonical links, or tracker/record drift fails closed without a
   transition. No second canonical backlog document, database, or service is
   introduced.
9. Dependencies determine readiness. Priority expresses maintainer intent but
   cannot bypass dependencies or authorization. The existing `Blocking`
   finding queue remains a specialized subset with its stricter convergence
   rules.
10. Ideas remain outside the actionable backlog until promotion. Completed,
    cancelled, and superseded work remains in the lifecycle catalog but not the
    active backlog.
11. New-consumer installation and existing-consumer transition are separate.
    Upstream capability/release work and each consumer adoption, update, or
    recovery are separately linked work identities under their own repository
    authority. Upstream completion or publication does not imply consumer
    adoption; consumer completion does not mutate upstream state. An ordinary
    compatible pin update creates no consumer product-backlog state unless a
    reviewed release-declared migration explicitly requires linked consumer
    work. Consumer-owned issues, labels, forms, records, and project-management
    configuration are not silently overwritten.
12. Slash commands, natural-language requests, agents, CLIs, workflows, and
   services may request lifecycle operations only through the thin-host and
   authority boundaries in [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md)
   and proposed [DEC-0038](DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md).
13. This proposed decision authorizes records and review only. Protocol text,
    executable tests, automation, labels, forms, consumers, releases, and
    runtime behavior require later bounded directives.

## Consequences

- The protocol gains one visible SDLC without duplicating Gate 0 through Gate
  7 or making a command the lifecycle owner.
- A workflow can complete while its requested gate transition remains denied
  because required evidence or authority is absent.
- Backlog projections can be rebuilt from GitHub and repository records rather
  than manually synchronized.
- Existing records need not be rewritten in bulk; prospective records and
  transition logic can adopt the vocabulary incrementally.
- Explicit state axes add modeling work and require structural scenarios to
  prevent false equivalence.
- Any future automation must fail closed on ambiguous state, stale evidence,
  missing authority, or consumer ownership conflicts.

## Alternatives considered

- Keep the lifecycle implicit: rejected because current terminology permits
  readiness, authorization, completion, and publication to be conflated.
- Make slash commands the lifecycle: rejected because aliases are transport
  conveniences and cannot be stable semantic authorities.
- Add a canonical backlog document or external service: rejected because it
  creates synchronization drift with GitHub Issues.
- Make the finding-remediation queue the whole backlog: rejected because its
  convergence ordering is intentionally narrower than product planning.
- Adopt the closed draft branch: rejected because its identifiers collided and
  its old base is not current authority.

## Review condition

Review before accepting [FEAT-0057](../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md), whenever the protocol gate model or GitHub tracking-state boundary changes, or when a real consumer transition demonstrates that the proposed state axes or ownership boundary is insufficient.
