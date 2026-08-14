# FEAT-0066 - Shared Execution-Authority Foundation

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0145](#subf-0145) `DesignFreezeCandidate`; implementation conditionally authorized only after `AcceptedFrozenDesign` exact-head hosted green |
| Target version | 0.17.0 |
| Issue | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) |
| Pull request | Design checkpoint not yet created |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md), [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md), and [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md) |
| Tests | [TEST-0212](test-cases.md#test-0212) and [TEST-0213](test-cases.md#test-0213) |

## Conditional implementation boundary

This record owns boundary 2 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
The current maintainer directive authorizes the
[SUBF-0145](#subf-0145) [design freeze](subf-0145-authority-grant-activation-design.md) and
conditionally authorizes only its four implementation packages after the exact
[AcceptedFrozenDesign gate](subf-0145-micro-delivery-plan.md#acceptedfrozendesign-gate)
is green. Until then no production or executable-test implementation is active.
After that gate, the package sequence proceeds without another confirmation.
Merge, release, publication, consumer mutation, credentials, authority
transfer, and [SUBF-0146](#subf-0146) implementation remain separately held.
The preserved [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160)
contains no directly reusable implementation for this foundation.

## Problem

Adoption, update, result publication, extension activation, and protocol
release finalization need the same exact authorization, concurrency, durability,
and recovery semantics. If each application implements them independently,
least authority, single-engine mutation, replay resistance, and crash recovery
will diverge.

## Outcome

One C# foundation owns authority-set snapshots, separated roles, typed
capabilities and grants, protected activation CAS, publication envelopes,
leases and fences, durable journals and receipts, retention, fail-closed
reconstruction, and explicit recovery grants for every mutating application.

## Scope

- Exact authority-set, actor, subject, repository, provider, target, operation,
  generation, freshness, expiry, capability, and grant identities.
- Non-transitive read, mutate, publish, finalize, recover, and transfer
  capabilities with separation of duties.
- Protected extension-activation records and compare-and-swap transitions.
- Sealed publication envelopes, plan identity, target revalidation, and
  time-of-check/time-of-use barriers.
- Leases, fencing tokens, append-only journal entries, receipts, retention,
  reconstruction, interruption classification, and recovery grants.
- One reusable application port boundary consumed by result publication,
  adoption, update, and release finalization.

## Non-goals

- Governance rule semantics or conformance evaluation.
- Git, GitHub, filesystem, workflow, or release adapter implementation.
- Application-specific strategy, migration, or release policy.
- Automatic fallback between PowerShell and C# or between mutation actors.
- Treating an engine-state label as executable authority.

## Readiness evidence

- Dependency: completed [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md).
- Consumers: [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md),
  [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md),
  [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), and
  [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md).
- WIP finding: the accepted
  [extraction ledger](../../architecture/protocol-governance-and-execution/wip-extraction-ledger.md#3-important-absence-findings)
  confirms this is new work rather than a renamed WIP authority-state enum.
- Verification approach: pure domain/unit tests first, followed by durable
  store, crash, replay, concurrency, and real-adapter integration fixtures.
- Selected-slice Gate 2 contracts and exact package controls:
  [selected design](subf-0145-authority-grant-activation-design.md),
  [exact public API contract](subf-0145-public-api-contract.md),
  [exact value/error contract](subf-0145-value-error-contract.md), and
  [micro-delivery plan](subf-0145-micro-delivery-plan.md).

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0302` <a name="risk-0302"></a> | A stale, replayed, over-broad, or role-conflicting grant authorizes mutation or authority transfer. | Authority owner / exact subject-target-operation-generation binding, expiry/freshness, non-transitivity, separation rules, and atomic consumption evidence. |
| `RISK-0303` <a name="risk-0303"></a> | Journal loss, lease expiry, retention, corruption, or duplicated receipts reconstructs an ambiguous operation as complete. | Recovery owner / fencing, append-only integrity, explicit terminal receipts, fail-closed reconstruction, and separately authorized recovery. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Activates only after the `AcceptedFrozenDesign` gate |
| Baseline run | Not run | No prior same-contract implementation exists |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0145` <a name="subf-0145"></a> | Authority snapshots, role separation, grants, activation CAS, and publication envelopes | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) | [TEST-0212](test-cases.md#test-0212) / not started | Design reviews pending | `DesignFreezeCandidate`; [design](subf-0145-authority-grant-activation-design.md) / [API](subf-0145-public-api-contract.md) / [values/errors](subf-0145-value-error-contract.md) / [micro plan](subf-0145-micro-delivery-plan.md) |
| `SUBF-0146` <a name="subf-0146"></a> | Leases, fences, journal, receipts, retention, reconstruction, and recovery grants | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) | [TEST-0213](test-cases.md#test-0213) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Consumers: [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), and [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)

## Definition of Ready

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, consumers, risks, and reviewable decomposition.
- [x] Numbered planning scenarios and explicit WIP absence finding.
- [x] Exact authority/grant/activation schemas and store-port contracts for selected [SUBF-0145](#subf-0145).
- [x] Exact [TEST-0212](test-cases.md#test-0212) expected-red FQNs, replay, role, publication, and concurrent-CAS fixture plan.
- [ ] [SUBF-0146](#subf-0146) journal, crash, corruption, retention, reconstruction, and recovery schema/fixture freeze.
- [ ] Gate 2 design review for the selected dependency-closed slice.
- [x] Maintainer implementation directive exists conditionally; activates only after `AcceptedFrozenDesign` exact-head hosted green.

## Acceptance criteria

1. No mutating operation can begin without a fresh exact capability grant for its unchanged subject, target, operation, and generation.
2. Read, repository mutation, provider mutation, publication, recovery, and authority transfer remain non-transitive and independently grantable.
3. Role conflicts, stale authority snapshots, replay, target drift, lease loss, or CAS failure block before mutation or transfer.
4. Every mutation produces durable journal and receipt evidence sufficient for deterministic fail-closed reconstruction.
5. Interrupted work enters an explicit recovery state and resumes only through a fresh recovery grant; no automatic engine fallback exists.
6. Every consuming application uses this one foundation and cannot substitute a private journal, lease, grant, or recovery implementation.

## Definition of Done

All implementation, expected-red, review, exact-head test, adapter,
documentation, release, and external evidence gates remain pending.
