# 2026-07-22 - v0.12.7 API-Safe Merge Finalization

## Scope and authority

- Feature: [FEAT-0038](../../../docs/features/FEAT-0038-v0127-api-safe-merge-finalization/README.md)
- Tracking and publication authority: [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96)
- Correction: `BUG-0022`
- Test authority: [TEST-0155](../../../docs/features/FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md)
- Governing decisions: [DEC-0016](../../../docs/decisions/DEC-0016-managed-post-merge-finalization.md) and [DEC-0017](../../../docs/decisions/DEC-0017-idempotent-consumer-lifecycle.md)

## Verified problem

GitHub REST API `2026-03-10` omits `merge_commit_sha` from pull-request
payloads. The consumer updater is pinned to that version, while both managed
finalization paths still required the removed property. A live merged consumer
PR reproduced the strict-mode failure and exposed one canonical `merged` issue
event with the required commit identity.

## Implemented candidate

- One shared helper reads the exact pull request's complete paginated issue
  events and accepts exactly one case-sensitive `merged` event with a canonical
  lowercase 40-character `commit_id`.
- Ordinary/schema-2 finalization and legacy installing-update repair use that
  helper without changing any existing ownership or mutation gate.
- Normal finalization retains one verified commit across its existing four
  state checks; legacy tracking repair performs its own pre-mutation event read.
- `TEST-0155` omits the removed PR property, places the merged event after 100
  unrelated records, covers legacy and schema-2 success, idempotency,
  zero/duplicate/malformed/uncontained evidence, no-mutation failure, and a
  structural regression against reintroducing the removed field.

## Current evidence and continuation

- Test-first focused execution failed on the removed property in both
  production paths before the correction.
- Final corrected Windows PowerShell 5.1 execution passes in 24.3 seconds with
  canonical `TEST-0155` evidence, including the unmanaged no-event-read guard.
- `StructureOnly`, `git diff --check`, and the bounded review/convergence scan
  pass with no unresolved `Blocking` finding.
- Hosted checks, PR merge, immutable v0.12.7 release, owned-branch cleanup, and
  consumer recovery remain pending.
