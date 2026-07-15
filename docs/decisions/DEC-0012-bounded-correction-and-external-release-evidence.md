# DEC-0012 - Bound Corrective Delivery and Keep Release Evidence External

- Classification: Decision
- Status: Accepted
- Date: 2026-07-16
- Decision owners: meAndAI maintainers
- Related feature: [FEAT-0012](../features/FEAT-0012-v082-correction/README.md)
- Tracking: [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), and [DEC-0011](DEC-0011-qualified-evidence-and-closure.md)
- Clarifies: exact automation ownership, scenario evidence, and pre-merge versus post-publication evidence

## Context

The read-only scan after v0.8.1 found ten blocking observations even though the
complete suite and the prior closure records were green. The defects shared
three causes: ownership was inferred from presentation strings instead of exact
records, concurrency and recovery were checked at only one instant or target,
and test/governance evidence asserted a behavior without retaining the contract
or event that proved it.

The v0.8.1 feature record also described its release as immutable before the
release existed. The release was subsequently published correctly, but that
later fact does not make the pre-publication claim valid. Requiring a second
documentation pull request after every release would create another completion
loop rather than repair the evidence boundary.

## Decision

The v0.8.2 correction remains one frozen, bounded feature:

1. Automation-owned records use an exact canonical marker parser and validate
   one unambiguous identity. Quoted, duplicated, malformed, or incidental marker
   text is not ownership evidence.
2. Repository-secret reconciliation is serialized per target repository. The
   live secret-name inventory is read inside that boundary before a missing
   secret is written, while existing names remain untouched.
3. A verified completed adoption proposal remains a valid lifecycle state until
   maintainer merge or explicit reviewed cleanup. The bootstrap path retains
   that exact maintainer-review proposal without mutation or duplicate creation.
4. Recovery inventories the complete reserved automation-branch namespace, not
   only the newest target name. Any unowned or ambiguous orphan blocks mutation.
5. Test doubles retain security-relevant headers, token authority, standard
   input, and repository identity. Assertions verify those contracts rather
   than only command success.
6. Each active `TEST-NNNN` has one canonical declaration, one owning suite and
   one evidence kind; successful completion of that suite is required.
   Historical superseded identifiers are never reused, and declared variants
   retain focused fixtures. Workflow semantics receive a pinned, checksummed
   actionlint CI gate in addition to repository tests.
7. The feature template always requires the one bounded post-development scan
   and preserves the distinct evidence contract for every finding disposition.
8. Pre-merge documents select a stable external publication authority and keep
   release/tag/commit/check fields `Pending`. After publication, exact evidence
   is written to that authority and the GitHub Release. No follow-up
   documentation-only pull request is required merely to mirror those facts.

The implementation is limited to the existing launcher, bootstrap/updater
adapters, tests, workflow, protocol, templates, and canonical records. It does
not add a service, recursive validator, or additional full-project scan.

## Consequences

- Ambiguous issue markers, concurrent secret provisioning, completed proposals,
  and old reserved branches fail closed at the owning boundary.
- Test evidence becomes more explicit, but the repository keeps its existing
  compact PowerShell test surface rather than adding a framework.
- Release records cannot be complete before publication. The stable external
  authority for FEAT-0012 is
  [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38); publication will
  add the exact release, commit, and check evidence there.
- The historical timing defect in FEAT-0011 remains visible as a correction
  record even though the current v0.8.1 release itself is valid.
- The finite validation budget is one initial scan and one confirmation scan
  after remediation. Only changed evidence or a blocking result may reopen the
  bounded work.

## Alternatives considered

- Add another generalized validator: rejected because the missed contracts
  require stronger evidence at existing boundaries, not another abstraction.
- Treat any marker substring as ownership: rejected because examples and quoted
  text are not authoritative records.
- Let concurrent launchers race and accept last-writer-wins secret behavior:
  rejected because an existing secret must never be overwritten.
- Reconcile only the current target branch: rejected because an older reserved
  orphan still affects ownership and recovery safety.
- Predict the release commit in the repository or require a post-release docs
  pull request: rejected because the former is impossible evidence and the
  latter creates needless delivery recursion.

## Review condition

Review if GitHub provides atomic create-if-absent repository secrets, structured
issue ownership metadata, an exact workflow schema validator built into the
Actions API, or commit-bound release attestations that can be referenced before
merge without predicting the merge commit.
