# FEAT-0059 - Shared C# Operational Foundation and Portable Release Contract

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | In development / [SUBF-0119](#subf-0119) complete; [SUBF-0120](#subf-0120) authorized |
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

## [SUBF-0120](#subf-0120) port and result contract

The second slice adds only the shared boundary needed to keep later repository
and provider implementations typed, least-authority, deterministic, and safe
to report:

- `Domain.Results` owns closed `OperationOutcome` identities for `succeeded`,
  `rejected`, `failed`, and `canceled`, plus closed `OperationFailureCode`
  identities for `input.malformed`, `capability.denied`, `dependency.failed`,
  and `operation.canceled`.
- `OperationResult<T>` contains exactly one stage, one outcome, a non-null value
  only on success, and one compatible failure code only on a non-success
  outcome. Payloads are reference types so absence remains unambiguous.
  Factories reject nulls and impossible outcome/code combinations.
  The base failure schema deliberately contains no arbitrary message,
  exception, command, standard-output, standard-error, argument, environment,
  or credential field.
- `Application.Ports` owns four marker contracts: repository read, repository
  mutation, provider read, and provider mutation. A future domain-specific
  port must derive from exactly one marker; its implementation must expose the
  same single marker. A marker itself is not a registrable operational contract.
  Combining capability markers in either layer is rejected instead of silently
  widening authority.
- A new `Infrastructure` project depends inward on `Application` and `Domain`.
  Its port registration binds one exact contract type to one implementation.
  Its immutable scope rejects duplicate or malformed registrations and rejects
  every registration not allowed by the supplied stage grant. Resolution checks
  capability authority before registration presence, so a read-only scope
  cannot probe for or acquire a mutation port.
- The infrastructure execution boundary accepts one stage, one asynchronous
  operation, and one cancellation token. Pre-cancellation does not invoke the
  operation; caller-requested cancellation becomes the closed canceled result;
  a typed dependency failure becomes the closed failed result. Raw exception
  text and inner exceptions never enter the result. Unexpected programming
  exceptions remain exceptions rather than being mislabeled as dependency
  failures.
- Result payloads are public, typed operation evidence only. Credential values
  remain input-only adapter concerns and no foundation port returns them.
  Application-specific report fields and credential transports remain owned by
  their later features.
- This slice adds no filesystem, Git, process, network, GitHub, credential, or
  consumer adapter and moves no production authority. PowerShell remains the
  supported implementation and compatibility authority.

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
- [SUBF-0120](#subf-0120) verification approach: activate
  [TEST-0192](test-cases.md#test-0192) first and demonstrate missing result,
  marker, scope, and execution-boundary contracts; then add only the contract
  surface above. Exercise malformed-result rejection, pre- and in-flight
  cancellation, typed dependency failure redaction, capability-marker
  ambiguity, duplicate registration, and read-only mutation denial.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0286` <a name="risk-0286"></a> | Shared abstractions encode speculative or duplicated domain rules. | Feature owner / introduce only contracts required by the first vertical consumer and review dependency direction. |
| `RISK-0287` <a name="risk-0287"></a> | Portable artifacts depend on an unavailable or ambiguous runtime. | Release owner / explicit target, roll-forward, preflight, manifest, and Windows/Linux evidence. |

## Hosted blocker findings

| ID | Area / priority | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0362` <a name="find-0362"></a> | Canonical streaming test infrastructure / P1 | Exact C# implementation head [`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976) passed 31 of 31 C# tests on both hosts and the complete [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643866), but the [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643994) failed only [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105). Every required JSONL event and presentation assertion passed; only the aggregate live-consumption oracle failed. The C# diff does not touch the bounded process, streaming test, or fixture. The retained oracle reopens the child independently by PID inside the callback, so a hosted process-observation false negative can block the gate without disproving incremental consumption. | `Blocking` / resolved in the reviewed working tree, with new-head hosted confirmation pending. Canonical [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105) now receives a `{ ProcessId, IsRunning }` value snapshot from the already-owned `Process` object with each output line, correlates the first event by parent-generated stream identity and exact process ID, and requires `IsRunning=true`. The tests-first missing-snapshot run failed only [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); the bounded correction then passed [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105) and [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) on PowerShell 7 and Windows PowerShell 5.1 in 9.7 / 11.7 seconds. No timing tolerance, weakened event, duplicate scenario, or adoption/publication behavior was added. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | [SUBF-0119](#subf-0119) passing locally and on exact-head Ubuntu/Windows hosts; [SUBF-0120](#subf-0120) expected-red plus 16 of 16 focused local tests complete | [TEST-0191](test-cases.md#test-0191), [TEST-0192](test-cases.md#test-0192) |
| Baseline run | Complete for first slice | Exact v0.15.6 predecessor, absent C# source graph, and local .NET inventory recorded above |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0119` <a name="subf-0119"></a> | Solution boundaries and typed core contracts | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0191](test-cases.md#test-0191) / 17 of 17 local Release tests plus exact-head [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410350) and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410352) jobs passing | Fresh-diff review complete; parameter-name, closed-identity, serializable-theory-data, and analyzer findings closed; zero unresolved `Blocking` findings | Complete |
| `SUBF-0120` <a name="subf-0120"></a> | Capability-scoped infrastructure ports and result schemas | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0192](test-cases.md#test-0192) / expected red then 16 of 16 focused Release tests; combined [TEST-0191](test-cases.md#test-0191) and [TEST-0192](test-cases.md#test-0192) 31 of 31 | Fresh-diff review complete; reference-type absence, implementation capability widening, concrete collection analyzer, canonical passing declaration, link hygiene, and local package-cache containment findings closed; candidate-tree StructureOnly passed in 203.3 seconds; zero unresolved `Blocking` findings | In development |
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

## [SUBF-0120](#subf-0120) development checkpoint

Progress is measured against five independently observable delivery gates:

1. Definition of Ready and explicit authorization: complete.
2. Tests-first missing-contract failure: complete.
3. Minimal typed implementation and focused green run: complete.
4. Local self-review, locked restore, analyzer/format verification, and
   candidate-tree protocol validation: complete.
5. Exact committed-tree validation, remote draft checkpoint, and final-head
   Ubuntu/Windows hosted evidence: blocked by [FIND-0362](#find-0362).

The 2026-07-28 checkpoint is therefore four of five gates, or 80% of
[SUBF-0120](#subf-0120). Feature completion remains one of three completed
subfeatures, or 33%. [SUBF-0121](#subf-0121) remains unauthorized.

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

### [SUBF-0120](#subf-0120) gate

- [x] Exact result identities, valid state combinations, nullability, and
  redaction boundary are recorded above.
- [x] Exact port markers, single-capability rule, registration, grant-check,
  and resolution behavior are recorded above.
- [x] Cancellation, typed dependency failure, unexpected-exception, and
  no-I/O/no-authority-transfer boundaries are recorded above.
- [x] Consumers are the planned governance, adoption, and update applications;
  their current records require read-only governance, stage-separated mutation,
  deterministic reports, cancellation, credential redaction, and exact plans.
- [x] PowerShell prior art was inventoried for deterministic plan/evidence
  objects, bounded process termination, and secret-name-only reporting. No C#
  sibling implements the same contract.
- [x] Active recurrence review found no entry that owns this result or port
  contract; result `None`. The committed-HEAD governance-packet entry remains
  applicable to final validation, while bundle-path mapping remains owned only
  by [SUBF-0121](#subf-0121).
- [x] [TEST-0192](test-cases.md#test-0192) and its `Distinct` sibling-intent
  review define the tests-first route.
- [x] Exact predecessor is the completed [SUBF-0119](#subf-0119) checkpoint on
  this branch; target version, SDK/runtime line, dependency direction, risks,
  and local/hosted validation routes remain unchanged.
- [x] Explicit [SUBF-0120](#subf-0120) implementation authorization received
  from the maintainer through the sequential-continuation directive on
  2026-07-27.

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
