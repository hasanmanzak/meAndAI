# FEAT-0061 - Consumer Adoption CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed / development not authorized |
| Target version | 0.18.0 |
| Issue | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) |
| Pull request | Not created; development deferred |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md), and [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0197](test-cases.md#test-0197), [TEST-0198](test-cases.md#test-0198), [TEST-0200](test-cases.md#test-0200), and [TEST-0201](test-cases.md#test-0201) |

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

## Non-goals

- Silent strategy selection for existing governance evidence.
- Consumer-specific policy or mutation outside an authorized repository.
- Replacing the C# update application or retiring PowerShell during this feature.

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

- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) and [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md).
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
| `SUBF-0126` <a name="subf-0126"></a> | Explicit strategy and immutable plan | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0198](test-cases.md#test-0198) / not started | Pending | Proposed |
| `SUBF-0127` <a name="subf-0127"></a> | Contained apply and closure | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0200](test-cases.md#test-0200) / not started | Pending | Proposed |
| `SUBF-0128` <a name="subf-0128"></a> | Publication, recovery, and equivalence | [#156](https://github.com/hasanmanzak/meAndAI/issues/156) | [TEST-0201](test-cases.md#test-0201) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) and [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [ ] Full contract/sibling inventory, recurrence evidence, credential and runtime contracts, baselines, target version, and implementation authorization.

## Acceptance criteria

1. Discovery, assessment, and planning are provably read-only.
2. Existing protocol evidence requires an explicit strategy and protected authority still requires maintainer review.
3. Apply accepts only an exact verified plan for the unchanged source snapshot and remains contained and recoverable.
4. Publication uses exact qualified results and preserves one owned issue/branch/draft lifecycle.
5. Authority transfers only after canonical PowerShell scenario equivalence and immutable release evidence.

## Definition of Done

All implementation, review, CI, migration, documentation, and release gates remain pending.
