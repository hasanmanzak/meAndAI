# [SUBF-0143](README.md#subf-0143) - ContractSlice B Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | `FrozenDesign`; implementation inactive pending this design delivery's exact-head hosted-green gate and a separate implementation directive |
| Parent | Owning feature and current subfeature |
| Scenario | [TEST-0210](test-cases.md#test-0210), still `Planned` |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Design-only authority | [Maintainer directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5230762350) |
| Accepted predecessor | Accepted A merge commit [`51623f4d404a95e0f706d72805cf7ddbbbd293b8`](https://github.com/hasanmanzak/meAndAI/commit/51623f4d404a95e0f706d72805cf7ddbbbd293b8); exact-main [run 31304787603](https://github.com/hasanmanzak/meAndAI/actions/runs/31304787603) passed Ubuntu `6m11s`, Windows `11m21s`, publication verification skipped |
| Normative owner | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Implementation language | C# only; this design delivery changes no executable surface |

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
| `B-SURFACE-01` | Exact 24-type B public surface, member/nullability/factory inventory, cumulative export count `72`, exact friend matrix, zero Domain export, and negative public surface | Permanent SurfaceRed: `CS0246`, `ContractSliceB.SurfaceRed.cs`, `5:38-5:65`, token `IObservedQualificationProof`; no BehaviorRed | PublicApi `1/1`, Ownership `1/1`, B `2/2`, cumulative A+B `34/34`; no runtime activation |
| `B-CODEC-ACTIVATION-01` | Exact codec-registration/model-token subset, writer/qualifier pair ownership, Tests-only private activation proof, and non-null activated harness | `TEST-0210-B-BEHAVIOR-RED-0001`; `ContractSliceBActivationTests.Activates_exact_codec_mirror` | Focused `1/1`; B `3/3`; A+B `35/35` |
| `B-WIRE-REPOSITORY-TREE-01` | `protocol.repository-tree/1` golden bytes, strict frame, scope/location equality, exact entry-kind/path order, empty tree, malformed grammar | `TEST-0210-B-BEHAVIOR-RED-0002`; `ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire` | Focused `1/1`; B `4/4`; A+B `36/36` |
| `B-WIRE-GOVERNED-TEXT-01` | `protocol.governed-text/1` golden bytes, strict UTF-8 framing, byte preservation, empty body, Repository/Provider leaf matrix | `TEST-0210-B-BEHAVIOR-RED-0003`; `ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire` | Focused `1/1`; B `5/5`; A+B `37/37` |
| `B-WIRE-REPOSITORY-TARGET-01` | `protocol.repository-target-resolution/1` demand echo/digest, ItemId/content tables, three selector variants, canonical row order, self-consistency rejection, wire-local ceilings; no target-index capability semantics | `TEST-0210-B-BEHAVIOR-RED-0004`; `ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire` | Focused `1/1`; B `6/6`; A+B `38/38` |
| `B-RESOURCE-01` | Codec-local four-counter independent meter, claimed-versus-measured equality, selected payload row plus codec node ledger, checked arithmetic, equality/first-one-over/dominated/unreachable vectors | `TEST-0210-B-BEHAVIOR-RED-0005`; `ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger` | Focused `1/1`; B `7/7`; A+B `39/39` |
| `B-CACHE-01` | Codec-model key bytes, collision closure, single-flight, success/declared-failure retention, deterministic eviction, exact-release/session isolation, no cancellation/host/integrity caching | `TEST-0210-B-BEHAVIOR-RED-0006`; `ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction` | Focused `1/1`; B `8/8`; A+B `40/40` |
| `B-ADMISSION-01` | Receipt frame after measured qualification/cache closure, exact instruction/proof bijection, manifest/type/artifact validation, Observed/Failed/NoInput leaf exclusivity, writer-before-qualifier lifecycle, forged/stale/partial rejection | `TEST-0210-B-BEHAVIOR-RED-0007`; `ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs` | Focused `1/1`; B `9/9`; A+B `41/41` |
| `B-SEALED-CONTEXT-01` | Exact sealed Authority/Manifest/Catalog/slot/scope projection plus ContextProof and Root reference shapes; no raw payload/digest factory and no selector semantics | `TEST-0210-B-BEHAVIOR-RED-0008`; `ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references` | Focused `1/1`; B `10/10`; A+B `42/42` |
| `B-CODEC-DERIVATION-01` | Codec-derived reference frame, manifest component/artifact/model identity, same-or-narrower location, structural comparator, collision and foreign-session rejection; no parser/index derivation | `TEST-0210-B-BEHAVIOR-RED-0009`; `ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing` | Focused `1/1`; B `11/11`; A+B `43/43` |
| `B-CONVERGE-01` | Pure cumulative audit of exact source/test/export/friend/trait/lock/project state; P/R/G `NotApplicable` | None; every canonical red remains immutable and is never rerun | B `11/11`; A+B/full Conformance `43/43`; Domain `98/98`; Release build/format/locks/diff/StructureOnly/publication evidence/reviews green |

## SurfaceRed and BehaviorRed contract

`B-SURFACE-01` is the accepted one-diagnostic compile-red exception. The exact
SurfaceRed command and diagnostic tuple remain owned by the typed design. It
proves initial B surface absence once. The public surface must then close as one
reviewed structural phase because exposing multiple missing symbols would
invalidate the one-diagnostic oracle. Its internal file staging cannot be
pushed, published, or treated as independent packet completion.

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
test files and add at most 2,500 normalized lines; the exact public type
inventory, not one-type-per-file layout, is authoritative and the packet owns
no semantic activation.
Existing project, package, lock, workflow, A test/source, and Domain source
files are immutable unless a packet freeze names and proves an unavoidable
exact change. No packet may change the final Scenario/status/owner/filter route.

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

This plan becomes an accepted `FrozenDesign` predecessor only after its exact
record cohort passes link/StructureOnly/publication-evidence checks, two final
reviews, commit/push, and exact-head hosted green. That outcome authorizes no B
test or C# implementation by itself. A separate maintainer implementation
directive must name the first active packet. C/D, final activation, feature
DoD, release, publication, consumer mutation, authority transfer, and
PowerShell retirement remain held.
