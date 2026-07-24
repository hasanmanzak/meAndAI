# 2026-07-23 - v0.13.3 Historical Capability-Review Recovery

## Scope

- Feature: [FEAT-0042](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/README.md)
- Decision: [DEC-0026](../../../docs/decisions/DEC-0026-historical-capability-review-recovery.md)
- Tracking: [issue #104](https://github.com/hasanmanzak/meAndAI/issues/104)
- Delivery: [PR #105](https://github.com/hasanmanzak/meAndAI/pull/105)
- Tests: [TEST-0165](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md) and [TEST-0166](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md)

## Verified problem

A merged capability review can retain its issue and branch if finalization is
interrupted. After a compatible protocol update appends catalog entries, the
retained marker no longer matches the current catalog and the v0.13.2 runner
rejects it before proving that the historical work already merged.

## Decision and implementation state

- Resolve the historical protocol commit from the consumer base commit's exact
  `.ai/protocol` gitlink, not issue prose or the current worktree.
- Require the exact VERSION tag, published immutable release, canonical Git
  blobs, catalog digest, and strict append-only predecessor relationship.
- Reapply current exact-head independent-review or personal-owner-attestation
  authority and prove the exact historical PR, merge, tree, and ledger.
- Preserve the complete current ledger, delete only the expected branch OID
  through a force-with-lease operation, record closure, and close the issue
  last.
- Permit one cleanup followed by one fresh current inventory per invocation;
  every active, unmerged, incompatible, duplicate, drifted, or unauthorized
  state remains fail-closed.

## Evidence

- The unchanged v0.13.2 runner produced the expected stale-catalog rejection
  after [TEST-0165](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md) and [TEST-0166](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md) were registered.
- The corrected, version-pinned capability-review owner passes [TEST-0139](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md),
  [TEST-0140](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0163](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md), [TEST-0164](../../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md), [TEST-0165](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md), and [TEST-0166](../../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md).
- StructureOnly and the v0.13.3 [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md) two-asset release bundle pass. The
  updater owner also passes outside the restricted sandbox after the sandboxed
  run reproduced Git for Windows `Win32 error 5` signal-pipe failures.
- The local aggregate runner reached its existing 15-minute process limit
  without reporting a test failure or completing. Hosted PR validation remains
  the required whole-repository gate before merge; release evidence is pending.

## Continuation

Complete the bounded blocker correction, final validation, PR, merge, and
immutable v0.13.3 release through [issue #104](https://github.com/hasanmanzak/meAndAI/issues/104). Do not mutate an affected
consumer from this protocol branch; install the released updater there and let
the consumer lifecycle perform the separately authorized recovery.
