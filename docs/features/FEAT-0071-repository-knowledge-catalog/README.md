# FEAT-0071 - Repository Knowledge Catalog and React Explorer

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed records-only plan; implementation not authorized |
| Target version | 0.21.0 |
| Issue | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) |
| Pull request | [#183](https://github.com/hasanmanzak/meAndAI/pull/183) (draft; records-only) |
| Decision | [DEC-0039](../../decisions/DEC-0039-repository-knowledge-catalog-and-react-explorer.md) |
| Architecture | [Repository Knowledge Catalog](../../architecture/repository-knowledge-catalog/README.md) |
| Tests | [TEST-0234](test-cases.md#test-0234), [TEST-0235](test-cases.md#test-0235), [TEST-0236](test-cases.md#test-0236), [TEST-0237](test-cases.md#test-0237), [TEST-0238](test-cases.md#test-0238), [TEST-0239](test-cases.md#test-0239), [TEST-0240](test-cases.md#test-0240), and [TEST-0241](test-cases.md#test-0241) |

## Planning authority and implementation hold

This record captures the selected product direction, contract questions,
delivery slices, risks, and future evidence obligations. It does not authorize
application scaffolding, package changes, a database, migrations, API or UI
code, test implementation, workflows, consumer changes, release publication,
or deployment. A separate maintainer directive is required after the selected
slice satisfies the Definition of Ready.

The binding presentation decision is a **React** client. Razor Pages, Blazor,
MVC views, and server-rendered HTML are outside the selected design.

The prospective `0.21.0` position preserves the current governance, adoption,
update, and compatibility sequence. It is a planning slot, not a release
commitment; acceptance, implementation, and release authority remain separate.

## Problem

Repository knowledge is distributed across source files, Markdown records,
Git identity, and provider objects such as issues and pull requests. Humans and
agents must repeatedly rediscover where an item lives, which records relate to
it, whether provider evidence is complete, and which link is authoritative.
Project-specific navigation tools would duplicate this work and make consumer
adoption inconsistent.

meAndAI needs an optional, repository-agnostic catalog capability that a
consumer can invoke against its own repository. The capability must discover
what is actually present without turning naming guesses or a local database
into authority.

## Outcome

One protocol-owned C# catalog engine produces a versioned, deterministic
`CatalogSnapshot` from sealed repository and provider acquisition inputs. The snapshot
contains typed entities, relations, locations, acquisition state, provenance,
diagnostics, and the selected discovery profile. JSON is the portable canonical
serialization of that output. SQLite is a disposable, rebuildable query
projection, and a React explorer consumes a thin read-only ASP.NET Core query
API without owning discovery or protocol semantics.

A generic repository works without meAndAI. A repository that adopts meAndAI
gains semantic discovery for protocol records. A consumer may add bounded,
declarative mappings for its own record families without adding executable
plugins or a shadow parser.

## Terminology and authority boundary

- The **Repository Knowledge Catalog** is a navigation and knowledge graph over
  repository/provider artifacts. It does not determine conformance.
- The governance **Rule Catalog** owned by
  [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md)
  contains executable rule specifications, applicability, evaluation, and
  verdict semantics. It is not replaced or reinterpreted here.
- A `CatalogSnapshot` is the canonical output for one exact acquisition input.
  It is not a new source of truth for the underlying artifact.
- Markdown, Git objects, and provider objects remain their own canonical
  sources. SQLite and the React view are projections.
- Explicit relations are distinguished from conservative inferred relations;
  unresolved or ambiguous candidates remain diagnostics rather than invented
  links.

## Scope

- Repository-agnostic semantic projection of sealed file, directory, supported
  Markdown, exact Git identity, and safe metadata acquisition inputs.
- meAndAI-aware semantic discovery of numbered feature, decision, test, risk,
  subfeature, idea, bug, finding, task, and related protocol records where the
  record format provides explicit identity.
- Declarative consumer profiles that map additional path/record families and
  relation rules through a versioned, closed schema.
- A typed entity/relation/location/provenance/diagnostic model and deterministic
  snapshot/JSON compatibility contract.
- SQLite projection, full-text query, deletion/rebuild, schema compatibility,
  and equivalence evidence behind a C# projection boundary.
- Read-only query API and React navigation/search/detail/relationship surfaces.
- Optional issue, pull-request, review, comment, check, workflow, release, and
  label enrichment acquired through the common
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  contract, including completeness, freshness, and failure state.
- Immutable protocol distribution and bounded consumer invocation with no
  copied catalog implementation.

## Non-goals

- Replacing Git, Markdown, GitHub, or another provider as source of truth.
- Conformance evaluation, rule applicability, governance verdicts, SDLC state
  transitions, approval, mutation, publication, or issue/PR write-back.
- Executing repository code, configuration scripts, generators, templates, or
  consumer-supplied plugins during discovery.
- Guessing semantic identity from arbitrary prose, filename resemblance, or
  unverified provider URLs.
- Copying Git/GitHub pagination, convergence, credential, trust, or immutable
  resolution behavior already owned by
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
- Giving React direct filesystem, Git, provider, or SQLite access.
- Razor Pages, Blazor, MVC views, or server-rendered HTML UI.
- Hosting a multi-tenant remote catalog service in the first delivery.
- Replacing the consumer adoption, update, or release-finalization paths owned
  by [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md),
  [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), or
  [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md).
- Implementing any part of the application in this records-only packet.

## Source and projection authority

| Surface | Authority in this feature | Required behavior |
| --- | --- | --- |
| Exact repository content and Git objects | Canonical input | Preserve exact repository/ref/object identity and acquisition state. |
| Markdown identity and links | Canonical only where the source format is explicit | Parse supported structures; retain raw location and diagnostics for malformed or ambiguous input. |
| GitHub/provider objects | Canonical provider input when acquisition is sealed as complete enough for the requested view | Reuse [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md); retain partial, stale, rate-limited, or failed state. |
| `CatalogSnapshot` JSON | Canonical catalog output for the exact declared inputs and contract version | Deterministic ordering, identifiers, provenance, diagnostics, profile digest, and acquisition manifest. |
| SQLite | Derived query projection | Rebuildable from one snapshot; deletion loses no authority; projection/schema mismatch fails explicitly. |
| React explorer | Presentation projection | Read-only rendering and navigation through the query API; no discovery or protocol decision logic. |

## Dependencies and readiness evidence

- [DEC-0039](../../decisions/DEC-0039-repository-knowledge-catalog-and-react-explorer.md)
  records the proposed architecture decision; it is not yet accepted.
- [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
  supplies the C# domain/adapters/host split and least-authority defaults.
- [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) supplies the
  shared C# and portable distribution foundation.
- [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  owns exact Git/provider acquisition, completeness, trust, and managed
  consumer integration. This feature consumes its sealed output and may not
  independently implement that behavior.
- [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md)
  remains the Rule Catalog and conformance authority. Catalog discovery may
  expose navigational references to its records but cannot evaluate them.
- [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md) and
  [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md) own consumer
  lifecycle transitions; [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
  owns release finalization and authority transfer. Catalog distribution and
  invocation must compose through those accepted paths rather than replace them.
- The detailed contract and delivery questions are recorded in the
  [architecture record](../../architecture/repository-knowledge-catalog/README.md).
- Identifier allocation accounts for the still-open allocations in
  [draft PR #181](https://github.com/hasanmanzak/meAndAI/pull/181): the
  immediately preceding feature position, two immediately preceding decision
  positions, five subfeatures, ten tests, and eight risks allocated by that
  draft remain reserved there.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0334` <a name="risk-0334"></a> | The Repository Knowledge Catalog is confused with the governance Rule Catalog and begins producing applicability or verdict authority. | Catalog and conformance owners / separate contracts, namespaces, APIs, UI labels, and [TEST-0235](test-cases.md#test-0235). |
| `RISK-0335` <a name="risk-0335"></a> | A host/order-dependent canonical snapshot, SQLite projection, or stale browser view becomes unstable or a competing source of truth. | Snapshot/projection owner / deterministic canonical payload and ID proof in [TEST-0237](test-cases.md#test-0237), snapshot identity on every projection, delete-and-rebuild proof, explicit stale/mismatch outcomes, and [TEST-0238](test-cases.md#test-0238). |
| `RISK-0336` <a name="risk-0336"></a> | Generic discovery guesses identities or relationships from prose and presents false certainty. | Discovery owner / closed explicit sources, confidence/provenance, unresolved diagnostics, no free-text authority, and [TEST-0234](test-cases.md#test-0234)/[TEST-0235](test-cases.md#test-0235). |
| `RISK-0337` <a name="risk-0337"></a> | Catalog code duplicates provider acquisition or converts partial, stale, rate-limited, or failed evidence into absence. | Integration owner / consume sealed [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) envelopes only and prove state propagation in [TEST-0240](test-cases.md#test-0240). |
| `RISK-0338` <a name="risk-0338"></a> | A hostile repository causes code execution, path escape, excessive resource use, binary/secret exposure, or unsafe link following. | Security owner / read-only acquisition, no plugin/script execution, path and resource bounds, redaction, fail-closed diagnostics, and [TEST-0241](test-cases.md#test-0241). |
| `RISK-0339` <a name="risk-0339"></a> | Consumer profiles become executable plugins or project-specific copies of common parsers. | Profile owner / versioned declarative schema, closed operations, project-neutral fixtures, upstream correction rule, and [TEST-0236](test-cases.md#test-0236). |
| `RISK-0340` <a name="risk-0340"></a> | React accumulates discovery, relation, authority, or database logic and diverges from headless output. | UI owner / typed query contract, server-owned projection/query, headless equivalence, and [TEST-0239](test-cases.md#test-0239). |
| `RISK-0341` <a name="risk-0341"></a> | The optional explorer expands the core five-host privilege model or becomes required for governance. | Architecture owner / optional read-only query host, no publication/mutation grant, explicit dependency direction, and [TEST-0241](test-cases.md#test-0241). |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenario contracts | Defined for planning | [Test scenarios](test-cases.md) |
| Scenario ownership | Planned documentation only | `tests/scenario-ownership.psd1`; no application test code |
| Expected-red fixtures | Not created | Implementation is not authorized |
| Baseline run | Not run | No catalog implementation exists |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0165` <a name="subf-0165"></a> | Versioned catalog contracts and deterministic projection of sealed generic repository/Markdown inputs | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) | [TEST-0234](test-cases.md#test-0234), [TEST-0237](test-cases.md#test-0237) / not started | Pending | Proposed; implementation not authorized |
| `SUBF-0166` <a name="subf-0166"></a> | meAndAI semantic discovery and bounded declarative consumer profiles | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) | [TEST-0235](test-cases.md#test-0235), [TEST-0236](test-cases.md#test-0236) / not started | Pending | Proposed; implementation not authorized |
| `SUBF-0167` <a name="subf-0167"></a> | Canonical JSON snapshot, SQLite projection, full-text query, and rebuild equivalence | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) | [TEST-0237](test-cases.md#test-0237), [TEST-0238](test-cases.md#test-0238) / not started | Pending | Proposed; implementation not authorized |
| `SUBF-0168` <a name="subf-0168"></a> | Thin read-only ASP.NET Core query host and React explorer | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) | [TEST-0239](test-cases.md#test-0239), [TEST-0241](test-cases.md#test-0241) / not started | Pending | Proposed; implementation not authorized |
| `SUBF-0169` <a name="subf-0169"></a> | Common [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) provider enrichment, immutable distribution, and consumer invocation | [#182](https://github.com/hasanmanzak/meAndAI/issues/182) | [TEST-0240](test-cases.md#test-0240), [TEST-0241](test-cases.md#test-0241) / not started | Pending | Proposed; implementation not authorized |

Each slice requires its own Gate 2 review, expected-red evidence, explicit Gate
3 directive, implementation/review cycle, and exact-head evidence. Later slices
may not make an earlier incomplete scenario appear passing.

## Prior art and recurrence boundary

- Applicable recurrence: [noncanonical cross-record links](../../../.ai/memory/project.md#record-synchronization-reintroduces-noncanonical-cross-record-links).
  Every rendered registered stable ID in this packet is wholly linked to its
  canonical record/anchor. Unmerged reserved IDs are deliberately not rendered;
  [draft PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) is linked
  descriptively as allocation evidence. The records-only packet requires the
  clickable-link structural coverage owned by
  [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
  through the committed-tree `StructureOnly` entry point.
- Applicable recurrence: [planned multi-slice scenario asserted before final activation](../../../.ai/memory/project.md#planned-multi-slice-scenario-is-asserted-before-final-activation).
  All eight new scenarios remain `PlannedDocumentation`, have one documentation
  owner, and must not appear in executable test sources or a `Scenario` trait
  until their exact owning slice is activated.
- Same-contract sibling inventory: each row in the
  [test plan](test-cases.md) names the nearest sibling, relationship disposition,
  and distinct contract/risk/evidence-level/exercised-boundary tuple.
- Failed catalog route: `None`; no catalog application or prior catalog
  implementation exists to treat as evidence.
- Future executable barrier: implementation requires an accepted decision, one
  exact ready slice, expected-red evidence, and a separate directive. This
  records-only packet cannot satisfy that barrier.

## Proposed delivery sequence

1. Accept or revise [DEC-0039](../../decisions/DEC-0039-repository-knowledge-catalog-and-react-explorer.md)
   and close the open contract questions without starting code.
2. Qualify [SUBF-0165](#subf-0165) as a headless generic projection over a
   caller-supplied, sealed, project-neutral `RepositoryInput`; the catalog
   performs no local Git/filesystem acquisition. The production acquisition
   route remains dependent on
   [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
3. Add [SUBF-0166](#subf-0166) semantic discovery without weakening generic
   behavior or adding executable consumer extensions.
4. Add [SUBF-0167](#subf-0167) only after the canonical snapshot contract is
   stable; prove SQLite can be deleted and rebuilt from it.
5. Add [SUBF-0168](#subf-0168) as a React client over the same headless query
   contract. UI delivery cannot redefine catalog semantics.
6. Add [SUBF-0169](#subf-0169) only from the accepted
   [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
   acquisition envelope and immutable distribution path.

## Definition of Ready

- [x] Stable feature, subfeature, test, and risk IDs are reserved with a linked
  issue and conflict accounting for open draft allocations.
- [x] Problem, outcome, scope, non-goals, source/projection authority, risks,
  tests, decomposition, and delivery sequence are reviewable.
- [x] React is selected as the UI; Razor Pages and Blazor are excluded.
- [x] SQLite is a rebuildable projection; `CatalogSnapshot` JSON is the
  portable canonical catalog output.
- [x] The knowledge catalog is separated from the
  [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md)
  Rule Catalog and provider acquisition is delegated to
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
- [ ] [DEC-0039](../../decisions/DEC-0039-repository-knowledge-catalog-and-react-explorer.md)
  is accepted after architecture, security, and dependency-boundary review.
- [ ] The selected first slice freezes entity, relation, location, provenance,
  diagnostic, identity, ordering, nullability, error, and compatibility
  contracts with exact examples.
- [ ] Generic Markdown support, binary/encoding/link/path/resource limits, and
  the first declarative profile schema are bounded.
- [ ] Snapshot canonicalization, JSON schema/versioning, SQLite schema/migration
  policy, query limits, and FTS capability/fallback behavior are frozen.
- [ ] The thin API and React route/component/accessibility/performance contract
  is reviewed without adding UI-owned semantics.
- [ ] Project-neutral expected-red fixtures and exact scenario-owner paths are
  approved for the selected slice.
- [ ] Dependency/release ordering with active
  [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md),
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md),
  and [draft PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) is
  reconciled against current `main`.
- [ ] A separate maintainer implementation directive names exactly one ready
  slice and its mutation authority.

## Acceptance criteria

1. The same declared repository inputs, profile, acquisition envelopes, and
   contract version produce byte-stable canonical JSON across supported hosts.
2. A generic repository is useful without meAndAI; meAndAI and consumer
   profiles only add explicit semantics and cannot reinterpret generic facts.
3. Every entity and relation carries source location, provenance, discovery
   method, and acquisition state; ambiguity remains explicit.
4. SQLite can be deleted and rebuilt from one compatible snapshot with
   equivalent bounded query results; it never becomes canonical evidence.
5. React provides search, filtering, entity detail, relationships, provenance,
   diagnostics, and source navigation only through the read-only query API.
6. GitHub/provider enrichment reuses [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
   and preserves complete, partial, stale, rate-limited, unsupported, and
   failed states without interpreting missing data as absence.
7. Discovery never executes untrusted repository content, follows unsafe paths,
   exposes secrets by default, or mutates repository/provider state.
8. A consumer invokes one immutable shared distribution plus its declarative
   profile; it does not copy common discovery, projection, API, UI, or tests.
9. The catalog remains optional and cannot grant, publish, or alter governance
   authority.

## Records-only self-review and convergence

The initial bounded review covered protocol/API boundaries, semantic contracts,
planned-test intent, documentation/index/link consistency, security assumptions,
dependency ownership, and repository hygiene. Source code, runtime behavior,
build output, application tests, package/dependency changes, and migrations are
not applicable because this packet implements none of them.

Independent review corrected several planning defects before delivery: generic
discovery now consumes a sealed input instead of ambiguously owning acquisition;
each planned scenario records the complete distinct-intent disposition; consumer
distribution depends on the existing adoption/update/finalization owners; and
canonical output, completeness scope, optional-host privilege, and cross-record
links are explicit. A confirmation structural scan is required after the
records-only commit. Open Gate 2 questions and the unresolved dependency/order
with active work are intentional readiness gaps, not passing evidence.

## Definition of Done

All future implementation-slice expected-red, code self-review, exact-head test,
hosted integration, consumer fixture, immutable release, adoption, final product
documentation, and external evidence gates remain pending. This reviewed
records-only packet does not claim any product behavior or feature delivery
completion.
