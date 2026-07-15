# DEC-0004 - Require Bounded Post-Development Convergence

- Classification: Decision
- Status: Accepted
- Date: 2026-07-14
- Decision owners: Repository maintainers
- Related feature:
  [FEAT-0003](../features/FEAT-0003-convergent-completion-scan/README.md)
- Related decisions: None

## Context

A final full-project scan can expose cross-cutting defects after feature work
appears complete. Requiring repeated scans without defining actionable scope,
progress, or a stop condition can instead produce a blind validation loop.

## Decision

After development is declared complete, assign every full-project scan
observation exactly one protocol disposition. `Blocking` means actionable and
in the current scope; it is the only disposition that reopens implementation or
prevents completion. `AcceptedResidual`, `ExternalOrLegacyFollowUp`, and
`OptionalImprovement` remain visible with their required authority, ownership,
rationale, and links but are not unresolved actionable in-scope findings.

Prioritize `Blocking` findings using severity, impact, and dependency order,
remediate them, and use the budgeted confirmation pass to prove none remain.
Before scanning, declare a finite validation budget,
scope, and exclusions. Every repeat requires changed diff, failed evidence, or
a new actionable finding. Budget exhaustion, missing authority, or an unchanged
blocker produces a blocked outcome rather than completion.

The four dispositions are mutually exclusive and reclassification requires new
evidence, changed scope, or recorded accepting authority; relabeling alone does
not clear a finding. The default budget is one
initial scan and one confirmation scan after remediation.

## Consequences

- Completion has an explicit repository-wide quality condition.
- High-priority actionable findings are handled before lower-priority work.
- The process can stop safely without claiming success when convergence cannot
  be reached inside its authority or budget.
- Consumers adopting `v0.3.0` receive a stricter prospective completion gate;
  earlier immutable pins remain valid.
- No new scanner or recursive validation framework is introduced.

## Alternatives considered

- Repeat until literally no observation exists: rejected as unbounded and
  unable to distinguish information from actionable work.
- Run only one scan regardless of blockers: rejected because known blocking
  defects could survive completion.
- Automatically defer every non-critical finding: rejected because severity
  does not replace scope, ownership, or acceptance analysis.

## Review condition

Review if ordinary deliveries repeatedly exhaust the default budget or if a
project class needs a different evidence-backed scan cadence.
