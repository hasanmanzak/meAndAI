# FEAT-0062 - Consumer Protocol Update CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed / development not authorized |
| Target version | 0.19.0 |
| Issue | [#157](https://github.com/hasanmanzak/meAndAI/issues/157) |
| Pull request | Not created; development deferred |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md), [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), and [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md) |
| Tests | [TEST-0202](test-cases.md#test-0202), [TEST-0203](test-cases.md#test-0203), and [TEST-0204](test-cases.md#test-0204) |

## Problem

The consumer update actor owns a mature deterministic migration and managed
proposal lifecycle in PowerShell that the maintainer cannot efficiently review.

## Outcome

A C# update application validates installed state, resolves the exact immutable
release-declared transition chain, produces and applies an exact plan, publishes
or resumes one managed proposal, and finalizes only a qualified merged result.

## Scope

- Installed-version, catalog, ledger, gitlink, managed asset, and release identity validation.
- Complete numeric descendant-chain resolution and exact immutable plan/apply.
- Existing updater recovery, proposal ownership, managed merge finalization,
  and current/no-op behavior.
- Differential evidence against applicable PowerShell authority.

## Non-goals

- Initial adoption or semantic strategy selection.
- Updating an ambiguous or invalid installation by inference.
- Consumer-local copies of shared engines or premature PowerShell retirement.

## Authority transition

- Installed PowerShell updaters remain authoritative for their immutable
  contract. A reviewed release-declared migration may install and verify the C#
  updater and move state from `PowerShellManaged` through
  `CSharpMigrationPending` to `CSharpManaged`.
- The transition state is explicit release/ledger evidence; the presence of a
  DLL, a successful `dotnet` preflight, or the absence of one script never
  infers authority.
- Read-only installed-state resolution and plan comparison may dual-run. Plan
  application, proposal publication, merge finalization, and recovery are
  single-engine operations with no automatic cross-engine fallback.
- A pre-cutover PowerShell updater may perform only the reviewed migration it
  can prove. After cutover, the C# updater owns later updates; unresolved or
  interrupted state becomes `RecoveryRequired` and fails closed.

## Readiness evidence

- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) and [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md).
- Prior art: updater workflow/adapter, migration catalogs, ledgers, target-bound recovery, proposal ownership, and managed finalization.
- Exact recurrence, scenario, release-schema, workflow projection, runtime, and baseline inventories remain required.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0292` <a name="risk-0292"></a> | The new actor reinterprets a historical release or migration schema. | Update owner / target release owns parsing and transition semantics; unknown or partial contracts fail closed. |
| `RISK-0293` <a name="risk-0293"></a> | Duplicate actors race or finalize the wrong proposal. | Lifecycle owner / retained lease, exact-head, single-owner event, and idempotent recovery contracts. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Development not authorized |
| Baseline run | Not run | Canonical update/full-recovery baselines required |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0129` <a name="subf-0129"></a> | Installed-state validation and transition resolution | [#157](https://github.com/hasanmanzak/meAndAI/issues/157) | [TEST-0202](test-cases.md#test-0202) / not started | Pending | Proposed |
| `SUBF-0130` <a name="subf-0130"></a> | Exact plan and contained apply | [#157](https://github.com/hasanmanzak/meAndAI/issues/157) | [TEST-0203](test-cases.md#test-0203) / not started | Pending | Proposed |
| `SUBF-0131` <a name="subf-0131"></a> | Proposal lifecycle, finalization, recovery, and equivalence | [#157](https://github.com/hasanmanzak/meAndAI/issues/157) | [TEST-0204](test-cases.md#test-0204) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependencies: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md) and [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [ ] Complete transition/lifecycle inventory, recurrence evidence, runtime/workflow contract, baselines, target version, and implementation authorization.

## Acceptance criteria

1. Only a valid installed state and complete compatible descendant chain can produce a plan.
2. Plan and apply preserve exact release, source, graph, marker, schema, managed-asset, and ledger identity.
3. One managed proposal lifecycle is created or resumed and only a qualified exact merge can finalize it.
4. Current state is an idempotent no-op; ambiguity and unsupported history fail closed.
5. Authority transfers only after canonical PowerShell scenario equivalence and immutable release evidence.

## Definition of Done

All implementation, review, CI, migration, documentation, and release gates remain pending.
