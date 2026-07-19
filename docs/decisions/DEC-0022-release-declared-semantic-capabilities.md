# DEC-0022 - Use Release-Declared Capability Assessment with Reviewed Semantic Adoption

- Classification: Decision
- Status: Accepted
- Date: 2026-07-19
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0032](../features/FEAT-0032-general-capability-test-architecture/README.md)
- Related decisions: [DEC-0002](DEC-0002-project-local-memory.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0018](DEC-0018-release-declared-consumer-migrations.md), and [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md)

## Context

Some reusable protocol practices can be installed deterministically, while
others require repository-aware interpretation and consumer-owned changes. The
existing migration catalog deliberately accepts only exact declarative state
transitions. Expanding it to reorganize tests, rewrite governance, or infer
applicability would violate its immutable path and state contract.

The protocol also needs one adoption path for a practice whether a repository
is newly adopting meAndAI, already current, or moving through an ordinary
compatible update. A documentation-only recommendation cannot produce a
traceable review handoff, while automatic semantic mutation would exceed the
updater's authority.

## Decision

### Typed immutable capability catalog

Every release may carry an ordered capability catalog at
`capabilities/index.json`. Each entry binds one stable lowercase slug, one
canonical definition path, one type, and the immutable Git blob of that
definition. Compatible catalogs are append-only: accepted predecessor entries
remain byte-identical and in the same order.

The supported types are:

- `Deterministic`: exact automation can establish and verify the contract.
- `DeclarativeMigration`: an exact consumer-state change is delegated to the
  existing `MIG-NNNN` catalog and ledger.
- `Semantic`: applicability or conformance requires repository-aware review and
  consumer-owned changes.
- `Manual`: completion depends on evidence outside deterministic automation.

The type states the authority model. It does not grant new path ownership.

### Consumer assessment evidence

Consumer capability evidence lives in `.ai/meandai-capabilities-state.json`,
outside project memory and outside the protocol submodule. It is not a second
protocol pin. Its ordered entries bind the capability slug, immutable
definition blob, terminal assessment, reviewed evidence, and review identity.
The ordered entries must be an exact prefix of the current target catalog.

Assessment has exactly four outcomes:

- `Conforming`: applicable and the reviewed consumer evidence satisfies the
  definition.
- `NotApplicable`: reviewed repository evidence proves that the definition's
  declared applicability condition does not hold.
- `AdoptionRequired`: applicable but not conforming; semantic consumer work is
  required.
- `ReviewRequired`: applicability, ownership, evidence, or a safe adoption plan
  is ambiguous.

Only `Conforming` and `NotApplicable` are terminal ledger entries.
`AdoptionRequired` and `ReviewRequired` remain transient handoff states. A
definition change appends a new catalog entry and therefore requires a new
assessment; an unchanged terminal definition/evidence pair is idempotent.

### Review-only lifecycle

Deterministic discovery may create only one canonical issue and one draft
semantic proposal for one unresolved immutable catalog batch. Their markers
bind repository, default-base identity, capability slugs, definition blobs,
catalog digest, branch, pull-request head, and tracking issue. Automation may
write the transient review manifest but may not perform semantic consumer
changes, mark the proposal ready, approve it, or merge it.

The invoked agent or maintainer satisfies the consumer's own DoR/DoD, records
the assessment, performs any authorized semantic adoption, removes the
manifest, and supplies review evidence. Completion is accepted only after the
reviewed proposal merges and the default branch contains a valid terminal
ledger. Cleanup is branch first under an exact-head lease and issue last with
one idempotent evidence marker. Ambiguity blocks without replacement or
cleanup.

Fresh protocol adoption retains its existing content envelope. After adoption
installs the local workflow, the same capability discovery path evaluates the
current catalog. An existing consumer whose immutable updater predates the
framework first installs it through the updater's ordinary proven path. The
newly installed workflow then performs one same-target capability discovery.
This split is capability-based, never source-tag-specific.

### First semantic capability

The first definition is `test-architecture`. It requires capability-based
physical test ownership, feature-based scenario traceability, deterministic
recursive suite discovery, small common infrastructure boundaries, separate
suite processes, and capability-local fixture ownership. It does not require
one programming language, test framework, directory spelling, or a brittle
file-size threshold. Equivalent repository-native structures may be recorded
as `Conforming`; repositories without an applicable automated test or
validation surface may be `NotApplicable` only with reviewed evidence.

## Consequences

- New semantic practices use one small reusable lifecycle rather than a new
  one-off migration or bootstrapper.
- Consumer ownership remains explicit: discovery is automated, semantic change
  and merge are reviewed.
- Fresh and existing consumers converge on one assessment contract, although
  immutable pre-framework consumers truthfully require an updater handoff
  before same-target discovery.
- A separate ledger and proposal namespace add state, but they avoid mixing
  semantic evidence with the deterministic migration ledger or live pin.
- `test-architecture` can be adopted across different stacks without forcing a
  universal runner implementation.

## Alternatives considered

- Encode test organization as `MIG-NNNN`: rejected because applicability and
  semantic file movement cannot be expressed as one exact state transition for
  every consumer.
- Let the updater rewrite tests automatically: rejected because it would gain
  unrestricted consumer-owned semantic path authority.
- Document the practice without discovery: rejected because existing consumers
  would have no canonical, idempotent adoption handoff.
- Create a central capability service or hosted AI agent: rejected as excessive
  authority and infrastructure for a compact pinned protocol.
- Use feature IDs as capability identities: rejected because consumer
  capability definitions are release contracts, while feature IDs track this
  repository's delivery history.
- Add a new global `CAP-NNNN` identifier class: rejected for the minimum
  framework; one stable slug plus immutable definition blob already supplies
  unambiguous catalog identity.

## Review condition

Review if a semantic capability cannot be represented by the four outcomes,
if consumer evidence shows that catalog-prefix identity is insufficient for
safe re-evaluation, if a deterministic capability needs broader managed paths,
or if GitHub provides an atomic reviewed semantic-proposal lifecycle primitive.
