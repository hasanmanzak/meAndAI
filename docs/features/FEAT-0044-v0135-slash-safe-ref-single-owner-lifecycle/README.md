# FEAT-0044 - Slash-Safe Ref and Single-Owner Consumer Lifecycle

| Field | Value |
| --- | --- |
| Classification | Backward-compatible consumer-lifecycle correction / [BUG-0026](https://github.com/hasanmanzak/meAndAI/issues/108) |
| Status | Complete |
| Target version | 0.13.5 |
| Issue | [#108](https://github.com/hasanmanzak/meAndAI/issues/108) |
| Pull request | [#109](https://github.com/hasanmanzak/meAndAI/pull/109) |
| Decisions | [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md), [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0027](../../decisions/DEC-0027-single-owner-consumer-merge-events.md) |
| Tests | [TEST-0169](test-cases.md) and [TEST-0170](test-cases.md) |

## Problem

The capability-review runner URI-encodes an entire slash-bearing review branch
before calling GitHub's Git refs API. The resulting `automation%2F...` path is
not the hierarchical `heads/<branch name>` endpoint and returns `404`, leaving
an otherwise recoverable review branch behind.

The consumer lifecycle also lets both the merged pull-request event and the
same default-branch push enter proposal discovery. A later push made by the
review branch itself can acquire the workflow concurrency key before job-level
guards run and replace the pending pull-request event. The exact merge event
then loses ownership while a branch-only handoff remains.

The generic failures were observed in Derdini runs
[30011058590](https://github.com/hasanmanzak/Derdini/actions/runs/30011058590),
[30011059451](https://github.com/hasanmanzak/Derdini/actions/runs/30011059451),
and [30011271796](https://github.com/hasanmanzak/Derdini/actions/runs/30011271796).

## Outcome

Preserve `/` as the Git ref path delimiter while encoding each branch segment,
then make the merged `pull_request.closed` event the sole owner of post-merge
finalization and proposal discovery. Remove `push` from the consumer lifecycle;
schedule and manual dispatch retain bounded repository-evidence recovery.

## Scope

- Use one segment-safe ref-path encoder for every capability-review Git ref
  read, update, and post-delete verification.
- Preserve exact ref/OID evidence, expected-head lease deletion, branch-first
  and issue-last cleanup, and idempotent recovery.
- Resume an exact branch-only interrupted handoff without creating a second
  branch.
- Remove default-branch and automation-branch push triggers from the consumer
  lifecycle so one managed merge creates one hosted run.
- Preserve managed PR merge, schedule, ordinary dispatch, and explicit pull-
  request-number recovery.
- Add focused regression coverage to the existing capability owners.

## Non-goals

- General orphan-branch deletion or prefix-based cleanup.
- Removing schedule or manual recovery.
- Adding a service, GitHub App, queue, retry loop, workflow, or test suite.
- Changing credential scopes, semantic assessment, consumer-owned files, or
  immutable historical releases.
- Mutating a consumer until v0.13.5 is published and its live evidence is
  revalidated.

## Readiness evidence

- Domain and contracts: [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) owns exact merged-PR finalization; [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
  owns idempotent repository-evidence recovery; [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md) requires bounded
  runner use; [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) owns the semantic review issue/branch/PR lifecycle;
  [DEC-0027](../../decisions/DEC-0027-single-owner-consumer-merge-events.md) assigns one workflow event per managed merge.
- Consumers and dependencies: the source-only capability-review runner, the
  canonical consumer workflow, GitHub Git refs API, and the existing injected
  production fixtures.
- Risks: `RISK-0203` through `RISK-0206` below.
- Verification: test-first focused owners, structural validation, one bounded
  diff review, one final relevant suite, and post-publication consumer recovery.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0169](test-cases.md) and [TEST-0170](test-cases.md) |
| Test code | Implemented | Existing capability-review and managed-finalization owners; no new suite |
| Baseline run | Failed as intended | Derdini run 30011058590 recorded the escaped-ref 404; runs 30011059451/30011271796 recorded pending-run displacement; focused [TEST-0169](test-cases.md) and [TEST-0170](test-cases.md) runs rejected `%2F`, absent event filtering, and duplicate proposal ownership |

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0203` | Ref identity | Encoding the branch as one URI token or failing to encode an individual segment targets another endpoint | Capability-review maintainer / encode segments independently, preserve literal separators, and require exact endpoints in [TEST-0169](test-cases.md) |
| `RISK-0204` | Duplicate mutation and cost | PR merge and default push start separate hosted lifecycle runs | Consumer lifecycle maintainer / PR merge alone owns the lifecycle; schedule/manual own recovery in [TEST-0170](test-cases.md) |
| `RISK-0205` | Concurrency | A merge-caused or self-created push replaces the pending exact-PR run before job guards execute | Workflow maintainer / remove push admission entirely and retain non-canceling lifecycle concurrency |
| `RISK-0206` | Recovery safety | Recovery deletes a moved, foreign, ambiguous, or merely prefix-matching branch | Capability-review maintainer / retain exact repository, branch, expected-OID, PR/issue, and lease gates; no generic orphan cleanup |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0083` | Slash-safe exact Git-ref lifecycle and branch-only recovery | [Issue #108](https://github.com/hasanmanzak/meAndAI/issues/108) | [TEST-0169](test-cases.md); passed in 14.5 seconds with its capability owner | Bounded review found no production defect; literal-slash, no-duplicate, finalization, and rerun evidence are explicit | Complete |
| `SUBF-0084` | Single-owner merge routing and push exclusion | [Issue #108](https://github.com/hasanmanzak/meAndAI/issues/108) | [TEST-0170](test-cases.md); passed in 18.3 seconds with its managed-finalization owner | Bounded review first rejected recovery-only push because it still created a second hosted run; refined test and [DEC-0027](../../decisions/DEC-0027-single-owner-consumer-merge-events.md) require no push admission | Complete |

## Definition of Ready

- [x] [BUG-0026](https://github.com/hasanmanzak/meAndAI/issues/108), `FEAT-0044`, `SUBF-0083`, `SUBF-0084`, and [issue #108](https://github.com/hasanmanzak/meAndAI/issues/108) exist.
- [x] Problem, outcome, scope, non-goals, API route, and event ownership are explicit.
- [x] Consumers, dependencies, credential boundaries, and compatibility are known.
- [x] `RISK-0203` through `RISK-0206` and governing decisions are recorded.
- [x] Independently testable slices and their gate ledger are defined.
- [x] [TEST-0169](test-cases.md) and [TEST-0170](test-cases.md) and the bounded verification approach are defined.

## Acceptance criteria

1. Every slash-bearing capability review branch uses literal `/` ref path
   separators with each segment URI-encoded independently; `%2F` is rejected.
2. Exact branch-only interrupted creation resumes issue, manifest, and draft PR
   work without a second ref creation; real ref/OID drift still fails closed.
3. Finalization reads the same exact ref, deletes through the existing
   expected-OID lease, verifies absence, closes the issue last, and reruns as a
   no-op.
4. A managed PR merge owns metadata-dependent proposal discovery exactly once.
5. Default-branch and reserved automation-branch pushes create no consumer
   lifecycle run and cannot displace a pending exact-merge event.
6. Schedule and ordinary/manual lifecycle routes retain bounded recovery and
   discovery authority.
7. No new credential, consumer-specific production rule, test suite, or
   generalized orphan deletion is introduced.

## Verification approach

Add [TEST-0169](test-cases.md) and [TEST-0170](test-cases.md) to their existing capability owners and capture the
expected failures against v0.13.4. Implement the two minimal corrections, rerun
the focused owners, run structural checks, review one fresh diff, and execute
one final relevant protocol validation. After immutable publication, install
the reviewed workflow/runtime in the affected consumer and recover only the
exact revalidated branch.

## Self-review

One bounded fresh-diff review confirmed that the production change is limited
to one segment-safe ref helper and the canonical workflow's event guards. All
five capability-review ref call sites use the helper; exact OID/lease,
branch-first/issue-last, authority, and credential paths remain unchanged.
The review rejected the initial recovery-only push design because it still
created a second hosted run and could compete for the single pending
concurrency slot. [DEC-0027](../../decisions/DEC-0027-single-owner-consumer-merge-events.md) and [TEST-0170](test-cases.md) now remove push admission entirely;
schedule/manual routes retain recovery. Structural validation also found one
stale escaped current-release fixture and the intermediate feature status;
both record/test defects were corrected. No blocking production finding
remains.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Focused test evidence recorded; final validation is recorded in the test scenarios.
- [x] Bounded self-review complete with no unresolved `Blocking` finding.
- [x] Documentation, version, changelog, links, and memory current for the
      pre-publication tree.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #108](https://github.com/hasanmanzak/meAndAI/issues/108) |
| Pull request | [#109](https://github.com/hasanmanzak/meAndAI/pull/109) |
| Release authority | [Immutable v0.13.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.5) |
| Release identifier | `v0.13.5` |
| Target commit | `014f9bbe30074a742c84e3915ebcf94b9fe9cc3e` |
| Consumer recovery | No consumer mutation is claimed by this feature; later shared byte-evidence work is owned by [FEAT-0045](../FEAT-0045-v0140-canonical-repository-evidence/README.md) |
