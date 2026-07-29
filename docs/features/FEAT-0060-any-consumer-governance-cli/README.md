# FEAT-0060 - Any-Consumer Governance CLI

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Architecture hold; exact draft work preserved; parent incomplete and implementation stopped |
| Target version | 0.17.0 |
| Issue | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) |
| Pull request | [#160](https://github.com/hasanmanzak/meAndAI/pull/160) (draft; frozen at a preservation checkpoint) |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) and proposed [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Tests | [TEST-0194](test-cases.md#test-0194), [TEST-0195](test-cases.md#test-0195), and [TEST-0196](test-cases.md#test-0196) |

## Architecture hold and preservation

Implementation is stopped by
[TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164).
The exact draft checkpoint
[`1873c98638ba4960734aadb188eb8c8d70b4bc52`](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52)
preserves all current work without granting default-branch or production
authority. Four of seven bounded subfeatures have exact draft-branch
implementation evidence; the parent feature was not completed, merged,
released, or granted authority, and three subfeatures remain incomplete.

This CLI-shaped record remains historical input. Its prospective ownership and
carry-forward rules are defined by the
[new architecture](../../architecture/protocol-governance-and-execution/README.md)
and its [transition register](../../architecture/protocol-governance-and-execution/transition-register.md).
No implementation extraction is authorized yet.

## Problem

Governance validation is difficult for the maintainer to review and is coupled
to PowerShell runtime behavior even when the governed evidence is technology
neutral.

## Outcome

A read-only C# application validates meAndAI itself and arbitrary consumers
through explicit profiles, structured results, and one canonical governance
engine without repository or GitHub mutation authority.

## Scope

- Repository discovery, governance profile selection, structural and semantic
  validation, instruction graph inspection, scenario ownership, links, ledgers,
  markers, release contracts, and machine-readable reports.
- Explicit `protocol-authority` and `consumer` profiles derived from canonical
  contracts rather than named-project allowlists.
- Differential evidence against applicable PowerShell governance authority.

## Non-goals

- Automatic repair, adoption, update, GitHub publication, or mutation.
- Consumer-specific duplicated validators.
- Retirement of PowerShell governance before equivalence and migration proof.

## Authority transition

- [SUBF-0122](#subf-0122) and [SUBF-0123](#subf-0123) run C# only as a
  read-only shadow against one captured repository input. Their output cannot
  replace the PowerShell result or authorize mutation.
- [SUBF-0124](#subf-0124) maps every applicable PowerShell-owned scenario and
  declared variant to equivalent or explicitly approved stronger C# evidence.
  Any unmapped or divergent result keeps `PowerShellAuthority`.
- An immutable C# release may become `CSharpReleasedNonAuthoritative` after the
  differential gate. Consumer authority changes only through the explicit
  migration owned by [FEAT-0063](../FEAT-0063-consumer-migration-powershell-retirement/README.md).
- Read-only dual execution is allowed; governance never gains a repair or
  mutation fallback. PowerShell validation contracts remain live for the
  supported scope until that migration and dependency proof complete.

## Readiness evidence

- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md).
- Prior art: `tests/protocol.tests.ps1`, capability suites, scenario ownership, and recurrence validation remain canonical until transferred.
- Recurrence and exact scenario mapping remain required before implementation.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0288` <a name="risk-0288"></a> | A C# validator reports green while omitting PowerShell-owned semantics. | Governance owner / complete scenario inventory, differential fixtures, and fail-closed unmapped contract handling. |
| `RISK-0289` <a name="risk-0289"></a> | Profiles become named-consumer policy forks. | Governance owner / capability-derived profiles and project-neutral fixtures. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started | Development not authorized |
| Baseline run | Not run | Current canonical suite baseline required before implementation |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0122` <a name="subf-0122"></a> | Read-only repository snapshot and profiles | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0194](test-cases.md#test-0194) / not started | Pending | Proposed |
| `SUBF-0123` <a name="subf-0123"></a> | Governance rules and structured report | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0195](test-cases.md#test-0195) / not started | Pending | Proposed |
| `SUBF-0124` <a name="subf-0124"></a> | Differential authority transfer evidence | [#155](https://github.com/hasanmanzak/meAndAI/issues/155) | [TEST-0196](test-cases.md#test-0196) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependency: [FEAT-0059](../FEAT-0059-csharp-operational-foundation/README.md)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, non-goals, initial scenarios, and risks.
- [ ] Exact rule inventory, profile contract, recurrence evidence, sibling-intent review, baseline, target version, and development authorization.

## Acceptance criteria

1. The governance application has no repository or GitHub mutation capability.
2. The same engine validates meAndAI and arbitrary consumers through explicit capability profiles.
3. Every transferred canonical scenario has equivalent or stronger executable evidence and unmapped authority blocks transfer.
4. Reports are deterministic, typed, redacted, and useful to local and hosted callers.

## Definition of Done

All implementation, review, CI, migration, documentation, and release gates remain pending.
