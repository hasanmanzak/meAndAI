# FEAT-0067 - Evidence Acquisition and Managed Consumer Integration

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed under accepted architecture; implementation not authorized |
| Target version | 0.17.0 |
| Issue | [#167](https://github.com/hasanmanzak/meAndAI/issues/167) |
| Pull request | Not created; development not authorized |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), [DEC-0001](../../decisions/DEC-0001-portable-protocol-reference.md), [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md), [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), and [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md) |
| Tests | [TEST-0214](test-cases.md#test-0214), [TEST-0215](test-cases.md#test-0215), and [TEST-0216](test-cases.md#test-0216) |

## Implementation hold

This record owns boundary 3 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
No C# implementation, WIP extraction, workflow or ruleset change, consumer
mutation, provider mutation, result publication, release publication, or
authority transfer is authorized.

## Problem

The shared conformance kernel cannot inspect a repository or provider by
itself, while consumers must not copy Git/GitHub validators, fixtures, or
workflow logic. Exact protocol references, provider pagination, event trust,
immutable runtime resolution, process isolation, and result publication also
carry different privilege and completeness risks.

## Outcome

Protocol-owned C# adapters acquire exact repository and GitHub evidence,
resolve and verify one immutable protocol distribution, invoke the shared
evaluator through least-authority hosts, and publish results through a
separately authorized path. Consumers retain only a small managed hook that
resolves, verifies, invokes, and transports.

## Scope

- Exact Git commit/tree/blob capture and explicitly non-authoritative candidate
  HEAD/index/worktree/untracked envelopes.
- Gitlink and repository-reference resolution, Trust Bootstrap, manifest,
  digest, runtime/catalog/schema compatibility, cache, and fresh extraction.
- GitHub event acquisition and scheduled/manual paginated full inventory with
  object identity, freshness, delivery, cursor/page, convergence, redaction,
  rate-limit, and completeness evidence.
- Read-only evaluator host and distinct report-publisher host using the shared
  [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
  publication boundary.
- Managed consumer hook lifecycle and stale/tampered projection detection.
- Fork, same-repository, private-artifact, credential, untrusted-input,
  cancellation, timeout, process-tree, and unsupported-capability behavior.

## Non-goals

- Rule semantics, catalog applicability, or conformance aggregation.
- Adoption or update strategy and mutation.
- Protocol release planning or authority transfer.
- Executing untrusted pull-request code in a privileged workflow.
- Copying shared validators, fixtures, transition engines, or release logic
  into a consumer.

## Readiness evidence

- Dependencies: completed [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md),
  [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md), and
  [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md).
- Initial acquisition split: the accepted
  [rule matrix](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#5-first-rulespecificationqualificationevidence-matrix)
  keeps semantics in [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md)
  while this feature owns repository/provider completeness.
- WIP input: exact Git reader/parser/policy, process runner, immutable
  resolution, candidate capture, packaging execution, and host seeds are
  classified in the
  [extraction ledger](../../architecture/protocol-governance-and-execution/wip-extraction-ledger.md).
- Canonical live-provider prior art: [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176)
  remains a qualification scenario, not a provider-owned rule.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0304` <a name="risk-0304"></a> | Partial, stale, truncated, divergent, rate-limited, or failed provider evidence appears conforming. | Acquisition owner / explicit completeness manifest, convergence and finite bounds, separate acquisition outcome, and fail-closed publication. |
| `RISK-0305` <a name="risk-0305"></a> | A privileged hook executes untrusted repository code, accepts a tampered runtime, leaks credentials, or publishes under the wrong authority. | Integration owner / exact immutable resolution and attestation, no untrusted checkout/execute, separated read/publish grants, process isolation, redaction, and unsupported-fork outcome. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Implementation is not authorized |
| Baseline run | Not run | Expected-red adapters, fixtures, and hosts do not exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0147` <a name="subf-0147"></a> | Exact Git/reference acquisition, Trust Bootstrap, immutable resolution, cache, and process execution | [#167](https://github.com/hasanmanzak/meAndAI/issues/167) | [TEST-0214](test-cases.md#test-0214) / not started | Pending | Proposed |
| `SUBF-0148` <a name="subf-0148"></a> | GitHub event and convergent full-inventory acquisition with completeness evidence | [#167](https://github.com/hasanmanzak/meAndAI/issues/167) | [TEST-0215](test-cases.md#test-0215) / not started | Pending | Proposed |
| `SUBF-0149` <a name="subf-0149"></a> | Managed hook, evaluator host, result publisher, privilege isolation, and unsupported-fork behavior | [#167](https://github.com/hasanmanzak/meAndAI/issues/167) | [TEST-0216](test-cases.md#test-0216) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md), and [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md)
- Consumers: [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), and [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
- Historical source: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md) and [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)

## Definition of Ready

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, dependencies, risks, and reviewable decomposition.
- [x] Repository/provider ownership split, numbered planning scenarios, and exact WIP disposition.
- [ ] Exact GitHub surface inventory, pagination/convergence limits, credential matrix, and managed-hook projection schema for the selected slice.
- [ ] Expected-red Git/GitHub/process/runtime/hook fixtures.
- [ ] Gate 2 security and dependency-boundary review.
- [ ] Separate maintainer implementation directive.

## Acceptance criteria

1. Exact Git evidence is canonical and immutable; candidate evidence is explicitly non-authoritative and cannot transfer authority.
2. Provider inventory proves identity, pagination, freshness, convergence, completeness, and bounded failure without converting missing evidence into success.
3. One verified immutable protocol release binds source, runtime, catalog, schemas, hosts, projections, and digests before invocation.
4. The managed hook contains no protocol rule, evaluator, fixture, mutation engine, or release-finalization copy.
5. The evaluator host is read-only; result publication uses a separate fresh grant and cannot alter evaluation evidence.
6. Privileged execution never checks out or executes untrusted pull-request code; unsupported trust shapes fail explicitly.
7. Process, cache, artifact, credential, cancellation, timeout, containment, and redaction behavior is qualified on every supported operating system.

## Definition of Done

All implementation, expected-red, review, exact-head test, hosted integration,
managed-hook, documentation, release, and external evidence gates remain
pending.
