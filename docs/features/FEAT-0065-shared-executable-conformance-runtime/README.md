# FEAT-0065 - Shared Executable Conformance Runtime

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0152](#subf-0152) authorized; Gate 3 expected-red pending |
| Target version | 0.17.0 |
| Issue | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Pull request | Not created; Gate 1 and Gate 2 complete |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), partially superseded [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) |
| Tests | [TEST-0209](test-cases.md#test-0209), [TEST-0210](test-cases.md#test-0210), [TEST-0211](test-cases.md#test-0211), [TEST-0220](test-cases.md#test-0220), [TEST-0221](test-cases.md#test-0221), and [TEST-0222](test-cases.md#test-0222) |

## Scoped implementation directive

This record owns boundary 1 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
The maintainer's 2026-07-29
[directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932)
and narrow [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
[infrastructure clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122634847)
authorize only [SUBF-0152](#subf-0152), whose
[design](subf-0152-domain-vocabulary-design.md) defines a
test-first implementation slice. [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169)
is merged and its exact tree passed the
[main validation run](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).
[SUBF-0153](#subf-0153), [SUBF-0143](#subf-0143),
[SUBF-0144](#subf-0144), [SUBF-0154](#subf-0154),
extraction from [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160),
provider or repository I/O, publication, release, and authority transfer remain
unauthorized.

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

## Gate 2 findings

| ID | Observation | Disposition |
| --- | --- | --- |
| `FIND-0365` <a name="find-0365"></a> | [SUBF-0142](#subf-0142) and [TEST-0209](test-cases.md#test-0209) mixed scalar, evidence, report, serialization, and debt/waiver contracts. | `Blocking`, resolved in design by [SUBF-0152](#subf-0152)/[TEST-0220](test-cases.md#test-0220) and later dependency-closed owners while preserving [TEST-0209](test-cases.md#test-0209) as a true feature-level composed scenario. |
| `FIND-0366` <a name="find-0366"></a> | The stable workflow runs only the Operations solution, so a new protocol test could compile locally yet never execute in hosted validation. | `Blocking`, resolved in design by the exact two-job [execution route](subf-0152-domain-vocabulary-design.md#canonical-execution-route) and explicitly authorized existing [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) infrastructure-contract barrier; executable closure remains part of [SUBF-0152](#subf-0152). |
| `FIND-0367` <a name="find-0367"></a> | The accepted architecture said no RULE IDs were allocated while its accepted successor matrix allocated [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005). | `Blocking`, resolved by the planning correction in the same Gate 2 packet; it grants no evaluator or digest authority. |
| `FIND-0368` <a name="find-0368"></a> | [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001), [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002), [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003), [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004), and [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005) resolve, but rule-specific fragment selectors, canonical bytes, and exact digests are not ready; [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002) has conflicting required-structure authorities. | `ExternalOrLegacyFollowUp`, owned by [SUBF-0143](#subf-0143) and [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165); blocking before the first catalog/evaluator slice, not [SUBF-0152](#subf-0152). |
| `FIND-0369` <a name="find-0369"></a> | The original durable directive and active instruction graph named the mixed [SUBF-0142](#subf-0142)/[TEST-0209](test-cases.md#test-0209) boundary and still withheld every implementation/workflow change. | `Blocking`, resolved by the [corrected scoped directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5122419932), transition gate, successor gate, and project-memory handoff. Only [SUBF-0152](#subf-0152)/[TEST-0220](test-cases.md#test-0220), including its stable-job registration, receives authority. |
| `FIND-0370` <a name="find-0370"></a> | The first Gate 2 draft left public signatures, nullability, collection exposure, and error categories ambiguous while making private/record details test oracles. | `Blocking`, resolved by the [exact public API/error contract and observable-test boundary](subf-0152-domain-vocabulary-design.md#exact-public-api-and-semantic-contract). |
| `FIND-0371` <a name="find-0371"></a> | The mixed-slice supersession map, future dependency edges, and [TEST-0221](test-cases.md#test-0221) same-contract review were incomplete. | `Blocking`, resolved by allocating typed rule/catalog ownership to [SUBF-0143](#subf-0143), making the dependency chain explicit, and recording [TEST-0221](test-cases.md#test-0221) against [TEST-0209](test-cases.md#test-0209) plus preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195). |
| `FIND-0372` <a name="find-0372"></a> | [TEST-0209](test-cases.md#test-0209) described incomplete acquisition and non-conforming verdict as one alternative outcome. | `Blocking`, resolved by preserving acquisition, rule evaluation, conformance, and enforcement as four separate dimensions with accepted precedence. |
| `FIND-0373` <a name="find-0373"></a> | Future [TEST-0221](test-cases.md#test-0221) wording could make evidence absence look like a fourth acquisition status. | `ExternalOrLegacyFollowUp`: planning now retains absence as an input fact whose required-evidence rollup is `Incomplete`, distinct from a present invalid source yielding `Failed`; full envelope semantics remain a [SUBF-0153](#subf-0153) Gate 2 obligation and do not block [SUBF-0152](#subf-0152). |

| Test readiness | Current state | Evidence |
| --- | --- | --- |
| Scenarios | Defined and decomposed | [TEST-0209](test-cases.md#test-0209) remains the feature-level composed scenario; [TEST-0220](test-cases.md#test-0220) owns [SUBF-0152](#subf-0152) |
| Test code | Not started | Exact-main prerequisite satisfied; Gate 3 expected-red is next |
| Baseline run | Not run | [TEST-0220](test-cases.md#test-0220) expected-red target assemblies and fixtures do not exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Dependencies | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `SUBF-0142` <a name="subf-0142"></a> | Original typed rule/evidence/location/outcome/report planning slice | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | Accepted architecture | [TEST-0209](test-cases.md#test-0209) / not started | Gate 2 found mixed contracts | Superseded before implementation by [SUBF-0152](#subf-0152), [SUBF-0153](#subf-0153), [SUBF-0143](#subf-0143), and [SUBF-0154](#subf-0154); never reuse |
| `SUBF-0143` <a name="subf-0143"></a> | Immutable catalog, evaluator kernel, first common-rule slice, and deterministic aggregation | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [SUBF-0152](#subf-0152), [SUBF-0153](#subf-0153), and rule-fragment closure | [TEST-0210](test-cases.md#test-0210) / not started | Pending | Proposed |
| `SUBF-0144` <a name="subf-0144"></a> | Extensions, waivers, debt, qualification, and predecessor-trusted self-consumption | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [SUBF-0143](#subf-0143) | [TEST-0211](test-cases.md#test-0211) / not started | Pending | Proposed |
| `SUBF-0152` <a name="subf-0152"></a> | [Closed rule identity, profile-axis, and outcome vocabulary](subf-0152-domain-vocabulary-design.md) in a fresh BCL-only Domain assembly | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md); merged [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169); exact-main [run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367) | [TEST-0220](test-cases.md#test-0220) / not started | Gate 2 fresh-diff findings resolved; implementation review pending | Authorized; Gate 3 expected-red pending |
| `SUBF-0153` <a name="subf-0153"></a> | Evidence requirements/envelopes, typed locations, findings, and rule-evaluation records | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [SUBF-0152](#subf-0152) | [TEST-0221](test-cases.md#test-0221) / not started | Pending | Proposed / not authorized |
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
- [ ] Gate 3 [TEST-0220](test-cases.md#test-0220) expected-red execution.

## Acceptance criteria

1. The same evaluator and protected baseline catalog apply to meAndAI and consumers; only typed evidence and applicability axes differ.
2. Every evaluated rule binds one stable identity, exact normative provenance, compiled evaluator, required evidence, and qualification scenario set.
3. Missing, stale, partial, failed, or unsupported evidence cannot become conforming.
4. Reports separate acquisition, evaluation, conformance, enforcement, debt, waiver, and authority dimensions and serialize deterministically.
5. Extensions cannot shadow or weaken baseline rules; waivers are typed, scoped, decision-linked, and report-visible.
6. Candidate runtime or policy cannot certify itself without predecessor-trusted and independently qualified evidence.
7. The kernel has no mutation, provider, workflow, or publication dependency.

## Definition of Done

[SUBF-0152](#subf-0152) implementation, expected-red, review, exact-head, and hosted evidence
remain pending. Every later task/subfeature, release, self-consumption transfer,
and authority gate remains separately pending and unauthorized.
