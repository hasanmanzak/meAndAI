# [SUBF-0143](README.md#subf-0143) - ContractSlice B Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | `B-SURFACE-01`, `B-CODEC-ACTIVATION-01`, `B-WIRE-REPOSITORY-TREE-01`, `B-WIRE-GOVERNED-TEXT-01`, and `B-WIRE-REPOSITORY-TARGET-01` exact-head hosted green; repository-target R=0004 diagnostic-only and canonical R=0005 accepted; B `6/11`, cumulative A+B `38/43`; `B-RESOURCE-01` `FrozenDesign`/inactive pending its synchronized design-head hosted gate; later packets inactive |
| Parent | Owning feature and current subfeature |
| Scenario | [TEST-0210](test-cases.md#test-0210), still `Planned` |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Ordered-B authority | [Maintainer directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5230762350) |
| Accepted predecessor | Accepted A merge commit [`51623f4d404a95e0f706d72805cf7ddbbbd293b8`](https://github.com/hasanmanzak/meAndAI/commit/51623f4d404a95e0f706d72805cf7ddbbbd293b8); exact-main [run 31304787603](https://github.com/hasanmanzak/meAndAI/actions/runs/31304787603) passed Ubuntu `6m11s`, Windows `11m21s`, publication verification skipped |
| Normative owner | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Implementation language | C# only; the frozen resource packet may add only its one test-owned file |

## Authority and non-goals

This plan decomposes only the accepted ContractSlice B contract. Operational
packet labels refine delivery; they allocate no new stable work or test ID.
No packet is active merely because it appears here.

ContractSlice B owns:

- cumulative-B public export shape `72`, with zero Domain export change;
- the codec-registration/model-token subset and exact activation mirror;
- three protocol-writer-owned persistent wire families;
- Tests-only private-stamp writer/qualifier/admission paths;
- Observed, Failed, and NoInput proof-candidate admission;
- the codec-model cache, exact-key collision checks, single-flight, bounded
  retention, deterministic eviction, cancellation, and host-failure lifecycle;
- codec-local `GeneratedBytes`, `LayerDepth`, `LayerNodes`, and
  `AdditionalComplexity` metering/ledger closure; and
- ContextProof, Root, and codec-derived qualified-reference sealing.

ContractSlice B does not own parser/index/projector/selector behavior,
provider-neutral capability semantics, parser or index cache, shared-root
ledgers, staged plans, applicability/evaluation, kernel outputs, Policy export,
the initial real-rule set, Scenario activation, workflow filters, or runtime-
efficiency changes.
Those remain held for C, D, or the final atomic activation.

## Frozen dependency graph

```text
accepted exact main
  -> B-SURFACE-01
  -> B-CODEC-ACTIVATION-01
  -> B-WIRE-REPOSITORY-TREE-01
  -> B-WIRE-GOVERNED-TEXT-01
  -> B-WIRE-REPOSITORY-TARGET-01
  -> B-RESOURCE-01
  -> B-CACHE-01
  -> B-ADMISSION-01
  -> B-SEALED-CONTEXT-01
  -> B-CODEC-DERIVATION-01
  -> B-CONVERGE-01
```

One mutating packet may be active at a time. A successor can be designed or
red-teamed while an independent predecessor check runs, but its executable
red or implementation cannot start before the predecessor is locally green,
reviewed, synchronized, pushed, and exact-head hosted green.

## Exact test topology

Every retained test is one direct, non-skipped xUnit `[Fact]` with exactly one
`ContractSlice=B` trait and no `Scenario` trait. No Theory, class-level trait,
generic/overloaded method, inherited fact, or second Scenario value is allowed.

The ordinal, LF-terminated FQN inventory contains exactly `11` identities and
has SHA-256
`FAA35F542B1C88DFD228920CB437A9F38C220591726F1ACCA3D756603DAD62AB`:

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceBActivationTests.Activates_exact_codec_mirror
MeAndAI.Protocol.Conformance.Tests.ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs
MeAndAI.Protocol.Conformance.Tests.ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction
MeAndAI.Protocol.Conformance.Tests.ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire
MeAndAI.Protocol.Conformance.Tests.ContractSliceBOwnershipTests.Enforces_exact_friend_factory_and_negative_surface
MeAndAI.Protocol.Conformance.Tests.ContractSliceBPublicApiTests.Matches_exact_cumulative_b_public_surface
MeAndAI.Protocol.Conformance.Tests.ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing
MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire
MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire
MeAndAI.Protocol.Conformance.Tests.ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger
MeAndAI.Protocol.Conformance.Tests.ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references
```

The structural package owns the PublicApi and Ownership facts. The nine
semantic packages own one Fact and one immutable BehaviorRed ordinal each.
`B-CONVERGE-01` is a pure audit and adds no Fact.

## Packet ledger

| Packet | Frozen contract | Red identity | Required green boundary |
| --- | --- | --- | --- |
| `B-SURFACE-01` | Exact 24-type B public surface, member/nullability/factory inventory, cumulative export count `72`, exact friend matrix, zero Domain export, negative public surface, and transfer of whole-assembly export-total ownership from the retained A PublicApi Fact to the B PublicApi Fact | Permanent SurfaceRed: `CS0246`, `ContractSliceB.SurfaceRed.cs`, `5:38-5:65`, token `IObservedQualificationProof`; no BehaviorRed | PublicApi `1/1`, Ownership `1/1`, B `2/2`, cumulative A+B `34/34`; retained A PublicApi FQN/trait/member snapshot green; no runtime activation |
| `B-CODEC-ACTIVATION-01` | Exact codec-registration/model-token subset, writer/qualifier pair ownership, Tests-only private activation proof, and non-null activated harness | `TEST-0210-B-BEHAVIOR-RED-0001`; `ContractSliceBActivationTests.Activates_exact_codec_mirror` | Focused `1/1`; B `3/3`; A+B `35/35` |
| `B-WIRE-REPOSITORY-TREE-01` | `protocol.repository-tree/1` golden bytes, strict frame, scope/location equality, exact entry-kind/path order, empty tree, malformed grammar | `TEST-0210-B-BEHAVIOR-RED-0002`; `ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire` | Focused `1/1`; B `4/4`; A+B `36/36` |
| `B-WIRE-GOVERNED-TEXT-01` | `protocol.governed-text/1` golden bytes, strict UTF-8 framing, byte preservation, empty body, Repository/Provider leaf matrix | `TEST-0210-B-BEHAVIOR-RED-0003`; `ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire` | Focused `1/1`; B `5/5`; A+B `37/37` |
| `B-WIRE-REPOSITORY-TARGET-01` | `protocol.repository-target-resolution/1` demand echo/digest, ItemId/content tables, three selector variants, canonical row order, self-consistency rejection, wire-local ceilings; no target-index capability semantics | Corrected canonical red `TEST-0210-B-BEHAVIOR-RED-0005`; R=0004 is immutable diagnostic-only; `ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire` | Focused `1/1`; B `6/6`; A+B `38/38` |
| `B-RESOURCE-01` | Codec-local four-counter independent meter, claimed-versus-measured equality, selected payload row plus codec node ledger, checked arithmetic, equality/first-one-over/dominated/unreachable vectors | `TEST-0210-B-BEHAVIOR-RED-0006`; `ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger` | Focused `1/1`; B `7/7`; A+B `39/39` |
| `B-CACHE-01` | Codec-model key bytes, collision closure, single-flight, success/declared-failure retention, deterministic eviction, exact-release/session isolation, no cancellation/host/integrity caching | `TEST-0210-B-BEHAVIOR-RED-0007`; `ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction` | Focused `1/1`; B `8/8`; A+B `40/40` |
| `B-ADMISSION-01` | Receipt frame after measured qualification/cache closure, exact instruction/proof bijection, manifest/type/artifact validation, Observed/Failed/NoInput leaf exclusivity, writer-before-qualifier lifecycle, forged/stale/partial rejection | `TEST-0210-B-BEHAVIOR-RED-0008`; `ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs` | Focused `1/1`; B `9/9`; A+B `41/41` |
| `B-SEALED-CONTEXT-01` | Exact sealed Authority/Manifest/Catalog/slot/scope projection plus ContextProof and Root reference shapes; no raw payload/digest factory and no selector semantics | `TEST-0210-B-BEHAVIOR-RED-0009`; `ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references` | Focused `1/1`; B `10/10`; A+B `42/42` |
| `B-CODEC-DERIVATION-01` | Codec-derived reference frame, manifest component/artifact/model identity, same-or-narrower location, structural comparator, collision and foreign-session rejection; no parser/index derivation | `TEST-0210-B-BEHAVIOR-RED-0010`; `ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing` | Focused `1/1`; B `11/11`; A+B `43/43` |
| `B-CONVERGE-01` | Pure cumulative audit of exact source/test/export/friend/trait/lock/project state; P/R/G `NotApplicable` | None; every canonical red remains immutable and is never rerun | B `11/11`; A+B/full Conformance `43/43`; Domain `98/98`; Release build/format/locks/diff/StructureOnly/publication evidence/reviews green |

### Immutable `B-WIRE-REPOSITORY-TREE-01` hosted-green boundary

The hosted-green activation packet retains the constrained memberless
`ICanonicalPayloadCodec<TModel>` identity and the object-identical Tests-owned
repository-tree mirror. The frozen wire packet extends that same codec/model
identity as a partial Tests-owned writer/qualifier mirror core; it adds no
production codec, alternate interface, adapter, static encoder, registration,
resource meter, cache, or admission behavior. The final generic interface
members remain held until all three wire cores and their dependency-owned
resource carriers exist. The typed design owns the exact golden/empty bytes,
callable staging declarations, error precedence, wire-local ceilings,
two-test-file allowlist, and `1,200`-line redraw threshold. The current
codec/wire memory handoff retains routing and immutable evidence only; it adds
no executable authority. Repository-tree canonical R is immutable, its bounded
green is exact-head hosted green, and it is never rerun.

The exact design cohort is the following twelve existing Markdown paths; no
new tracked node may be added:

```text
.ai/memory/README.md
.ai/memory/log/2026-08-09-feat-0065-subf-0143-contractslice-b-codec-activation-freeze.md
.ai/memory/log/README.md
.ai/memory/project.md
docs/architecture/protocol-governance-and-execution/README.md
docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md
docs/architecture/protocol-governance-and-execution/transition-register.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-b-micro-delivery-plan.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md
docs/features/README.md
```

This cohort must remain edge-neutral: the existing codec/wire handoff remains
the sole detailed ledger, stays at exactly four Markdown links, and replaces
rather than accumulates predecessor commit/run relations. The schema-2 graph
ceilings remain `8,192` relations and `8,388,608` parsed bytes; an exact-tree
projection and fresh wire-specific reviews are mandatory before commit.

### Immutable hosted-green `B-WIRE-GOVERNED-TEXT-01` boundary

The governed-text wire packet extends only the retained same-object Tests-owned
`GovernedTextCodecMirror` and `GovernedTextModelMirror` identities as partial
types. It modifies only `ContractSliceBActivationTests.cs` for those two
partial declarations and adds only
`ContractSliceBGovernedTextCodecTests.cs`; the memberless generic codec
interface and every production/project/package/lock/workflow surface remain
unchanged. The typed design normatively owns the internal callable/result
declarations, Repository/Provider/empty Base64 vectors and SHA-256 identities,
strict UTF-8/BOM grammar, exact failure precedence, body/payload equality and
first-one-over semantics, defensive copying, `1,200`-line redraw threshold,
and the specialized `0003` one-shot runner command.

The exact design cohort remains the same twelve existing Markdown paths named
above. The current memory handoff stays the single detailed B wire ledger and
replaces its predecessor commit/run pair rather than adding relations. No
source/test implementation or canonical red is authorized until this exact
synchronized design head is committed, pushed, and hosted green. Governed-text
green is focused `1/1`, B `5/5`, A+B/full Conformance `37/37`, and Domain
`98/98`; all later packet, Scenario/filter, runtime-efficiency, C/D, merge,
release, and publication holds remain.

### Frozen `B-WIRE-REPOSITORY-TARGET-01` staging boundary

The governed-text implementation is immutable exact-head hosted-green
predecessor evidence. Repository-target extends only the retained same-object
Tests-owned `RepositoryTargetCodecMirror` and `RepositoryTargetModelMirror`
identities as partial types. It modifies only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBActivationTests.cs`
for those two declarations and adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBRepositoryTargetCodecTests.cs`.
The memberless generic codec interface and every production/public/project/
package/lock/workflow/Policy/resource/cache/admission/index/capability surface
remain unchanged.

The typed design normatively owns the internal callable/result/content/row
declarations; exact `318`-byte demand frame and `1,465`-byte golden payload;
three selector families and eight closed result variants; strict row/content
order, digest, self-consistency, error precedence, defensive copying, and six
wire-local equality/first-one-over ceilings; corrected `0005` one-shot runner; and
the packet-specific `3,200` normalized-line redraw threshold. This reviewed
redraw is intentionally larger than the default `1,200` because the packet
must retain all three selector/result grammars and two content-key families in
one same-object mirror; `3,201` or more forces a new design review. It does not
raise any later packet's default threshold.

The sole direct non-skipped Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire`,
with only `ContractSlice=B`, no Scenario/Theory/class trait/overload, and exact
marker `TEST-0210-B-BEHAVIOR-RED-0005`. The red changes only the fully prepared
valid writer's non-null semantic return to `null!`; only that null reaches
direct `Assert.Fail(marker)`. Green is focused `1/1`, cumulative B `6/6`,
A+B/full Conformance `38/38`, and Domain `98/98`.

R=0004 is immutable `OracleRejected/NoCanonicalRed` evidence. Its sole child
returned native `1`, but the valid fixture carried stale digest
`9DF61AC4D5F82C17F68486C14C66C58E65603F02A34A2D2B18B461E74922672E`
instead of the frozen demand-frame SHA-256
`9DF61AC4D5F82C5FDA121B05319B16399580FC0A8D28B4AC62D1879D24899CBA`;
the writer therefore returned a marker-free rejection and the later digest
assertion failed. R=0004 is never rerun. Corrected R=0005 changes only that
constant plus the marker identity before the same null-only canonical red.

The exact design cohort remains the same twelve existing Markdown paths. It
adds no tracked node; schema-2 limits remain `512` nodes, `8,192` relations,
`1,048,576` bytes per parsed blob, and `8,388,608` aggregate parsed bytes.
Runner complete stdout/stderr logs remain `8,388,608` bytes each, report remains
`1,048,576`, and the sole child remains bounded by `420000` monotonic
milliseconds. No canonical red or source/test implementation may begin before
the commit containing this synchronized freeze is pushed and exact-head hosted
green.

### Frozen `B-RESOURCE-01` staging boundary

This packet adds exactly one Tests-owned file:
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBResourceLedgerTests.cs`.
It changes no retained source/test file and no production, project, package,
lock, workflow, Scenario, filter, Domain, Policy, cache, admission, or later
packet surface. The normalized new-file ceiling is `1,200` lines; `1,201`
requires a reviewed redraw. The same twelve existing Markdown paths are the
complete design cohort, no tracked node is added, and the prospective
`v0.17.0` schema-2 limits remain `512` nodes, `8,192` relations, `1,048,576`
bytes per parsed blob, and `8,388,608` aggregate parsed bytes.

The new file owns one direct non-skipped Fact at
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger`,
exactly one `ContractSlice=B` trait, no Scenario/Theory/class trait/overload,
and marker `TEST-0210-B-BEHAVIOR-RED-0006`. Tests-owned mirror carriers stage
the already accepted four-counter algebra without implementing production
interfaces. A same-object resource coordinator calls one independent meter
exactly once after a successful raw value, compares claimed and measured local
usage field-for-field, selects one payload row, adds one codec layer row, and
returns a closed Qualified/Rejected result. Only the fully prepared valid call's
null result may reach direct `Assert.Fail(marker)` in red; every wrong result,
exception, or setup failure remains marker-free.

The golden selected payload is `1,465` bytes at SHA-256
`936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0`.
Its measured local tuple is `(GeneratedBytes=0, LayerDepth=4, LayerNodes=61,
AdditionalComplexity=0)`, producing aggregate `(Bytes=1465, MaxDepth=4,
Nodes=61, Complexity=1526)` and exactly two canonical rows: rank-0 payload then
rank-2 codec layer. The aggregate budget is `(33554432,64,500000,34054432)`.
Checked 64-bit arithmetic, nonnegative values, canonical key order, exact-equal
deduplication, unequal-key collision rejection, equality success, first one-
over rejection, multi-counter precedence `Bytes -> MaxDepth -> Nodes ->
Complexity`, and schema-unreachable repository-target depth `5` rejected before
metering are mandatory. The typed design owns exact declarations, fixture keys,
failure/argument/cancellation precedence, and the complete vector matrix.

Canonical R=0006 is one fresh external runner/root/report/log identity and one
child invocation only. After one warning-as-error Release `--no-restore` build,
the packet-specific test argv is:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0006.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger"
```

The runner repeats exact branch/HEAD/upstream/status/source/self/lock/DLL/PDB
custody at start, pre-build, pre-test, and post-test; permits only the new test
file plus the excluded user-owned NCrunch file; sets child-only
`VSTEST_CONNECTION_TIMEOUT=300`; applies one `420000`-ms monotonic bound; and
uses complete untruncated stdout/stderr logs capped at `8,388,608` bytes each
and an atomic report capped at `1,048,576` bytes. Secure XML parsing, exact one-
file root inventory, result/definition/entry bijection, exact FQN/marker-only
message, exact sixteen counters, optional frozen marker-free stack/echo/RunInfo,
and zero forbidden diagnostics/attachments are required. Atomic
`InvocationCommitted` consumes R=0006 for every process-create, timeout,
interruption, exit, TRX, or oracle outcome; no changed or unchanged retry is
permitted. Only a pre-commit preflight/build failure may be corrected and
revalidated under renewed review.

Green requires focused `1/1`, B `7/7`, cumulative A+B/full Conformance `39/39`,
Domain `98/98`, warning/error-free Release build, format/diff/locks,
StructureOnly, publication evidence `7/7` without a publication claim, and
independent product/test plus evidence/scope reviews `0/0/0`. B-CACHE and every
later packet remain inactive until that implementation head is hosted green.

## SurfaceRed and BehaviorRed contract

`B-SURFACE-01` is the accepted one-diagnostic compile-red exception. The exact
SurfaceRed command and diagnostic tuple remain owned by the typed design. It
proves initial B surface absence once. The public surface must then close as one
reviewed structural phase because exposing multiple missing symbols would
invalidate the one-diagnostic oracle. Its internal file staging cannot be
pushed, published, or treated as independent packet completion.

The retained A PublicApi Fact keeps its exact FQN, direct Fact and
`ContractSlice=A` trait, A-owned 48-type/member snapshot, friend boundary, and
negative surface. Its obsolete whole-assembly-total equality becomes exact
containment of the A-owned exports. The B PublicApi Fact becomes the sole owner
of current cumulative assembly-total equality at `72`. Every later slice
surface repeats this predecessor-containment/current-total ownership transfer.

Each semantic packet begins only after a warning-free Release build of its
accepted predecessor. Its temporary implementation changes exactly the tested
non-null semantic return to `null!`; only that null result may call direct
`Assert.Fail(exactMarker)`. Setup, structural assertions, wrong exceptions,
wrong non-null values, restore/analyzer/environment failures, or console text
cannot emit or substitute the marker.

Every BehaviorRed uses one fresh external result directory, one exact FQN plus
`ContractSlice=B` filter, one TRX logger, exactly one selected/executed/failed
result, exact 16-counter closure, the exact marker-only failed message, the
locked optional assertion stack/summary echo/RunInfo allowances, and no other
diagnostic or attachment. A canonical red is invoked once and never rerun.

### Repository-tree canonical-red runner custody

The `0002` runner is one fresh external regular, non-reparse, CreateNew file at
`D:\Temp\meandai-test-0210-b-wire-r0002-runner-<32-lowercase-hex-guid>.ps1`.
Its canonical LF-plus-terminal-LF byte length, SHA-256, and zero-error
PowerShell AST are frozen before use. Its sibling report and stdout/stderr logs
are separate regular, non-reparse, CreateNew files. Each complete accepted log
is UTF-8, untruncated, at most `8,388,608` bytes, with exact length/SHA custody;
the append-only UTF-8-LF report journal is at most `1,048,576` bytes. A first
byte over either ceiling kills any live child tree, records explicit overflow
when the journal remains writable, and is always `OracleRejected`, never
accepted or silently truncated. Those siblings plus the different fresh
`D:\Temp\meandai-test-0210-b-<32-lowercase-hex-guid>` result root must all be
absent initially. The runner has disjoint `ValidateOnly` and `Execute` modes.
`ValidateOnly` is read-only and creates no script, report, log, root, build, or
test artifact; `Execute` repeats every predicate before committing authority.

At runner start, immediately before build, immediately before test, and after
test immediately before acceptance, the runner rebinds the exact repo root,
branch, future hosted-green design HEAD equal to upstream, no staged delta, and
the complete porcelain allowlist containing only the retained activation-test
modification, the new repository-tree test, and the excluded user-owned NCrunch
file. At those same four gates it binds exact length/SHA of both sources and the
runner; one direct Fact/FQN, sole
`ContractSlice=B`, no Scenario/Theory/class trait, one marker literal, the
null-only direct `Assert.Fail` branch, the partial-only retained identity edit,
and normalized two-test-file delta `<=1,200` are mandatory. The following six
regular lock files remain exact throughout, in Domain, Abstractions,
Conformance, Policy, Domain.Tests, Conformance.Tests order:

```text
03EEADC5EF377C17F787AB65F41FB4C8A9C936BB7F7F4171111FDEEC8A81CB46
D79FF11818ABFE0B6CA9CAEC111778169AA36A04709BCA3E0EC0AB84325BF799
20E6BA80BFB6EDE58228D28560A03B6143F3D163AC5E06720491458FEA9570E7
C57F6AFAEBA953E49D3B6D2CB85E82C00E6A40631507426B1616E57B94724309
D2065F11ED7030EE7DFA7A757FBA2A0D420DAC2F32D0105DFA93D3F78F9B00BC
BA8D8C653CF0CFD2398F9E43F7AB87ED268A9B77EC5FC2E0F81D2BD7849016C0
```

`Execute` sets process-local `DOTNET_CLI_UI_LANGUAGE=en` and performs exactly
`dotnet build tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-incremental --nologo --verbosity minimal -warnaserror`.
It requires exit `0`, zero warnings/errors, then records and seals the freshly
written test DLL/PDB length/SHA/timestamps and uses those exact bytes through
the following packet-specific command, which specializes and supersedes the
generic red template only for this runner:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0002.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire"
```

It creates the still-absent result root once and proves it empty. Immediately before direct child creation it atomically
records `InvocationCommitted`; the parent runner environment must have
`VSTEST_CONNECTION_TIMEOUT` absent before and after the process-scoped child
value `300`. An exact `420000`-ms monotonic outer bound, one child, one logger,
and no discovery/wrapper/retry apply. Timeout kills the whole child tree once.
The only accepted native child exit is integer `1`; the runner exits `0` only
after the complete frozen TRX/root/source/binary oracle.

`InvocationCommitted` irrevocably consumes `R=0002`. A process-create failure,
timeout, runner interruption/crash, unexpected exit, missing/malformed/extra
TRX, or any oracle rejection after that state is immutable `NoSuccess` and is
never retryable with a changed or unchanged runner, timeout, path, or wrapper.
Only `PreflightFailed` or `BuildFailed` before `InvocationCommitted` may be
corrected and revalidated after renewed review without consuming the invocation.

The TRX reader is fail-closed: DTD processing is prohibited, external entity
resolution is disabled with a null resolver, and malformed or nonconforming XML
is `OracleRejected` without any alternate parser or recovery path.

The atomic report schema is
`protocol.canonical-behavior-red-runner-report/1` and records runner/source/Git/
status/line-budget/locks/build/DLL/PDB/root/process/environment/timeout/exit/TRX
custody with start/end UTC and elapsed milliseconds. Terminal states are
`ValidateOnly`, `PreflightFailed`, `BuildFailed`, `InvocationCommitted`,
`TimedOut`, `OracleRejected`, or `CanonicalRedAccepted`. A final accepted
report prints its own path/SHA, TRX path/SHA, native exit `1`, and runner exit
`0`, mutates no repository record, and grants no green authority.

## Packet-local activation gate

Before each packet, freeze and review:

1. the exact predecessor commit/tree and hosted run;
2. the exact source/test path allowlist and explicit non-goals;
3. one FQN/marker/TRX identity or the reviewed `NotApplicable` red rationale;
4. the semantic carrier/oracle and first intended failing boundary;
5. public/friend/export and project/package/lock/workflow deltas;
6. exact focused/B/A+B/full Conformance/Domain commands and cardinalities;
7. resource, concurrency, cancellation, cache, and error ownership where used;
8. a file/line/link budget and graph-capacity projection; and
9. two independent design reviews closing `0 Blocking / 0 Important / 0 Minor`.

No active packet may mutate more than eight production files and two test files
or add more than 1,200 normalized lines without a reviewed redraw. The one
structural exception may create at most 24 public-type carrier files plus two
B test files, modify only the retained A PublicApi test file for the exact
total-to-containment ownership transfer above, and add at most 2,500 normalized
source/test lines. The exact public type inventory, not one-type-per-file
layout, is authoritative and the packet owns no semantic activation.
Existing project, package, lock, workflow, every other A test/source file, and
Domain source files are immutable unless a packet freeze names and proves an
unavoidable exact change. No packet may change the final
Scenario/status/owner/filter route.

## Green, review, and delivery gates

After bounded implementation, each packet must pass, in order:

1. exact focused Fact;
2. exact cumulative `ContractSlice=B` and `ContractSlice=A|ContractSlice=B`;
3. full Conformance and Domain suites;
4. Release build with zero warnings/errors, format, six lock hashes, and diff;
5. StructureOnly and bounded publication-evidence without publication claim;
6. fresh code/test review and independent evidence/scope review, both `0/0/0`;
7. record and memory synchronization without raw stable-ID or document-path
   pseudo-links;
8. exact staged allowlist and instruction-graph ceilings;
9. commit/push/draft-PR update; and
10. exact-head Ubuntu/Windows hosted green with publication skipped.

A hosted or local infrastructure failure is classified by the active recurrence
contract and never auto-retried as semantic red/green evidence. A product,
test, design, or canonical-record failure reopens only the current packet.

## Design-delivery allowlist

This design delivery may change only the owning feature architecture,
feature, test, micro-plan, transition, memory, and index records plus this new
plan and one dated memory handoff. It changes no source, executable test,
project, package, lock, workflow, release, or consumer file. The user-owned
`MeAndAI.Protocol.v3.ncrunchsolution.user` remains untracked and excluded.

## Exit condition

This plan records repository-target exact-head hosted green. The surface, codec
activation, repository-tree, governed-text, and repository-target packets are
immutable hosted-green history. R=0004 is diagnostic-only; canonical R=0005 is
accepted, focused/B/full Conformance/Domain are `1/1`, `6/6`, `38/38`, and
`98/98`, and the bounded executable delta is `2,849/3,200` normalized lines. B
is `6/11` and cumulative A+B is `38/43`. `B-RESOURCE-01` is `FrozenDesign`/
inactive until the commit containing this exact synchronized design is pushed
and exact-head hosted green; every successor remains held. C/D, final
activation, feature DoD, release, publication, consumer mutation, authority
transfer, and PowerShell retirement remain held.
