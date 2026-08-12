# Repository Knowledge Catalog Records-Only Planning

Date: 2026-08-12

## Current state

- [FEAT-0071](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md)
  is a proposed records-only plan tracked by
  [issue #182](https://github.com/hasanmanzak/meAndAI/issues/182) and
  [draft PR #183](https://github.com/hasanmanzak/meAndAI/pull/183).
- [DEC-0039](../../../docs/decisions/DEC-0039-repository-knowledge-catalog-and-react-explorer.md)
  is proposed; implementation authority is withheld.
- The detailed [Repository Knowledge Catalog architecture](../../../docs/architecture/repository-knowledge-catalog/README.md)
  records contract vocabulary, source/projection authority, delivery slices,
  security bounds, and unresolved Gate 2 questions.
- No application, dependency, database, migration, API, UI, test implementation,
  workflow, consumer, release, or deployment change is authorized or present.

## Selected direction

- The capability is repository-agnostic: generic sealed repository inputs work
  without meAndAI, meAndAI adds explicit protocol semantics, and consumers may
  add only closed declarative discovery profiles.
- The Repository Knowledge Catalog is a navigation graph and remains separate
  from the [FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md)
  governance Rule Catalog and its applicability/verdict authority.
- `CatalogSnapshot` JSON is the deterministic portable canonical catalog
  output. Repository/Markdown/Git/provider objects remain their underlying
  sources of truth.
- SQLite is a disposable query projection that must be deletable and rebuildable
  from a compatible snapshot.
- The UI is React. Razor Pages, Blazor, MVC views, and server-rendered HTML are
  excluded. A thin read-only ASP.NET Core host may serve typed query endpoints
  and built assets; React owns no discovery, provider, database, or protocol
  semantics.
- Git/provider acquisition, pagination, completeness, trust, redaction, and
  immutable managed integration remain owned by
  [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
- Consumer adoption, update, and finalization remain owned by
  [FEAT-0061](../../../docs/features/FEAT-0061-consumer-adoption-cli/README.md),
  [FEAT-0062](../../../docs/features/FEAT-0062-consumer-protocol-update-cli/README.md),
  and [FEAT-0068](../../../docs/features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md).

## Reserved delivery graph

- [SUBF-0165](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#subf-0165):
  contracts and generic sealed-input projection.
- [SUBF-0166](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#subf-0166):
  meAndAI semantics and declarative consumer profiles.
- [SUBF-0167](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#subf-0167):
  canonical JSON, SQLite, and bounded query.
- [SUBF-0168](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#subf-0168):
  thin ASP.NET Core API and React explorer.
- [SUBF-0169](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#subf-0169):
  provider enrichment and immutable consumer distribution.
- The eight numbered scenarios in the canonical
  [test plan](../../../docs/features/FEAT-0071-repository-knowledge-catalog/test-cases.md)
  are `PlannedDocumentation`; they have no executable or passing evidence.
- The eight numbered risks in the canonical
  [feature record](../../../docs/features/FEAT-0071-repository-knowledge-catalog/README.md#risks)
  define the initial authority, projection, inference, acquisition, hostile-input,
  profile, React, and privilege concerns.

The identifiers allocated by
[open draft PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) remain
reserved. Reconcile both drafts against current `main` before either later plan
exits draft status.

## Continuation boundary

Do not start implementation from this memory entry. First re-read the current
feature, decision, architecture, active repository memory, and dependencies;
reconcile open allocations; accept or revise the decision; close the selected
slice's Definition of Ready and exact expected-red plan; then obtain a separate
maintainer directive naming exactly one implementation slice and mutation
authority.
