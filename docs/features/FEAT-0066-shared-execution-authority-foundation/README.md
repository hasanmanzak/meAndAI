# FEAT-0066 - Shared Execution-Authority Foundation

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | [SUBF-0145](#subf-0145) and [TEST-0212](test-cases.md#test-0212) are merged and exact-main hosted green through [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189) and [run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165); the [SUBF-0146](#subf-0146) Gate 1/2 packet is a records-only `DesignFreezeCandidate`, while implementation, feature DoD, release, and publication remain held |
| Target version | 0.17.0 |
| Issue | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) |
| Pull request | Merged [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187); activation [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189) |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md), [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md), and [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md) |
| Tests | [TEST-0212](test-cases.md#test-0212) and [TEST-0213](test-cases.md#test-0213) |

## Conditional implementation boundary

This record owns boundary 2 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
The current maintainer directive authorized the
[SUBF-0145](#subf-0145) [design freeze](subf-0145-authority-grant-activation-design.md) and,
after the exact
[AcceptedFrozenDesign gate](subf-0145-micro-delivery-plan.md#acceptedfrozendesign-gate),
only its four implementation packages. The initial gate and both narrow
design corrections passed exact-head hosted validation; the accepted reds were
never rerun. Authority snapshot, execution grant, publication envelope, and
extension activation now each have a separate focused `ReviewedLocalGreen`
commit. The immutable [EA-CONVERGE-01 checkpoint](subf-0145-package-evidence.md#ea-converge-01)
passed its records-only commit, one cohort push, and exact-head Ubuntu/Windows
gate. The final review-link cohort is merged at exact main
[`ff7d1f62641947e32c7b818a0d457fb1bc8f3296`](https://github.com/hasanmanzak/meAndAI/commit/ff7d1f62641947e32c7b818a0d457fb1bc8f3296)
through [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187) and
[run 32521885155](https://github.com/hasanmanzak/meAndAI/actions/runs/32521885155).
That closure does not retroactively replace the immutable package checkpoint.
Every implementation Fact remains subfeature-scoped with exact
[Subfeature=SUBF-0145](#subf-0145), and the atomic final-activation candidate
adds [Scenario=TEST-0212](test-cases.md#test-0212) to the same exact `20` Facts.
The neutral topology, executable owner, both stable filters, [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) oracle,
and `Passing` status are merged through [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189).
Its corrected exact-main commit
[`aab8307d578192fbdca96457ace013071f724ca2`](https://github.com/hasanmanzak/meAndAI/commit/aab8307d578192fbdca96457ace013071f724ca2)
passed [run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165)
on Ubuntu and Windows. Release, publication, consumer mutation, credentials,
authority transfer, and [SUBF-0146](#subf-0146) implementation remain
separately held. The [SUBF-0146](#subf-0146)
[design](subf-0146-journal-recovery-design.md),
[public API](subf-0146-public-api-contract.md),
[value/error contract](subf-0146-value-error-contract.md), and
[micro plan](subf-0146-micro-delivery-plan.md) are a records-only freeze
candidate; they confer no red or implementation authority.
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
- Successor selected-slice Gate 1/2 freeze candidate:
  [journal/recovery design](subf-0146-journal-recovery-design.md),
  [exact public API](subf-0146-public-api-contract.md),
  [exact values/errors](subf-0146-value-error-contract.md), and
  [conditional micro-delivery plan](subf-0146-micro-delivery-plan.md).

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0302` <a name="risk-0302"></a> | A stale, replayed, over-broad, or role-conflicting grant authorizes mutation or authority transfer. | Authority owner / exact subject-target-operation-generation binding, expiry/freshness, non-transitivity, separation rules, and atomic consumption evidence. |
| `RISK-0303` <a name="risk-0303"></a> | Journal loss, lease expiry, retention, corruption, or duplicated receipts reconstructs an ambiguous operation as complete. | Recovery owner / fencing, append-only integrity, explicit terminal receipts, fail-closed reconstruction, and separately authorized recovery. |

## Findings

| ID | Observation | Disposition |
| --- | --- | --- |
| `FIND-0465` <a name="find-0465"></a> | Exact activation head [`4679d15`](https://github.com/hasanmanzak/meAndAI/commit/4679d15ce597ae74c945259aa2da38551d263b87) passed Ubuntu in `20m37s`, while [Windows job 96928488451](https://github.com/hasanmanzak/meAndAI/actions/runs/32532961685/job/96928488451) in [run 32532961685](https://github.com/hasanmanzak/meAndAI/actions/runs/32532961685) was cancelled at the exact `55m0s` ceiling. Its PowerShell 5.1 Full route emitted successful quick-adoption (`773683ms`), instruction-graph (`373843ms`), protocol-governance (`836293ms`), and recurrence (`739ms`) evidence before nine discovered suites and all later package steps remained; no semantic failure was emitted. | Classification `VerifiedDefect`; disposition `Resolved`; severity `low`; confidence `high`; priority `p0`; owning layer `workflow finite bound` / [TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124). Windows `55 -> 65`, with Linux `30` and post-publication `5` unchanged, is merged in [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189); corrected exact-main [run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165) passed Ubuntu and Windows. Activation semantics, Scenario traits, owners, routes, canonical reds, and the held [TEST-0213](test-cases.md#test-0213)/[SUBF-0146](#subf-0146) implementation boundary remain unchanged. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | [SUBF-0145](#subf-0145) four packages and [TEST-0212](test-cases.md#test-0212) final activation exact-main hosted green; [SUBF-0146](#subf-0146) has no test code | The [activation design](subf-0145-test-0212-final-activation-freeze.md) owns exact Scenario `20/20`, neutral topology `1/1`, owner/workflow and [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) evidence; the [SUBF-0146](#subf-0146) [micro plan](subf-0146-micro-delivery-plan.md#package-matrix) freezes only future marker/FQN intent |
| Baseline run | Four canonical reds immutable; four bounded greens complete | Exact R identities and local package evidence are retained in the [package ledger](subf-0145-package-evidence.md) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0145` <a name="subf-0145"></a> | Authority snapshots, role separation, grants, activation CAS, and publication envelopes | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) | [TEST-0212](test-cases.md#test-0212) / exact `20` Scenario Facts | Package/cohort reviews `0/0/0`; merged [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187); activation merged [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189) | `Passing`; exact-main hosted green through [run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165) |
| `SUBF-0146` <a name="subf-0146"></a> | Leases, fences, journal, receipts, retention, reconstruction, and recovery grants | [#166](https://github.com/hasanmanzak/meAndAI/issues/166) | [TEST-0213](test-cases.md#test-0213) / four frozen future FQNs; no test code | Records-only Gate 1/2 candidate reviews pending | `DesignFreezeCandidate`; red and implementation held |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)
- Consumers: [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), and [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)

## Definition of Ready

- [x] Stable ID, linked issue, accepted decision, problem, outcome, scope, non-goals, consumers, risks, and reviewable decomposition.
- [x] Numbered planning scenarios and explicit WIP absence finding.
- [x] Exact authority/grant/activation schemas and store-port contracts for selected [SUBF-0145](#subf-0145).
- [x] Exact [TEST-0212](test-cases.md#test-0212) expected-red FQNs, replay, role, publication, and concurrent-CAS fixture plan.
- [x] Exact [TEST-0212](test-cases.md#test-0212) [final activation](subf-0145-test-0212-final-activation-freeze.md) inventory, neutral topology oracle, owner/workflow transform, allowlist, caps, and held boundary.
- [x] Narrow expected lease/fence and protected grant-store correction passed the exact `AcceptedFrozenDesign` local and hosted gates.
- [ ] [SUBF-0146](#subf-0146) journal, crash, corruption, retention,
  reconstruction, recovery schema, exact future FQNs/markers/allowlists/caps,
  and fixture intent have a complete [freeze candidate](subf-0146-journal-recovery-design.md);
  committed review, hosted validation, and maintainer acceptance remain before
  `AcceptedFrozenDesign`.
- [x] Gate 2 design review for the selected dependency-closed slice; accepted at
  [`8616aa1f4fe198b666b3abf5934b31e80d9498b8`](https://github.com/hasanmanzak/meAndAI/commit/8616aa1f4fe198b666b3abf5934b31e80d9498b8)
  with exact-head hosted [run 31810451377](https://github.com/hasanmanzak/meAndAI/actions/runs/31810451377).
- [x] The prior maintainer implementation directive is limited to
  [SUBF-0145](#subf-0145) and activated only after its accepted gate.
- [ ] [SUBF-0146](#subf-0146) has no implementation directive; one may be
  issued only after its separately committed `AcceptedFrozenDesign` exact-head
  hosted gate.

## Acceptance criteria

1. No mutating operation can begin without a fresh exact capability grant for its unchanged subject, target, operation, and generation.
2. Read, repository mutation, provider mutation, publication, recovery, and authority transfer remain non-transitive and independently grantable.
3. Role conflicts, stale authority snapshots, replay, target drift, lease loss, or CAS failure block before mutation or transfer.
4. Every mutation produces durable journal and receipt evidence sufficient for deterministic fail-closed reconstruction.
5. Interrupted work enters an explicit recovery state and resumes only through a fresh recovery grant; no automatic engine fallback exists.
6. Every consuming application uses this one foundation and cannot substitute a private journal, lease, grant, or recovery implementation.

## Definition of Done

All four selected implementation packages and their package-local reviews are
green, and the immutable [EA-CONVERGE-01 checkpoint](subf-0145-package-evidence.md#ea-converge-01)
is exact-head hosted green. The final review-link cohort is merged through
[PR #187](https://github.com/hasanmanzak/meAndAI/pull/187); exact-main
[`ff7d1f62641947e32c7b818a0d457fb1bc8f3296`](https://github.com/hasanmanzak/meAndAI/commit/ff7d1f62641947e32c7b818a0d457fb1bc8f3296)
passed [run 32521885155](https://github.com/hasanmanzak/meAndAI/actions/runs/32521885155).
[TEST-0212](test-cases.md#test-0212) is exact-main hosted green through
[PR #189](https://github.com/hasanmanzak/meAndAI/pull/189) and
[run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165).
[SUBF-0146](#subf-0146), adapters, feature DoD, release, publication,
consumer mutation, and external authority effects remain held.
The [SUBF-0146](#subf-0146) [design packet](subf-0146-journal-recovery-design.md) is only a
records candidate and does not satisfy the remaining implementation or feature
DoD.
