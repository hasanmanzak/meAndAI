# ContractSlice B codec-activation packet freeze

| Field | Value |
| --- | --- |
| Packet | `B-CODEC-ACTIVATION-01` |
| State | `ReviewedLocalGreen`; exact-head hosted pending |
| Parent | [ContractSlice B micro-delivery plan](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-b-micro-delivery-plan.md) |
| Scenario | [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), retained `Planned` |
| Exact predecessor | [`2d5f5c6ed5c5317b827e7ee6f969d58822c663e9`](https://github.com/hasanmanzak/meAndAI/commit/2d5f5c6ed5c5317b827e7ee6f969d58822c663e9); exact-head [run 31312309195](https://github.com/hasanmanzak/meAndAI/actions/runs/31312309195) passed Ubuntu `20m25s`, Windows `16m49s`, publication verification skipped |
| Implementation language | C# only |

## Frozen executable boundary

The packet may add one Abstractions registration file, one Conformance
activation file, and one retained test file, and may update only the existing B
ownership fact plus the retained A PublicApi Fact's obsolete
`ICodecRegistration`-absence row. That exact predecessor assertion transition
changes no A FQN, trait, public member snapshot, or 48-type containment. The
product surface is limited to:

- internal `IProtocolSemanticModel` and `ModelTypeToken<TModel>`;
- internal `ICanonicalPayloadCodec<TModel>` as the constrained, memberless
  activation-stage identity of the one object that will own both final `Write`
  and `Qualify` operations;
- internal `ICodecRegistration`, `ICodecRegistrationVisitor<TResult>`, and
  `CodecRegistration<TModel>` with exact declaration, model-token, codec-object,
  private-constructor, factory, and visitor-dispatch ownership;
- internal `IContractSliceBActivationProofState`; and
- internal `ContractSliceBAdmissionHarness.Activate`, whose temporary red body
  is exactly `return null!;` and whose bounded green validates and retains only
  the exact canonical codec mirror.

The memberless codec interface is packet staging, not an alternate final
architecture. It exposes no write, qualify, resource, wire, cache, or admission
behavior. Its final two operations and resource-meter inheritance remain owned
by the already accepted typed design and may be added only with their dependency-
owning successor packets. No second writer/qualifier interface or adapter is
allowed.

`Activate` enumerates registrations exactly once, rejects null elements,
canonicalizes them by ordinal schema key/version, requires a bijection with the
manifest payload-schema declarations, and requires each registration to retain
the object-identical declaration, its exact output-model contract, and one
non-null codec object. It accepts only the manifest-declared activation-proof
CLR type/artifact, exact contract/version/digest/artifact inventory, the one
Tests-only proof-state interface, and a successful proof over the same manifest
and canonical registration instances. Registration mismatch and activation-
proof mismatch remain distinct fail-closed integrity categories. The returned
harness is non-null and exposes no new callable behavior in this packet.

## Exact retained test and canonical red

- File: `ContractSliceBActivationTests.cs`.
- Exact FQN:
  `MeAndAI.Protocol.Conformance.Tests.ContractSliceBActivationTests.Activates_exact_codec_mirror`.
- One direct non-skipped `[Fact]`, exactly one `ContractSlice=B` trait, no
  `Scenario`, Theory, overload, inheritance, or class-level trait.
- Exact marker and TRX filename:
  `TEST-0210-B-BEHAVIOR-RED-0001` and
  `TEST-0210-B-BEHAVIOR-RED-0001.trx`.
- The complete valid test-owned manifest/proof/three-registration mirror is
  constructed before the call. Only `Activate(...) is null` calls direct
  `Assert.Fail(marker)`. Every other wrong result uses marker-free assertions or
  propagates.
- R uses one fresh external
  `meandai-test-0210-b-<32-lowercase-hex-guid>` directory, one exact FQN-filtered
  Release `--no-restore` invocation, one TRX logger, no discovery prepass, no
  retry, exactly one Failed result, the exact marker-only result message, and
  the frozen complete sixteen-counter/no-diagnostic/no-attachment oracle.
- R is immutable after the one accepted invocation. The transient `null!` body
  is replaced in the same uncommitted red-to-green operation and is never
  committed or pushed.

## Required green and negative scope

Green requires focused `1/1`, B `3/3`, cumulative A+B and full Conformance
`35/35`, Domain `98/98`, Release build with zero warnings/errors, format and diff
clean, StructureOnly green, publication-evidence `7/7` with no publication
claim, and independent product/test plus evidence/scope reviews `0/0/0`.

No public API, other A source/test, Domain, Policy, project, package, lock,
workflow, Scenario/status/
owner/filter, writer input/intent, wire bytes, resource meter, cache, ticket,
qualification, admission result, sealed context, C/D, release, or publication
mutation is allowed. `B-WIRE-REPOSITORY-TREE-01` and every later packet remain
inactive until this exact packet is reviewed, synchronized, pushed, and exact-
head hosted green. The accepted schema-2 graph ceilings remain `8,192` relations
and `8,388,608` parsed bytes.

## Immutable canonical BehaviorRed

The only accepted invocation used the fresh external directory
`D:\Temp\meandai-test-0210-b-fb2ad14fcdb84b49b2c8a9562c8aeb84` and the exact
command:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "D:\Temp\meandai-test-0210-b-fb2ad14fcdb84b49b2c8a9562c8aeb84" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0001.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBActivationTests.Activates_exact_codec_mirror"
```

It exited `1` and produced exactly one `4,730`-byte TRX with SHA-256
`1B4C85C6A6D3ECFAB300D1A4655052E7CE10DF69FA486D6A91812EE2429FD60D`.
The result/definition/entry inventory was exactly `1/1/1`, the sole result was
Failed at the exact FQN, its sole message was the exact marker, and the only
other marker occurrence was the permitted same-FQN standard-output echo. The
sole marker-free RunInfo was the permitted same-FQN `[FAIL]` record. Counters
were exactly total/executed/failed `1/1/1`; passed and the other twelve
counters, including completed, were `0`; attachments and
collector data were absent.

Transient red source SHA-256 identities were:

- registration `8BF5B2C5746595504892CF425C3F819B5CECFC6FBF3F079C6D26E93A910094C3`;
- activation harness `7755FE6B08F84363A7CAAC8F3AD7BBDE1D17DCFD199F23FFD383C7DF398C84D9`;
- retained test `761F78E3919C633CE40D5A698EDB4D1A654D6E3842A59E410E48459B7C71FCE2`.

A pre-invocation compile exposed only the test proof's missing retained
`IAdmissionProofCandidate` overload. It created no TRX/marker result and
consumed no red authority. After that scaffold correction, the fresh Release
build was warning/error-free and the canonical invocation above ran exactly
once. It is immutable and must never be rerun.

## Bounded green and review evidence

- Release build: `0` warnings / `0` errors.
- Focused activation: `1/1`; ContractSlice B: `3/3`.
- Cumulative A+B and full Conformance: `35/35`; Domain: `98/98`.
- The retained A PublicApi transition removes only its obsolete internal
  registration-absence assertion; A FQN/trait/public inventory remains exact.
- Product/test review: `0 Blocking / 0 Important / 0 Minor`.
- Evidence/scope review: `0 Blocking / 0 Important / 0 Minor`.
- Preliminary synchronized-tree StructureOnly was green with
  `elapsedMs=464853`; publication evidence was `7/7`, including the fresh
  commit-reference recurrence, with no publication claim.
- Default-severity format verification and diff check were clean; schema-2
  graph ceilings were respected by StructureOnly.
- The exact tree containing this evidence row must repeat StructureOnly and
  publication evidence green before commit. Commit/push and hosted gates remain
  pending at this record point; no later record edit may reuse an earlier run.

## Pre-red reviews

- Architecture/semantic-boundary review: `0 Blocking / 0 Important / 0 Minor`.
  The activation-stage marker preserves the final one-object writer/qualifier
  architecture without pulling successor input/intent/resource behavior forward.
- Evidence/scope review: `0 Blocking / 0 Important / 0 Minor`. The predecessor,
  one exact red identity, one absent predicate, one-shot invocation, exact
  production/test allowlist, cumulative cardinalities, and downstream holds are
  finite and fail-closed.
