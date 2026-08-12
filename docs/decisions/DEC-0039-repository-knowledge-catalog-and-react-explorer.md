# DEC-0039 - Add a Repository Knowledge Catalog with a React Explorer

- Classification: Decision
- Status: Proposed; implementation authority withheld
- Date: 2026-08-12
- Decision owners: Maintainer and meAndAI architecture owner
- Owning feature: [FEAT-0071](../features/FEAT-0071-repository-knowledge-catalog/README.md)
- Tracking issue: [#182](https://github.com/hasanmanzak/meAndAI/issues/182)
- Full architecture: [Repository Knowledge Catalog](../architecture/repository-knowledge-catalog/README.md)
- Related decisions: [DEC-0001](DEC-0001-portable-protocol-reference.md), [DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md), [DEC-0030](DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md), and [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md)

## Context

Repository knowledge is useful to humans and agents only when they can locate
the underlying artifact, understand explicit relationships, and see whether the
available evidence is exact, incomplete, stale, or ambiguous. Today that
knowledge is spread across files, Markdown records, Git identity, issues, pull
requests, reviews, comments, workflows, releases, and other provider objects.

A repository-specific navigation application would solve only meAndAI's local
problem. Copying such an application into consumers would violate the upstream
ownership and non-duplication model. Treating a local SQLite database as
canonical would also create a second, silently stale source of truth.

The term "catalog" is already used in the executable governance architecture
for the Rule Catalog. A repository navigation catalog therefore needs an
explicitly different authority boundary. It may expose where a rule record is
located and how it is linked, but it must not decide rule applicability,
evaluation, conformance, enforcement, or mutation.

## Decision

### 1. Product boundary

Add an optional, repository-agnostic **Repository Knowledge Catalog** capability
to the meAndAI protocol product. It discovers and relates repository/provider
artifacts for navigation and query. It is not required for governance,
adoption, update, execution, or release authority.

The Repository Knowledge Catalog and the governance Rule Catalog remain
separate contracts, namespaces, APIs, evidence, tests, and UI concepts.
[FEAT-0065](../features/FEAT-0065-shared-executable-conformance-runtime/README.md)
continues to own the Rule Catalog and all conformance semantics.

### 2. Canonical output and projections

The catalog engine returns a versioned deterministic `CatalogSnapshot` for
explicitly declared acquisition inputs, discovery profile, and contract
version. Its portable canonical serialization is JSON.

The snapshot contains typed entities, relations, locations, provenance,
acquisition state, diagnostics, profile identity, and exact source identities.
It never replaces the canonical repository, Git, Markdown, or provider objects
from which those facts came.

SQLite is a derived, disposable query projection. It must be deletable and
rebuildable from one compatible snapshot with equivalent bounded query results.
SQLite schema state, full-text indexes, timestamps, and internal row identities
cannot create or override catalog facts.

### 3. Discovery levels

Discovery is layered without making meAndAI a prerequisite:

1. **Generic repository discovery** projects safe, conservative file,
   directory, supported Markdown, Git identity, and location facts supplied by
   a sealed acquisition input. It does not perform Git/filesystem acquisition.
2. **meAndAI semantic discovery** recognizes explicit protocol record identity
   and relations from supported structures.
3. **Consumer discovery profiles** add project-specific path families, record
   types, labels, and relations through a closed, versioned declarative schema.

Profiles cannot execute code, load plugins, embed arbitrary expressions, copy a
common parser, redefine common semantics, or convert uncertain inference into
explicit authority. Reusable behavior belongs upstream under
[DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md).

### 4. Implementation and dependency direction

New executable discovery, domain, canonicalization, projection, query, and
provider-composition behavior is C#, consistent with
[DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md).
Dependencies point inward from adapters and hosts to application use cases and
typed catalog contracts.

The headless engine remains independently usable without a web host. A thin
ASP.NET Core query host may expose typed read-only JSON endpoints and serve the
built client assets. It owns no discovery rule, relation inference, provider
acquisition, governance decision, or mutation authority.

### 5. React presentation

The explorer UI is React. Razor Pages, Blazor, MVC views, and server-rendered
HTML are not part of this design.

React consumes only the versioned read-only query contract. It cannot read the
repository, invoke Git/provider acquisition, access SQLite directly, invent
entities or relations, interpret completeness as absence, or implement
protocol/governance semantics. Search, filters, entity detail, relationship
navigation, provenance, diagnostics, and source navigation are presentation of
server-provided catalog facts.

The exact React build tooling, component library, styling system, and client
state/query library remain Gate 2 selections. Those implementation choices may
not change the React-only presentation decision or move domain authority into
the client.

### 6. Acquisition and completeness

The catalog does not implement a second Git/GitHub crawler. Exact Git/provider
identity, event trust, pagination, convergence, freshness, rate limits,
credential behavior, redaction, and completeness remain owned by
[FEAT-0067](../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).

The catalog consumes sealed acquisition envelopes and preserves their state.
Complete, partial, stale, rate-limited, unsupported, non-convergent, redacted,
and failed evidence remain distinguishable. Unknown or unavailable cannot be
rendered as confirmed absence.

Provider-free catalog projection is a supported mode when a caller supplies a
sealed local `RepositoryInput`. The production local acquisition adapter and
optional GitHub enrichment both remain common
[FEAT-0067](../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
responsibilities and may be composed only after that contract is accepted and
available.

### 7. Identity, inference, and compatibility

Every entity and relation carries stable catalog identity, kind, source
location, source identity, discovery method, provenance, and acquisition
state. Relations distinguish `Explicit`, `Inferred`, and `Unresolved` methods.
Inference is conservative and cannot create normative authority.

Snapshot, profile, query, and projection contracts are independently versioned.
Unknown required versions, kinds, or semantics fail explicitly. Additive
compatibility is allowed only where the consuming contract declares it. Stable
source identities and content-derived catalog identities must not depend on
traversal order, wall-clock time, machine-specific absolute paths, or SQLite row
allocation.

### 8. Read-only and hostile-input boundary

Initial catalog operation is read-only. Discovery does not execute repository
code, scripts, hooks, generators, templates, configuration expressions, or
consumer plugins. It does not follow paths outside the acquired root or expose
secret-bearing/binary content by default. File size, count, depth, parse,
relation, query, response, time, memory, and cancellation behavior must be
bounded before implementation is authorized.

The optional query host has no provider publication, repository mutation,
governance enforcement, or release grant. The five governance/execution hosts
accepted by
[DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md)
remain unchanged. The catalog introduces a separate optional non-governance
read-only host plus React assets; their host, API, client, and schema digests
must be bound in the immutable release manifest before distribution.

### 9. Distribution and consumer adoption

The capability is published through one immutable protocol-owned distribution.
A consumer keeps its pinned protocol reference, catalog configuration/profile,
and project-specific semantic evidence. It invokes shared catalog behavior and
does not copy or reimplement the discovery engine, SQLite projection, query API,
React explorer, fixtures, or qualification tests.

Consumer adoption/update planning may reference the capability through
[FEAT-0061](../features/FEAT-0061-consumer-adoption-cli/README.md) and
[FEAT-0062](../features/FEAT-0062-consumer-protocol-update-cli/README.md) after
its own release and readiness gates are satisfied; release closure remains with
[FEAT-0068](../features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md).
This decision does not add another adoption/update/finalization path, authorize
a consumer mutation, or make catalog adoption mandatory.

## Consequences

- meAndAI can provide a common navigation capability without making its local
  record layout a prerequisite for generic repositories.
- Headless snapshot output becomes the primary contract; database and UI work
  cannot hide nondeterministic or incomplete discovery.
- React can evolve as a product surface while C# remains the protocol-owned
  semantic and projection authority.
- GitHub completeness and trust behavior has one owner, avoiding a second
  subtly different provider implementation.
- The design introduces new versioned contracts, security bounds, database
  projection evidence, and frontend/API qualification work. These must be
  completed slice by slice before release.

## Alternatives considered

- **A meAndAI-only catalog application:** rejects consumer reuse and encourages
  project-specific forks.
- **SQLite as the canonical store:** creates stale dual authority and weakens
  reproducibility.
- **A React application that parses repositories directly:** duplicates C#
  semantics, expands browser privilege, and prevents headless parity.
- **Razor Pages, Blazor, MVC views, or server-rendered HTML:** contradicts the
  selected React presentation boundary.
- **Executable consumer plugins or arbitrary profile expressions:** execute
  untrusted behavior and create shadow protocol implementations.
- **A catalog-owned GitHub crawler:** duplicates
  [FEAT-0067](../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  pagination, completeness, trust, and credential contracts.
- **A remote multi-tenant service as the first delivery:** adds identity,
  tenancy, persistence, credential, and operations scope before the local
  canonical contract is proven.

## Implementation authority

This proposed decision and its records-only feature packet do not authorize
code, dependencies, tests, workflows, consumers, releases, or deployment.
Implementation requires decision acceptance, selection of one ready subfeature,
expected-red evidence, review of the exact mutation boundary, and a separate
maintainer directive.

## Review condition

Review this decision if any proposal would:

- merge the Repository Knowledge Catalog with the governance Rule Catalog;
- make SQLite or React authoritative;
- move discovery/query semantics outside C#;
- replace React with Razor Pages, Blazor, MVC views, or server rendering;
- introduce executable consumer extensions;
- duplicate [FEAT-0067](../features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  acquisition behavior;
- add mutation/publication/enforcement authority or make the explorer required;
- introduce a remote/multi-tenant persistence or credential boundary; or
- change immutable distribution or consumer non-duplication rules.
