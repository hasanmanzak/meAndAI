# [FEAT-0060](README.md) Differential Ledger Inventory Analysis

Status: records-only inventory complete at scenario level; executable
development and authority transfer are not authorized.

This record fixes the finite starting universe for [TEST-0196](test-cases.md#test-0196)
without pretending that the existing PowerShell suites expose a complete
machine-readable variant manifest. The identity authority remains
[tests/scenario-ownership.psd1](../../../tests/scenario-ownership.psd1); this
analysis is not a second scenario registry.

## Frozen baseline and counts

The inclusion predicate is every identity at immutable protocol `0.16.0`
commit
[`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd)
whose evidence kind is neither `PlannedDocumentation` nor
`HistoricalSuperseded`.

| Inventory unit | Count | State |
| --- | ---: | --- |
| Manifest identities | 206 | Exact |
| Historical/superseded identities | 5 | Excluded by predicate |
| Planned documentation identities | 13 | Excluded by predicate |
| Active base identities | 188 | Exact, 188/188 inventoried (100%) |
| Explicit `ParameterizedVariant` declaration packets | 7 across 6 unique TEST identities | Exact, 7/7 inventoried (100%) |
| Declaration-level units | 195 | Exact; `188 + 7` |
| Proven named source cases | 107 | Lower bound; `7 + 100` |
| Proven TEST/case mappings | 116 | Exact lower bound; nine shared cases map to two TEST identities |
| Conditional base-plus-mapping units | 304 | Planning arithmetic only; `188 + 116` if the accepted schema retains a base row beside expanded mappings |

The denominator for all concrete variants is not currently knowable. Several
suites iterate inline or generated matrices and record only one TEST
completion, while no central schema assigns stable keys to their material
oracle branches. The 188 base identities and 116 proven mappings are separate
facts. Their sum, 304, becomes a row count only if the maintainer accepts a
schema that retains a base row beside expanded mappings; it is not currently a
ledger-size claim or progress denominator.

## Explicit declaration packets

| Feature record | TEST identity | Expansion evidence |
| --- | --- | --- |
| [FEAT-0054](../FEAT-0054-v0153-bounded-quick-adoption-runtime/test-cases.md) | [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107) | Seven named version cases |
| [FEAT-0055](../FEAT-0055-v0154-utf8-workflow-dispatch/test-cases.md) | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) | Graph-aware/unaware and PS5.1/PS7 transport variants; cardinality not normalized |
| [FEAT-0056](../FEAT-0056-v0155-instruction-graph-resilience/test-cases.md) | [TEST-0151](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) | Grammar and authority variants; cardinality not normalized |
| [FEAT-0056](../FEAT-0056-v0155-instruction-graph-resilience/test-cases.md) | [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) | Target/path/decode variants; cardinality not normalized |
| [FEAT-0056](../FEAT-0056-v0155-instruction-graph-resilience/test-cases.md) | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) | Immutable graph-profile and dispatch variants; cardinality not normalized |
| [FEAT-0056](../FEAT-0056-v0155-instruction-graph-resilience/test-cases.md) | [TEST-0161](../FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) | Process, clock, fault, and capacity variants; cardinality not normalized |
| [FEAT-0058](../FEAT-0058-v0156-completed-historical-adoption-issues/test-cases.md) | [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) | 100 cases with an exact bounded inventory |

[TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
appears in two packets because two later features extend the same canonical
identity. [TEST-0190](../FEAT-0053-v0152-distinct-test-intent/test-cases.md#test-0190)
tests classification behavior containing the term `ParameterizedVariant`; it
is not itself a variant declaration.

The proven lower bound expands as follows:

- [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
  contributes seven named source cases.
- [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069)
  contributes 100 source cases: nine marker, 56
  historical-contract, two snapshot, two inventory-bound, four
  invalid-inventory, 23 registry-tag, and four full-launcher cases.
- The nine marker cases are also canonical evidence for
  [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176),
  so one source case produces two TEST/case mappings for those cases.

## Scenario-level planned-route inventory

These routes describe analysis intent only. They are not evidenced
dispositions and cannot move authority.

| Planned route | Count | Meaning |
| --- | ---: | --- |
| `CSharpCandidate` | 43 | Pure or technology-neutral governance contract appears eligible for later C# evidence |
| `MixedBoundary` | 16 | One TEST currently combines transferable validation with operational, infrastructure, or provider behavior and must be split by material variant |
| `PowerShellOperationalRetained` | 94 | Adoption, update, finalization, recovery, or other mutation/process behavior remains outside [FEAT-0060](README.md) |
| `InfrastructureContract` | 29 | Runner, AST, process, transport, sharding, workflow, or fixture contract is not a governance-rule transfer row |
| `ExternalProvider` | 3 | Wholly live or supplied provider evidence remains outside the repository-only v1 engine |
| `ExistingCSharpFoundation` | 3 | Existing compiled foundation/package contracts remain their own evidence |
| **Total** | **188** | Complete, mutually exclusive scenario-level classification |

The scenario-level route classification is unambiguous for 172 of 188
identities (91.5%). The 16 mixed identities are the remaining 8.5% and cannot
receive a single honest disposition until their material variants have stable
keys. Exact, mutually exclusive row membership, profile proposal, canonical
owner, evidence kind, and canonical record are retained in the
[188-row scenario-route analysis](scenario-route-analysis.csv). The CSV is an
auditable analysis projection, not scenario identity authority or the future
evidenced differential ledger.

## Proposed authoritative ledger shape

After maintainer acceptance, one protocol-owned JSON ledger may become the
authoritative TEST/variant mapping. It must reference, not replace, scenario
identity authority. A generated Markdown view may aid review.

Each declaration packet records `expansionState` as `Unexpanded`, `Partial`,
or `Complete` and its proven cardinality. Each concrete row uses a stable
namespaced `variantKey`; a no-variant identity uses `base`. Shared input uses
one `sourceCaseKey` and separate `(testId, variantKey)` mappings.

Required row fields are:

- `testId`, `variantKey`, `rowKind`, `sourceCaseKey`, and
  `canonicalEvidenceKind`;
- `canonicalScenarioOwner`, `canonicalEvidenceOwner`, `canonicalRecordPath`,
  `canonicalVariantSource`, and `contractSourceOwner`;
- `ruleFamily`, `ruleId`, `findingCodes`, and `profileApplicability`;
- `repositorySnapshotMode` and `evidenceSourceKinds`;
- `expectedOracle`, separate PowerShell and C# observed results, and evidence
  links;
- `plannedRoute`, `evidencedDisposition`, `operationalAuthorityState`, and
  `reviewState`; and
- immutable source commit, repository-relative path, stable selector, and
  source digest.

The closed evidenced dispositions remain `CSharpSameContract`,
`ApprovedStrongerEvidence`, `PowerShellOperationalRetained`,
`InfrastructureContract`, and reasoned `NotApplicable`. The reasoned
`NotApplicable` case includes `AlreadyOwnedByCSharpFoundation`; it reuses the
existing compiled evidence without claiming a cross-language transfer.

`canonicalEvidenceOwner` always preserves the current channel or executable
owner, including PowerShell suites, GitHub Actions semantics, external
post-publication evidence, and .NET test projects.
`operationalAuthorityState` is populated only for rows participating in the
governance operational-capability migration; applicable current rows remain
`PowerShellAuthority`. Infrastructure, provider, workflow-semantic, and
existing-foundation rows do not receive a fabricated PowerShell authority
state. During this records-only stage every `evidencedDisposition` remains
empty.

## Decision boundary and progress

The [contract decision packet](contract-decision-packet.md) asks the maintainer
to approve the material-variant granularity and the separation between
planned route, evidenced disposition, canonical evidence owner, and applicable
operational authority. Until that decision, expanding the 16 mixed identities
would invent an authority schema rather than document an
accepted one.

Current conclusive progress is:

- base identity inventory: 188/188, 100%;
- explicit declaration-packet inventory: 7/7, 100%;
- scenario-level route classification: 172/188 unambiguous, 91.5%, with
  16/188 mixed, 8.5%;
- mapping evidence: 188 base identities and a separate lower bound of 116
  TEST/case mappings; 304 is conditional base-plus-mapping arithmetic, not an
  accepted ledger row count;
- Definition of Ready: 8/12, 67%; and
- implementation: 0/7 subfeatures, 0%.

No monotonic start marker was captured for this records-only audit, so its
elapsed duration cannot be reconstructed without guessing. The first
post-decision normalization batch must record elapsed time and observed rows
per hour before publishing a remaining-duration estimate.
