# FEAT-0063 - Consumer Migration and PowerShell Retirement

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed / development not authorized |
| Target version | 0.20.0 |
| Issue | [#158](https://github.com/hasanmanzak/meAndAI/issues/158) |
| Pull request | Not created; development deferred |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) and [DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md) |
| Tests | [TEST-0205](test-cases.md#test-0205), [TEST-0206](test-cases.md#test-0206), and [TEST-0207](test-cases.md#test-0207) |

## Problem

Even after C# applications exist, supported consumers and recovery paths may
remain bound to PowerShell assets and PS 5.1/7 compatibility. Removing them
without an exact dependency inventory and recoverable migration would strand
consumers or erase required evidence.

## Outcome

Supported consumers move through an immutable, bounded migration to released
C# applications. PowerShell production authority and its PS 5.1/7 validation
matrix are retired only after executable evidence proves that no supported
normal, recovery, historical, or publication path depends on them.

## Scope

- Supported consumer-state and PowerShell dependency inventory.
- Release-declared migration to verified portable application artifacts.
- Mixed-version recovery, rollback/forward recovery, and compatibility window.
- Documentation, workflow, release asset, capability, test, fixture, and
  recurrence reconciliation after authority transfer.
- Evidence-gated deletion/retirement in a final independently reviewed slice.

## Non-goals

- Deleting PowerShell when this feature is merely planned.
- Migrating consumers before immutable predecessor releases exist.
- Preserving unsupported states by silent inference or duplicating C# engines
  locally in consumers.
- Keeping PS 5.1/7 tests after executable evidence proves they have no supported
  production or migration contract.

## Authority-state migration and retirement gates

Every supported consumer is classified from immutable release, workflow,
ledger, and repository evidence as exactly one of:

- `PowerShellManaged`: PowerShell remains the sole mutating authority.
- `CSharpMigrationPending`: one reviewed, target-bound migration is in progress;
  only its declared engine may mutate.
- `CSharpManaged`: the verified C# release owns normal operations.
- `RecoveryRequired`: durable evidence is incomplete or interrupted; normal
  operation and automatic fallback are blocked.
- `Unsupported`: no reviewed compatible path exists and no inference is made.

[SUBF-0132](#subf-0132) inventories and migrates supported states. It may keep
a bounded legacy recovery route after `CSharpManaged`, but each recovery event
still chooses one engine before mutation. [SUBF-0133](#subf-0133) separately
proves three retirements:

1. authority retirement: no supported operation selects PowerShell;
2. compatibility retirement: no supported normal or recovery path requires PS
   5.1/7 execution evidence; and
3. source retirement: live scripts, workflow branches, tests, and fixtures may
   be removed without deleting immutable historical tags, assets, or forensic
   records.

These gates are ordered. Completion of any predecessor C# feature, successful
runtime installation, or source-file presence cannot skip consumer migration
or authorize PowerShell deletion.

[DEC-0033](../../decisions/DEC-0033-specification-first-csharp-governance.md)
allows bounded clean-room governance implementation and an explicitly
non-authoritative package before exhaustive PowerShell mapping. It does not
weaken this feature's cutover boundary. Before governance equivalence,
authority transfer, compatibility retirement, or source retirement, the
complete [governance differential ledger](../FEAT-0060-any-consumer-governance-cli/differential-ledger-analysis.md)
and variant-level [rule/profile/evidence-source matrix](../FEAT-0060-any-consumer-governance-cli/rule-profile-matrix-analysis.md)
must cover every applicable supported row; missing or divergent evidence fails
closed.

## Readiness evidence

- Blocking dependencies: completed immutable releases for [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md), plus complete applicable equivalence ledgers and matrices before any cutover.
- Prior art: release-declared migrations, target-bound recovery, instruction graph closure, managed workflow projection, and exact consumer ledger.
- Live supported-consumer inventory requires separate authorization and fresh evidence before implementation.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0294` <a name="risk-0294"></a> | A dormant or recovery-only consumer dependency is missed. | Migration owner / discover normal, recovery, historical, publication, and bootstrap paths from immutable and live evidence. |
| `RISK-0295` <a name="risk-0295"></a> | Deletion removes forensic or rollback evidence. | Release owner / distinguish executable authority from retained historical records and preserve immutable recovery evidence. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Development and consumer mutation not authorized |
| Baseline run | Not run | Predecessor releases and fresh consumer inventory do not yet exist |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0132` <a name="subf-0132"></a> | Consumer inventory and immutable migration | [#158](https://github.com/hasanmanzak/meAndAI/issues/158) | [TEST-0205](test-cases.md#test-0205), [TEST-0206](test-cases.md#test-0206) / not started | Pending | Blocked by predecessor releases |
| `SUBF-0133` <a name="subf-0133"></a> | Dependency-proof retirement and validation contraction | [#158](https://github.com/hasanmanzak/meAndAI/issues/158) | [TEST-0207](test-cases.md#test-0207) / not started | Pending | Blocked by migration closure |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Blocking dependencies: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [ ] Immutable predecessor releases, complete applicable differential
  ledgers and rule/profile/evidence-source matrices, supported-consumer
  authority, fresh inventory, recurrence evidence, migration design,
  baselines, target version, and explicit migration/deletion authorization.

## Acceptance criteria

1. Every supported state has one immutable, verified, recoverable path to the C# applications or fails closed as unsupported with explicit ownership.
2. Migrated consumers use no consumer-local copy of common engines and retain exact release/ledger evidence.
3. Normal, recovery, historical, bootstrap, publication, and finalization inventories prove no supported production dependency on retired PowerShell assets.
4. PowerShell production code and PS 5.1/7 validation are removed only in the final authorized slice without deleting historical evidence.
5. Post-retirement governance, adoption, update, release, and consumer simulations pass through C# authority.

## Definition of Done

All implementation, consumer mutation, deletion, review, CI, documentation, and release gates remain pending.
