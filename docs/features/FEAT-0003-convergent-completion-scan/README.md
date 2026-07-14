# FEAT-0003 - Convergent Post-Development Scan

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | In progress |
| Target version | 0.3.0 |
| Issue | [#7](https://github.com/hasanmanzak/meAndAI/issues/7) |
| Pull request | Pending draft publication |
| Protocol | [Post-development convergence scan](../../../PROTOCOL.md#post-development-convergence-scan) |
| Decision | [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

Development can appear complete before a repository-wide review exposes
cross-cutting defects or drift. Repeating a literal “scan until no observation
exists” rule, however, can create an unbounded validation loop that never
distinguishes actionable blockers from owned residual risk.

## Outcome

Completed development receives a prioritized full-project scan and remediation
cycle whose success condition is zero unresolved actionable in-scope findings.
Finite scope, evidence-based repetition, and a blocked exit prevent blind loops.

## Scope

- Add the post-development convergence contract to the common protocol.
- Define priority ordering, remediation, repeat, convergence, and blocked states.
- Align the feature template and current adoption/version metadata.
- Add executable structural coverage and portable project-memory context.

## Non-goals

- A new scanner, validator framework, bootstrapper, or semantic AI-memory tool.
- Automatic remediation or automatic acceptance of residual risk.
- Reopening unrelated legacy refactors or findings in this delivery.
- Changing the semi-automatic consumer updater behavior.

## Readiness evidence

- Domain and contracts: the semantic states are `actionable`, `in scope`,
  `resolved`, `accepted residual risk`, `converged`, and `blocked`; completion
  cannot be inferred from validation-budget exhaustion.
- Consumers and dependencies: this repository and consumers that intentionally
  adopt `v0.3.0`; consumers pinned to earlier immutable tags remain unchanged.
- Verification: `TEST-0019`, the existing structural/link suite, one fresh-diff
  self-review, and one final relevant verification command.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0014` | Process | Literal zero-observation wording creates a blind loop | Mitigated; maintainers | Finite budget and blocked outcome in [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md) |
| `RISK-0015` | Quality | Findings are hidden by relabeling rather than resolved | Mitigated; maintainers | Residual risk requires ownership, rationale, and a link |
| `RISK-0016` | Scope | Self-application expands into unrelated hardening | Mitigated; maintainer/user | Explicit non-goals and one declared validation slice |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0019](test-cases.md#test-0019---post-development-convergence-contract) |
| Test code | Implemented in the same slice | [Structural test](../../../tests/protocol.tests.ps1) |
| Baseline run | N/A by explicit one-run validation budget | The contract assertion is added before final verification; no separate red run |

## Decomposition and subfeature gates

This is one small, coherent documentation-and-test slice; subfeature
decomposition is not applicable.

## Decisions and relationships

- Decision: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Related feature: [FEAT-0001](../FEAT-0001-common-development-protocol/README.md)
- Related issue: [#7](https://github.com/hasanmanzak/meAndAI/issues/7)

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Process states, consumers, compatibility, and dependencies identified.
- [x] Numbered risks and [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md).
- [x] Small-slice rationale recorded; no subfeature decomposition required.
- [x] Numbered test scenario and verification approach.
- [x] Test-code state and explicit baseline-run rationale recorded.

## Acceptance criteria

1. Development completion requires a full-project scan.
2. Findings are documented, classified, and resolved from highest to lowest
   severity.
3. Remediation repeats until no unresolved actionable in-scope finding remains.
4. Every repeat has changed diff, failed evidence, or a new actionable finding
   within a declared finite budget.
5. Budget exhaustion or missing authority produces a documented blocked state,
   never a successful completion claim.
6. The repository enforces the contract through executable `TEST-0019`.

## Self-review

Pending the final test run and fresh-diff review. The declared review scope is
the complete tracked repository with generated content and `.git` excluded. The
validation budget is the existing repository baseline, one remediation slice,
one final full-project contract/test pass, and one fresh-diff inspection.

| ID | Classification / severity / confidence | Evidence and action | Status |
| --- | --- | --- | --- |
| `FIND-0041` | Process gap / High / High | Completion scanning lacked a convergence contract; add the protocol subsection. | Resolved in diff; verification pending |
| `FIND-0042` | Loop risk / High / High | Literal repetition could be unbounded; add finite budget, progress, and blocked conditions. | Resolved in diff; verification pending |
| `FIND-0043` | Regression risk / Medium / High | The new contract could drift; add template alignment and `TEST-0019`. | Resolved in diff; verification pending |

Shared finding scope is `FEAT-0003`; impact is protocol execution behavior;
canonical evidence is the linked protocol section, decision, and test scenario.

## Definition of Done

- [ ] Acceptance criteria met.
- [ ] Mandatory test code and scenario mapping complete.
- [ ] Test command and successful result recorded.
- [ ] Bounded self-review and required convergence scan complete.
- [ ] No unresolved blocking finding; non-blocking follow-ups are owned and linked.
- [ ] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decision, and related work cross-linked.
- [ ] Applicable CI and review gates pass.

## Post-merge release gate

After the delivery pull request merges, tag the merged `main` commit as
`v0.3.0`, push the tag, and verify the remote reference.
