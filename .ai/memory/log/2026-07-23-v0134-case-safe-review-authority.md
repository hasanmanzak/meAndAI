# 2026-07-23 - v0.13.4 Case-Safe Review Authority

## Scope

- Feature: [FEAT-0043](../../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md)
- Governing decisions: [DEC-0025](../../../docs/decisions/DEC-0025-exact-head-personal-owner-attestation.md)
  and [DEC-0026](../../../docs/decisions/DEC-0026-historical-capability-review-recovery.md)
- Tracking: [issue #106](https://github.com/hasanmanzak/meAndAI/issues/106)
- Delivery: [PR #107](https://github.com/hasanmanzak/meAndAI/pull/107)
- Tests: [TEST-0167 and TEST-0168](../../../docs/features/FEAT-0043-v0134-case-safe-review-authority/test-cases.md)

## Verified problem

The immutable v0.13.3 historical finalizer can compare a canonical lowercase
repository binding with an equivalent GitHub pull-request URL that retains the
repository's display casing. The strings differ even though GitHub owner and
repository-name identity is case-insensitive, so valid historical recovery
fails before cleanup. [Derdini run 30004752646](https://github.com/hasanmanzak/Derdini/actions/runs/30004752646)
retains the external failure evidence.

## Implemented correction

- Parse the trusted GitHub PR URL into structured host, owner, repository,
  pull-request path, and number components.
- Compare only owner and repository-name components case-insensitively.
- Keep host, URL structure, PR number, reviewed head, actor authority,
  immutable release, catalog, ledger, and cleanup evidence strict.
- Preserve exact ledger bytes, expected-OID branch deletion, issue-last
  closure, one fresh inventory, and completed-rerun idempotency.
- Use only project-neutral TEST-0167/0168 fixtures in the existing capability-
  review owner; add no workflow or hosted fan-out.

## Readiness and evidence

- `BUG-0025`, `FEAT-0043`, `SUBF-0082`, `RISK-0201`, `RISK-0202`, and issue
  #106 define the bounded correction.
- DEC-0025 already defines lowercase repository identity for owner
  attestation; DEC-0026 remains authoritative for historical proof and cleanup.
- TEST-0167 covers mixed-case equivalent recovery and idempotency. TEST-0168
  covers non-case identity, host, path, number, and malformed binding rejection.
- The focused test-first run failed as intended in 10.3 seconds. After the
  structured authority correction and bounded review fixes, the capability-
  review owner passed in 14.5 seconds with TEST-0167/0168 in scenario evidence.
- Final local StructureOnly validation passed in 13.6 seconds. Hosted checks,
  pull request, and immutable v0.13.4 publication remain pending.

## Continuation

Publish SUBF-0082 through issue #106 and record immutable v0.13.4 evidence. Do
not mutate Derdini from this branch.
After the immutable release is installed there, rerun the separately
authorized historical finalization and verify exact cleanup.
