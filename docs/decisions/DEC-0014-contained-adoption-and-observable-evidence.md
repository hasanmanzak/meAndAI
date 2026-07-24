# DEC-0014 - Require Contained Adoption and Observable Evidence

- Classification: Decision
- Status: Accepted
- Date: 2026-07-16
- Decision owners: meAndAI maintainers
- Related feature: [FEAT-0014](../features/FEAT-0014-v085-convergence/README.md)
- Tracking and publication authority: [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), [DEC-0012](DEC-0012-bounded-correction-and-external-release-evidence.md), and [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md)

## Context

The v0.8.4 correction strengthened trusted updater preflight, seed ordering,
recoverable publication, exact manifest validation, and external evidence. Its
complete suite passed, but the requested read-only scan found nine remaining
observations at adjacent boundaries.

A repository-relative string and clean Git status do not prove that a managed
destination stays inside the workspace when an existing ancestor is a symbolic
link, junction, or reparse point. `Completed` state also receives less semantic
validation than `Publishing`, even though both claim the same completion result.
Version grammar has an exact protocol definition but divergent runtime parsers.

Evidence has a related problem: several named variants are not executed,
workflow dispatch mocks derive their success from caller input, and the
scenario-ownership gate infers every mapped result from one suite exit. Durable
records then miscount one prior disposition and leave the external GitHub
projection stale or incomplete. Another generalized validator would not repair
these ownership boundaries.

## Decision

1. **Containment precedes side effects.** For every managed target, the owning
   launcher or bootstrap path first establishes a canonical lexical path below
   the workspace root, walks every existing ancestor, rejects symbolic links,
   junctions, and reparse points, and confirms the resolved destination remains
   inside the workspace. This gate occurs before the affected secret boundary
   or managed filesystem mutation.
2. **One completed-publication contract.** `Publishing` recovery, bootstrap
   retention, and launcher readiness reuse one pure exact validator for the
   completion transition. It proves a single expected parent, the allowed
   change set, protected-path integrity, exact protocol reference, exact updater
   assets, manifest absence, and bound proposal identity before mutation.
3. **One canonical version grammar.** A protocol version consists of three
   unbounded ASCII decimal components without leading zeros except `0`.
   Parsing and numeric comparison do not use `\d` or `System.Version` as the
   semantic authority and therefore introduce no undocumented platform bound.
4. **Declared variants are executable obligations.** Every named exact,
   missing, drifted, identity, schema, type, interruption, release, and
   case-collision variant receives a focused or parameterized fixture at its
   owning boundary. A description is narrowed if the behavior is not executed.
5. **External mock identity is independently derived.** Workflow dispatch
   evidence includes exact repository, workflow, ref, correlation, and expected
   head. The mock persists its own expected event and must not echo a later
   caller query to manufacture a matching run.
6. **Scenario completion is observable.** Each executable owner exposes a small
   explicit set of scenario IDs and results. The repository validator compares
   that observed set with the canonical ownership map. Suite process success is
   necessary but is not evidence that every mapped scenario executed. This is a
   compact evidence contract, not a new framework.
7. **Canonical and hosted projections converge.** Counts and scenario wording
   match their owning records. Closed issues do not retain an in-progress state;
   issues and pull requests link the canonical feature and decision; unresolved
   external [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) receives a durable active finding record. These changes
   do not claim that [RISK-0076](../features/FEAT-0013-v084-correction/README.md) itself is resolved.
8. **Validation remains finite.** Delivery uses one correction pass over the
   three declared slices, one fresh-diff self-review and complete suite, review
   branch and pull-request publication, and one fresh confirmation scan. A pass
   repeats only for a verified actionable finding, changed evidence, or failed
   declared gate while budget remains.

## Consequences

- Linked or escaping managed targets fail before credentials or files can cross
  the intended repository boundary.
- A completed proposal cannot gain trust from its marker alone; every completion
  projection proves the same transition and protected content.
- Runtime version selection matches the documented grammar even for very large
  components, while existing canonical tags remain compatible.
- The test surface gains focused cases and a compact result manifest, but no
  runner framework, service, or additional persistent validator layer.
- Missing scenario assertions, wrong workflow dispatch, stale external status,
  and inaccurate durable wording become observable failures.
- Private-repository `main` protection remains an external maintainer-owned risk
  with its existing visibility/plan review condition.
- Exact merge, release, commit, and hosted-check facts remain in [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) and
  the GitHub Release after publication rather than being predicted here.

## Alternatives considered

- Rely on Git staging to reject linked paths: rejected because external writes
  or secret mutations can already have occurred before staging fails.
- Validate only the final destination: rejected because an existing linked
  ancestor can redirect an otherwise ordinary final filename.
- Keep separate `Publishing` and `Completed` validators: rejected because their
  semantic drift created the trust gap.
- Use a stricter `System.Version` bound without documentation: rejected because
  the protocol defines unbounded decimal components and does not need a runtime
  integer representation for comparison.
- Treat a successful suite exit as evidence for all mapped scenarios: rejected
  because scenario assertions can disappear while unrelated suite work remains
  green.
- Build a new test framework or validator service: rejected because explicit
  result sets and focused fixtures fit the existing small test surface.
- Mark branch protection resolved or reopen the completed delivery feature:
  rejected because the control is still externally unavailable and needs a
  dedicated follow-up, not a false completion claim.

## Review condition

Review this decision if the supported filesystems provide a portable atomic
no-follow write primitive, GitHub exposes an atomic secret-plus-seed transaction,
proposal state becomes an immutable signed object, the version contract adopts
an explicit numeric bound, or the test runner gains native per-scenario result
reporting that replaces the compact repository contract.
