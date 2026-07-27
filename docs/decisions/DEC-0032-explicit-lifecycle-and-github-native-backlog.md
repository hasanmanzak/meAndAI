# DEC-0032 - Use One Explicit Lifecycle with GitHub-Native Backlog Authority

- Classification: Decision
- Status: Proposed
- Date: 2026-07-27
- Decision owners: meAndAI maintainers and adopting-project maintainers
- Related feature: [FEAT-0057](../features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md)
- Tracking: [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150)
- Related decisions: [DEC-0001](DEC-0001-portable-protocol-reference.md), [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0009](DEC-0009-repository-native-idea-incubation.md), [DEC-0015](DEC-0015-event-triggered-stability-cycles.md), and [DEC-0018](DEC-0018-release-declared-consumer-migrations.md)

## Context

The common protocol already defines the delivery gates, GitHub tracking,
repository-native records, idea incubation, and a deterministic remediation
queue. It does not define their combined SDLC position, one general work-item
state model, or complete backlog authority and projection rules.

Using the feature index as completed history only makes planned and active work
invisible. Treating every open issue as an undifferentiated backlog loses the
idea boundary, durable specification, dependencies, and lifecycle evidence.
Adding a manually maintained backlog file would duplicate GitHub state and
create drift. Reusing the specialized `Blocking` finding queue as the product
backlog would let a correction-order contract displace maintainer product
judgment.

The protocol also serves consumers. Any new tracking vocabulary must distinguish
the canonical common contract from consumer-owned issues, records, labels,
forms, project views, and local customizations.

## Decision

Adopt one explicit, non-linear development lifecycle as the upper-level map of
the existing protocol. The map references rather than duplicates the detailed
Gate 0 through Gate 7 and post-merge release rules. It additionally names the
discovery, operation and maintenance, deprecation, and retirement boundaries,
including re-entry through bugs, findings, recurrence, recovery, and changed
evidence.

Use one normative work-item lifecycle vocabulary. The feature must review and
finalize states equivalent to:

`Proposed -> Planned -> Ready -> In Progress -> Needs Review -> Complete`

with `Blocked` as a resumable interruption and `Cancelled` or `Superseded` as
terminal outcomes. Each state has explicit entry, exit, and allowed-transition
conditions. `Ready` means Definition of Ready is satisfied; it does not itself
grant implementation authority. `Complete` means the applicable Definition of
Done is satisfied; merge, immutable release publication, operation, deprecation,
and retirement retain their separate evidence.

Use GitHub Issues as the live backlog and workflow authority. Use
repository-native features, decisions, tests, risks, findings, and related
records as durable versioned specification and evidence. The feature index is a
lifecycle catalog containing non-terminal work and completed history, not only
a release archive. Do not create a second manually synchronized canonical
backlog file.

Keep the following projections distinct:

- candidate inventory: proposed actionable work;
- committed backlog: planned or ready work, including blocked work whose return
  state and re-entry condition are preserved;
- active delivery: in-progress or review work;
- history: complete, cancelled, or superseded work; and
- pre-work ideas: outside the backlog until promoted under
  [DEC-0009](DEC-0009-repository-native-idea-incubation.md).

Dependencies determine whether an item is ready to be selected. Priority
describes relative importance but does not silently override dependencies or
choose product strategy. Maintainers retain explicit product ordering; any
deterministic fallback must be bounded and recorded. The existing
dependency-first `Blocking` finding queue remains a specialized remediation
subset governed by [DEC-0004](DEC-0004-bounded-completion-convergence.md) and
[DEC-0015](DEC-0015-event-triggered-stability-cycles.md).

GitHub Projects, milestones, iterations, and dashboards may project the same
canonical issue state but are optional. The protocol does not mandate one
planning methodology, estimation system, cadence, or provider UI.

New consumers may receive release-declared canonical tracking assets through
the reviewed adoption path. Existing consumer-owned forms, labels, records, and
project settings are not silently overwritten. A required deterministic change
must use an authority consistent with [DEC-0018](DEC-0018-release-declared-consumer-migrations.md);
otherwise adoption is explicit opt-in or remains manual.

This decision remains `Proposed` until the feature completes the current-surface
inventory and the maintainer reviews the exact state transitions, backlog order,
and existing-consumer transition choice. It does not authorize implementation.

## Consequences

- The protocol can answer what its SDLC and backlog are without creating a
  parallel delivery process.
- Planned, ready, active, and historical feature records become visible under
  one catalog contract.
- GitHub retains useful live workflow state while repository records retain
  reviewable versioned meaning and evidence.
- Ideas, product backlog, active delivery, remediation queue, review state, and
  publication evidence no longer rely on overloaded terminology.
- Consumers can adopt the same semantics while retaining ownership of their
  project records and provider configuration.
- Forms, labels, templates, protocol text, adoption guidance, and structural
  evidence must be reconciled to one vocabulary during implementation.
- The model adds some governance text and review obligations, so minimalism and
  optional-projection boundaries require explicit verification.

## Alternatives considered

- Keep the current implicit model: rejected because it cannot represent or
  query selected-not-started work consistently and leaves consumer backlog
  behavior ambiguous.
- Add `BACKLOG.md` as the canonical queue: rejected because GitHub Issues is
  already the live tracker and a second mutable list would drift.
- Treat the feature index as completed history only: rejected because the index
  has a status column and the protocol requires durable feature records before
  implementation.
- Use only GitHub issue bodies and remove repository feature records: rejected
  because issue forms are not authoritative DoR/DoD evidence and immutable pins
  need repository-native specifications.
- Use the finding remediation queue for all work: rejected because its
  dependency-first corrective ordering does not own product prioritization.
- Mandate GitHub Projects, sprints, or Kanban: rejected because provider UI and
  project methodology are project choices, not portable protocol invariants.
- Automatically select the next item and start an agent: rejected because
  backlog order does not grant implementation authority.
- Split SDLC, state vocabulary, and backlog into separate decisions: rejected
  for this scope because each term defines the others and separate acceptance
  could create an internally inconsistent intermediate contract.

## Review condition

Review before acceptance after [FEAT-0057](../features/FEAT-0057-v0160-lifecycle-backlog-governance/README.md)
completes its current-surface and consumer-transition inventory. After
acceptance, review if the provider no longer supports the required issue/label
semantics, consumers repeatedly need incompatible backlog models, lifecycle
states fail to represent ordinary work without exceptions, or optional
projection drift becomes operationally material.
