# 2026-07-27 - C# operational platform planning

## Directive and boundary

The maintainer approved creation of planning records for replacing the
PowerShell-owned governance, consumer adoption, and consumer update engines with
readable C# applications. Development, solution/project creation, workflow
changes, consumer mutation, PowerShell deletion, and migration are explicitly
deferred until later directives.

## Canonical records

- [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- [DEC-0032](../../../docs/decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
- [FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
  / [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154)
- [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
  / [issue #155](https://github.com/hasanmanzak/meAndAI/issues/155)
- [FEAT-0061](../../../docs/features/FEAT-0061-consumer-adoption-cli/README.md)
  / [issue #156](https://github.com/hasanmanzak/meAndAI/issues/156)
- [FEAT-0062](../../../docs/features/FEAT-0062-consumer-protocol-update-cli/README.md)
  / [issue #157](https://github.com/hasanmanzak/meAndAI/issues/157)
- [FEAT-0063](../../../docs/features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
  / [issue #158](https://github.com/hasanmanzak/meAndAI/issues/158)

## Agreed architecture

Use one C# solution with shared canonical domain/governance/transition/release
components and three separately publishable, capability-bounded applications:
governance, adoption, and consumer update. Distribute one portable framework-
dependent ZIP per application, execute through `dotnet`, and use ordinary JIT.
Native AOT, self-contained, single-file, ReadyToRun, and RID-specific assets are
not defaults. Governance remains read-only; assessment/planning cannot mutate;
apply/publish require separate authority.

PowerShell remains production authority until feature-level differential and
immutable release evidence transfers it. PS 5.1/7 validation may be removed only
after supported dependency inventory and consumer migration prove it obsolete.
