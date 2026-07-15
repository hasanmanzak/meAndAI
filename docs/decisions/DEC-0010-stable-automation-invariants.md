# DEC-0010 - Use Stable Evidence Invariants Across Protocol Automation

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0010](../features/FEAT-0010-protocol-stability-invariants/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), and [DEC-0008](DEC-0008-local-codex-execution.md)

## Context

The protocol has separate checks for branch heads, pull-request markers,
managed paths, tags, workflow runs, and release records. Several checks compare
only snapshots or duplicate canonical inventories. A local fix can therefore
pass while the same missing invariant reappears through a rename, rerun,
concurrent event, or stale evidence record.

A workflow cannot embed the SHA of the commit that contains that workflow; the
resulting self-reference has no stable solution. An annotated tag is also a
movable Git ref unless an external authority locks it. Stable executable-source
trust therefore requires evidence outside the release commit itself.

## Decision

Automation uses six reusable evidence invariants:

1. **External release authority.** A tag is a version label, not executable
   authority. Source-only bootstrap and update-target selection require an
   exact published immutable GitHub Release whose associated tag is locked.
   Historical pre-v0.8.0 annotated tags remain valid historical records but are
   not described as cryptographically or administratively immutable.
2. **Persisted state transitions.** Proposal markers have explicit proposed and
   completed states and bind the live head for that state. Every mutation
   re-fetches canonical PR/ref evidence immediately before publication and
   verifies the resulting state afterward. Exact reruns reconcile incomplete
   launcher-owned transitions without rerunning semantic work.
3. **Complete path provenance.** Managed-path policy evaluates ordinal source
   and destination paths from machine-readable, NUL-delimited Git status. A
   rename, copy, case drift, or deletion cannot be reduced to its destination.
4. **Unique causality and continuity.** Workflow dispatch observes the prior
   run-ID set and accepts exactly one unseen matching run. Replacement-first
   cleanup revalidates replacement continuity around old mutation and uses
   explicit compensation where GitHub and Git cannot share a transaction.
5. **Canonical evidence sources.** Validation derives feature, decision, and
   memory coverage from canonical indexes or schema rather than maintaining a
   second partial file inventory. Claims state the evidence boundary they can
   prove; local Git inspection never claims unavailable remote history.
6. **Bounded responsibility seams.** High-risk validators separate PR-marker,
   tree/ancestry, manifest, and final-continuity evidence behind cohesive
   helpers while orchestration stays thin. Structural tests guard the seam so
   later hardening cannot silently rebuild a monolithic validator.

These invariants remain implemented by small functions and existing test
suites. They do not create a persistent validator service, background scanner,
or another bootstrap layer.

## Consequences

- New protocol releases require repository release immutability to be enabled
  before publication and require a GitHub Release, not only a pushed tag.
- A tag that exists before its immutable release is published is not eligible
  for new adoption or automated update.
- Proposal reruns gain a recoverable completed state instead of relying on an
  initial-head snapshot forever.
- Concurrency windows are documented and compensated; full distributed
  atomicity is still not claimed.
- Tests exercise invariant classes, reducing equivalent findings in later
  scans without recursively adding validators.
- Active template pins and test fixtures are checked against the canonical
  version, while historical evidence remains explicitly exempt.
- Exact release-target evidence lives in the external post-publication release
  or linked issue/PR record; repository documents do not create an impossible
  self-reference to their own commit.
- Existing consumers keep their current pin and adopt these prospective
  controls only when they review an upgrade to `v0.8.0` or later.

## Alternatives considered

- Embed the expected release commit in its own workflow: rejected because the
  commit hash includes that value and is self-referential.
- Trust annotated tags as immutable: rejected because the tag ref can be moved
  or deleted without an external lock.
- Add more one-off string assertions: rejected because duplicated snapshots
  caused the current class of drift.
- Build a central validator or hosted transaction coordinator: rejected as
  disproportionate to this compact, review-only protocol.
- Claim atomic supersession: rejected because Git refs and GitHub PR state do
  not share a transaction boundary.

## Review condition

Review if GitHub removes immutable-release evidence, provides conditional PR
mutations or atomic PR/ref cleanup, or a non-GitHub source provider is adopted.
