# FEAT-NNNN - Feature Title

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed |
| Target version | M.m.rev |
| Issue | Replace with clickable link |
| Pull request | Replace with clickable link |
| Tests | [Test scenarios](test-cases.md) |

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
command. Classify observations as blocking or follow-up, record the stop
condition, and do not recursively add validators unless a concrete risk and
decision require them.

When a post-development full-project scan is required, record its declared
scope, exclusions, finite validation budget, prioritized findings, remediation,
and convergence or blocked outcome.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test commands and successful results recorded.
- [ ] Bounded self-review stop condition and explicitly required scans complete.
- [ ] No unresolved blocking finding; non-blocking follow-ups are owned and linked.
- [ ] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed; if CI is not configured, rationale recorded.

## Post-merge release evidence

Keep this gate separate from the pre-merge Definition of Done. Complete it only
after publication; use `Pending` before then and never predict a commit or
release identifier.

| Field | Evidence |
| --- | --- |
| Release authority | Published immutable GitHub Release, historical annotated tag, or explicit N/A rationale |
| Release identifier | Exact tag/release link or `Pending` |
| Target commit | Exact full commit SHA/link from an external post-publication record, or `Pending` |
| Verification evidence | External release API/ref/check result and date, or `Pending` |
