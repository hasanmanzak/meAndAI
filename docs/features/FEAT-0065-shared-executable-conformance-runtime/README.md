# FEAT-0065 - Shared Executable Conformance Runtime

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0152](#subf-0152) complete; [SUBF-0153](#subf-0153) Gate 2 accepted/merged/exact-main validated; [SUBF-0143](#subf-0143) Gate 2 design candidate active; implementation not authorized |
| Target version | 0.17.0 |
| Issue | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Pull request | Completed [SUBF-0152](#subf-0152): [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170); accepted [SUBF-0153](#subf-0153) design: [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171); active [SUBF-0143](#subf-0143) design remains governed by [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), partially superseded [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) |
| Tests | [TEST-0209](test-cases.md#test-0209), [TEST-0210](test-cases.md#test-0210), [TEST-0211](test-cases.md#test-0211), [TEST-0220](test-cases.md#test-0220), [TEST-0221](test-cases.md#test-0221), and [TEST-0222](test-cases.md#test-0222) |

## Scoped directives

This record owns boundary 1 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
The maintainer's 2026-07-29
[implementation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
and narrow [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
[infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847)
authorized only [SUBF-0152](#subf-0152). [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170)
merged that implementation at exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
whose [exact-main run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506)
passed both stable jobs.

The 2026-07-30 historical
[SUBF-0153](#subf-0153)
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
produced the accepted
[evidence-contract design](subf-0153-evidence-contract-design.md).
[PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) merged that packet at
exact main
[`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f),
and its [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520)
records bounded exact-main validation. That consumed design authority did not
authorize implementation.

The current
[SUBF-0143](#subf-0143)
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584)
authorizes only Gate 1/2 design and expected-red planning for
[SUBF-0143](#subf-0143)/[TEST-0210](test-cases.md#test-0210). Its
[typed-evaluation-kernel design](subf-0143-typed-evaluation-kernel-design.md)
is a review candidate. Production code, executable tests, Gate 3,
project/package/lock/solution files, workflows, scenario ownership,
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), WIP
extraction, provider or consumer mutation, publication, release, authority
transfer, and PowerShell retirement remain unauthorized. Maintainer acceptance,
merge of the accepted [SUBF-0143](#subf-0143) packet, bounded exact-main validation, and a
separate implementation directive are required before Gate 3.

## Problem

Common governance requirements currently appear through protocol prose,
PowerShell validation, fixtures, and delivery-specific GitHub verification.
A consumer cannot reliably execute the same versioned semantics without
copying or reinterpreting those assets, and meAndAI must not certify itself
through a separate private validator.

## Outcome

One protocol-owned C# conformance runtime evaluates the same stable rules for
meAndAI and every consumer against typed acquired evidence. It produces
deterministic, machine-readable results without repository, provider,
publication, or authority-transfer capabilities.

## Scope

- Protocol domain types for rule, evidence, location, profile, applicability,
  evaluation, conformance, enforcement, debt, waiver, and report identities.
- Immutable baseline catalog descriptors bound to exact normative fragments
  and compiled C# evaluators.
- Parse/acquire-once indexes and rule evaluation over repository, document,
  provider, workflow, release, and lifecycle evidence supplied through ports.
- Deterministic aggregation, canonical serialization, digests, redaction, and
  fail-closed missing or unmapped rule inventory.
- Protected baseline plus namespaced extension, waiver, and historical-debt
  semantics without consumer weakening.
- Upstream qualification fixtures, first-rule matrix, and predecessor-trusted
  self-consumption evaluation.

## Non-goals

- Git, GitHub, filesystem, network, release-registry, or workflow acquisition.
- Repository or provider mutation, result publication, release publication, or
  authority transfer.
- CLI grammar or exit codes as domain contracts.
- Arbitrary executable consumer plugins.
- Treating the initial five [RULE identities](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#5-first-rulespecificationqualificationevidence-matrix)
  as the complete protocol catalog.

## Readiness evidence

- Dependency: completed [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md).
- Integration contracts: evidence adapters and hosts belong to
  [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md);
  durable extension activation and grants belong to
  [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md).
- Initial rules: the accepted
  [rule/specification/qualification/evidence matrix](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#5-first-rulespecificationqualificationevidence-matrix)
  covers feature/decision documents, links, anchors, and exact commit evidence
  across repository and provider surfaces.
- WIP input: the exact
  [extraction ledger](../../architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
  classifies reusable evaluator, catalog, parser, identity, and report seeds.
- Prior-art state: the [preserved WIP host scenario](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0194)
  and [preserved WIP model scenario](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195)
  are historical WIP evidence only.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0300` <a name="risk-0300"></a> | An incomplete catalog or missing evidence silently yields a conforming result. | Conformance owner / complete inventory binding, explicit acquisition/execution dimensions, and fail-closed missing or unmapped rules. |
| `RISK-0301` <a name="risk-0301"></a> | A profile, extension, waiver, or self-consumption route weakens the protected baseline. | Policy owner / independent semantic axes, namespaced additive extensions, typed bounded waivers, predecessor-trusted execution, and deterministic enforcement truth tables. |
| `RISK-0308` <a name="risk-0308"></a> | Open evidence vocabulary is interpreted by the wrong owner and becomes a consumer fork or unqualified adapter contract. | Catalog/[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) owners / strict namespaced syntax plus separate catalog, adapter/source, payload-schema, acquisition-failure, and later evaluation-code ownership. |
| `RISK-0309` <a name="risk-0309"></a> | Missing, partial, stale, weakly consistent, redacted, or failed evidence is constructed as complete and permits false satisfaction. | Evidence/kernel owners / requirement-scoped derived status, exact context/result union, and later catalog-bound RuleEvaluationInput closure. |
| `RISK-0310` <a name="risk-0310"></a> | A bare path/string location makes repository, issue, PR, release, document-anchor, and snapshot findings ambiguous or unsafe. | Domain owner / closed EvidenceScope-bound location family and context-minted references. |
| `RISK-0311` <a name="risk-0311"></a> | Later [TEST-0221](test-cases.md#test-0221)/[TEST-0210](test-cases.md#test-0210) ownership weakens predecessor API barriers or hides an additional Conformance.Tests testhost under the near-exhausted Windows budget. | Test/infrastructure owners / list-derived predecessor presence/shape plus new exact export ownership, one restore/test invocation per stable job, per-project count reconciliation, exact-count [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), lock-hash oracle, unchanged timeout, and stop-for-review on exact-head budget failure. |
| `RISK-0312` <a name="risk-0312"></a> | Metadata-only evidence cannot evaluate documents, issues, PRs, comments, or file trees, while a generic object/DTO surface permits unsafe execution. | Domain/SUBF-0143 owners / schema-identified bytes asserted canonical by an untrusted carrier, then [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification and one release-bound generic typed-model context with two-tier parse/index semantics. |
| `RISK-0313` <a name="risk-0313"></a> | Subject, source, requested target, observed boundary, and evidence location can be recombined across repositories or snapshots. | Domain/[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) owners / explicit target-boundary EvidenceScope on every location and binding, plus kind-specific exact identities. |
| `RISK-0314` <a name="risk-0314"></a> | A caller combines one location with unrelated payload bytes or invents a reference/evaluation closure. | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)/Domain/kernel owners / untrusted structural carriers, qualified payload/location coherence, context-minted root references, typed-context derived references, and evaluation records deferred to the catalog-bound kernel. |
| `RISK-0315` <a name="risk-0315"></a> | A one-shot evaluation plan must predict commit/tag/captured-file targets before governed-reference indexing, or a provider route silently mixes external repository owners under one request. | [SUBF-0143](#subf-0143)/[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) owners / topological repository-target demand projection, zero-to-N evaluation rounds, owner-sharded instructions, exact demand/instruction digests, and one route/proof candidate per instruction. |
| `RISK-0316` <a name="risk-0316"></a> | Application-owned decoding, provider-shaped payloads, or scalar-only resource counts fork the release-bound semantic implementation and make qualification/cache results nondeterministic. | [SUBF-0143](#subf-0143) owner / protocol-owned persistent binary wire schemas, a plan-bound Conformance qualification/cache session, six manifest-bound typed registration lists, and exact byte/depth/node/complexity usage on every producer result. |

## Gate 2 findings

Independent red-team labels `BRT-0143-01` through `BRT-0143-13` map one-to-one
and in order to `FIND-0401` through `FIND-0413`. Later fresh-diff, signature,
parser, lifecycle, and target-resolution reviews are recorded separately as
`FIND-0414` through `FIND-0435`.

| ID | Observation | Disposition |
| --- | --- | --- |
| `FIND-0365` <a name="find-0365"></a> | [SUBF-0142](#subf-0142) and [TEST-0209](test-cases.md#test-0209) mixed scalar, evidence, report, serialization, and debt/waiver contracts. | `Blocking`, resolved in design by [SUBF-0152](#subf-0152)/[TEST-0220](test-cases.md#test-0220) and later dependency-closed owners while preserving [TEST-0209](test-cases.md#test-0209) as a true feature-level composed scenario. |
| `FIND-0366` <a name="find-0366"></a> | The stable workflow runs only the Operations solution, so a new protocol test could compile locally yet never execute in hosted validation. | `Blocking`, resolved in design by the exact two-job [execution route](subf-0152-domain-vocabulary-design.md#canonical-execution-route) and explicitly authorized existing [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) infrastructure-contract barrier; executable closure remains part of [SUBF-0152](#subf-0152). |
| `FIND-0367` <a name="find-0367"></a> | The accepted architecture said no RULE IDs were allocated while its accepted successor matrix allocated [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005). | `Blocking`, resolved by the planning correction in the same Gate 2 packet; it grants no evaluator or digest authority. |
| `FIND-0368` <a name="find-0368"></a> | [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005) resolve, but rule-specific fragment selectors, canonical bytes, and exact digests were not ready; [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002) had conflicting required-structure authorities. | `Blocking`, resolved by the [SUBF-0143](#subf-0143) [normative fragment inventory](subf-0143-typed-evaluation-kernel-design.md#initial-normative-fragment-inventory), whole-template RULE-0002 composition, exact fragment/rule digests, and first-rule declaration matrix. |
| `FIND-0369` <a name="find-0369"></a> | The original durable directive and active instruction graph named the mixed [SUBF-0142](#subf-0142)/[TEST-0209](test-cases.md#test-0209) boundary and still withheld every implementation/workflow change. | `Blocking`, resolved by the [corrected scoped directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932), transition gate, successor gate, and project-memory handoff. Only [SUBF-0152](#subf-0152)/[TEST-0220](test-cases.md#test-0220), including its stable-job registration, receives authority. |
| `FIND-0370` <a name="find-0370"></a> | The first Gate 2 draft left public signatures, nullability, collection exposure, and error categories ambiguous while making private/record details test oracles. | `Blocking`, resolved by the [exact public API/error contract and observable-test boundary](subf-0152-domain-vocabulary-design.md#exact-public-api-and-semantic-contract). |
| `FIND-0371` <a name="find-0371"></a> | The mixed-slice supersession map, future dependency edges, and [TEST-0221](test-cases.md#test-0221) same-contract review were incomplete. | `Blocking`, resolved by allocating typed rule/catalog ownership to [SUBF-0143](#subf-0143), making the dependency chain explicit, and recording [TEST-0221](test-cases.md#test-0221) against [TEST-0209](test-cases.md#test-0209) plus preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195). |
| `FIND-0372` <a name="find-0372"></a> | [TEST-0209](test-cases.md#test-0209) described incomplete acquisition and non-conforming verdict as one alternative outcome. | `Blocking`, resolved by preserving acquisition, rule evaluation, conformance, and enforcement as four separate dimensions with accepted precedence. |
| `FIND-0373` <a name="find-0373"></a> | Future [TEST-0221](test-cases.md#test-0221) wording could make evidence absence look like a fourth acquisition status. | `ExternalOrLegacyFollowUp`: planning retains absence as an input fact that is `Incomplete`, distinct from an attempted source yielding `Failed`; exact context/result-union semantics are now owned by [SUBF-0153](#subf-0153) and did not block [SUBF-0152](#subf-0152). |
| `FIND-0374` <a name="find-0374"></a> | Extensible vocabulary had collapsed semantic ownership. | `Blocking`, resolved by strict namespaced syntax and separate catalog, adapter/source, payload-schema, acquisition-failure, and future evaluation-code owners. |
| `FIND-0375` <a name="find-0375"></a> | Missing input and source failure were not representable without a fourth state. | `Blocking`, resolved by the closed observed/absent/failed [result union](subf-0153-evidence-contract-design.md#evidence-context-and-closed-acquisition-result); Failed has no valid context. |
| `FIND-0376` <a name="find-0376"></a> | Repository-only path/line/anchor prior art cannot locate provider, release, or snapshot evidence safely. | `Blocking`, resolved by the closed [EvidenceScope-bound location family](subf-0153-evidence-contract-design.md#typed-location-family). |
| `FIND-0377` <a name="find-0377"></a> | Completeness, consistency, redaction, failure, timestamps, object counts, and pagination lacked one fail-closed graph. | `Blocking`, resolved by RequirementAcquisition, EvidenceContext, long source-object counts, and caller-independent status. |
| `FIND-0378` <a name="find-0378"></a> | A premature Domain RuleEvaluation could accept caller-provided closure and false satisfaction. | `Blocking`, resolved by removing finding/evaluation records from SUBF-0153 and making their exact [sealed-kernel obligations](subf-0153-evidence-contract-design.md#sealed-typed-evaluation-boundary) part of SUBF-0143/[TEST-0210](test-cases.md#test-0210). |
| `FIND-0379` <a name="find-0379"></a> | [TEST-0220](test-cases.md#test-0220) owns the predecessor Domain export inventory. | `Blocking`, resolved by [inventory-derived cumulative ownership](subf-0153-evidence-contract-design.md#cumulative-public-api-ownership-transition), not handwritten counts. |
| `FIND-0380` <a name="find-0380"></a> | Preserved WIP mixes reusable ideas with repository-only evidence, reports, parsers, hosts, and CLI contracts. | `Blocking`, resolved by exact successor-owner [WIP dispositions](subf-0153-evidence-contract-design.md#prior-art-and-wip-disposition); no source or passing state is inherited. |
| `FIND-0381` <a name="find-0381"></a> | Records called SUBF-0152 local/pending after exact-main completion. | `Blocking`, resolved by reconciling [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170), exact commit [`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da), and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506). |
| `FIND-0382` <a name="find-0382"></a> | A separate [TEST-0221](test-cases.md#test-0221) workflow test invocation exceeds the tight Windows budget and duplicates discovery. | `Blocking`, resolved for the [SUBF-0153](#subf-0153)-only route by one protocol test CLI invocation using the existing Domain.Tests testhost, exact-count [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), scoped lock hashes, and the exact [budget job](https://github.com/hasanmanzak/meAndAI/actions/runs/30490879521/job/90708165290). A later accepted [TEST-0210](test-cases.md#test-0210) transition may add one Conformance.Tests testhost without adding another workflow test invocation. |
| `FIND-0383` <a name="find-0383"></a> | Lifecycle prose had replaced canonical scenario states. | `Blocking`, resolved by retaining [TEST-0220](test-cases.md#test-0220) `Passing` and [TEST-0221](test-cases.md#test-0221) `Planned` until atomic authorized activation. |
| `FIND-0384` <a name="find-0384"></a> | The first SUBF-0153 draft carried provenance metadata but no document/issue/PR/comment/file-tree content. | `Blocking`, resolved by schema-identified, defensively copied payload bytes and a mandatory release-bound qualification/typed-model handoff. |
| `FIND-0385` <a name="find-0385"></a> | Request subject/source, snapshot authority, and location identity were independently constructible. | `Blocking`, resolved by requested target, observed boundary, exact EvidenceScope, and scope-owned locations/bindings. |
| `FIND-0386` <a name="find-0386"></a> | Bare location/digest values and public Domain construction could be mistaken for verified evidence authority. | `Blocking`, resolved by context-minted structural root references, explicit untrusted-carrier semantics, [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) payload/location qualification, and SUBF-0143 parser-derived references. |
| `FIND-0387` <a name="find-0387"></a> | Global redaction, nullable failure scope, and “valid failure envelope” semantics were ambiguous. | `Blocking`, resolved by requirement-scoped redaction/failure and the closed result union. |
| `FIND-0388` <a name="find-0388"></a> | Location equality, version grammar, UTF-16 validity, page counts, and cursor uniqueness had contradictory edges. | `Blocking`, resolved by concrete base equality, explicit version/UTF-16 rules, long checked counts, non-paged semantics, and adjacent-transition uniqueness. |
| `FIND-0389` <a name="find-0389"></a> | The live directive requires design review, merge, exact-main validation, then a separate implementation directive. | `Blocking`, resolved by making that chain an unchecked DoR/continuation gate. |
| `FIND-0390` <a name="find-0390"></a> | The expected-red route could run StructureOnly on an intentionally invalid authority tree and [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) could miss duplicate commands or self-register scenario IDs. | `Blocking`, resolved by transient-red prohibition, split IDs, exact-count command assertions, and lock-hash proof. |
| `FIND-0391` <a name="find-0391"></a> | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) [TEST-0214](../FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0214) still uses the superseded “one typed acquisition envelope” terminology after SUBF-0153 selected EvidenceContext plus a closed AcquisitionResult union. | `ExternalOrLegacyFollowUp` owned by [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)/[TEST-0214](../FEAT-0067-evidence-acquisition-managed-consumer-integration/test-cases.md#test-0214) Gate 2; it must consume the accepted result/context contract before implementation, but the current SUBF-0153 design-only directive does not authorize sibling-record mutation. |
| `FIND-0392` <a name="find-0392"></a> | Payload schema, provider/source contracts, and provider ObjectType had overlapping or implicit semantic owners. | `Blocking`, resolved in design by one immutable SUBF-0143 release schema registry and explicit [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) adapter, source-contract, failure-code, and ObjectType registries/contracts. |
| `FIND-0393` <a name="find-0393"></a> | SUBF-0153 implementation could begin before the exact typed evaluation seam was accepted. | `Blocking`, resolved by the gate-level DAG: accepted/merged/exact-main SUBF-0153 Gate 2, then accepted/merged/exact-main SUBF-0143 typed-handoff Gate 2, then a separate directive before SUBF-0153 Gate 3. |
| `FIND-0394` <a name="find-0394"></a> | Content-only parse/index caching, adapter-minted refined references, reference-free empty-inventory findings, and `Complete`-only evaluation readiness could cross locations or manufacture closure. | `Blocking`, resolved in design by separate release/artifact-bound decode and context/location-bound index caches, sealed-context qualified context-proof/derived references, and kernel-derived readiness/applicability/final status. |
| `FIND-0395` <a name="find-0395"></a> | Premature binding/context/manifest digests required an unspecified second canonical serializer and duplicated later report identity. | `Blocking`, resolved by deriving only ContentDigest in SUBF-0153 and assigning report/reference stable keys plus canonical report bytes to SUBF-0154. |
| `FIND-0396` <a name="find-0396"></a> | “Schema-qualified canonical” wording could grant authority to unknown-schema or caller-constructed Domain values. | `Blocking`, resolved by treating all public Domain payload/location/context values as schema-identified assertions until exact release-bound [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) codec, provenance, resource-limit, and semantic-coherence qualification succeeds. |
| `FIND-0397` <a name="find-0397"></a> | Requirement-key partitioning, repeated observations at one location/schema, or a same-digest/different-bytes collision could create ambiguous bindings and leak input order. | `Blocking`, resolved by one pre-unioned binding per location+schema observation, unconditional duplicate-observation rejection, and fail-closed content-identity collision rejection. |
| `FIND-0398` <a name="find-0398"></a> | Observed, Failed, and Absent results could enter the sealed kernel through one vague “qualified result” path, allowing caller-authored absence or unaudited failure. | `Blocking`, resolved in design by [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) observed/failure receipts and kernel-only synthesis of Absent from an expected request slot plus a no-input/no-attempt routing receipt. |
| `FIND-0399` <a name="find-0399"></a> | A single requirement-closure phase could require evaluation-only evidence for a proven-inapplicable rule or turn unresolved applicability into NotApplicable. | `Blocking`, resolved in design by catalog-declared applicability-first closure, conditional evaluation requirements, NotEvaluated on unresolved applicability, and referenced zero-finding/zero-failure NotApplicable. |
| `FIND-0400` <a name="find-0400"></a> | Machine-dependent wall-clock timeout could be memoized as a semantic parser failure and make reports nondeterministic. | `Blocking`, resolved in design by deterministic byte/depth/count/complexity budgets for semantic qualification and operational-only treatment of host timeout/cancellation. |
| `FIND-0401` <a name="find-0401"></a> | The RULE-0001..0005 qualification pack could be mistaken for the complete protocol catalog and mint an authoritative conforming verdict. | `Blocking`, resolved by separate qualification-slice and complete-snapshot declarations, exports, kernels, and results in the [SUBF-0143](#subf-0143) [design](subf-0143-typed-evaluation-kernel-design.md#catalog-authority-classes); the real Policy assembly exposes no complete pack in this slice. |
| `FIND-0402` <a name="find-0402"></a> | Embedding final artifact digests in the artifact that emits the manifest creates a self-digest cycle. | `Blocking`, resolved by the acyclic artifact -> finalized manifest -> release-envelope graph; neither artifact nor canonical manifest bytes contain their own final digest. |
| `FIND-0403` <a name="find-0403"></a> | Public or caller-authored receipts could be mistaken for admission authority, and canonical payload parsing could run twice across [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) and the kernel. | `Blocking`, resolved by manifest-bound but initially untrusted proof candidates, one plan-bound Conformance qualification/cache session that invokes the manifest codec once per exact binding/cache miss, and a separate Conformance admission pass that validates the qualified proof without rerunning the codec. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) owns routing/I/O and structural result construction, not decoding. |
| `FIND-0404` <a name="find-0404"></a> | Catalog evidence requirements could absorb adapter keys, provider ObjectType, permissions, or routes and fork common semantics. | `Blocking`, resolved by provider-neutral material roles/target selectors and exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) slot-to-route reconciliation; denial is failed/unavailable acquisition, never Absent. |
| `FIND-0405` <a name="find-0405"></a> | A one-shot evaluation API could acquire evaluation-only evidence before applicability, predict derived repository-target demand too early, or turn unresolved applicability into NotApplicable. | `Blocking`, resolved by the mandatory PlanApplicability -> CloseApplicability -> PlanEvaluation -> zero-to-N AdvanceEvaluation -> EvaluationClosure -> proof-free Evaluate state API and closed Applicable/NotApplicable/Unresolved intent. |
| `FIND-0406` <a name="find-0406"></a> | The accepted architecture assigned findings to Domain even though qualified references and final status require the outward sealed kernel. | `Blocking`, resolved by zero [SUBF-0143](#subf-0143) Domain exports, semantic intents in Abstractions, and kernel-only qualified references/findings/evaluations in Conformance; the architecture allocation is corrected in the same packet. |
| `FIND-0407` <a name="find-0407"></a> | Content-only or unbounded caches could cross releases/locations, accept a digest collision, or memoize cancellation. | `Blocking`, resolved by exact release/schema/artifact/budget decode keys, structural context/root/index keys, exact byte verification, session bounds, deterministic single-flight/eviction, and non-caching of operational failure. |
| `FIND-0408` <a name="find-0408"></a> | Initial rule selectors/digests were absent, RULE-0002 had two authorities, and RULE-0003/0004/0005 overlap was undefined. | `Blocking`, resolved by exact fragment bytes/digests, ordered length-framed normative digests, documentation-graph plus whole-template composition for RULE-0002, and explicit specialized co-report semantics. |
| `FIND-0409` <a name="find-0409"></a> | Evaluators could emit final status/severity/messages or collapse semantic, integrity, operational, and report failure domains. | `Blocking`, resolved by code/reference-only intents, catalog-derived severity/remediation, kernel minting, stable integrity codes, operational cancellation, and [SUBF-0154](#subf-0154)-only report serialization. |
| `FIND-0410` <a name="find-0410"></a> | [SUBF-0143](#subf-0143)/[TEST-0210](test-cases.md#test-0210) was too large for one test-first implementation/review cycle. | `Blocking`, resolved by four ordered internal ContractSlice groups A-D under the one canonical [TEST-0210](test-cases.md#test-0210) identity, each with its own later red/review/green gate. |
| `FIND-0411` <a name="find-0411"></a> | The successor surface matrix is broader than [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)'s exact initial live-provider inventory, and a Domain payload copy could occur before a non-lowerable transport ceiling. | `ExternalOrLegacyFollowUp` owned by [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md); [SUBF-0143](#subf-0143) supports provider-neutral captured fixtures but claims no unsupported live coverage. |
| `FIND-0412` <a name="find-0412"></a> | One solution-level workflow invocation may create a second testhost, so describing it as one OS process would hide a real Windows-budget cost. | `Blocking`, resolved in design by one restore/test invocation per existing job, explicit per-project testhost/count reconciliation, unchanged 35-minute timeout, and stop-for-review on exact-head budget failure. |
| `FIND-0413` <a name="find-0413"></a> | The typed handoff lacked exact per-assembly exports, activation proof, provider-neutral views, public state API, and negative surface oracles. | `Blocking`, resolved by the inventory-derived supported exports, exact activation/qualification/admission boundary, capability views, staged zero-to-N façade, and [TEST-0210](test-cases.md#test-0210) export/negative-surface matrix. |
| `FIND-0414` <a name="find-0414"></a> | The advertised exact API and canonical manifest were incomplete: factories used ellipses, nested field order was absent, and stable integrity codes had no inventory. | `Blocking`, resolved by complete public signatures, staged export deltas, closed integrity codes, exact nested manifest schema/order, private canonical bytes, and list-derived API oracles. |
| `FIND-0415` <a name="find-0415"></a> | Direct [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) codec invocation would split release/schema/cache authority from Conformance, while admission still must not decode twice. | `Blocking`, resolved by the plan-bound Conformance qualification session: [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) supplies the routed structural observed result, Conformance resolves and invokes the exact manifest codec once per binding/cache miss, Application copies the qualified handles into its proof candidate, and admission validates those handles without a codec rerun. |
| `FIND-0416` <a name="find-0416"></a> | A slot could not serve both applicability and evaluation under a single Phase field, and Abstractions referenced a reference-kind type owned downstream. | `Blocking`, resolved by phase-less structurally equal slot reuse across the two rule lists and moving QualifiedEvidenceReferenceKind into Abstractions. |
| `FIND-0417` <a name="find-0417"></a> | Activation/admission proofs self-asserted type identity without exact slot/contract/artifact mapping. | `Blocking`, resolved by activation/admission proof declarations, actual CLR type plus artifact bijection, exact coalesced SlotKey coverage, request reconciliation, and predecessor-trusted proof algorithms. |
| `FIND-0418` <a name="find-0418"></a> | [TEST-0210](test-cases.md#test-0210) required a complete-verdict truth table but no permitted complete pack could activate. | `Blocking`, resolved by a friend-only synthetic complete fixture envelope that cannot name or activate the real production Policy/release. |
| `FIND-0419` <a name="find-0419"></a> | Schema/model/parser/index/demand dependencies and heterogeneous invocation were not executable without reflection/object dispatch. | `Blocking`, resolved by one exact producer DAG, six typed internal codec/parser/index/demand-projector/selector/evaluator registration lists, complete registration/type-token bijection, and no reflection/DI/object/dynamic surface. |
| `FIND-0420` <a name="find-0420"></a> | ExpectedSelector provenance and qualified-reference canonical ordering were not declared. | `Blocking`, resolved by manifest-owned selector declarations/resolvers, sealed parent handles, exact variant projections, and a structural ordinal comparator distinct from report identity. |
| `FIND-0421` <a name="find-0421"></a> | Complete activation had no predecessor snapshot and could not verify transition completeness independently. | `Blocking`, resolved by genesis/existing predecessor bindings, kernel-minted snapshots, exact inventory framing, previous/current union validation, semantic comparison, and full-baseline named profile. |
| `FIND-0422` <a name="find-0422"></a> | Cache ceilings, manifest-byte immutability, and many-components-per-artifact uniqueness were unrepresentable. | `Blocking`, resolved by a separate session cache budget/retention algorithm, no public manifest bytes, artifact-file plus component mapping, and exact uniqueness/order rules. |
| `FIND-0423` <a name="find-0423"></a> | Slice A owned later-slice exports and the expected-red oracle simultaneously required compile failure and runtime discovery. | `Blocking`, resolved by cumulative A-D export deltas and separate exact SurfaceRed compile diagnostics followed by discovered/executed BehaviorRed tests. |
| `FIND-0424` <a name="find-0424"></a> | RULE-0001..0005 lacked exact slots, axes, components, selectors, budgets, scenario order, and stage-specific failure declarations. | `Blocking`, resolved by the complete initial registry/component/slot/rule/finding/failure matrices in the [SUBF-0143](#subf-0143) design. |
| `FIND-0425` <a name="find-0425"></a> | Plan/closure/result members, exact evaluation targets, selection rules, and capability collection ordering were incomplete. | `Blocking`, resolved by complete staged state signatures, target-bound instructions, exact static selection, zero-to-N single-use evaluation rounds, canonical provider-neutral views, and opaque predecessor/session-state enforcement. |
| `FIND-0426` <a name="find-0426"></a> | Repository-tree, governed-text, and repository-target-resolution payloads had logical names but no provider-neutral persistent bytes, so a codec could not prove canonical input or embedded scope/location coherence. | `Blocking`, resolved by the exact protocol-owned schema-1 binary wire grammars, strict UTF-8/framing/order rules, and closed demand-to-result bijection in the [SUBF-0143](#subf-0143) design. |
| `FIND-0427` <a name="find-0427"></a> | Historical/current target demand is discoverable only after governed-reference indexing; provider/repository aliases, external owners, empty demand, and multi-owner routing were not representable in the one-plan API. | `Blocking`, resolved by the typed repository-target projector over the one per-plan governed-reference capability, global ItemId-to-source-and-authority correlation, owner-sharded instructions, no-I/O empty demand with the registered target index invoked once over zero models, and deterministic AdvanceEvaluation rounds. |
| `FIND-0428` <a name="find-0428"></a> | Component cardinality, producer usage, and cache ownership remained ambiguous after adding dynamic projection. | `Blocking`, resolved by exact cumulative exports `48/72/95/96`, final `72` Abstractions / `23` Conformance / `1` Policy, the `27`-row Policy registration/type-contract partition, `35`-row full component union, six registration lists, four-counter usage/ledger contracts, and distinct Conformance-owned decode/model and index caches. |
| `FIND-0429` <a name="find-0429"></a> | A qualifier-only codec seam would force Application/provider code to reimplement canonical protocol bytes. | `Blocking`, resolved by one manifest component owning a persistent writer and paired qualifier, exact writer intent/failure codes, golden round trips, and no Application-side encoder. |
| `FIND-0430` <a name="find-0430"></a> | Acquisition attempts, staged outcomes, final public exports, and nullability/cardinality were incomplete after the typed-handoff expansion. | `Blocking`, resolved by the closed attempt/outcome unions including aggregate-only `projected-resource-failed`, cumulative `48/72/95/96` export lists, final `72/23/1` assembly partition, and exact Plan/Advance/Closure/result signatures. |
| `FIND-0431` <a name="find-0431"></a> | Producers could self-claim transitive resource usage, double-count selected payload bytes, and let cache hits lose exact metered authority. | `Blocking`, resolved by disjoint local-versus-selected four-counter rows, reachable-governing/algebraically-dominated/schema-unreachable oracle classes, target-codec/parser non-dominated equality budgets, declared-failure versus pairing-integrity semantics, immutable usage on sealed handles, and input-only collision-checked cache identities. |
| `FIND-0432` <a name="find-0432"></a> | Markdown syntax, renderer-active links/anchors, heading IDs, parser exceptions, and source-span ownership were implementation-selected. | `Blocking`, resolved by manifest-bound Markdig 1.3.2 bytes, a fresh exact pipeline, protocol-owned iterative walk/GFM heading projection, exact autolink/HTML truth tables, and pinned failure discrimination. |
| `FIND-0433` <a name="find-0433"></a> | ContractSlice B/C/D tests crossed ownership boundaries, made C depend on real Policy before its synthetic graph was green, and left first-red absence nondeterministic. | `Blocking`, resolved by B codec-only activation/admission, C Tests-owned synthetic complete six-family activation, D-only real Policy consumption, exact warning-free first-red sentinels, D export-first/RULE-0001-second ordering, and fresh immutable fixture data rather than consumed B/C results. |
| `FIND-0434` <a name="find-0434"></a> | Writer/qualifier/admission attempt, retry, cancellation, terminal rejection, and NoInput eligibility could not be reconstructed causally. | `Blocking`, resolved by the private stamped ticket, zero-mutation structural validation, sticky Attempted bit, exact retained products/cache association, terminal cleanup, and closed Observed/Failed/NoInput admission cases. |
| `FIND-0435` <a name="find-0435"></a> | Commit-only Git resolution could not prove tag roots, deleted historical paths, captured current files, Markdown anchors, non-Markdown lines, or source authority without consulting the current tree. | `Blocking`, resolved by the CommitObject/TagRoot/CapturedSnapshotPath union, manifest-expected captured-content authority, canonical target payload/content table and derived-node identity frames, paired historical Markdown model, generalized target index/cache, external-owner Snapshot custody, and exact RULE-0003/0004/0005 overlays. |

| Test readiness | Current state | Evidence |
| --- | --- | --- |
| Scenarios | Defined and decomposed; [TEST-0220](test-cases.md#test-0220) executable and complete; [TEST-0221](test-cases.md#test-0221) Gate 2 design complete; [TEST-0210](test-cases.md#test-0210) Gate 2/expected-red design candidate | [TEST-0209](test-cases.md#test-0209) remains the feature-level composed scenario; later executable scenarios remain planned |
| Test code | [TEST-0220](test-cases.md#test-0220) exact-main complete; [TEST-0221](test-cases.md#test-0221) and [TEST-0210](test-cases.md#test-0210) deliberately absent | No source, project, lock, workflow, scenario-owner, expected-red execution, or [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) mutation is authorized |
| Baseline run | [SUBF-0153](#subf-0153) Gate 2 exact-main closure complete; executable baseline remains [SUBF-0152](#subf-0152) | [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171), exact design commit [`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f), and [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520); no [TEST-0221](test-cases.md#test-0221) or [TEST-0210](test-cases.md#test-0210) executable evidence exists |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Dependencies | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `SUBF-0142` <a name="subf-0142"></a> | Original typed rule/evidence/location/outcome/report planning slice | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | Accepted architecture | [TEST-0209](test-cases.md#test-0209) / not started | Gate 2 found mixed contracts | Superseded before implementation by [SUBF-0152](#subf-0152), [SUBF-0153](#subf-0153), [SUBF-0143](#subf-0143), and [SUBF-0154](#subf-0154); never reuse |
| `SUBF-0143` <a name="subf-0143"></a> | [Qualification/complete catalog separation, release-bound provider-neutral typed context, persistent schema wires, topological owner-sharded target demand, sealed references, staged evaluator kernel, first common-rule slice, and deterministic aggregation](subf-0143-typed-evaluation-kernel-design.md) | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) / [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584) | Accepted/merged/exact-main-validated [SUBF-0153](#subf-0153) Gate 2 for its own Gate 2; completed [SUBF-0153](#subf-0153) before its Gate 3 | [TEST-0210](test-cases.md#test-0210) / expected-red matrix designed; no executable source or run | Bounded red-team and maintainer acceptance pending; exact design inventory is `48/72/95/96`, final public split `72/23/1`, with `27` Policy registration/type-contract and `35` full component rows | Gate 2 design candidate; implementation not authorized |
| `SUBF-0144` <a name="subf-0144"></a> | Extensions, waivers, debt, qualification, and predecessor-trusted self-consumption | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [SUBF-0143](#subf-0143) | [TEST-0211](test-cases.md#test-0211) / not started | Pending | Proposed |
| `SUBF-0152` <a name="subf-0152"></a> | [Closed rule identity, profile-axis, and outcome vocabulary](subf-0152-domain-vocabulary-design.md) in a fresh BCL-only Domain assembly | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md); architecture [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169); implementation [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170) | [TEST-0220](test-cases.md#test-0220) / expected red, 52 of 52 focused Release tests, cross-runtime StructureOnly, and exact-main [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506) | Gate 5 reviews and exact-main Ubuntu/Windows validation clean; zero unresolved `Blocking` findings | Complete at [`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da) |
| `SUBF-0153` <a name="subf-0153"></a> | [Evidence requirements, target/boundary scope, asserted-canonical payloads, typed locations, contexts, and acquisition-result union](subf-0153-evidence-contract-design.md) | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) / historical [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253) / [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) | Completed [SUBF-0152](#subf-0152) for Gate 2; accepted/merged/exact-main-validated [SUBF-0143](#subf-0143) typed-handoff Gate 2 before Gate 3 | [TEST-0221](test-cases.md#test-0221) / expected-red matrix designed; no executable source or run | Gate 2 accepted/merged/exact-main validated at [`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f) | Gate 2 design complete; implementation not authorized |
| `SUBF-0154` <a name="subf-0154"></a> | Canonical report sealing, serialization, digest, redaction, and full composed qualification | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [SUBF-0153](#subf-0153), [SUBF-0143](#subf-0143), [SUBF-0144](#subf-0144) | [TEST-0222](test-cases.md#test-0222), [TEST-0209](test-cases.md#test-0209) / not started | Pending | Proposed / not authorized |

[TEST-0209](test-cases.md#test-0209) is a feature-level composed production
qualification scenario across [SUBF-0152](#subf-0152),
[SUBF-0153](#subf-0153), [SUBF-0143](#subf-0143),
[SUBF-0144](#subf-0144), and [SUBF-0154](#subf-0154). It is not a child-test
aggregator and cannot close a predecessor by collecting other tests' results.

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Required collaborators: [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md) and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
- Historical source: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md) and [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)

## Definition of Ready for [SUBF-0152](#subf-0152)

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, dependencies, risks, and reviewable decomposition.
- [x] Initial rule/specification/qualification/evidence matrix and numbered planning scenarios, including distinct [SUBF-0152](#subf-0152) coverage.
- [x] Exact WIP source disposition and approved design-level destinations.
- [x] Complete [SUBF-0152](#subf-0152) contract inventory; normative RULE inventory and fragment digests are reviewed `NotApplicable` and owned by [SUBF-0143](#subf-0143).
- [x] Project-neutral [TEST-0220](test-cases.md#test-0220) expected-red matrix and exact execution route.
- [x] [Gate 2 design review](subf-0152-domain-vocabulary-design.md) for [SUBF-0152](#subf-0152), including recurrence, sibling, WIP, project-graph, error, compatibility, and hosted-owner contracts.
- [x] Separate [maintainer implementation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932), scoped only to [SUBF-0152](#subf-0152) after exact-main validation.
- [x] Gate 3 [TEST-0220](test-cases.md#test-0220) expected-red execution and focused green; see [canonical local evidence](test-cases.md#evidence).

## Definition of Ready for [SUBF-0153](#subf-0153)

- [x] Stable subfeature/test IDs, linked issue, accepted parent architecture,
  completed predecessor, design-only directive, problem, outcome, scope,
  non-goals, dependencies, and C# implementation rule are explicit.
- [x] Exact inventory-derived public API, parameter/nullability contract,
  open/closed vocabulary and owner boundary, target/boundary/scope graph,
  derived-state matrices, errors, equality, digests, deterministic ordering,
  and defensive immutability are defined in the
  [evidence-contract design](subf-0153-evidence-contract-design.md).
- [x] Missing versus failed acquisition, consistency, completeness,
  requirement-scoped redaction/failure, pagination, structural empty-inventory
  proof, typed location, asserted-canonical payload, binding, context, and
  result-union invariants are closed.
- [x] Finding/evaluation records are removed from this slice; SUBF-0143 owns
  the release-bound typed-model context, exact evaluation-input closure,
  applicability, evaluation failures, findings, and status factories.
- [x] Same-contract scenario inventory, WIP provenance/dispositions, exact
  [TEST-0221](test-cases.md#test-0221) expected-red matrix, [TEST-0220](test-cases.md#test-0220) cumulative API ownership transition,
  one-invocation hosted route, risks, recurrences, and verification budget are
  defined.
- [x] Bounded Gate 2 red-team has no unresolved `Blocking` or `Important`
  finding.
- [x] The maintainer accepted the design candidate; [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171)
  merged the accepted packet.
- [x] Exact main
  [`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f)
  passed the bounded structural/document route recorded in the
  [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520)
  without restarting the held full hosted workflow matrix.
- [ ] A separately reviewed and maintainer-accepted SUBF-0143 typed-handoff
  Gate 2 packet closes persistent schema wires, plan-bound Conformance
  codec/qualification/cache ownership, instruction-bound admission receipts,
  four-counter semantic budgets, typed producer/demand DAG, owner-sharded target
  projection, context-proof/derived references, zero-to-N staged evaluation
  readiness, finding, and final-status ownership; that packet is merged and
  passes bounded exact-main validation before SUBF-0153 implementation.
- [ ] A separate maintainer directive explicitly authorizes [TEST-0221](test-cases.md#test-0221) source,
  expected-red execution, production implementation, [TEST-0220](test-cases.md#test-0220) inventory
  transition, scenario-owner activation, combined workflow filter, and narrow
  [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) update.

No unchecked item may be inferred from design publication, structural
validation, a draft pull request, or the word “continue.” Gate 3 remains closed.

## Definition of Ready for [SUBF-0143](#subf-0143)

- [x] Stable subfeature/test IDs, linked issue, accepted parent architecture,
  accepted/merged/exact-main predecessor design, design-only directive,
  problem, outcome, scope, non-goals, dependencies, risks, and C# future
  implementation rule are explicit.
- [x] Qualification slice and complete protocol snapshot use distinct
  declarations, exports, kernels, results, activation requirements, and verdict
  authority.
- [x] Canonical manifest bytes, acyclic artifact binding, exact rule fragment
  selectors/bytes/digests, normative framing, first-rule revisions/codes,
  evolution, and overlap semantics are defined in the
  [typed-evaluation-kernel design](subf-0143-typed-evaluation-kernel-design.md).
- [x] Zero Domain export delta, exact Abstractions/Conformance/Policy export
  inventories, project dependencies, provider-neutral capabilities, proof-
  candidate admission, sealed references, persistent schema wires, two-tier
  cache keys, four-counter budgets, six typed registration lists, staged
  zero-to-N façade, owner-sharded demand, semantic intents, kernel-minted
  outputs, and aggregate truth table are exact.
- [x] Full same-contract sibling inventory, WIP dispositions, four internal
  ContractSlice groups, [TEST-0210](test-cases.md#test-0210) expected-red purity,
  exact project/lock transition, combined invocation,
  [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  obligations,
  and unchanged Windows budget are defined.
- [ ] Bounded Gate 2 red-team has no unresolved `Blocking` or `Important`
  finding.
- [ ] The maintainer has accepted the [SUBF-0143](#subf-0143) design candidate.
- [ ] The accepted design packet is merged and its exact-main commit passes
  bounded structural/document validation.
- [ ] A separate maintainer directive explicitly authorizes the first
  [TEST-0210](test-cases.md#test-0210) ContractSlice source, expected-red
  execution, reviewed project/lock transition, and bounded production
  implementation.

No unchecked item may be inferred from design publication, structural
validation, a draft pull request, or the word “continue.” Gate 3 remains closed.

## Acceptance criteria

1. The same evaluator and protected baseline catalog apply to meAndAI and consumers; only typed evidence and applicability axes differ.
2. Every evaluated rule binds one stable identity, exact normative provenance, compiled evaluator, required evidence, and qualification scenario set.
3. Missing, stale, partial, failed, or unsupported evidence cannot become conforming.
4. Reports separate acquisition, evaluation, conformance, enforcement, debt, waiver, and authority dimensions and serialize deterministically.
5. Extensions cannot shadow or weaken baseline rules; waivers are typed, scoped, decision-linked, and report-visible.
6. Candidate runtime or policy cannot certify itself without predecessor-trusted and independently qualified evidence.
7. The kernel has no mutation, provider, workflow, or publication dependency.

## Definition of Done

[SUBF-0152](#subf-0152) is complete through expected red, bounded production
implementation, focused green, zero-warning Release build, clean format,
direct [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
evidence, cross-runtime StructureOnly, protected [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170),
exact merge commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and exact-main [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).

[SUBF-0153](#subf-0153) is complete through Gate 2 design acceptance, merge,
and bounded exact-main validation, but its implementation and
[TEST-0221](test-cases.md#test-0221) remain
pending. [SUBF-0143](#subf-0143) is not done: the current packet is only a Gate
2 design candidate and [TEST-0210](test-cases.md#test-0210) has no executable
source or run. The parent
feature remains open because every later implementation, complete catalog,
report, policy, self-consumption, release, and authority gate is separately
pending. External pull-request, directive, and hosted facts are governed by
[issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) and do not grant
unstated authority.
