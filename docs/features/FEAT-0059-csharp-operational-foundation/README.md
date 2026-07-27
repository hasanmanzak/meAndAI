# FEAT-0059 - Shared C# Operational Foundation and Portable Release Contract

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | In development / [SUBF-0119](#subf-0119) complete; later slices gated |
| Target version | 0.16.0 |
| Issue | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) |
| Pull request | Draft [#159](https://github.com/hasanmanzak/meAndAI/pull/159) |
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

## Runtime and build contract

- Target framework: `net10.0`, ordinary JIT, framework-dependent deployment.
- SDK selection: `global.json` selects the `10.0.3xx` feature band and permits
  only a later servicing patch in that band; hosted validation installs the
  current reviewed `10.0.302` SDK explicitly instead of depending on mutable
  runner-image contents.
- Runtime selection: released applications require a supported .NET 10 runtime
  at the latest servicing level accepted by the release preflight. Runtime
  absence or incompatibility fails before application work; installation is a
  separately declared host/workflow action, never an implicit application
  mutation.
- Source builds enable nullable analysis, implicit usings, deterministic output,
  warnings as errors, package lock files, and locked restore in authoritative
  validation.
- Production projects take no third-party package dependency in this feature.
  The test project uses only exact centrally pinned test packages.
- Executables added by later slices use `UseAppHost=false` and are invoked as
  `dotnet <entry-assembly>.dll`; no RID participates in package identity.

## [SUBF-0119](#subf-0119) domain and dependency contract

The first slice introduces only typed authority declarations and dependency
rules needed by the three future entry applications:

- Application identities are exactly `governance`, `adoption`, and
  `consumer-update`.
- Operation stages are application-owned identifiers. Governance initially
  declares `validate`; adoption declares `discover`, `assess`, `plan`, `apply`,
  and `publish`; consumer update declares `discover`, `plan`, `apply`,
  `publish`, and `finalize`.
- Capabilities are exactly `repository.read`, `repository.mutate`,
  `provider.read`, and `provider.mutate`. A mutation capability requires the
  corresponding read capability in the same immutable grant.
- Governance grants contain no mutation capability. Discovery, assessment, and
  planning grants contain no mutation capability. The typed catalog returns
  one exact immutable grant or fails for an unknown application/stage; it never
  widens a grant by fallback.
- Identifiers are non-null closed value objects. Capability collections are
  duplicate-free, ordinally ordered, and exposed read-only. Invalid identifiers,
  duplicate capabilities, missing read prerequisites, and unknown catalog
  lookups fail with typed argument/range errors before any I/O.
- [SUBF-0119](#subf-0119) performs no repository, process, network, Git, GitHub,
  packaging, or consumer operation. Capability-scoped ports and result schemas
  remain [SUBF-0120](#subf-0120); executable and package composition remains
  [SUBF-0121](#subf-0121).

The planned production dependency graph is one-way:

`Domain <- Application <- Infrastructure <- capability-bounded entry app`.

`Domain` has no project or infrastructure dependency. `Application` may depend
only on `Domain`. Infrastructure and entry projects are introduced only in the
slice that exercises them. Test projects may depend inward on the production
projects but never become a production dependency.

## Readiness evidence

- Domain and contracts: [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
  and the contracts above fix application/stage/capability meaning, dependency
  direction, invalid-state behavior, runtime line, and slice ownership. Result,
  port, manifest, and schema-evolution details remain intentionally owned by
  their later subfeatures.
- Consumers and dependencies: [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md), [FEAT-0061](../FEAT-0061-consumer-adoption-cli/README.md), and [FEAT-0062](../FEAT-0062-consumer-protocol-update-cli/README.md) consume this feature.
- Prior art and siblings: the repository currently has no C# solution, project,
  or source file. PowerShell remains the behavior authority rather than a
  compiled-contract sibling. Nearest scenario [TEST-0116](../FEAT-0024-v0101-parallel-windows-validation/test-cases.md#test-0116)
  owns Windows validation composition; [TEST-0191](test-cases.md#test-0191) is
  `Distinct` because it exercises compiled dependency and application-authority
  boundaries.
- Recurrence: no active entry matches the [SUBF-0119](#subf-0119) typed solution
  boundary; result `None`. [SUBF-0121](#subf-0121) is separately routed by the
  active [declarative bundle-path entry](../../../.ai/memory/project.md#runtime-bundle-path-is-inferred-as-a-repository-source-path),
  which forbids inferred archive-to-source mapping. Candidate governance
  packets must also follow the active [committed-HEAD graph entry](../../../.ai/memory/project.md#untracked-governance-packet-is-absent-from-the-head-self-consumer-graph)
  before final exact-tree evidence.
- Baseline: immutable [v0.15.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.6)
  at [merge commit `5321f1f1aa5966114c69b46bf6ed9191df109e6b`](https://github.com/hasanmanzak/meAndAI/commit/5321f1f1aa5966114c69b46bf6ed9191df109e6b)
  is the exact predecessor. The 2026-07-27 local host exposes SDK `10.0.301`
  and runtime `10.0.9`; source inventory proves no pre-existing `.sln`, `.slnx`,
  `.csproj`, or `.cs` authority.
- Verification approach: write [TEST-0191](test-cases.md#test-0191) first;
  demonstrate the intended missing-contract failure; implement only Domain and
  Application projects; run the focused .NET test project, solution build,
  locked restore, protocol structure validation, and fresh-diff self-review.
  Package/manifest and cross-platform execution remain later scenario gates.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0286` <a name="risk-0286"></a> | Shared abstractions encode speculative or duplicated domain rules. | Feature owner / introduce only contracts required by the first vertical consumer and review dependency direction. |
| `RISK-0287` <a name="risk-0287"></a> | Portable artifacts depend on an unavailable or ambiguous runtime. | Release owner / explicit target, roll-forward, preflight, manifest, and Windows/Linux evidence. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | [SUBF-0119](#subf-0119) passing locally and on exact-head Ubuntu/Windows hosts | [TEST-0191](test-cases.md#test-0191) |
| Baseline run | Complete for first slice | Exact v0.15.6 predecessor, absent C# source graph, and local .NET inventory recorded above |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0119` <a name="subf-0119"></a> | Solution boundaries and typed core contracts | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0191](test-cases.md#test-0191) / 17 of 17 local Release tests plus exact-head [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410350) and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410352) jobs passing | Fresh-diff review complete; parameter-name, closed-identity, serializable-theory-data, and analyzer findings closed; zero unresolved `Blocking` findings | Complete |
| `SUBF-0120` <a name="subf-0120"></a> | Capability-scoped infrastructure ports and result schemas | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0192](test-cases.md#test-0192) / not started | Pending | Proposed |
| `SUBF-0121` <a name="subf-0121"></a> | Portable packaging and immutable manifest | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0193](test-cases.md#test-0193) / not started | Pending | Proposed |

## [SUBF-0119](#subf-0119) development checkpoint

Progress is measured against five independently observable delivery gates:

1. Definition of Ready and explicit authorization: complete.
2. Tests-first missing-contract failure: complete.
3. Minimal typed implementation and focused green run: complete.
4. Local self-review, locked restore, analyzer/format verification, and candidate-
   tree protocol validation: complete.
5. Exact committed-tree validation, remote draft checkpoint, and final-head
   Ubuntu/Windows hosted evidence: complete.

The 2026-07-27 closure is therefore five of five gates, or 100% of
[SUBF-0119](#subf-0119). Feature completion is one of three completed
subfeatures, or 33%. [SUBF-0120](#subf-0120) and [SUBF-0121](#subf-0121)
remain unauthorized; no estimate or implementation authority is inferred for
them.

Observed hosted timings are evidence, not workflow service-level objectives:

| Host | .NET setup | Locked restore | C# tests | Full required job |
| --- | ---: | ---: | ---: | ---: |
| Ubuntu | 2 s | 2 s | 7 s | 11 min 56 s |
| Windows | 32 s | 7 s | 8 s | 31 min 48 s |

The existing PowerShell full-validation stages consumed 11 min 37 s on Ubuntu
PowerShell 7 and 30 min 34 s on Windows PowerShell 5.1. This measurement shows
where this checkpoint spent hosted time; it does not authorize removing either
PowerShell route while those routes remain production or compatibility
authority.

## Decisions and relationships

- Parent epic: [Epic issue #153](https://github.com/hasanmanzak/meAndAI/issues/153)
- Dependencies: no new feature dependency; existing immutable release contracts are prior authority.

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Detailed [SUBF-0119](#subf-0119) type, nullability, ownership, lifecycle,
  invalid-state, compatibility, and dependency contracts recorded above.
- [x] Consumers, same-contract sibling inventory, decisions, and risks recorded.
- [x] Recurrence result `None` recorded for this slice; later packaging route is
  explicitly bound to the active recurrence owner.
- [x] [TEST-0191](test-cases.md#test-0191) and its `Distinct` sibling-intent
  review are recorded with a tests-first verification route.
- [x] Exact predecessor, absent C# source baseline, target `0.16.0`, target
  framework, SDK policy, and local toolchain evidence recorded.
- [x] Explicit [SUBF-0119](#subf-0119) implementation authorization received
  from the maintainer on 2026-07-27.

## Acceptance criteria

1. One solution builds shared components without allowing domain dependencies on infrastructure or CLI projects.
2. Governance, adoption, and update entry applications can receive different capability sets without duplicating canonical domain policy.
3. One portable ZIP per application runs unchanged on declared Windows and Linux hosts through `dotnet`.
4. The immutable manifest binds source, entry assembly, framework, schema compatibility, asset name, and digest.

## Definition of Done

[SUBF-0119](#subf-0119) DoD is complete: its scoped acceptance criteria,
tests-first evidence, local and hosted test commands, fresh-diff review,
exact-tree validation, documentation, links, and project memory are current,
with no unresolved `Blocking` finding. Feature-level DoD remains pending for
[SUBF-0120](#subf-0120), [SUBF-0121](#subf-0121), portable package/manifest
acceptance, and their independent authorization. This closure does not
authorize consumer mutation, authority transfer, release publication, or
PowerShell retirement.
