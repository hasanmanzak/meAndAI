# DEC-0009 - Keep Pre-Work Ideas as Repository-Native Records

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0008](../features/FEAT-0008-idea-incubation/README.md)
- Related decisions: [DEC-0001](DEC-0001-portable-protocol-reference.md), [DEC-0002](DEC-0002-project-local-memory.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md)

## Context

Some possibilities are worth preserving before maintainers decide to plan or
deliver them. The existing classifications begin at committed work, audit
evidence, tests, risks, and decisions. Using a feature ID too early implies
scope and delivery intent, while chat-only notes are not portable or reviewable.
GitHub Discussions could hold open-ended ideas but would make the canonical
record depend on a repository feature and network surface outside the pinned
protocol documentation.

## Decision

Use `IDEA-NNNN` records under a repository-owned `docs/ideas` index for durable
pre-work discovery. An idea is explicitly not a work item, decision, backlog
commitment, or implementation authorization. It does not require an issue,
owner, tests, target version, Definition of Ready, or delivery date.

An idea uses one of four statuses: `Exploring`, `Parked`, `Promoted`, or
`Rejected`. It records the observation, possibility, potential value, concerns,
promotion condition, and outcome. Promotion creates the appropriate linked
`EPIC`, `FEAT`, `TASK`, or `DEC` record. The promoted work must independently
satisfy the normal gates. Promoted and rejected idea records remain in history
with rationale and links.

The canonical template lives in the pinned protocol. New collision-free
submodule adoption may copy an absent consumer-owned `docs/ideas/README.md`.
Existing content is a collision and is never overwritten. Compatible protocol
updates do not manage consumer idea records; existing consumers opt in by
creating the index from the pinned source when they need it.

## Consequences

- Valuable possibilities survive across machines and AI sessions without
  becoming false delivery commitments.
- Idea history is reviewable, linkable, and available offline with the repo.
- Consumers can use the same lifecycle without enabling GitHub Discussions.
- Repository documentation gains a small amount of index and record overhead.
- Maintainers must avoid recording low-value passing thoughts merely because a
  template exists.
- Promotion is explicit and traceable but does not bypass Definition of Ready.

## Alternatives considered

- GitHub Discussions `Ideas`: useful for community conversation, but rejected
  as the canonical protocol record because it is external to the immutable
  repository pin and unavailable offline.
- Backlog issues: rejected for raw ideas because an issue implies actionable
  tracked work and mixes uncommitted exploration with delivery queues.
- `POSSIBILITY-NNNN` or `POSS-NNNN`: rejected because possibility describes a
  maturity state poorly and is less direct than `IDEA`.
- Store ideas only in project memory: rejected because memory is a curated AI
  handoff, not the canonical design-history graph.

## Review condition

Review if idea volume creates material documentation noise, consumers require
collaborative discussion features, or promotion repeatedly loses traceability.
