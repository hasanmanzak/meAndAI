# FEAT-0059 - Shared C# Operational Foundation and Portable Release Contract

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Proposed / development not authorized |
| Target version | 0.16.0 |
| Issue | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) |
| Pull request | Not created; development deferred |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) |
| Tests | [TEST-0191](test-cases.md#test-0191), [TEST-0192](test-cases.md#test-0192), and [TEST-0193](test-cases.md#test-0193) |

## Problem

The three planned operational applications need one typed contract authority
without becoming one all-capable executable or duplicating domain rules.

## Outcome

A shared C# foundation defines domain models, application use cases,
capability-scoped ports, deterministic results, portable framework-dependent
packaging, and an immutable release manifest that later applications can adopt
independently.

## Scope

- Solution/project boundaries and dependency rules.
- Shared domain, governance/transition contracts, infrastructure ports, result
  schemas, SDK pin, locked restore, and portable publish contract.
- Per-application ZIP identity and one release manifest with source commit,
  target framework, entry assembly, schema compatibility, and SHA-256.
- Runtime preflight contract for hosted and local execution.

## Non-goals

- Implementing governance, adoption, or update behavior.
- Native AOT, self-contained, single-file, ReadyToRun, RID-specific assets, or
  a unified all-capable executable.
- Moving production authority from PowerShell in this feature.

## Readiness evidence

- Domain and contracts: direction is fixed by [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md); exact public models, schema evolution, runtime version, and dependency inventory remain to be designed.
- Consumers and dependencies: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md) consume this feature.
- Prior art and recurrence: current PowerShell module, bundle, release, scenario ownership, and runtime-efficiency surfaces are canonical prior art; active recurrence entries must be inventoried before implementation.
- Verification approach: unit architecture tests, package/manifest contract tests, Windows/Linux execution, and capability-negative tests.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0286` <a name="risk-0286"></a> | Shared abstractions encode speculative or duplicated domain rules. | Feature owner / introduce only contracts required by the first vertical consumer and review dependency direction. |
| `RISK-0287` <a name="risk-0287"></a> | Portable artifacts depend on an unavailable or ambiguous runtime. | Release owner / explicit target, roll-forward, preflight, manifest, and Windows/Linux evidence. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | Not started; development not authorized | Later implementation directive required |
| Baseline run | Not run | Exact PowerShell/source and packaging baselines remain required |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0119` <a name="subf-0119"></a> | Solution boundaries and typed core contracts | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0191](test-cases.md#test-0191) / not started | Pending | Proposed |
| `SUBF-0120` <a name="subf-0120"></a> | Capability-scoped infrastructure ports and result schemas | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0192](test-cases.md#test-0192) / not started | Pending | Proposed |
| `SUBF-0121` <a name="subf-0121"></a> | Portable packaging and immutable manifest | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0193](test-cases.md#test-0193) / not started | Pending | Proposed |

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependencies: no new feature dependency; existing immutable release contracts are prior authority.

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [ ] Detailed contracts, dependency inventory, recurrence evidence, scenario-intent review, baselines, target version, and implementation authorization.

## Acceptance criteria

1. One solution builds shared components without allowing domain dependencies on infrastructure or CLI projects.
2. Governance, adoption, and update entry applications can receive different capability sets without duplicating canonical domain policy.
3. One portable ZIP per application runs unchanged on declared Windows and Linux hosts through `dotnet`.
4. The immutable manifest binds source, entry assembly, framework, schema compatibility, asset name, and digest.

## Definition of Done

All template DoD gates remain pending; this planning record is not implementation evidence.
