# DEC-0034 - Bound the First C# Governance Release to a Reusable Catalog

- Classification: Decision
- Status: Accepted
- Date: 2026-07-29
- Decision owners: Maintainer and meAndAI governance owner
- Related epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Related features: [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md), and [FEAT-0063](../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
- Related decisions: [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) and [DEC-0033](DEC-0033-specification-first-csharp-governance.md)
- Narrow supersession: supersedes the [accepted FEAT-0060 v1 packet](../features/FEAT-0060-any-consumer-governance-cli/contract-decision-packet.md#7-candidate-snapshot-authority) only where that packet places full `candidate` snapshot support inside the first released governance package; the candidate contract remains planned under [FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md)
- Scope allocation: applies DEC-0033 by assigning exhaustive coverage and equivalence qualification to FEAT-0064; DEC-0033 remains authoritative and is not superseded

## Context

The first [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
slice proved that a readable, repository-read-only C# rule can be designed from
canonical specifications without translating PowerShell. The remaining
estimate nevertheless combined three different outcomes: a bounded useful
package, broad rule coverage, and exhaustive equivalence evidence required for
authority transfer and retirement.

Treating every canonical scenario as a separate parser, fixture, metadata
surface, review slice, and hosted run would also contradict the protocol's
single-owner and non-duplication rules. Feature records, decision records,
identifiers, versions, links, anchors, policy catalogs, and integration pins
share stable syntactic and semantic primitives even though their individual
governance invariants remain distinct.

## Decision

Deliver the first governance release as an explicitly bounded,
non-authoritative catalog over one reusable analysis pipeline.

1. A captured repository file is acquired once and parsed once per immutable
   evaluation context. Record, identifier, version, path, link, anchor,
   catalog, and integration indexes have one canonical owner and are reused by
   every applicable rule and later operational application.
2. Each rule family records a compact reuse map before implementation: the
   same-contract sibling inventory, canonical owners, reused types/methods/
   parsers/adapters/fixtures, and the genuinely new invariant. A new helper or
   parser requires evidence that the existing owner is semantically
   insufficient.
3. Common parsing and immutable semantic models live at the narrowest shared
   inward layer justified by known consumers. Governance-only policy remains
   in the governance core. Adoption and consumer update remain separate
   applications and authority boundaries; they consume shared primitives
   instead of reimplementing them.
4. Surface similarity alone does not justify a universal framework or one
   all-purpose rule. Distinct invariants may retain distinct rule classes while
   sharing the same parsed models, indexes, finding envelope, serializer, and
   fixture builders.
5. [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
   closes only a bounded `0.17.0` catalog: explicit `protocol-authority` and
   canonical `.ai/protocol` gitlink `consumer` profiles, an `exact-commit`
   release snapshot, canonical
   [TEST-0004](../features/FEAT-0001-common-development-protocol/test-cases.md#test-0004)
   and
   [TEST-0005](../features/FEAT-0001-common-development-protocol/test-cases.md#test-0005),
   deterministic typed report/exit behavior, and one portable
   `maai-governance.zip`.
6. The report binds the exact evaluated rule inventory and catalog digest and
   declares bounded coverage. `Conforming` means conforming only to that exact
   declared catalog; it is not a complete-governance, equivalence,
   required-check, or authority claim.
7. The release CLI does not expose implicit snapshot selection. Full
   HEAD/index/worktree `candidate` overlay, repository-reference adapters,
   remaining transferable rule families, mixed-boundary normalization, and
   same-snapshot PowerShell/C# differential qualification belong to
   [FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md).
8. Existing PowerShell governance remains production and compatibility
   authority. [FEAT-0063](../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
   depends on complete FEAT-0064 equivalence evidence in addition to the
   released operational applications before any authority, compatibility, or
   source retirement.

## Consequences

- The maintainer receives a real portable C# package before exhaustive
  equivalence work, without a misleading completeness claim.
- Parser, grammar, snapshot, serializer, digest, finding, and fixture logic is
  implemented once and reviewed before a second same-contract implementation
  can appear.
- The first release intentionally cannot validate dirty or staged candidate
  state and supports only the canonical gitlink consumer integration.
- Remaining coverage and differential work is moved, not waived. Missing or
  divergent evidence continues to block required-check eligibility, authority
  transfer, and retirement.
- Separate executable composition roots and application-specific packaging
  metadata may remain small and explicit because they preserve different
  authority boundaries; they do not own duplicate business rules.

## Alternatives considered

- Complete all 43 candidate identities and every differential variant inside
  FEAT-0060: rejected because it delays the first useful package and conflates
  delivery with authority qualification.
- Implement each canonical scenario independently: rejected because it would
  duplicate parsers, models, fixtures, and metadata and cause late review
  rework.
- Build a universal parser or source-generator framework first: rejected
  because common ownership must follow concrete contracts and consumers, not
  speculative abstraction.
- Remove PowerShell validation while C# coverage is bounded: rejected because
  the C# package is explicitly non-authoritative.

## Review condition

Review before widening the released snapshot or consumer-adapter surface,
claiming complete governance coverage or equivalence, enabling a required
check, transferring authority, or retiring any PowerShell route; or when two
consumers expose incompatible semantics that the shared analysis model cannot
represent without false consolidation.
