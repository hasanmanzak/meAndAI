# FEAT-0008 - Repository-Native Idea Incubation

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Implemented |
| Target version | 0.7.0 |
| Issue | [#26](https://github.com/hasanmanzak/meAndAI/issues/26) |
| Pull request | [#28](https://github.com/hasanmanzak/meAndAI/pull/28) |
| Decision | [DEC-0009](../../decisions/DEC-0009-repository-native-idea-incubation.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The protocol begins delivery tracking at epics, features, tasks, bugs, findings,
decisions, tests, and risks. It has no durable repository-native state for an
idea that is worth preserving but has not been selected, scoped, or authorized
for delivery. Treating such a possibility as a feature implies false
commitment; leaving it only in chat makes it unavailable to other machines,
maintainers, and consumer projects.

## Outcome

Repositories can record an `IDEA-NNNN` under `docs/ideas` as a lightweight,
non-authorizing discovery artifact. An idea remains outside the delivery gates
until a maintainer promotes it to a linked numbered work item or decision.
Consumers receive the same protocol rule and pinned source template, while new
collision-free submodule adoptions also receive an absent idea index.

## Scope

- Define the `IDEA-NNNN` identifier, statuses, minimum record, and promotion
  lifecycle.
- Add a canonical idea index, reusable template, and the first repository idea
  for role-based multi-agent protocol integration.
- Add an absent-only `docs/ideas/README.md` target to collision-safe initial
  submodule adoption.
- Document how existing consumers create the index and idea records from their
  pinned protocol source without a forced migration.
- Add structural and bootstrap regression coverage.
- Publish the backward-compatible protocol capability as `0.7.0`.

## Non-goals

- Implementing role-based multi-agent behavior.
- Adding GitHub Discussions integration, a backlog service, or a general idea
  management application.
- Giving an idea Definition of Ready, implementation authority, mandatory
  tests, an issue, an owner, or a delivery date.
- Automatically updating or overwriting existing consumer-owned idea files.
- Reclassifying historical features, decisions, or findings as ideas.

## Readiness evidence

- Domain and contracts: an idea is an incubating possibility, not accepted
  scope. `Exploring`, `Parked`, `Promoted`, and `Rejected` are record statuses;
  only promotion creates a delivery or decision relationship.
- Consumers and dependencies: the canonical lifecycle is read through the
  pinned protocol. The template is available inside the pin. New collision-free
  submodule adoption may copy only an absent index; any existing target is a
  collision and remains untouched.
- Compatibility: current consumer pins remain immutable. Existing adopted
  consumers need no updater migration and may create `docs/ideas` when they
  first record an idea.
- Verification: structural contract/link checks plus a real-Git bootstrap
  fixture that proves absent-only installation and collision preservation.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0044` | Lifecycle | An idea is mistaken for approved implementation scope | Mitigated; maintainers | Explicit non-authorizing contract and promotion gate |
| `RISK-0045` | Consumer ownership | Adoption overwrites a consumer idea index | Mitigated; bootstrap adapter | Exact collision inventory and manifest-only proposal on collision |
| `RISK-0046` | Process weight | Every passing thought creates protocol bureaucracy | Mitigated; idea author | Minimal record, no issue/DoR/test requirement, and explicit value threshold |
| `RISK-0047` | Traceability | Promotion or rejection erases the reasoning history | Mitigated; maintainers | Preserve terminal idea records and add bidirectional links on promotion |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0043 and TEST-0044](test-cases.md) |
| Test code | Automated and green | `tests/idea-incubation.tests.ps1` and the existing real-Git bootstrap fixture |
| Baseline run | Passed | `TEST-0001` through `TEST-0042` in 90.9 seconds on Windows PowerShell 5.1, 2026-07-15 |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0015` | Idea lifecycle, decision, repository index, and template | [Issue #26](https://github.com/hasanmanzak/meAndAI/issues/26) | `TEST-0043`; passed 2026-07-15 | `FIND-0063`; resolved | Reviewed |
| `SUBF-0016` | Consumer adoption mapping, guidance, and regression closure | [Issue #26](https://github.com/hasanmanzak/meAndAI/issues/26) | `TEST-0044` and full suite; passed 2026-07-15 | `FIND-0062`; resolved | Reviewed |

## Decisions and relationships

- Decision: [DEC-0009](../../decisions/DEC-0009-repository-native-idea-incubation.md)
- Portable protocol: [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md)
- Adoption handoff: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Tracking: [issue #26](https://github.com/hasanmanzak/meAndAI/issues/26) and
  [pull request #28](https://github.com/hasanmanzak/meAndAI/pull/28)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Lifecycle, status, ownership, promotion, consumer, and compatibility contracts.
- [x] Numbered risks and DEC-0009.
- [x] Two bounded, reviewable slices.
- [x] Numbered test scenarios and verification approach.
- [x] Test-code state and successful pre-change baseline recorded.

## Acceptance criteria

1. `IDEA-NNNN` is a repository-local, monotonically allocated identifier whose
   record cannot authorize implementation or satisfy Definition of Ready.
2. Every idea records status, observation, possibility, potential value,
   concerns, promotion condition, and outcome; speculative delivery detail is
   optional and must not be presented as commitment.
3. Allowed statuses are `Exploring`, `Parked`, `Promoted`, and `Rejected`.
   Terminal records remain in history with rationale.
4. Promotion creates and links the appropriate `EPIC`, `FEAT`, `TASK`, or
   `DEC` record; implementation still waits for the normal delivery gates.
5. The protocol repository has an indexed first idea for the deferred
   role-based multi-agent protocol, without implementing that feature.
6. Consumers can use the lifecycle and template from their immutable protocol
   pin. A new collision-free submodule adoption receives an absent idea index;
   an existing index is never overwritten.
7. Existing consumers require no migration, and the updater's managed-path
   contract does not expand to consumer-owned idea content.
8. Structural, bootstrap, link, version, and full regression tests pass.

## Self-review

Completed on 2026-07-15. The declared scan scope was the complete tracked
repository, the `main`-to-branch diff, identifier/status inventory, active
version references, Markdown links, PowerShell parsing, real-Git bootstrap
fixtures, updater managed paths, and the full repository suite. `.git`, the
unrelated user-owned `.worktrees/bug-0002` worktree, generated temporary test
repositories, and external GitHub implementation were excluded from file
review. The finite budget was one fresh-diff review and one final full-suite
confirmation after blocker remediation.

| ID | Classification / severity / confidence | Evidence and action | Status |
| --- | --- | --- | --- |
| `FIND-0062` | Test fixture / High / High | The first full run found one escaped `v0.6.2` API-ref matcher after active fixtures moved to `v0.7.0`; updated the exact mock boundary and reran its focused and full suites. | Resolved |
| `FIND-0063` | Documentation usability / Medium / High | The consumer index named the pinned template path without a clickable immutable source; added the exact `v0.7.0` template link without making the updater own consumer idea files. | Resolved |
| `FIND-0064` | Repository hygiene / Low / High | The staged-diff check exposed Markdown hard-break trailing spaces in two newly added, previously untracked files; removed them before commit and repeated the staged check. | Resolved |

The convergence run passed `TEST-0001` through `TEST-0044` in 114.4 seconds;
the final post-record confirmation passed the same suite in 101.1 seconds. No
unresolved actionable in-scope finding remains, so the bounded scan stops.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Bounded self-review and convergence stop condition complete.
- [x] No unresolved blocking finding; residual risks are owned and linked.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue, pull request, decision, and related records cross-linked.
- [x] Applicable CI and review gates passed in
  [Protocol validation run 29423653441](https://github.com/hasanmanzak/meAndAI/actions/runs/29423653441)
  on Ubuntu and Windows; GitGuardian also passed.
