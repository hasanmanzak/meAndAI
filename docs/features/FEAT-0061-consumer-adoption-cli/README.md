# FEAT-0061 - Consumer Adoption Application

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed under accepted architecture; implementation not authorized |
| Target version | 0.18.0 |
| Issue | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) |
| Pull request | Not created; development deferred |
| Decisions | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md), partially superseded [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md), and [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0197](test-cases.md#test-0197), [TEST-0198](test-cases.md#test-0198), [TEST-0200](test-cases.md#test-0200), and [TEST-0201](test-cases.md#test-0201) |

## Accepted architecture rescope and implementation hold

This record now owns boundary 4 in the accepted
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#1-capability-ownership).
Its historical directory slug is retained to avoid destructive record moves;
CLI syntax is only an optional host adapter and does not define the product.
Existing scenario identities remain planned and receive no passing status by
rescope. No implementation, mutation, publication, or consumer operation is
authorized.

## Problem

Consumer adoption combines discovery, semantic assessment, strategy, contained
mutation, credentials, GitHub proposal ownership, recovery, and closure in a
PowerShell implementation that is difficult for the maintainer to own.

## Outcome

A C# adoption application exposes separately authorized `discover`, `assess`,
`plan`, `apply`, and `publish` stages while preserving exact target release,
explicit strategy, protected authority, containment, recovery, and proposal
lifecycle contracts.

## Scope

- Project-neutral repository and instruction-graph discovery.
- Explicit `FreshAdoption`, `FullMigration`, `HybridReconciliation`,
  acknowledged `CleanStart`, and `Abort` handling.
- Immutable assessment and plan identities; exact-head revalidation before apply.
- Contained mutation, closure validation, and separately authorized GitHub
  issue/branch/draft-PR publication and recovery.
- Direct or provider exact-target closure, durable receipts, finalization, and
  recovery through the shared execution-authority foundation.

## Non-goals

- Silent strategy selection for existing governance evidence.
- Consumer-specific policy or mutation outside an authorized repository.
- Replacing the C# update application or retiring PowerShell during this feature.
- Reimplementing shared conformance, acquisition, grant, journal, lease,
  publication, or release-finalization behavior.

## Authority transition

- `discover`, `assess`, and `plan` may run in read-only shadow mode against the
  same captured base and immutable target evidence. Differential comparison
  cannot itself authorize `apply` or `publish`.
- A mutation attempt is single-engine: exactly one of PowerShell or C# owns the
  exact plan, repository write, branch, issue, and pull-request lifecycle. The
  two engines never apply or publish the same adoption operation.
- A failed C# mutation enters `RecoveryRequired`; it does not automatically
  invoke PowerShell. Recovery must revalidate the durable boundary and select
  one explicitly supported engine before any later write.
- This feature may qualify an immutable C# adoption release, but existing
  consumer authority remains `PowerShellManaged` until the reviewed migration
  in [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md)
  records `CSharpManaged`.

## Readiness evidence

- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md), [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md), and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
- Prior art: quick-adoption launcher/module, instruction-graph discovery, proposal ownership, capability review, and completed-historical classification.
- Exact recurrence entries, scenario mapping, credential/runtime bootstrap, GitHub authority, and baselines remain required.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0290` <a name="risk-0290"></a> | Staged commands permit assessment or planning to mutate. | Adoption owner / capability-separated ports plus before/after repository and remote identity evidence. |
| `RISK-0291` <a name="risk-0291"></a> | C# behavior diverges on protected authority, ambiguity, credentials, or recovery. | Adoption owner / full canonical scenario mapping and retained real Git/GitHub/security vertical slices. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Development not authorized |
| Baseline run | Not run | Canonical PowerShell adoption baseline required |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0125` <a name="subf-0125"></a> | Read-only discovery and assessment | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0197](test-cases.md#test-0197) / not started | Pending | Proposed |
| `SUBF-0126` <a name="subf-0126"></a> | Explicit strategy and sealed immutable plan | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0198](test-cases.md#test-0198) / not started | Pending | Proposed |
| `SUBF-0127` <a name="subf-0127"></a> | Separately granted contained apply and interruption recovery | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0200](test-cases.md#test-0200) / not started | Pending | Proposed |
| `SUBF-0128` <a name="subf-0128"></a> | Direct/provider closure, publication, finalization, and recovery | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0201](test-cases.md#test-0201) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
- Historical planning parent: [EPIC-0001 / issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0065](../FEAT-0065-shared-executable-conformance-runtime/README.md), [FEAT-0066](../FEAT-0066-shared-execution-authority-foundation/README.md), and [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
- Immutable publication dependency: [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [ ] Full application contract/sibling inventory, recurrence evidence, credential/runtime/grant contracts, expected-red baselines, Gate 2 design review, and separate implementation authorization.

## Acceptance criteria

1. Discovery, assessment, and planning are provably read-only.
2. Existing protocol evidence requires an explicit strategy and protected authority still requires maintainer review.
3. Apply accepts only an exact verified plan for the unchanged source snapshot and remains contained and recoverable.
4. Direct or provider closure, publication, and finalization use exact qualified
   results, the shared authority/journal foundation, and one owned
   issue/branch/draft lifecycle.
5. This feature produces compatibility evidence but does not itself transfer
   consumer authority or retire PowerShell.

## Definition of Done

All implementation, review, CI, migration, documentation, and release gates remain pending.
