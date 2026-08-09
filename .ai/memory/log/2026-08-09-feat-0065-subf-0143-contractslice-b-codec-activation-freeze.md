# ContractSlice B codec-activation and wire packet freeze

| Field | Value |
| --- | --- |
| Packet | `B-CODEC-ACTIVATION-01` / `B-WIRE-REPOSITORY-TREE-01` / `B-WIRE-GOVERNED-TEXT-01` |
| State | Codec activation and repository-tree wire `ReviewedHostedGreen`; governed-text `FrozenDesign`/inactive pending the synchronized design head's hosted gate |
| Parent | [ContractSlice B micro-delivery plan](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-b-micro-delivery-plan.md) |
| Scenario | [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), retained `Planned` |
| Exact governed-text design predecessor | [`be94ea6da507e654e325b7cfc97074b3b0e5bacd`](https://github.com/hasanmanzak/meAndAI/commit/be94ea6da507e654e325b7cfc97074b3b0e5bacd); exact-head [run 31329704543](https://github.com/hasanmanzak/meAndAI/actions/runs/31329704543) passed Ubuntu `21m01s`, Windows `46m10s`, publication verification skipped |
| Implementation language | C# only |

## Immutable codec-activation boundary

The completed codec packet added one Abstractions registration file, one
Conformance activation file, and one retained test file, and updated only the existing B
ownership fact plus the retained A PublicApi Fact's obsolete
`ICodecRegistration`-absence row. That exact predecessor assertion transition
changes no A FQN, trait, public member snapshot, or 48-type containment. The
completed product surface is limited to:

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
mutation was allowed. At that codec checkpoint, repository-tree wire and every
later packet remained inactive. The codec exact head is now hosted green; the
current packet-specific wire staging below owns the next gate. The accepted
schema-2 graph ceilings remain `8,192` relations and `8,388,608` parsed bytes.

## Immutable `B-WIRE-REPOSITORY-TREE-01` hosted-green boundary

The typed evaluation-kernel design is the normative executable contract. This
handoff mirrors routing, review, and immutable evidence only and adds no
executable authority.

This packet extends the already registered test-owned
`RepositoryTreeCodecMirror` and `RepositoryTreeModelMirror` identities on the
same object. Both identities become `partial`; the new file owns the one direct
Fact plus a closed writer/qualifier mirror core. It adds no second codec,
adapter, static encoder, direction-specific interface, service lookup, or real
Policy implementation. `ICanonicalPayloadCodec<TModel>` remains the same
constrained memberless identity in this packet. After all three wire mirrors
and the later resource carriers exist, only its already accepted final
`Write`, `Qualify`, and meter members may be added, with the same mirror objects
delegating to these cores.

The exact packet-local methods are:

```csharp
RepositoryTreeWriteMirrorResult WriteRepositoryTree(
    EvidenceScope scope,
    SnapshotEvidenceLocation location,
    IReadOnlyList<RepositoryTreePayloadEntryMirror> entries,
    CancellationToken cancellationToken);
RepositoryTreeQualificationMirrorResult QualifyRepositoryTree(
    EvidenceBinding binding,
    CancellationToken cancellationToken);
```

Written carries one `CanonicalEvidencePayload`; Rejected carries exactly one of
the four declared codec failure-code strings. Qualified carries one
`RepositoryTreeModelMirror` retaining the decoded scope, Snapshot location, and
ordinal immutable entry copy; Rejected carries exactly one declared failure
code. Null arguments fail their argument boundary, cancellation remains out of
band, and neither becomes a semantic rejection. These names and signatures are
Tests-owned staging only and confer no public or Policy authority.

The exact executable allowlist is:

- modify `ContractSliceBActivationTests.cs` only to make the retained tree
  codec/model identities partial;
- add `ContractSliceBRepositoryTreeCodecTests.cs`, containing the sole Fact,
  tree entry/model carriers, the same-object mirror core, and its closed
  Written/Rejected and Qualified/Rejected result leaves; and
- change no production, public API, project, package, lock, friend, workflow,
  Domain, Conformance, Policy, admission-harness, cache, resource-ledger,
  capability/index, Scenario/status/owner/filter, or runtime-efficiency file.

The packet may change at most two test files and `1,200` normalized test lines;
`1,201` or more requires a design redraw. The valid-fixture red body changes only
`WriteRepositoryTree(...)`'s non-null semantic result to `return null!;`. Setup
and every qualifier/golden/negative assertion are marker-free; only that null
return may call direct `Assert.Fail("TEST-0210-B-BEHAVIOR-RED-0002")`.

The exact persistent frame is:

```text
ASCII "protocol.repository-tree/1\n"
seven EvidenceScope text leaves
i64 StartedAtUtc UTC ticks
i64 CompletedAtUtc UTC ticks
u8 Snapshot location rank = 3
u32 entry count
repeat in StringComparer.Ordinal RepositoryRelativePath order:
  text RepositoryRelativePath
  u8 Directory=0 | File=1 | SymbolicLink=2 | GitLink=3
```

`u32` and `i64` are big-endian. `text` is a big-endian `u32` byte length
followed by strict BOM-free UTF-8. The embedded target surface is Repository,
the location is Snapshot and reuses the embedded scope, paths are unique and
use the accepted repository-relative grammar, and no normalization or trailing
byte is allowed. The four-entry golden vector is `257` bytes, Base64
`cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAQAAAAJQUdFTlRTLm1kAQAAAARkb2NzAAAAAAxsaW5rcy9sYXRlc3QCAAAAD3ZlbmRvci9wcm90b2NvbAM=`
and SHA-256
`C5A8CB268E42C8A8C532A42C86ECDB0200B4C75186364B6399AD1AE5A40AE97F`.
The empty-tree vector is `197` bytes, Base64
`cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAA=`
and SHA-256
`BD2C4A254E295AE63E3EC7B610B7A6E88FC345E5D4DBD99C9AFFB61397E98676`.

Wire-local ceilings are `200,000` entries, `16,777,216` aggregate strict-UTF-8
path bytes before retention, and `16,777,216` canonical payload bytes. The
declared qualification budget remains `(16777216, 64, 200000, 2000000)`, but
four-counter equality, first-one-over, dominated, and unreachable accounting
remain wholly owned by `B-RESOURCE-01`.

Failure precedence is mutually exclusive. A hard byte/count ceiling breach is
`protocol.codec.resource-limit-exceeded`. An exact known non-Repository surface
or non-Snapshot location is `protocol.codec.payload-location-mismatch`. A
structurally valid embedded scope/location unequal to the enclosing binding is
`protocol.codec.embedded-identity-mismatch`. Header mutation, unknown rank or
kind, BOM/invalid/overlong/surrogate UTF-8, premature EOF, numeric/length/count
overflow or mismatch, trailing bytes, invalid path grammar, duplicate path, or
non-ordinal rows is `protocol.codec.invalid-repository-tree`. The test covers
every class, empty tree, four kinds, round trip, and the entry/path/payload
first-one-over boundaries without asserting later resource-ledger semantics.

The exact retained Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire`:
one direct non-skipped Fact, exactly one `ContractSlice=B` trait, no Scenario,
Theory, overload, inheritance, or class-level trait. Its sole canonical red uses
marker `TEST-0210-B-BEHAVIOR-RED-0002`, a fresh external result root, one exact
Release FQN-filtered invocation, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, a `420`-second outer bound, and the frozen
standard one-result/one-definition/one-entry TRX oracle. Once the child starts,
ordinal `0002` is consumed and never rerun.

Required green is focused `1/1`, B `4/4`, A+B/full Conformance `36/36`, Domain
`98/98`, warning/error-free Release build, format/locks/diff, StructureOnly,
publication evidence `7/7` without publication claim, and independent
product/test plus evidence/scope reviews `0/0/0`. Later B packets, real Policy,
C/D, final activation, merge, release, and publication remain held.

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
- The exact codec implementation tree repeated StructureOnly and publication
  evidence green before commit; its commit/push/hosted result is immutable at
  the exact predecessor named above. No later record edit may reuse an earlier
  run. The repository-tree design cohort must receive its own exact-head hosted
  green before canonical red.

## Immutable codec-activation pre-red reviews

- Architecture/semantic-boundary review: `0 Blocking / 0 Important / 0 Minor`.
  The activation-stage marker preserves the final one-object writer/qualifier
  architecture without pulling successor input/intent/resource behavior forward.
- Evidence/scope review: `0 Blocking / 0 Important / 0 Minor`. The predecessor,
  one exact red identity, one absent predicate, one-shot invocation, exact
  production/test allowlist, cumulative cardinalities, and downstream holds are
  finite and fail-closed.

## Immutable repository-tree wire design reviews

- Semantic/runner D/RT: `0 Blocking / 0 Important / 0 Minor`; exact topology,
  fixture, limits, precedence, one-shot boundary, custody, and no-retry contract
  are frozen without implementation authority.
- Route/content/scope review: `0 Blocking / 0 Important / 0 Minor`; the mutation
  surface remains the exact twelve-document design cohort and the later two-test-
  file executable allowlist, with no production or downstream-slice mutation.
- Canonical pre-red schema-2 projection: `364` nodes / `4,143` relations / `319`
  parsed blobs / `4,268,778` parsed bytes. The capacity interlude raised only
  prospective `v0.17.0` per-blob capacity to `1,048,576`; other graph and runtime
  ceilings remain unchanged.

## Immutable repository-tree wire red and bounded green

- The sole accepted R=0002 used runner SHA-256
  `4C806A083465E8DCE370CE1957D3C860F158B443F4B0BD0F2B58D37D775DEB8B`.
  Its report SHA-256 is
  `58E1ADFBA8169DA9C0998BB2D14D2B417A6F9C968AA76F3B21FAC3CE70A7E158`;
  the one TRX SHA-256 is
  `E9B79AADBEA9B0A6EB9D810816AD8959685A9E592ABA22015C19D8B9E03F024C`.
- Native exit `1` produced exactly one Failed result/definition/entry at the
  frozen FQN, the exact marker-only message, exact sixteen counters, and no
  forbidden diagnostics or attachments. R=0002 is immutable and never reruns.
- Bounded green changes only the test-owned mirror: the retained tree codec/model
  identities become partial and the new file owns the same-object writer,
  qualifier, carriers, result leaves, and sole Fact. Production delta is zero.
- Release build is `0` warnings / `0` errors; format is clean; focused `1/1`, B
  `4/4`, full Conformance `36/36`, and Domain `98/98` pass. The executable delta
  is `581/1,200` normalized lines; locks, projects, packages, and workflows are
  unchanged. Product/test and evidence/scope reviews are `0/0/0`.
- B is `4/11` and cumulative A+B is `36/43`. Exact implementation-head
  StructureOnly, publication evidence, commit/push, and hosted validation are
  green at the exact predecessor above; the canonical red is immutable.

## Frozen `B-WIRE-GOVERNED-TEXT-01` routing

- Normative bytes, carrier/result declarations, Repository/Provider/empty
  vectors, error precedence, body/payload limits, two-test-file allowlist, and
  the specialized `0003` runner contract are owned only by the typed design.
- The packet modifies only the retained activation test's two partial identity
  declarations and adds one governed-text test/core file, with zero production,
  interface, project, package, lock, workflow, resource, cache, or admission
  delta and at most `1,200` normalized lines.
- The sole Fact is the exact governed-text FQN with one `ContractSlice=B` trait,
  no Scenario, and marker `TEST-0210-B-BEHAVIOR-RED-0003`. No runner or red may
  start before the commit containing this exact twelve-record freeze is pushed
  and exact-head hosted green.
- The frozen green boundary is focused `1/1`, B `5/5`, A+B/full Conformance
  `37/37`, and Domain `98/98`. B remains `4/11` and A+B `36/43` until then;
  the parent scenario and every later/downstream hold remain unchanged.

## Frozen governed-text wire design reviews

- Semantic/runner D/RT: `0 Blocking / 0 Important / 0 Minor`; the same-object
  topology, closed carrier/result declarations, exact Repository/Provider/empty
  vectors, UTF-8/BOM grammar, failure precedence, equality/first-one-over
  limits, defensive copying, and one-shot no-retry custody are fully frozen.
- Route/content/scope review: `0 Blocking / 0 Important / 0 Minor`; the design
  cohort remains exactly twelve existing Markdown paths, while the later
  executable allowlist remains two Tests-owned files with zero production or
  downstream mutation.
- Capacity review: the typed-design blob is `532510/1048576` normalized bytes.
  The B-WIRE ceiling is `1200` normalized changed lines and `1201` requires a
  redraw. Node, relation, aggregate-byte, runner-log, report, timeout, and
  evidence-root limits remain unchanged; exact-tree StructureOnly and the
  publication-evidence recurrence must pass before commit.
- The packet remains `FrozenDesign`/inactive. These reviews authorize only the
  design delivery; no runner materialization, canonical red, or implementation
  begins before its exact synchronized design head is hosted green.
