# 2026-07-23 - v0.13.2 Exact-Head Personal-Owner Attestation

## Scope

- Feature: [FEAT-0041](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/README.md)
- Decision: [DEC-0025](../../../docs/decisions/DEC-0025-exact-head-personal-owner-attestation.md)
- Tracking: [issue #102](https://github.com/hasanmanzak/meAndAI/issues/102)
- Tests: [TEST-0163](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md) and [TEST-0164](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md)

## Verified problem

The v0.13.1 capability finalizer accepts only an exact-head `APPROVED` review
from a different trusted maintainer. GitHub prohibits a pull-request creator
from approving their own pull request. A valid personal-owner semantic review
can therefore merge but retain its exact branch and issue with no supported
finalization recovery. Ready and merge are deliberately not review evidence.

## Decision and implementation state

- Any nonempty review collection retains the existing independent review-state
  behavior and never falls through to self-attestation.
- Only an empty review collection can use one exact single-line comment bound
  to repository, pull request, and exact head SHA.
- The comment author, PR creator, `User` repository owner, and collaborator-
  permission actor must be the same identity; permission must be exactly
  `admin`.
- Automation reads but never creates the attestation. Existing ledger, tree,
  merge, branch, issue, closure, and idempotency gates remain unchanged.
- The existing `finalize_pull_request` dispatch supplies already-merged
  recovery; no new workflow, job, token scope, or consumer-specific fixture is
  added.

## Evidence

- Baseline focused owner passed [TEST-0139](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) and [TEST-0140](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) on v0.13.1.
- Test-first execution then failed at the absent owner fallback with
  `Merged capability review lacks an approval for the exact review head.`
- Corrected focused execution passed [TEST-0139](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0140](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0163](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md), and
  [TEST-0164](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md), including a valid page-two attestation after 100 ordinary
  comments, nonempty-review non-fallback, identity/permission negatives,
  branch-first issue-last recovery, and completed-rerun no-op behavior.
- Structural validation passed all discovered contracts and current-release
  metadata; the v0.13.2 release-bundle contract passed [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md).

## Continuation

Complete the one bounded fresh-diff review, then publish v0.13.2 through [issue
#102](https://github.com/hasanmanzak/meAndAI/issues/102) and retain hosted evidence there.
Do not mutate the affected consumer from this branch. After the immutable
release is installed there, the personal owner adds the exact canonical
attestation to the retained merged pull request and explicitly reruns
finalization.
