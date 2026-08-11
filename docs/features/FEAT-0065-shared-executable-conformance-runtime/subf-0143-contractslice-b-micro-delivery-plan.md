# [SUBF-0143](README.md#subf-0143) - ContractSlice B Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | B surface, codec, three wire packets, `B-RESOURCE-01`, `B-CACHE-01`, and `B-ADMISSION-01` exact-head hosted green; repository-target R=0004 plus admission R=0008/R=0009/R=0010 diagnostic/no-success, R=0005, resource R=0006, cache R=0007, admission R=0011, and sealed-context R=0012 accepted/immutable; `B-SEALED-CONTEXT-01` `ReviewedLocalGreen` with its implementation head hosted pending; B `10/11`, cumulative A+B `42/43`; `B-CODEC-DERIVATION-01` `FrozenDesign`/inactive pending that synchronized head's hosted gate |
| Parent | Owning feature and current subfeature |
| Scenario | [TEST-0210](test-cases.md#test-0210), still `Planned` |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Ordered-B authority | [Maintainer directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5230762350) |
| Accepted predecessor | Accepted A merge commit [`51623f4d404a95e0f706d72805cf7ddbbbd293b8`](https://github.com/hasanmanzak/meAndAI/commit/51623f4d404a95e0f706d72805cf7ddbbbd293b8); exact-main [run 31304787603](https://github.com/hasanmanzak/meAndAI/actions/runs/31304787603) passed Ubuntu `6m11s`, Windows `11m21s`, publication verification skipped |
| Normative owner | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Implementation language | C# only; the admission correction remains limited to its two test-owned files; later packets remain held |

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
| `B-ADMISSION-01` | Receipt frame after measured qualification/cache closure, exact instruction/proof bijection, manifest/type/artifact validation, Observed/Failed/NoInput leaf exclusivity, writer-before-qualifier lifecycle, forged/stale/partial rejection; R=0008, R=0009, and R=0010 are immutable diagnostics/no-success | Third-corrected `TEST-0210-B-BEHAVIOR-RED-0011`; `ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs` | Focused `1/1`; B `9/9`; A+B `41/41` |
| `B-SEALED-CONTEXT-01` | Exact sealed Authority/Manifest/Catalog/slot/scope projection plus ContextProof and Root reference shapes; no raw payload/digest factory and no selector semantics | `TEST-0210-B-BEHAVIOR-RED-0012`; `ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references` | Focused `1/1`; B `10/10`; A+B `42/42` |
| `B-CODEC-DERIVATION-01` | Codec-derived reference frame, manifest component/artifact/model identity, same-or-narrower location, structural comparator, collision and foreign-session rejection; no parser/index derivation | `TEST-0210-B-BEHAVIOR-RED-0013`; `ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing` | Focused `1/1`; B `11/11`; A+B `43/43` |
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
the sole detailed ledger, stays at no more than four Markdown links, and replaces
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

R=0006 is accepted once and never rerun. Bounded green is `1/1`, `7/7`,
`39/39`, and `98/98`, with Release `0/0`, format/diff clean, `1,176/1,200`
source lines, and zero production delta. Final exact-tree publication evidence
is `7/7` in `285.2s` without publication claim and StructureOnly is green at
`elapsedMs=439938`. The exact implementation identity and hosted run are owned
by the canonical B ledger: Ubuntu passed in `15m52s`, Windows in `49m31s`, and
publication verification was skipped.

### Frozen `B-CACHE-01` staging boundary

This packet adds exactly one Tests-owned file,
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBDecodeModelCacheTests.cs`,
bounded at `1,200` normalized lines; `1,201` requires redesign before build/red.
It changes no retained file and no production, interface, project, package,
lock, workflow, Scenario, admission, sealed-context, reference, Policy, C, or D
surface. The same twelve Markdown/memory paths form the complete design cohort;
no tracked node is added. Schema-2 stays `512` nodes / `8,192` relations /
`1,048,576` bytes per parsed blob / `8,388,608` aggregate, and the typed design
must retain at least `2,048` bytes of per-blob headroom.
P is `NotApplicable`; R adds the complete new Tests-owned mirror with only the
final valid aggregate return as `null!`; G changes only that return to the
already computed non-null aggregate. No intermediate source is deliverable.

The new file owns one direct Fact at
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction`,
one `ContractSlice=B` trait, no Scenario/Theory/class trait, and marker
`TEST-0210-B-BEHAVIOR-RED-0007`. It stages one Tests-only exact-release/session
decode-model cache over opaque validated canonical key bytes. The typed design
solely owns the exact carriers, three 89-byte Base64/SHA fixtures, collision
probe, result union, concurrency/single-flight lifecycle, retainable and
non-retainable outcomes, deterministic low-key eviction, equality/first-over
vectors, release/session isolation, and failure precedence.

Only byte-equal digest candidates reuse. Equal digest with unequal bytes is an
integrity exception before producer invocation. Same-key callers share one
attempt; pending new keys are dispatched in canonical byte order within the
positive concurrency ceiling. Success and declared typed failure may be cached.
Cancellation, timeout, unexpected host exception, and integrity failure are
propagated and never retained. Retention greedily keeps canonical-lowest entries
under checked count and canonical-byte ceilings, continues after oversized
entries, accepts equality, rejects the first crossing entry, and is disabled by
either zero ceiling. Release/session mismatch never reuses an entry.

Only the final fully valid aggregate assertion's null result reaches direct
`Assert.Fail(marker)` in red. Canonical R=0007 uses one fresh external runner,
root, report, and complete logs under the accepted R=0006 custody contract. Its
packet-specific child command is:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0007.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction"
```

The runner binds exact hosted design HEAD/upstream/branch/status, sole source and
self identities at four gates, six locks, warning-as-error Release build, fresh
DLL/PDB, child-only timeout `300`, outer `420000` ms, complete logs capped at
`8,388,608` bytes, atomic report capped at `1,048,576`, secure XML, native exit
`1`, one exact TRX result/definition/entry, sixteen counters, and no forbidden
diagnostics/attachments. `InvocationCommitted` consumes R=0007 for every outcome;
no changed or unchanged retry exists. Green requires focused `1/1`, B `8/8`,
A+B/full Conformance `40/40`, Domain `98/98`, build/format/locks/diff/
StructureOnly/publication, and two fresh reviews `0/0/0`. At that
pre-implementation checkpoint B-ADMISSION and later packets remained held
through the exact cache implementation-head hosted gate.

The accepted R=0007 evidence is immutable and never rerun: exact runner
`35,007` bytes / SHA-256 `5967E18E...FEA0AC`; red source `1,063/1,200` lines /
SHA-256 `999B4E84...EDB9E`; native/runner exit `1/0`; report SHA-256
`3B380FBB...9D3291`; sole TRX SHA-256 `514CCAE6...FBFE52`; one exact failed
result/definition/entry, sixteen counters, and no attachments/collector data.
Bounded green changes only the final aggregate return. Its source is
`1,063/1,200` lines / `38,102` bytes / SHA-256 `41F3FC40...4717E4`, production
delta is zero, build is `0/0`, focused/B/full Conformance/Domain are `1/1`,
`8/8`, `40/40`, and `98/98`, and format/diff are clean. Exact-tree
StructureOnly is green; publication evidence is `7/7` without a publication
claim; both fresh final reviews are `0/0/0`.
The owning ledger's exact cache implementation identity passed Ubuntu in
`20m42s` and Windows in `49m17s`; publication verification was skipped.
B-CACHE is immutable hosted history.

### Immutable hosted-green `B-ADMISSION-01` staging boundary

This packet modifies only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBActivationTests.cs`
and adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBAdmissionProofTests.cs`.
Their combined normalized changed-line count is at most `2,400`; `2,401`
requires reviewed redesign before build/red. This packet-specific exception
does not raise the general `1,200`-line B ceiling: it owns three closed proof
leaves, two canonical frames, and the full bijection/lifecycle matrix in one
test-owned boundary. Production, project, package,
lock, workflow, Scenario, Policy, C, D, sealed-context, and reference deltas are
zero. The design cohort is exactly the twelve existing Markdown/memory paths
listed above, adds no tracked node and no new Markdown relation, and stays under
schema-2 `512` nodes / `8,192` relations / `1,048,576` bytes per blob /
`8,388,608` aggregate. The retained activation file only exposes its existing manifest helper
internally and extends `ContractSliceBActivationProof` with a defensively copied
optional exact candidate-reference allowlist; default-empty construction keeps
the existing activation Fact byte-semantically unchanged and
`Proves(IAdmissionProofCandidate)` false for every non-allowlisted object.

The new file owns one direct Fact,
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs`,
one `ContractSlice=B` trait, no Scenario/Theory/class trait, and third-corrected marker
`TEST-0210-B-BEHAVIOR-RED-0011`. P is `NotApplicable`. R implements the complete
test-owned admission mirror and sets only its final valid aggregate return to
`null!`; G restores that already computed aggregate. The retained activation
Fact must remain green through both identities.

The fixture rebuilds only the three manifest admission declarations so their
Observed, Failed, and NoInput proof components are the exact three test-owned
candidate types bound to `MeAndAI.Protocol.Conformance.Tests.dll`. The source
manifest's `MeAndAI.Protocol.Application.dll` artifact row is removed because
its only three component bindings are precisely the replaced admission-proof
components; retaining that row would leave an unbound artifact and must fail
canonical parsing. Contract keys/versions, surfaces, material roles, activation
proof, payload schemas, all non-admission components, and every other artifact
row/order/digest remain unchanged.
Three canonical singleton instructions bind, respectively,
`protocol.slot.repository-tree`, `protocol.slot.provider-governed-text`, and
`protocol.slot.repository-target-resolution` to Repository Observed, Provider
Failed, and Repository NoInput requests. The typed design owns their exact
target/request values, strict frame grammar, receipt projection, closed
qualification/cache/resource state, and declarations.

Admission enumerates each proof collection once, flattens exactly one leaf per
candidate, and proves a bijection over singleton SlotKey, InstructionDigest,
candidate object, and ReceiptDigest. It revalidates exact manifest digest,
contract kind/key/version, CLR proof type, component/artifact binding, allowed
surface/material role, request, activation-proof reference, instruction frame,
receipt frame, and variant tail. Observed alone carries a complete structural
result, exact codec binding, and privately stamped post-qualification state
whose claimed/measured four counters match and whose cache disposition is
Produced or Retained. Failed carries complete request failure coverage. NoInput
has no result/tail and proves no writer, qualifier, or cache call.

The lifecycle vectors are exact: source-intent rejection calls no downstream
stage; writer rejection calls writer once and no qualifier/meter/cache;
successful write then qualifier rejection calls writer/qualifier once and no
meter/cache; only write plus qualification plus one measured-state closure and
one cache completion produces Observed. NoInput calls none; cancellation,
timeout, cache-integrity, or host failure produces no candidate.
Missing/extra/duplicate, null, dual-leaf, multi-slot, wrong/stale
manifest/instruction/request/contract/type/artifact/surface/material/activation,
partial Observed state, and mutated receipt all fail atomically with
`CatalogIntegrityCode.AdmissionProofInvalid`. Equal supplied digest with unequal
canonical receipt bytes fails first with `CacheIdentityCollision`. No partial
receipt set escapes.

R=0008 is immutable diagnostic/no-success and is never rerun. Its sole child
executed the exact Fact but failed during manifest parsing before the marker:
`System.FormatException: The manifest artifactFiles array must be fully bound.`
The one TRX had raw marker count `0`; the runner correctly rejected the attempt.
The exact artifact and runner custody is retained by the owning handoff.

R=0009 is a second immutable diagnostic/no-success and is never rerun. Its
exact corrected-design head was hosted green, its warning-free build and sole
exact-FQN child ran, but the complete five-rule catalog reached
`CreateInstructions` where the fixture incorrectly called `Rules.Single()`.
The child failed marker-free with `System.InvalidOperationException: Sequence
contains more than one element`; raw marker count was `0` and the runner ended
`OracleRejected`. The owning handoff retains exact script/root/TRX/report/log
custody.

R=0010 is a third immutable diagnostic/no-success and is never rerun. The exact
second-correction design head was hosted green and its sole warning-free child
selected the exact Fact, but the Joined negative vector reached
`AdmissionMirrorFrame.WriteObserved`, whose frame switch encoded only Produced
and Retained. It threw marker-free `System.InvalidOperationException: Operation
is not valid due to the current state of the object.` before admission; raw
marker count was `0` and the runner ended `OracleRejected`. Exact artifact
custody remains in the owning handoff.

The retained second correction flattens rules in canonical manifest order and
requires exact slot occurrence
counts Provider governed-text=`3`, repository-target=`3`, repository-tree=`2`,
and chooses the first occurrence only after every repeated declaration equals
it in requirement, profile surfaces, material role, target-selector key, and
ordered capability identities. Missing, extra, or semantically unequal repeats
fail marker-free before admission. Third-corrected R=0011 retains all of that
and changes only the marker plus the test-owned receipt-frame switch:
Produced=`0`, Retained=`1`, Joined=`2`, and every unknown value remains
unencodable. Rank `2` exists solely to give the invalid Joined candidate a
deterministic identity so the coordinator can reject it as
`AdmissionProofInvalid`; Joined never becomes a valid admitted state. No
manifest, instruction, admission, final `null!`, allowlist, or line-cap change
is permitted.

The third-corrected packet-specific canonical red command is Release `--no-restore
--no-build` against the exact FQN/filter above, one fresh R=0011 TRX logger/root,
process-scoped `VSTEST_CONNECTION_TIMEOUT=300`, and a fresh `420000`-ms/8-MiB-
log/1-MiB-report one-shot runner. Its TRX oracle requires one marker-only error
message, permits zero or one byte-identical marker echo in the same result's
StdOut, permits zero or one marker-free same-FQN `[FAIL]` RunInfo, and therefore
accepts raw marker count only in `[1,2]`; all sixteen counters and every other
diagnostic/attachment prohibition remain exact. Green is focused `1/1`, B `9/9`,
A+B/full Conformance `41/41`, Domain `98/98`, build/format/locks/diff/
StructureOnly/publication, and two fresh `0/0/0` reviews. At that design
checkpoint, B-SEALED-CONTEXT and all later scopes remained held until the exact
admission implementation head became hosted green; the immutable evidence below
closes that predecessor gate only.

Canonical R=0011 is accepted and immutable. Its one-shot runner bound exact
hosted design head, source/status/locks, and `1,676/2,400` lines; the sole child
returned native exit `1` and produced one exact marker-only failed result. The
TRX is `4,868` bytes / SHA-256 `B28FC956...5E36`, report `15,213` /
`34341B88...9167`, with exact sixteen counters and no forbidden diagnostics or
attachments. Bounded green changes only the final aggregate return and passes
focused `1/1`, B `9/9`, full Conformance `41/41`, Domain `98/98`, Release build
`0/0`, format/diff, publication `7/7` without publication claim, and
StructureOnly. Code/test and evidence/scope reviews are `0/0/0`. The exact
implementation head then passed Ubuntu in `20m17s` and Windows in `42m17s`;
publication verification was skipped. B-ADMISSION is immutable exact-head
hosted green and is the accepted predecessor for the following freeze.

### Frozen `B-SEALED-CONTEXT-01` staging boundary

This packet modifies only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBAdmissionProofTests.cs`
to change `ExecuteContract` and `CreateAdmissionManifest` from `private static`
to `internal static`, prepend exact `AuthorityKind`, `ManifestDigest`, and
`CatalogVersion` identity to the Tests-owned `AdmissionAggregateMirror`, and
populate those values from the admitted manifest; it adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBSealedContextTests.cs`.
The retained admission Fact, marker, frames, candidates, receipts, and every
existing assertion remain byte-semantically unchanged; the three successor-
owned fields close detached aggregate-to-manifest authority without adding a
second aggregate or production seam. Combined normalized changed lines are at
most `1,200`; `1,201` requires reviewed redesign. Production, public API,
project, package, lock, workflow, Policy, Scenario, C, and D deltas are exactly
zero.

The new file owns one direct Fact,
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references`,
one `ContractSlice=B` trait, no Scenario/Theory/class trait, and marker
`TEST-0210-B-BEHAVIOR-RED-0012`. P is `NotApplicable`. R implements the complete
Tests-owned seal core but returns `null!` only after the fully prepared valid
projection; only that null reaches `Assert.Fail(Marker)`. G restores the already
computed non-null projection. No alternate factory, adapter, second aggregate,
or production coordinator is introduced.

The exact Tests-owned declarations are one static
`ContractSliceBSealedContextCoordinatorMirror.Seal(FinalizedPolicyManifest,
AdmissionAggregateMirror)` method returning nullable
`SealedContextProjectionMirror`, and one closed projection record containing
one actual `SealedEvaluationContext`, one actual `QualifiedEvidenceReference`
ContextProof, and a defensively copied root-reference list. The core uses the
existing internal constructors of those public carriers; it adds no public
constructor/factory and exposes no payload bytes, mutable digest seam, selector,
derivation, parser, index, or kernel behavior.

The valid fixture is exact. The independently rebuilt admission manifest has
`QualificationSlice` authority and the same exact authority/digest/catalog-
version triple carried by the accepted aggregate. The aggregate has three
ordinal receipts, leaf counts `(1,1,1)`, and a closed lifecycle. Failed and
NoInput remain non-admitted and mint no scope/reference. Only the complete
Observed repository-tree receipt
admits slot `protocol.slot.repository-tree` and scope Repository/ExactCommit at
the synthetic commit value: `0123456789abcdef0123456789abcdef01234567`. The ContextProof binds exact
manifest/catalog, slot, requirement `protocol.requirement.repository-tree`,
scope, and receipt digest, with null root/location/parent/selector and zero
derivations. Its one Root reference retains the exact structural
`RootEvidenceReference` and location with the same identities/digest and the
same four null/empty negative fields. Context admitted-slot and scope lists plus
the root list are ordinal, unique, immutable copies.

Validation precedence is exact: null arguments; manifest authority/slice and
catalog identity; aggregate lifecycle, leaf-count, null/order/duplicate and
receipt-digest closure; canonical slot/requirement and complete Observed
context/binding/root coherence. Manifest defects map to `ManifestInvalid` and
aggregate/admission defects to `AdmissionProofInvalid`. The coordinator accepts
no caller-supplied reference, derivation, parent, or selector, so exact minted
reference shapes are positive postconditions rather than an invented
`ReferenceInvalid` input seam. Reordered, duplicate, unknown-slot, forged-
receipt-digest, incomplete lifecycle, wrong leaf counts, scope/root mismatch,
Failed/NoInput admission, mutable input, and foreign-manifest aggregate vectors
are marker-free. Malformed/foreign-session derived-reference rejection remains
owned by `B-CODEC-DERIVATION-01`; no partial context/reference set escapes.

The canonical R command is one Release `--no-restore --no-build` invocation of
the exact FQN/filter above, one fresh R=0012 TRX logger/root, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, and the retained `420000`-ms/8-MiB-log/1-MiB-
report one-shot custody. `InvocationCommitted` consumes R=0012; process-create,
timeout, exit, interruption, root/TRX, source/binary, or oracle failure is
immutable no-success/no-retry. The exact one-result marker/TRX/16-counter/no-
attachment oracle is unchanged. Green is focused `1/1`, B `10/10`, A+B/full
Conformance `42/42`, Domain `98/98`, warning-free Release build, format, six
locks, diff, StructureOnly, publication evidence, and two fresh `0/0/0`
reviews. B-CODEC-DERIVATION and all later scopes remain held.

### Accepted `B-SEALED-CONTEXT-01` red and local green

The corrected design predecessor passed exact-head hosted validation. Canonical
R=0012 then ran once from its fresh external runner and is accepted/immutable:
native exit `1`, runner exit `0`, one exact Failed result/definition/entry,
marker count `2`, total/executed/failed `1/1/1`, all other thirteen counters
zero, and no attachment/collector data. Its sole TRX is `4,842` bytes / SHA-256
`24B78DD8AEF0B7D95B7D9FB653A233B333D2EB10DB71893516C00F01D73A98B4`;
the append-state report SHA-256 is
`3764392A7E5CDCC3E1A2F7C447067492053D25340C60DE408A765A77A15E3A21`.
R=0012 is never rerun.

Bounded green removes the marker/null branch and changes no other behavior.
The retained admission source is `64,871` bytes / SHA-256
`D6E34E10A121447FE25906451FEAE2623D3B18D0B0AA1CD6EC2C1123C5066E63`;
the final sealed-context source is `534` lines, `20,197` bytes / SHA-256
`D83BB1E5A729F5890F8D2B577209C200802478EDEE6D0068C1D909BAF89F1AC6`;
combined changed lines are `549/1,200`. Focused/B/full Conformance/Domain are
`1/1`, `10/10`, `42/42`, and `98/98`; Release build is zero warnings/errors,
format and diff are clean. B-SEALED-CONTEXT is `ReviewedLocalGreen`; its
implementation head remains hosted pending. No downstream authority follows.

### Frozen `B-CODEC-DERIVATION-01` staging boundary

This final executable B packet adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBQualifiedReferenceTests.cs`.
It modifies no existing source and has no production, public API, project,
package, lock, workflow, Policy, Scenario, C, or D delta. The new file is at
most `1,200` normalized lines; `1,201` requires reviewed redesign.

The file owns exactly one direct Fact,
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing`,
one `ContractSlice=B` trait, no Scenario/Theory/class trait/overload, and marker
`TEST-0210-B-BEHAVIOR-RED-0013`. P is `NotApplicable`. R implements every
valid and negative assertion but returns `null!` only after both valid derived
references are fully prepared; only that null reaches `Assert.Fail(Marker)`.
G restores only the already computed read-only result.

The exact Tests-owned callable surface is:

```csharp
internal sealed record CodecDerivedReferenceFrameMirror(
    QualifiedEvidenceReference Parent,
    ComponentArtifactBinding Codec,
    ExactSha256Digest ArtifactDigest,
    ModelContractIdentity OutputModel,
    string TypedNodeKind,
    string TypedNodeIdentity,
    EvidenceLocation Location);

internal static class ContractSliceBCodecDerivedReferenceCoordinatorMirror
{
    internal static IReadOnlyList<QualifiedEvidenceReference>? Seal(
        FinalizedPolicyManifest manifest,
        SealedContextProjectionMirror context,
        IReadOnlyList<CodecDerivedReferenceFrameMirror> frames);
}
```

There is no alternate codec, adapter, public factory, production coordinator,
raw payload/digest input, selector, parser, index, capability, cache, resource,
admission, or kernel seam. `Seal` defensively copies the frame collection and
uses only the actual finalized manifest plus the accepted sealed projection.

The valid fixture is exact. It rebuilds the admission manifest/aggregate and
seals the accepted projection. The sole root parent structurally owns exact
manifest digest, catalog version, slot `protocol.slot.repository-tree`,
requirement `protocol.requirement.repository-tree`, repository ExactCommit
scope, qualification-proof digest, root, and Snapshot location. The manifest's
unique repository-tree schema resolves one codec component binding, its exact
artifact file and artifact digest, and its exact output-model identity.

Two already ordinal frames are required. Frame zero retains the parent Snapshot
location and uses typed node kind `protocol.codec-output.repository-tree` plus
identity `<model-key>@<model-version>`. Frame one narrows to
`RepositoryEvidenceLocation` at `AGENTS.md`, blob identity equal to the exact
commit, no line/anchor/property refinement, the same kind, and identity
`<model-key>@<model-version>#AGENTS.md`. Each output is kind `Derived`, retains
the exact parent manifest/catalog/slot/requirement/scope/proof/root identities,
uses its frame location, contains exactly one `QualifiedEvidenceDerivation`
with the exact codec component/artifact/digest/output model, null output
capability, exact typed node kind/identity and location, and has null
ExpectedSelectorParentKind/Selector. The output list is a defensive copy.

Validation precedence is exact:

1. null manifest/context/frame collection is the corresponding
   `ArgumentNullException`; a null frame element is `ArgumentException` with
   `ParamName=frames`;
2. wrong manifest authority/slice/complete-catalog state or any sealed-context
   authority/digest/catalog/slot/scope inequality is `ManifestInvalid`;
3. a parent that is not structurally identical to the sole accepted Root,
   including foreign manifest/catalog/proof/scope/root/location identity, is
   `ReferenceInvalid`;
4. codec component/artifact file/artifact digest/output model that is not the
   unique repository-tree manifest binding is `ReferenceInvalid`;
5. wrong/empty typed-node values, any location wider than Snapshot or not
   exactly Snapshot-equal/Repository-narrower under the same scope, and any
   Repository blob/refinement drift is `ReferenceInvalid`; and
6. frames must be strictly ordinal by `(TypedNodeKind, TypedNodeIdentity)`;
   duplicate keys, reordered rows, and same-key unequal rows are collisions and
   map to `ReferenceInvalid` before any output escapes.

Reference comparison is field-by-field and ordinal across kind, manifest,
catalog, slot, requirement, scope, proof, root, location, ordered derivations,
parent-kind and selector; object identity is never authority. Separately rebuilt
structurally equal inputs must produce structurally equal output. Mutating the
caller frame array after sealing cannot affect the result. Every negative vector
is marker-free and no partial result escapes.

Canonical R=0013 is one exact warning-free Release build followed by exactly:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory <fresh-root> --logger trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0013.trx --filter ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing
```

This packet-specific command supersedes the generic red template only for
R=0013. It retains fresh external CreateNew runner/report/log custody, exact
source/runner/head/upstream/branch/full-status checks at start/pre-build/pre-test/
post-test, six lock hashes, warning/error-free build, exact DLL/PDB, process-only
`VSTEST_CONNECTION_TIMEOUT=300`, one child/logger, monotonic `420000`-ms bound,
complete `8,388,608`-byte stdout/stderr ceilings, `1,048,576`-byte report,
secure no-DTD/no-external-resolution XML, exact one-result marker/optional-stack/
echo/RunInfo/16-counter/no-diagnostic/no-attachment oracle, and native exit `1`.
`InvocationCommitted` irrevocably consumes R=0013; process-create, timeout,
unexpected exit, interruption/crash, missing/malformed/extra TRX, or oracle
rejection is immutable no-success/no-retry. Only pre-commit preflight/build
failure may be corrected and revalidated without creating R.

Green is focused `1/1`, B `11/11`, A+B/full Conformance `43/43`, Domain `98/98`,
warning/error-free Release build, format, six locks, diff, StructureOnly,
publication evidence without publication claim, and two fresh `0/0/0` reviews.
B-CONVERGE remains P/R/G `NotApplicable`; parent [TEST-0210](test-cases.md#test-0210), final Scenario/
status/owner and both workflow filters, the runtime-efficiency scenario, C/D,
activation, merge, release, publication, and DoD remain held. This design grants no R or
implementation authority until the synchronized B-SEALED implementation plus
B-CODEC-DERIVATION design commit itself is exact-head hosted green.

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

This plan records repository-target and resource exact-head hosted green. The
surface, codec, three wire packets, and resource packet are immutable hosted
history. Resource R=0006 is accepted once and never rerun; focused/B/full
Conformance/Domain are `1/1`, `7/7`, `39/39`, and `98/98`, and the Tests-only
source is `1,176/1,200` normalized lines with zero production delta. Cache
R=0007 is accepted once and never rerun; `B-CACHE-01` is exact-head hosted green
at focused/B/full/Domain `1/1`, `8/8`, `40/40`, and `98/98`, with one
`1,063/1,200`-line Tests-only file and zero production delta. Admission R=0008,
R=0009, and R=0010 are immutable diagnostics/no-success; R=0011 and sealed-
context R=0012 are accepted/immutable. B-ADMISSION is exact-head hosted green;
B-SEALED-CONTEXT is `ReviewedLocalGreen` with its implementation head hosted
pending. B is `10/11`, cumulative A+B is `42/43`; B-CODEC-DERIVATION is
`FrozenDesign`/inactive pending that synchronized head's hosted gate.
B-CONVERGE remains held.
C/D, final
activation, feature DoD, release, publication, consumer mutation, authority
transfer, and PowerShell retirement remain held.
