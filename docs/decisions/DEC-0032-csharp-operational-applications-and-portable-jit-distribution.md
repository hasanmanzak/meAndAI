# DEC-0032 - Use Separate C# Operational Applications with Portable JIT Distribution

- Classification: Decision
- Status: Accepted / implementation deferred
- Date: 2026-07-27
- Decision owners: Maintainer and meAndAI architecture owner
- Related epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Related features: [FEAT-0059](../features/FEAT-0059-csharp-operational-foundation/README.md), [FEAT-0060](../features/FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../features/FEAT-0061-consumer-adoption-cli/README.md), [FEAT-0062](../features/FEAT-0062-consumer-protocol-update-cli/README.md), and [FEAT-0063](../features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
- Related decisions: [DEC-0018](DEC-0018-release-declared-consumer-migrations.md), [DEC-0021](DEC-0021-explicit-initial-adoption-strategy.md), [DEC-0023](DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md), and [DEC-0028](DEC-0028-upstream-owned-reusable-corrections.md)

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
- This decision authorizes architecture records, not implementation.

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
