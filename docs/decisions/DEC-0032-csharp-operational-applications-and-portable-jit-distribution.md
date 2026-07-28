# DEC-0032 - Use Separate C# Operational Applications with Portable JIT Distribution

- Classification: Decision
- Status: Accepted
- Date: 2026-07-27
- Decision owners: Maintainer and meAndAI architecture owner
- Related epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Related features: [FEAT-0059](../features/FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../features/FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../features/FEAT-0062-consumer-protocol-update-cli/README.md), [FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md), and [FEAT-0063](../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
- Related decisions: [DEC-0018](DEC-0018-release-declared-consumer-migrations.md), [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md), [DEC-0023](DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md), [DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md), [DEC-0033](DEC-0033-specification-first-csharp-governance.md), and [DEC-0034](DEC-0034-bounded-reusable-governance-catalog.md)
- Narrow sequencing supersession: [DEC-0033](DEC-0033-specification-first-csharp-governance.md) supersedes only the requirement to complete exhaustive PowerShell differential evidence before bounded `CSharpShadow` implementation or an explicitly non-authoritative governance package; this decision's application, JIT distribution, and authority architecture remain active

## Context

PowerShell is currently both implementation and compatibility authority for
governance, adoption, and update operations. The maintainer can review C# much
more effectively, and the operational domain now benefits from typed immutable
models, explicit state transitions, dependency direction, and capability-based
authorization. The applications must remain usable on Windows and Linux without
creating a platform-specific release matrix.

## Decision

Use one C# solution and shared source foundation with three separately
publishable applications: governance, adoption, and consumer update. Shared
domain, governance, transition, release, and infrastructure contracts have one
canonical owner; executable boundaries keep actor authority distinct.

Publish each application as one portable, framework-dependent ZIP with
`UseAppHost=false`, executed as `dotnet <entry-assembly>.dll`. Use ordinary JIT.
Do not require Native AOT, self-contained, ReadyToRun, single-file, or RID-
specific assets unless later measured evidence and a new decision justify an
exception.

Source build and test pin the SDK through repository-owned configuration and a
pinned setup action where required. Released consumer execution requires only
the declared compatible runtime. Hosted-runner preinstallation is an
optimization, not immutable compatibility authority; runtime preflight and a
bounded setup/failure policy belong to the consuming workflow contract.

Governance is read-only. Adoption and update share a transition engine but use
different application use cases and authorization profiles. Assessment and
planning cannot mutate; apply and publish are separately authorized. Existing
PowerShell authority remains until the relevant feature proves equivalence and
a later migration feature transfers authority.

### Incremental authority transition

Completing a C# feature does not automatically disable its PowerShell
counterpart. Each operational capability moves through these explicit states:

1. `PowerShellAuthority`: the supported PowerShell path remains the production
   and compatibility authority.
2. `CSharpShadow`: C# may evaluate the same immutable input read-only and
   produce differential evidence; PowerShell still owns the result.
3. `CSharpReleasedNonAuthoritative`: an immutable C# artifact exists and may be
   invoked explicitly, but supported consumers have not transferred authority.
4. `CSharpPrimaryWithRecovery`: an explicitly reviewed migration transfers the
   supported operation to the C# release while a bounded legacy recovery route
   may remain.
5. `CSharpOnly`: supported normal and recovery paths use C# and executable
   PowerShell authority is eligible for final retirement.

Read-only actors may run both implementations against the same captured input
for comparison. Mutating actors are exclusive: one operation is owned by
exactly one engine, and PowerShell and C# must never both apply or publish the
same plan. A failed C# mutation does not automatically fall back to PowerShell;
it enters an explicit recovery state and fails closed until the owning recovery
contract selects one engine.

Consumer authority is recorded as one of `PowerShellManaged`,
`CSharpMigrationPending`, `CSharpManaged`, `RecoveryRequired`, or `Unsupported`.
File presence, runtime availability, or successful process startup alone cannot
infer or change that state.

The feature sequence owns distinct gates:

- [FEAT-0059](../features/FEAT-0059-csharp-operational-foundation/README.md)
  creates only the shared foundation and portable release contract; no
  PowerShell authority changes.
- [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md)
  may shadow read-only governance and qualify an immutable C# release through
  complete differential evidence.
- [FEAT-0061](../features/FEAT-0061-consumer-adoption-cli/README.md) and
  [FEAT-0062](../features/FEAT-0062-consumer-protocol-update-cli/README.md)
  may dual-run only their read-only stages; apply, publish, recovery, and
  finalization remain single-engine operations.
- [FEAT-0063](../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
  owns consumer-state migration, explicit authority cutover, dependency proof,
  and final retirement.

Authority retirement, compatibility retirement, and source retirement are
separate decisions. Historical tags, release assets, and evidence remain
immutable even after their executable route is no longer supported.

### Subsequent bounded scope allocation

[DEC-0034](DEC-0034-bounded-reusable-governance-catalog.md) applies the
specification-first sequencing accepted in
[DEC-0033](DEC-0033-specification-first-csharp-governance.md) by bounding the
first FEAT-0060 release catalog and assigning full `candidate` snapshot
support, remaining governance coverage, and equivalence qualification to
[FEAT-0064](../features/FEAT-0064-governance-coverage-equivalence/README.md).
DEC-0033 remains authoritative, and this later allocation does not alter this
decision's application separation, portable JIT distribution, or authority
state architecture.

## Consequences

- Maintainers gain typed, directly readable operational behavior and tests.
- One application artifact can run on supported Windows and Linux hosts.
- Hosts must provide a compatible .NET runtime or follow the declared bounded
  setup route.
- Separate applications may duplicate packaging metadata but preserve least
  authority and independent delivery.
- JIT startup cost is accepted unless measurement later proves it material.
- PowerShell 5.1/7 tests remain mandatory only while supported production or
  migration paths still execute PowerShell behavior.
- Every feature still requires its own complete Definition of Ready and explicit
  maintainer authorization before implementation or authority transfer.

## Alternatives considered

- Retain PowerShell as production authority: rejected as the target architecture
  because maintainer readability and ownership remain weak.
- One all-capable executable: rejected initially because it obscures mutation
  authority and distributes capabilities consumers do not need.
- Native AOT or self-contained RID assets: rejected as default because the
  platform matrix and release weight provide no currently measured necessity.
- Platform-specific apphost executables: rejected because portable DLL launch
  through `dotnet` provides the desired single-artifact contract.

## Review condition

Review when runtime availability, JIT startup, offline adoption, artifact
integrity, or consumer compatibility evidence invalidates the portable
framework-dependent contract, or before introducing a unified executable,
Native AOT, self-contained, single-file, or RID-specific distribution.
