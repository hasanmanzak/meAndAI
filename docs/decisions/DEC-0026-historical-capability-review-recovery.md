# DEC-0026 - Recover Only Proven Merged Strict-Predecessor Capability Reviews

- Classification: Decision
- Status: Accepted
- Date: 2026-07-23
- Decision owners: meAndAI maintainers and consumer repository owners
- Related feature: [FEAT-0042](../features/FEAT-0042-v0133-historical-capability-review-recovery/README.md)
- Related decisions: [DEC-0016](DEC-0016-managed-post-merge-finalization.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0025](DEC-0025-exact-head-personal-owner-attestation.md)

## Context

Capability markers bind an immutable ordered catalog. A compatible protocol
release may append catalog entries after an earlier reviewed proposal merges
but before branch-first/issue-last cleanup completes. The retained issue then
has a different catalog identity from the current release even though its work
may already be contained in the default branch. Rejecting every mismatch
forever prevents convergence; treating mismatch as sufficient cleanup evidence
could destroy active or unrelated semantic work.

The recovery boundary must therefore distinguish a proven merged predecessor
from active or ambiguous stale state without trusting mutable worktree bytes,
rewriting the consumer ledger, weakening review authority, or adding an
unbounded reconciliation loop.

## Decision

The capability-review runner may retire at most one stale-catalog record per
invocation only after proving that it represents a merged strict predecessor
of the current catalog.

It resolves `.ai/protocol` from the historical pull request base head's
canonical Git tree. That gitlink must identify an exact immutable meAndAI
commit with one accepted version tag, and the catalog marker, catalog digest,
ordered entries, and immutable definition blobs must all match that release.
The historical catalog must be a strict byte-identical ordered prefix of the
current catalog; equality, rewriting, reordering, removal, an unrelated
history, or an untagged or moved release fails closed.

Exactly one trusted issue, pull request, branch, base head, reviewed head,
merged result, and marker must agree. The exact reviewed head must satisfy the
current review-authority contract: either a trusted independent exact-head
approval or, only under DEC-0025's boundary, the canonical exact-head personal-
owner attestation. Ready state, merge alone, cached authority, and issue prose
are not evidence.

The ledger at the merged historical result must be exact for the predecessor
catalog. The current default-branch ledger must preserve those reviewed entries
as an exact prefix and may contain valid later entries for the appended current
catalog. Recovery is metadata-only and must neither rewrite the ledger nor
discard later entries.

After one final live-state revalidation, branch deletion uses a true expected-
OID force-with-lease operation. A moved or absent-without-completion-proof ref
fails closed. Only after branch deletion or proven prior deletion may the
runner write one canonical closure marker and close the issue. It then acquires
one fresh current-catalog inventory so ordinary discovery can continue. It may
not clean a second historical record or reacquire inventory repeatedly in the
same invocation.

Any active, open, closed-unmerged, superseded, duplicated, drifted,
incompatible, unauthorized, or otherwise ambiguous record remains fail-closed
without mutation.

## Consequences

- Compatible append-only protocol evolution no longer strands a fully proven
  merged historical review.
- The existing fail-closed behavior remains the default and active semantic
  work cannot be retired from catalog mismatch alone.
- Historical recovery costs bounded canonical Git reads and GitHub evidence
  reads, plus at most one cleanup and one current inventory; it adds no job,
  poller, or hosted fan-out.
- Exact immutable-release provenance and current authority are stricter than
  trusting old runtime state, but consumers with incomplete historical evidence
  require maintainer repair rather than automatic cleanup.
- Ledger history remains monotonic: later valid assessments survive recovery
  unchanged.
- True lease deletion turns a concurrent branch move into a safe failure, while
  issue-last ordering preserves recoverable evidence after partial failure.

## Alternatives considered

- Close every issue whose marker differs from the current catalog: rejected
  because catalog drift does not prove merge, ownership, or authorization.
- Keep all historical markers permanently blocking: rejected because a proven
  compatible merged predecessor could never converge after an interrupted
  finalizer.
- Validate the old marker against the current catalog only: rejected because
  the historical digest and definitions require their exact immutable release
  context.
- Rebuild the old catalog from issue or pull-request text: rejected because
  consumer-controlled prose is not canonical release evidence.
- Replace the current ledger with the historical merged ledger: rejected
  because it would truncate valid later assessments.
- Delete the branch through an unconditional ref API call: rejected because a
  proof-to-mutation race could destroy newly moved work.
- Sweep every historical record until none remain: rejected because it creates
  an unbounded mutation and runner-cost loop; one cleanup plus one fresh
  inventory makes each invocation finite and inspectable.

## Review condition

Review if capability catalogs cease to be append-only, if GitHub provides a
native atomic conditional-ref deletion with stronger evidence, if immutable
release identity can no longer be proven from the protocol gitlink and tag, or
if real consumers require recovery across a deliberately incompatible catalog
transition.
