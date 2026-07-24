# FEAT-NNNN - Feature Title

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed |
| Target version | M.m.rev |
| Issue | Replace with clickable link |
| Pull request | Replace with clickable link |
| Decisions | Replace with clickable links, or N/A with rationale |
| Tests | [Test scenarios](test-cases.md) |

Use clickable links to the exact referenced records; free-text identifiers, numbers, titles, or paths do not satisfy a reference.

## Problem

Describe the problem without prescribing an implementation.

## Outcome

Describe independently valuable behavior.

## Scope

- Included behavior.

## Non-goals

- Explicitly excluded behavior.

## Readiness evidence

- Domain and contracts: concepts, invariants, semantic types, units, nullability,
  lifecycle, errors, compatibility, and affected boundaries.
- Consumers and dependencies: entry points, callers, external systems, blocking
  work, and compatibility constraints.
- Risks: numbered `RISK-NNNN` records with owner and response.
- Verification approach: test levels, commands, manual checks, and review scope.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | Link numbered scenarios |
| Test code | Planned / not started / red | Link or rationale |
| Baseline run | Not run / failing / N/A | Command and reason |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-NNNN` | Reviewable slice | Issue link | Test links and latest result | Review link and findings | Proposed |

## Decisions and relationships

- Decisions:
- Parent epic:
- Dependencies:
- Related issues, pull requests, wiki pages, or documentation:

## Definition of Ready

- [ ] Stable ID and linked issue.
- [ ] Problem, outcome, scope, and non-goals.
- [ ] Acceptance criteria.
- [ ] Domain/boundary contracts, consumers, and dependencies.
- [ ] Numbered risks and decisions, or explicit N/A rationale.
- [ ] Reviewable decomposition with a gate ledger.
- [ ] Numbered test scenarios and verification approach.
- [ ] Test-code and baseline-run states recorded.

## Acceptance criteria

1. Measurable result.

## Self-review

Record date, reviewed diff/scope, findings, fixes, residual risks, and evidence
for the feature and for every declared subfeature. Number and classify each
finding, including findings fixed in the same slice.


Default to one bounded fresh-diff pass and one final relevant verification
command. Assign each observation exactly one protocol disposition: `Blocking`,
`AcceptedResidual`, `ExternalOrLegacyFollowUp`, or `OptionalImprovement`.
Record its required evidence contract: `Blocking` requires a verified fix for
completion; otherwise a durable blocking issue remains open and Definition of
Done remains incomplete. `AcceptedResidual` needs accepting authority, owner,
rationale, evidence, and review condition; `ExternalOrLegacyFollowUp` needs a
durable owner and link proving it is outside this change; and
`OptionalImprovement` needs evidence that its absence does not invalidate the
current work. Do not recursively add validators unless a concrete risk and
decision require them.

After development, the post-development full-project scan is mandatory. Record
its declared scope, exclusions, finite validation budget, prioritized findings,
remediation, and convergence or blocked outcome.

Record mandate cycle evidence in the same review surface:

- the material development trigger and scan entry;
- the dependency-first ready set and priority order;
- per-finding correction evidence and fresh-diff self-review;
- any change-caused or change-exposed blocker returned to the active queue;
- the confirmation result and converged final push, or the reason publication
  stopped; and
- the resulting waiting state or blocked state without an unchanged re-scan.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test commands and successful results recorded.
- [ ] Bounded self-review stop condition and explicitly required scans complete.
- [ ] No unresolved `Blocking` finding; every other disposition has its required authority, owner, rationale, and link.
- [ ] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed; if CI is not configured, rationale recorded.

## Post-merge release evidence

Keep this gate separate from the pre-merge Definition of Done. Complete it only
after publication. Before merge, designate one stable external evidence
authority, normally the delivery issue, as the external post-publication record;
keep every publication-dependent field `Pending`, and never predict a commit or
release identifier. Publication writes the exact facts to that external
authority and the GitHub Release; it does not require a follow-up
documentation-only pull request.

| Field | Evidence |
| --- | --- |
| External evidence authority | Stable issue or PR link selected before merge |
| Release authority | `Pending`; after publication, recorded externally as an immutable GitHub Release, historical annotated tag, or explicit N/A rationale |
| Release identifier | `Pending`; exact tag/release link is written to the external authority after publication |
| Target commit | `Pending`; exact full commit SHA/link is written to the external authority after publication |
| Verification evidence | `Pending`; release API/ref/check result and date are written to the external authority after publication |
