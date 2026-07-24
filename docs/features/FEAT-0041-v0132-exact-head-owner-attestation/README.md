# FEAT-0041 - Exact-Head Owner Attestation for Capability Review

| Field | Value |
| --- | --- |
| Classification | Backward-compatible capability-finalization correction / [BUG-0023](https://github.com/hasanmanzak/meAndAI/issues/102) |
| Status | Complete |
| Target version | 0.13.2 |
| Issue | [#102](https://github.com/hasanmanzak/meAndAI/issues/102) |
| Pull request | [#103](https://github.com/hasanmanzak/meAndAI/pull/103) |
| Decision | [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md) |
| Tests | [TEST-0163](test-cases.md) and [TEST-0164](test-cases.md) |

## Problem

GitHub does not allow a pull-request creator to approve their own pull
request. The semantic capability finalizer nevertheless requires an exact-head
`APPROVED` review from a different trusted maintainer. A personal repository
maintained by its owner can therefore complete and merge valid semantic work
but has no protocol-approved finalization or recovery path. The exact review
branch and tracking issue remain open by design.

## Outcome

Keep independent exact-head approval as the normal path. Only when the pull
request has no review submissions at all, add one bounded
fallback for a personal repository owner who is also the pull-request creator
and an exact `admin` collaborator. A single canonical pull-request comment
attests the repository, pull-request number, and exact reviewed head. The same
evidence works before merge and for explicit recovery after merge; Ready and
merge events remain non-evidence.

## Scope

- Define one byte-exact owner-attestation comment schema bound to repository,
  pull request, and exact head SHA.
- Accept the fallback only for a GitHub `User` repository whose owner, pull-
  request creator, comment author, and permission response resolve to the same
  actor and whose current permission is exactly `admin`.
- Preserve the existing review-state behavior without an attestation lookup
  whenever any review submission exists; stale, rejected, creator-authored, or
  insufficient submissions cannot fall through to self-attestation.
- Reject stale, malformed, duplicate, conflicting, untrusted, non-owner,
  organization-owner, non-admin, or identity-drifted evidence before mutation.
- Reuse the existing explicit merged-PR recovery and branch-first/issue-last
  finalization path.

## Non-goals

- Treating Ready, merge, an ordinary comment, a commit author, or a workflow
  actor as semantic review evidence.
- Allowing self-attestation in organization-owned repositories or for a
  personal-repository collaborator who is not the owner.
- Weakening ledger, catalog, merge, tree, branch, issue, actor, containment,
  or idempotency gates.
- Adding a workflow, hosted job, service, retry loop, or consumer-specific
  fixture.

## Readiness evidence

- Domain and contracts: [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)
  defines the additive review-authority path and its exact identity boundary.
- Consumers and dependencies: the source-only capability-review runner used by
  the existing consumer workflow; GitHub repository, pull-request review,
  issue-comment, and collaborator-permission reads; no token-scope expansion.
- Risks: `RISK-0193` through `RISK-0196` below.
- Verification: focused capability-review tests first, then structural and
  release-pin validation, one bounded fresh-diff review, and the protocol's
  bounded final scan.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0163](test-cases.md) and [TEST-0164](test-cases.md) |
| Test code | Expected red complete | [TEST-0163](test-cases.md) reaches the canonical empty-review owner-attestation case and the unchanged v0.13.1 runner rejects it at the exact-head approval gate |
| Baseline run | Green | 2026-07-23 Windows PowerShell 5.1 focused owner passed with [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md) and [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md) before the new scenarios |

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0193` | Review authority | A generic self-comment silently replaces or bypasses an existing review | Protocol maintainer / fallback requires an empty review collection plus one canonical exact-head comment from the personal repository owner, PR creator, and exact admin actor |
| `RISK-0194` | Evidence integrity | A stale, malformed, duplicate, or spoofed marker is accepted | Capability-review maintainer / strict canonical bytes, complete bounded pagination, exact repository/PR/head binding, actor ID/login equality, and negative [TEST-0163](test-cases.md) coverage |
| `RISK-0195` | Recovery safety | Historical recovery bypasses merged-tree or cleanup gates | Consumer lifecycle maintainer / reuse the existing finalization state machine and prove no mutation for rejected evidence in [TEST-0164](test-cases.md) |
| `RISK-0196` | Runner efficiency | The correction adds repeated API work or hosted fan-out | Workflow maintainer / comments are read only after independent approval is unavailable; no new job or workflow and one bounded collection read per fallback attempt |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0080` | Canonical personal-owner attestation, exact-head authorization, and merged recovery | [Issue #102](https://github.com/hasanmanzak/meAndAI/issues/102) | [TEST-0163](test-cases.md), [TEST-0164](test-cases.md); expected red reproduced, corrected focused owner green | `FIND-0207` resolved during the bounded review | Complete |

## Decisions and relationships

- Governing decision: [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)
- Semantic capability lifecycle: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Post-merge finalization: [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) and [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- External incident evidence: [Derdini PR #14](https://github.com/hasanmanzak/Derdini/pull/14), [issue #13](https://github.com/hasanmanzak/Derdini/issues/13), and [failed run](https://github.com/hasanmanzak/Derdini/actions/runs/29909559142)

## Definition of Ready

- [x] Stable IDs and linked [issue #102](https://github.com/hasanmanzak/meAndAI/issues/102) exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria and exact authority/error contracts are defined.
- [x] Consumers, dependencies, compatibility, and token boundaries are known.
- [x] `RISK-0193` through `RISK-0196` and [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md) are recorded.
- [x] One independently reviewable slice has a gate ledger.
- [x] [TEST-0163](test-cases.md) and [TEST-0164](test-cases.md) and the bounded verification approach are defined.
- [x] Test-code and current-baseline states are recorded before implementation.

## Acceptance criteria

1. Any nonempty review collection retains the v0.13.1 review-state behavior
   and does not require a pull-request comment lookup.
2. With an empty review collection, exactly one canonical exact-head attestation from a
   personal repository owner who is also PR creator and exact admin authorizes
   the existing finalization path.
3. Ready, merge, ordinary comments, stale/wrong bindings, malformed or
   duplicate markers, non-owner or organization actors, insufficient
   permission, identity drift, and any attempted attestation fallback beside
   an existing review submission fail before branch or issue mutation.
4. An already-merged retained review can recover through the existing explicit
   pull-request-number dispatch after the owner adds the canonical comment.
5. Successful recovery preserves exact tree/ledger/merge proof,
   branch-first/issue-last cleanup, and completed-rerun idempotency.
6. No new workflow/job, credential permission, consumer-specific production
   knowledge, or hosted fan-out is introduced.

## Verification approach

Register [TEST-0163](test-cases.md) and [TEST-0164](test-cases.md) in the existing capability-adoption owner and first run
them against the unchanged v0.13.1 runner to record the intended failure. Add
the smallest production fallback, rerun the focused owner, then run structural
and release-pin checks. Perform one bounded fresh-diff review and one final
protocol validation command; only a proven Blocking finding reopens the slice.

## Self-review

The single bounded fresh-diff review found one Blocking design defect in the
initial proposal: the fallback was available whenever no trusted approval
existed, which could have allowed an owner comment to bypass a stale,
creator-authored, or adverse review submission. `FIND-0207` was resolved before
publication by making the complete review collection authoritative whenever it
is nonempty. The same review also preserved the existing reviewer result
shape, made the comment one exact API string, and added second-page pagination
and negative identity coverage. The subsequent focused run passed all four
capability-review scenarios; no unresolved Blocking finding remains.

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0207` | Blocking / review-authority bypass | A fallback based only on the absence of a trusted approval could bypass an existing non-authorizing review submission. | Resolved: owner attestation is evaluated only when the complete review collection is literally empty; [TEST-0163](test-cases.md) proves nonempty stale and creator-authored collections never read comments. |

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful focused results recorded.
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current for
      the pre-publication tree.
- [x] Issue, decision, tests, and related work cross-linked; the pull request
      and immutable release are recorded below when GitHub creates them.

Hosted gates, immutable publication, and the external retained consumer
recovery are post-merge evidence. They do not weaken or reopen this completed
upstream implementation gate and remain fail-closed until recorded below.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #102](https://github.com/hasanmanzak/meAndAI/issues/102) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
