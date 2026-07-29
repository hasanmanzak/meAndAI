# FEAT-0065 - Shared Executable Conformance Runtime

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed under accepted architecture; implementation not authorized |
| Target version | 0.17.0 |
| Issue | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Pull request | Not created; development not authorized |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), partially superseded [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), and [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) |
| Tests | [TEST-0209](test-cases.md#test-0209), [TEST-0210](test-cases.md#test-0210), and [TEST-0211](test-cases.md#test-0211) |

## Implementation hold

This record owns boundary 1 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
It does not authorize C# code, test code, extraction from
[draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160), workflow
changes, publication, or authority transfer.

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

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Implementation is not authorized |
| Baseline run | Not run | Expected-red target assemblies and fixtures do not exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0142` <a name="subf-0142"></a> | Typed rule, evidence, location, outcome, and report contracts | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [TEST-0209](test-cases.md#test-0209) / not started | Pending | Proposed |
| `SUBF-0143` <a name="subf-0143"></a> | Immutable catalog, evaluator kernel, first common-rule slice, and deterministic aggregation | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [TEST-0210](test-cases.md#test-0210) / not started | Pending | Proposed |
| `SUBF-0144` <a name="subf-0144"></a> | Extensions, waivers, debt, qualification, and predecessor-trusted self-consumption | [#165](https://github.com/hasanmanzak/meAndAI/issues/165) | [TEST-0211](test-cases.md#test-0211) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Required collaborators: [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md) and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
- Historical source: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md) and [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)

## Definition of Ready

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, dependencies, risks, and reviewable decomposition.
- [x] Initial rule/specification/qualification/evidence matrix and numbered planning scenarios.
- [x] Exact WIP source disposition and approved design-level destinations.
- [ ] Complete rule inventory for the selected implementation slice and exact normative-fragment digests.
- [ ] Expected-red test implementation and project-neutral fixtures.
- [ ] Gate 2 design review for the selected dependency-closed slice.
- [ ] Separate maintainer implementation directive.

## Acceptance criteria

1. The same evaluator and protected baseline catalog apply to meAndAI and consumers; only typed evidence and applicability axes differ.
2. Every evaluated rule binds one stable identity, exact normative provenance, compiled evaluator, required evidence, and qualification scenario set.
3. Missing, stale, partial, failed, or unsupported evidence cannot become conforming.
4. Reports separate acquisition, evaluation, conformance, enforcement, debt, waiver, and authority dimensions and serialize deterministically.
5. Extensions cannot shadow or weaken baseline rules; waivers are typed, scoped, decision-linked, and report-visible.
6. Candidate runtime or policy cannot certify itself without predecessor-trusted and independently qualified evidence.
7. The kernel has no mutation, provider, workflow, or publication dependency.

## Definition of Done

All implementation, expected-red, review, exact-head test, release,
self-consumption transfer, documentation, and external evidence gates remain
pending.
