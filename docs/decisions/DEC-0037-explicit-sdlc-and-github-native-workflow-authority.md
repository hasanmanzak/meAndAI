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
3. The target work-item lifecycle is evaluated through `Proposed`, `Planned`,
   `Ready`, `InProgress`, `NeedsReview`, and `Complete`, with `Blocked` as a
   resumable interruption and `Cancelled` or `Superseded` as terminal outcomes.
   Exact names and transition schemas remain proposed until
   [FEAT-0057](../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
   closes design review.
4. `Ready` means Definition of Ready evidence is complete. It does not grant
   implementation, repository mutation, provider mutation, merge, or release
   authority.
5. GitHub Issues is the live work-item tracker and state store. Protocol and
   accepted decision records own lifecycle and workflow semantics;
   repository-native feature, test, risk, idea, architecture, and memory
   records preserve durable specification and evidence. No second canonical
   backlog document, database, or service is introduced.
6. Dependencies determine readiness. Priority expresses maintainer intent but
   cannot bypass dependencies or authorization. The existing `Blocking`
   finding queue remains a specialized subset with its stricter convergence
   rules.
7. Ideas remain outside the actionable backlog until promotion. Completion,
   merge, immutable publication, operation, deprecation, and retirement remain
   separately evidenced.
8. New-consumer installation and existing-consumer transition are separate.
   Consumer-owned issues, labels, forms, records, and project-management
   configuration are not silently overwritten.
9. Slash commands, natural-language requests, agents, CLIs, workflows, and
   services may request lifecycle operations only through the thin-host and
   authority boundaries in [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md)
   and proposed [DEC-0038](DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md).
10. This proposed decision authorizes records and review only. Protocol text,
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
