# DEC-0011 - Carry Qualified Evidence Through Mutation and Closure

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0011](../features/FEAT-0011-stability-closure/README.md)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), [DEC-0008](DEC-0008-local-codex-execution.md), and [DEC-0010](DEC-0010-stable-automation-invariants.md)
- Clarifies: DEC-0010 evidence identity, causality, and canonical-state clauses

## Context

The v0.8.0 correction defined reusable evidence invariants but several adapters
reduced qualified evidence to a presentation value: repository host became a
slug, immutable release became a Boolean check detached from its credential and
commit, rename provenance became destination-only paths, and workflow dispatch
became a time-window match. Governance likewise projected one delivery state
into files and GitHub records without a post-publication reconciliation step.

These reductions allowed equivalent defects to survive or be introduced while
local structural tests remained green. Adding another validator would repeat
the same problem at a new layer.

## Decision

Evidence remains qualified from observation through mutation and closure:

1. A GitHub repository identity is `(host, owner, repository)`. A verified host
   is never discarded before metadata, credential, workflow, issue, PR, or
   source operations.
2. Protocol release authority is `(repository, tag, locked commit, release
   state, source credential boundary)`. The private-source token resolves that
   record after publication; the consumer-write token never substitutes for it.
3. Path evidence contains every ordinal source and destination path.
   Deterministic local proposals disable rename inference so a rename is
   evaluated as deletion plus addition; API proposals reject rename/copy
   provenance rather than inferring preservation from destination paths.
4. A launcher session creates a unique correlation ID and requires that exact
   identity in its workflow run. Read-then-create external records receive a
   post-create convergence check.
5. A finding has exactly one disposition: `Blocking`, `AcceptedResidual`,
   `ExternalOrLegacyFollowUp`, or `OptionalImprovement`. Only `Blocking` is an
   unresolved actionable in-scope finding. The other states require recorded
   ownership/rationale as applicable and never trigger an unchanged scan.
6. Pre-merge delivery state and post-publication release state are separate.
   After publication, current feature/index/memory and owned GitHub status
   projections are reconciled, and durable external links use `main`, an
   immutable release/tag, or an exact commit before branch deletion.
7. A test claim is supported by an executable scenario identity and observed
   result. Summary text, substring checks, and physical line counts may aid a
   test but cannot independently claim runtime, schema, timeout, or scenario
   coverage.

The implementation stays inside the existing scripts, fixtures, documents, and
CI workflow. No persistent service or recursive validation framework is added.

## Consequences

- Consumer operations fail closed when host, credential, commit, path, or
  session evidence cannot remain qualified.
- Future private-protocol updates use both existing credentials for their
  intended independent authorities.
- A unique dispatch input changes the v0.8.1 seed workflow contract but remains
  backward-compatible for reviewed adopters and manual dispatch.
- Completion stops on known blocking defects while recorded non-blocking work
  does not create a blind validation loop.
- Release closure includes a small external reconciliation step; it does not
  predict a self-referential release commit inside that commit.
- Test evidence becomes more honest without introducing a large test registry
  or universal validator.

## Alternatives considered

- Add more one-off substring assertions: rejected because they produced the
  false-green evidence being corrected.
- Use the updater PAT for both repositories: rejected because it violates the
  least-privilege credential decision and broadens blast radius.
- Accept timestamp-based workflow causality: rejected because concurrent runs
  for the same commit are indistinguishable.
- Repeat scans until no observation exists: rejected as an unbounded loop.
- Build a hosted coordinator or semantic validator: rejected as unnecessary
  authority and complexity for this compact review-only protocol.

## Review condition

Review if GitHub provides host-bound repository handles, a dispatch API that
returns an exact run ID, commit-bound immutable-release attestations, or atomic
issue create-if-absent semantics.
