# FEAT-0059 Test Scenarios

The original `v0.16.0` implementation of
[SUBF-0119](README.md#subf-0119), [SUBF-0120](README.md#subf-0120), and
[SUBF-0121](README.md#subf-0121) is complete and its focused local
expected-red/green, exact committed-tree, exact package, fresh-download, and
required Ubuntu/Windows evidence remains below.
[SUBF-0141](README.md#subf-0141) extends the same three canonical scenario
identities; its tests-first failure is complete, implementation remains
pending, and no new TEST identity is declared.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0191` <a name="test-0191"></a> | [SUBF-0119](README.md#subf-0119) | Build the planned solution and inspect project dependencies and capability composition. | Dependency direction is acyclic; domain is infrastructure-free; each entry application receives only declared capabilities. | Architecture / unit | Nearest sibling: [TEST-0116](../FEAT-0024-v0101-parallel-windows-validation/test-cases.md#test-0116); `Distinct` compiled application dependency and authority boundaries. | Passing | `tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj` |
| `TEST-0192` <a name="test-0192"></a> | [SUBF-0120](README.md#subf-0120) | Exercise typed results and infrastructure ports with malformed, canceled, failed, and redacted operations. | Results remain deterministic, secrets are not emitted, and read-only callers cannot acquire mutation ports. | Unit / security | Nearest sibling: [TEST-0168](../FEAT-0043-v0134-case-safe-review-authority/test-cases.md#test-0168); `Distinct` compiled port and result contract. | Passing | `tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj` |
| `TEST-0193` <a name="test-0193"></a> | [SUBF-0121](README.md#subf-0121) | Build the exact three declared framework-dependent ZIPs once, validate the external manifest and archive inventories, run those same bytes through `dotnet` on supported Windows and Linux, and tamper with source, schema, asset, archive, and runtime evidence. | The exact manifest-bound package set runs unchanged on both; unknown/duplicate/inferred identity, digest or length drift, unsafe archive content, and missing/incompatible runtime evidence fail before application work. | Packaging / integration | Nearest sibling: [TEST-0185](../FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0185); `Distinct` because this scenario owns portable release identity/runtime preflight rather than test-harness execution identity. | Passing | `tests/dotnet/MeAndAI.Operations.Packaging.Tests/MeAndAI.Operations.Packaging.Tests.csproj` plus exact-head package handoff in `.github/workflows/protocol-tests.yml` |

## [SUBF-0141](README.md#subf-0141) extension evidence

The first [TEST-0192](#test-0192) Release compile ran the existing Architecture.Tests
project with `--no-restore` and the exact `Scenario=TEST-0192` filter. It
failed in 11.1 seconds only with `CS0246` for the deliberately absent
`BoundedProcessRequest`; no test executed and no `CS0017`, restore, lock,
warning, or unrelated compiler failure occurred. This is the expected-red
evidence for the shared Infrastructure contract. No implementation or green
result is claimed yet.

The exact predecessor
[`2a70b64a7b34abfc440f4af65e2067cdee6adcc3`](https://github.com/hasanmanzak/meAndAI/commit/2a70b64a7b34abfc440f4af65e2067cdee6adcc3)
passed [hosted run `30429072869`](https://github.com/hasanmanzak/meAndAI/actions/runs/30429072869)
on Ubuntu and Windows and is readiness evidence, not implementation evidence.

| Existing owner | Planned support-extension amendment | Expected extension result |
| --- | --- | --- |
| [TEST-0191](#test-0191) | Extend the existing dependency inspection with exact single ownership of production process primitives and absence of a Packaging runner/wrapper. | Domain and Application remain process-free; Infrastructure is the only production owner; Packaging references Infrastructure and contains no second runner. |
| [TEST-0192](#test-0192) | Extend the existing Infrastructure execution boundary with immutable process requests/results, discrete shell-free arguments, environment isolation, binary stdin/stdout/stderr, concurrent streaming limits, nonzero exit, cancellation, timeout, inherited-pipe completion, active-descendant cleanup, and redacted failure. | Exact bytes and inclusive limits hold without deadlock or unobserved work; clean cancellation preserves the caller token after cleanup; dependency failures disclose no sensitive request, output, path, environment, or operating-system diagnostics. |
| [TEST-0193](#test-0193) | Extend existing package execution to consume the shared Infrastructure kernel while retaining strict adapter decode/exit interpretation and temporary-state cleanup. | Package/manifest identities and same-byte Windows/Linux behavior remain unchanged; process failure stops before application work; Packaging owns no process implementation. |

## Historical `v0.16.0` evidence

[TEST-0193](#test-0193) expected red on 2026-07-28 because the authorized C#
packaging project, inventory, manifest, builder, and verifier contracts did not
exist. Configured restore identified only the absent production project; the
subsequent focused Release compile failed in 4.1 seconds with `CS0246` only for
the planned `OperationsPackageInventory`, `PortablePackageBuildRequest`, and
`PortablePackageVerificationRequest` contract family. An earlier invocation
that supplied restore-only `--configfile` syntax to `dotnet test` did not reach
the scenario and is not test evidence.

The bounded implementation then passed 17 of 17 focused cases and the combined
[TEST-0191](#test-0191), [TEST-0192](#test-0192), and [TEST-0193](#test-0193)
set passed 48 of 48. The package cases cover exact declarative mappings,
unknown/missing/duplicate inventory state, deterministic repeated ZIP/manifest
bytes, source/schema/asset tampering, digest and length drift, escaping archive
entries even after digest rebinding, apphost/RID payload rejection, missing or
incompatible runtime inventories, and inherited entry-project publish policy.
Locked restore, zero-warning/zero-error Release build, and clean format/analyzer
evidence pass. A real adoption-entry publish probe produced six flat managed
files and the exact declared runtime config. Windows PowerShell 5.1 candidate-
tree StructureOnly passed all discovered contracts in 211.2 seconds; its
protocol-governance owner reported 208,942 ms. Exact implementation commit
[`956a2b8c3d0787b6133f5d7ed2eb2a1636294560`](https://github.com/hasanmanzak/meAndAI/commit/956a2b8c3d0787b6133f5d7ed2eb2a1636294560)
passed exact committed-tree StructureOnly in 208.8 seconds, built all three
clean-HEAD packages in 13.1 seconds, and verified/executed them locally in 2.6
seconds. Exact-head [run `30329211045`](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045)
passed 48 of 48 compiled tests and the same uploaded package bytes on
[Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045/job/90180695565)
in 9 min 39 s and
[Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30329211045/job/90180695611)
in 31 min 23 s. A fresh hosted-artefact download independently passed all
digest/runtime checks and all three Windows executions in 2.4 seconds.

[TEST-0191](#test-0191) expected red on 2026-07-27 because the authorized
`Domain.Authority`, `Domain.Identity`, and `Application.Authority` contracts did
not exist. After the bounded implementation and one assertion-driven parameter
identity correction, the focused Release run passed 17 of 17 tests locally on
Windows with SDK `10.0.301`, zero build warnings, and zero build errors. The
expanded boundary set covers exact case-sensitive identities, unknown/null
identity rejection, exact stage/capability composition, mutation prerequisites,
production package-reference absence, and solution dependency direction.
Locked restore passed, `dotnet format --verify-no-changes --severity info`
reported no remaining diagnostics, and exact committed-tree protocol structure
validation passed. On exact implementation head
[`59c82770fb7175dc01aa40915ac5b8b6c4104bc7`](https://github.com/hasanmanzak/meAndAI/commit/59c82770fb7175dc01aa40915ac5b8b6c4104bc7),
the required [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410350)
passed in 11 min 56 s and the required
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30299109933/job/90087410352)
passed in 31 min 48 s. The C# test steps themselves completed in 7 s and 8 s,
respectively; the existing full PowerShell validation dominated the job times.
[TEST-0192](#test-0192) expected red on 2026-07-27 because the authorized
`Domain.Results`, `Application.Ports`, `Infrastructure.Ports`, and
`Infrastructure.Execution` contracts did not exist. The focused Release
compile failed only on those missing namespaces and types before running a
test. The bounded implementation then passed 16 of 16 focused Release tests
and the combined [TEST-0191](#test-0191)/[TEST-0192](#test-0192) filter passed
31 of 31. Coverage fixes found during fresh-diff review constrain result
payloads to reference types, freeze the four-field base schema, reject direct
marker registration, reject implementation capability widening, and use the
concrete immutable dictionary type identified by `CA1859`. Locked restore,
zero-warning/zero-error Release build, and `dotnet format --verify-no-changes
--severity info` pass. Windows PowerShell 5.1 candidate-tree StructureOnly
passed all discovered contracts in 203.3 seconds after canonical status/link
hygiene and local package-cache containment corrections. At that checkpoint,
exact committed-tree and hosted evidence remained pending and
[TEST-0193](#test-0193) was still a planning record.

Exact implementation head
[`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976)
then passed 31 of 31 C# tests on Ubuntu and Windows. The complete
[Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643866)
passed in 12 min 28 s. The
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690/job/90115643994)
failed after 8 min 1 s only in the retained canonical
[TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
streaming infrastructure oracle; the C# step, runtime-efficiency step, every
required JSONL event, and every separate presentation assertion passed.
[FIND-0362](README.md#find-0362) owns that blocker; an unchanged-head rerun is
not closure evidence.

Exact correction head
[`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a)
again passed 31 of 31 C# tests on both hosts. Its
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827/job/90122730639)
failed only the retained
[TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
aggregate even though every event and
separate presentation assertion passed; its
[Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30309863827/job/90122730666)
passed the streaming owner and failed later only when
[TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) rejected the
non-navigable short commit reference in the current project snapshot.
[FIND-0363](README.md#find-0363) owns the remaining process-liveness oracle.
The replacement
[TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
contract first failed alone on PowerShell 7 /
Windows PowerShell 5.1 in 9.7 / 11.5 seconds while `ConsumptionStage` was
absent, then passed
[TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
and [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
in 10.0 / 12.4 seconds after the
active read loop and post-exit drain received distinct closed stage values.
The canonical exact commit link is restored, and candidate-tree Windows
PowerShell 5.1 StructureOnly passed in 208.5 seconds.

Exact correction commit
[`26b126858cd4a6612a8c19909bd4fd3958fb82f1`](https://github.com/hasanmanzak/meAndAI/commit/26b126858cd4a6612a8c19909bd4fd3958fb82f1)
passed exact committed-tree StructureOnly in 206.6 seconds and exact-head
[run `30312104364`](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364).
The [Ubuntu job](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779014)
passed in 12 min 04 s with 31 of 31 C# tests in 99 ms and
[TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
inside the seven-scenario post-publication manifest. The
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779066)
passed in 32 min 09 s with 31 of 31 C# tests in 170 ms and the exact
[TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)/[TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
manifest. [TEST-0192](#test-0192) is complete; PowerShell production authority
and every consumer remain unchanged.
