# DEC-0033 - Build C# Governance from Canonical Specifications

- Classification: Decision
- Status: Accepted
- Date: 2026-07-28
- Decision owners: Maintainer and meAndAI governance owner
- Related features: [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md) and [FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md)
- Related decisions: [DEC-0030](DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), and [DEC-0034](DEC-0034-bounded-reusable-governance-catalog.md)
- Narrow supersession: supersedes [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) only where it sequences complete PowerShell differential evidence before bounded `CSharpShadow` implementation or an explicitly non-authoritative portable package; the separate applications, shared typed foundation, portable framework-dependent JIT distribution, and authority-state architecture remain authoritative

## Context

[FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
first treated a complete PowerShell scenario/variant ledger as a prerequisite
for writing C# governance behavior. That ordering made the legacy
implementation an implicit design source and delayed a small, independently
testable C# slice even though the canonical behavior already exists in the
protocol, decisions, feature contracts, and numbered scenarios.

The PowerShell inventory remains valuable evidence about supported legacy
behavior and retirement risk. It is not the normative description of the
target C# design. Project-local memory likewise preserves context and routes
recurring work, but the protocol explicitly makes it routing evidence rather
than executable or normative rule authority.

## Decision

Design and implement C# governance clean-room, specification first:

1. The canonical protocol, accepted decisions, owning feature contracts, and
   numbered test scenarios are the normative sources for behavior.
2. Project-local memory may supply dated context, known boundaries, and safe
   continuation routes. It cannot create or override a governance rule.
3. PowerShell source is not a C# design source and is not translated line by
   line. After an independently designed C# rule exists, the supported
   PowerShell path may be treated only as a legacy black-box oracle for
   differential evidence.
4. A bounded read-only `CSharpShadow` slice and an explicitly
   non-authoritative portable package may be implemented and tested before the
   exhaustive differential ledger and variant-level rule/profile matrix are
   complete.
5. The complete ledger and matrix remain mandatory before any equivalence or
   stronger-evidence claim, required-check enforcement, authority transfer,
   compatibility retirement, or PowerShell source retirement. Missing or
   divergent rows fail those later gates closed.
6. Existing PowerShell governance remains the production and compatibility
   authority throughout the clean-room slices. No slice disables a PowerShell
   route or authorizes repository, provider, adoption, or update mutation.

The first authorized vertical slice,
[SUBF-0138](../features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0138),
reuses canonical
[TEST-0004](../features/FEAT-0001-common-development-protocol/test-cases.md#test-0004):
for the explicit `protocol-authority` profile, inspect feature directories and
require both `README.md` and `test-cases.md`. The slice is repository-read-only,
provider-free, non-authoritative, and test-first. Its compiled test must first
fail for the missing C# behavior and then pass for conforming and missing-file
fixtures. This language implementation does not allocate a new `TEST-*`
identity.

On 2026-07-28 the maintainer's explicit continuation directive authorized only
this bounded first clean-room `CSharpShadow` vertical slice. Later rule slices,
managed integration, release publication, authority transfer, consumer
mutation, and retirement retain independent gates and authorization.

### Subsequent bounded scope allocation

[DEC-0034](DEC-0034-bounded-reusable-governance-catalog.md) preserves this
decision as the authoritative specification-first sequencing rule while
bounding the first
[FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
release to an exact declared catalog. It assigns
full `candidate` snapshot support, remaining governance coverage, and
equivalence qualification to
[FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md).
That allocation changes feature ownership and release scope, not this
decision's normative-source, black-box-oracle, or fail-closed authority
boundaries.

## Consequences

- C# structure follows readable domain contracts instead of legacy script
  control flow.
- Small rule slices can produce early typed design and test evidence without a
  false claim that migration coverage is complete.
- Differential work becomes incremental and can compare two independently
  implemented results instead of validating a transcription.
- A built or released non-authoritative package may have intentionally partial
  rule coverage; its report and documentation must state that limitation and
  cannot imply equivalence or enforcement eligibility.
- The historical inventory counts remain audit facts and become mandatory
  inputs at the equivalence and retirement gates.
- [DEC-0032](DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
  remains authoritative for application separation, portable JIT packaging,
  and authority states.

## Alternatives considered

- Translate PowerShell suite by suite: rejected because script structure would
  become accidental target architecture and remain hard for the maintainer to
  review.
- Finish every variant row before any C# implementation: rejected as an
  implementation sequencing rule; it remains required before equivalence,
  authority transfer, and retirement.
- Ignore PowerShell behavior entirely: rejected because supported legacy
  behavior still requires black-box differential and retirement evidence.
- Transfer authority after the first green C# rule: rejected because one rule
  cannot prove complete supported governance coverage.

## Review condition

Review before any equivalence claim, required-check enforcement, authority
transfer, or PowerShell retirement; or if canonical specifications cannot
define a rule without consulting implementation-specific behavior.
