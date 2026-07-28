# FEAT-0059 - Shared C# Operational Foundation and Portable Release Contract

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | In development / [SUBF-0119](#subf-0119) and [SUBF-0120](#subf-0120) complete; [SUBF-0121](#subf-0121) local implementation candidate |
| Target version | 0.16.0 |
| Issue | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) |
| Pull request | Draft [#159](https://github.com/hasanmanzak/meAndAI/pull/159) |
| Decisions | [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md) and [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md) |
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

## [SUBF-0121](#subf-0121) portable package and manifest contract

The third slice adds only the executable/package boundary needed to prove that
the shared foundation can be delivered once and run unchanged on supported
Windows and Linux hosts:

- The separately publishable applications are exactly `governance`, `adoption`,
  and `consumer-update`. Their assets are exactly `maai-governance.zip`,
  `maai-adoption.zip`, and `maai-consumer-update.zip`; their entry assemblies
  are exactly `MeAndAI.Operations.Governance.dll`,
  `MeAndAI.Operations.Adoption.dll`, and
  `MeAndAI.Operations.ConsumerUpdate.dll`.
- A repository-owned declarative inventory records application identity,
  project source path, asset name, and entry assembly independently. The C#
  packager consumes those exact fields and never derives a repository path
  from an archive or asset path. Inventory and manifest JSON use strict UTF-8
  without a BOM, reject unknown or duplicate identities, and retain ordinal
  ordering.
- Every entry project is `net10.0`, framework-dependent, ordinary JIT,
  `UseAppHost=false`, non-self-contained, and has no runtime identifier,
  single-file, ReadyToRun, Native AOT, or third-party package dependency. The
  package contains the sorted publish output at its root, uses one fixed ZIP
  timestamp, and carries no platform apphost or RID-specific payload.
- The external release manifest is exactly
  `maai-operations-release-manifest.json`, schema 1. It binds one exact
  lowercase 40-hex source commit; `Microsoft.NETCore.App`; target framework
  `net10.0`; minimum runtime `10.0.0`; roll-forward policy `LatestPatch`; the
  supported application-contract schema interval `[1,1]`; and, for each exact
  asset, its application, entry assembly, contract schema, byte length, and
  lowercase SHA-256 digest. The manifest cannot bind its own containing ZIP,
  so it remains one sibling asset outside the three archives.
- Verification is fail-closed and ordered. It validates the exact manifest and
  inventory shapes, expected identity set, safe leaf names, source/runtime and
  schema contracts, then asset length and digest before opening an archive.
  It rejects duplicate, escaping, unexpected, apphost, RID-specific, missing,
  or mismatched archive entries. Runtime preflight must accept one installed
  stable `Microsoft.NETCore.App` `10.0.x` version at or above the declared
  minimum before any packaged application process starts.
- Each entry application exposes only a deterministic contract-description
  command in this feature. Cross-platform package verification extracts to an
  owned temporary directory, invokes the exact manifest-bound assembly through
  `dotnet`, and requires the exact application and schema identity. It always
  cleans its owned extraction directory. Governance, adoption, update,
  repository, provider, credential, and consumer behavior remain later
  features.
- Runtime installation is not application behavior. Source validation installs
  the reviewed SDK explicitly; a future consumer host may use an already
  compatible runtime or a separately declared setup action. Missing,
  prerelease-only, malformed, incompatible, or ambiguous runtime evidence
  fails before application work and never triggers an implicit installation.
- The existing Ubuntu job builds the clean exact-head package set once and
  uploads it before its retained protocol validation. The independent existing
  Windows job completes its retained platform validation, then downloads,
  verifies, and executes that exact current-run set. No additional hosted
  runner, matrix axis, or job dependency is introduced. Missing package
  evidence fails closed; both jobs verify and execute the same manifest-bound
  bytes while retained stable check names remain unchanged.
- This slice publishes no GitHub Release, changes no consumer, implements no
  operational behavior, and transfers no authority. PowerShell remains the
  production and compatibility authority.

## Readiness evidence

- Domain and contracts: [DEC-0032](../../decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
  and the contracts above fix application/stage/capability meaning, dependency
  direction, invalid-state behavior, runtime line, and slice ownership. Result
  and port details are fixed by [SUBF-0120](#subf-0120); package, manifest, and
  runtime-preflight details are fixed by [SUBF-0121](#subf-0121). Later schema
  evolution remains owned by the feature that introduces it.
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
  Package/manifest and cross-platform execution were retained for the later
  [SUBF-0121](#subf-0121) scenario gate.
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
| `FIND-0362` <a name="find-0362"></a> | Canonical streaming test infrastructure / P1 | Exact C# implementation head [`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976) passed 31 of 31 C# tests on both hosts and the complete [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643866), but the [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643994) failed only [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105). Every required JSONL event and presentation assertion passed; only the aggregate live-consumption oracle failed. The C# diff does not touch the bounded process, streaming test, or fixture. The retained oracle reopens the child independently by PID inside the callback, so a hosted process-observation false negative can block the gate without disproving incremental consumption. | `Superseded` / exact correction commit [`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a) removed the independent PID reopen and passed the canonical owner locally on PowerShell 7 / Windows PowerShell 5.1 in 9.7 / 11.7 seconds. Its exact-head [Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827/job/90122730639) nevertheless failed only the same aggregate oracle. The correction therefore removed the reopen defect but proved that retaining OS process identity and liveness as the consumption boundary remained over-constrained; [FIND-0363](#find-0363) owns that distinct remaining blocker. |
| `FIND-0363` <a name="find-0363"></a> | Portable streaming-consumption evidence / P1 | Exact correction head [`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a) passed 31 of 31 C# tests on both hosts, but canonical [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105) again reported only the aggregate live-consumption failure on hosted Windows even though all JSONL events and separate presentation assertions passed. The callback still inferred consumption from OS process identity and liveness. That state is not the contract: `Invoke-BoundedProcess` already has a deterministic control-flow boundary between its active asynchronous read loop and its post-exit drain. The exact-head [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827/job/90122730666) passed the streaming owner and failed later only because a current-status Markdown sentence used a non-navigable short commit reference. | `Resolved` / exact correction commit [`26b126858cd4a6612a8c19909bd4fd3958fb82f1`](https://github.com/hasanmanzak/meAndAI/commit/26b126858cd4a6612a8c19909bd4fd3958fb82f1) requires exact parent-generated stream identity plus `ConsumptionStage=ActiveReadLoop`, supplies `PostExitDrain` only after process completion, and restores the canonical commit link. The absent stage first failed only [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105) on PowerShell 7 / Windows PowerShell 5.1 in 9.7 / 11.5 seconds; the unchanged [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)/[TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) owner then passed locally in 10.0 / 12.4 seconds. Candidate- and exact-committed-tree Windows PowerShell 5.1 StructureOnly passed in 208.5 / 206.6 seconds. Exact-head [run `30312104364`](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364) passed [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779014) and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779066); Windows emitted the exact [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)/[TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) pass manifest and Ubuntu passed the [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) link verifier. Exit zero, all required events, bounded redaction, final-result authority, and cancellation coverage remain mandatory. No process reopen, OS-liveness predicate, timing tolerance, retry, weakened event, duplicate scenario, or adoption/publication behavior was added. |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [Test scenarios](test-cases.md) |
| Test code | [SUBF-0119](#subf-0119) and [SUBF-0120](#subf-0120) passing locally and on exact-head Ubuntu/Windows hosts | [TEST-0191](test-cases.md#test-0191), [TEST-0192](test-cases.md#test-0192) |
| Baseline run | Complete for first slice | Exact v0.15.6 predecessor, absent C# source graph, and local .NET inventory recorded above |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0119` <a name="subf-0119"></a> | Solution boundaries and typed core contracts | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0191](test-cases.md#test-0191) / 17 of 17 local Release tests plus exact-head [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410350) and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410352) jobs passing | Fresh-diff review complete; parameter-name, closed-identity, serializable-theory-data, and analyzer findings closed; zero unresolved `Blocking` findings | Complete |
| `SUBF-0120` <a name="subf-0120"></a> | Capability-scoped infrastructure ports and result schemas | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0192](test-cases.md#test-0192) / expected red then 16 of 16 focused Release tests; combined [TEST-0191](test-cases.md#test-0191) and [TEST-0192](test-cases.md#test-0192) 31 of 31 locally and on exact-head [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779014) / [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779066) | Fresh-diff review complete; all result, authority, analyzer, link, cache, and hosted streaming findings closed; candidate/exact-tree StructureOnly passed in 208.5 / 206.6 seconds; zero unresolved `Blocking` findings | Complete |
| `SUBF-0121` <a name="subf-0121"></a> | Portable packaging and immutable manifest | [#154](https://github.com/hasanmanzak/meAndAI/issues/154) | [TEST-0193](test-cases.md#test-0193) / expected red then 17 of 17 focused and 48 of 48 combined local tests | Fresh-diff review closed source binding, atomic output, null/ambiguity, bounded archive, analyzer, workflow-topology, and link findings; candidate-tree StructureOnly passed in 211.2 seconds; exact-tree and hosted package evidence pending | Local candidate (4/5 gates) |

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
   Ubuntu/Windows hosted evidence: complete.

The 2026-07-28 closure is therefore five of five gates, or 100% of
[SUBF-0120](#subf-0120). At that checkpoint feature completion was two of three
completed subfeatures, or 67%, and [SUBF-0121](#subf-0121) remained gated and
unauthorized.

Observed hosted timings are evidence, not workflow service-level objectives:

| Host | C# test process | C# workflow step | Retained validation | Full required job |
| --- | ---: | ---: | ---: | ---: |
| Ubuntu | 99 ms | 12 s | 11 min 31 s / PowerShell 7 | 12 min 04 s |
| Windows | 170 ms | 10 s | 30 min 48 s / Windows PowerShell 5.1 | 32 min 09 s |

The compiled contract tests remain a small fraction of hosted duration; this
measurement does not authorize removing either retained PowerShell route while
those routes remain production or compatibility authority.

## [SUBF-0121](#subf-0121) development checkpoint

Progress is measured against five independently observable delivery gates:

1. Definition of Ready and explicit authorization: complete.
2. Tests-first missing-contract failure: complete.
3. Minimal entry applications, package/manifest implementation, and focused
   green run: complete.
4. Local self-review, locked restore, analyzer/format verification, and
   candidate-tree protocol validation: complete.
5. Exact committed-tree package construction, same-byte Ubuntu/Windows
   execution, remote draft checkpoint, and final exact-head hosted evidence:
   pending.

The 2026-07-28 candidate is therefore four of five gates, or 80% of
[SUBF-0121](#subf-0121). Across all three slices, 14 of 15 delivery gates are
closed, or 93%; formal feature completion remains two of three completed
subfeatures, or 67%, until the exact package and hosted gate closes.

Local implementation evidence is 17 of 17 focused [TEST-0193](test-cases.md#test-0193)
cases in 419 ms and 48 of 48 combined C# cases in 523 ms of test-process time.
Locked restore passed, the complete Release solution built with zero warnings
and errors in 1.56 seconds, and `dotnet format --verify-no-changes --severity
info` passed in 12.2 seconds. A real framework-dependent publish probe produced
only six flat managed/runtime files, no apphost or RID payload, and exact
`net10.0` / `Microsoft.NETCore.App` `10.0.0` / `LatestPatch` runtime config.
Windows PowerShell 5.1 candidate-tree StructureOnly passed in 211.2 seconds;
its protocol-governance owner reported 208,942 ms. Local `actionlint` and Ruby
are unavailable, so no local success is claimed for those tools; the hosted
pinned actionlint step retains workflow authority.

The same-byte artifact handoff adds no runner, matrix job, or job dependency.
Ubuntu uploads the package before its retained protocol suite; the independent
Windows job performs its retained long platform validation before downloading
the current-run artifact. Missing or late artifact evidence fails closed. The
expected critical path and total hosted runner count therefore remain materially
unchanged; this observation does not alter PowerShell authority or coverage.

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

### [SUBF-0121](#subf-0121) gate

- [x] Exact application, asset, entry-assembly, inventory, archive, manifest,
  runtime, schema, digest, and fail-closed verification contracts are recorded
  above, including ownership, null/invalid state, compatibility, and cleanup.
- [x] Consumers are the separately gated governance, adoption, and update
  features. This slice supplies only their executable/package shells and does
  not implement their commands or transfer authority.
- [x] The existing quick-adoption bundle builder and release verifier were
  reviewed as PowerShell-owned, source-bundle-specific prior art. They retain
  their canonical contract and are neither called, copied, nor changed. No C#
  sibling owns the operational-application package contract.
- [x] The active declarative bundle-path recurrence applies: the new inventory
  declares project source path and asset/entry identity independently and the
  packager must not infer one from another. The committed-HEAD graph recurrence
  applies to final exact-tree evidence. No other active recurrence entry owns
  this contract.
- [x] [TEST-0193](test-cases.md#test-0193) remains `Distinct` from
  [TEST-0185](../FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0185):
  it exercises portable artifact identity and runtime preflight rather than
  test-harness execution identity. Tests are added first and must fail only on
  the absent authorized entry, inventory, manifest, packager, and verifier
  contracts.
- [x] Exact predecessor is the completed [SUBF-0120](#subf-0120) head
  [`e80e3a2147e0254a69f5aabdc7cb896fb59aa3d1`](https://github.com/hasanmanzak/meAndAI/commit/e80e3a2147e0254a69f5aabdc7cb896fb59aa3d1).
  Local baseline exposes SDK `10.0.301` and stable runtime `10.0.9`; hosted
  source validation retains explicit SDK `10.0.302` setup rather than mutable
  runner-image assumptions.
- [x] Verification uses focused compiled tamper/runtime tests, locked restore,
  zero-warning Release build, format/analyzer validation, one clean exact-head
  package build, the same package bytes on Ubuntu and Windows, retained
  protocol validation, fresh-diff review, and exact committed-tree evidence.
- [x] Workflow topology retains one independent Ubuntu and one independent
  Windows runner and their stable checks. The producing Ubuntu job uploads
  early and Windows consumes after its retained platform validation; the
  handoff adds no repeated setup, dependency, or third runner.
- [x] Explicit [SUBF-0121](#subf-0121) implementation authorization received
  from the maintainer through the sequential-continuation directive on
  2026-07-28.

## Acceptance criteria

1. One solution builds shared components without allowing domain dependencies on infrastructure or CLI projects.
2. Governance, adoption, and update entry applications can receive different capability sets without duplicating canonical domain policy.
3. One portable ZIP per application runs unchanged on declared Windows and Linux hosts through `dotnet`.
4. The immutable manifest binds source, entry assembly, framework, schema compatibility, asset name, and digest.

## Definition of Done

[SUBF-0119](#subf-0119) and [SUBF-0120](#subf-0120) DoD are complete: their
scoped acceptance criteria, tests-first evidence, local and hosted test
commands, fresh-diff review, exact-tree validation, documentation, links, and
project memory are current, with no unresolved `Blocking` finding. Feature-
level DoD remains pending for [SUBF-0121](#subf-0121), portable package and
manifest acceptance, and its independent authorization. This closure does not
authorize consumer mutation, authority transfer, release publication, or
PowerShell retirement.
