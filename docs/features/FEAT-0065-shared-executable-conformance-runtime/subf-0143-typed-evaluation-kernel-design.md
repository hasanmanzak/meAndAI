# [SUBF-0143](README.md#subf-0143) - Typed Evaluation Kernel Design

| Field | Value |
| --- | --- |
| Classification | Subfeature / third dependency-closed [FEAT-0065](README.md) design slice |
| Status | Gate 2 accepted; ContractSlice A and B merged/exact-main green; B is `11/11`, cumulative A+B `43/43`. C Activation, Applicability, and Evaluation are `ExactHeadHostedGreen`; C is `9/11`, current A+B+C `52/52`. R=0007/R=0011/R=0014/R=0015 are accepted/immutable; R=0012/R=0013 are diagnostics/no-success. `C-INTENT-RESULT-01` is `FrozenDesign`/inactive pending this synchronized records/design exact-head hosted gate; [TEST-0210](test-cases.md#test-0210) remains `Planned`, and D/activation/DoD remain held. |
| Parent | [FEAT-0065](README.md) |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Decision | [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) |
| Test | [TEST-0210](test-cases.md#test-0210) |
| Gate 3 micro-delivery routing | Historical A delivery remains owned by the [A micro-delivery control plan](subf-0143-micro-delivery-plan.md). Current B design routing is the [ContractSlice B micro-delivery plan](subf-0143-contractslice-b-micro-delivery-plan.md); packet labels refine delivery but activate no executable work. |
| Exact-main design baseline | Accepted A merge commit [`51623f4d404a95e0f706d72805cf7ddbbbd293b8`](https://github.com/hasanmanzak/meAndAI/commit/51623f4d404a95e0f706d72805cf7ddbbbd293b8), validated by exact-main [run 31304787603](https://github.com/hasanmanzak/meAndAI/actions/runs/31304787603) |
| Design and Gate 3 authority | Historical A/B directives, accepted reds, diagnostics, and hosted evidence remain immutable. The exact [C micro-delivery plan](subf-0143-contractslice-c-micro-delivery-plan.md) is exact-head hosted-green design authority; Activation, Applicability, and Evaluation are `ExactHeadHostedGreen`, diagnostic R=0012/R=0013 are immutable, and R=0014/R=0015 are accepted/immutable. `C-INTENT-RESULT-01` is the sole next frozen packet and remains inactive until this synchronized records/design head becomes exact-head hosted green; D, final activation, merge, release, and publication remain outside this authority. |
| Completed predecessor | [SUBF-0153](README.md#subf-0153) / [TEST-0221](test-cases.md#test-0221), merged through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173) and exact-main validated by [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256) |

## Directive and hard boundary

The historical directive authorized Gate 1 and Gate 2 architecture design plus
expected-red planning for [SUBF-0143](README.md#subf-0143) and
[TEST-0210](test-cases.md#test-0210). The later corrected
[ContractSlice A directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228)
authorizes only the reviewed A topology correction, project/lock transition,
exact A expected reds, and bounded cumulative-A C# implementation after this
correction has no unresolved Blocking or Important architecture finding. This packet closes the catalog,
release binding, provider-neutral typed model, admission, cache, applicability,
evaluator, finding, evaluation, and aggregation handoff required by the
accepted [SUBF-0153](README.md#subf-0153) design.

The historical
[ContractSlice B design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5230762350)
authorized only the linked B micro-delivery plan and normative B freeze. That
predecessor authority activated no executable work. After its accepted
exact-main delivery, later packet authority closed the surface and codec
activation predecessors. The current ordered-B maintainer directive names the
remaining B sequence without bypassing any packet's dependency, design,
expected-red, review, or hosted gate.

Historical A message/echo, RunInfo, assertion-stack, bounded-timeout
diagnostics, and the accepted 0003 red remain owned by their packet evidence
ledgers. They add no current B authority; the bounded-green record below keeps
only the retained outcome needed by this design.

### `A-SCHEMA-SLOT-01` bounded-green evidence

The final retained
`ContractSliceASchemaSlotManifestTests.cs` source is exactly `436` lines with
SHA-256
`FC43FDDA4B273BFCBED442FB145E28BA207EE433A08A9D3E43BEA88574154480`.
The temporary marker and legacy branch are absent. The fixture-only scenario
literal exposed by [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074)
was changed to neutral
[TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md#test-0001);
no active [TEST-0210](test-cases.md#test-0210) source literal
remains. The measured implementation is `256` production plus `436` test lines,
or `692/700`: two lines above the `600-690` planning estimate, but below the
only hard stop of more than `700` changed code/test lines.

The original-oracle green, with the temporary branch still present, passed
`1/1` at
`D:\Temp\meandai-test-0210-a-green-d223831945254a88b29b723f0a07f3e3\TEST-0210-A-GREEN-0003.trx`,
SHA-256 `EF73BE838513986CA8FB9D41D1FC2B34D98CC3E31C650638B15158A7B115BB80`.
After topology cleanup, the final focused run passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-topology-64237a9f1c384c1fb5adef025948cfe0\TEST-0210-A-GREEN-FINAL-0003.trx`,
SHA-256 `A8552AF906E45AFB22A85BF0F3B61DDFD8AFA813036AA78292180C1BC32A2ACD`,
and cumulative `ContractSlice=A` passed `18/18` at
`D:\Temp\meandai-test-0210-a-cumulative-topology-retry-c93d714f03894591b62e498df55931c3\TEST-0210-A-GREEN-CUMULATIVE-0003.trx`,
SHA-256 `920BC60B161595E97D12544836D5B6E5B271C60931FFFB0860389F81F77B9DDC`.

The Release build completed with zero warnings and zero errors, standard format
verification passed, and all six lock fingerprints remained unchanged. The
earlier full protocol-suite run reached its controlled `600`-second outer
timeout, and the later post-correction `-StructureOnly` run reached its
controlled `300`-second timeout with no orphan process. Both are inconclusive,
remain below the repository's reviewed `20`/`35`-minute full-validation
budgets, and are neither pass nor fail evidence. Fresh full-diff review pass 2
closed `0 Blocking / 0 Important / 0 Minor` after the pass-1 traceability
correction. Exact-head hosted [run 30704338972](https://github.com/hasanmanzak/meAndAI/actions/runs/30704338972)
closes [FIND-0444](README.md#find-0444) at remote-equal
[`c73977d...`](https://github.com/hasanmanzak/meAndAI/commit/c73977d4af922aa66c464f6caced0d1aae473665).
`A-INDEX-SLOT-01` remains packet-local `ReviewedLocalGreen`; its canonical R,
focused/cumulative green, hashes, line budget, locks, and review evidence are
unchanged. Pushed head
[`bfa961d...`](https://github.com/hasanmanzak/meAndAI/commit/bfa961d1f661588dc48f337720cae2ef741887a7),
git tree identity: `07ceea87ae934c53e64eb2bd9e3ecf2904fa3943`, failed only repository-record
[TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
in [run 30712296217](https://github.com/hasanmanzak/meAndAI/actions/runs/30712296217).
[FIND-0445](README.md#find-0445) owns that historical authoring failure. Exact
correction head
[`43c1800...`](https://github.com/hasanmanzak/meAndAI/commit/43c1800b551c0f7d337a20dd290390094d72311c),
git tree identity: `2d550a6a894f6dcaa43b73bf156cb72d7c13e9e3`, made Windows
green while Ubuntu failed only
[TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
with twenty-three ambiguous Git tree identities in
[run 30714966450](https://github.com/hasanmanzak/meAndAI/actions/runs/30714966450).
[FIND-0446](README.md#find-0446) owns their object-identity classification
correction. Both findings are resolved by exact remote-equal
[`25e26f9...`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`, and hosted-green
[run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
At that historical strict-redraw checkpoint, never-activated
`A-PARSER-INDEX-01` was retired and fourteen of twenty live packets were
`ReviewedLocalGreen` (`70%`). `A-PARSER-RECORD-SLOT-01` was exact-
head `ReviewedLocalGreen` at [`fca0778...`](https://github.com/hasanmanzak/meAndAI/commit/fca0778663238b83bb2ede7cba5ab52012414689)
/ [run 30722890590](https://github.com/hasanmanzak/meAndAI/actions/runs/30722890590).
`A-GOVERNED-REFERENCE-SLOTS-01`, `A-TARGET-PARSER-INDEX-SLOT-01`,
`A-FINDING-01`, `A-SELECTOR-01`, `A-ADMISSION-01`, and `A-PROJECTOR-DAG-01`
are `ReviewedLocalGreen`; cumulative A is `26/26`. The exact admission FrozenDesign
predecessor is [`f298e87f98cb0896904a21078e2e3f391b2b8dcd`](https://github.com/hasanmanzak/meAndAI/commit/f298e87f98cb0896904a21078e2e3f391b2b8dcd),
git tree identity `6debfc2f3648ec7972d3e1f21d1f1cc224b35a4a`, with Ubuntu and Windows green in
[run 30774470978](https://github.com/hasanmanzak/meAndAI/actions/runs/30774470978).
The exact admission record-evidence delivery is
[`b735853a2153338fd97c366bcd8c212f78bc1bce`](https://github.com/hasanmanzak/meAndAI/commit/b735853a2153338fd97c366bcd8c212f78bc1bce),
git tree identity `fc5ae301331f55f1435b4262c300489e3cbcff2f`, with Windows green in
`17m10s`, Ubuntu green in `19m02s`, and publication verification correctly
skipped in [run 30781516326](https://github.com/hasanmanzak/meAndAI/actions/runs/30781516326).
`A-PROJECTOR-DAG-01` and `A-FULL-MANIFEST-01` are packet-local
`ReviewedLocalGreen`. The projector hosted run `30798854880` passed Windows in
`14m58s` and Ubuntu in `19m00s`; publication verification was correctly skipped.
Never-activated `A-CONVERGE-01` is retired; `A-COMPLETE-PROFILE-01` is
exact-head hosted-green `ReviewedLocalGreen` at commit
`canonical owning-finding correction head`, tree
`canonical owning-finding correction git tree identity`, and run `canonical owning-finding replacement run`.

### Reviewed-local-green `A-INDEX-SLOT-01` delivery freeze

The accepted design is unchanged. The delivery plan's hard line-budget gate
redraws the next implementation into a first closed repository-tree path:
schema/model -> exact `protocol.index.repository-tree` / `1`, `PerContext`, one
`protocol.model.repository-tree` / `1` input at `(1,1)` -> exact
`protocol.capability.repository-tree` / `1` -> the existing repository-tree
slot. The exact indexer is component `protocol.index.repository-tree` / `1`,
assembly `MeAndAI.Protocol.Policy`, type
`MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex`; the output capability's
interface component is `protocol.type.capability.repository-tree` / `1`,
assembly `MeAndAI.Protocol.Conformance.Abstractions`, type
`MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree`. Its exact budget is
`(16777216, 64, 200000, 2000000)`, and canonical failure-code order is
`protocol.budget.exhausted`, then
`protocol.index.repository-tree-unavailable`. Shared `(0,0)` rejection through
both public input factories is included. Parser rows and every other index row
remain absent and fail closed.

The exact partial Fact is
`ContractSliceAIndexSlotManifestTests.Enforces_exact_repository_tree_index_and_slot_capability_closure`
with only `ContractSlice=A`; its marker/TRX stem is
`TEST-0210-A-BEHAVIOR-RED-0004`. Transient source must construct the otherwise
valid graph and invoke the writer before direct factory/matrix assertions; only
the exact current writer exception type/message may emit marker 0004. Positive
coverage freezes byte/digest round trip, projection, `TryGetIndex`, nested field
order, and slot/producer equality. Negatives freeze nested spelling/null/
duplicate/order, collection order, scope/input/model/cardinality, output/
interface, producer reachability/uniqueness, budget/failure codes, component/
artifact references, plus explicit rejection of parser and other index rows.
First-pass D/RT was `0 Blocking / 1 Important / 0 Minor`; the freeze was
corrected and renewed RT closed `0 Blocking / 0 Important / 0 Minor`. Estimate
is `540-660`, packet ceiling `690`; `700+` forces another redraw.
At this freeze boundary `A-PARSER-INDEX-01` remained Candidate/inactive and
received no marker or implementation authority; the later strict redraw above
retires that never-activated label and activates only its first replacement.

LR completed once with all six lock fingerprints unchanged. P is
`NotApplicable`; unchanged-source predecessor proof passed schema-slot focused
`1/1` in
`D:\Temp\meandai-test-0210-a-index-slot-p-schema-ae918b5eb8a74a6e9126831803ab815d\TEST-0210-A-PREDECESSOR-SCHEMA-SLOT-0004.trx`
(`4FBD396466F80A5373A33B8E3C8E0C4CA55995699B7B761AF997644057F3BE60`),
and cumulative A passed `18/18` in
`D:\Temp\meandai-test-0210-a-index-slot-p-cumulative-bd86c6e63c7d4c1593a9ead3903ef8b6\TEST-0210-A-PREDECESSOR-CUMULATIVE-0004.trx`
(`8D8F84F25712CDE59845E99C88C3A34AAAA5C9E5AD5383449CB828EB23508B5E`).
Both were fresh one-invocation `--no-restore` proofs; neither is R.

The transient source is `388` lines at SHA-256
`996CDD4A7244A39E702530DF4E45152CAE3EBBE6B430CA3E79FA63FF3756EBF0`.
After a `0/2/0` source finding pass was corrected, two fresh reviews closed
`0/0/0` independently and the Release `--no-restore` build was warning/error
free. The single canonical R is
`D:\Temp\meandai-test-0210-a-index-slot-red-a4e9fd0d6c8e44cd9e0e20c65eea37fd\TEST-0210-A-BEHAVIOR-RED-0004.trx`,
SHA-256 `72788214F782CE347C68E646D0B3AB82E58B92F7C18EA4B2B07ED60DDC7053A4`.
Its exact Failed result, marker Message, permitted marker-free stack, one marker
echo, permitted same-FQN RunInfo, exact sixteen counters, no attachments, unset
parent timeout, and no orphan testhost pass the complete BehaviorRed oracle.
No red retry is authorized.

Bounded implementation changed only the frozen four production files and one
test. Original-oracle focused green passed `1/1` at
`D:\Temp\meandai-test-0210-a-index-slot-green-original-5f90b4d8a1724f5da17984eeb4221ae6\TEST-0210-A-GREEN-ORIGINAL-0004.trx`,
SHA-256 `66F8DC42BD29C603E8004EDAB5EF634F69659854F64618FE34889B2A8640CB4F`.
After marker/catch removal and final LF normalization, focused green passed
`1/1` at
`D:\Temp\meandai-test-0210-a-index-slot-green-lf-final-5793a27fa8f445cbb07582683c308256\TEST-0210-A-GREEN-LF-FINAL-0004.trx`,
SHA-256 `B755D5DD4A7ED5E269410A72CB422AF0995B80362712EDDFE4FC9DE4BAFB91EE`.
Final LF-normalized cumulative A passed `19/19` at
`D:\Temp\meandai-test-0210-a-index-slot-green-lf-cumulative-f13b37ea9fec4fb8b973697898eaac3c\TEST-0210-A-GREEN-LF-CUMULATIVE-0004.trx`,
SHA-256 `5BAAFF3717BFA1E5FBEC755F187766D627EBFB52A360749A2F5C06D9AFAF06E6`.
The final source is `377` lines / SHA-256
LF-normalized SHA-256 `F94B6138B87EBABBE8D0E4033B94CD41F6B44BF9FA37B58948513D3DA52D280B`;
production delta is `265`, total packet size is `642/690`, Release build has
zero warnings/errors, full format and diff checks are clean, six locks are
unchanged, and three final live reviews each closed `0/0/0`.

### Reviewed-local-green `A-PARSER-RECORD-SLOT-01` strict redraw freeze

Strict-redraw base
[`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`, passed both stable jobs in
[run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
Exact activation predecessor
[`42ce5e550867a1b74be9072fd78b52787d41df5c`](https://github.com/hasanmanzak/meAndAI/commit/42ce5e550867a1b74be9072fd78b52787d41df5c),
git tree identity: `dc53b2f61f1468089724fd6eb798cb9d7d248570`, passed both stable jobs in
[run 30719208988](https://github.com/hasanmanzak/meAndAI/actions/runs/30719208988).
Exact reviewed-local-green head
[`fca0778663238b83bb2ede7cba5ab52012414689`](https://github.com/hasanmanzak/meAndAI/commit/fca0778663238b83bb2ede7cba5ab52012414689),
git tree identity: `05c7591565d965966285cd51226446b2f54c81bc`, passed both stable jobs in
[run 30722890590](https://github.com/hasanmanzak/meAndAI/actions/runs/30722890590).
The accepted D/RT verdict is `0 Blocking / 0 Important / 0 Minor`. The prior
combined `A-PARSER-INDEX-01` was never activated and is
`RetiredBeforeActivation`; it has no FQN, marker, R, G, or V and is excluded
from the live denominator. The three ordered replacements are
`A-PARSER-RECORD-SLOT-01`,
`A-GOVERNED-REFERENCE-SLOTS-01`, and
`A-TARGET-PARSER-INDEX-SLOT-01`. At that redraw checkpoint, the first was
exact-head `ReviewedLocalGreen`; the second was `ReviewedLocalGreen` without a
current exact-head hosted claim, and target/later identities remained `None`.
Current governed-reference and target-freeze evidence is recorded in the
[micro-delivery ledger](subf-0143-micro-delivery-plan.md#packet-evidence-ledger).

The first replacement retains one Fact with only `ContractSlice=A`:
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAParserRecordSlotManifestTests.Enforces_exact_markdown_parser_protocol_record_index_and_slot_capability_closure`.
Its exact marker/TRX is `TEST-0210-A-BEHAVIOR-RED-0005`; only the exact current
writer `InvalidOperationException` and exact message `This writer increment
supports only the minimal qualification slice.` may emit the marker. The
writer-first branch precedes every direct factory or matrix assertion.

The cumulative registry is exactly two schemas in governed-text/repository-tree
order, one Markdown parser, two indexes in protocol-record/repository-tree
order, and two slots in repository-governed-text/repository-tree order. The
governed schema closes governed-text codec, source-text model, retention
`(200000,67108864)`, budget `(4194304,256,500000,5000000)`, and its exact five
failures. Markdown consumes source-text `(1,1)`, produces markdown-document,
uses the same budget, and orders `protocol.budget.exhausted` before
`protocol.model.invalid-markdown`. Protocol-record is `PerContext`, consumes
markdown `(0,null)`, omits `maximumCount` on wire while rejecting explicit
null, produces protocol-record-index, uses budget
`(67108864,256,1000000,10000000)`, and orders budget exhaustion before record
unavailable.

The only new slot in this test-owned partial qualification-slice fixture is
`protocol.slot.repository-governed-text`, on Repository requirement scope with
Repository+Provider profile surfaces, exact governed body evidence/
completeness/schema/consistency/material/target values, and only the
protocol-record-index capability. This does not redefine the final governed-
text slot closure; the next packet owns the provider slot and final governed-
reference relationship. Exact cumulative cache is
`(512,67108864,128,2000000,8,4,retain-lowest-canonical-keys)`. Provider-governed
slot/reference, target parser/index/slot, projector graph, admission, executable
export, and every later slice remain rejected. The exact identities, values,
negative matrix, line budgets, source allowlist, TRX oracle, and holds are
normatively frozen in the [micro-delivery plan](subf-0143-micro-delivery-plan.md#a-parser-record-slot-01-drt-observation).

The frozen contract is now proven locally. Canonical R source was `377` lines
at SHA-256 `DE9E8FD9A2816E6FF0351659D35340D4AD5BCA88059A7811C4E70E88C1DD2028`;
its sole exact-FQN failed TRX is SHA-256
`75B557B03901C7279B77745178CECE96D11E1245817CCFA3D603F971AC9F79A9`
and was never rerun. Final focused green is `1/1` at SHA-256
`51EBD24767650CD6C89F29647BE72247DAD01CAFE4E3EFD88767381901A09295`;
final cumulative A is `20/20` at SHA-256
`751671ED7354EA75E7FEBF2F2FB3FAF7144E28DAE1FE8AA319EE7F303E512B11`.
Retained test source is `366` lines at SHA-256
`990920A61CE9BA53444BFA0F87E67301594D0B2A9E1338B06B5CE84D980C5FAE`;
production is `300` gross changed lines and packet total is `666/690`.
Release build, format, locks, diff, allowlist, traits, and retained-marker checks
passed; three independent post-green reviews each closed `0/0/0`.

### Reviewed-local-green `A-GOVERNED-REFERENCE-SLOTS-01` closure

The next frozen Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAGovernedReferenceSlotsManifestTests.Enforces_exact_governed_reference_index_and_dual_governed_text_slot_capability_closure`,
with marker `TEST-0210-A-BEHAVIOR-RED-0006` and only `ContractSlice=A`. Exact
predecessor is [`fca0778...`](https://github.com/hasanmanzak/meAndAI/commit/fca0778663238b83bb2ede7cba5ab52012414689),
git tree identity: `05c7591565d965966285cd51226446b2f54c81bc`, hosted-green in
[run 30722890590](https://github.com/hasanmanzak/meAndAI/actions/runs/30722890590).

The exact cumulative shape is `2` schemas, `1` Markdown parser, `3` indexes in
governed-reference/protocol-record/repository-tree order, and `3` slots in
provider-governed/repository-governed/repository-tree order. Governed-reference
is `protocol.index.governed-reference/1`, component
`protocol.index.governed-reference/1`, assembly `MeAndAI.Protocol.Policy`, type
`MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex`, `PerPlan`; it consumes
`protocol.model.markdown-document/1` through component
`protocol.type.model.markdown-document/1`, assembly `MeAndAI.Protocol.Policy`,
type `MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel`, at `(0,null)`, then
`protocol.capability.protocol-record-index/1` through component
`protocol.type.capability.protocol-record-index/1`, assembly
`MeAndAI.Protocol.Conformance.Abstractions`, type
`MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex`, at `(1,null)`, produces
`protocol.capability.governed-reference-index/1` through component
`protocol.type.capability.governed-reference-index/1`, assembly
`MeAndAI.Protocol.Conformance.Abstractions`, type
`MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex`, uses budget
`(67108864,256,1000000,10000000)`, and
orders `protocol.budget.exhausted` before
`protocol.index.reference-unavailable`. Both governed slots canonicalize
governed-reference before protocol-record capability while retaining their
exact slot/requirement keys, requirement surfaces, kind
`protocol.evidence.governed-text-set`, completeness
`protocol.completeness.all-governed-bodies`, schema `protocol.governed-text/1`,
ExactSnapshot/ObjectVersionBound/BoundedNonAtomicObservation consistency order,
Provider versus `[Repository, Provider]` profile sets, material
`protocol.material.governed-text`, and exact provider/repository governed-body-
set targets. Each provider field and every shared-field preservation has a
negative drift. Components become
`14`; artifacts stay `3`; cache stays
`(512,67108864,128,2000000,8,4,retain-lowest-canonical-keys)`.

Natural R prebuilds the graph, remaining Catalog arguments, the successful
`CatalogSliceDeclaration.Create` result, the validation-free
`ParsedCanonicalManifest`, and the runtime-created expected exception outside
the exact catch. The internal production `CanonicalManifestWriter.Write(parsed)`
boundary is the first and only guarded expected-red observation, the first
cross-graph validation, and the first serialization call. Only its exact runtime
`ArgumentException`, `ParamName=rules`, with Message equal to the runtime-created
expected exception for `The parser and protocol-record graph is not exact.` may
emit the marker; the filter also requires exact runtime type equality because
`ArgumentNullException` derives from `ArgumentException`. Every setup, Catalog,
writer-guard, filter-mismatch, or other exception remains marker-free. Direct
invocation of the internal closure validator is forbidden. On green, the same
writer result feeds all subsequent assertions. Reader/writer may generalize only index
inputs to model/capability; parser remains exact-one model. Catalog preserves
predecessor `2/2`, accepts only successor `3/3`, and rejects mixed counts.
Production is limited to Reader/Writer/Catalog and one new test; hard caps are
`145/55/110`, production `310`, test `370`, total `680`. Pipeline review
corrected `0/3/0` to provisional `0/0/0`; fresh and renewed post-hosted reviews
then corrected cross-record, identity, matrix, ordering, and literal-assembly
findings, but blocking [FIND-0448](README.md#find-0448) later proved their
Catalog-first natural-red call unreachable. The Writer-first correction above
closed through three independent current-tree `0/0/0` reviews and StructureOnly.
Exact activation baseline
[`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d),
git tree identity: `8f120c396bd531e7b33d9c00a1265e0a7be6d1ba`, passed Ubuntu and Windows in
[run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145)
and resolved the activation hold. The packet is now `ReviewedLocalGreen`.
Exact remote-equal
[`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602),
git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`,
passed Ubuntu and Windows in
[run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121);
publication verification was correctly skipped. Prior `0/0/0`
reviews remain historical rather than current authority. The complete matrix
and holds are in the
[handoff](../../../.ai/memory/log/2026-08-02-feat-0065-subf-0143-contractslice-a-governed-reference-slots.md).

P is `NotApplicable`. Unchanged-source predecessor focused `1/1` is
`D:\Temp\meandai-test-0210-a-predecessor-focused-0006-561a760-clean\TEST-0210-A-PREDECESSOR-FOCUSED-0006.trx`,
SHA-256 `8C03E5859A46F29B6BB56BA96DCBF81A210AD5B13198C82FE8A1DF62FA6BC422`;
predecessor cumulative A `20/20` is
`D:\Temp\meandai-test-0210-a-predecessor-cumulative-0006-561a760-r2\TEST-0210-A-PREDECESSOR-CUMULATIVE-0006-R2.trx`,
SHA-256 `298BA6226AA5BCC5EE4731575F086224C465AC6F22055BD44FD9207BDDA9ADB3`.
The first Socket 10055 attempt is diagnostic only, neither P nor R. Transient
source froze at `370` lines / SHA-256
`9CFB0ACD9081072B9187FFB9E75704DBBB4FA3094881F643A766E9C872E84075`.
Canonical R completed the exact oracle and was not rerun:
`D:\Temp\meandai-test-0210-a-6f79b6c0330541d49d851464e1a8349e\TEST-0210-A-BEHAVIOR-RED-0006.trx`,
SHA-256 `938DDA74559F955F28A4470EE953DB9575A46DC9453CA27C9EE664FB90E635E2`.

Original-oracle focused green `1/1` is
`D:\Temp\meandai-test-0210-a-green-original-8bc26cee2b884f80b06ba76c4eef9834\TEST-0210-A-GREEN-ORIGINAL-0006.trx`,
SHA-256 `06633DAF09D312609E5DF6CA1018F5209A3BB8F88437C1F4E43FCD20A79E140F`.
Final focused green `1/1` is
`D:\Temp\meandai-test-0210-a-green-final-ed5ec8da05d44ddba9e00a6f0a196efa\TEST-0210-A-GREEN-FINAL-0006.trx`,
SHA-256 `CCDA68221C94F051414BE38E2099D447C1EDA5835F9E5C74E30B62C351B0DF77`;
the parser-record predecessor regression `1/1` is
`D:\Temp\meandai-test-0210-a-green-predecessor-9c2babadda3f4070aaf749071e62f7cb\TEST-0210-A-GREEN-PREDECESSOR-0006.trx`,
SHA-256 `08CD02F6EFE613B4E4F8F7754E574B18C84B77F83926FDACB3982B5555F47AA5`;
and cumulative A `21/21` is
`D:\Temp\meandai-test-0210-a-green-cumulative-163c8a4efe0d42d89cac064a8ebd3b9a\TEST-0210-A-GREEN-CUMULATIVE-0006.trx`,
SHA-256 `59917686763074521CB0FABD9A2AC7A8F2C4636C87B545994FF93958190587B9`.
Retained test source is `358` lines at SHA-256
`BBE93D8E43632363E63E5D29C4F709353B04F6BD389276126C3409DE8A10A0D1`;
Reader/Writer/Catalog gross changed lines are `135/21/57`, production `213`,
combined `571/680`. Locked Release build, format, diff, allowlist, locks, trait,
and marker checks passed; full Domain is `98/98`, full Conformance is `21/21`,
and three independent post-green reviews each closed `0/0/0`.

### Reviewed-local-green `A-TARGET-PARSER-INDEX-SLOT-01`

The accepted architecture's target parser/index/slot vertical necessarily owns
the third repository-target schema/model row. Exact cumulative topology is
`3/2/4/4`, with zero projector/admission rows, exact `20` components, exact `3`
artifacts, and unchanged cache. The reserved marker is
`TEST-0210-A-BEHAVIOR-RED-0007`; the reserved Fact is
`ContractSliceATargetParserIndexSlotManifestTests.Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure`,
with only `ContractSlice=A`. Existing canonicalization fixes target-index input
order as target-Markdown-set model, target-resolution model, then
governed-reference capability. The exact identities, Writer-first oracle,
negative matrix, Catalog-only production allowlist, `180/500/680` hard caps,
and all held boundaries are frozen in the
[micro-delivery D/RT observation](subf-0143-micro-delivery-plan.md#a-target-parser-index-slot-01-drt-observation)
and [target packet handoff](../../../.ai/memory/log/2026-08-02-feat-0065-subf-0143-contractslice-a-target-parser-index-slot-freeze.md).
The canonical expected red ran exactly once and remains immutable. Retained
focused green is `1/1`, cumulative A is `22/22`, full Domain is `98/98`, full
Conformance is `22/22`, retained source is `401` lines, and production/test
size is `497/680`. Release build, format, locks, diff, marker/trait checks,
StructureOnly, and three independent post-green reviews are green. Exact
[`bdd252bb74a2d8ee87664cb0d34b5c893d34a7b9`](https://github.com/hasanmanzak/meAndAI/commit/bdd252bb74a2d8ee87664cb0d34b5c893d34a7b9),
git tree identity `b95ac0da13e26c168d03525a0d2f7c63127e9885`, passed Ubuntu and Windows in
[run 30762028026](https://github.com/hasanmanzak/meAndAI/actions/runs/30762028026)
and is the exact `A-FINDING-01` predecessor.

### Reviewed-local-green `A-FINDING-01` evidence

The frozen `R=NotApplicable` / `TestOnlyGreen` route produced no marker/TRX and
no production delta. The retained FQN is
`ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles`;
its one synthetic-fixture test file is `420` lines at SHA-256
`19DDFFA7131306C8BEF70D7E5B83E88B7ED564FE657045C5ACAF6CFAE49A1CAF`.
Focused green is `1/1` at `D7C069CC...25D`, cumulative A is `23/23` at
`8B7046AA...CD3`, full Domain is `98/98` at `8B59FC...3CDB`, and full
Conformance is `23/23` at `B714DD...56804F`. Release build is
`0 warnings / 0 errors`; default-severity format, diff, six locks,
StructureOnly, publication-evidence checks, independent code red-team, and
evidence audit are green. Exact hosted-green delivery
[`2430a67e0140a6c8ce0f26eaebae8aed35259134`](https://github.com/hasanmanzak/meAndAI/commit/2430a67e0140a6c8ce0f26eaebae8aed35259134),
git tree identity `893e6f6dc1a6f0a246dc209be650f906e5f5c702`, passed Ubuntu and Windows in
[run 30767103072](https://github.com/hasanmanzak/meAndAI/actions/runs/30767103072)
and is the exact selector design predecessor.

### Reviewed-local-green `A-SELECTOR-01` contract and evidence

Schema 1 already states that `ExpectedSelectorDeclaration.AllowedParentKinds`
may contain only `ContextProof`, `Root`, and `Derived`; selector-on-selector
nesting is invalid. At the exact frozen predecessor,
`ExpectedSelectorDeclaration.Create` instead accepted `ExpectedSelector`.
D/RT closed `0 Blocking / 0 Important / 0 Minor` on a
single-production-file correction: canonicalize `allowedParentKinds` once in
that factory, then reject any `ExpectedSelector` with `ArgumentException`,
parameter `allowedParentKinds`, and base literal
`Expected selector parent kinds must be ContextProof, Root, or Derived.` Exact
observable `Message` equals
`new ArgumentException(FrozenMessage, nameof(allowedParentKinds)).Message`, so
framework-appended parameter text is compared portably. The
shared canonicalizer and kind-rank helper remain unchanged because finding
declarations legitimately use `ExpectedSelector` reference roles.

The retained one-Fact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure`;
its only trait is `ContractSlice=A`, and its canonical-R marker/TRX stem was
`TEST-0210-A-BEHAVIOR-RED-0008`. Before any sibling assertion or writer call,
the canonical-R first action was:

```csharp
_ = ExpectedSelectorDeclaration.Create(
    "protocol.test.selector.alpha",
    "protocol.slot.repository-tree",
    "protocol.test.selector-schema.alpha",
    Resolve("protocol.selector.test-alpha"),
    [QualifiedEvidenceReferenceKind.ExpectedSelector],
    [FindingCode.Parse("protocol.test.finding.alpha")]);

Assert.Fail("TEST-0210-A-BEHAVIOR-RED-0008");
```

No catch surrounded the call; unexpected exceptions would have been
marker-free. Retained green replaces only the marker branch with exact
`ParamName` and runtime-created
expected-`ArgumentException` `Message` equality.

Production allowlist is only
`src/MeAndAI.Protocol.Conformance.Abstractions/Rules/ExpectedSelectorDeclaration.cs`
with target `8-18` and hard cap `20`. Test allowlist is only new
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceASelectorManifestTests.cs`
with target `340-430` and hard cap `500`; combined hard cap is `520`.
The exact reversed-input fixture contains alpha
`protocol.test.selector.alpha` / `protocol.slot.repository-tree` /
`protocol.test.selector-schema.alpha` / `protocol.selector.test-alpha/1` with
all three allowed parents and findings `protocol.test.finding.alpha` /
`protocol.test.finding.zeta`; and zeta
`protocol.test.selector.zeta` / `protocol.slot.repository-governed-text` /
`protocol.test.selector-schema.zeta` / `protocol.selector.test-zeta/1` with
`Derived` and finding `protocol.test.finding.zeta`. Both resolver component rows use assembly
`MeAndAI.Protocol.Conformance.Tests`, artifact `ContractSliceA.Proof.dll`, and
types `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver`
and `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver`.

The retained matrix owns input snapshot/canonical order, null/empty/null-element/
duplicate boundaries, the three allowed and one forbidden parent kinds,
selector ordering, declared-slot/finding and resolver-component closure, exact
six-field wire order, and byte/digest roundtrip. Removing the entire
`expectedSelectors` collection and both resolver rows reproduces the predecessor
graph; selectors or either resolver left orphaned fail. Malformed-wire ownership
is limited to the six outer fields/order, both lists, and selector-array
ordering/null/duplicate boundaries. Nested resolver grammar receives positive
`componentKey`/`componentVersion` order and orphan negatives only; existing
component-reference tests retain exhaustive nested grammar. `selectorSchemaKey`
is preserved exactly but gains no registry or whitelist here. Real five-rule
selector inventory, schema/resolver mapping, and runtime resolution remain
`A-FULL-MANIFEST-01` or later-packet scope. The exact selector freeze
[`c97c317fb0d5e734597f43f605fe4f1718aa6d1c`](https://github.com/hasanmanzak/meAndAI/commit/c97c317fb0d5e734597f43f605fe4f1718aa6d1c),
git tree identity `7fa1748c59902f027f1bd8ca4cdd66b72194f98e`, passed Ubuntu in `17m33s` and
Windows in `15m23s` in
[run 30769530904](https://github.com/hasanmanzak/meAndAI/actions/runs/30769530904).

Canonical R used transient test source `367` lines at SHA-256
`FC04D1916D14D5A750FC8A884E353E2A2B3662D052F2EAF9A39E0549E64B8F55`, with
production unchanged at
`5CFA7E3C37F730FA0ED3259A1688BF03C95D8E4B8D6061D9A21737656ABC1146`.
The single exact-FQN invocation failed exactly once with the frozen marker; TRX
SHA-256 is `7A85D0CC4B1AAF45038E818B3687C10D5F3339EC2ECC53D9D5646C97D5F6D30A`.
The sixteen counters, permitted same-result diagnostics, source custody, and
zero-attachment oracle passed; R is immutable and was not rerun.

The retained test is `370` lines at
`56B9B30AE4432D06644F58331569148EF7729DBE282FB8119634B11397862B69`.
The one production file is
`F4AA63038FCCA7B6DFBCF087E0F97CDC851C980B099840871C66722FADC4AAAF`,
with gross `12/20`; combined packet size is `382/520`. Focused green is `1/1`
at `98B2EADB4E111FEFCAB18C46FD3293FD88E88C028E562DE6CEC9B0C7DE33DDB2`;
cumulative A is `24/24` at
`527DCB9E2799AAEDAA1D6A1083014F005705E66C6E620F174A736926D1418D35`;
full Conformance is `24/24` at
`7356CC3AD6BD329D84B7694DB5919E7D751C00712216840FE0F562A3F5555532`;
and full Domain is `98/98` at
`8DEBDBBE253F5DB7D2A72C0AD80690123AA6E904AAA50C8DAA8B123E35E7F478`.
Release build is `0 warnings / 0 errors`; format, diff, six locked fingerprints,
StructureOnly (`elapsedMs=376188`), and the bounded seven-test
publication-evidence suite are green. Independent code and evidence/scope
reviews each closed `0 Blocking / 0 Important / 0 Minor`. The packet is
`ReviewedLocalGreen`. Its exact delivery is
[`2bbd36f5dd9ee975778063719fe8f879873e00d5`](https://github.com/hasanmanzak/meAndAI/commit/2bbd36f5dd9ee975778063719fe8f879873e00d5),
git tree identity `fe543889cc68fad6a61139f0125a41ca4050ce40`; Ubuntu passed in
`17m11s`, Windows passed in `14m43s`, and publication verification was correctly
skipped in [run 30772197693](https://github.com/hasanmanzak/meAndAI/actions/runs/30772197693).

### Reviewed-local-green `A-ADMISSION-01` contract and evidence

The exact FrozenDesign predecessor is
[`f298e87f98cb0896904a21078e2e3f391b2b8dcd`](https://github.com/hasanmanzak/meAndAI/commit/f298e87f98cb0896904a21078e2e3f391b2b8dcd),
git tree identity `6debfc2f3648ec7972d3e1f21d1f1cc224b35a4a`, which passed Ubuntu in
`17m46s` and Windows in `12m15s` in
[run 30774470978](https://github.com/hasanmanzak/meAndAI/actions/runs/30774470978);
publication verification was correctly skipped. This is the hosted design
predecessor, not the admission implementation delivery. R is
`Applicable / BehaviorRed`, P is `NotApplicable`, marker/TRX stem is
`TEST-0210-A-BEHAVIOR-RED-0009`, and the one-Fact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAAdmissionProofManifestTests.Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure`.
Its only trait is `ContractSlice=A`. Fixture construction precedes the oracle;
only Writer's exact current `InvalidOperationException` type and exact
`This writer increment supports only the minimal qualification slice.` message
may call the marker. Every mismatch or other exception remains marker-free.

The synthetic fixture preserves the exact selector topology and adds three
admission rows sharing `protocol.test.admission-proof/1`. Reversed typed input
NoInput/Failed/Observed canonicalizes by composite key/version/kind rank to
Observed/Failed/NoInput. Three distinct Tests-owned proof components map to the
existing `ContractSliceA.Proof.dll`; every row has the exact Repository+Provider
surface union and the complete canonical slot-role union. The graph changes
from twenty-two to twenty-five components while retaining three artifacts.
Removing all three rows and components reproduces the selector predecessor;
partial, split-key/version, orphaned, shared, activation/functional-overlapping,
or unmapped topology fails closed.

Only `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`,
`CatalogSliceDeclaration.cs`, and one new admission test are allowed. Reader,
Writer, Catalog, production, test, and combined hard caps are respectively
`145`, `55`, `110`, `310`, `370`, and `680`. The retained matrix owns exact
rank/lookup/snapshotting, surfaces/material roles, component/artifact and
partition closure, six-field wire order, Writer/Reader byte and digest
roundtrip, forty-two outer-wire mutations, orphan negatives, and predecessor
reproduction. Real Application proof rows and the six-artifact/thirty-five-row
inventory remain `A-FULL-MANIFEST-01`; runtime admission and all later behavior stay
held. Reconciled D/RT closed `0 Blocking / 0 Important / 0 Minor`.

Locked restore ran once and all six lock fingerprints remained unchanged;
`P` remained `NotApplicable`, while predecessor revalidation passed selector
focused `1/1` at SHA-256 `CEF622D01BD7AFC6DDF057CAF872F7922BCCAAAA3556AFFF658095B7D5B437B4`
and cumulative A `24/24` at
`DE9231E844691362042F8EBDDFC6833CE2BB99D219864404D08189CD62683BB8`.
Canonical R ran exactly once at the reserved FQN and failed only with the exact
marker. Its external TRX SHA-256 is
`2D7B35424911010D120424E6BFDBDBB07C8A265444D8CFE8FF5007FD941EEE76`;
the transient source is
`7898CFADE43DD8176DFCB2F8C5C864D00EBCEB066C260C8FC9AE8C2C9C3B3CAC`.
Reader/Writer/Catalog prehashes are respectively
`5E1C3CCCD3AF91E6E9CC952057FCB3ADD999C717169624B75D74CD4A3E70B550`,
`409B40B6AE4121714607707724546AD20EF284CE2510F4F8D488F1B9D9D56DA1`,
and `2F370175B36BACCC0D3F328F2E23991BC15D1E2A8F6F681C37A28189F93D397B`.
The TRX has `total/executed/failed=1/1/1`, every other one of the sixteen
counters zero, no attachment, and no independent diagnostic.

The original oracle passed `1/1` at SHA-256
`39A9F362E5FEF02A39B283F8879F75A8E0BD87C616DFD9C9EF9CBB9C2F825AFF`.
Retained focused green is `1/1` at SHA-256
`3250DA7332E81D3A732AD4E6E3266126EDFA53D9282AC2293944C42E143FD4CA`;
cumulative A is `25/25` at
`F5163E4F1D190519D534FCFF1DC5010E0DBA4EFD9DF788302EEDFB31DA53AAB5`;
full Domain is `98/98` at
`5DE82E15A344C3A87133878892B2B4DDE7B3860B5E77E5697734629879EFD0E3`;
and full Conformance is `25/25` at
`12CACAF9D5BD9BE9240E75ECA29E329243543851E132B05C8BFCAED984B1E9A1`.
The retained test is `339/370` lines at SHA-256
`AEFF47E643F97AB31DB69CDB24810F766B078A989D05E5D56E52015B924A9F97`.
Reader, Writer, and Catalog gross sizes/hashes are `85/145` at
`25512694EA4B8D1E81265A23493307F76E7CDA5E887E2F0CE9E89C542F702949`,
`35/55` at `94C659B148C40334628AE90D67213143E1417E6DD9487C74E539139C88DC20AD`,
and `66/110` at
`10C1D55F28120DD1D4CE816CFED35A7BF9BB686B37E0232196DA84C0CB05B238`.
Production/test/combined totals are `186/310`, `339/370`, and `525/680`.
Release build is `0 warnings / 0 errors`;
format, diff, marker scan, scope, and locks are green. Full `StructureOnly`
passed with `elapsedMs=370203`; the seven-test publication-evidence suite passed
in `242.5` seconds without claiming published-state evidence. Independent final
code/test and evidence/hash/counter/scope reviews each closed
`0 Blocking / 0 Important / 0 Minor`. Exact evidence is retained in the
[admission-proof reviewed-local-green handoff](../../../.ai/memory/log/2026-08-03-feat-0065-subf-0143-contractslice-a-admission-freeze.md).
Exact hosted-green admission record-evidence delivery
[`b735853a2153338fd97c366bcd8c212f78bc1bce`](https://github.com/hasanmanzak/meAndAI/commit/b735853a2153338fd97c366bcd8c212f78bc1bce),
git tree identity `fc5ae301331f55f1435b4262c300489e3cbcff2f`, passed Windows in
`17m10s` and Ubuntu in `19m02s` in
[run 30781516326](https://github.com/hasanmanzak/meAndAI/actions/runs/30781516326);
publication verification was correctly skipped. `A-ADMISSION-01` remains
packet-local `ReviewedLocalGreen`.

### Frozen-design `A-PROJECTOR-DAG-01` boundary

The next packet adds the single declaration
`protocol.projector.repository-target-resolution-demand/1` with component
`MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector` in
the existing Policy artifact. It consumes
`protocol.capability.governed-reference-index/1` from the provider- and
repository-governed-text input slots, projects the evaluation-only
repository-target-resolution output slot, and names opaque demand-frame token
`protocol.repository-target-resolution-demand/1`. That token is neither a
payload-schema declaration nor a producer-graph node. Its exact budget is
`(33554432,64,100000,5000000)` and its sole failure is
`protocol.budget.exhausted`.

The exact one-Fact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAProjectorDagManifestTests.Enforces_exact_projector_bindings_and_global_producer_graph`;
its only trait is `ContractSlice=A`, no Scenario is active, and its immutable
BehaviorRed marker/TRX stem is `TEST-0210-A-BEHAVIOR-RED-0010`. P is
`NotApplicable`. Fully valid successor creation and all count preconditions are
outside the catch; only the existing Writer's exact `InvalidOperationException`
and exact legacy message may emit the marker. Reader is excluded and canonical
R is never rerun.

The matrix has exactly `103` unique one-at-a-time canonical-byte negatives.
Validation precedence is array envelope; projector-row wire grammar; raw
component/artifact resolution and role ownership; locate the one required exact
projector key/version and validate that row's values; raw projector-slot
preflight before typed rule factories; generic producer DAG over every producer,
including extra projector rows; remaining projector cardinality/extra-row
rejection; then historical exact selector/admission/parser topology. Each
fixture must reach its owned layer, and every retained negative asserts its
mapped stable diagnostic rather than accepting an arbitrary `FormatException`.

The `50` projector-row wire negatives are the ten fields, each independently
missing, duplicated, `null`, or Boolean-wrong-type (`40`), one extra field, and
each of nine adjacent field swaps. The four array-envelope negatives are a null
array, object instead of array, one null element, and two byte-identical exact
projector rows. An empty array is not negative: removing both declaration and
component must byte-reproduce the valid `25`-component predecessor.

The exact `27` value/local negatives are:

1. alternate `projectorKey`;
2. projector version `2`;
3. alternate projector component key with its binding atomically renamed and
   the old binding removed;
4. projector component version `2` with its binding atomically versioned;
5. protocol-record capability key with the governed interface retained;
6. input capability version `2`;
7. protocol-record interface component with the governed capability retained;
8. a fully mapped version-2 governed interface component with a distinct
   physical test type;
9. existing repository-tree evaluation slot as output;
10. alternate demand-schema key;
11. demand-schema version `2`;
12. empty `inputSlotKeys`;
13. one null input-slot element;
14. duplicate provider input slot;
15. exact input-slot reversal;
16. provider input replaced by well-formed unknown `protocol.slot.unknown`;
17. output slot appended to inputs;
18. provider governed-text rule slot removed while its projector key remains;
19. repository governed-text rule slot removed while its projector key remains;
20. empty failure-code array;
21. one null failure-code element;
22. duplicate `protocol.budget.exhausted`;
23. canonical superset adding `protocol.projector.unexpected-failure`;
24. `maxBytes` changed to generically valid value `1`;
25. `maxDepth` changed to generically valid value `1`;
26. `maxNodes` changed to generically valid value `1`; and
27. `maxComplexity` changed to generically valid value `1`.

The exact `22` component/DAG negatives are:

1. remove only the projector component binding;
2. duplicate that component binding;
3. add one fully mapped declaration-free projector component;
4. map the projector component to undeclared `Missing.Projector.dll`;
5. remove only the projector declaration while retaining its binding;
6. through 12. reuse respectively the activation proof, observed admission
   proof, governed-text codec, source model, Markdown parser,
   governed-reference index, and governed-reference capability component as
   projector, removing the original projector binding in every case;
13. and 14. remove governed-reference capability from respectively provider
   and repository governed-text input slot;
15. remove the governed-reference index declaration and its implementation
   binding while retaining its capability-type binding and consumers;
16. add a fully mapped second index with the same output capability;
17. add a fully mapped second projector with the same output slot;
18. move the projected output slot to applicability;
19. add target-resolution capability input to governed-reference index, forming
   the frozen five-producer/five-edge cycle;
20. add a fully mapped unused parser that consumes a reachable model and
   produces an otherwise unconsumed distinct model;
21. reuse a selector-resolver component as projector and remove the original
   projector binding; and
22. reuse the evaluator component as projector and remove the original
   projector binding.

Component ownership is a role-aware `(key,version) -> role` table over activation
proof, admission proof, codec, model, parser, index, capability, projector,
selector, and evaluator. Repetition inside one role is legal; use by a second
role emits `protocol.manifest.functional-role-collision`. The four envelope and
50 wire cases emit `protocol.manifest.projector-array-envelope` and
`protocol.manifest.projector-row-wire`. Component/DAG rows 1-3 and 5 emit
`protocol.manifest.component-closure`; row 4 emits
`protocol.manifest.artifact-owner`; rows 6-12 and 21-22 emit the role-collision
token. Value rows 1-17 and 20-27 emit `protocol.manifest.projector-value`, while
value rows 18-19 and topology rows 13-14 and 18 emit
`protocol.manifest.projector-slot`. Topology rows 15-17 emit
`protocol.manifest.producer-owner`, row 19 emits
`protocol.manifest.producer-cycle`, and row 20 emits
`protocol.manifest.producer-unreachable`.

Reader performs the raw component/artifact/role, required-projector value, and
projector-slot preflight after parsing raw registry/rule records but before
`CreateRules`, so factory exceptions cannot mask projector diagnostics. Catalog's
generic producer-DAG validation then runs over every producer before remaining
extra-projector/cardinality and legacy exact-topology guards. A friend-test-only
internal result exposes the production-computed root identities, never execution
order; C still owns first runtime ordering.

Production may change only Reader, Writer, and Catalog. Revised readable-code
hard caps are `175`, `70`, and `170`, aggregate production `380`; the one test
hard cap is `410`, and combined green acceptance cap is `770`. A measured
`771-799` stops green acceptance for readability-preserving refactor back to
`770` or lower; `800+` forces design redraw. Assertions, diagnostics, or semantic
vectors may not be compressed away to fit. Fully green successor tuple is
`(3,2,4,1,4,2,2,3,26,3)` and cumulative A becomes `26/26`.
That frozen contract has exact packet-local implementation/evidence, and the
packet is
`ReviewedLocalGreen`. P is `NotApplicable`; unchanged-source predecessor focused
`1/1` has TRX SHA-256
`5144216718A515CDF7B96B47C1F99E93CC2E4E28AC9407D9F9D8BF6B211D5EDC`, and
predecessor cumulative A `25/25` has TRX SHA-256
`3A4AAD033A9F0F8E7E1F4365866867B56143CFECC950C028C75D2C0C5C32EF8A`.
Immutable R source SHA-256 is
`8CA46746908FF177E0041B37BACFC344B555784C9E793F2B272C020F288C7E2A`; its sole
canonical failed `1/1` TRX SHA-256 is
`E8CF388ECF27BC37B79AE51966D3A123CED82CD80432C6F860CB2DA14A03C006`, and R was
never rerun. Final production source SHA-256 values are Reader
`6700C1E03629E576155F6AA55BB87AAC2DEBD800BAE8B3ABDB9FA99AB792E04E`, Writer
`69242E672FEC8606E82CEC9DAFB1C0F8318D33F69B38C582B0BC4714F7EE0D41`, and
Catalog `8428DAA4E2A4C5C4193C0A271B802DED3F15AC4AA199D644A9D787B45B4B7FDA`.
Canonical retained test source is `408` lines at SHA-256
`8E919A438CD9D6B13021AAFB50481E3567E3B40A95F45B059E71E00C71843010`;
focused `1/1` passed in `472ms` at TRX SHA-256
`8F708B1AEEA6848DCA134CC3C653423F3AABC705708CC07C0E4C6173829A4546`,
and cumulative A `26/26` passed with projector duration `518ms` at TRX SHA-256
`74A9A6AD9F152976156D11450F813487FE9E1ECD23F8DE5F6134A2894FBED005`.
Release build passed with `0 warnings / 0 errors` in `6.63s`; format is green;
`StructureOnly` passed with `elapsedMs=394809`; publication-evidence passed
`7/7` in `256.7s` without claiming published-state evidence; independent review
closed `0 Blocking / 0 Important / 0 Minor`. Realized Reader `175`, Writer `32`,
Catalog `155`, aggregate production `362`, test `408`, and combined `770`
satisfy the frozen caps. Hosted run `30798854880` passed Windows in `14m58s` and
Ubuntu in `19m00s`; publication verification was correctly skipped.

### Reviewed-local-green `A-FULL-MANIFEST-01` correction

The inactive `A-CONVERGE-01` routing label is retired before activation. Its
reserved fresh full-manifest Fact was incompatible with a no-new-Fact
convergence classification. `A-FULL-MANIFEST-01` replaces it one-for-one in the
twenty-packet live denominator. `A-CONVERGE-02` remains the final A audit and
adds no Fact.

The replacement was not `TestOnlyGreen`. The pre-green
`CatalogSliceDeclaration` closure rejected the accepted initial manifest before
Writer/Reader because it assumed exactly one rule, four evaluation-slot
occurrences, two selectors, two findings, and one shared admission contract
identity. The accepted declaration has five rules, twelve slot occurrences
over four structurally equal reusable SlotKeys, three selectors, sixteen
findings, and three distinct admission contract identities. That current
restriction was the sole expected-red seam.

Green generalized the already-accepted declaration mechanics without embedding
initial-release counts in reusable production code:

- `CanonicalRules` continues to reject two declarations of one SlotKey unless
  they are structurally equal.
- schema, producer, parser, index, projector, and admission closure use exact
  SlotKey lookup over structurally unique slots rather than flattened cross-rule
  occurrence positions; applicability and evaluation distinct sets remain
  separate, while occurrence counts remain visible to the exact snapshot test.
- admission closure requires exactly the Observed, Failed, and NoInput kinds,
  three distinct proof-component identities, and surfaces/material roles equal
  to the complete canonical slot union. All contracts share one contract
  version, but independently canonical contract keys have no cardinality rule.
  It imposes no zero-applicability rule and no selector/finding count.
- five rules, twelve occurrences, three selectors, sixteen findings,
  twenty-seven logical Policy rows, thirty-five component rows, and six
  artifacts remain exact initial-catalog assertions in the retained Fact; they
  are not generic parser constants.

The proof identities absent from the earlier snapshot text are now exact. The
activation contract is `protocol.activation.release-envelope` / `1`, with proof
component `protocol.activation-proof.release-envelope` / `1`, type
`MeAndAI.Protocol.Application.PolicyActivationProof`. Admission contracts and
components, all version `1`, are:

| Kind | Contract key | Proof component key | Exact Application type |
| --- | --- | --- | --- |
| Observed | `protocol.admission.observed` | `protocol.admission-proof.observed` | `MeAndAI.Protocol.Application.Qualification.ObservedQualificationProof` |
| Failed | `protocol.admission.failed` | `protocol.admission-proof.failed` | `MeAndAI.Protocol.Application.Qualification.FailedAttemptProof` |
| NoInput | `protocol.admission.no-input` | `protocol.admission-proof.no-input` | `MeAndAI.Protocol.Application.Qualification.NoInputRoutingProof` |

The exact R marker and TRX stem are
`TEST-0210-A-BEHAVIOR-RED-0011`. The exact Fact/FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAFullManifestGraphTests.Full_declaration_graph_equals_the_exact_five_rule_six_artifact_thirty_five_component_snapshot`.
It has only `ContractSlice=A`, no Scenario, and expected-red ordinal `0011`.
After registry, five rules, artifacts, components, the successful
`CatalogSliceDeclaration.Create` result, and validation-free
`ParsedCanonicalManifest` are constructed outside the guard, R invokes only
`CanonicalManifestWriter.Write(parsed)`. Only exact runtime type
`ArgumentException`, parameter `rules`, and message equal to
`new ArgumentException("Admission-proof contracts require the exact selector topology.", "rules").Message`
may execute the sole direct `Assert.Fail(exactMarker)`. Type/message mismatch,
setup, Reader, and every other failure remain marker-free. R runs once. Its TRX
contains the marker only in the sole failed result ErrorInfo/Message plus at
most one byte-identical summary echo; permitted stack and RunInfo are marker-
free, and no other result, diagnostic, or attachment contains it.

Green proves canonical Writer -> Reader -> Writer bytes/digest and exact ordered
projections for five rules, ten normative fragments, registry `3/2/4/1`, zero
applicability occurrences, four distinct slots/twelve occurrences distributed
`2/4/3/3`, three selectors, sixteen findings distributed `2/2/4/4/4`, three
admission proofs, exact caches/budgets/failures, the twenty-seven logical Policy
partition, four runtime anchors, one activation proof, three admission proofs,
thirty-five components, and six artifact basenames. The four partitions are
disjoint; exact component-key-to-artifact bindings and the named distribution
Policy `23`, Conformance.Abstractions `5`, Application `4`, Domain `1`,
Conformance `1`, and Markdig `1` are asserted; every artifact is used; the exact
producer roots and reverse slot reachability remain green. The same Fact proves
equal repeated SlotKeys accepted; divergent repeated SlotKey, missing proof
kind, reused proof component, and derived surface/material-role mismatch
rejected; and shared admission contract keys across kinds accepted.

Artifact byte lengths/digests in this A fixture are deterministic test sentinels
that bind declaration rows only. The Fact performs no filesystem, reflection,
assembly-load, or artifact hashing; it does not claim the future Application or
Policy implementation types exist, register, execute, or match physical files.
Actual artifact/type/registration proof remains with activation and later
slices.

The production allowlist is only `CatalogSliceDeclaration.cs`, target/hard
gross delta `40-60/80`. Test scope is the new
`ContractSliceAFullManifestGraphTests.cs`, target `450-550` and retained-source
hard cap `608`, plus the existing
`ContractSliceAAdmissionProofManifestTests.cs` changed-key assertion correction,
gross-delta hard cap `12`. The stale-sibling finding added only the two owning
assertions in `ContractSliceAGovernedReferenceSlotsManifestTests.cs` and
`ContractSliceATargetParserIndexSlotManifestTests.cs`, gross `3+2=5`; it added
no production behavior. The aggregate test hard cap remains `620`; combined
hard cap remains `700`. The admission sibling stayed unchanged through P/R and
green converted only its changed-Observed-key rejection into a positive
parse/write byte round-trip; its mixed-version rejection remains. Project,
solution, package, lock, workflow, public/friend API, every other sibling test,
and held downstream scope remain unchanged. P was `NotApplicable`; unchanged
projector focused `1/1` and cumulative A `26/26` preceded the one canonical R.

Canonical R is immutable at TRX SHA-256
`F586F5BC8FFD5964EB1857512FA089FC8E5E5D3A054E39F28850057BE75DC0DB`.
The terminal-sentinel finding records why unchanged-source original green is not claimed: after
the production correction, the unchanged transient source failed marker-free
only at its terminal missing-behavior sentinel, TRX SHA-256
`AA5F050091E0DAD737B7639C2CFF42E36854C97A924DD61E14D7D34C9CE20010`.
Removing only that terminal line changed source and passed `1/1` at TRX SHA-256
`264F9BEA27ED1B458C8E74AF0448D710356B95218E385F8DF7EFCB2E06128986`;
it is a corrected-original checkpoint only. Final retained green removes the
marker, catch, and sentinel entirely.

The stale-sibling finding first exposed cumulative `25/27` at TRX SHA-256
`700CB92C90BB7C8FF031767D2A6B7C9E25C2A416828CD1D1720AF5695658BF97`.
The two corrected sibling proofs are SHA-256
`8FFB1E412D0311510E0ADB0A94AA6D0FEC1518D94683CE7790FDA44DBCD955F9`
and `884B7478FC4C0DCE166D1FB72E84F9305D072631E3063DFEC42479F24B964EEF`.
The qualification-lifecycle finding then removed five premature planned scenario semantic-evidence
entries. Current per-rule qualification counts are `[1,1,3,1,1]`, total `7`;
the deferred final atomic activation adds that scenario to every rule and changes
them to `[2,2,4,2,2]`, total `12`.

Final A-FULL source is `353` lines at SHA-256
`863BDCDBED53BF3D08C1009CE86842DF8D8B058D49D9BFF5D72B3D5C1A67D4CA`;
Catalog is SHA-256
`456EFCCC3E34A84473CB265B5E3494690D72867C329E3FFE33E2151F70027EF5`.
Focused, cumulative A, full Conformance, and full Domain passed `1/1`, `27/27`,
`27/27`, and `98/98`, at respective TRX SHA-256
`B11EBABED2AE2D938B65F3C8202694B88364DA1AF0E2DDADBCC69754EC450489`,
`0392900A44314848BD0EDBC7425A0ABE5767B2E960726AD29DBF5AC78AB77A90`,
`97C0B960F3EC0CABB32803D4394D3D23685B57D2E0B046DA99929EEBF69E13E2`,
and `0095818A237CB1E84FBDC1F4C4B6279CC5422FC1DDBB9C0CBAA496B00FA5016D`.
StructureOnly passed in `484633ms`; publication-evidence passed `7/7` in
`329.3s` without a published-state claim. Realized production/test/combined
gross deltas are `77/80`, `364/620`, and `441/700`. The packet is exact-head
hosted-green `ReviewedLocalGreen` at correction head
`canonical owning-finding correction head`, tree
`canonical owning-finding correction tree`, and run `30834117740`.
Windows passed in `15m53s`, Ubuntu in `17m50s`, publication verification was
correctly skipped, and that correction head's graph is `4094/4096`. This
records-only closure adds only the reserved two evidence relations, producing a
final delivery graph of `4096/4096` that is closed by the exact evidence in the canonical owning finding; Windows passed in `17m28s`, Ubuntu in `12m28s`, and publication verification was correctly skipped.
Cumulative A is now `32/32`; `A-COMPLETE-PROFILE-01` is exact-head hosted-green
`ReviewedLocalGreen` at the implementation identity recorded in the canonical
owning finding.

### Exact-head hosted-green `A-PREDECESSOR-01` canonical boundary

The direct parent FrozenDesign delivery hosted check is green. Its immutable
attached check on the existing draft PR satisfied the activation predecessor
gate. The packet is now exact-head hosted-green `ReviewedLocalGreen` at the
bounded instruction-graph correction identity recorded in the canonical owning
finding. Its exact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAPredecessorManifestTests.Enforces_existing_predecessor_version_and_exact_digests`;
P is `NotApplicable`; canonical R `0014` is accepted and immutable; G/V are
packet-local green under exact marker/TRX stem
`TEST-0210-A-BEHAVIOR-RED-0014`.

An Existing predecessor serializes exactly `kind`, `catalogVersion`,
`manifestDigest`, and `completeInventoryDigest` in that order. Its version is
strictly lower than the enclosing complete catalog: `2/1` and non-adjacent
`3/1` are positive; equal and higher predecessor versions fail closed. The
current five-rule revision-1 inventory is `104` bytes with digest
`c013e4b9937f225163f58e41b893600b87d88faf6340678a79242041443f8af3`;
the four-rule revision-1 predecessor inventory is `91` bytes with digest
`52cf1f9c6ecc7e8b652d047f595bb4c66fac53735f9637cb3edbd0c54c8e8554`.
The `44`-byte UTF-8/no-BOM, one-terminal-LF seed
`meandai.test-0210.a.predecessor-manifest.v1\n` hashes to
`6fb963fcdf35683f2172ea62e383401f36f5c41660c59e0c594852ccb64108df`.
It is an opaque field-separation/round-trip vector, never parsed as a canonical
predecessor manifest and never treated as authenticity evidence.

The current catalog is rebuilt from the A-FULL rules property by property via
`RuleDeclaration.Create`, changing only `CatalogVersion`. The four-rule
predecessor frame remains an external canonical digest fixture; no predecessor
catalog is activated. `CompleteCatalogDeclaration` owns only strict-lower
validation. Existing transition carriers stay constructible, but this increment
keeps Reader and Writer restricted to Added/current-rule transitions and rejects
non-Added/deferred transition shapes so the later transition packet retains a
natural boundary.

The frozen clone is exactly the current 20-argument API; `currentCatalogVersion`
is v2 or v3 and no other argument changes:

```csharp
RuleDeclaration.Create(
    rule.RuleId,
    rule.RuleRevision,
    currentCatalogVersion,
    rule.NormativeDigest,
    rule.NormativeFragments,
    rule.QualificationScenarios,
    rule.Evaluator,
    rule.ApplicabilitySlots,
    rule.EvaluationSlots,
    rule.ExpectedSelectors,
    rule.SubjectRoles,
    rule.Surfaces,
    rule.SnapshotKinds,
    rule.Operations,
    rule.Findings,
    rule.EvaluationFailureCodes,
    rule.IntroducedIn,
    rule.DeprecatedIn,
    rule.RetiredIn,
    rule.CompatibilityAliases)
```

The accepted immutable R was Writer-only: all construction preceded one guarded
`CanonicalManifestWriter.Write(parsedExisting)` call, which failed with the
exact `InvalidOperationException` message `This writer increment supports only
the minimal qualification slice.` It emitted only the atomically allocated
`TEST-0210-A-BEHAVIOR-RED-0014`; Reader failures could not emit it, and R was
not rerun.
The green contract adds the exact `32`-negative matrix frozen in the test
contract. Production ownership is limited to `CanonicalManifestReader.cs`,
`CanonicalManifestWriter.cs`, and `CompleteCatalogDeclaration.cs`; test
ownership is limited to `ContractSliceAPredecessorManifestTests.cs` and the
obsolete six-line equal-version Writer cleanup in
`ContractSliceACompleteCatalogProfileTests.cs`. Gross production/test/combined
caps are `160/440/600`; `601+` returns to D/RT and `700+` requires redesign.
The `600` D/RT exception is indivisible: separating Reader wire parsing, Writer
canonical emission, Catalog strict ordering, or the exact boundary matrix would
create a temporarily accepted or emitted noncanonical Existing manifest. The
per-file caps and cleanup allocation are mapped by basename in the control plan.
Transition semantics, authenticity/coherence, lifecycle truth, public API,
project/friend/lock/workflow changes, and kernel activation remain held.

The bounded implementation, canonical red/green identities, exact test counts,
graph result, reviews, and two-stage hosted delivery remain immutable in the
owning A-PREDECESSOR historical ledger; they grant no current C authority.

### ReviewedLocalGreen `A-TRANSITION-01` boundary and evidence <a name="a-transition-01-freeze"></a>

The A-PREDECESSOR records synchronization is exact-head hosted-green at the
identity recorded in the canonical owning finding, and the separate
freeze-delivery head passed hosted validation. `A-TRANSITION-01` implementation
and synchronized records delivery are exact-hosted-green; it is immutable
predecessor history. Its exact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes`;
ordinal `0015`; marker/TRX stem
`TEST-0210-A-BEHAVIOR-RED-0015`; one Fact; only `ContractSlice=A`; no Scenario.
Design, independent red-team, final code/test, and evidence/scope reviews each
closed `0/0/0`. P is `NotApplicable`; both implementation and synchronized
records heads are exact-hosted-green.

The exact positive Existing carrier is protocol `0.18.0`, current catalog
version `2`, predecessor catalog version `1`, and current rules `RULE-0001`,
`RULE-0002`, `RULE-0003`, and `RULE-0005`. `RULE-0002` is revision `2`; the
other current rules are revision `1`. Sorted transitions are:

| Rule | Kind | Previous | Current | Reviewed authority |
| --- | --- | ---: | ---: | --- |
| `RULE-0001` | Unchanged | `1` | `1` | absent; wire field omitted |
| `RULE-0002` | Revised | `1` | `2` | present |
| `RULE-0003` | Unchanged | `1` | `1` | present |
| `RULE-0004` | Retired | `1` | absent; wire field omitted | present |
| `RULE-0005` | Added | absent; wire field omitted | `1` | present |

`RULE-0004` is absent from current rules, the current profile, and the current
inventory. `RULE-0005` is absent from the predecessor side. The current profile
contains exactly `RULE-0003` and `RULE-0005`. No predecessor authenticity or
historical-coherence claim is made.

Reader owns strict variant grammar and typed projection; Writer owns canonical
variant serialization; `CompleteCatalogDeclaration` owns RuleId-based current/
absent membership and current-revision mapping. Positional zipping is forbidden.
The typed transition declaration and its public API remain unchanged. Production
is limited to `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`, and
`CompleteCatalogDeclaration.cs`; tests are limited to new
`ContractSliceATransitionManifestTests.cs` and deletion-only predecessor cleanup.

Canonical R constructs the whole valid carrier outside the guard. Only the
assignment from `CanonicalManifestWriter.Write(parsedExisting)` is inside it.
Only exact `InvalidOperationException` with exact message `This writer increment
supports only the minimal qualification slice.` may emit the marker. Type or
message mismatch, Reader failure, setup failure, and every other exception are
marker-free. The exact-FQN run must select, discover, execute, and fail exactly
one result, with zero passed/skipped, and satisfy all sixteen established TRX
oracle requirements. Accepted canonical R is SHA-256
`8E08CAF887D69FF38B247960501AF470DB0DC840154586DF2D4A78CD77D8780E`
with transient source `353` lines / SHA-256
`5593A547D7347224081A28755D6F09B70D8CC5C7C5269B5DDBD1D756DEEBC428`.
The complete oracle passed; R ran once and was never rerun.

The retained Reader matrix has exactly `91` syntactically valid single-object
mutations:

- `001..016`: Unchanged required fields `ruleId`, `kind`, `previousRevision`,
  `currentRevision`, each missing, duplicate, wire-null, and wrong-typed;
- `017..019`: present optional `reviewedAuthority` duplicate, wire-null, and
  numeric wrong-type;
- `020..035`: Added required-field four-by-four matrix;
- `036..055`: Revised required-field five-by-four matrix;
- `056..071`: Retired required-field four-by-four matrix;
- `072..079`: unknown kind, illegal Added previous, illegal Retired current,
  Unchanged unequal revisions, Revised non-increasing revision, and the first
  three Unchanged adjacent swaps;
- `080..090`: final Unchanged swap plus all Added, Revised, and Retired adjacent
  swaps; and
- `091`: representative unexpected property after Revised authority.

Every raw mutation changes one unique transition object, passes a `JsonDocument`
syntax preflight, and reaches the outer `FormatException` boundary. The direct
Catalog matrix is exactly `092..098`: missing `RULE-0005` mapping, duplicate
`RULE-0003`, absent-current non-Retired `RULE-9998`, current `RULE-0003` mapped
Retired, plus Unchanged/Added/Revised current-revision mismatches. Each is exact
`ArgumentException` with `ParamName=transitions`. No other synthetic rule ID is
a positive carrier.

The new transition test owns internal future seam
`CreateMixedTransitionManifest()` and all clone/catalog/profile/mutation helpers;
`A-LIFECYCLE-01` may consume that seam unchanged. The predecessor test receives
exactly `73` physical deletions and no new seam: legacy message constant `1`,
call `1`, transition-boundary helper `22`, transition cases `20`, legacy
rejection helper `6`, transition array `2`, transition JSON `21`.

Gross production additions are capped at Reader `125`, Writer `45`, Catalog
`70`, and `240` total. The retained new test is capped at `377` lines; gross
test additions at `450`; combined additions at `690`. The `73` predecessor
deletions are audited separately and never netted. Production above `240`
reopens D/RT; `700+` requires redesign. The achieved implementation order after
the freeze-delivery hosted gate was canonical R, RuleId catalog partition, atomic
Writer guard/serializer, atomic Reader raw/parser/projection/validator, exact
`91+7` green matrix, then predecessor cleanup and cumulative validation.

The first post-production exact-FQN validation failed marker-free and
console-only with `protocol.manifest.component-closure`; no TRX existed.
[FIND-0461](README.md#find-0461) owns the test-fixture correction that removed only inherited
`protocol.evaluator.rule-0004` while retaining the shared Policy artifact.
Corrected original-oracle source `364` /
`17FD5051B63EB14D44BDF501E108FC15D3FC10E1D666C853C52BC5FC630C5B09`
passed `1/1` console-only. Final marker-free source is `351` /
`44A7F1B6A016105D088005DFECC6AE8B516890295890B7AA5FF10C13F5A1E4C6`.
Focused and retained predecessor runs are `1/1`; cumulative A and full
Conformance are `30/30`; Domain is `98/98`. Reader/Writer/Catalog additions are
`98/12/55`; production/test/combined additions are `165/351/516`; predecessor
cleanup is exact `+0/-73` separately. Release build, format, diff, `15` locks,
pass TRX oracles, and final reviews are green.

The implementation and synchronized records delivery are exact-hosted-green;
the lifecycle records-only freeze delivery also passed Ubuntu in `20m44s` and
Windows in `46m51s`.

### `A-LIFECYCLE-01` operational boundary and local-green closure <a name="a-lifecycle-01-freeze"></a>

The synchronized A-TRANSITION records delivery is the immutable exact
hosted-green activation predecessor recorded in the canonical lifecycle
handoff. The lifecycle packet owns one test Fact at exact FQN
`MeAndAI.Protocol.Conformance.Tests.ContractSliceALifecycleManifestTests.Enforces_rule_lifecycle_against_transitions_and_active_profiles`,
only `ContractSlice=A`, and no Scenario. R is `NotApplicable`, no ordinal,
marker, or red TRX is allocated, G is `TestOnlyGreen`, and production delta is
exactly `0`.

The test consumes the internal mixed transition carrier unchanged. Introduced
and non-null Deprecated values are bounded above by the enclosing protocol
version, not required to equal it. Added does not imply introduced-at-current.
A deprecated but non-retired compatible rule remains active and remains in the
exact named/baseline profile. A current rule has no RetiredIn; retirement is
represented only by an absent-current Retired transition. Predecessor lifecycle,
compatibility-alias deltas, authenticity, and deprecation-implies-Revised remain
outside this packet.

The exact matrix contains four positives and six negatives. Positives retain
the earlier-introduced Added carrier, accept current-version introduction, and
accept earlier/current deprecation while keeping the rule in-profile. Negatives
cover future introduction/deprecation, current RetiredIn, deprecated-active
profile omission, retired/absent profile insertion, and one canonical
deprecatedIn mutation preserving the exact outer FormatException and inner
ArgumentException category/message.

Only new `ContractSliceALifecycleManifestTests.cs` may change. Production and
all existing tests/helpers plus public/friend/project/package/lock/workflow
surfaces are locked. Target test size is `320`, hard test/combined cap is `420`,
and production cap is `0`. The unchanged-production original oracle passed
`1/1`. After one review-owned N4 specificity correction, retained source is
`266` lines / `704F...EDCF`, focused is `1/1`, cumulative A and full
Conformance are `32/32`, Domain is `98/98`, production remains `0`, and fresh
code/test plus evidence/scope reviews each closed `0/0/0`. At that packet
checkpoint, progress was `19/20` (`95%`); any future production need still reopens D/RT.

### Historical `A-COMPLETE-PROFILE-01` closure

The corrected A complete-profile directive, its invalid diagnostic, single
canonical red, bounded C# green, reviews, and exact-head hosted evidence remain
immutable in the owning historical ledger. It closed only that completed A
packet and granted no later-slice authority.

That corrected directive still does **not** authorize:

- ContractSlice B, C, or D source/test implementation;
- executable policy-export construction, `CatalogSliceKernel`, typed
  registration activation, or registration-mismatch behavior in A;
- workflow, scenario-trait, scenario-owner, or
  [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  mutation before all four ContractSlice groups and the combined local route
  are green and separately authorized;
- extraction or cherry-picking from [draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160);
- provider, consumer, adoption, update, release, publication, or authority
  mutation; or
- PowerShell compatibility or retirement work.

Every executable contract described here is implemented in C#.
Markdown is its reviewed architecture and contract specification, not a second
runtime or rule engine. The A directive grants no later-slice authority by
implication.

### ContractSlice B design-freeze boundary <a name="contractslice-b-design-freeze"></a>

The normative delivery decomposition is the
[ContractSlice B micro-delivery plan](subf-0143-contractslice-b-micro-delivery-plan.md).
Its accepted predecessor is the A merge commit
[`51623f4d404a95e0f706d72805cf7ddbbbd293b8`](https://github.com/hasanmanzak/meAndAI/commit/51623f4d404a95e0f706d72805cf7ddbbbd293b8),
validated by exact-main [run 31304787603](https://github.com/hasanmanzak/meAndAI/actions/runs/31304787603).

The frozen B surface contains exactly `24` Abstractions/Conformance public
types, produces cumulative public export count `72`, and changes no Domain
export. The permanent first SurfaceRed is exactly `CS0246` in
`ContractSliceB.SurfaceRed.cs` at `5:38-5:65` for token
`IObservedQualificationProof`; it makes no discovery claim. Retained B tests
will be exactly `11` direct Facts with only `ContractSlice=B`, no `Scenario`,
and ordinal LF-terminated FQN digest
`FAA35F542B1C88DFD228920CB437A9F38C220591726F1ACCA3D756603DAD62AB`.

Public export-total ownership advances with the active slice. The retained A
PublicApi Fact preserves its exact FQN, direct Fact/trait, and A-owned
type/member/friend/negative-surface snapshot, but proves those 48 exports by
exact containment rather than claiming that the growing assemblies contain no
later-slice exports. The B PublicApi Fact is the sole exact cumulative-total
owner at `72`. C and D must repeat the same predecessor-containment/current-
total transition; no retained predecessor Fact may become stale when a later
public surface is added.

B owns codec activation, the three persistent protocol wires, Tests-only
private proof admission, the decode/model cache, codec-local four-counter
resource accounting, sealed ContextProof/Root shapes, and codec-derived
reference narrowing. It does not own parser/index/projector/selector or
provider-neutral capability semantics, shared-root ledgers, staged planning,
kernel evaluation, real Policy export, the initial real-rule set, Scenario
activation, workflow filters, or runtime-efficiency changes. The original B
design phase had P/R/G `NotApplicable` and an empty executable allowlist.
Surface, codec activation, all three wires, B-RESOURCE, B-CACHE, B-ADMISSION,
and B-SEALED-CONTEXT are now immutable hosted-green history. Admission R=0008,
R=0009, R=0010, and codec-derivation R=0013 are immutable diagnostics/no-success;
R=0011, sealed-context R=0012, and corrected codec-derivation R=0014 are
accepted/immutable and their implementation packets are exact-head hosted
green. B-CONVERGE is complete locally with final-sync hosted pending; no later
packet is active.

## Gate 2 outcome

The selected architecture is one release-bound flow. Its proof-candidate step
is supplied by [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md):

```text
verified release or qualification binding
  -> exact finalized manifest and exact compiled policy export
  -> catalog-slice kernel or complete-catalog kernel activation
  -> static profile/rule selection
  -> applicability requirement plan
  -> evidence-acquisition proof candidates
  -> kernel admission and sealed applicability input
  -> Applicable / NotApplicable / Unresolved
  -> PlanEvaluation fixed point
  -> zero-to-N non-empty evaluation acquisition plans
  -> AdvanceEvaluation admission + codec/parser/index/projector fixed points
  -> EvaluationClosure with cumulative typed context
  -> proof-free Evaluate and evaluator semantic intents
  -> kernel-minted findings and evaluations
  -> slice flags OR complete-catalog conformance verdict
```

The same compiled evaluator and provider-neutral capability contract applies to
meAndAI and consumers. Repository files and provider bodies retain different
sealed evidence locations, but they do not select different rule
implementations. A consumer supplies evidence through managed integration; it
does not supply or copy a rule, catalog, codec, parser, indexer, fixture, or
test.

## Project ownership and dependency direction

[SUBF-0143](README.md#subf-0143) adds no public type to
`MeAndAI.Protocol.Domain`. The accepted Domain values from
[SUBF-0152](README.md#subf-0152) and the future evidence carriers from
[SUBF-0153](README.md#subf-0153) remain BCL-only structural values.
Caller-constructible Domain values never confer catalog, acquisition,
qualification, or evaluation authority.

```text
MeAndAI.Protocol.Domain
  <- MeAndAI.Protocol.Conformance.Abstractions
       <- MeAndAI.Protocol.Conformance
       <- MeAndAI.Protocol.Policy

MeAndAI.Protocol.Conformance.Tests
  -> Domain + Abstractions + Conformance + Policy
```

| Project | Exact responsibility | Forbidden responsibility |
| --- | --- | --- |
| `MeAndAI.Protocol.Domain` | Existing scalar/profile/outcome values and the accepted [SUBF-0153](README.md#subf-0153) structural acquisition/evidence carriers | Qualified references, findings, evaluations, catalog activation, parsing, or authority |
| `MeAndAI.Protocol.Conformance.Abstractions` | Catalog/schema declarations, finalized manifest bindings, provider-neutral capability views, evaluator inputs/intents, and proof-candidate seams | I/O, public registration/discovery, final findings/status, cache implementation, or reports |
| `MeAndAI.Protocol.Conformance` | Manifest/catalog activation, admission, sealed contexts, two-tier caches, two-phase planning, qualified references, kernel minting, and aggregation | Provider I/O, consumer plugins, debt/waiver/enforcement, report serialization, or publication |
| `MeAndAI.Protocol.Policy` | Exact compiled RULE-0001..0005 codecs/models/indexers/evaluators and one qualification-only export | Complete-protocol-catalog or verdict authority, public registration, host, I/O, report, or mutation |
| `MeAndAI.Protocol.Conformance.Tests` | Fresh [TEST-0210](test-cases.md#test-0210) qualification, exact export/project graph, negative surface, and deterministic behavior | Shipped product API, consumer tests, provider live-I/O coverage, or sibling-result aggregation |

`Conformance` and `Policy` are siblings. `Conformance` never references
`Policy`; the application later supplies an exact export and its already
verified release-artifact proof. No reflection scan, DI scan, assembly scan, or
consumer registration closes that gap.

## Catalog authority classes

The first five rules are deliberately not the complete protocol catalog. Two
non-interchangeable declaration and kernel families make that fact executable:

| Family | Declaration/export | Kernel/result | Authority |
| --- | --- | --- | --- |
| Qualification slice | `CatalogSliceDeclaration` plus `PolicyQualificationSliceExport` | `CatalogSliceKernel` plus `CatalogSliceEvaluation` | May qualify exactly the declared slice; has no named authoritative profile and no `ConformanceVerdict` |
| Complete protocol snapshot | `CompleteCatalogDeclaration` plus `CompletePolicyPackExport` | `ConformanceKernel` plus `CompleteCatalogEvaluation` | May resolve release-declared named profiles and mint a complete-baseline `ConformanceVerdict` only after exact inventory and release-envelope proof |

The production `MeAndAI.Protocol.Policy` assembly in this slice exposes only
`InitialRuleQualificationPolicy.Export`, whose type is
`PolicyQualificationSliceExport`. It exposes no
`CompletePolicyPackExport`. Relabeling the same five rules as a complete
protocol snapshot, adding a caller-created named profile, omitting a rule,
adding an undeclared rule, retaining a retired rule, or leaving an evaluator,
schema, model, index, finding code, or transition unmapped fails activation.

A synthetic [TEST-0210](test-cases.md#test-0210) qualification authority may
declare RULE-0001 through RULE-0005 as its exact *fixture* inventory. It cannot
claim those five rules are the complete inventory of a real protocol release
and cannot produce an authoritative `Conforming` result.

## Acyclic artifact and manifest binding

The build and authority graph is one-way:

```text
compile artifacts containing logical keys only
  -> hash exact artifact bytes
  -> finalize canonical manifest binding keys, types, and artifact digests
  -> hash canonical manifest bytes
  -> bind manifest plus artifacts in the release or qualification envelope
```

No compiled artifact embeds its own final digest. No manifest includes its own
digest in the bytes that are hashed. `FinalizedPolicyManifest.ManifestDigest`
is computed over a private entry copy of the canonical manifest bytes and is
carried by the sealed typed projection; the raw bytes are not retained by
`FinalizedPolicyManifest` and the digest is not a serialized manifest field. The release envelope owned by
[FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
binds that digest and every exact artifact digest.

Compiled exports contain only logical component keys, versions, explicit
instances, and exact registration order. Activation receives an
`IPolicyActivationProof` from the already trusted release resolver/bootstrap
boundary. Implementing that interface grants no authority. The activator
requires its exact proof implementation type and artifact to be bound by the
same envelope, and requires it to prove that the loaded export instance came
from the exact artifact bytes named by the manifest. A caller-authored proof,
an assembly-name assertion, an MVID assertion, or an export self-asserted
digest is insufficient.

[TEST-0210](test-cases.md#test-0210) has four ordered, friend-only proof paths and no generic test
origin. ContractSlice B admits only its codec-registration subset through
`IContractSliceBActivationProofState`; it does not construct either public
export. ContractSlice C owns a Tests-owned synthetic qualification export and
a distinct synthetic complete graph; both reuse the same
Tests-owned six registration families and executable component objects and
artifact graph, but only the complete variant has complete-snapshot authority.
Neither reuses a real Policy registration or claims a production release.
ContractSlice D alone may mint the non-authoritative qualification
mirror whose catalog, component list, codec/parser/index/projector
declarations, budgets, and all six internal registration lists are exact-equal
to `InitialRuleQualificationPolicy.Export`; only the activation and three
admission proof declarations are replaced by exact test-owned proof types.
Every path is rejected outside the exact [TEST-0210](test-cases.md#test-0210) friend envelope. None can
activate a production complete manifest/export, escape the test process, or
confer release/consumer authority.

## Canonical manifest contract

The manifest schema key is `protocol.policy-manifest.v1`. Its canonical bytes
are strict UTF-8 without BOM and contain one JSON object followed by exactly one
LF. Schema 1 permits at most `16,777,216` input bytes, reachable JSON container
depth `9`, and `1,000,000` JSON tokens including property names and scalar/
container tokens. The root object has depth `1`; only an object or array start
increments depth. `ParseCanonical` checks the byte ceiling before allocating
its private copy, then enforces the depth and token ceilings while reading;
equality is allowed. Byte and token one-over values retain their exact resource
`FormatException` boundaries: byte one-over owns exact message `The canonical
policy manifest exceeds the byte ceiling.` and token one-over owns exact message
`The policy manifest exceeds the JSON token ceiling.`; both have null inner
exception. A tenth container is not a grammar-valid schema-1 manifest; it is
rejected first through outer `FormatException` message `The policy manifest is
not canonical JSON.` with a `JsonException` inner exception.
It adds no ambient, machine-dependent, declaration-count, or collection-count
limit. Canonicalization is
owned by [SUBF-0143](README.md#subf-0143), independently
of the later report serializer owned by
[SUBF-0154](README.md#subf-0154).

Canonical input bytes are private parsing state. After the non-reading length
ceiling check, `ParseCanonical` copies the complete `ReadOnlyMemory<byte>` at
method entry, parses only that copy with the
exact schema below, reserializes the typed projection, requires byte equality,
computes `ManifestDigest`, seals immutable projections, and then discards the
raw copy. `FinalizedPolicyManifest` publishes the digest and safe typed
projections, not raw JSON, a byte buffer, or a retained `ReadOnlyMemory<byte>`.
The `MeAndAI.Protocol.Application` internal factory used by [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
and the `MeAndAI.Protocol.Conformance.Tests` [TEST-0210](test-cases.md#test-0210) friend call this one parser; neither implements another copy/parser path.
There is no public manifest constructor or factory.

`A-RESOURCE-01` freezes independent sequential byte/token/depth carriers:
qualification aliases, sorted unique fixed-width aliases, and the full depth-9
graph with deepest `componentKey` scalar replaced by a tenth container. Legacy
R owns exact `Expected JSON token 'String'.` with no inner exception; G changes
only `CanonicalManifestReader.MaximumDepth` from `64` to `9`. Production is
`+1/-1`; test/combined additions are capped at `650/651`. A fresh parent samples
the exact focused process tree every `100ms` from root launch through root exit;
observable descendants, at most `90s`, and at most `1,610,612,736` bytes
(`1.5 GiB`) are mandatory. Carriers are in-memory and sequential, use pre-sized
and released buffers plus streaming token counts, and use no disk fixture,
`JsonDocument`, naive repeated concatenation, ambient value, or parallel
million-token construction. Any variance reopens D/RT.

`0016`-`0023` remain immutable diagnostic attempts. The sole accepted canonical
R is `0024`; bounded `MaximumDepth 64 -> 9` G, focused/cumulative/full/Domain
green, Release build/format, and renewed reviews are complete locally. Exact
artifact paths, metrics, SHA-256 identities, diagnostic causes, and green
evidence remain owned by their historical ledger.
Exact [`885ad0ba01f99ed44e325fa974a6cb62e89b4986`](https://github.com/hasanmanzak/meAndAI/commit/885ad0ba01f99ed44e325fa974a6cb62e89b4986) passed Ubuntu `18m51s` and
Windows `43m06s` in run `31264791256`,
with publication verification skipped. R was not rerun.

### `A-CONVERGE-02` corrected V4 audit contract <a name="a-converge-02-freeze"></a>

Resource head
[`885ad0ba01f99ed44e325fa974a6cb62e89b4986`](https://github.com/hasanmanzak/meAndAI/commit/885ad0ba01f99ed44e325fa974a6cb62e89b4986)
is hosted-green. V1 is immutable diagnostic/no success. V2 design head
[`7bf97ad149511a4d13a44da0c2a048d300818602`](https://github.com/hasanmanzak/meAndAI/commit/7bf97ad149511a4d13a44da0c2a048d300818602)
passed Ubuntu `19m37s` and Windows `37m52s` in
[run 31273865409](https://github.com/hasanmanzak/meAndAI/actions/runs/31273865409),
with publication skipped, but its sole
authorized launcher admission failed at the outer sandbox with exact
`CreateProcessAsUserW failed: 5` before any shell/child/root. V2 is therefore
`AttemptInvalidated/NoInvocation/NoSuccess`; same-V2 retry is prohibited. V3
passed its hosted gate and every audit validation, then exited `1` because
default `ConvertFrom-Json` coerced exact ISO strings to culture-formatted
`DateTime` text before `ParseExact('O')`. V3 is immutable no-success/no-retry.

This pure audit packet has P/R/G `NotApplicable`, not `TestOnlyGreen`, and an
empty executable allowlist. It adds no Fact/FQN/marker/ordinal/TRX or code,
test, project, package, lock, workflow, scenario/status/owner mutation. The
exact predecessor twelve-path cohort recorded V1/V2/V3 and froze V4 while
retaining `19/20`; only a fully green V4 could produce `CompletionRecommended`,
and no intermediate record claimed `20/20`.

One atomic code-free `COHORT-SYNC-A-FINAL` commit owns the only global
transition to `20/20`. Its exact allowlist is:

```text
.ai/memory/README.md
.ai/memory/log/README.md
.ai/memory/project.md
.ai/memory/log/2026-08-08-feat-0065-subf-0143-contractslice-a-converge.md
docs/architecture/protocol-governance-and-execution/README.md
docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md
docs/architecture/protocol-governance-and-execution/transition-register.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-micro-delivery-plan.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md
docs/features/README.md
```

The handoff is at most `80` lines and `4` Markdown links, with at most `2`
repository-relative outgoing links; no other new node or link relation is
allowed. The sync changes each live current tuple exactly once to A audit
complete/recommended, `20/20`, cumulative `32/32`, [TEST-0210](test-cases.md#test-0210)
`Planned`, and all activation/B/C/D holds retained; it rewrites no historical
evidence. `git diff --check`, StructureOnly, graph limits `4096` edges and
`4,194,304` parsed bytes, and two final reviews `0/0/0` must close on the exact
atomic tree before commit. Until that commit is exact-head hosted green, the
authoritative state remains local completion recommended / hosted pending.

Discovery is frozen to Release `--no-restore --no-build --list-tests --filter
"ContractSlice=A"`. Sorting the exact FQNs ordinally, joining with LF, and
adding one final LF yields `32` names and SHA-256
`C42DF0B847DF11078C904346CA5D033084797B5386450527E3F8D99612F08B92`.
Each exact FQN is prefix `MeAndAI.Protocol.Conformance.Tests.` plus one
suffix below; the reconstructed full names, not the suffixes alone, own the digest:

```text
ContractSliceAAdmissionProofManifestTests.Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure
ContractSliceAArtifactComponentGraphTests.Enforces_exact_binding_runtime_anchor_and_reachability_graph
ContractSliceACanonicalJsonGrammarTests.Enforces_exact_document_and_slice_structural_grammar
ContractSliceACanonicalNumberTests.Enforces_exact_integer_grammar_and_range
ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding
ContractSliceACompleteCatalogProfileTests.Enforces_exact_provider_profile_genesis_catalog_inventory_digest_and_added_transitions
ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles
ContractSliceAFullManifestGraphTests.Full_declaration_graph_equals_the_exact_five_rule_six_artifact_thirty_five_component_snapshot
ContractSliceAGovernedReferenceSlotsManifestTests.Enforces_exact_governed_reference_index_and_dual_governed_text_slot_capability_closure
ContractSliceAIndexSlotManifestTests.Enforces_exact_repository_tree_index_and_slot_capability_closure
ContractSliceALifecycleManifestTests.Enforces_rule_lifecycle_against_transitions_and_active_profiles
ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest
ContractSliceAOwnershipTests.DomainExportsEqualTheOrdinalUnionOfPredecessorInventories
ContractSliceAOwnershipTests.EffectiveRestoreGraphsEqualTheContractSliceATotalGraph
ContractSliceAOwnershipTests.FriendAssembliesEqualTheCurrentContractSliceAMatrix
ContractSliceAOwnershipTests.LocksEqualTheContractSliceATotalGraph
ContractSliceAOwnershipTests.PackageReferencesEqualTheContractSliceAGraph
ContractSliceAOwnershipTests.SolutionAndProjectReferencesEqualTheContractSliceAGraph
ContractSliceAParserRecordSlotManifestTests.Enforces_exact_markdown_parser_protocol_record_index_and_slot_capability_closure
ContractSliceAPredecessorManifestTests.Enforces_existing_predecessor_version_and_exact_digests
ContractSliceAProjectorDagManifestTests.Enforces_exact_projector_bindings_and_global_producer_graph
ContractSliceAPublicApiTests.DeclaredPublicSurfaceEqualsTheContractSliceASnapshot
ContractSliceAPublicApiTests.ExportedTypesEqualTheContractSliceAInventories
ContractSliceAPublicApiTests.FriendAssembliesEqualTheCurrentContractSliceAAllowlist
ContractSliceAPublicApiTests.PublicTypesHaveNoConstructionOrSerializationLeak
ContractSliceAPublicApiTests.StagedExportsExposeOnlyTheContractSliceASeam
ContractSliceAResourceManifestTests.Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings
ContractSliceARuleDeclarationTests.Enforces_canonical_multi_fragment_rule_provenance
ContractSliceASchemaSlotManifestTests.Enforces_exact_schema_and_zero_capability_evidence_slot_closure
ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure
ContractSliceATargetParserIndexSlotManifestTests.Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure
ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes
```

The focused predecessor FQN is the resource test above and must pass `1/1`.
The main `ContractSlice=A` run and unfiltered full Conformance run must each
pass `32/32`; full Domain must pass `98/98`. The API/friend/hold subset is
exactly the five `ContractSliceAPublicApiTests` plus six
`ContractSliceAOwnershipTests` FQNs above; the same LF framing yields SHA-256
`F58C362D6CA12A4C67AFCD1C75573063A89F2909088BA11DFA9BAF247E68B0C6`,
and the class-union filter must select and pass `11/11`.

After the synchronized V4 design head is hosted green, preflight the exact
head/clean status and PowerShell `7.6.4`; require both the fixed script path and
fixed evidence root below to be absent. The competing-process set is exactly
`pwsh.exe` or `powershell.exe`, excluding the preflight PID, whose non-null
command line contains the exact V4 script path or root name by ordinal-ignore-
case comparison; a nonzero set blocks materialization without consuming V4.
Materialize the fence once at
`D:\Temp\meandai-aconverge-v4-91a7c6e4c5e349a0b22e3f37d5d0f84a.ps1`,
then require canonical LF plus one terminal LF, exactly `10,338` bytes, SHA-256
`2232F691F8671CD256A79D2AE381423469CB046B4FC43F0F5DDEB289816C5019`,
and AST `1,774` tokens / `69` top-level statements / `0` errors
while the root remains absent and the same process set remains zero. Invoke one pre-authorized
`require_escalated` tool call from repository root, substituting the literal
hosted-green forty-character head for `<HEAD>`, with exact command
`& 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe' -NoProfile -File 'D:\Temp\meandai-aconverge-v4-91a7c6e4c5e349a0b22e3f37d5d0f84a.ps1' -ExpectedHead '<HEAD>'; exit $LASTEXITCODE`.
No wrapper/fallback/retry is permitted; every admitted tool call, including an
outer admission failure, consumes the attempt. The exact immutable V4 script body
(identity above) and its final six-file evidence-root inventory are retained by
the owning convergence ledger; this historical design intentionally omits the
verbatim copy.

V4 attempt classification is fail closed: absent root means outer/pre-entry
failure; root without `entry.json` means entry-write failure; a malformed or
missing entry is invalid evidence; valid `Entered` with null `completedUtc`
means in-script failure; only child exit `0`, exact final six regular files, and
the parsed identity/chronology-valid `Completed` entry can mean success. Every
admitted attempt consumes authority and is never retried.

V4 owns build, format, diff, StructureOnly, publication, and six lock oracles;
every exit must be zero. Final production/test/docs/memory and evidence/scope
reviews must each close `0/0/0` after the final record edit.

V1 exact head
[`7c698d78374678a9f3d2264edc8d451effeaffe0`](https://github.com/hasanmanzak/meAndAI/commit/7c698d78374678a9f3d2264edc8d451effeaffe0)
and [run 31269244100](https://github.com/hasanmanzak/meAndAI/actions/runs/31269244100)
are immutable diagnostic/no success. V2 and V3 are likewise immutable
diagnostics; their detailed custody is owned by the convergence ledger. V4
preserves every audit oracle and changes only culture-safe timestamp sealing.

The exact V4 audit is `FullyGreen` and produced `CompletionRecommended`; the
atomic sync above now records routing `20/20` locally, with its exact-head hosted
gate pending, while cumulative A remains `32/32`. [TEST-0210](test-cases.md#test-0210)
stays `Planned`. Scenario/status/owner, both combined workflow filters,
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
B/C/D, merge, release, and publication remain held.

`FinalizedPolicyManifest.ParseCanonical` is the Abstractions-owned byte
boundary. It throws `FormatException` for empty input, BOM, invalid UTF-8,
invalid JSON, trailing or missing LF, alternate field order or spelling,
unknown/duplicate/null fields, numeric or grammar failure, invalid closed
union/cardinality, noncanonical collection order, or typed-reserialization byte
inequality, including declaration/reference/artifact-component mapping closure
failure observable from the document alone. It does not reference or throw the
downstream Conformance-owned `CatalogIntegrityException`. A successfully parsed
manifest that later conflicts with the predecessor-trusted sealed-manifest or
release-envelope identity uses `CatalogIntegrityCode.ManifestInvalid`; a valid
parsed artifact projection that differs from the actual loaded artifact set or
bytes uses `CatalogIntegrityCode.ArtifactMismatch`. Raw byte rejection never
enters a kernel or masquerades as activation evidence.

The [FIND-0439](README.md#find-0439) correction makes this exception boundary
exhaustive. `ParseCanonical` resolves every
document-local rule/slot/requirement/profile/transition/schema/producer/
projector/component/artifact reference, uniqueness constraint, reachability
constraint, and DAG edge and reports any failure as `FormatException`.
`CatalogIncomplete` begins only after successful parsing when validation needs
predecessor-trusted snapshot state or the loaded executable export/registration
partition; it never reclassifies a defect knowable from manifest bytes alone.
Factory `ArgumentException` instances caused by parsed document values are
wrapped as `FormatException`; cancellation, out-of-memory, and unexpected
runtime failures are not caught or relabeled.

A qualification slice may contain zero rules. Its payload-schema, parser,
index, demand-projector, and admission-proof arrays may each be empty when the
resulting declaration/reference graph is closed and no rule or declaration
requires a missing row. The activation-proof contract, its component identity,
one mapped positive-length artifact, and the positive cache-budget shape remain
mandatory. Such an empty qualification slice is structural only: it is not a
complete catalog, executable export, production-policy claim, or verdict
authority. This is the exact minimal positive manifest fixture for the first
ContractSlice A behavior increment.

Every component row must be referenced by the activation-proof,
admission-proof, codec, parser, index, demand-projector, selector, evaluator,
model-implementation, or capability-interface declaration graph, except the
four exact schema-1 runtime anchors `protocol.runtime.domain`,
`protocol.runtime.conformance-abstractions`, `protocol.runtime.conformance`, and
`protocol.runtime.markdig` with the exact identities declared below. A
qualification manifest may omit any runtime anchor that its closed declaration
graph does not require, including all four in the minimal fixture. An arbitrary
unreferenced component, an alternate runtime-anchor identity, a component
without exactly one artifact mapping, an artifact used by no component, or a
reference to an undeclared component is document-local `FormatException`.

The exact byte rules are:

- no insignificant whitespace, comments, duplicate properties, `null`,
  floating-point numbers, unknown properties, or alternate spellings;
- field names are ASCII and appear in the schema order below;
- strings use JSON escaping with `\"`, `\\`, `\b`, `\f`, `\n`, `\r`, and
  `\t` where applicable; `/` remains raw; remaining C0, `DEL`, and C1 controls
  use lowercase `\u00xx`; every other valid Unicode scalar is emitted as its
  raw UTF-8 bytes without normalization;
- integers are base-10, non-negative, and have no leading zero except `0`;
- booleans are lowercase `true` or `false`;
- object collections are arrays in the exact canonical ordinal order below;
- all key, version, rule, fragment, slot, code, profile, transition, component,
  and artifact collections reject duplicates before serialization; and
- the document ends with exactly one LF.

The root field order is:

```text
schema
authorityKind
sourceCommit
protocolVersion
catalogVersion
slice | completeCatalog
schemaRegistry
activationProofContract
artifactFiles
components
```

Exactly one of `slice` or `completeCatalog` is present. The absent variant is
omitted, never serialized as `null`. `manifestDigest`, canonical bytes, loaded
instances, cache state, and a release-envelope digest are never serialized.
`sourceCommit` is an exact lowercase 40-hex commit identity. `ParseCanonical`
validates that identity and the internal normative-fragment path/blob/selector/
digest grammar and closure only. Proof that the commit and containing blobs
actually exist and contain the declared fragment bytes requires trusted source/
blob evidence and remains in the predecessor-trusted qualification or release
envelope; it is not inferred by this byte parser.

The nested object field order is normative:

| Object | Exact fields in order |
| --- | --- |
| `slice` | `sliceKey`, `sliceVersion`, `rules` |
| `completeCatalog` | `predecessor`, `completeInventoryDigest`, `baselineProfileName`, `rules`, `transitions`, `namedProfiles` |
| genesis `predecessor` | `kind` |
| existing `predecessor` | `kind`, `catalogVersion`, `manifestDigest`, `completeInventoryDigest` |
| `schemaRegistry` | `payloadSchemas`, `parsers`, `indexes`, `demandProjectors`, `admissionProofContracts`, `cacheBudget` |
| payload schema | `schemaKey`, `schemaVersion`, `codec`, `outputModel`, `maxBindingsPerInstruction`, `maxRetainedCanonicalBytesPerInstruction`, `budget`, `codecFailureCodes` |
| parser | `parserKey`, `parserVersion`, `parser`, `inputs`, `outputModel`, `budget`, `failureCodes` |
| index | `indexKey`, `indexVersion`, `indexer`, `invocationScope`, `inputs`, `outputCapability`, `budget`, `failureCodes` |
| demand projector | `projectorKey`, `projectorVersion`, `projector`, `inputCapability`, `inputSlotKeys`, `outputSlotKey`, `demandSchemaKey`, `demandSchemaVersion`, `budget`, `failureCodes` |
| activation proof contract | `contractKey`, `contractVersion`, `proofComponent` |
| admission proof contract | `contractKey`, `contractVersion`, `kind`, `proofComponent`, `surfaces`, `materialRoles` |
| component identity | `componentKey`, `componentVersion`, `assemblyName`, `typeName` |
| artifact file | `fileName`, `byteLength`, `artifactDigest` |
| component/artifact mapping | `component`, `artifactFileName` |
| model input | `kind`, `model`, `minimumCount`, then optional `maximumCount` |
| capability input | `kind`, `capability`, `minimumCount`, then optional `maximumCount` |
| model identity | `modelKey`, `modelVersion`, `implementationType` |
| capability identity | `capabilityKey`, `capabilityVersion`, `interfaceType` |
| semantic budget | `maxBytes`, `maxDepth`, `maxNodes`, `maxComplexity` |
| cache budget | `maxDecodeEntries`, `maxDecodeCanonicalBytes`, `maxIndexEntries`, `maxIndexNodes`, `maxConcurrentDecodeAttempts`, `maxConcurrentIndexAttempts`, `retentionPolicy` |
| normative fragment | `path`, `containingBlob`, `anchor`, `startLine`, `endLine`, `canonicalizationSchema`, `canonicalByteLength`, `fragmentDigest` |
| evidence slot | `slotKey`, `requirement`, `profileSurfaces`, `materialRole`, `targetSelectorKey`, `capabilities` |
| expected selector | `selectorKey`, `slotKey`, `selectorSchemaKey`, `resolver`, `allowedParentKinds`, `allowedFindingCodes` |
| finding declaration | `code`, `severity`, `remediation`, `allowedPrimaryReferenceKinds`, `allowedRelatedReferenceKinds` |
| rule | `ruleId`, `ruleRevision`, `catalogVersion`, `normativeDigest`, `normativeFragments`, `qualificationScenarios`, `evaluator`, `applicabilitySlots`, `evaluationSlots`, `expectedSelectors`, `subjectRoles`, `surfaces`, `snapshotKinds`, `operations`, `findings`, `evaluationFailureCodes`, `introducedIn`, `deprecatedIn`, `retiredIn`, `compatibilityAliases` |
| transition | `ruleId`, `kind`, then only the variant-valid `previousRevision`, `currentRevision`, and `reviewedAuthority` fields in that order |
| named profile | `name`, `axes`, `ruleIds` |

The manifest never serializes a nullable property as JSON `null`.
`deprecatedIn` and `retiredIn` are independently omitted when their typed
values are null and otherwise appear at their table positions. A transition
omits every variant-inapplicable revision/authority field; `reviewedAuthority`
is optional only for `Unchanged` and mandatory for Added, Revised, and Retired.
A component input has exactly one of `model` or `capability`; `kind` is exactly
`model` or `capability`. `maximumCount` is omitted when its typed value is null
(`unbounded`) and otherwise is present at the shown position.

Every `ComponentTypeIdentity`-typed field outside the root `components` array
is an exact component reference object with fields `componentKey`, then
`componentVersion`; it never repeats `assemblyName` or `typeName`. The root
array alone contains the full component identity rows. `ModelContractIdentity`
is an inline reference value with fields `modelKey`, `modelVersion`, then
`implementationType`, where `implementationType` is a component reference.
`CapabilityContractIdentity` is an inline reference value with fields
`capabilityKey`, `capabilityVersion`, then `interfaceType`, where
`interfaceType` is a component reference. Repeated model/capability reference
values must be byte-identical; they are not duplicate declaration rows.

Embedded Domain values have manifest-local JSON shapes; this does not add a
serializer or canonical text API to Domain:

| Domain value | Exact manifest JSON |
| --- | --- |
| `RuleId` and every closed categorical value | one JSON string containing exact `Value` |
| `RuleRevision` | one positive JSON integer containing `Value` |
| `ExactSha256Digest` | one lowercase 64-hex JSON string |
| `SurfaceSet` | a JSON array of SurfaceKind token strings in Repository, Provider, Workflow, Release schema order |
| `ExecutionProfile` | object fields `subjectRole`, `operation`, `snapshotKind`, `surfaces`, `enforcementPhase`; categorical fields are token strings and `surfaces` is the array above |
| `EvidenceRequirement` | object fields `key`, `surface`, `kind`, `completenessContract`, `payloadSchemaKey`, `payloadSchemaVersion`, `acceptedConsistencyClasses`; `surface` is its token and the last field is a token array in ExactSnapshot, ObjectVersionBound, BoundedNonAtomicObservation schema order |

Rule/category collections use the same token representation and their declared
schema order; they are never CLR property names, numeric enum ordinals, or
`ToString()` of `ExecutionProfile`. The accepted Domain property order is
therefore not inferred by a serializer.

Arrays are unique and sorted as follows: artifact files by `FileName`;
component mappings by component key/version; schemas, parsers, indexes, demand
projectors, model and capability reference values by key/version; component
inputs by model before capability then referenced key/version; admission proof contracts by
key/version then proof-kind rank; rules and transitions by RuleId; profiles by
Name; slots by SlotKey; expected selectors by SelectorKey; codes and material
roles ordinal. Profile categorical collections use their accepted schema
order. Normative fragments alone retain declared semantic order. A schema,
parser, index, proof contract, component definition, artifact, rule,
transition, or profile declaration row appears exactly once; only the explicit
logical reference values above may recur.

`CompleteInventoryDigest` is factory-derived and cannot hash itself. Its exact
input is:

```text
ASCII "meandai.complete-rule-inventory.v1\n"
uint32-be active-rule-count
repeat in RuleId ordinal order:
  exact 9 ASCII bytes RULE-NNNN
  uint32-be RuleRevision.Value
```

The SHA-256 of that frame is serialized in `completeCatalog`.
`ManifestDigest`, not the inventory digest, binds the complete semantic,
schema, profile, transition, component, and artifact projection.

## Normative fragment and rule-revision contract

Each `NormativeFragmentDeclaration` contains:

- repository-relative path;
- renderer-active stable fragment;
- exact containing Git blob identity;
- inclusive one-based source-line selector;
- canonicalization schema key;
- canonical fragment byte length; and
- exact SHA-256 fragment digest.

The canonicalization schema is
`protocol.normative-fragment.utf8-lines.v1`. It rejects BOM, invalid UTF-8, and
lone CR; accepts LF or CRLF; normalizes selected line endings to LF; and emits
the exact selected lines followed by exactly one LF. The selected range must be
inside the exact containing blob and the declared stable fragment must resolve
uniquely in that blob.

Path, stable fragment, containing blob, selectors, and fragment digest prove
provenance and selector integrity. `RuleRevision` semantic identity is derived
from the ordered canonical fragment bytes so an unrelated edit elsewhere in a
containing document does not revise the rule. The exact framing is:

```text
ASCII "meandai.rule-normative-fragments.v1\n"
uint32-be fragment-count
repeat in declared order:
  uint64-be fragment-byte-length
  exact canonical fragment bytes
```

The SHA-256 digest of that framed byte sequence is the rule's normative digest.
Path, fragment name, anchor, blob identity, selector, and already-computed
fragment digest are intentionally not repeated inside the semantic framing.
Changing the ordered fragment bytes, applicability/evidence/finding contract,
or qualification-observable expected outcome increments `RuleRevision`. A
same-semantics compiled-artifact refactor changes only the artifact binding
after differential qualification.

The exact baseline input blobs are:

| Path | Exact blob |
| --- | --- |
| `PROTOCOL.md` | SHA-1 digest: `4698461c34196bc3639498d6b137f87e5a8bbe5d` |
| `templates/decision.md` | SHA-1 digest: `a222f89700ea589dfbda683d69ad0ad50c48d72a` |

### Initial normative fragment inventory

| Rule / fragment | Selector | Canonical bytes | Fragment SHA-256 |
| --- | --- | ---: | --- |
| RULE-0001 / `protocol.feature-packet` | `PROTOCOL.md#6-documentation-graph`, lines 520-521 | 84 | `15d1991754f47a2ab096a32e5bbbcc4e8e20b8e95554364eac29da8c6114c3d7` |
| RULE-0002 / `protocol.decision-record` | `PROTOCOL.md#6-documentation-graph`, lines 522-523 | 92 | `a4588d88bea471839d750e4889d4deaabd422562053ab7caca5c11eede2ee243` |
| RULE-0002 / `template.decision.required-structure` | `templates/decision.md#dec-nnnn---decision-title`, lines 1-30 | 677 | `63a1ad23d40e8b228f9efc6e85fb76a91aee46e707a4fbd2536aab081c4c3aa5` |
| RULE-0003 / `protocol.clickable-exact-target` | `PROTOCOL.md#6-documentation-graph`, lines 496-508 | 911 | `a27cab5b79026b0b72839de0d88ade32fe37aeaa5a46a2076dea5f54cdfcf37f` |
| RULE-0003 / `protocol.repository-provider-reference-form` | `PROTOCOL.md#6-documentation-graph`, lines 535-543 | 680 | `26d715022a371aa5154254bca291adb4e0f87bc6a43a913a6ff93727e9b54065` |
| RULE-0003 / `protocol.link-validation` | `PROTOCOL.md#6-documentation-graph`, lines 554-555 | 156 | `fca31621542242a9243eb5ef4efc799e0614c7dcc7ceb502600b2fe5ce60d021` |
| RULE-0004 / `protocol.addressable-target-fragment` | `PROTOCOL.md#6-documentation-graph`, lines 500-504 | 365 | `527f9b4fa06345a74c50da8388fd5704608f808c4a0ffc2963789425f69220f0` |
| RULE-0004 / `protocol.embedded-stable-id-anchor` | `PROTOCOL.md#6-documentation-graph`, lines 509-517 | 620 | `c992774d3b8a2a4ccd1e910991ef623b04ac925c176ba994c978380834a6f702` |
| RULE-0004 / `protocol.fragment-target-form` | `PROTOCOL.md#6-documentation-graph`, lines 535-546 | 887 | `12fec7ac5a00e0ba137bc49f41ac7e54799e5e4b8278b5a785ef558ff7f8bd8f` |
| RULE-0005 / `protocol.commit-permalink` | `PROTOCOL.md#6-documentation-graph`, lines 547-553 | 509 | `203c70b6f2211f453b711c56d3a669a573cae728513b46d5706e1e8ec8d06231` |

All five initial rules use `RuleRevision.Create(1)`. Their exact normative
digests are:

| Rule | Normative digest |
| --- | --- |
| [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001) | `69fa9341b359ed5393ba6c92dd0682abecb5bc15e1745d8cddc07583744544fe` |
| [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002) | `321aca48e204e7f3ddba9a327e57ad9184c9ec838160d1cd50b0afcf1c57121f` |
| [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003) | `cac99d8884e9737f3db976b4ea10d175f87b8b526af38d9442d964443ef2639e` |
| [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004) | `951932712706a09ee94dbdb784533d48ae2895c962d94476dde98da92fbf8e69` |
| [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005) | `e4512349b2fb23f6a367675f6a0b43bfe936c109d3109773d304affc5a1dd0b3` |

For RULE-0002 the documentation-graph fragment proves that the record must
exist, while the entire canonical decision template is the exact required
shape. [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005)
remains a canonical semantic sibling and historical qualification owner; it
does not narrow or replace the template.

## Exact public API conventions

The API blocks below use signature notation. A semicolon denotes a future
concrete body unless `interface` is shown. Parameter names and nullability are
source API. All product assemblies are nullable-enabled.

- Every closed category in the token table, `CatalogIntegrityCode`, and the
  open `FindingCode`, `EvaluationFailureCode`, `FindingSeverity`, and
  `RemediationKey` families is a `public sealed class T : IEquatable<T>` with
  the exact `Value`/`Parse`/`TryParse` surface below. `TestScenarioId` is the
  same sealed reference shape and additionally implements
  `IComparable<TestScenarioId>`. `CatalogVersion` is the separately specified
  sealed reference shape with `IEquatable<CatalogVersion>` and
  `IComparable<CatalogVersion>`. None is a struct, enum, record, abstract base,
  interface, or publicly derivable type. Non-token identities instead expose
  only their shown factories and interfaces. No value family exposes a public
  constructor or conversion operator.
- Composite declarations and outputs are sealed, enumerate each input exactly
  once into defensive immutable snapshots, expose collections only as
  `IReadOnlyList<T>`, and have no public constructor, setter, deconstructor,
  serializer attribute, or mutable collection.
- Policy exports and evaluator inputs have no public constructor or factory.
  They are minted through the explicitly reviewed friend boundary and exact
  activated artifact only.
- Kernel output types have no public constructor or factory. Only the kernel
  mints them after catalog, intent, and reference validation.
- Message text, exception text, raw content snippets, credentials, provider
  DTOs, raw JSON, cursors, ETags, service providers, and localization values are
  absent from every public type.
- Exception category and `CatalogIntegrityCode` are observable. Exception
  message, parameter name, private layout, hash integer, cache implementation,
  and singleton reference identity are not compatibility or test oracles.

### Strong key and category grammar

`FindingCode`, `EvaluationFailureCode`, `FindingSeverity`, `RemediationKey`,
`CatalogVersion`, `TestScenarioId`, `ModelContractIdentity`,
`CapabilityContractIdentity`, `CatalogPredecessorBinding`, and
`ReviewedAuthorityPermalink` are distinct semantic value types. They use the
accepted namespaced token grammar where applicable from the
[SUBF-0153](README.md#subf-0153) [open-vocabulary contract](subf-0153-evidence-contract-design.md#open-vocabulary-and-semantic-owners).
They cannot convert to one another. Remaining declaration keys and versions
are grammar-validated ordinal strings owned by their exact parameter position;
this design does not claim a separate wrapper type where the signatures below
say `string`.
`TestScenarioId` accepts exactly `TEST-[0-9]{4}`. `CatalogVersion` is a positive
32-bit integer. Protocol versions use exact `M.m.rev` non-negative decimal
components without leading zeros except the single value `0`; each component
fits uint32 and comparison is the numeric `(M, m, rev)` tuple.

`IntroducedIn`, non-null `DeprecatedIn`, and non-null `RetiredIn` use that same
grammar. Value construction requires Introduced <= Deprecated <= Retired for
the fields that exist. Activation additionally requires Introduced <= the
enclosing ProtocolVersion and any Deprecated value <= it. The current rule
array contains active declarations only, so every activated current rule has
`RetiredIn == null`; a non-null value is rejected as a retained retired rule.
Retirement is represented only by a `Retired` transition: the predecessor rule
exists, the current rule is absent, and retirement becomes effective at the
current enclosing ProtocolVersion under its reviewed authority. A deprecated
but not retired current rule remains active and remains in named-profile/
baseline closure as declared.

The closed categories and canonical tokens are:

| Type | Values / tokens |
| --- | --- |
| `CatalogAuthorityKind` | `QualificationSlice` / `qualification-slice`; `CompleteProtocolSnapshot` / `complete-protocol-snapshot` |
| `AdmissionProofKind` | `Observed` / `observed`; `Failed` / `failed`; `NoInput` / `no-input` |
| `CacheRetentionPolicy` | `RetainLowestCanonicalKeys` / `retain-lowest-canonical-keys` |
| `IndexInvocationScope` | `PerContext` / `per-context`; `PerPlan` / `per-plan` |
| `CatalogPredecessorKind` | `Genesis` / `genesis`; `Existing` / `existing` |
| `RuleTransitionKind` | `Unchanged` / `unchanged`; `Added` / `added`; `Revised` / `revised`; `Retired` / `retired` |
| `ApplicabilityIntentKind` | `Applicable` / `applicable`; `NotApplicable` / `not-applicable`; `Unresolved` / `unresolved` |
| `QualifiedEvidenceReferenceKind` | `ContextProof` / `context-proof`; `Root` / `root`; `Derived` / `derived`; `ExpectedSelector` / `expected-selector` |
| `RepositoryEntryKind` | `Directory` / `directory`; `File` / `file`; `SymbolicLink` / `symbolic-link`; `GitLink` / `git-link` |
| `GovernedReferenceKind` | `CrossRecord` / `cross-record`; `EmbeddedRecord` / `embedded-record`; `Commit` / `commit` |
| `GovernedReferenceSyntax` | `Clickable` / `clickable`; `NonClickable` / `non-clickable`; `UnsupportedAuthoringForm` / `unsupported-authoring-form` |
| `GovernedReferenceResolution` | `Exact` / `exact`; `WrongTarget` / `wrong-target`; `Unresolved` / `unresolved`; `MissingFragment` / `missing-fragment`; `WrongFragment` / `wrong-fragment`; `WrongRepository` / `wrong-repository`; `WrongObject` / `wrong-object`; `ExternalEvidenceRequired` / `external-evidence-required` |

`FindingSeverity` remains a protocol-owned open token so later releases can add
reviewed semantics without a consumer enum fork. Every initial finding uses the
exact token `protocol.finding.error`. Syntactically valid unknown values are
structural only and fail catalog activation unless declared by the exact
protocol manifest.

`CatalogIntegrityCode` is instead closed in schema 1. Its exact named
properties/tokens are `ManifestInvalid` / `protocol.integrity.manifest-invalid`,
`ArtifactMismatch` / `protocol.integrity.artifact-mismatch`,
`ActivationProofInvalid` / `protocol.integrity.activation-proof-invalid`,
`CatalogIncomplete` / `protocol.integrity.catalog-incomplete`,
`RegistrationMismatch` / `protocol.integrity.registration-mismatch`,
`PlanStateInvalid` / `protocol.integrity.plan-state-invalid`,
`AdmissionProofInvalid` / `protocol.integrity.admission-proof-invalid`,
`ReferenceInvalid` / `protocol.integrity.reference-invalid`, `IntentInvalid` /
`protocol.integrity.intent-invalid`, and `CacheIdentityCollision` /
`protocol.integrity.cache-identity-collision`. Unknown values fail
`Parse`/`TryParse`.

`CatalogIntegrityException.Code` mapping and precedence are exact. Validation
stops at the first applicable row in this order:

| Code | Exact category |
| --- | --- |
| `ManifestInvalid` | A successfully parsed sealed-manifest identity/digest/projection conflicts with the predecessor-trusted release or qualification envelope, including an envelope-supplied self-digest or unknown manifest identity. Raw schema/field/order/grammar/union/duplicate/declaration/reference/mapping rejection is the Abstractions-owned `ParseCanonical` `FormatException` contract above. |
| `ArtifactMismatch` | A valid parsed artifact/component projection differs from the actual loaded artifact set, filename, length, digest, assembly/type binding, or loaded-artifact mapping. Document-local missing/extra/duplicate mapping is rejected earlier by `ParseCanonical`. |
| `ActivationProofInvalid` | Wrong activation contract/type/artifact/envelope/manifest; incomplete verified-artifact set; failed export/loaded-Assembly proof |
| `CatalogIncomplete` | After a successful document-local parse only: the parsed manifest conflicts with predecessor-trusted snapshot state, or the loaded executable export/registration partition is incomplete despite a document-internally closed declaration graph. Missing/extra/duplicate/retired rules, incomplete transition/profile/baseline/rule-to-schema closure, and cyclic/unreachable/ambiguous declared producer DAGs knowable from manifest bytes are earlier `ParseCanonical` `FormatException`. |
| `RegistrationMismatch` | Export family/projection or internal registration/type-token set differs from the accepted manifest partition; logical key maps to a wrong CLR generic type/instance |
| `PlanStateInvalid` | Invalid named/caller profile selection, target-selector cardinality, target/slot/instruction set, kernel/session stamp, phase transition, reuse, staleness, or cross-plan input |
| `AdmissionProofInvalid` | Missing/extra/duplicate/overlapping/foreign proof or instruction identity; SlotKey multiplicity outside the exact owner-sharded instruction bijection; wrong proof kind/type/artifact/receipt/request/resolved target/route; failed proof attestation |
| `ReferenceInvalid` | Foreign/unminted handle; invalid root/derivation/refinement/selector parent; reference kind violates its primary/related declaration role |
| `IntentInvalid` | Missing/extra/duplicate/unknown evaluator intent; undeclared finding/failure code; wrong rule/phase/status shape |
| `CacheIdentityCollision` | Equal cache identity/digest with unequal exact bytes or unequal structural context/root identity |

Ordinary null/format/range errors at caller-creatable value factories retain
their declared argument exception categories and are not recast as integrity
exceptions. Host cancellation and unexpected runtime failures also remain
outside this table.

## Exact cumulative ContractSlice export inventories

The following ordinal *delta* lists, not handwritten totals, are the normative
product export oracles for [TEST-0210](test-cases.md#test-0210). A slice's exact
assembly inventory is the ordinal union of its own delta and every earlier
delta. A public type enters once with its complete member/nullability/factory
surface; no later slice adds a public member to an earlier type.

### ContractSlice A - catalog, provenance, and manifest preflight

`MeAndAI.Protocol.Conformance.Abstractions` delta:

```text
AcquisitionDemandProjectorDeclaration
ActivationProofContractDeclaration
AdmissionProofContractDeclaration
AdmissionProofKind
ArtifactFileBinding
CacheRetentionPolicy
CapabilityContractIdentity
CatalogAuthorityKind
CatalogIntegrityCode
CatalogPredecessorBinding
CatalogPredecessorKind
CatalogSliceDeclaration
CatalogVersion
CompleteCatalogDeclaration
CompletePolicyPackExport
ComponentArtifactBinding
ComponentInputDeclaration
ComponentTypeIdentity
ContextIndexDeclaration
EvaluationFailureCode
EvidenceSlotDeclaration
ExpectedSelectorDeclaration
FinalizedPolicyManifest
FindingCode
FindingDeclaration
FindingSeverity
IAdmissionProofCandidate
IPolicyActivationProof
IndexInvocationScope
ModelContractIdentity
NamedProfileDeclaration
NormativeFragmentDeclaration
PayloadSchemaDeclaration
PolicyQualificationSliceExport
QualifiedEvidenceReferenceKind
ReleaseSchemaRegistry
RemediationKey
ReviewedAuthorityPermalink
RuleDeclaration
RuleTransitionDeclaration
RuleTransitionKind
SemanticModelParserDeclaration
SemanticResourceBudget
SessionCacheBudget
TestScenarioId
```

`MeAndAI.Protocol.Conformance` delta:

```text
CatalogIntegrityException
CompleteCatalogSnapshot
NamedExecutionProfile
```

ContractSlice A validates canonical manifest bytes, digest and typed
projection, declaration/reference closure, artifact/component mapping,
catalog/provenance, predecessor/transition shape, and the negative public/friend
surface. It constructs no executable policy export, calls no
`IPolicyActivationProof.Proves(...)` overload, validates no internal export
registration list, and declares or exports no kernel. First executable export
activation and the complete `CatalogSliceKernel` public API begin together in
ContractSlice C.

### ContractSlice B - admission and sealed capabilities

`MeAndAI.Protocol.Conformance.Abstractions` delta:

```text
GovernedReferenceKind
GovernedReferenceResolution
GovernedReferenceSyntax
GovernedReferenceView
IEvidenceCapability
IFailedAttemptProof
IGovernedReferenceIndex
INoInputRoutingProof
IObservedQualificationProof
IProtocolRecordIndex
IRepositoryTargetResolutionIndex
IRepositoryTree
ProtocolRecordMemberView
ProtocolRecordView
QualifiedEvidenceHandle
RepositoryEntryKind
RepositoryEntryView
RepositoryTargetResolutionDemandItem
RepositoryTargetResolutionView
```

`MeAndAI.Protocol.Conformance` delta:

```text
AcquisitionProofSet
QualifiedEvidenceDerivation
QualifiedEvidenceReference
QualifiedEvidenceSelector
SealedEvaluationContext
```

### ContractSlice C - applicability, evaluation, and aggregation

`MeAndAI.Protocol.Conformance.Abstractions` delta:

```text
ApplicabilityIntent
ApplicabilityIntentKind
EvaluationFailureIntent
EvaluationIntent
FindingIntent
IRuleEvaluator
RuleApplicabilityInput
RuleEvaluationInput
```

`MeAndAI.Protocol.Conformance` delta:

```text
AcquisitionInstruction
ApplicabilityClosure
ApplicabilityPlan
CatalogSliceEvaluation
CatalogSliceKernel
CompleteCatalogEvaluation
ConformanceKernel
EvaluationAdvanceResult
EvaluationClosure
EvaluationPlan
RuleEvaluation
RuleEvaluationFailure
RuleFinding
SealedAcquisitionAttempt
SealedAcquisitionOutcome
```

### ContractSlice D - first compiled common rules

`MeAndAI.Protocol.Policy` delta:

```text
InitialRuleQualificationPolicy
```

The list-derived cumulative type totals are 48 after A, 72 after B, 95 after
C, and 96 after D. The final per-assembly totals are 72 Abstractions, 23
Conformance, and one Policy export. These counts are review aids; the lists are
authority.

`MeAndAI.Protocol.Domain` gains zero exports. The future
`MeAndAI.Protocol.Conformance.Tests` assembly has no supported product API and
is never referenced or shipped. Public xUnit test classes, if required by its
runner, are test artifacts and are excluded from product export authority.

Any supported-export change before Gate 2 acceptance must update this list,
the detailed signatures, [TEST-0210](test-cases.md#test-0210), project graph,
feature record, findings, and project-memory handoff together.

## Exact declaration, input, and intent surface

The complete supported **public** member inventory is expressed by these
signatures and the shared conventions above. No supported inventory below
lists a public instance constructor; every non-static class therefore declares
an explicit non-public instance constructor in source. The sole static class,
`InitialRuleQualificationPolicy`, has no instance constructor. An omitted
constructor in these public inventory snippets never means the C# implicit
public parameterless constructor. Conformance-owned outputs use same-assembly
private/internal construction. Every carrier that must cross an assembly
boundary has its exact internal friend factory shown below; implementation may
not invent another cross-assembly mint seam.

```csharp
public sealed class SemanticResourceBudget
{
    public long MaxBytes { get; }
    public int MaxDepth { get; }
    public long MaxNodes { get; }
    public long MaxComplexity { get; }
    public static SemanticResourceBudget Create(
        long maxBytes,
        int maxDepth,
        long maxNodes,
        long maxComplexity);
}

public sealed class SessionCacheBudget
{
    public int MaxDecodeEntries { get; }
    public long MaxDecodeCanonicalBytes { get; }
    public int MaxIndexEntries { get; }
    public long MaxIndexNodes { get; }
    public int MaxConcurrentDecodeAttempts { get; }
    public int MaxConcurrentIndexAttempts { get; }
    public CacheRetentionPolicy RetentionPolicy { get; }
    public static SessionCacheBudget Create(
        int maxDecodeEntries,
        long maxDecodeCanonicalBytes,
        int maxIndexEntries,
        long maxIndexNodes,
        int maxConcurrentDecodeAttempts,
        int maxConcurrentIndexAttempts,
        CacheRetentionPolicy retentionPolicy);
}

public sealed class ModelContractIdentity : IEquatable<ModelContractIdentity>
{
    public string ModelKey { get; }
    public string ModelVersion { get; }
    public ComponentTypeIdentity ImplementationType { get; }
    public static ModelContractIdentity Create(
        string modelKey,
        string modelVersion,
        ComponentTypeIdentity implementationType);
    public bool Equals(ModelContractIdentity? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class CapabilityContractIdentity :
    IEquatable<CapabilityContractIdentity>
{
    public string CapabilityKey { get; }
    public string CapabilityVersion { get; }
    public ComponentTypeIdentity InterfaceType { get; }
    public static CapabilityContractIdentity Create(
        string capabilityKey,
        string capabilityVersion,
        ComponentTypeIdentity interfaceType);
    public bool Equals(CapabilityContractIdentity? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class ComponentTypeIdentity
{
    public string ComponentKey { get; }
    public string ComponentVersion { get; }
    public string AssemblyName { get; }
    public string TypeName { get; }
    public static ComponentTypeIdentity Create(
        string componentKey,
        string componentVersion,
        string assemblyName,
        string typeName);
}

public sealed class ArtifactFileBinding
{
    public string FileName { get; }
    public long ByteLength { get; }
    public ExactSha256Digest ArtifactDigest { get; }
    public static ArtifactFileBinding Create(
        string fileName,
        long byteLength,
        ExactSha256Digest artifactDigest);
}

public sealed class ComponentArtifactBinding
{
    public ComponentTypeIdentity Component { get; }
    public string ArtifactFileName { get; }
    public static ComponentArtifactBinding Create(
        ComponentTypeIdentity component,
        string artifactFileName);
}

public sealed class ComponentInputDeclaration
{
    public ModelContractIdentity? Model { get; }
    public CapabilityContractIdentity? Capability { get; }
    public int MinimumCount { get; }
    public int? MaximumCount { get; }
    public static ComponentInputDeclaration ForModel(
        ModelContractIdentity model,
        int minimumCount,
        int? maximumCount);
    public static ComponentInputDeclaration ForCapability(
        CapabilityContractIdentity capability,
        int minimumCount,
        int? maximumCount);
}

public sealed class ActivationProofContractDeclaration
{
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ComponentTypeIdentity ProofComponent { get; }
    public static ActivationProofContractDeclaration Create(
        string contractKey,
        string contractVersion,
        ComponentTypeIdentity proofComponent);
}

public sealed class AdmissionProofContractDeclaration
{
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public AdmissionProofKind Kind { get; }
    public ComponentTypeIdentity ProofComponent { get; }
    public SurfaceSet Surfaces { get; }
    public IReadOnlyList<string> MaterialRoles { get; }
    public static AdmissionProofContractDeclaration Create(
        string contractKey,
        string contractVersion,
        AdmissionProofKind kind,
        ComponentTypeIdentity proofComponent,
        SurfaceSet surfaces,
        IEnumerable<string> materialRoles);
}

public interface IPolicyActivationProof
{
    string ContractKey { get; }
    string ContractVersion { get; }
    ExactSha256Digest ManifestDigest { get; }
    IReadOnlyList<ArtifactFileBinding> VerifiedArtifacts { get; }
    bool Proves(PolicyQualificationSliceExport policy);
    bool Proves(CompletePolicyPackExport policy);
    bool Proves(IAdmissionProofCandidate candidate);
}

// The three Proves overloads are attestations by the exact manifest-declared
// proof component; callers cannot supply an alternate proof type.

public sealed class NormativeFragmentDeclaration
{
    public string Path { get; }
    public string ContainingBlob { get; }
    public string Anchor { get; }
    public int StartLine { get; }
    public int EndLine { get; }
    public string CanonicalizationSchema { get; }
    public long CanonicalByteLength { get; }
    public ExactSha256Digest FragmentDigest { get; }
    public static NormativeFragmentDeclaration Create(
        string path,
        string containingBlob,
        string anchor,
        int startLine,
        int endLine,
        string canonicalizationSchema,
        long canonicalByteLength,
        ExactSha256Digest fragmentDigest);
}

public sealed class EvidenceSlotDeclaration
{
    public string SlotKey { get; }
    public EvidenceRequirement Requirement { get; }
    public SurfaceSet ProfileSurfaces { get; }
    public string MaterialRole { get; }
    public string TargetSelectorKey { get; }
    public IReadOnlyList<CapabilityContractIdentity> Capabilities { get; }
    public static EvidenceSlotDeclaration Create(
        string slotKey,
        EvidenceRequirement requirement,
        SurfaceSet profileSurfaces,
        string materialRole,
        string targetSelectorKey,
        IEnumerable<CapabilityContractIdentity> capabilities);
}

public sealed class ExpectedSelectorDeclaration
{
    public string SelectorKey { get; }
    public string SlotKey { get; }
    public string SelectorSchemaKey { get; }
    public ComponentTypeIdentity Resolver { get; }
    public IReadOnlyList<QualifiedEvidenceReferenceKind> AllowedParentKinds { get; }
    public IReadOnlyList<FindingCode> AllowedFindingCodes { get; }
    public static ExpectedSelectorDeclaration Create(
        string selectorKey,
        string slotKey,
        string selectorSchemaKey,
        ComponentTypeIdentity resolver,
        IEnumerable<QualifiedEvidenceReferenceKind> allowedParentKinds,
        IEnumerable<FindingCode> allowedFindingCodes);
}

public sealed class FindingDeclaration
{
    public FindingCode Code { get; }
    public FindingSeverity Severity { get; }
    public RemediationKey Remediation { get; }
    public IReadOnlyList<QualifiedEvidenceReferenceKind> AllowedPrimaryReferenceKinds { get; }
    public IReadOnlyList<QualifiedEvidenceReferenceKind> AllowedRelatedReferenceKinds { get; }
    public static FindingDeclaration Create(
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        IEnumerable<QualifiedEvidenceReferenceKind> allowedPrimaryReferenceKinds,
        IEnumerable<QualifiedEvidenceReferenceKind> allowedRelatedReferenceKinds);
}

public sealed class PayloadSchemaDeclaration
{
    public string SchemaKey { get; }
    public string SchemaVersion { get; }
    public ComponentTypeIdentity Codec { get; }
    public ModelContractIdentity OutputModel { get; }
    public int MaxBindingsPerInstruction { get; }
    public long MaxRetainedCanonicalBytesPerInstruction { get; }
    public SemanticResourceBudget Budget { get; }
    public IReadOnlyList<string> CodecFailureCodes { get; }
    public static PayloadSchemaDeclaration Create(
        string schemaKey,
        string schemaVersion,
        ComponentTypeIdentity codec,
        ModelContractIdentity outputModel,
        int maxBindingsPerInstruction,
        long maxRetainedCanonicalBytesPerInstruction,
        SemanticResourceBudget budget,
        IEnumerable<string> codecFailureCodes);
}

public sealed class SemanticModelParserDeclaration
{
    public string ParserKey { get; }
    public string ParserVersion { get; }
    public ComponentTypeIdentity Parser { get; }
    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }
    public ModelContractIdentity OutputModel { get; }
    public SemanticResourceBudget Budget { get; }
    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }
    public static SemanticModelParserDeclaration Create(
        string parserKey,
        string parserVersion,
        ComponentTypeIdentity parser,
        IEnumerable<ComponentInputDeclaration> inputs,
        ModelContractIdentity outputModel,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes);
}

public sealed class ContextIndexDeclaration
{
    public string IndexKey { get; }
    public string IndexVersion { get; }
    public ComponentTypeIdentity Indexer { get; }
    public IndexInvocationScope InvocationScope { get; }
    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }
    public CapabilityContractIdentity OutputCapability { get; }
    public SemanticResourceBudget Budget { get; }
    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }
    public static ContextIndexDeclaration Create(
        string indexKey,
        string indexVersion,
        ComponentTypeIdentity indexer,
        IndexInvocationScope invocationScope,
        IEnumerable<ComponentInputDeclaration> inputs,
        CapabilityContractIdentity outputCapability,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes);
}

public sealed class AcquisitionDemandProjectorDeclaration
{
    public string ProjectorKey { get; }
    public string ProjectorVersion { get; }
    public ComponentTypeIdentity Projector { get; }
    public CapabilityContractIdentity InputCapability { get; }
    public IReadOnlyList<string> InputSlotKeys { get; }
    public string OutputSlotKey { get; }
    public string DemandSchemaKey { get; }
    public string DemandSchemaVersion { get; }
    public SemanticResourceBudget Budget { get; }
    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }
    public static AcquisitionDemandProjectorDeclaration Create(
        string projectorKey,
        string projectorVersion,
        ComponentTypeIdentity projector,
        CapabilityContractIdentity inputCapability,
        IEnumerable<string> inputSlotKeys,
        string outputSlotKey,
        string demandSchemaKey,
        string demandSchemaVersion,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes);
}

public sealed class ReleaseSchemaRegistry
{
    public IReadOnlyList<PayloadSchemaDeclaration> PayloadSchemas { get; }
    public IReadOnlyList<SemanticModelParserDeclaration> Parsers { get; }
    public IReadOnlyList<ContextIndexDeclaration> Indexes { get; }
    public IReadOnlyList<AcquisitionDemandProjectorDeclaration>
        DemandProjectors { get; }
    public IReadOnlyList<AdmissionProofContractDeclaration> AdmissionProofContracts { get; }
    public SessionCacheBudget CacheBudget { get; }
    public static ReleaseSchemaRegistry Create(
        IEnumerable<PayloadSchemaDeclaration> payloadSchemas,
        IEnumerable<SemanticModelParserDeclaration> parsers,
        IEnumerable<ContextIndexDeclaration> indexes,
        IEnumerable<AcquisitionDemandProjectorDeclaration> demandProjectors,
        IEnumerable<AdmissionProofContractDeclaration> admissionProofContracts,
        SessionCacheBudget cacheBudget);
    public bool TryGetPayloadSchema(
        string schemaKey,
        string schemaVersion,
        [NotNullWhen(true)] out PayloadSchemaDeclaration? declaration);
    public bool TryGetParser(
        string parserKey,
        string parserVersion,
        [NotNullWhen(true)] out SemanticModelParserDeclaration? declaration);
    public bool TryGetIndex(
        string indexKey,
        string indexVersion,
        [NotNullWhen(true)] out ContextIndexDeclaration? declaration);
    public bool TryGetDemandProjector(
        string projectorKey,
        string projectorVersion,
        [NotNullWhen(true)] out AcquisitionDemandProjectorDeclaration? declaration);
    public bool TryGetAdmissionProofContract(
        string contractKey,
        string contractVersion,
        AdmissionProofKind kind,
        [NotNullWhen(true)] out AdmissionProofContractDeclaration? declaration);
}

public sealed class RuleDeclaration
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public CatalogVersion CatalogVersion { get; }
    public ExactSha256Digest NormativeDigest { get; }
    public IReadOnlyList<NormativeFragmentDeclaration> NormativeFragments { get; }
    public IReadOnlyList<TestScenarioId> QualificationScenarios { get; }
    public ComponentTypeIdentity Evaluator { get; }
    public IReadOnlyList<EvidenceSlotDeclaration> ApplicabilitySlots { get; }
    public IReadOnlyList<EvidenceSlotDeclaration> EvaluationSlots { get; }
    public IReadOnlyList<ExpectedSelectorDeclaration> ExpectedSelectors { get; }
    public IReadOnlyList<SubjectRole> SubjectRoles { get; }
    public SurfaceSet Surfaces { get; }
    public IReadOnlyList<SnapshotKind> SnapshotKinds { get; }
    public IReadOnlyList<ProtocolOperation> Operations { get; }
    public IReadOnlyList<FindingDeclaration> Findings { get; }
    public IReadOnlyList<EvaluationFailureCode> EvaluationFailureCodes { get; }
    public string IntroducedIn { get; }
    public string? DeprecatedIn { get; }
    public string? RetiredIn { get; }
    public IReadOnlyList<string> CompatibilityAliases { get; }
    public static RuleDeclaration Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        CatalogVersion catalogVersion,
        ExactSha256Digest normativeDigest,
        IEnumerable<NormativeFragmentDeclaration> normativeFragments,
        IEnumerable<TestScenarioId> qualificationScenarios,
        ComponentTypeIdentity evaluator,
        IEnumerable<EvidenceSlotDeclaration> applicabilitySlots,
        IEnumerable<EvidenceSlotDeclaration> evaluationSlots,
        IEnumerable<ExpectedSelectorDeclaration> expectedSelectors,
        IEnumerable<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IEnumerable<SnapshotKind> snapshotKinds,
        IEnumerable<ProtocolOperation> operations,
        IEnumerable<FindingDeclaration> findings,
        IEnumerable<EvaluationFailureCode> evaluationFailureCodes,
        string introducedIn,
        string? deprecatedIn,
        string? retiredIn,
        IEnumerable<string> compatibilityAliases);
}

public sealed class NamedProfileDeclaration
{
    public string Name { get; }
    public ExecutionProfile Axes { get; }
    public IReadOnlyList<RuleId> RuleIds { get; }
    public static NamedProfileDeclaration Create(
        string name,
        ExecutionProfile axes,
        IEnumerable<RuleId> ruleIds);
}

public sealed class ReviewedAuthorityPermalink :
    IEquatable<ReviewedAuthorityPermalink>
{
    public string Value { get; }
    public static ReviewedAuthorityPermalink Create(string value);
    public bool Equals(ReviewedAuthorityPermalink? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class CatalogPredecessorBinding :
    IEquatable<CatalogPredecessorBinding>
{
    public CatalogPredecessorKind Kind { get; }
    public CatalogVersion? CatalogVersion { get; }
    public ExactSha256Digest? ManifestDigest { get; }
    public ExactSha256Digest? CompleteInventoryDigest { get; }
    public static CatalogPredecessorBinding Genesis();
    public static CatalogPredecessorBinding Existing(
        CatalogVersion catalogVersion,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest completeInventoryDigest);
    public bool Equals(CatalogPredecessorBinding? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed class RuleTransitionDeclaration
{
    public RuleId RuleId { get; }
    public RuleTransitionKind Kind { get; }
    public RuleRevision? PreviousRevision { get; }
    public RuleRevision? CurrentRevision { get; }
    public ReviewedAuthorityPermalink? ReviewedAuthority { get; }
    public static RuleTransitionDeclaration Unchanged(
        RuleId ruleId,
        RuleRevision revision,
        ReviewedAuthorityPermalink? reviewedAuthority);
    public static RuleTransitionDeclaration Added(
        RuleId ruleId,
        RuleRevision currentRevision,
        ReviewedAuthorityPermalink reviewedAuthority);
    public static RuleTransitionDeclaration Revised(
        RuleId ruleId,
        RuleRevision previousRevision,
        RuleRevision currentRevision,
        ReviewedAuthorityPermalink reviewedAuthority);
    public static RuleTransitionDeclaration Retired(
        RuleId ruleId,
        RuleRevision previousRevision,
        ReviewedAuthorityPermalink reviewedAuthority);
}

public sealed class CatalogSliceDeclaration
{
    public string SliceKey { get; }
    public string SliceVersion { get; }
    public string ProtocolVersion { get; }
    public CatalogVersion CatalogVersion { get; }
    public IReadOnlyList<RuleDeclaration> Rules { get; }
    public static CatalogSliceDeclaration Create(
        string sliceKey,
        string sliceVersion,
        string protocolVersion,
        CatalogVersion catalogVersion,
        IEnumerable<RuleDeclaration> rules);
}

public sealed class CompleteCatalogDeclaration
{
    public string ProtocolVersion { get; }
    public CatalogVersion CatalogVersion { get; }
    public CatalogPredecessorBinding Predecessor { get; }
    public ExactSha256Digest CompleteInventoryDigest { get; }
    public string BaselineProfileName { get; }
    public IReadOnlyList<RuleDeclaration> Rules { get; }
    public IReadOnlyList<RuleTransitionDeclaration> Transitions { get; }
    public IReadOnlyList<NamedProfileDeclaration> NamedProfiles { get; }
    public static CompleteCatalogDeclaration Create(
        string protocolVersion,
        CatalogVersion catalogVersion,
        CatalogPredecessorBinding predecessor,
        string baselineProfileName,
        IEnumerable<RuleDeclaration> rules,
        IEnumerable<RuleTransitionDeclaration> transitions,
        IEnumerable<NamedProfileDeclaration> namedProfiles);
}

public sealed class FinalizedPolicyManifest
{
    public CatalogAuthorityKind AuthorityKind { get; }
    public string SourceCommit { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ReleaseSchemaRegistry SchemaRegistry { get; }
    public ActivationProofContractDeclaration ActivationProofContract { get; }
    public IReadOnlyList<ArtifactFileBinding> ArtifactFiles { get; }
    public IReadOnlyList<ComponentArtifactBinding> Components { get; }
    public CatalogSliceDeclaration? Slice { get; }
    public CompleteCatalogDeclaration? CompleteCatalog { get; }
    internal static FinalizedPolicyManifest ParseCanonical(
        ReadOnlyMemory<byte> canonicalBytes);
}

public sealed class PolicyQualificationSliceExport
{
    public string ExportKey { get; }
    public string ExportVersion { get; }
    public CatalogSliceDeclaration Catalog { get; }
    public ReleaseSchemaRegistry SchemaRegistry { get; }
    public IReadOnlyList<ComponentTypeIdentity> Components { get; }
    internal IReadOnlyList<ICodecRegistration> CodecRegistrations { get; }
    internal IReadOnlyList<IParserRegistration> ParserRegistrations { get; }
    internal IReadOnlyList<IIndexRegistration> IndexRegistrations { get; }
    internal IReadOnlyList<IDemandProjectorRegistration>
        DemandProjectorRegistrations { get; }
    internal IReadOnlyList<ISelectorRegistration> SelectorRegistrations { get; }
    internal IReadOnlyList<RuleEvaluatorRegistration> EvaluatorRegistrations { get; }
    internal static PolicyQualificationSliceExport Create(
        string exportKey,
        string exportVersion,
        CatalogSliceDeclaration catalog,
        ReleaseSchemaRegistry schemaRegistry,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IEnumerable<IParserRegistration> parserRegistrations,
        IEnumerable<IIndexRegistration> indexRegistrations,
        IEnumerable<IDemandProjectorRegistration> demandProjectorRegistrations,
        IEnumerable<ISelectorRegistration> selectorRegistrations,
        IEnumerable<RuleEvaluatorRegistration> evaluatorRegistrations);
}

public sealed class CompletePolicyPackExport
{
    public string ExportKey { get; }
    public string ExportVersion { get; }
    public CompleteCatalogDeclaration Catalog { get; }
    public ReleaseSchemaRegistry SchemaRegistry { get; }
    public IReadOnlyList<ComponentTypeIdentity> Components { get; }
    internal IReadOnlyList<ICodecRegistration> CodecRegistrations { get; }
    internal IReadOnlyList<IParserRegistration> ParserRegistrations { get; }
    internal IReadOnlyList<IIndexRegistration> IndexRegistrations { get; }
    internal IReadOnlyList<IDemandProjectorRegistration>
        DemandProjectorRegistrations { get; }
    internal IReadOnlyList<ISelectorRegistration> SelectorRegistrations { get; }
    internal IReadOnlyList<RuleEvaluatorRegistration> EvaluatorRegistrations { get; }
    internal static CompletePolicyPackExport Create(
        string exportKey,
        string exportVersion,
        CompleteCatalogDeclaration catalog,
        ReleaseSchemaRegistry schemaRegistry,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IEnumerable<IParserRegistration> parserRegistrations,
        IEnumerable<IIndexRegistration> indexRegistrations,
        IEnumerable<IDemandProjectorRegistration> demandProjectorRegistrations,
        IEnumerable<ISelectorRegistration> selectorRegistrations,
        IEnumerable<RuleEvaluatorRegistration> evaluatorRegistrations);
}

public static class InitialRuleQualificationPolicy
{
    public static PolicyQualificationSliceExport Export { get; }
}
```

Every `ReleaseSchemaRegistry.TryGet*` validates its required key/version
arguments with the corresponding declaration grammar. `null` throws
`ArgumentNullException`; empty, whitespace-padded, malformed, wrong-case, or
otherwise noncanonical text throws `ArgumentException`; over-maximum-length
text throws `ArgumentOutOfRangeException`. A well-formed but absent identity
returns `false` with `declaration = null`; an exact present identity returns
`true` with a non-null declaration. These methods never trim, normalize, or
case-fold.

The activation-proof overload semantics are closed; returning `true` means all
conditions in the matching row hold and returning `true` for only a subset is
`ActivationProofInvalid`, except for the explicitly narrower C synthetic-
qualification negative-fixture branch defined below, which is rejected outside
that exact friend envelope:

| Overload | Exact attestation bound by the proof's private verified envelope |
| --- | --- |
| `Proves(PolicyQualificationSliceExport)` | The exact export object reference, its actual loaded Policy `Assembly` object, its six internal registration lists, and its public projection came from the manifest-mapped Policy artifact bytes and equal the accepted qualification-slice manifest partition. This overload makes no completeness claim. |
| `Proves(CompletePolicyPackExport)` | Every qualification-export condition plus exact complete-export family; genesis/existing predecessor authority; predecessor manifest/inventory binding; all Added/Revised/Retired immutable reviewed-authority objects; every Unchanged executable/artifact delta's same-evidence differential qualification; and the exact current manifest/source-commit release envelope are one manifest-digest-bound claim. |
| `Proves(IAdmissionProofCandidate)` | The exact candidate object reference and actual loaded proof-component `Assembly` object were created by the manifest-declared proof component/artifact, and its receipt/request/instruction binding belongs to this same manifest envelope. It does not make evidence semantically valid; Conformance independently reframes and validates every field. |

Every overload returns `false` for a null/foreign object, another loaded
assembly instance, another manifest/export/candidate instance, an unverified
or extra artifact, a missing private claim, an authority permalink whose
provider object immutability was not verified, or any byte/projection mismatch.
The kernel independently recomputes all structural, predecessor, transition,
registration, and receipt predicates; `true` cannot waive a failed predicate.

ContractSlice A does not invoke any `Proves` overload. Its
`ParseCanonical`-only behavior validates the canonical manifest projection and
declaration/artifact graph without constructing or attesting an executable
export. ContractSlice C is the first slice that can invoke complete-export
attestation against the final six-list registration shape; ContractSlice D is
the first slice that can invoke qualification-export attestation against the
real Policy artifact. B's private codec-mirror proof remains a distinct
non-export harness contract.

[TEST-0210](test-cases.md#test-0210) has exactly three non-production public-export activation variants in
addition to B's private codec-only proof:

- ContractSlice C's synthetic-qualification manifest has `QualificationSlice`
  authority and reuses the object-identical Tests-owned six-family registration
  objects, logical declarations, component identities, schema graph, budgets,
  artifacts, and immutable fixture source used by C's synthetic-complete
  variant. Its `PolicyQualificationSliceExport` contains no real Policy type or
  artifact and cannot produce a complete evaluation or verdict. A private
  friend-only branch of `Proves(PolicyQualificationSliceExport)` attests the
  exact candidate object, Tests assembly/artifact origin, fixture stamp, and
  presented registration objects independently of their equality to the
  manifest. That deliberately narrow test branch lets `CatalogSliceKernel`
  classify missing/extra/duplicate/foreign/wrong-generic registration and
  public-projection drift as `RegistrationMismatch`; the kernel, not the proof,
  performs that comparison. It is rejected for every production envelope and
  cannot satisfy D's real-Policy qualification-mirror semantics. The final
  internal export factory preserves the presented six-list order and
  multiplicity for this friend fixture; only the kernel owns manifest
  bijection validation and `RegistrationMismatch` classification.
- ContractSlice C's synthetic-complete manifest has
  `CompleteProtocolSnapshot` authority. Its 27 registration/type-contract rows
  preserve the production logical keys, versions, declarations, DAG, budgets,
  failure codes, and ordinal family partition, but replace every Policy CLR
  type/artifact binding with an exact Tests synthetic type in
  `MeAndAI.Protocol.Conformance.Tests.dll`. The activation and three admission
  proof rows are Tests-owned too. Its artifact set is exactly five files: four
  retained production runtime artifacts (`Domain`,
  `Conformance.Abstractions`, `Conformance`, and `Markdig`) plus
  `Conformance.Tests`; neither `Policy` nor `Application` is
  present. Every artifact remains mapped. The fixture binds a canonical
  test-owned source commit and immutable normative fixture blobs plus either a
  `Genesis` predecessor or an exact earlier synthetic manifest/inventory pair.
  A friend-only branch of `Proves(CompletePolicyPackExport)` attests that exact
  object/assembly/fixture envelope. It can exercise transition and verdict
  truth tables, but it cannot satisfy the production source-commit, artifact,
  predecessor-authority, or release-envelope branch of that overload.
- ContractSlice D's qualification mirror has `QualificationSlice` authority
  and names the exact Tests proof artifact. For that envelope only,
  `Proves(PolicyQualificationSliceExport)` may attest a Tests-factory-created
  mirror when its export key/version, catalog, non-proof schema registry fields,
  27 component identities, and each of the six registration objects/order are
  exact-equal to the real `InitialRuleQualificationPolicy.Export`; registration
  instances are the same objects. The activation and three admission proof
  components are the only substitutions. The proof binds the real Policy
  artifact that supplied those registrations and the Tests artifact that
  supplied the mirror/proofs. It cannot satisfy complete-export proof
  semantics.

All three branches require the exact friend assembly identity and private fixture
stamp and are rejected under a production envelope. No public origin flag,
factory, registration seam, or authority token is added.

The two nullable manifest properties are an exclusive closed union: exactly one
is non-null and must match `AuthorityKind`. Internal
`MeAndAI.Protocol.Application` ([FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)) and
`MeAndAI.Protocol.Conformance.Tests` ([TEST-0210](test-cases.md#test-0210)) friend factories obtain manifests only through
`ParseCanonical` and compare its sealed digest/projections, declarations, and
artifact order with their private envelope state; they do not trust caller
projections and cannot access or revalidate discarded raw bytes.

The two policy exports expose only safe logical identity publicly. Their exact
codec/model/parser/index/evaluator/selector-resolver
registrations are internal friend members inspected by `Conformance` during
activation. Neither has a public constructor or factory. The real policy
assembly provides no complete export in this slice.

Every closed category in the token table, plus `CatalogIntegrityCode`, exposes
exactly its named static properties plus the following source surface,
substituting its exact concrete type for `T`. The open `FindingCode`, `EvaluationFailureCode`,
`FindingSeverity`, and `RemediationKey` types expose the same surface without
named statics; syntactically valid unknown values remain structural until a
manifest declares them. `TestScenarioId` uses the same surface plus
`IComparable<TestScenarioId>` and `CompareTo(TestScenarioId? other)`.

```csharp
public string Value { get; }
public static T Parse(string value);
public static bool TryParse(
    string? value,
    [NotNullWhen(true)] out T? result);
public bool Equals(T? other);
public override bool Equals(object? obj);
public override int GetHashCode();
public override string ToString();
```

`Parse(null)` throws `ArgumentNullException`; malformed, unknown closed,
wrong-case, padded, or non-canonical input throws `FormatException`.
`TryParse` never throws for caller input and returns `false` with `result=null`
for those inputs. Factories and parsers never trim, case-fold, or normalize.

`CatalogVersion` alone has `int Value`, `Create(int value)`,
`IComparable<CatalogVersion>`, `CompareTo(CatalogVersion? other)`, the exact
equality/hash/`ToString` members above, and no `Parse`/`TryParse`.
`ModelContractIdentity` and `CapabilityContractIdentity` expose only their
shown `Create` factories and equality members; `ReviewedAuthorityPermalink`
exposes only its shown `Create` factory and equality members. None inherits the
token-family parse surface.

Shared validation and value semantics are exact. All textual validation,
equality, hash input, and textual ordering are ordinal and ASCII-exact. Inputs
are never trimmed, case-folded, Unicode-normalized, or accepted through aliases.
A required reference or enumerable that is `null` throws
`ArgumentNullException`. In caller-creatable `Create` and variant factories, an
empty or whitespace-only required string, a grammar-invalid/noncanonical
string, a null enumerable element, a duplicate semantic key/value, an invalid
union variant, or a cross-field/foreign-membership conflict throws
`ArgumentException`; an empty enumerable throws `ArgumentException` only where
that type's exact contract requires one or more elements. A non-positive value
where positivity is required, a negative count, an invalid numeric or temporal
range, or an over-maximum-length value throws `ArgumentOutOfRangeException`.
Checked arithmetic overflow remains `OverflowException`. Optional nullable
members accept `null` only where their exact signature and variant contract
permit it. Exception category is observable; message, `ParamName`, and
validation implementation/order are not oracles unless a type-specific rule
explicitly says otherwise.

Every declared `Parse(string value)` throws `ArgumentNullException` for `null`
and `FormatException` for empty, whitespace-padded, malformed, unknown-closed,
wrong-case, over-length, or otherwise noncanonical text. Its paired `TryParse`
never throws for caller text, returns `false` with `result = null` for every
such invalid input, and returns `true` with a non-null value exactly when
`Parse` succeeds. `CatalogVersion.Create(0)` and negative values throw
`ArgumentOutOfRangeException`.

Every `IEquatable<T>` implementation uses all and only the type's public
semantic state: ordinal strings, exact bytes/digests, numeric values,
nullable-state presence, nested semantic equality, and collection elements in
their exposed canonical order. `Equals(null)` and equality with another union
leaf/runtime type are false. `GetHashCode()` uses the same state and ordinal
comparers; its integer result is not stable evidence. A text value's
`ToString()` returns exact `Value`. Only types explicitly declaring
`IComparable<T>` expose public comparison: textual values use ordinal
comparison, `CatalogVersion` uses numeric `Value` comparison, and
`CompareTo(null)` returns `1`. `CatalogVersion.ToString()` returns invariant
ASCII base-10 `Value` with no sign or leading zero.

Artifact files are unique and ordered by `FileName`; component bindings are
unique and ordered by component key/version, and physical assembly/type
identity is also unique. FileName is a basename with no separator and
ByteLength is positive. Every component maps to exactly one existing artifact
file, every file is referenced, and many components may share one file. Equal
digests under distinct filenames do not collapse file identity.

Each applicability list and evaluation list rejects duplicate SlotKey values.
The same SlotKey may appear once in both lists only when the two
`EvidenceSlotDeclaration` values are structurally equal; the kernel then
coalesces it to one acquisition and one admission. This is the exact shared-
phase representation. Expected selector keys are unique per rule, reference a
slot in that rule's union, and may name only finding codes declared by that
rule.

Every `RuleDeclaration.CatalogVersion` equals its enclosing slice or complete
catalog version exactly. The complete catalog's Rules list remains the global
current active inventory across every operation/axis. For each authoritative
named profile, however, `RuleIds` must equal exactly the full subset of that
inventory satisfying the same static planning predicate: the rule declares the
profile's SubjectRole, Operation, and SnapshotKind, and the profile Surfaces
intersect the rule Surfaces. Missing a compatible rule or adding an
incompatible one is document-local `ParseCanonical` `FormatException`; no named profile that can mint a
`CompleteCatalogEvaluation`/verdict may narrow this closure. The designated
baseline is one default named profile and obeys the same exact compatible-set
rule; it is not falsely required to contain rules for incompatible Adoption,
Update, Publication, Finalization, or Recovery axes.

`ReviewedAuthorityPermalink.Create` accepts an absolute HTTPS, userinfo-free,
query-free immutable-object permalink and preserves the exact ordinal string.
Its fragment is either absent or one renderer-active stable object fragment
such as an issue-comment/review-comment anchor; arbitrary/local fragments fail.
The predecessor-trusted release proof additionally validates provider/object
immutability. `CatalogPredecessorBinding.Genesis` has all three
nullable fields null; `Existing` has all three non-null.
`ModelContractIdentity.ToString()` is exactly
`<ModelKey>@<ModelVersion>|<ImplementationType.ComponentKey>@<ImplementationType.ComponentVersion>`;
`CapabilityContractIdentity.ToString()` is exactly
`<CapabilityKey>@<CapabilityVersion>|<InterfaceType.ComponentKey>@<InterfaceType.ComponentVersion>`;
`ReviewedAuthorityPermalink.ToString()` is exactly `Value`.
`CatalogPredecessorBinding.ToString()` is `genesis` for Genesis and otherwise
`existing:<CatalogVersion.Value>:<ManifestDigest>:<CompleteInventoryDigest>`,
using the accepted lowercase digest text. The separators cannot occur in the
component token/version grammars used in those positions.

The heterogeneous executable seam is internal and exact. The future
`InternalsVisibleTo` matrix is the following complete allowlist; an omitted
cell means no grant and no product assembly may add another friend:

| Granting assembly | Exact friend assembly simple names |
| --- | --- |
| `MeAndAI.Protocol.Domain` | none |
| `MeAndAI.Protocol.Conformance.Abstractions` | `MeAndAI.Protocol.Policy`; `MeAndAI.Protocol.Conformance`; `MeAndAI.Protocol.Application`; `MeAndAI.Protocol.Conformance.Tests` |
| `MeAndAI.Protocol.Conformance` | `MeAndAI.Protocol.Application`; `MeAndAI.Protocol.Conformance.Tests` |
| `MeAndAI.Protocol.Policy` | none |
| `MeAndAI.Protocol.Application` | none |

There is no wildcard, consumer, provider-adapter, host, dynamic-proxy, or
alternate-test friend. ContractSlice Gate 3 adds a grant only when both its
granting and receiving projects actually exist in that authorized slice; the
`Application` entries are added atomically only when that separately
authorized project first exists. Abstractions owns the generic typed
registration/factory seam. Conformance separately exposes its plan-bound
evidence writer/qualification session only to Application and Tests; Policy receives no
Conformance-internal access. The simple-name matrix is itself a [TEST-0210](test-cases.md#test-0210)
negative authority oracle. Its normative contracts are:

Every non-static internal factory-created class in the following seam declares
an explicit private instance constructor unless an exact inheritance
constructor is shown. To keep the contract signatures readable, ordinary sealed
class constructor declarations are suppressed in these snippets but are
mandatory in source and in [TEST-0210](test-cases.md#test-0210)'s constructor/reflection oracle; abstract
union constructors remain shown because their inheritance accessibility is
semantic. No implicit internal/public parameterless constructor exists. Its own
static factory or private nested union leaf is the only source-level
construction path; Conformance's live stamp/registration validation is
additional authority validation rather than a substitute for constructor
closure.

```csharp
internal interface IProtocolSemanticModel { }
internal interface IComponentInput { }

internal sealed class SemanticResourceUsage
{
    internal long Bytes { get; }
    internal int MaxDepth { get; }
    internal long Nodes { get; }
    internal long Complexity { get; }
    internal static SemanticResourceUsage Create(
        long bytes,
        int maxDepth,
        long nodes,
        long complexity);
    internal bool Fits(SemanticResourceBudget budget);
}

internal sealed class SemanticResourceLocalUsage
{
    internal long GeneratedBytes { get; }
    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal long AdditionalComplexity { get; }
    internal static SemanticResourceLocalUsage Create(
        long generatedBytes,
        int layerDepth,
        long layerNodes,
        long additionalComplexity);
}

internal sealed class SemanticResourceAllowance
{
    internal SemanticResourceBudget AggregateBudget { get; }
    internal SemanticResourceUsage SelectedBaseline { get; }
    internal static SemanticResourceAllowance Create(
        SemanticResourceBudget aggregateBudget,
        SemanticResourceUsage selectedBaseline);
    internal bool FitsLocal(SemanticResourceLocalUsage localUsage);
}

internal sealed class SemanticResourceContribution
{
    internal int KindRank { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> Roots { get; }
    internal string? PayloadSchemaKey { get; }
    internal string? PayloadSchemaVersion { get; }
    internal ComponentTypeIdentity? Component { get; }
    internal ExactSha256Digest? InvocationDigest { get; }
    internal SemanticResourceUsage Usage { get; }
    internal static SemanticResourceContribution Payload(
        QualifiedEvidenceHandle root,
        string payloadSchemaKey,
        string payloadSchemaVersion,
        SemanticResourceUsage usage);
    internal static SemanticResourceContribution GeneratedBytes(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage);
    internal static SemanticResourceContribution Layer(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage);
    internal static SemanticResourceContribution ComplexityTerm(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage);
}

internal sealed class SemanticResourceLedger
{
    internal IReadOnlyList<SemanticResourceContribution> Contributions { get; }
    internal SemanticResourceUsage Usage { get; }
    internal static SemanticResourceLedger Create(
        IEnumerable<SemanticResourceContribution> contributions);
}

internal sealed class ModelTypeToken<TModel>
    where TModel : class, IProtocolSemanticModel
{
    internal ModelContractIdentity Contract { get; }
    internal static ModelTypeToken<TModel> Create(
        ModelContractIdentity contract);
}

internal sealed class CapabilityTypeToken<TCapability>
    where TCapability : class, IEvidenceCapability
{
    internal CapabilityContractIdentity Contract { get; }
    internal static CapabilityTypeToken<TCapability> Create(
        CapabilityContractIdentity contract);
}

internal interface ICodecModelHandle
{
    ModelContractIdentity Contract { get; }
    EvidenceBinding Binding { get; }
    ComponentTypeIdentity Producer { get; }
    ExactSha256Digest InstructionDigest { get; }
    ExactSha256Digest DemandDigest { get; }
    IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    TResult Accept<TResult>(ICodecModelHandleVisitor<TResult> visitor);
}

internal interface ICodecModelHandleVisitor<TResult>
{
    TResult Visit<TModel>(CodecModelHandle<TModel> handle)
        where TModel : class, IProtocolSemanticModel;
}

internal sealed class CodecModelHandle<TModel> : ICodecModelHandle
    where TModel : class, IProtocolSemanticModel
{
    public ModelContractIdentity Contract { get; }
    public EvidenceBinding Binding { get; }
    public ComponentTypeIdentity Producer { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest DemandDigest { get; }
    public IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal ModelTypeToken<TModel> ModelType { get; }
    internal TModel Value { get; }
    public SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    internal static CodecModelHandle<TModel> Create(
        ModelTypeToken<TModel> modelType,
        EvidenceBinding binding,
        ComponentTypeIdentity producer,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        TModel value,
        SemanticResourceLocalUsage claimedLocalUsage);
    public TResult Accept<TResult>(
        ICodecModelHandleVisitor<TResult> visitor);
}

internal interface IObservedQualificationProofState
{
    IReadOnlyList<ICodecModelHandle> QualifiedModels { get; }
}

internal interface ISealedModelHandle
{
    ModelContractIdentity Contract { get; }
    QualifiedEvidenceHandle Evidence { get; }
    SemanticResourceUsage Usage { get; }
    SemanticResourceLedger Ledger { get; }
}

internal sealed class SealedModelHandle<TModel> : ISealedModelHandle
    where TModel : class, IProtocolSemanticModel
{
    public ModelContractIdentity Contract { get; }
    public QualifiedEvidenceHandle Evidence { get; }
    public SemanticResourceUsage Usage { get; }
    public SemanticResourceLedger Ledger { get; }
    internal ModelTypeToken<TModel> ModelType { get; }
    internal TModel Value { get; }
    internal static SealedModelHandle<TModel> Create(
        ModelTypeToken<TModel> modelType,
        QualifiedEvidenceHandle evidence,
        TModel value,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger);
}

internal interface ICapabilityHandle
{
    CapabilityContractIdentity Contract { get; }
    IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    SemanticResourceUsage Usage { get; }
    SemanticResourceLedger Ledger { get; }
}

internal sealed class CapabilityHandle<TCapability> : ICapabilityHandle
    where TCapability : class, IEvidenceCapability
{
    public CapabilityContractIdentity Contract { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    public SemanticResourceUsage Usage { get; }
    public SemanticResourceLedger Ledger { get; }
    internal CapabilityTypeToken<TCapability> CapabilityType { get; }
    internal TCapability Value { get; }
    internal static CapabilityHandle<TCapability> Create(
        CapabilityTypeToken<TCapability> capabilityType,
        TCapability value,
        IEnumerable<QualifiedEvidenceHandle> evidence,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger);
}

internal interface IExpectedReferenceLookup
{
    QualifiedEvidenceHandle Require(
        string selectorKey,
        QualifiedEvidenceHandle parent);
}

internal interface IRuleInputAccess
{
    TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;
    QualifiedEvidenceHandle GetContextProof(string slotKey);
    QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
}

internal sealed class TypedInputReader
{
    internal static TypedInputReader Create(
        IEnumerable<ISealedModelHandle> models,
        IEnumerable<ICapabilityHandle> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        IEnumerable<DemandReferenceAuthorityBinding> demandBindings);
    internal SealedModelHandle<TModel> RequireModel<TModel>(
        ModelTypeToken<TModel> expected)
        where TModel : class, IProtocolSemanticModel;
    internal IReadOnlyList<SealedModelHandle<TModel>> RequireModels<TModel>(
        ModelTypeToken<TModel> expected)
        where TModel : class, IProtocolSemanticModel;
    internal CapabilityHandle<TCapability> RequireCapability<TCapability>(
        CapabilityTypeToken<TCapability> expected)
        where TCapability : class, IEvidenceCapability;
    internal IReadOnlyList<CapabilityHandle<TCapability>>
        RequireCapabilities<TCapability>(
            CapabilityTypeToken<TCapability> expected)
        where TCapability : class, IEvidenceCapability;
    internal QualifiedEvidenceHandle RequireContextProof(string slotKey);
    internal QualifiedEvidenceHandle RequireExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parent);
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> RequireDemandItems();
    internal DemandReferenceAuthorityBinding RequireDemandBinding(int itemId);
}

internal sealed class DemandReferenceAuthorityBinding
{
    internal int ItemId { get; }
    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle SourceAuthority { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? CapturedManifestRepositoryRelativePath { get; }
    internal string? CapturedManifestContentIdentity { get; }
    internal static DemandReferenceAuthorityBinding Create(
        int itemId,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity);
}

internal sealed class SlotCapabilityBinding
{
    internal string SlotKey { get; }
    internal ICapabilityHandle Capability { get; }
    internal static SlotCapabilityBinding Create(
        string slotKey,
        ICapabilityHandle capability);
}

internal sealed class RuleInputAccess : IRuleInputAccess
{
    internal static RuleInputAccess Create(
        IEnumerable<SlotCapabilityBinding> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences);
    TCapability IRuleInputAccess.GetCapability<TCapability>(string slotKey);
    QualifiedEvidenceHandle IRuleInputAccess.GetContextProof(string slotKey);
    QualifiedEvidenceHandle IRuleInputAccess.GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
}

internal interface IComponentInputBinder<TInput>
    where TInput : class, IComponentInput
{
    IReadOnlyList<ComponentInputDeclaration> Inputs { get; }
    TInput Bind(TypedInputReader reader);
}

internal interface IQualifiedEvidenceDerivationFactory
{
    QualifiedEvidenceHandle Derive(
        QualifiedEvidenceHandle parent,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location);
}

internal sealed class RepositoryTreePayloadEntry
{
    internal string RepositoryRelativePath { get; }
    internal RepositoryEntryKind Kind { get; }
    internal static RepositoryTreePayloadEntry Create(
        string repositoryRelativePath,
        RepositoryEntryKind kind);
}

internal sealed class RepositoryTargetResolutionContent
{
    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string NormalizedRepositoryRelativePath { get; }
    internal string ObservedContentIdentity { get; }
    internal ReadOnlyMemory<byte> Bytes { get; }
    internal static RepositoryTargetResolutionContent CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string normalizedRepositoryRelativePath,
        string observedBlobObjectId,
        ReadOnlyMemory<byte> bytes);
    internal static RepositoryTargetResolutionContent CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string observedContentIdentity,
        ReadOnlyMemory<byte> bytes);
}

internal abstract class RepositoryTargetResolutionPayloadRow
{
    private RepositoryTargetResolutionPayloadRow();
    internal RepositoryTargetResolutionDemandItem DemandItem { get; }
    internal static RepositoryTargetResolutionPayloadRow MissingCommit(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetResolutionPayloadRow PresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity);
    internal static RepositoryTargetResolutionPayloadRow PresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity);
    internal static RepositoryTargetResolutionPayloadRow PresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedObjectType,
        string observedObjectIdentity,
        string observedRepositoryRelativePath,
        string observedPathObjectType,
        string observedPathObjectIdentity,
        RepositoryTargetResolutionContent? content);
    internal static RepositoryTargetResolutionPayloadRow MissingTag(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetResolutionPayloadRow PresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedRefName,
        string observedRefObjectType,
        string observedRefObjectIdentity,
        string observedPeeledObjectType,
        string observedPeeledObjectIdentity);
    internal static RepositoryTargetResolutionPayloadRow MissingCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetResolutionPayloadRow PresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwningRepositoryIdentity,
        string observedCapturedSnapshotIdentity,
        string observedRepositoryRelativePath,
        string observedEntryKind,
        string observedContentIdentity,
        RepositoryTargetResolutionContent content);
    internal abstract TResult Accept<TResult>(
        IRepositoryTargetResolutionPayloadRowVisitor<TResult> visitor);
}

internal interface IRepositoryTargetResolutionPayloadRowVisitor<TResult>
{
    TResult VisitMissingCommit(RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity);
    TResult VisitPresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity);
    TResult VisitPresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity,
        string observedPath, string observedPathType,
        string observedPathIdentity,
        RepositoryTargetResolutionContent? content);
    TResult VisitMissingTag(RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedRefName,
        string observedRefType, string observedRefIdentity,
        string observedPeeledType, string observedPeeledIdentity);
    TResult VisitMissingCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem);
    TResult VisitPresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedCapture, string observedPath,
        string observedEntryKind, string observedContentIdentity,
        RepositoryTargetResolutionContent content);
}

internal abstract class CanonicalPayloadWriteSource
{
    private CanonicalPayloadWriteSource();
    internal EvidenceScope Scope { get; }
    internal EvidenceLocation Location { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal static CanonicalPayloadWriteSourceIntent RepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTreePayloadEntry> entries);
    internal static CanonicalPayloadWriteSourceIntent GovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ReadOnlyMemory<byte> body);
    internal static CanonicalPayloadWriteSourceIntent RepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents);
    internal abstract TResult Accept<TResult>(
        ICanonicalPayloadWriteSourceVisitor<TResult> visitor);
}

internal abstract class CanonicalPayloadWriteSourceIntent
{
    private CanonicalPayloadWriteSourceIntent();
    internal static CanonicalPayloadWriteSourceIntent Created(
        CanonicalPayloadWriteSource source);
    internal static CanonicalPayloadWriteSourceIntent Rejected(
        string schemaKey,
        string schemaVersion,
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        string codecFailureCode);
    internal abstract TResult Accept<TResult>(
        ICanonicalPayloadWriteSourceIntentVisitor<TResult> visitor);
}

internal interface ICanonicalPayloadWriteSourceIntentVisitor<TResult>
{
    TResult VisitCreated(CanonicalPayloadWriteSource source);
    TResult VisitRejected(
        string schemaKey,
        string schemaVersion,
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        string codecFailureCode);
}

internal interface ICanonicalPayloadWriteSourceVisitor<TResult>
{
    TResult VisitRepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTreePayloadEntry> entries);
    TResult VisitGovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ReadOnlyMemory<byte> body);
    TResult VisitRepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents);
}

internal sealed class CanonicalPayloadWriteInput
{
    internal EvidenceSlotDeclaration Slot { get; }
    internal AcquisitionTarget Target { get; }
    internal CanonicalPayloadWriteSource Source { get; }
    internal SemanticResourceBudget Budget { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal static CanonicalPayloadWriteInput Create(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        CanonicalPayloadWriteSource source,
        SemanticResourceBudget budget,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems);
}

internal sealed class CanonicalPayloadWriteProduct
{
    internal CanonicalEvidencePayload Payload { get; }
    internal static CanonicalPayloadWriteProduct Create(
        CanonicalEvidencePayload payload);
}

internal abstract class CanonicalPayloadWriteIntent
{
    private CanonicalPayloadWriteIntent();
    internal static CanonicalPayloadWriteIntent Written(
        CanonicalPayloadWriteProduct product);
    internal static CanonicalPayloadWriteIntent Rejected(
        IEnumerable<AcquisitionFailure> failures);
    internal abstract TResult Accept<TResult>(
        ICanonicalPayloadWriteIntentVisitor<TResult> visitor);
}

internal interface ICanonicalPayloadWriteIntentVisitor<TResult>
{
    TResult VisitWritten(CanonicalPayloadWriteProduct product);
    TResult VisitRejected(IReadOnlyList<AcquisitionFailure> failures);
}

internal interface ISemanticResourceMeter<TInput, TValue>
{
    SemanticResourceLocalUsage MeasureLocal(
        TInput input,
        TValue value,
        CancellationToken cancellationToken);
}

internal sealed class CodecQualificationInput
{
    internal EvidenceBinding Binding { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal static CodecQualificationInput Create(
        EvidenceBinding binding,
        SemanticResourceAllowance resourceAllowance,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems);
}

internal interface ICanonicalPayloadCodec<TModel> :
    ISemanticResourceMeter<CodecQualificationInput, TModel>
    where TModel : class, IProtocolSemanticModel
{
    CanonicalPayloadWriteIntent Write(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken);
    CodecQualificationIntent<TModel> Qualify(
        CodecQualificationInput input,
        CancellationToken cancellationToken);
}

internal abstract class CodecQualificationIntent<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private CodecQualificationIntent();
    internal static CodecQualificationIntent<TModel> Qualified(
        CodecModelHandle<TModel> model);
    internal static CodecQualificationIntent<TModel> Rejected(
        IEnumerable<AcquisitionFailure> failures);
    internal abstract TResult Accept<TResult>(
        ICodecQualificationIntentVisitor<TModel, TResult> visitor);
}

internal interface ICodecQualificationIntentVisitor<TModel, TResult>
    where TModel : class, IProtocolSemanticModel
{
    TResult VisitQualified(CodecModelHandle<TModel> model);
    TResult VisitRejected(IReadOnlyList<AcquisitionFailure> failures);
}

internal sealed class SemanticModelInput<TInput>
    where TInput : class, IComponentInput
{
    internal TInput Value { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal static SemanticModelInput<TInput> Create(
        TInput value,
        SemanticResourceAllowance resourceAllowance);
}

internal interface ISemanticModelParser<TInput, TOutput> :
    ISemanticResourceMeter<SemanticModelInput<TInput>, TOutput>
    where TInput : class, IComponentInput
    where TOutput : class, IProtocolSemanticModel
{
    SemanticModelIntent<TOutput> Parse(
        SemanticModelInput<TInput> input,
        CancellationToken cancellationToken);
}

internal sealed class ContextIndexInput<TInput>
    where TInput : class, IComponentInput
{
    internal TInput Value { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal IQualifiedEvidenceDerivationFactory Derivations { get; }
    internal static ContextIndexInput<TInput> Create(
        TInput value,
        SemanticResourceAllowance resourceAllowance,
        IQualifiedEvidenceDerivationFactory derivations);
}

internal interface IContextIndexer<TInput, TCapability> :
    ISemanticResourceMeter<ContextIndexInput<TInput>, TCapability>
    where TInput : class, IComponentInput
    where TCapability : class, IEvidenceCapability
{
    CapabilityIntent<TCapability> Build(
        ContextIndexInput<TInput> input,
        CancellationToken cancellationToken);
}

internal sealed class ExpectedSelectorInput
{
    internal ExpectedSelectorDeclaration Declaration { get; }
    internal QualifiedEvidenceHandle Parent { get; }
    internal string ParentCanonicalValue { get; }
    internal static ExpectedSelectorInput Create(
        ExpectedSelectorDeclaration declaration,
        QualifiedEvidenceHandle parent,
        string parentCanonicalValue);
}

internal interface IExpectedSelectorResolver
{
    SelectorIntent Resolve(ExpectedSelectorInput input);
}

internal sealed class SemanticFailureIntent
{
    internal EvaluationFailureCode Code { get; }
    internal QualifiedEvidenceHandle PrimaryReference { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }
    internal static SemanticFailureIntent Create(
        EvaluationFailureCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences);
}

internal sealed class SemanticModelProduct<TModel>
    where TModel : class, IProtocolSemanticModel
{
    internal TModel Value { get; }
    internal QualifiedEvidenceHandle Parent { get; }
    internal string TypedNodeKind { get; }
    internal string TypedNodeIdentity { get; }
    internal EvidenceLocation Location { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    internal static SemanticModelProduct<TModel> Create(
        TModel value,
        QualifiedEvidenceHandle parent,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location,
        SemanticResourceLocalUsage claimedLocalUsage);
}

internal abstract class SemanticModelIntent<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private SemanticModelIntent();
    internal static SemanticModelIntent<TModel> Produced(
        SemanticModelProduct<TModel> product);
    internal static SemanticModelIntent<TModel> Failed(
        SemanticFailureIntent failure);
    internal abstract TResult Accept<TResult>(
        ISemanticModelIntentVisitor<TModel, TResult> visitor);
}

internal interface ISemanticModelIntentVisitor<TModel, TResult>
    where TModel : class, IProtocolSemanticModel
{
    TResult VisitProduced(SemanticModelProduct<TModel> product);
    TResult VisitFailed(SemanticFailureIntent failure);
}

internal sealed class CapabilityProduct<TCapability>
    where TCapability : class, IEvidenceCapability
{
    internal TCapability Value { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    internal static CapabilityProduct<TCapability> Create(
        TCapability value,
        IEnumerable<QualifiedEvidenceHandle> evidence,
        SemanticResourceLocalUsage claimedLocalUsage);
}

internal abstract class CapabilityIntent<TCapability>
    where TCapability : class, IEvidenceCapability
{
    private CapabilityIntent();
    internal static CapabilityIntent<TCapability> Produced(
        CapabilityProduct<TCapability> product);
    internal static CapabilityIntent<TCapability> Failed(
        SemanticFailureIntent failure);
    internal abstract TResult Accept<TResult>(
        ICapabilityIntentVisitor<TCapability, TResult> visitor);
}

internal interface ICapabilityIntentVisitor<TCapability, TResult>
    where TCapability : class, IEvidenceCapability
{
    TResult VisitProduced(CapabilityProduct<TCapability> product);
    TResult VisitFailed(SemanticFailureIntent failure);
}

internal sealed class SelectorProduct
{
    internal QualifiedEvidenceHandle Parent { get; }
    internal string CanonicalValue { get; }
    internal static SelectorProduct Create(
        QualifiedEvidenceHandle parent,
        string canonicalValue);
}

internal abstract class SelectorIntent
{
    private SelectorIntent();
    internal static SelectorIntent Resolved(SelectorProduct product);
    internal static SelectorIntent Invalid(CatalogIntegrityCode code);
    internal abstract TResult Accept<TResult>(
        ISelectorIntentVisitor<TResult> visitor);
}

internal interface ISelectorIntentVisitor<TResult>
{
    TResult VisitResolved(SelectorProduct product);
    TResult VisitInvalid(CatalogIntegrityCode code);
}

internal sealed class SourceReferenceResolutionAuthority
{
    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle AuthorityProof { get; }
    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? NormalizedTagName { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? CapturedManifestRepositoryRelativePath { get; }
    internal string? CapturedManifestContentIdentity { get; }
    internal static SourceReferenceResolutionAuthority Create(
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle authorityProof,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity);
}

internal sealed class DemandProjectionInput<TCapability>
    where TCapability : class, IEvidenceCapability
{
    internal EvidenceSlotDeclaration OutputSlot { get; }
    internal AcquisitionTarget Target { get; }
    internal IReadOnlyList<TCapability> Inputs { get; }
    internal IReadOnlyList<int> SourceReferenceDerivationDepths { get; }
    internal IReadOnlyList<SourceReferenceResolutionAuthority>
        SourceReferenceAuthorities { get; }
    internal IReadOnlyList<int> SourceAuthorityDerivationDepths { get; }
    internal SemanticResourceAllowance ResourceAllowance { get; }
    internal static DemandProjectionInput<TCapability> Create(
        EvidenceSlotDeclaration outputSlot,
        AcquisitionTarget target,
        IEnumerable<TCapability> inputs,
        IEnumerable<int> sourceReferenceDerivationDepths,
        IEnumerable<SourceReferenceResolutionAuthority> sourceReferenceAuthorities,
        IEnumerable<int> sourceAuthorityDerivationDepths,
        SemanticResourceAllowance resourceAllowance);
}

internal sealed class RepositoryTargetResolutionDemandCandidate
{
    internal string OwningRepositoryIdentity { get; }
    internal string? CommitObjectId { get; }
    internal string? NormalizedTagName { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? NormalizedRepositoryRelativePath { get; }
    internal string? NormalizedFragment { get; }
    internal string? ExpectedCapturedContentIdentity { get; }
    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle SourceAuthority { get; }
    internal static RepositoryTargetResolutionDemandCandidate CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    internal static RepositoryTargetResolutionDemandCandidate TagRoot(
        string owningRepositoryIdentity,
        string normalizedTagName,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    internal static RepositoryTargetResolutionDemandCandidate CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string normalizedFragment,
        string expectedCapturedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    internal TResult Accept<TResult>(
        IRepositoryTargetResolutionDemandCandidateVisitor<TResult> visitor);
}

internal interface IRepositoryTargetResolutionDemandCandidateVisitor<TResult>
{
    TResult VisitCommitObject(
        string owner, string commit, string? path, string? fragment,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    TResult VisitTagRoot(
        string owner, string tag,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
    TResult VisitCapturedSnapshotPath(
        string owner, string capture, string path, string fragment,
        string expectedContentIdentity,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority);
}

internal sealed class DemandProjectionProduct
{
    internal IReadOnlyList<RepositoryTargetResolutionDemandCandidate> Candidates { get; }
    internal SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    internal static DemandProjectionProduct Create(
        IEnumerable<RepositoryTargetResolutionDemandCandidate> candidates,
        SemanticResourceLocalUsage claimedLocalUsage);
}

internal abstract class DemandProjectionIntent
{
    private DemandProjectionIntent();
    internal static DemandProjectionIntent Projected(
        DemandProjectionProduct product);
    internal static DemandProjectionIntent Failed(
        SemanticFailureIntent failure);
    internal abstract TResult Accept<TResult>(
        IDemandProjectionIntentVisitor<TResult> visitor);
}

internal interface IDemandProjectionIntentVisitor<TResult>
{
    TResult VisitProjected(DemandProjectionProduct product);
    TResult VisitFailed(SemanticFailureIntent failure);
}

internal interface IAcquisitionDemandProjector<TCapability> :
    ISemanticResourceMeter<
        DemandProjectionInput<TCapability>,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>
    where TCapability : class, IEvidenceCapability
{
    DemandProjectionIntent Project(
        DemandProjectionInput<TCapability> input,
        CancellationToken cancellationToken);
}
```

Every abstract intent union above has exactly two private nested sealed leaves;
callers cannot derive, construct, or create a nullable multi-property union.
Their exact CLR names are `QualifiedCase`/`RejectedCase` for codec
qualification, `ProducedCase`/`FailedCase` for both semantic-model and
capability intents, `ResolvedCase`/`InvalidCase` for selector intent, and
`ProjectedCase`/`FailedCase` for demand projection. Static factory method names
remain the semantic variant names without `Case`.
`IObservedQualificationProofState` is implemented only by the exact
Application-owned observed proof in a production envelope or by the exact
manifest-declared Conformance.Tests observed proof in the qualification-mirror
envelope. No other implementation or stamp is accepted. Conformance validates that proof and
uses the generic handle visitor to seal the typed models without rerunning the
codec. `TypedInputReader` resolves only an exact contract and checked matching
generic handle. A wrong logical/CLR pair is `RegistrationMismatch`.

Cross-assembly construction ownership is exact. Application maps routed
provider responses into the three closed provider-neutral
`CanonicalPayloadWriteSource` leaves and calls the plan-bound Conformance
evidence session. Conformance validates the live instruction/source relation,
creates `CanonicalPayloadWriteInput`, and dispatches `Write` through the same
manifest-bound Policy codec that later qualifies the resulting payload.
Application constructs the Domain binding/context around that returned payload
but never frames canonical bytes. It then calls the same session's qualification
operation and creates the observed proof state from the returned handles.
Conformance creates `CodecQualificationInput`, and the Policy codec creates
`CodecModelHandle<TModel>`. Conformance alone registers a newly constructed
`QualifiedEvidenceHandle` in its private session map and creates
`SealedModelHandle<TModel>`, `CapabilityHandle<TCapability>`,
`TypedInputReader`, `SemanticModelInput<TInput>`, `ContextIndexInput<TInput>`,
`ExpectedSelectorInput`, and the two public evaluator inputs. Policy creates
canonical payload write products, semantic/capability/selector products, and
failure intents through their shown factories. Policy also creates its immutable
provider-neutral view values and registrations. An internal friend can technically call an internal factory,
but that grants no authority: a handle/input/product not registered under the
current Conformance session and exact invocation stamp is rejected. Every
factory materializes enumerable arguments once, rejects null members,
canonicalizes or verifies the declared order, and enforces the local structural
and non-negative counter shape it can observe. Positive budgets, measured
claimed-local equality, within-budget aggregate success, and ledger authority are enforced
only by the Conformance invocation boundary that owns the live stamp.

`CanonicalPayloadWriteSource` has exactly three private nested sealed CLR
leaves, `RepositoryTreeCase`, `GovernedTextCase`, and
`RepositoryTargetResolutionCase`. `CanonicalPayloadWriteSourceIntent` has exactly two,
`CreatedCase` and `RejectedCase`; `CanonicalPayloadWriteIntent` has exactly two,
`WrittenCase` and `RejectedCase`; the `Case` suffix deliberately avoids a C#
declaration-name collision with its static variant factories.

Source construction is bounded before copying. Repository-tree accepts an
`IReadOnlyList` with at most 200,000 entries and at most 16,777,216 aggregate
strict-UTF-8 path bytes; governed-text accepts `ReadOnlyMemory<byte>` with at
most 4,194,304 bytes; repository-target resolution accepts at most 50,000 rows,
64 referenced unique content objects, 16,777,216 aggregate strict-UTF-8 bytes
across row text fields, 1,048,576 bytes per content, 16,777,216 aggregate unique
content bytes, and 33,554,432 combined retained metadata/content bytes. Count
is checked before indexing, checked arithmetic stops at the
first over-limit element, and no unbounded `IEnumerable` is retained or
enumerated. Null/invalid members reject before retention. A ceiling breach
returns SourceIntent Rejected retaining the exact schema key/version, the
already structurally valid scope/location, and the caller-visible instruction/
demand digests together with
`protocol.codec.resource-limit-exceeded`; schema-invalid rows use that schema's
declared invalid-* code. Every Created source retains those same two digests.
Application obtains them from the issued `AcquisitionInstruction`; the B harness
obtains them from its private-stamped write ticket. The plan-bound service
compares both digests byte-for-byte before any Policy call, preventing cross-
schema/kind/scope/location/instruction/shard replay. A Created source copies its
bounded memory/lists once; shared fragment rows retain one canonical content
object and its bytes are copied only once.
The paired writer then applies the manifest budget, including headers, framing,
scope, and location, so these hard ceilings never raise authority. A larger
absolute ceiling requires a new write-source/schema version rather than a
runtime setting.

The
governed-text body is exact BOM-free strict UTF-8 bytes; the repository entry
and repository-target result/content carriers contain only the normalized
fields shown. No source or
writer input contains a provider DTO, raw JSON, route, credential, I/O handle,
clock, or caller-selected digest. The public `CanonicalEvidencePayload.Create`
factory remains an untrusted structural carrier factory; an authoritative
protocol-schema payload used by Application must be the exact object returned
by this writer session.

The heterogeneous registration surface is also exact:

```csharp
internal interface ICodecRegistration
{
    PayloadSchemaDeclaration Declaration { get; }
    TResult Accept<TResult>(ICodecRegistrationVisitor<TResult> visitor);
}

internal interface ICodecRegistrationVisitor<TResult>
{
    TResult Visit<TModel>(CodecRegistration<TModel> registration)
        where TModel : class, IProtocolSemanticModel;
}

internal sealed class CodecRegistration<TModel> : ICodecRegistration
    where TModel : class, IProtocolSemanticModel
{
    public PayloadSchemaDeclaration Declaration { get; }
    internal ModelTypeToken<TModel> OutputModel { get; }
    internal ICanonicalPayloadCodec<TModel> Codec { get; }
    internal static CodecRegistration<TModel> Create(
        PayloadSchemaDeclaration declaration,
        ModelTypeToken<TModel> outputModel,
        ICanonicalPayloadCodec<TModel> codec);
    public TResult Accept<TResult>(
        ICodecRegistrationVisitor<TResult> visitor);
}

internal interface IParserRegistration
{
    SemanticModelParserDeclaration Declaration { get; }
    TResult Accept<TResult>(IParserRegistrationVisitor<TResult> visitor);
}

internal interface IParserRegistrationVisitor<TResult>
{
    TResult Visit<TInput, TOutput>(
        ParserRegistration<TInput, TOutput> registration)
        where TInput : class, IComponentInput
        where TOutput : class, IProtocolSemanticModel;
}

internal sealed class ParserRegistration<TInput, TOutput> :
    IParserRegistration
    where TInput : class, IComponentInput
    where TOutput : class, IProtocolSemanticModel
{
    public SemanticModelParserDeclaration Declaration { get; }
    internal IComponentInputBinder<TInput> Binder { get; }
    internal ModelTypeToken<TOutput> OutputModel { get; }
    internal ISemanticModelParser<TInput, TOutput> Parser { get; }
    internal static ParserRegistration<TInput, TOutput> Create(
        SemanticModelParserDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        ModelTypeToken<TOutput> outputModel,
        ISemanticModelParser<TInput, TOutput> parser);
    public TResult Accept<TResult>(
        IParserRegistrationVisitor<TResult> visitor);
}

internal interface IIndexRegistration
{
    ContextIndexDeclaration Declaration { get; }
    TResult Accept<TResult>(IIndexRegistrationVisitor<TResult> visitor);
}

internal interface IIndexRegistrationVisitor<TResult>
{
    TResult Visit<TInput, TCapability>(
        IndexRegistration<TInput, TCapability> registration)
        where TInput : class, IComponentInput
        where TCapability : class, IEvidenceCapability;
}

internal sealed class IndexRegistration<TInput, TCapability> :
    IIndexRegistration
    where TInput : class, IComponentInput
    where TCapability : class, IEvidenceCapability
{
    public ContextIndexDeclaration Declaration { get; }
    internal IComponentInputBinder<TInput> Binder { get; }
    internal CapabilityTypeToken<TCapability> OutputCapability { get; }
    internal IContextIndexer<TInput, TCapability> Indexer { get; }
    internal static IndexRegistration<TInput, TCapability> Create(
        ContextIndexDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        CapabilityTypeToken<TCapability> outputCapability,
        IContextIndexer<TInput, TCapability> indexer);
    public TResult Accept<TResult>(
        IIndexRegistrationVisitor<TResult> visitor);
}

internal interface IDemandProjectorRegistration
{
    AcquisitionDemandProjectorDeclaration Declaration { get; }
    TResult Accept<TResult>(
        IDemandProjectorRegistrationVisitor<TResult> visitor);
}

internal interface IDemandProjectorRegistrationVisitor<TResult>
{
    TResult Visit<TCapability>(
        DemandProjectorRegistration<TCapability> registration)
        where TCapability : class, IEvidenceCapability;
}

internal sealed class DemandProjectorRegistration<TCapability> :
    IDemandProjectorRegistration
    where TCapability : class, IEvidenceCapability
{
    public AcquisitionDemandProjectorDeclaration Declaration { get; }
    internal CapabilityTypeToken<TCapability> InputCapability { get; }
    internal IAcquisitionDemandProjector<TCapability> Projector { get; }
    internal static DemandProjectorRegistration<TCapability> Create(
        AcquisitionDemandProjectorDeclaration declaration,
        CapabilityTypeToken<TCapability> inputCapability,
        IAcquisitionDemandProjector<TCapability> projector);
    public TResult Accept<TResult>(
        IDemandProjectorRegistrationVisitor<TResult> visitor);
}

internal interface ISelectorRegistration
{
    ComponentTypeIdentity Component { get; }
    string SelectorSchemaKey { get; }
    TResult Accept<TResult>(ISelectorRegistrationVisitor<TResult> visitor);
}

internal interface ISelectorRegistrationVisitor<TResult>
{
    TResult Visit<TResolver>(SelectorRegistration<TResolver> registration)
        where TResolver : class, IExpectedSelectorResolver;
}

internal sealed class SelectorRegistration<TResolver> :
    ISelectorRegistration
    where TResolver : class, IExpectedSelectorResolver
{
    public ComponentTypeIdentity Component { get; }
    public string SelectorSchemaKey { get; }
    internal TResolver Resolver { get; }
    internal static SelectorRegistration<TResolver> Create(
        ComponentTypeIdentity component,
        string selectorSchemaKey,
        TResolver resolver);
    public TResult Accept<TResult>(
        ISelectorRegistrationVisitor<TResult> visitor);
}

internal sealed class RuleEvaluatorRegistration
{
    internal RuleDeclaration Declaration { get; }
    internal IRuleEvaluator Evaluator { get; }
    internal static RuleEvaluatorRegistration Create(
        RuleDeclaration declaration,
        IRuleEvaluator evaluator);
}
```

Each `CodecRegistration` binds one paired writer/qualifier object: its `Write`
and `Qualify` methods are supplied by the same manifest component CLR type and
artifact. The writer direction does not add a registration, model contract,
component row, cache, or public API. A component that can decode but cannot
write its declared persistent schema, or vice versa, is
`RegistrationMismatch` at activation.
`PayloadSchemaDeclaration.CodecFailureCodes` is the one canonical ordinal
allowlist for both writer Rejected and qualifier Rejected outcomes. A direction-
specific undeclared code or a second failure-code registry is
`RegistrationMismatch`.

Both policy-export families expose exact internal ordinal lists named
`CodecRegistrations`, `ParserRegistrations`, `IndexRegistrations`,
`DemandProjectorRegistrations`, `SelectorRegistrations`, and
`EvaluatorRegistrations` with the six element types above. Application or
Conformance selects a non-generic row by exact logical key/version. The five
heterogeneous codec/parser/index/demand-projector/selector lists dispatch only
through `Accept(visitor)`, where the concrete generic types become statically
available inside `Visit`; evaluator rows dispatch through their already public
`IRuleEvaluator` only after exact declaration/type validation. Registration/type-token
closure must equal the manifest model/capability/component graph. None of these
friend types contains `object`, `dynamic`, raw JSON/provider DTO,
`IServiceProvider`, I/O, or public registration; activation never reflects,
scans, or performs service lookup.

The internal export members/factories shown above are the final ContractSlice C
source shape, not an instruction to reference later-slice types early.
ContractSlice A introduces the public export projections with explicit
non-public constructors and validates canonical manifest plus declaration/
artifact/component preconditions without constructing an executable export or
calling an activation-proof overload. ContractSlice B
introduces only the final internal model-token plus codec-registration/visitor
subset needed by its test mirror; it does not yet add an export registration
list or six-list export factory.

`B-CODEC-ACTIVATION-01` stages only the identity-bearing prefix of that final
subset. `ICanonicalPayloadCodec<TModel>` is initially a constrained, memberless
internal interface so one object-identical component owns the future paired
writer and qualifier without introducing their successor-owned inputs, intents,
or resource meter early. Later packets may only add the exact final `Write`,
`Qualify`, and meter members already frozen above; they may not replace this
identity, add a direction-specific registration, or introduce an adapter.

`B-WIRE-REPOSITORY-TREE-01` deliberately keeps that generic interface
memberless. [TEST-0210](test-cases.md#test-0210) extends the already registered
Tests-owned `RepositoryTreeCodecMirror` and `RepositoryTreeModelMirror` as the
same partial identities, adding one closed `WriteRepositoryTree` /
`QualifyRepositoryTree` mirror core and closed Written/Rejected plus
Qualified/Rejected leaves in the repository-tree Fact file. This is
qualification-fixture staging, not a second codec architecture: no alternate
interface, adapter, static encoder, service lookup, public or production type is
introduced. After all three wire cores and the later resource carriers exist,
the final generic methods may delegate on these same mirror objects. Real
manifest-bound Policy implementations remain ContractSlice D work.

The packet-local signatures are exact:

```csharp
internal sealed class RepositoryTreePayloadEntryMirror
{
    internal string RepositoryRelativePath { get; }
    internal RepositoryEntryKind Kind { get; }
    internal static RepositoryTreePayloadEntryMirror Create(
        string repositoryRelativePath,
        RepositoryEntryKind kind);
}

internal sealed partial class RepositoryTreeModelMirror
{
    internal EvidenceScope Scope { get; }
    internal SnapshotEvidenceLocation Location { get; }
    internal IReadOnlyList<RepositoryTreePayloadEntryMirror> Entries { get; }
    internal static RepositoryTreeModelMirror Create(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        IEnumerable<RepositoryTreePayloadEntryMirror> entries);
}

internal abstract class RepositoryTreeWriteMirrorResult
{
    private RepositoryTreeWriteMirrorResult();
    internal static RepositoryTreeWriteMirrorResult Written(
        CanonicalEvidencePayload payload);
    internal static RepositoryTreeWriteMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IRepositoryTreeWriteMirrorResultVisitor<TResult> visitor);
}

internal interface IRepositoryTreeWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}

internal abstract class RepositoryTreeQualificationMirrorResult
{
    private RepositoryTreeQualificationMirrorResult();
    internal static RepositoryTreeQualificationMirrorResult Qualified(
        RepositoryTreeModelMirror model);
    internal static RepositoryTreeQualificationMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IRepositoryTreeQualificationMirrorResultVisitor<TResult> visitor);
}

internal interface IRepositoryTreeQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(RepositoryTreeModelMirror model);
    TResult VisitRejected(string failureCode);
}

internal sealed partial class RepositoryTreeCodecMirror
{
    internal RepositoryTreeWriteMirrorResult WriteRepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        IReadOnlyList<RepositoryTreePayloadEntryMirror> entries,
        CancellationToken cancellationToken);
    internal RepositoryTreeQualificationMirrorResult QualifyRepositoryTree(
        EvidenceBinding binding,
        CancellationToken cancellationToken);
}
```

Written carries one `CanonicalEvidencePayload`; Qualified carries one
`RepositoryTreeModelMirror` retaining the decoded scope, Snapshot location, and
ordinal immutable entry copy. Each Rejected leaf carries exactly one declared
codec failure code. Null arguments remain argument failures and cancellation is
out of band; neither is a semantic rejection. Each abstract result has exactly
two private nested sealed leaves, named `WrittenCase`/`RejectedCase` and
`QualifiedCase`/`RejectedCase`; callers observe them only through `Accept`.
Every factory materializes once and retains a defensive read-only copy. Writer
input is never sorted: it must already be unique and strictly increasing by
`StringComparer.Ordinal`; a duplicate or out-of-order row is rejected.
`RepositoryTreePayloadEntryMirror.Create` rejects only null path/kind and
otherwise preserves the supplied path text byte-for-byte so the writer remains
the sole path-grammar owner. `RepositoryTreeModelMirror.Create` rejects null
scope/location/entries and null entry elements, requires the Snapshot
location's scope to equal the supplied scope, then stores one defensive copy;
the qualifier calls it only after the complete wire has passed every oracle.
A null writer-list element throws `ArgumentException` with `ParamName=entries`
before semantic row validation. A structurally valid writer `scope` unequal to
`location.Scope` returns Rejected with
`protocol.codec.embedded-identity-mismatch`.

The repository-tree core implements the exact persistent frame below, the
`257`-byte golden SHA-256
`C5A8CB268E42C8A8C532A42C86ECDB0200B4C75186364B6399AD1AE5A40AE97F`,
and the `197`-byte empty-tree SHA-256
`BD2C4A254E295AE63E3EC7B610B7A6E88FC345E5D4DBD99C9AFFB61397E98676`.
The canonical semantic fixture is:

| Field | Exact value |
| --- | --- |
| Target subject / source / surface | `repo` / `git` / `repository` |
| Target snapshot / identity | `exact-commit` / fixture commit: `0123456789abcdef0123456789abcdef01234567` |
| Boundary snapshot / identity | `exact-commit` / fixture commit: `0123456789abcdef0123456789abcdef01234567` |
| Started / completed UTC ticks | `0` / `1` |
| Location | Snapshot, rank `3`, reusing the exact scope |
| Entry 1 | `AGENTS.md` / File / kind byte `1` |
| Entry 2 | `docs` / Directory / kind byte `0` |
| Entry 3 | `links/latest` / SymbolicLink / kind byte `2` |
| Entry 4 | `vendor/protocol` / GitLink / kind byte `3` |

The four-entry canonical Base64 is
`cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAQAAAAJQUdFTlRTLm1kAQAAAARkb2NzAAAAAAxsaW5rcy9sYXRlc3QCAAAAD3ZlbmRvci9wcm90b2NvbAM=`.
The empty-tree Base64 uses the same fixture and is
`cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAA=`.

It permits at most `200,000` entries, `16,777,216` aggregate strict-UTF-8 path
bytes before retention, and `16,777,216` payload bytes. Count equality is
reachable with `e000000` through `e199999` File rows and must succeed; adding
`e200000` rejects before encoding. Payload equality is reachable with exactly
`4,091` ordinal `p000000/`-style File rows: the first `4,090` paths are padded
to `4,096` UTF-8 bytes and the last to `3,924`, making the `197`-byte empty
frame plus five framing bytes per row exactly `16,777,216`; extending the last
path by one byte rejects. Aggregate path-byte equality is algebraically
dominated because its nonzero framing makes the payload exceed its ceiling: it
passes the path counter then rejects on payload size; path first-one-over stops
before framing or retention. These are wire-local fail-closed bounds;
four-counter ledger equality, dominated, and unreachable accounting remain
wholly owned by `B-RESOURCE-01`.

Failure precedence is exact: hard size/count first-one-over is
`protocol.codec.resource-limit-exceeded`; a known non-Repository surface or
non-Snapshot location is `protocol.codec.payload-location-mismatch`; a valid
embedded identity unequal to the enclosing binding is
`protocol.codec.embedded-identity-mismatch`; and malformed header/rank/kind,
UTF-8, length/count, EOF, trailing bytes, path grammar, duplication, or ordering
is `protocol.codec.invalid-repository-tree`. The executable allowlist is only
the retained activation test's partial-identity edit plus the new repository-
tree test/core file, with no production delta and a `1,200` normalized-line hard
cap. Canonical R is the exact FQN/marker/one-shot TRX route owned by the B plan
and current memory handoff; it cannot execute before the synchronized design
head is hosted green.

The mandatory malformed matrix is exact: wrong or mutated ASCII header;
BOM/invalid/overlong/surrogate UTF-8; premature EOF at every primitive;
declared text length or entry count overflow/mismatch; trailing byte; unknown
surface, location rank, or kind byte `4`; structurally valid known-but-
disallowed surface/location; structurally valid embedded scope/location unequal
to the enclosing binding; and empty, leading-slash, trailing-slash, backslash,
empty-segment, dot-segment, dot-dot-segment, drive-form, duplicate, and non-
ordinal paths. Writer tests construct invalid path text through the permissive
entry carrier and exercise count/path/payload first-one-over in that order;
unknown kind and malformed primitive cases are qualifier-only byte mutations.
Schema key/version mismatch belongs to invalid-repository-tree before any
embedded identity comparison. Count equality and payload equality are green as
specified above; aggregate path-byte equality is the declared dominated
resource rejection, while its first-one-over rejects before framing/retention.

Writer order is: null arguments, cancellation, known source surface/location,
source scope/location equality, one-time entry materialization and count,
per-row path/kind/order plus aggregate path bytes, computed payload size, then
encoding. Qualifier order is: null argument, cancellation, payload byte ceiling,
exact schema key/version, strict grammar and primitive bounds, entry count,
known embedded surface/location, row grammar/order/kind/path bytes, trailing-
byte closure, enclosing binding surface/location, then embedded-versus-
enclosing identity equality. Schema metadata mismatch, an unknown surface/rank,
or any construction failure in the decoded scope is invalid-repository-tree;
known-but-disallowed surface/rank is payload-location-mismatch. Only a fully
parsed valid embedded identity can reach embedded-identity-mismatch.

### Immutable hosted-green `B-WIRE-GOVERNED-TEXT-01` staging contract

The repository-tree implementation is immutable exact-head hosted-green
predecessor evidence. Governed text reuses the same Tests-owned same-object
mirror topology: only `GovernedTextModelMirror` and `GovernedTextCodecMirror`
become `partial`, and the new governed-text test file adds the following
packet-local core. The memberless generic codec interface remains unchanged;
there is no production codec, adapter, second encoder, resource meter, cache,
admission path, project, package, lock, workflow, friend, or public API delta.

```csharp
internal sealed partial class GovernedTextModelMirror
{
    internal EvidenceScope Scope { get; }
    internal EvidenceLocation Location { get; }
    internal ReadOnlyMemory<byte> Body { get; }
    internal static GovernedTextModelMirror Create(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body);
}

internal abstract class GovernedTextWriteMirrorResult
{
    private GovernedTextWriteMirrorResult();
    internal static GovernedTextWriteMirrorResult Written(
        CanonicalEvidencePayload payload);
    internal static GovernedTextWriteMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IGovernedTextWriteMirrorResultVisitor<TResult> visitor);
}

internal interface IGovernedTextWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}

internal abstract class GovernedTextQualificationMirrorResult
{
    private GovernedTextQualificationMirrorResult();
    internal static GovernedTextQualificationMirrorResult Qualified(
        GovernedTextModelMirror model);
    internal static GovernedTextQualificationMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IGovernedTextQualificationMirrorResultVisitor<TResult> visitor);
}

internal interface IGovernedTextQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(GovernedTextModelMirror model);
    TResult VisitRejected(string failureCode);
}

internal sealed partial class GovernedTextCodecMirror
{
    internal GovernedTextWriteMirrorResult WriteGovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body,
        CancellationToken cancellationToken);
    internal GovernedTextQualificationMirrorResult QualifyGovernedText(
        EvidenceBinding binding,
        CancellationToken cancellationToken);
}
```

Written carries exactly one `CanonicalEvidencePayload`; Qualified carries one
`GovernedTextModelMirror` retaining the decoded scope, exact Repository or
Provider location, and one defensive body-byte copy. Rejected carries exactly
one declared codec failure code. The result types have only private nested
`WrittenCase`/`RejectedCase` and `QualifiedCase`/`RejectedCase` leaves and are
observable only through their visitors. Null scope/location/binding arguments
remain argument failures; cancellation is checked before semantic work and is
out of band. `ReadOnlyMemory<byte>` is copied once before retention, and later
source-array mutation cannot alter the payload or qualified model.
`GovernedTextModelMirror.Create` rejects null scope/location, requires exact
`scope.Equals(location.Scope)`, copies body bytes once, and is called by the
qualifier only after every wire oracle passes.

The exact Repository fixture is:

| Field | Exact value |
| --- | --- |
| Target subject / source / surface | `repo` / `git` / `repository` |
| Target snapshot / identity | `exact-commit` / fixture commit: `0123456789abcdef0123456789abcdef01234567` |
| Boundary snapshot / identity | `exact-commit` / the same 40-hex identity |
| Started / completed UTC ticks | `0` / `1` |
| Location | Repository rank `0`; path `docs/body.text`; blob identity the same 40-hex value; line/anchor/property null |
| Body | exact UTF-8 bytes for `alpha\nβ\n`: `61 6C 70 68 61 0A CE B2 0A` |

Its canonical payload is `270` bytes with SHA-256
`93261D439E5D04624BC1F832077CEB9BBD2CA7B83B1CF7EEE0EA679553CECDAA`:

```text
cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQAAAAAOZG9jcy9ib2R5LnRleHQBAAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAJYWxwaGEKzrIK
```

The same Repository fixture with an empty body is valid, exactly `261` bytes,
and has SHA-256
`89DD683B71FD99D048642D63412F66E8CA358C36F32491337F86EC8E7810452F`:

```text
cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQAAAAAOZG9jcy9ib2R5LnRleHQBAAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAA
```

The exact Provider fixture is:

| Field | Exact value |
| --- | --- |
| Target subject / source / surface | `provider` / `github` / `provider` |
| Target snapshot / identity | `provider-event` / `event-42` |
| Boundary snapshot / identity | `provider-event` / `0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef` |
| Started / completed UTC ticks | `0` / `1` |
| Location | Provider rank `1`; service `github`; object type `provider.issue`; stable object `object42`; version `version-7`; field `body`; line/fragment null |
| Body | exact ASCII bytes for `provider body\n` |

Its canonical payload is `274` bytes with SHA-256
`D75DBDC44A92B21AADF730B6E5D65A992E74C8847F613DC7D378CA1F6B104F5E`:

```text
cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAAhwcm92aWRlcgAAAAZnaXRodWIAAAAIcHJvdmlkZXIAAAAOcHJvdmlkZXItZXZlbnQAAAAIZXZlbnQtNDIAAAAOcHJvdmlkZXItZXZlbnQAAABAMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZgAAAAAAAAAAAAAAAAAAAAEBAAAABmdpdGh1YgAAAA5wcm92aWRlci5pc3N1ZQAAAAhvYmplY3Q0MgAAAAl2ZXJzaW9uLTcBAAAABGJvZHkAAAAAAA5wcm92aWRlciBib2R5Cg==
```

The source-body and complete-payload ceilings are independently
`4,194,304` bytes. Repository payload equality is reachable with the exact
`261`-byte empty frame plus `4,194,043` ASCII `x` body bytes and must succeed;
one more body byte rejects as `protocol.codec.resource-limit-exceeded`.
Source-body equality at `4,194,304` passes the pre-copy body counter but is
algebraically dominated by nonzero framing and therefore rejects on complete
payload size. Body first-one-over rejects before UTF-8 inspection, copying, or
framing. These are wire-local checks only; multi-binding retention and the
four-counter ledger remain owned by later packets.

Writer precedence is exact: null arguments, cancellation, source-body first-
one-over, known Repository/Provider location leaf and tail matrix, supplied
scope versus `location.Scope` equality, UTF-8/BOM validation, computed payload
size, one defensive copy, then encoding. Qualifier precedence is null argument,
cancellation, canonical-payload byte ceiling, exact schema key/version, strict
header/primitive/optional framing, embedded scope and location construction,
body UTF-8/BOM validation, trailing-byte closure, known embedded and enclosing
Repository/Provider matrix, then embedded-versus-enclosing identity equality.

Any malformed UTF-8 sequence in a scope/location text or body is
`protocol.codec.invalid-utf8`. A leading UTF-8 BOM anywhere, wrong header,
schema key/version mismatch, premature EOF, declared length mismatch/overflow,
invalid optional flag, invalid known-leaf field grammar, unknown surface,
snapshot, or rank, or a trailing byte is
`protocol.codec.noncanonical-encoding`. A structurally valid Repository leaf
with non-null line/anchor/property, a structurally valid Provider leaf with
null field or non-null line/fragment, Workflow surface, or ReleaseAsset/
Snapshot rank is `protocol.codec.payload-location-mismatch`. Only a fully valid
allowed Repository or Provider embedded scope/location unequal to the supplied
writer scope or enclosing binding may return
`protocol.codec.embedded-identity-mismatch`. These outcomes are mutually
exclusive; writer and qualifier tests cover both allowed leaves, every tail
condition, every primitive EOF, BOM and invalid/overlong/surrogate UTF-8,
optional flags `0/1/2`, schema/header mutation, declared body mismatch,
trailing bytes, size equality/first-one-over, defensive copying, empty body,
and byte-exact round trips without newline or Unicode normalization.

The executable allowlist is exactly a partial-identity-only modification to
`ContractSliceBActivationTests.cs` plus one new
`ContractSliceBGovernedTextCodecTests.cs`; production, public surface, project,
package, lock, workflow, Policy, resource, cache, admission, and later-wire
surfaces are immutable. The normalized two-test-file delta is at most `1,200`;
`1,201` or more requires renewed design review. The test is one direct,
non-skipped Fact at
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire`,
with exactly one `ContractSlice=B` trait, no Scenario/Theory/class trait or
overload, and marker `TEST-0210-B-BEHAVIOR-RED-0003`. Its red temporarily makes
only the fully prepared valid Repository `WriteGovernedText` semantic return
`null!`; only that null may call direct `Assert.Fail(marker)`. Every setup,
exception, wrong non-null result, negative, and qualifier assertion is marker-
free. Green is focused `1/1`, cumulative B `5/5`, and cumulative A+B/full
Conformance `37/37`, while Domain remains `98/98`.

Canonical R uses one fresh external CreateNew runner matching
`D:\Temp\meandai-test-0210-b-governed-text-r0003-runner-<32-lowercase-hex-guid>.ps1`,
fresh report/log siblings, and a different fresh result root. It inherits the
repository-tree runner's exact source/Git/lock/build/DLL/PDB/hash, `8,388,608`-
byte complete-log, `1,048,576`-byte report, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, `420000`-ms monotonic, secure-TRX, atomic
`InvocationCommitted`, and immutable no-retry contracts, specialized to these
two source files, the `1,200`-line ceiling, marker/FQN, and this exact command:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0003.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire"
```

No runner may be materialized and no canonical red may start until the exact
commit containing this twelve-record freeze is pushed and exact-head hosted
green. The accepted repository-tree red is immutable and is never rerun.

### Frozen-design `B-WIRE-REPOSITORY-TARGET-01` staging contract

The governed-text implementation is immutable exact-head hosted-green
predecessor evidence. Repository-target reuses the same Tests-owned,
same-object topology: only the retained `RepositoryTargetModelMirror` and
`RepositoryTargetCodecMirror` declarations become `partial`, and one new test
file supplies the packet-local core below. The memberless generic codec
interface remains unchanged. No production codec, adapter, alternate encoder,
resource meter, cache, admission path, index/capability semantics, project,
package, lock, workflow, friend, or public API is activated.

```csharp
internal sealed partial class RepositoryTargetModelMirror
{
    internal EvidenceScope Scope { get; }
    internal SnapshotEvidenceLocation Location { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal IReadOnlyList<RepositoryTargetRowMirror> Rows { get; }
    internal IReadOnlyList<RepositoryTargetContentMirror> Contents { get; }
    internal static RepositoryTargetModelMirror Create(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        IEnumerable<RepositoryTargetRowMirror> rows,
        IEnumerable<RepositoryTargetContentMirror> contents);
}

internal abstract class RepositoryTargetContentMirror
{
    private RepositoryTargetContentMirror();
    internal static RepositoryTargetContentMirror CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string normalizedRepositoryRelativePath,
        string observedBlobObjectId,
        ReadOnlyMemory<byte> bytes);
    internal static RepositoryTargetContentMirror CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string observedContentIdentity,
        ReadOnlyMemory<byte> bytes);
    internal abstract TResult Accept<TResult>(
        IRepositoryTargetContentMirrorVisitor<TResult> visitor);
}

internal interface IRepositoryTargetContentMirrorVisitor<TResult>
{
    TResult VisitCommitObject(
        string owner, string commit, string path, string blob,
        ReadOnlyMemory<byte> bytes);
    TResult VisitCapturedSnapshotPath(
        string owner, string capture, string path, string contentIdentity,
        ReadOnlyMemory<byte> bytes);
}

internal abstract class RepositoryTargetRowMirror
{
    private RepositoryTargetRowMirror();
    internal RepositoryTargetResolutionDemandItem DemandItem { get; }
    internal static RepositoryTargetRowMirror MissingCommit(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetRowMirror PresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity);
    internal static RepositoryTargetRowMirror PresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity);
    internal static RepositoryTargetRowMirror PresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedType, string observedIdentity,
        string observedPath, string observedPathType,
        string observedPathIdentity, RepositoryTargetContentMirror? content);
    internal static RepositoryTargetRowMirror MissingTag(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetRowMirror PresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedRefName,
        string observedRefType, string observedRefIdentity,
        string observedPeeledType, string observedPeeledIdentity);
    internal static RepositoryTargetRowMirror MissingCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem);
    internal static RepositoryTargetRowMirror PresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner, string observedCapture, string observedPath,
        string observedEntryKind, string observedContentIdentity,
        RepositoryTargetContentMirror content);
    internal abstract TResult Accept<TResult>(
        IRepositoryTargetRowMirrorVisitor<TResult> visitor);
}

internal interface IRepositoryTargetRowMirrorVisitor<TResult>
{
    TResult VisitMissingCommit(RepositoryTargetResolutionDemandItem demand);
    TResult VisitPresentCommit(
        RepositoryTargetResolutionDemandItem demand,
        string owner, string type, string identity);
    TResult VisitPresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner, string type, string identity);
    TResult VisitPresentCommitPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner, string type, string identity,
        string path, string pathType, string pathIdentity,
        RepositoryTargetContentMirror? content);
    TResult VisitMissingTag(RepositoryTargetResolutionDemandItem demand);
    TResult VisitPresentTag(
        RepositoryTargetResolutionDemandItem demand,
        string owner, string refName, string refType, string refIdentity,
        string peeledType, string peeledIdentity);
    TResult VisitMissingCapturedPath(
        RepositoryTargetResolutionDemandItem demand);
    TResult VisitPresentCapturedPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner, string capture, string path, string entryKind,
        string contentIdentity, RepositoryTargetContentMirror content);
}

internal abstract class RepositoryTargetWriteMirrorResult
{
    private RepositoryTargetWriteMirrorResult();
    internal static RepositoryTargetWriteMirrorResult Written(
        CanonicalEvidencePayload payload);
    internal static RepositoryTargetWriteMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IRepositoryTargetWriteMirrorResultVisitor<TResult> visitor);
}

internal interface IRepositoryTargetWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}

internal abstract class RepositoryTargetQualificationMirrorResult
{
    private RepositoryTargetQualificationMirrorResult();
    internal static RepositoryTargetQualificationMirrorResult Qualified(
        RepositoryTargetModelMirror model);
    internal static RepositoryTargetQualificationMirrorResult Rejected(
        string failureCode);
    internal abstract TResult Accept<TResult>(
        IRepositoryTargetQualificationMirrorResultVisitor<TResult> visitor);
}

internal interface IRepositoryTargetQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(RepositoryTargetModelMirror model);
    TResult VisitRejected(string failureCode);
}

internal sealed partial class RepositoryTargetCodecMirror
{
    internal RepositoryTargetWriteMirrorResult WriteRepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems,
        IReadOnlyList<RepositoryTargetRowMirror> rows,
        IReadOnlyList<RepositoryTargetContentMirror> contents,
        CancellationToken cancellationToken);
    internal RepositoryTargetQualificationMirrorResult
        QualifyRepositoryTargetResolution(
            EvidenceBinding binding,
            ExactSha256Digest expectedDemandDigest,
            IReadOnlyList<RepositoryTargetResolutionDemandItem> expectedDemandItems,
            CancellationToken cancellationToken);
}
```

Each abstract carrier has only the private sealed leaves implied by its factory
list; no public constructor, catch-all row, mutable property, direction-specific
adapter, or second codec exists. Written and Qualified carry exactly one
payload/model; Rejected carries exactly one declared code. Every list and every
content byte sequence is copied once before retention. Input order is
authoritative and must already be canonical; the writer never sorts or repairs
rows, demand items, or content. Null list arguments are
`ArgumentNullException`; a null element is `ArgumentException` with exact
`ParamName` equal to `demandItems`, `rows`, or `contents` before semantic
validation. Cancellation is checked before semantic work and remains out of
band.

Demand list/row list are non-empty, counts are equal, every demand has the same
non-empty canonical owner, and ItemIds are non-negative and strictly increasing.
A CommitObject demand
without a path permits only MissingCommit or PresentCommit; one with a path
permits only MissingCommit, PresentCommitMissingPath, or PresentCommitPath. A
TagRoot permits only MissingTag/PresentTag and a CapturedSnapshotPath permits
only MissingCapturedPath/PresentCapturedPath. PresentCommitPath may omit its
content only when the requested fragment is null; PresentCapturedPath and every
fragment-bearing present path require content. Writer rows reference the exact
demand object at the same ordinal and content carriers by object identity;
every referenced content object occurs exactly once in the contents list and no
unreferenced content is accepted.

The exact valid fixture uses one Repository/Snapshot scope with subject `repo`
and source `git`. Fixture commit SHA: `0123456789abcdef0123456789abcdef01234567`;
snapshot/boundary kind `exact-commit`, ticks `0/1`, and one owner shard
`https://github.com/owner/repo`. Its exact demand rows are:

| Item | Selector and requested tuple | Qualified row | Content |
| --- | --- | --- | --- |
| `0` | Fixture commit SHA: `0123456789abcdef0123456789abcdef01234567`, path `docs/README.md`, fragment `intro` | Present commit/path; exact owner; type `commit`; exact commit; exact path; type `blob`; fixture blob OID: `1e0981f10f35ca8f594fec2a03f11df5a7299098` | ordinal `0`; exact bytes `# Intro\n`; SHA-256 digest: `2A8A06BBB4A42EEE60F35E2C6EACB1C3BBE0F8748817D1547A59692784B53C33` |
| `1` | Tag `v1` | Present tag; exact owner/ref `refs/tags/v1`; type `tag`; ref identity forty `1` digits; peeled type `commit`; exact fixture commit | none |
| `2` | Test vector: `abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789`, path `src/file.txt`, fragment `L1` | Present captured path; exact owner/capture/path; entry kind `file`; SHA-256 digest: `c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1` | ordinal `1`; exact bytes `line\n`; same SHA-256 identity |

The exact canonical demand frame is `318` bytes with SHA-256
`9DF61AC4D5F82C5FDA121B05319B16399580FC0A8D28B4AC62D1879D24899CBA`:

```text
cHJvdG9jb2wuYWNxdWlzaXRpb24tZGVtYW5kLzEKAQAAAAMAAAAAAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAEAAAAFaW50cm8AAAABAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAQAAAAJ2MQAAAAIAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8CAAAAQGFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODkAAAAMc3JjL2ZpbGUudHh0AAAAAkwx
```

The exact canonical payload is `1,465` bytes with SHA-256
`936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0`:

```text
cHJvdG9jb2wucmVwb3NpdG9yeS10YXJnZXQtcmVzb2x1dGlvbi8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQOd9hrE1fgsX9oSGwUxmxY5lYD8Co0otKxi0YedJImcugAAAAMAAAAAAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAEAAAAFaW50cm8BAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAABmNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAAAAARibG9iAAAAKDFlMDk4MWYxMGYzNWNhOGY1OTRmZWMyYTAzZjExZGY1YTcyOTkwOTgBAAAAAAAAAAEAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8BAAAAAnYxAQAAAB1odHRwczovL2dpdGh1Yi5jb20vb3duZXIvcmVwbwAAAAxyZWZzL3RhZ3MvdjEAAAADdGFnAAAAKDExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEAAAAGY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAACAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAgAAAEBhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5AAAADHNyYy9maWxlLnR4dAAAAAJMMQEAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8AAABAYWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OQAAAAxzcmMvZmlsZS50eHQAAAAEZmlsZQAAAEBjNzNiNzNhZjg4NTFlOWU5MWJjNmI0ZGMxMmU3ZGFjZTBhMmJmYjkzMWMxZDBiOGIzNmVmMzY3MzE5ZjU4Y2QxAAAAAQAAAAIAAAAAAAAAAB1odHRwczovL2dpdGh1Yi5jb20vb3duZXIvcmVwbwAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADmRvY3MvUkVBRE1FLm1kAAAAKDFlMDk4MWYxMGYzNWNhOGY1OTRmZWMyYTAzZjExZGY1YTcyOTkwOTgAAAAIKooGu7SkLu5g814sbqyxw7vg+HSIF9FUellpJ4S1PDMjIEludHJvCgAAAAEBAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAQGFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODkAAAAMc3JjL2ZpbGUudHh0AAAAQGM3M2I3M2FmODg1MWU5ZTkxYmM2YjRkYzEyZTdkYWNlMGEyYmZiOTMxYzFkMGI4YjM2ZWYzNjczMTlmNThjZDEAAAAFxztzr4hR6ekbxrTcEufazgor+5McHQuLNu82cxn1jNFsaW5lCg==
```

The writer recomputes the exact demand frame and digest before payload
retention; the qualifier recomputes it from the caller-supplied expected demand
and requires exact digest, row echo, and canonical byte equality. ItemIds are
strictly increasing but need not be contiguous across a one-owner shard. Row
count equals demand count and rows retain exact demand order. Contents are
ordinal `0..N-1`, CommitObject keys precede CapturedSnapshotPath keys, then key
fields compare ordinally. Every content row is referenced; a fragment-bearing
present path references exactly one content; a path-only commit may reference
none. No row/content repair, normalization, sorting, or deduplication occurs.

Validation precedence is exact. Argument/null/cancellation boundaries occur
first. The writer then checks row count, content count, aggregate strict-UTF-8
row-text bytes, per-content bytes, aggregate unique-content bytes, Repository/
Snapshot scope/location shape and equality, selector closure and one-owner
demand order, demand digest, row bijection/variant fields, content ordinal/key/
reference closure, commit-blob or capture SHA self-consistency, combined
payload size, defensive copies, and encoding. The qualifier checks complete
payload size, schema key/version, header and primitive framing, embedded scope/
location construction, demand digest and expected-item equality, row/content
grammar/order/reference closure, self-consistency, trailing-byte closure,
enclosing Repository/Snapshot shape, and embedded-versus-enclosing identity.

The exact failure partition is mutually exclusive:

- any hard first-one-over or checked-arithmetic overflow is
  `protocol.codec.resource-limit-exceeded`;
- a structurally valid known non-Repository surface or non-Snapshot location is
  `protocol.codec.payload-location-mismatch`;
- a fully valid embedded scope/location unequal to the supplied writer scope
  or enclosing binding is `protocol.codec.embedded-identity-mismatch`; and
- wrong schema/header, invalid UTF-8 or selector/optional/outcome/owner-kind
  byte, EOF/length/count mismatch, row echo/order/duplicate/missing/extra,
  content ordinal/key/order/reference defect, trailing byte, invalid owner/tag/
  path/fragment/object identity grammar, or self-inconsistent Git-blob/capture
  content is `protocol.codec.invalid-repository-target-resolution`.

The semantic `Unresolved`, `WrongRepository`, `WrongTarget`, `WrongObject`,
`MissingFragment`, `WrongFragment`, and `Exact` capability outcomes remain held
for the later repository-target index. This packet only persists and qualifies
closed wire variants; it does not classify a final target view.

Wire-local ceilings are exactly `50,000` rows, `64` referenced unique content
objects, `16,777,216` aggregate strict-UTF-8 row-text bytes, `1,048,576` bytes
per content, `16,777,216` aggregate unique-content bytes, and `33,554,432`
complete payload bytes. Deterministic test constructors prove each reachable
equality and first-one-over in that order, keeping all earlier counters below
their ceilings; count equality uses increasing zero-padded selector identities,
content equality uses canonical small keys, and the payload constructor adjusts
its final valid ASCII path/content filler without crossing an earlier limit.
First-one-over stops before retention/copy. These checks do not activate the
later four-counter resource ledger or plan-global multi-owner aggregate.
The row-text counter includes every serialized strict-UTF-8 demand echo,
observed row field, and content-key text occurrence after scope/location and
before raw content bytes; invalid UTF-16 input fails as invalid-repository-
target-resolution at that gate rather than being replaced or counted.

The malformed matrix mutates every header/digest/primitive boundary; every
selector/optional/outcome/owner-kind tag; strict UTF-8 and path/tag/fragment/
identity grammar; missing/extra/duplicate/reordered row; demand echo and digest;
content ordinal/key/digest/length/bytes; unreferenced or multiply conflicting
content; path-only versus required-fragment content; Git SHA-1 blob framing for
40-hex commits; captured SHA-256 content; trailing bytes; and all six equality/
one-over constructors. Source-array mutation after writer/model construction
must not alter retained payload, rows, or contents.

The executable allowlist is exactly a partial-identity-only modification to
`ContractSliceBActivationTests.cs` plus one new
`ContractSliceBRepositoryTargetCodecTests.cs`. Production, public surface,
project, package, lock, workflow, Policy, resource, cache, admission, index,
capability, and later-wire surfaces are immutable. This packet receives a
reviewed complexity redraw to at most `3,200` normalized two-test-file lines;
`3,201` requires renewed design. The default `1,200` ceiling remains unchanged
for later packets unless separately reviewed.

The test is one direct non-skipped Fact at
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire`,
with exactly one `ContractSlice=B` trait, no Scenario/Theory/class trait or
overload, and marker `TEST-0210-B-BEHAVIOR-RED-0005`. Its red temporarily makes
only the fully prepared valid `WriteRepositoryTargetResolution` semantic
return `null!`; only that null calls direct `Assert.Fail(marker)`. Setup,
exceptions, wrong non-null results, negative vectors, and qualifier assertions
remain marker-free. Green is focused `1/1`, cumulative B `6/6`, A+B/full
Conformance `38/38`, and Domain `98/98`.

R=0004 is immutable `OracleRejected/NoCanonicalRed` evidence. Its exact
37,198-byte runner SHA-256 is
`8A5E3FD7C580F57C429DA89996D5A073A3E416E9D31BCD985BF99E04E3879192`;
report/TRX SHA-256 values are
`0D300970B537A0265DC3E39732333ED63385D82D8EC038EA40262ABACD1493F8` and
`CC5D494F1154113A9735935F5238711520C5E5F1C9292D60F931CFF4AA5E993D`.
The child returned native `1`, but the stale fixture digest ended in
`...2C17...` while the actual frozen frame SHA-256 ends in `...2C5F...`;
therefore writer preparation returned a marker-free rejection, the later
digest assertion failed, raw marker count was `0`, and R=0004 is never rerun.

Corrected R=0005 changes only the source `DemandDigest` constant to exact
`9df61ac4d5f82c5fda121b05319b16399580fc0a8d28b4ac62d1879d24899cba`
and the marker from `0004` to `0005`; the valid writer's `null!` staging and
every other source/design byte remain semantically unchanged. Canonical R=0005
uses one fresh external CreateNew runner matching
`D:\Temp\meandai-test-0210-b-repository-target-r0005-runner-<32-lowercase-hex-guid>.ps1`,
fresh report/log siblings, and a different fresh result root. It inherits the
governed-text runner's exact source/Git/lock/build/DLL/PDB/hash, `8,388,608`-
byte complete-log, `1,048,576`-byte report, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, `420000`-ms monotonic, secure-TRX, atomic
`InvocationCommitted`, and immutable no-retry contracts, specialized to these
two source files, the `3,200`-line ceiling, marker/FQN, and this exact command:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0005.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire"
```

The exact twelve-record design cohort added no tracked node and validated
under schema-2 ceilings `512` nodes / `8,192` relations / `1,048,576` bytes per
parsed blob / `8,388,608` aggregate bytes. Its exact correction head passed both
stable hosted jobs before R=0005. R=0001..0003 remain immutable; R=0004 is
immutable diagnostic-only; none is ever rerun. Canonical R=0005 was accepted
once (native exit `1`, runner exit `0`, report SHA-256
`513677E6D4BB7552455E1DB3CDAA986384C6EA441B002F0718293633B0522EB7`,
TRX SHA-256 `64D22B48825F0128D48FBB9FA500C4358B4321D2D804F7C46999B779EAA39F6C`).
The bounded green is `1/1`, `6/6`, `38/38`, and `98/98` at `2,849/3,200`
normalized lines, with zero production delta; its implementation head is hosted pending.

The complete Tests-only causal surface is:

```csharp
internal interface IContractSliceBActivationProofState
{
    bool ProvesCodecMirror(
        FinalizedPolicyManifest manifest,
        IReadOnlyList<ICodecRegistration> codecRegistrations);
}

internal sealed class ContractSliceBWriteTicket
{
    internal EvidenceSlotDeclaration Slot { get; }
    internal AcquisitionTarget Target { get; }
    internal AcquisitionRequest Request { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal static ContractSliceBWriteTicket Create(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        AcquisitionRequest request,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest);
}

internal abstract class ContractSliceBAdmissionResult
{
    private ContractSliceBAdmissionResult();
    internal static ContractSliceBAdmissionResult Observed(
        SealedEvaluationContext context,
        QualifiedEvidenceReference contextProof,
        IEnumerable<QualifiedEvidenceReference> roots);
    internal static ContractSliceBAdmissionResult Failed(
        FailedAcquisitionResult result);
    internal static ContractSliceBAdmissionResult NoInput(
        AcquisitionRequest request);
    internal abstract TResult Accept<TResult>(
        IContractSliceBAdmissionResultVisitor<TResult> visitor);
}

internal interface IContractSliceBAdmissionResultVisitor<TResult>
{
    TResult VisitObserved(
        SealedEvaluationContext context,
        QualifiedEvidenceReference contextProof,
        IReadOnlyList<QualifiedEvidenceReference> roots);
    TResult VisitFailed(FailedAcquisitionResult result);
    TResult VisitNoInput(AcquisitionRequest request);
}

internal sealed class ContractSliceBAdmissionHarness
{
    internal static ContractSliceBAdmissionHarness Activate(
        FinalizedPolicyManifest manifest,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IPolicyActivationProof activationProof);
    internal ContractSliceBWriteTicket IssueWriteTicket(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        AcquisitionRequest request,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems);
    internal CanonicalPayloadWriteIntent WriteCanonicalPayload(
        ContractSliceBWriteTicket ticket,
        CanonicalPayloadWriteSourceIntent source,
        CancellationToken cancellationToken);
    internal ObservedEvidenceQualificationIntent Qualify(
        ContractSliceBWriteTicket ticket,
        ObservedAcquisitionResult result,
        CancellationToken cancellationToken);
    internal ContractSliceBAdmissionResult Admit(
        ContractSliceBWriteTicket ticket,
        IAdmissionProofCandidate candidate,
        CancellationToken cancellationToken);
}
```

`Activate` materializes the exact manifest-declared Conformance.Tests codec
mirror in ordinal order, requires the activation proof to implement the one
internal `IContractSliceBActivationProofState`, and validates artifact/type/
schema/object-instance bijection before retaining either. `IssueWriteTicket`
requires `Request.Target` to equal the separately supplied slot-resolved
`Target`, the request's
singleton Requirement to equal `Slot.Requirement`, and schema/surface to match.
Repository-tree and governed-text slots require the canonical empty static
demand. A repository-target-resolution slot requires one non-empty canonical
contiguous single-owner demand whose rows use the closed CommitObject, TagRoot,
or CapturedSnapshotPath selector union; kernel-proven empty target demand has no
instruction/ticket. The harness derives and retains both frames/digests. Only the
harness-registered ticket object plus its private stamp is live.

Ticket state has a sticky `Attempted` bit separate from its retryable phase.
Every ticket/private-stamp/call-structure predicate is validated first and
mutates nothing. Only after that complete validation succeeds does a valid
Write or Qualify call atomically set `Attempted`, immediately before its first
local resource/component step. Cancellation or host failure retains both the
sticky bit and the exact retryable phase/products; it can never restore NoInput
eligibility. A declared source/writer rejection stores canonical failures,
discards every retained write product, and enters `TerminalRejected`; count
one-over rejects before Policy, while byte one-over rejects the just-produced
bytes without retaining them and discards the prior open set. Both ceiling
paths retain the exact singleton slot requirement and the sole failure code
`protocol.codec.resource-limit-exceeded` for later Failed equality. A
terminal, foreign, duplicate, or structurally mismatched call performs no
Policy work and changes no ticket field.

`Qualify` accepts only the exact complete retained payload-object bijection in
binding/location order and runs the paired qualifier through the one
Conformance-owned decode/model cache. Qualified retains the exact result,
intent, model handles, and cache identity; Rejected retains canonical failures,
discards observed authority, and enters `TerminalRejected`. `Admit` validates
that a candidate implements exactly one Observed/Failed/NoInput leaf, then
checks its exact CLR proof type/artifact, manifest/private stamp, digests,
Request/slot/route/receipt frames, and `Proves(candidate)` before one atomic
consume. It never reruns a writer or qualifier.

Observed requires the object-identical retained `ObservedAcquisitionResult`,
the exact ordered `IObservedQualificationProofState.QualifiedModels` handle
sequence, and the internally retained decode/model-cache association; there is
no separately exposed or caller-forgeable Qualified-state object. Failed has
two causal paths: after local work it requires `TerminalRejected` plus exact
Request and retained failure-list equality; before local work it may represent
a proof-component-attested external route/authority/transport attempt with the
exact Failed result and interval, and that structurally valid external attempt
sets the same sticky `Attempted` bit before proof work. NoInput requires a
pristine, never-attempted ticket with no product or qualification. Open writes
or retained qualification reject Failed/NoInput. Cancellation or any structural
mismatch consumes nothing; a consumed ticket/candidate cannot replay. Closed
nested `ObservedCase`, `FailedCase`, and `NoInputCase` leaves implement the
result visitor without adding a public type.

The harness returns only B writer/qualification/admission assertions, never a
public plan, closure, catalog evaluation, export, or authority proof. The final
`IPlanBoundEvidenceSession(AcquisitionInstruction, ...)` shape below is
introduced with ContractSlice C; B source/tests do not name the C public type.
ContractSlice C atomically introduces `IRuleEvaluator`, all six final internal
registration families, and a Tests-owned synthetic complete export/fixture.
ContractSlice D is the first slice that consumes the real Policy qualification
export and the first slice containing real Policy writer/codec/parser/index/
projector/evaluator implementations. D repeats B and C semantic vectors
directly against those real registrations; immutable fixture data may be
shared, but no B/C result is consumed as product evidence. Policy keeps no Tests
friend and no pre-D bootstrap/export seam. No A/B source mentions
`IDemandProjectorRegistration` or `RuleEvaluatorRegistration` before its owning
internal contract exists, so later SurfaceRed symbols remain truly absent.

### Exact input cardinality and invocation expansion

`ComponentInputDeclaration` is an exclusive union: exactly one of `Model` and
`Capability` is non-null. `MinimumCount` is non-negative. `MaximumCount` is
either null (unbounded) or greater than or equal to `MinimumCount`; `(0, 0)` is
rejected as a no-op declaration. One parser/index declaration cannot repeat a
model or capability identity. The binder's `Inputs` list must be structurally
equal, including cardinalities and order, to its manifest declaration;
otherwise activation is `RegistrationMismatch`.

Schema 1 expands components deterministically:

- each admitted `EvidenceBinding` invokes its one manifest-resolved codec once;
  a zero-binding complete context invokes no codec;
- every parser has exactly one model input with `(1, 1)`, no capability input,
  and is invoked once for each matching sealed model/binding; therefore its
  singular `SemanticModelProduct.Parent` is the complete parser provenance;
- a `PerContext` index is invoked once for each exact admitted
  `(SlotKey, resolved AcquisitionTarget, EvidenceContext)` after all inputs
  belonging to that same context are ready; and
- a `PerPlan` index is invoked once for the exact plan after every declared
  predecessor input from all contributing admitted contexts and earlier index
  outputs is ready. Its input values are the canonical unique union, not one
  caller-selected context.

If identical exact input handles would schedule the same component more than
once through coalesced rules/slots, the scheduler makes one invocation and
aliases the sealed output under every contributing SlotKey. Model handles are
ordered by contract then their qualified-reference structural identity;
capability handles are ordered by contract then their ordered evidence list.
`RequireModel`/`RequireCapability` require exactly one matching value;
`RequireModels`/`RequireCapabilities` return that canonical list. Missing
inputs caused by a Failed/NoInput/incomplete predecessor terminalize the
dependent slot as `NotEvaluated` without invoking the component. A supposedly
ready invocation outside its declared count range is `PlanStateInvalid`.

`RequireDemandItems` and `RequireDemandBinding` are an activation-guarded
auxiliary seam only for the exact
`protocol.index.repository-target-resolution` / `1` binder when its input is
bound to the declared repository-target projector output slot/schema. Every
other registration call
is `RegistrationMismatch`. The item list/map is the exact current plan's
canonical instruction-shard union. Each ItemId maps to both its source-reference
and source-authority handle. The complete selector tuple plus both structural
handles/authority provenance are included in the target-index cache input
identity; none is caller supplied or available to an evaluator.

The initial registry cardinality/scope is exact:

| Component | Invocation scope | Exact inputs |
| --- | --- | --- |
| Markdown parser | per admitted binding | source-text model `(1, 1)` |
| Repository-target Markdown parser | per admitted binding | repository-target-resolution model `(1, 1)`; every `Produced` success has exactly one set-model output even when it contains zero Markdown entries; declared failure has none |
| Repository-tree index | `PerContext` | repository-tree model `(1, 1)` |
| Protocol-record index | `PerContext` | Markdown-document model `(0, unbounded)` |
| Governed-reference index | `PerPlan` | Markdown-document model `(0, unbounded)`; protocol-record capability `(1, unbounded)` |
| Repository-target-resolution index | `PerPlan` | repository-target-resolution model `(0, unbounded)`; repository-target-Markdown set model `(0, unbounded)`; governed-reference-index capability `(1, 1)` |

For a complete governed-text context with zero bindings, the per-context
protocol-record index still runs and produces an empty capability backed by
the slot's context proof. Consequently every active governed-text slot
contributes exactly one protocol-record capability to the per-plan reference
index even when it contributes no Markdown model. The target index receives
zero target and target-Markdown models only for kernel-proven empty dynamic
demand; otherwise it receives exactly one target model and one set model per
owner-sharded repository-target instruction. Each set model retains the same
binding, parent, demand, and instruction identity as its target model. This
pairing check applies only to parser invocations that returned `Produced`. A
declared `SemanticFailureIntent` from the target-Markdown parser deliberately
produces no set model: Conformance retains that exact typed failure, does not
invoke the target index for the plan, and terminalizes its dependent rules as
`NotEvaluated`. Only a missing, extra, duplicate, or cross-paired model when
every relevant parser invocation succeeded is `PlanStateInvalid`. Cancellation
and unexpected host failure remain out of band and publish neither a semantic
failure nor a model. These are scheduler refinements of the declared
`(0, unbounded)` range, not adapter discretion.

### Exact semantic resource accounting

`SemanticResourceUsage` is aggregate-only and carries the same four non-negative
dimensions as `SemanticResourceBudget`; `Fits` means every counter is less than
or equal to its matching maximum. `SemanticResourceLocalUsage` is deliberately
different: it carries only producer-computable `GeneratedBytes`, `LayerDepth`,
`LayerNodes`, and `AdditionalComplexity`. Equality is accepted, the first
greater value is exhaustion, and all additions use checked 64-bit arithmetic.
Successful component products carry only their claimed local usage, never a
transitive aggregate or private ledger claim. A `SemanticFailureIntent`
deliberately carries no usage scalar: no handle/ledger is sealed from a failed
product, and an unmetered partial traversal cannot claim resource authority.
Every sealed model/capability handle additionally carries the immutable
canonical `SemanticResourceLedger` from which that usage was calculated; no
factory may drop or replace it.
The deterministic schema-1 counters are:

| Component family | Local `GeneratedBytes` | Local `LayerDepth` | Local `LayerNodes` | Local `AdditionalComplexity` |
| --- | --- | --- | --- | --- |
| Payload codec | `0`; canonical bytes already exist in the selected rank-0 payload row | Persistent payload root is depth 1; each nested scope/location/list/row adds one; scalar/body bytes are leaves | One per root, structural container, list, row, scalar, present optional, and the body byte-string as one leaf | `0` |
| Markdown parser | `0`; the selected rank-0 row owns the input bytes | Structural root is 1; every owned block/inline edge adds one; every derived protocol node is one deeper than its narrowest containing structural node | One document root, every owned Block, every `LeafBlock.Inline` structural root, every owned Inline, plus one each for every derived record, renderer-active anchor, maximal rendered-text run, and normalized governed occurrence | `0` |
| Repository-target Markdown parser | `0`; the selected rank-0 row owns the input bytes | Set root is 1; each ParsedMarkdown ownership tree uses the same structural/derived rule as Markdown and is one level below its set entry; InvalidText is one entry leaf | One set root, one entry per included Markdown content, every structural/derived node of each ParsedMarkdown entry, and one leaf for each InvalidText entry; non-Markdown content adds no parser entry | `0` |
| Repository-tree index | `0` | Maximum selected codec semantic depth plus one index layer | Newly emitted entry/view nodes only | `0` |
| Protocol-record index | `0` | Maximum selected Markdown semantic depth plus one; empty input has depth 1 | Newly emitted record/member nodes only | `0` |
| Governed-reference index | `0` | Maximum input model/capability depth plus one | Newly emitted reference/target-candidate nodes only | `MatchPairs`, the deterministic count of reference-to-record candidates sharing the exact parsed target identity |
| Repository-target-resolution index | `0` | Maximum governed-reference, target-model, and paired target-Markdown-model depth plus one | Newly emitted demand/result/view rows and derived commit/tag/blob/anchor/line proof nodes only | `DemandItemCount` |
| Demand projector | Sum of strict-UTF-8 byte lengths of owner and every non-null commit/tag/capture/path/fragment/manifest-expected-content-identity field retained by each candidate, occurrence by occurrence | Maximum source-reference and source-authority derivation count plus one; empty input is depth 1 | Every input governed-reference view plus every emitted candidate; no prior ledger row is re-counted | `CandidateCount` |

The local table and the selected-baseline table below are disjoint by
construction. Aggregate Bytes come only from selected rank-0 payload rows and
positive rank-1 generated rows; aggregate Nodes come only from selected and new
rank-2 semantic rows; aggregate Complexity is the resulting `Bytes + Nodes`
plus positive rank-3 terms. The first codec ledger therefore contains exactly
one payload-byte row and one codec-node row, never two copies of the canonical
payload bytes.

The Markdown structural walker is exact and iterative. Its only ownership edges
are `ContainerBlock[index]`, `LeafBlock.Inline`, and the child-sibling sequence
owned by a `ContainerInline`. It never follows `Parent`, `ParentBlock`,
`PreviousSibling`, `NextSibling`, `LinkInline.Reference`, a dynamic URL
delegate, footnote backlinks, or data dictionaries as ownership edges. It
counts `MarkdownDocument`; every reachable `Block`, including reference-
definition, table, footnote, code, and HTML blocks; every otherwise implicit
`LeafBlock.Inline` container root; and every owned `Inline`, including
`LinkInline`, `AutolinkInline`, `HtmlInline`, `CodeInline`, and footnote links.
`TableColumnDefinition`, attached `HtmlAttributes`, line buffers, and other
non-owned metadata are not nodes. A reference-identity duplicate or cycle in
the purported ownership graph is `IntentInvalid`; it is never silently
deduplicated.

Structural traversal is document order: container-block index order, then a
leaf's inline root, then inline sibling order. Every derived protocol node is a
separate sibling attached directly to its narrowest containing structural AST
node; derived nodes never own or chain through one another merely because their
spans overlap. Those siblings are ordered after their containing structural
node by inclusive zero-based UTF-16 `SourceSpan` start, end, then the closed
ordinal kind `record`, `anchor`, `text-run`, `occurrence`. `SourceSpan.End` is
inclusive, so a non-empty span length is
`End - Start + 1`. Adjacent literal/entity text participating in one rendered
region is one maximal rendered-text run until a structural, authored-region,
or link-coverage boundary. A raw canonical `<a name=...></a>` is recognized
from the exact adjacent source-span sequence (normally two `HtmlInline` tag
nodes) and contributes one derived anchor node; it is not assumed to be one AST
node. The custom walker, not Markdig `Descendants()`, owns these counters
because that helper omits `LeafBlock.Inline` roots. Checked counters and the
supplied allowance are tested at equality and the first deterministic one-over.
Before inserting derived siblings, the walker assigns every structural node a
zero-based uint32 owned-walk ordinal in that exact order and one closed role
rank: `MarkdownDocument=0`, `Block=1`, synthetic `LeafBlock.Inline` root `=2`,
and owned `Inline=3`. Its stable structural locator is role rank, owned-walk
ordinal, and inclusive SourceSpan start/end; synthetic inline roots use their
owning LeafBlock's span. This locator, never CLR object identity or a dictionary
index, is the only AST-node identity consumed by later target proof framing.
Because Markdig has already allocated its AST when this protocol walk begins,
the Markdown parser reports but cannot preempt allocation at a semantic depth/
node one-over. The canonical input-byte ceiling and pinned package guards are
the pre-allocation bounds; no evidence may describe post-parse metering as an
allocation guard.

Input-ledger propagation is a family-declared row selection, never a blind
transitive union:

| Family | Exact prior rows selected before adding the local metered rows |
| --- | --- |
| Payload codec | The current binding's one rank-0 payload row; no prior semantic layer |
| Markdown parser | The input governed-text rank-0 payload row only |
| Repository-target Markdown parser | The input repository-target rank-0 payload row only |
| Repository-tree index | Repository-tree rank-0 payload and codec rank-2 rows for its exact input roots |
| Protocol-record index | Governed-text rank-0 payload and Markdown rank-2 rows for its exact input roots |
| Governed-reference index | Governed-text rank-0 payload plus Markdown and protocol-record rank-2 rows reachable from its exact inputs |
| Repository-target-resolution index | Repository-target rank-0 payload plus target-codec and target-Markdown-parser rank-2 rows, and every rank-2 row reachable through its exact governed-reference capability; shared target rows are selected once and no upstream governed-text payload row is selected |
| Demand projector | No prior row; it always adds one local rank-2 row that counts input views plus candidates. For a non-empty candidate set it also adds the positive generated-bytes row and positive CandidateCount rank-3 term; for zero candidates both zero-valued rows are omitted. |

The row selector is fixed by component family in Conformance and validated
against the manifest declaration; Policy cannot broaden it. Selected roots and
rows are structural, collision-checked, and canonicalized before local rows are
added. Intentionally non-selected input rows are ignored. A missing required
selected row, an unexpected extra row in the newly constructed output ledger,
or a family/component mismatch is `IntentInvalid`.

Before invoking a codec, parser, indexer, or demand projector, Conformance
selects and de-duplicates the family table's exact input-ledger/payload rows and
computes their aggregate `SelectedBaseline`. It then mints the authority-free
`SemanticResourceAllowance` from that baseline and the manifest aggregate
budget and places the allowance in the exact typed producer input. The
allowance exposes neither row identity, invocation digest, handle factory, nor
ledger mutation. Its `FitsLocal` calculation is exact: aggregate Bytes are
`baseline.Bytes + local.GeneratedBytes`; Nodes are `baseline.Nodes +
local.LayerNodes`; MaxDepth is `max(baseline.MaxDepth, local.LayerDepth)`; and
Complexity is `baseline.Complexity + local.GeneratedBytes + local.LayerNodes +
local.AdditionalComplexity`. A producer can therefore stop at the deterministic
one-over boundary without knowing or reconstructing private/transitive rows.

Budgets are conjunctive, and Complexity is derived rather than independent.
Equality for one counter is accepted only when every other counter also fits.
A declared MaxBytes, MaxDepth, or MaxNodes may therefore be intentionally
dominated by a lower MaxComplexity and need not be independently reachable.
A separate defense-in-depth ceiling may also be *schema-unreachable* when the
closed wire/AST/view grammar has a lower structural maximum. [TEST-0210](test-cases.md#test-0210) uses
three disjoint oracle classes: equality and first one-over for every *reachable
governing* counter; for every *algebraically dominated* scalar maximum, the
smallest canonical contribution that reaches that scalar and the earlier
governing counter it exhausts; and for every *schema-unreachable* scalar, the
closed grammar-derived maximum legal tuple below the ceiling plus rejection of
the first larger structural candidate by its schema/intent validator before
metering. The third class is not mislabeled as budget exhaustion and neither
unreachable class fabricates an impossible equality success. After each canonical contribution the check order is
Bytes, MaxDepth, Nodes, then Complexity, so a contribution that crosses more
than one limit has one deterministic governing rank. The repository-target
codec and target-Markdown parser maxima called out below are deliberately
non-dominated and retain their explicit byte/node equality oracles.

Every producer implements the exact typed
`ISemanticResourceMeter<TInput,TValue>` base shown above on that same manifest-
bound component object. After a successful producer intent and before any
handle, cache entry, plan state, or outcome is committed, Conformance calls
`MeasureLocal` with the same operation cancellation token, the exact same typed
producer input, and only the raw produced model/capability/candidate list. The
meter never receives the producer wrapper or its `ClaimedLocalUsage` and
therefore cannot satisfy the contract merely by echoing that scalar.

The meter returns an independently recomputed `SemanticResourceLocalUsage`.
Conformance compares it field-for-field with the product's claimed local usage,
converts the measured tuple to the rank-1/2/3 rows, combines those rows with its
already selected private baseline, and derives the aggregate with the
contribution algebra below. Only that Conformance-derived aggregate is stored in
sealed handles and compared with the manifest budget. Missing meter behavior or
a logical/CLR mismatch is `RegistrationMismatch`; negative, overflowing,
unequal, under-reported, or measured over-budget success is `IntentInvalid`: it
returned the wrong success union shape. A well-behaved component uses the same
allowance during production and returns its catalog-declared Rejected/Failed
intent at the first one-over boundary; Conformance never synthesizes references
or a semantic failure from a malformed success. The operation is atomic on
cancellation. This is independent runtime recomputation of producer scalars,
not a claim that Conformance can distrust the already envelope-verified Policy
artifact itself; semantic meter algorithms and boundary/golden vectors are
release-qualified by [TEST-0210](test-cases.md#test-0210).

For each successful producer invocation Conformance calls `MeasureLocal`
exactly once with that invocation's exact typed meter input/value/token. It never
calls the meter for a Failed/Rejected intent. The measured tuple contributes
only the new local rows; family-selected input-ledger rows are added separately
and are never re-reported by the meter. A malformed returned tuple, meter/
claimed-local mismatch, aggregate formula mismatch, or over-budget success is
`IntentInvalid` and
commits no cache entry, handle, plan state, or outcome. Cancellation remains
out of band and leaves the operation retryable; any other thrown meter/producer
exception is likewise an unexpected host failure and propagates unchanged. A declared budget failure is
memoizable only for codec/parser/index through the already specified cache
path; a projector failure is plan-local and a
meter-integrity failure is never memoized as a semantic result.

`ContextIndexInput.Derivations` is an invocation-scoped, Conformance-owned
capability. It is enabled only while `Build` is executing and is irrevocably
closed before `MeasureLocal` begins. Any derive call during metering is
`IntentInvalid` and mints no handle; a cancellation retry receives a fresh
input/factory. Thus the meter can inspect the typed input and product but cannot
create provenance, mutate the successful product, or expand authority.

The ledger makes “unique contributing” executable without double counting an
input that reaches an index both as a model and through an earlier capability.
Its contribution-kind ranks are payload bytes `0`, generated bytes `1`,
semantic layer `2`, and additional complexity term `3`. A payload row key is
exact qualified root plus payload schema; every other row key is ordered
qualified roots plus component key/version and the private collision-checked
invocation digest. Generated bytes cover deterministic component-created text
such as projector owner/object-ID demand fields without pretending it is an
admitted payload. Rows are canonical by kind rank and those structural keys. Exact-equal
keys with unequal roots/frame/usage are `CacheIdentityCollision`; otherwise a
union keeps one row. A payload/generated row has only non-zero Bytes, a
semantic-layer row has only MaxDepth/Nodes, and a complexity-term row has only
non-zero Complexity; the factories reject any other dimension shape. A zero
generated-byte or zero additional-
complexity contribution is represented by absence of that row, never by a
zero-valued rank-1/rank-3 row; the empty projector still has its depth-1 rank-2
layer. Bytes sum
the selected payload/generated rows, Nodes sum selected semantic-layer rows,
MaxDepth is their maximum (zero only for an empty ledger), and Complexity is
checked `Bytes + Nodes` plus selected rank-3 terms. Each initial component family selects precisely the input payload and
semantic layers named in the table, then adds its one local layer/term; aliases
copy row identity rather than minting work. Thus the governed-reference index
counts a shared Markdown root once when it arrives through both the Markdown
model and protocol-record capability, while the repository-target-resolution
index selects target payload bytes and paired target-Markdown nodes but may also
retain governed-reference semantic nodes. Different source
occurrences with equal bytes have different qualified roots and remain
distinct. When Conformance seals a codec binding/root, the first ledger has
exactly its one payload row and one codec semantic-layer row; this preserves
both canonical byte count and payload-structure nodes. Later Policy products
return only their producer-computable claimed local usage and immutable typed
product; they never see or invent private invocation digests or transitive
ledgers. Conformance alone composes the next ledger from the canonical input-
handle ledgers, manifest-declared component family, private invocation frame/
digest, product evidence handles, and independently metered local contribution,
then compares meter output with the local claim and validates aggregate key
closure, budget, and collision bytes before sealing the next handle. The contribution/
ledger factories are
therefore Conformance-owned in practice; friend access grants no minting
authority without the current private session/invocation stamp.
Capability/model inputs therefore retain their already validated usage/depth
metadata internally, and an index never reparses bytes to count them. The
schema algorithms define
`MatchPairs` and demand rows independently of collection/dictionary or sorting
implementation, making Complexity cross-OS and cross-implementation stable.

A writer/codec that would exceed a dimension returns the declared acquisition failure
`protocol.codec.resource-limit-exceeded` and no model. Parser/index/projector
exhaustion returns `SemanticFailureIntent` with
`protocol.budget.exhausted` and no partial product. Producers traverse their
schema-defined canonical order and check Bytes, MaxDepth, Nodes, then Complexity
after each deterministic contribution; the first would-be one-over value stops
the operation, except that the explicitly documented Markdig semantic walk can
stop only after its bounded parse has returned. Failure carries code/references
only, no partial usage or ledger.
The verified Policy artifact owns this fail-fast path using the exact supplied
allowance, and [TEST-0210](test-cases.md#test-0210) proves each reachable governing equality/one-over plus
each algebraic-dominance/first-governing-rank vector and each schema-unreachable
maximum/structural-rejection vector; only a success
reaches independent metering. A component returning negative, inconsistent,
under-reported, or over-budget claimed-local usage is `IntentInvalid`; a host timeout/cancellation is
never recast as budget exhaustion.

### Provider-neutral capability views

```csharp
public interface IEvidenceCapability { }

public interface IRepositoryTree : IEvidenceCapability
{
    IReadOnlyList<RepositoryEntryView> Entries { get; }
}

public interface IProtocolRecordIndex : IEvidenceCapability
{
    IReadOnlyList<ProtocolRecordView> Records { get; }
}

public interface IGovernedReferenceIndex : IEvidenceCapability
{
    IReadOnlyList<GovernedReferenceView> References { get; }
}

public interface IRepositoryTargetResolutionIndex : IEvidenceCapability
{
    IReadOnlyList<RepositoryTargetResolutionView> Targets { get; }
}

public sealed class QualifiedEvidenceHandle
{
    internal static QualifiedEvidenceHandle Create();
}

public sealed class RepositoryEntryView
{
    public string RepositoryRelativePath { get; }
    public RepositoryEntryKind Kind { get; }
    public QualifiedEvidenceHandle Evidence { get; }
    internal static RepositoryEntryView Create(
        string repositoryRelativePath,
        RepositoryEntryKind kind,
        QualifiedEvidenceHandle evidence);
}

public sealed class ProtocolRecordMemberView
{
    public string MemberKey { get; }
    public int Ordinal { get; }
    public QualifiedEvidenceHandle Evidence { get; }
    internal static ProtocolRecordMemberView Create(
        string memberKey,
        int ordinal,
        QualifiedEvidenceHandle evidence);
}

public sealed class ProtocolRecordView
{
    public string RecordKind { get; }
    public string RecordId { get; }
    public int Ordinal { get; }
    public QualifiedEvidenceHandle Evidence { get; }
    public IReadOnlyList<ProtocolRecordMemberView> Members { get; }
    internal static ProtocolRecordView Create(
        string recordKind,
        string recordId,
        int ordinal,
        QualifiedEvidenceHandle evidence,
        IEnumerable<ProtocolRecordMemberView> members);
}

public sealed class GovernedReferenceView
{
    public GovernedReferenceKind Kind { get; }
    public GovernedReferenceSyntax Syntax { get; }
    public GovernedReferenceResolution Resolution { get; }
    public string? OwningRepositoryIdentity { get; }
    public string? CommitObjectId { get; }
    public string? NormalizedTagName { get; }
    public string? CapturedSnapshotIdentity { get; }
    public string? NormalizedRepositoryRelativePath { get; }
    public string? NormalizedFragment { get; }
    public QualifiedEvidenceHandle Reference { get; }
    public QualifiedEvidenceHandle? Target { get; }
    internal static GovernedReferenceView Create(
        GovernedReferenceKind kind,
        GovernedReferenceSyntax syntax,
        GovernedReferenceResolution resolution,
        string? owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment,
        QualifiedEvidenceHandle reference,
        QualifiedEvidenceHandle? target);
}

public sealed class RepositoryTargetResolutionDemandItem
{
    public int ItemId { get; }
    public string OwningRepositoryIdentity { get; }
    public string? CommitObjectId { get; }
    public string? NormalizedTagName { get; }
    public string? CapturedSnapshotIdentity { get; }
    public string? NormalizedRepositoryRelativePath { get; }
    public string? NormalizedFragment { get; }
    internal static RepositoryTargetResolutionDemandItem Create(
        int itemId,
        string owningRepositoryIdentity,
        string? commitObjectId,
        string? normalizedTagName,
        string? capturedSnapshotIdentity,
        string? normalizedRepositoryRelativePath,
        string? normalizedFragment);
}

public sealed class RepositoryTargetResolutionView
{
    public QualifiedEvidenceHandle Reference { get; }
    public GovernedReferenceResolution Resolution { get; }
    public QualifiedEvidenceHandle ResolutionEvidence { get; }
    public QualifiedEvidenceHandle? Commit { get; }
    public QualifiedEvidenceHandle? Tag { get; }
    public QualifiedEvidenceHandle? Target { get; }
    internal static RepositoryTargetResolutionView Create(
        QualifiedEvidenceHandle reference,
        GovernedReferenceResolution resolution,
        QualifiedEvidenceHandle resolutionEvidence,
        QualifiedEvidenceHandle? commit,
        QualifiedEvidenceHandle? tag,
        QualifiedEvidenceHandle? target);
}
```

`QualifiedEvidenceHandle` is an opaque, sealed, zero-public-member token. It
does not implement a public interface and exposes no public constructor,
factory, equality member, value, conversion, or serializer surface. Object
reference identity is not a semantic or test oracle; only the minting sealed
input/kernel stamp and the kernel's private structural reference mapping give
it meaning.

The five immutable view types expose only normalized provider-neutral keys,
closed classifications, and `QualifiedEvidenceHandle` values. They expose no
raw text, snippet, content digest, provider DTO, provider `ObjectType`,
cursor, ETag, credential, or exception. `QualifiedEvidenceHandle` has no public
constructor or factory and is meaningful only inside the exact sealed input
that minted it.

The view classes also have no public construction or factory. Repository
entries are unique by normalized path and sorted path/kind/handle. Protocol
records are sorted kind/id/ordinal/handle; members are sorted
member-key/ordinal/handle, so duplicate semantic IDs or members remain visible
without ambiguous collection order. Governed references are sorted by their
sealed reference handle, kind/syntax/resolution, null-before owner/object/path/
fragment, with tag and capture between object and path, then null-before target;
Repository-target resolutions are sorted by their sealed
reference handle then resolution, resolution-evidence handle, null-before
commit, null-before tag, and null-before target. A duplicate
exact source handle is rejected. All
comparisons are ordinal and use the qualified-reference structural comparator
below, never input or dictionary order.

The governed-reference kind/resolution/nullability matrix is closed:

| Kind | Allowed `Resolution` values | `Target` |
| --- | --- | --- |
| `CrossRecord` | `Exact`, `WrongTarget`, `Unresolved`, `MissingFragment`, `WrongFragment`, `ExternalEvidenceRequired` | non-null for Exact/WrongTarget/ExternalEvidenceRequired and for fragment outcomes that prove the containing target; null for Unresolved |
| `EmbeddedRecord` | `Exact`, `WrongTarget`, `Unresolved`, `MissingFragment`, `WrongFragment`, `ExternalEvidenceRequired` | non-null except Unresolved |
| `Commit` | `WrongTarget`, `Unresolved`, `ExternalEvidenceRequired` | parsed link-target handle for WrongTarget/ExternalEvidenceRequired; null for Unresolved |

`WrongRepository` and `WrongObject` are final repository-target-resolution
outcomes and are invalid in `GovernedReferenceView`. Fragment outcomes outside
EmbeddedRecord are allowed for a CrossRecord Markdown heading or non-Markdown
line fragment. A
preliminary `Target` proves only the parsed link target, never historical Git
object/blob/fragment existence. The kernel validates this matrix before sealing
a capability.
`Clickable` and `NonClickable` may pair with any resolution allowed by the
kind table. `UnsupportedAuthoringForm` pairs only with `Unresolved`, has null
Target, and for Commit has a null owner/commit/tag/capture/path/fragment tuple. Any other
Syntax/Resolution/Target combination is invalid.

`ExternalEvidenceRequired` is the only projected preliminary state. It requires
`Clickable`, a non-null parsed `Target`, a canonical non-null repository
identity, and exactly one of these closed selectors:

- `CommitObject`: full SHA non-null and tag/capture null. Path may be null for a
  commit permalink or non-null for an immutable/current-ExactCommit blob;
  fragment requires path. CrossRecord and EmbeddedRecord both allow an optional
  fragment: exact target intent decides whether omission is a valid general
  blob target or `MissingFragment` after the blob is proven.
- `TagRoot`: normalized tag non-null and commit/capture/path/fragment null. The
  URI is exactly GitHub `/tree/<one canonical tag segment>` with no query,
  fragment, or suffix path. GitLab-style `/-/tree/...`, slash-bearing, or
  ambiguous tag names are outside schema 1 rather than guessed as a tree path.
- `CapturedSnapshotPath`: qualified capture identity, normalized path, and
  non-Markdown line fragment are non-null and commit/tag null. It is available
  only from an exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) capture-manifest mapping for a Candidate or
  CapturedEvidence scope; an opaque capture digest alone cannot mint it.

Kind and selector are a second closed union:

| `GovernedReferenceKind` | Allowed external selector |
| --- | --- |
| `Commit` | `CommitObject` with null path/fragment only |
| `CrossRecord` | `CommitObject` with non-null path and optional fragment; `TagRoot`; or `CapturedSnapshotPath` only for a current relative non-Markdown line target |
| `EmbeddedRecord` | `CommitObject` with non-null path and optional fragment; omission is retained so an existing exact blob can become `MissingFragment` |

`TagRoot` is never an EmbeddedRecord selector. `CapturedSnapshotPath` is never
Commit or EmbeddedRecord and is never minted for an absolute historical URL.
Any other Kind/selector/nullability combination is `IntentInvalid` before a
demand item exists.

Current relative no-fragment targets resolve from repository-tree evidence and
current Markdown fragments resolve from governed-text/Markdown evidence. Only
current relative non-Markdown line fragments project: ExactCommit uses
CommitObject with the qualified source owner/commit; Candidate/CapturedEvidence
uses CapturedSnapshotPath. A historical blob candidate depends only on its
canonical URL/path and qualified source owner, never on current-tree membership,
so a path deleted after the referenced commit remains resolvable. All non-
external preliminary views have a null owner/commit/tag/capture/path/fragment
tuple. An evaluator cannot treat
`ExternalEvidenceRequired` as a finding or a final exact result; RULE-0003,
RULE-0004, and RULE-0005 consume its final repository-target overlay.

Captured projection has one executable authority invariant. For a Candidate or
CapturedEvidence source,
`CapturedSnapshotIdentity` equals both the private structural record for
SourceReference's `EvidenceScope.Target.TargetIdentity` and that record's
`Boundary.BoundaryIdentity`; the value is the lowercase
64-hex SHA-256 of the exact verified immutable capture manifest, never of a
candidate string, route, or source body. `SourceReferenceResolutionAuthority`
is minted only from that source reference and the exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
capture-manifest entry. Its captured identity, normalized path, and expected
content identity are all non-null and equal that manifest entry; the expected
content identity is lowercase 64-hex SHA-256 of the captured file bytes. For
CommitObject and TagRoot all three captured-manifest fields are null. The
projector copies the expected content identity into the private candidate and,
when assigning ItemId, Conformance retains it in
`DemandReferenceAuthorityBinding` beside the exact source-reference and
source-authority handles. It is intentionally absent from the public demand
item and acquisition wire. The target index requires the binding for every row
and compares the self-consistent observed content identity with that retained
manifest expectation to choose `Exact` versus `WrongObject`; a missing, foreign,
or path/capture-inconsistent authority binding is `IntentInvalid`, not a guessed
resolution.

`RepositoryTargetResolutionView` is also closed. When the projected repository-
target slot is fully
admitted, the index emits exactly one view for every globally numbered demand
item and none otherwise. `Reference` equals the projector's private
`ItemId -> source QualifiedEvidenceHandle` entry; the same ItemId's private
source-authority handle must equal the retained authority map and is never
exposed by the public view. `ResolutionEvidence` is the
target payload row derivation (`protocol.node.repository-target-resolution`) and is
always non-null. A qualified authoritative Missing commit/tag/path row maps to `Unresolved`;
present rows may map to `Exact`, `WrongTarget`, `MissingFragment`,
`WrongFragment`, `WrongRepository`, or `WrongObject` by the exact wire rules.
`ExternalEvidenceRequired` is never a final target value. `Commit` is the same-row
derived `protocol.node.git-commit-object` proof whenever the requested commit
was proven exact, including a later missing/wrong blob or fragment. `Target` is
that Commit for exact commit-only demand, the proven blob for a blob demand
without a fragment or with MissingFragment/WrongFragment, and the exact derived
anchor/line proof for an exact fragmented blob. `Tag` is non-null only when the
exact requested tag ref and its terminal peeled commit are proven; an exact tag
root uses Tag as Target. A captured-snapshot resolution has null Commit/Tag;
once its exact file exists, MissingFragment/WrongFragment retains that captured-
file proof as Target and Exact replaces it with the exact line proof. Target is
null before the requested leaf exists and for WrongRepository/WrongObject.
Wrong or negative evidence remains honestly represented by
`ResolutionEvidence`. Item gaps,
duplicates, source-handle mismatch, or a resolution/nullability mismatch are
`IntentInvalid` and no partial capability is sealed.

The derivation topology is exact. `ResolutionEvidence` is a direct derived child
of the qualified target-model root. Commit, blob, captured-file, tag-ref, and
peeled-commit proof nodes are separate direct children of that result-row proof,
with node kinds `protocol.node.git-commit-object`,
`protocol.node.git-blob-object`, `protocol.node.captured-snapshot-file`,
`protocol.node.git-tag-ref`, and `protocol.node.git-peeled-commit`
respectively. A historical Markdown anchor is a direct
`protocol.node.markdown-anchor` child of its exact blob/captured-file proof; the
paired target-Markdown model and the narrowest containing structural AST node
are inputs to its identity, not alternate parents. A non-Markdown line target
is a direct `protocol.node.line-fragment` child of its exact blob/captured-file
proof. No parser-set root, AST node, peeled commit, or unrelated occurrence is
inserted into either public parent chain.

Every one of those derived calls uses this canonical identity frame; `bytes`
means uint32-be length plus exact bytes and `text` means uint32-be length plus
strict UTF-8:

```text
ASCII "protocol.repository-target-node-identity/1\n"
u8 node-kind rank:
  resolution-row=0, commit=1, blob=2, captured-file=3,
  tag-ref=4, peeled-commit=5, markdown-anchor=6, line-fragment=7
u32-be ItemId
bytes exact parent QualifiedEvidenceReference structural frame
bytes exact demand-item selector frame
bytes exact source-reference QualifiedEvidenceReference structural frame
bytes exact source-authority QualifiedEvidenceReference structural frame
u8 captured-authority-present; when 1:
  text captured manifest identity
  text captured manifest repository-relative path
  text manifest-expected content identity
node-specific tail
```

The tails are closed:

| Rank | Exact node-specific tail |
| --- | --- |
| resolution-row | Exact canonical result-row bytes through every wire outcome and `ContentOrdinal`, excluding raw content bytes but including the referenced canonical content key, byte length, and SHA-256 digest when present; then the exact computed final `GovernedReferenceResolution` token |
| commit | owner, requested commit, observed object type, observed object identity |
| blob | owner, requested commit, normalized path, observed blob identity, nullable ContentOrdinal |
| captured-file | owner, captured manifest identity, normalized path, manifest-expected content identity, observed content identity, ContentOrdinal |
| tag-ref | owner, normalized tag, observed ref name, observed ref object type, observed ref object identity |
| peeled-commit | owner, normalized tag, observed peeled object type, observed peeled object identity |
| markdown-anchor | canonical content key, content digest, byte length, normalized fragment, exact retained paired target-Markdown parser-model cache-key frame and its SHA-256 digest, containing structural locator `(role rank, owned-walk ordinal, inclusive UTF-16 SourceSpan start/end)`, anchor SourceSpan start/end, u8 active-anchor kind `heading-gfm=0`, `canonical-custom-name=1` |
| line-fragment | canonical content key, content digest, byte length, canonical line fragment, one-based inclusive start/end line |

The source-reference and source-authority frames are the exact private
`DemandReferenceAuthorityBinding` entry for ItemId. The captured-authority bit
is 1 exactly for CapturedSnapshotPath and its tuple must equal that binding;
CommitObject and TagRoot require bit 0. Consequently two otherwise equal
payload/result rows evaluated under different capture-manifest expectations
cannot share a resolution-evidence identity. Each textual tail field uses
`text`; each digest is exact 32 bytes; each
nullable ordinal is a presence byte followed by uint32-be when present; each
span/line integer is checked uint64-be. The exact public `TypedNodeIdentity`
grammar is `rt1:` + the invariant decimal node-kind rank + `:` + exactly 64
lowercase hex characters containing SHA-256 of the entire frame. Conformance retains the
entire frame privately. Equal identity digests over unequal frames are
`ReferenceInvalid`; a caller-supplied identity is never accepted.

All target-derived nodes begin at the qualified target-model root's Snapshot
location. Commit, tag, and peeled nodes retain Snapshot. Blob, captured-file,
anchor, and line nodes refine to Repository path/content/Anchor/Line only when
the qualified source-authority mapping proves both that the target owner equals
the source scope's repository owner and that the exact path belongs to that
same source identity. External-owner custody remains Snapshot; its target path,
content identity, fragment, and span/line stay cryptographically bound in the
node identity instead of being mislabeled as source-repository custody. This
location rule plus the parent and demand frames binds ref/tag peeling and
content/fragment relationships without manufacturing a handle by chaining
unrelated source occurrences.

Repository Markdown and issue, pull-request, review, and comment bodies decode
to the same source-text and Markdown capabilities and feed the same
`IGovernedReferenceIndex`. Their handles retain different sealed roots and
locations. Provider `ObjectType` remains owned by
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
and never appears in a rule declaration or evaluator branch.

### Exact expected-selector schemas

Expected selectors are pure Policy components. Conformance validates the
parent handle, obtains its safe typed-node canonical value from the private
qualified-reference map, and supplies that value through
`ExpectedSelectorInput`; Policy never inspects an opaque handle or raw payload.
Schema 1 admits exactly these algorithms:

| Schema | Exact parent and resolver algorithm | Exact `CanonicalValue` |
| --- | --- | --- |
| `protocol.selector.relative-child.v1` | Parent kind is Derived, its final typed-node kind is `protocol.node.repository-directory`, and its canonical value is one normalized repository-relative directory path from the repository-tree codec/index. `FeatureReadmeSelectorResolver` appends literal `README.md`; `FeatureTestCasesSelectorResolver` appends literal `test-cases.md`. Join uses one `/`, never `.`/`..`, backslash, URI decoding, case folding, or filesystem probing. | The resulting normalized repository-relative path, at most 4096 strict-UTF-8 bytes. |
| `protocol.selector.decision-record-by-id.v1` | Parent kind is Derived, its final typed-node kind is `protocol.node.governed-record-reference`, and its canonical value is exactly one `DEC-[0-9]{4}` target identity already parsed by the governed-reference index. `DecisionRecordSelectorResolver` copies that identity; it does not search text, infer the next number, or choose a path. | Exactly the same nine ASCII `DEC-NNNN` bytes. |

Any other parent kind/node kind/value, empty or over-budget value, noncanonical
path/ID, or resolver/schema mismatch is `ReferenceInvalid`. Zero or more than
one typed canonical value for a parent is `PlanStateInvalid`; input/dictionary
order never breaks ambiguity. The selector represents only the expected
identity for a proven-missing target. It creates no target root, location, or
existence assertion.

### Evaluator inputs and semantic intents

```csharp
public sealed class RuleApplicabilityInput
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public ExecutionProfile Profile { get; }
    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;
    public QualifiedEvidenceHandle GetContextProof(string slotKey);
    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
    internal static RuleApplicabilityInput Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        ExecutionProfile profile,
        IRuleInputAccess access);
}

public sealed class RuleEvaluationInput
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public ExecutionProfile Profile { get; }
    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;
    public QualifiedEvidenceHandle GetContextProof(string slotKey);
    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
    internal static RuleEvaluationInput Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        ExecutionProfile profile,
        IRuleInputAccess access);
}

public interface IRuleEvaluator
{
    ApplicabilityIntent EvaluateApplicability(
        RuleApplicabilityInput input,
        CancellationToken cancellationToken);
    EvaluationIntent Evaluate(
        RuleEvaluationInput input,
        CancellationToken cancellationToken);
}

public sealed class ApplicabilityIntent
{
    public ApplicabilityIntentKind Kind { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> References { get; }
    public static ApplicabilityIntent Applicable(
        IEnumerable<QualifiedEvidenceHandle> references);
    public static ApplicabilityIntent NotApplicable(
        IEnumerable<QualifiedEvidenceHandle> references);
    public static ApplicabilityIntent Unresolved(
        IEnumerable<QualifiedEvidenceHandle> references);
}

public sealed class FindingIntent
{
    public FindingCode Code { get; }
    public QualifiedEvidenceHandle PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }
    public static FindingIntent Create(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences);
}

public sealed class EvaluationFailureIntent
{
    public EvaluationFailureCode Code { get; }
    public QualifiedEvidenceHandle PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }
    public static EvaluationFailureIntent Create(
        EvaluationFailureCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences);
}

public sealed class EvaluationIntent
{
    public IReadOnlyList<FindingIntent> Findings { get; }
    public IReadOnlyList<EvaluationFailureIntent> Failures { get; }
    public static EvaluationIntent Create(
        IEnumerable<FindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures);
}
```

Inputs have no public construction and no untyped lookup. Each method rejects a
slot from the wrong rule or phase, a capability not declared for the slot, or a
foreign handle. The evaluator has no self-asserted RuleId, revision, evaluator
key, severity, remediation, or status; the manifest/export registration owns
those identities.

The kernel checks the operation token before each evaluator call and passes the
same token through. Evaluators must observe cancellation at their deterministic
bounded-work checkpoints and must not translate it into an applicability,
finding, or failure intent. A matching `OperationCanceledException` is
operational cancellation: the whole public call returns no semantic result and
no cache entry; another token or exception remains an unexpected host failure.

`ApplicabilityIntent` carries exactly one closed intent kind and a canonical
unique list of qualified handles. `Applicable` permits an empty list for a
catalog-universal rule; `NotApplicable` and `Unresolved` require at least one
qualified proof handle. `FindingIntent` carries only a declared
`FindingCode`, one primary handle, and canonical unique related handles.
`EvaluationFailureIntent` carries only a declared `EvaluationFailureCode`, one
primary handle, and canonical unique related handles. `EvaluationIntent`
contains ordered finding and failure intents. No intent contains a final
status, severity, remediation, arbitrary message, raw snippet, location/digest
pair, or report field.

Unknown or duplicate codes, a handle from another input/session, a disallowed
reference kind, or duplicate semantic
intent is a catalog/runtime integrity failure. It is not evidence failure and
cannot become `NotEvaluated`.

## Provider-neutral canonical payload wire contracts

The three schema-1 payloads use a protocol-owned persistent binary framing,
not JSON, a provider DTO, the private cache-key frame, or the future report
serializer. Shared primitives are:

These bytes are emitted only by the `Write` direction of the exact
manifest-bound codec component and decoded/qualified only by that same
component's `Qualify` direction. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) owns route and I/O plus the mapping
from a provider response to a closed `CanonicalPayloadWriteSource`; it owns no
header, rank, length, order, digest, or UTF-8 framing code. For every valid
write source, qualifying the writer-returned payload must recover the exact
provider-neutral semantic model represented by that source. Golden writer
bytes and writer-to-qualifier round trips are [TEST-0210](test-cases.md#test-0210) authority for both
directions; a second encoder in Application or a provider adapter is a project-
graph/API failure even if its bytes happen to match.

```text
u8          one byte
u32         unsigned 32-bit big-endian
i32/i64     signed big-endian
digest      exact 32 bytes
text        u32 byte length followed by strict UTF-8 bytes
bytes       u32 byte length followed by exact bytes
optional T  u8 0, or u8 1 followed by T
```

Text rejects a BOM, invalid/overlong UTF-8, surrogate encoding, trimming, or
Unicode/newline normalization. An unknown rank, invalid optional tag, numeric
overflow, premature EOF, length mismatch, or trailing byte rejects the payload.
The exact embedded `EvidenceScope` sequence is:

```text
text Target.SubjectIdentity
text Target.SourceIdentity
text Target.Surface.Value
text Target.SnapshotKind.Value
text Target.TargetIdentity
text Boundary.SnapshotKind.Value
text Boundary.BoundaryIdentity
i64 Boundary.StartedAtUtc UTC ticks
i64 Boundary.CompletedAtUtc UTC ticks
```

The following location immediately reuses that scope (structural equality is
required and the scope is not written twice), then writes one rank and tail:

```text
u8 rank: Repository=0, Provider=1, ReleaseAsset=2, Snapshot=3
Repository tail:
  text RepositoryRelativePath
  optional text BlobIdentity
  optional i32 Line
  optional text Anchor
  optional text Property
Provider tail:
  text ProviderServiceIdentity
  text ObjectType
  text StableObjectIdentity
  text VersionIdentity
  optional text Field
  optional i32 Line
  optional text Fragment
ReleaseAsset tail:
  text ReleaseObjectIdentity
  text Tag
  text AssetName
  digest AssetDigest
Snapshot tail:
  no fields
```

The embedded scope/location must equal the enclosing admitted
`EvidenceContext` and `EvidenceBinding.Location`; mismatch is
`protocol.codec.embedded-identity-mismatch`. Location leaf invariants remain
the accepted [SUBF-0153](README.md#subf-0153) invariants.

### `protocol.repository-tree` / `1`

```text
ASCII "protocol.repository-tree/1\n"
EvidenceScope
Location
u32 entry count
repeat in RepositoryRelativePath ordinal order:
  text RepositoryRelativePath
  u8 kind: Directory=0, File=1, SymbolicLink=2, GitLink=3
```

Surface is Repository and Location is Snapshot. Paths use the accepted
repository-relative path grammar and are unique. A structurally empty tree is
valid, but only a complete qualified inventory proof makes it authoritative.
For a Git tree, modes map exactly as `040000 -> Directory`,
`100644|100755 -> File`, `120000 -> SymbolicLink`, and `160000 -> GitLink`;
another/malformed mode rejects the tree. A symbolic link is inventory evidence
only: no codec/index/selector follows it or treats its target bytes as a regular
file. Every document/body selector, including feature README and test-cases,
requires the terminal repository-tree entry Kind to be exactly File; a
SymbolicLink/GitLink/Directory at that path is unresolved evidence, never file
presence.
One repository-tree instruction has exactly one payload binding; scope and
boundary bind the Git/candidate object version rather than repeating it per
entry.

### `protocol.governed-text` / `1`

```text
ASCII "protocol.governed-text/1\n"
EvidenceScope
Location
bytes Body
```

Each payload is exactly one governed body. Body bytes are BOM-free strict UTF-8
and otherwise byte-preserving; empty body is allowed. A Repository body uses a
Repository location with line/anchor/property null. A Provider body uses a
Provider location with non-null Field and null line/fragment. ReleaseAsset and
Snapshot locations are invalid. Bindings in one instruction are in the
accepted location comparator order. Completeness is proved only by the routed
EvidenceContext/receipt; it is never inferred from body count or contents.

### `protocol.repository-target-resolution` / `1`

```text
ASCII "protocol.repository-target-resolution/1\n"
EvidenceScope
Location
digest DemandDigest
u32 result count
repeat in exact demand ItemId order:
  u32 ItemId
  text OwningRepositoryIdentity
  u8 selector: CommitObject=0, TagRoot=1, CapturedSnapshotPath=2
  CommitObject demand:
    text CommitObjectId
    u8 path-present; when 1: text NormalizedRepositoryRelativePath
    u8 fragment-present; when 1: text NormalizedFragment
    u8 commit outcome: Missing=0, Present=1
    Present commit:
      text ObservedOwningRepositoryIdentity
      text ObservedObjectType
      text ObservedObjectIdentity
      when path-present:
        u8 path outcome: Missing=0, Present=1
        Present path:
          text ObservedRepositoryRelativePath
          text ObservedObjectType
          text ObservedObjectIdentity
          u8 content-present; when 1: u32 ContentOrdinal
  TagRoot demand:
    text NormalizedTagName
    u8 tag outcome: Missing=0, Present=1
    Present tag:
      text ObservedOwningRepositoryIdentity
      text ObservedRefName
      text ObservedRefObjectType
      text ObservedRefObjectIdentity
      text ObservedPeeledObjectType
      text ObservedPeeledObjectIdentity
  CapturedSnapshotPath demand:
    text CapturedSnapshotIdentity
    text NormalizedRepositoryRelativePath
    text NormalizedFragment
    u8 path outcome: Missing=0, Present=1
    Present path:
      text ObservedOwningRepositoryIdentity
      text ObservedCapturedSnapshotIdentity
      text ObservedRepositoryRelativePath
      text ObservedEntryKind
      text ObservedContentIdentity
      u32 ContentOrdinal
u32 unique content count
repeat ContentOrdinal 0..count-1 in canonical content-key order:
  u32 ContentOrdinal
  u8 owner kind: CommitObject=0, CapturedSnapshotPath=1
  text OwningRepositoryIdentity
  CommitObject key: text CommitObjectId; text path; text observed blob OID
  Captured key: text CapturedSnapshotIdentity; text path; text observed content identity
  u32 byte length
  digest SHA-256 of exact bytes
  exact bytes
```

Surface is Repository and Location is Snapshot. A non-empty repository-target
instruction has exactly one payload binding. Result count equals demand count,
and every row echoes its complete selector tuple byte-for-byte. The codec
recomputes DemandDigest from the exact demand frame; reordering, missing/extra/
duplicate rows, selector ambiguity, a wrong digest, or a demand not bound to
`CodecQualificationInput` is rejection. `Missing` is only an authoritative
qualified negative observation. Permission, rate limit, timeout, routing,
transport, capture incompleteness, or an unqualified source-snapshot mapping is
Failed/NoInput acquisition and can never be serialized as Missing.

CommitObject compares observed owner/type/id with the requested owner, literal
`commit`, and full SHA. A requested path then compares the observed path/type
with that path and literal `blob`. When content is present, the codec recomputes
`blob <byte-length>\0 || bytes` with the repository object format implied by the
40/64-hex commit identity and requires that digest to equal that same row's
`ObservedPathObjectIdentity`. A path-only exact blob has `content-present=0` and
needs no body; its qualified commit-tree/object lookup, not an impossible local
rehash, attests the path/OID pair. A non-null fragment requires
`content-present=1`. TagRoot requires exact ref name
`refs/tags/<NormalizedTagName>`; a lightweight ref has object type `commit`, an
annotated ref has type `tag`, and both must peel finitely to a terminal
`commit`. CapturedSnapshotPath requires exact qualified capture identity/path,
entry kind `file`, and a 64-hex observed content identity equal to SHA-256 of
the exact bytes. A present content row whose bytes disagree with its own
observed blob/content identity is self-inconsistent input and the codec rejects
the whole payload with `protocol.codec.invalid-repository-target-resolution`;
it is never an honest `WrongObject` view. `WrongObject` is reserved for a
structurally self-consistent observation that disagrees with the requested
commit/type, tag peel, or capture-manifest expected identity. Owner mismatch
maps WrongRepository; wrong observed path maps WrongTarget; an authoritative
missing commit/ref/path maps Unresolved.

The final comparison precedence is closed per wire variant. Within one row the
first applicable predicate wins:

| Wire variant | Ordered predicates -> final resolution |
| --- | --- |
| `MissingCommit`, `MissingTag`, `MissingCapturedPath` | The exact authoritative negative represented by that variant -> `Unresolved` |
| `PresentCommit` without requested path | owner differs -> `WrongRepository`; observed type is not `commit` or identity differs from requested commit -> `WrongObject`; otherwise -> `Exact` |
| `PresentCommitMissingPath` | owner differs -> `WrongRepository`; observed type/commit identity differs -> `WrongObject`; otherwise the exact requested path is authoritatively absent -> `Unresolved` |
| `PresentCommitPath` | owner differs -> `WrongRepository`; observed commit type/identity differs or the entry type is not `blob` -> `WrongObject`; observed path differs -> `WrongTarget`; otherwise apply the fragment row below |
| `PresentTag` | owner differs -> `WrongRepository`; observed ref name differs from `refs/tags/<requested>` -> `WrongTarget`; ref is neither a lightweight commit nor an annotated tag peeling finitely to the observed terminal commit -> `WrongObject`; otherwise -> `Exact` |
| `PresentCapturedPath` | owner differs -> `WrongRepository`; observed capture identity/entry kind differs or the self-consistent observed content identity differs from the retained manifest expectation -> `WrongObject`; observed path differs -> `WrongTarget`; otherwise apply the fragment row below |
| Exact blob/file fragment overlay | omitted fragment when the classified intent requires one -> `MissingFragment`; supplied fragment is noncanonical, absent, non-unique, invalid-text, zero/out-of-range line, or otherwise wrong -> `WrongFragment`; optional omission or exact unique anchor/line -> `Exact` |

The self-consistency rejection above precedes this semantic table and produces
no final view.

Content identity excludes fragment so multiple source occurrences and
fragments share one fetched body while retaining distinct ItemIds. Commit keys
order before capture keys, then owner, commit/capture identity, path, and
observed content identity ordinal. Every content row is referenced; every exact
fragment-bearing Present path references exactly one row; path-only commit
demands reference none. Equal keys/ordinals with unequal OID, digest, length, or
bytes are `CacheIdentityCollision`. Plan-global content hard bounds are exactly
64 unique keys, 1,048,576 bytes per content, and 16,777,216 aggregate unique
bytes. Writer/qualifier enforce per-content limits; Conformance enforces the
canonical union count/sum across all owner shards before parsing or indexing.
The complete canonical payload, including fixed/variable metadata and content,
has a separate per-instruction 33,554,432-byte retention ceiling. Independently,
the sum of complete canonical repository-target payload byte lengths across the
plan's owner shards is at most 67,108,864 bytes.

The three plan-global limit ranks are aggregate-admission limits, not per-shard
codec results. During `AdvanceEvaluation`, after validating every individual proof
candidate but before committing the projected aggregate Scope, ContextProof,
semantic model set, parser/index input, or either cache key, Conformance walks
the complete qualified target payloads in canonical instruction order and uses
checked arithmetic to add each content key and full payload length. Equality
succeeds. The first unique-content-count, aggregate-content-byte, or full-
payload-byte one-over produces the closed `projected-resource-failed` aggregate
outcome: Status `Failed`, null aggregate Scope/acquisition/ContextProof, and the
exact singleton aggregate failure
`protocol.codec.resource-limit-exceeded` for the projected slot requirement.
It does not relabel any independently valid owner-shard attempt; those attempt
rows retain their admitted kind/status/receipt and safe values. No partial
target-model set, target-Markdown model, parser/index product, or plan-local
cache entry is committed. Previously completed session cache entries remain
valid but grant no aggregate admission authority. The outcome tail binds the
limit rank, ceiling, checked would-be value, and first canonical instruction
whose addition crossed it, so concurrency cannot choose a different failure
identity.

Fragment content is decoded with strict UTF-8; BOM bytes decode as U+FEFF and
are not stripped. U+0000..U+0008, U+000B, U+000C, and U+000E..U+001F make a
non-text row. Line count is zero for empty text; otherwise it is the count of
CRLF, bare CR, or bare LF boundaries plus one unless the text ends in one of
those boundaries. A non-Markdown fragment is canonical only as
`L[1-9][0-9]*` or `Lstart-Lend` with the second `L`, checked 64-bit parsing,
`end >= start`, and `end <= lineCount`. Markdown paths compare the `.md`
extension ASCII-case-insensitively and use the same pinned parser/active-anchor
multiset as current governed Markdown. A supplied fragment against invalid text,
zero matching anchors/lines, a noncanonical line/anchor, or more than one
matching active anchor is WrongFragment; exactly one valid line/range or active
anchor is Exact. MissingFragment is reserved for an omitted required fragment.
An EmbeddedRecord with an omitted required fragment becomes MissingFragment
only after its exact blob exists. Invalid text is a typed historical-model row,
not a parser-wide host failure.

`RepositoryTargetMarkdownDocumentParser` emits one immutable set model for
every qualified target model. In canonical content-key order it includes one
entry for each referenced Present exact content whose path extension is `.md`
under ASCII case-insensitive comparison, and omits non-Markdown contents. An
entry is the closed `InvalidText` row or `ParsedMarkdown` row containing the
same pinned AST/source spans, protocol-owned GFM heading IDs, and active-anchor
multiset as the current Markdown parser. Strict UTF-8/C0 invalidity is data;
package/semantic budget exhaustion remains the declared parser failure. The set
model is present even with zero entries. Parent/binding/demand identity, content
key/order/digest/bytes, duplicate/gap closure, and exact one set model per target
model are checked before the target index; mismatch is `IntentInvalid` and no
partial model is sealed.

When every owner shard is Observed and qualified, the canonical ItemId union
across all repository-target models must equal the projector's complete
contiguous `0..n-1` map exactly. Models are ordered by instruction owner then
InstructionDigest before the one per-plan target index invocation. In that
all-Observed case a
duplicate/gap, foreign model, or row attributed to another source handle is
`AdmissionProofInvalid`. If any shard has a valid Failed/NoInput proof, the
target index is not invoked, no partial resolution capability is minted, and the
dependent slot/rule terminalizes `NotEvaluated`; the absent model row is then
expected evidence unavailability, not an integrity gap.

## Release schema registry and capability inventory

The qualification slice binds this exact provider-neutral producer graph:

| Kind / key / version | Exact component type | Inputs -> output | Per-instruction write retention `(bindings, bytes)` | Budget `(bytes, depth, nodes, complexity)` |
| --- | --- | --- | --- | --- |
| Schema `protocol.repository-tree` / `1` | `protocol.codec.repository-tree` / `1`; `MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec` | qualified canonical bytes -> model `protocol.model.repository-tree` / `1` | `(1, 16777216)` | `(16777216, 64, 200000, 2000000)` |
| Schema `protocol.governed-text` / `1` | `protocol.codec.governed-text` / `1`; `MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec` | qualified strict-UTF-8 body -> model `protocol.model.source-text` / `1` | `(200000, 67108864)` | `(4194304, 256, 500000, 5000000)` |
| Schema `protocol.repository-target-resolution` / `1` | `protocol.codec.repository-target-resolution` / `1`; `MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec` | qualified repository target/content proof -> model `protocol.model.repository-target-resolution` / `1` | `(1, 33554432)` | `(33554432, 64, 500000, 34054432)` |
| Parser `protocol.parser.markdown` / `1` | `protocol.parser.markdown` / `1`; `MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser` | per binding: source-text model `(1, 1)` -> model `protocol.model.markdown-document` / `1` | n/a | `(4194304, 256, 500000, 5000000)` |
| Parser `protocol.parser.repository-target-markdown` / `1` | `protocol.parser.repository-target-markdown` / `1`; `MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser` | per binding: repository-target model `(1, 1)` -> model `protocol.model.repository-target-markdown-document-set` / `1`; every `Produced` success has exactly one output even with zero Markdown contents; declared failure has none | n/a | `(33554432, 256, 1000000, 34554432)` |
| Index `protocol.index.repository-tree` / `1` | `protocol.index.repository-tree` / `1`; `MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex` | `PerContext`: repository-tree model `(1, 1)` -> capability `protocol.capability.repository-tree` / `1` | n/a | `(16777216, 64, 200000, 2000000)` |
| Index `protocol.index.protocol-record` / `1` | `protocol.index.protocol-record` / `1`; `MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex` | `PerContext`: Markdown model `(0, unbounded)` -> capability `protocol.capability.protocol-record-index` / `1` | n/a | `(67108864, 256, 1000000, 10000000)` |
| Index `protocol.index.governed-reference` / `1` | `protocol.index.governed-reference` / `1`; `MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex` | `PerPlan`: Markdown model `(0, unbounded)` + protocol-record capability `(1, unbounded)` -> capability `protocol.capability.governed-reference-index` / `1` | n/a | `(67108864, 256, 1000000, 10000000)` |
| Index `protocol.index.repository-target-resolution` / `1` | `protocol.index.repository-target-resolution` / `1`; `MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex` | `PerPlan`: repository-target model `(0, unbounded)` + repository-target-Markdown model `(0, unbounded)` + governed-reference-index capability `(1, 1)` -> capability `protocol.capability.repository-target-resolution-index` / `1`; exact one historical model per target model | n/a | `(67108864, 256, 2000000, 20000000)` |
| Projector `protocol.projector.repository-target-resolution-demand` / `1` | `protocol.projector.repository-target-resolution-demand` / `1`; `MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector` | per plan/slot/target: governed-reference-index capability `(1, 1)` plus Conformance-qualified source-reference authority map -> owner-sharded demand for repository-target-resolution slot | n/a | `(33554432, 64, 100000, 5000000)` |

The repository-target codec's 34,054,432 Complexity ceiling is its exact
33,554,432-byte plus 500,000-node maximum, so a parent at both declared
equalities is reachable and the first one-over fails in the matching dimension.
The target-Markdown parser's byte and complexity dimensions deliberately admit
a legal 33,554,432-byte parent payload at byte equality; independent depth/node
limits can still reject its parsed structure. Local `GeneratedBytes` is zero,
the aggregate Node ceiling is 1,000,000, and the Complexity ceiling is the
exact byte-plus-node maximum. Parser-node equality therefore succeeds and the
first one-over returns its declared `protocol.budget.exhausted` failure; payload
metadata is not double-counted as parser-generated bytes.

Every component type above uses assembly simple name
`MeAndAI.Protocol.Policy`; its full type name is shown. The four capability
identities bind respectively to `IRepositoryTree`, `IProtocolRecordIndex`,
`IGovernedReferenceIndex`, and `IRepositoryTargetResolutionIndex` in assembly
`MeAndAI.Protocol.Conformance.Abstractions`. No model is public. The exact
model and capability type components, all version `1`, are:

| Contract | Component key / exact full type / assembly |
| --- | --- |
| `protocol.model.repository-tree` | `protocol.type.model.repository-tree`; `MeAndAI.Protocol.Policy.Models.RepositoryTreeModel`; `MeAndAI.Protocol.Policy` |
| `protocol.model.source-text` | `protocol.type.model.source-text`; `MeAndAI.Protocol.Policy.Models.SourceTextModel`; `MeAndAI.Protocol.Policy` |
| `protocol.model.repository-target-resolution` | `protocol.type.model.repository-target-resolution`; `MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel`; `MeAndAI.Protocol.Policy` |
| `protocol.model.markdown-document` | `protocol.type.model.markdown-document`; `MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel`; `MeAndAI.Protocol.Policy` |
| `protocol.model.repository-target-markdown-document-set` | `protocol.type.model.repository-target-markdown-document-set`; `MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel`; `MeAndAI.Protocol.Policy` |
| `protocol.capability.repository-tree` | `protocol.type.capability.repository-tree`; `MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree`; `MeAndAI.Protocol.Conformance.Abstractions` |
| `protocol.capability.protocol-record-index` | `protocol.type.capability.protocol-record-index`; `MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex`; `MeAndAI.Protocol.Conformance.Abstractions` |
| `protocol.capability.governed-reference-index` | `protocol.type.capability.governed-reference-index`; `MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex`; `MeAndAI.Protocol.Conformance.Abstractions` |
| `protocol.capability.repository-target-resolution-index` | `protocol.type.capability.repository-target-resolution-index`; `MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex`; `MeAndAI.Protocol.Conformance.Abstractions` |

The manifest also has an exact four-row runtime artifact-anchor partition, all
component version `1`. These rows are never invoked as registrations and add no new
public type; they bind the already supported runtime types and the complete
assembly bytes that supply structural and kernel behavior:

| Component key | Exact full type / assembly / artifact file |
| --- | --- |
| `protocol.runtime.domain` | `MeAndAI.Protocol.Domain.RuleId`; `MeAndAI.Protocol.Domain`; `MeAndAI.Protocol.Domain.dll` |
| `protocol.runtime.conformance-abstractions` | `MeAndAI.Protocol.Conformance.Abstractions.PolicyQualificationSliceExport`; `MeAndAI.Protocol.Conformance.Abstractions`; `MeAndAI.Protocol.Conformance.Abstractions.dll` |
| `protocol.runtime.conformance` | `MeAndAI.Protocol.Conformance.CatalogIntegrityException`; `MeAndAI.Protocol.Conformance`; `MeAndAI.Protocol.Conformance.dll` |
| `protocol.runtime.markdig` | anchor type `Markdig.Markdown`; co-required API type `Markdig.Helpers.LinkHelper`; `Markdig`; artifact basename `Markdig.dll` |

The anchor identities are physically unique in the component graph. A runtime
anchor proves only the containing artifact identity; it is not a codec,
parser, index, evaluator, selector, activation proof, or admission proof.

The exact session cache budget is `(512 decode entries, 67108864 canonical
bytes, 128 index entries, 2000000 index nodes, 8 concurrent decode attempts,
4 concurrent index attempts, retain-lowest-canonical-keys)`.

The schema registry declares three admission proof contracts, version `1`:

| Contract | Kind / exact proof component | Surfaces / material roles |
| --- | --- | --- |
| `protocol.admission.observed` | `Observed`; `MeAndAI.Protocol.Application.Qualification.ObservedQualificationProof` in `MeAndAI.Protocol.Application` | Repository + Provider / repository-tree, governed-text, repository-target-resolution |
| `protocol.admission.failed` | `Failed`; `MeAndAI.Protocol.Application.Qualification.FailedAttemptProof` in `MeAndAI.Protocol.Application` | Repository + Provider / repository-tree, governed-text, repository-target-resolution |
| `protocol.admission.no-input` | `NoInput`; `MeAndAI.Protocol.Application.Qualification.NoInputRoutingProof` in `MeAndAI.Protocol.Application` | Repository + Provider / repository-tree, governed-text, repository-target-resolution |

The production activation contract is
`protocol.activation.release-envelope` / `1`, implemented by
`MeAndAI.Protocol.Application.PolicyActivationProof` in
`MeAndAI.Protocol.Application`. [TEST-0210](test-cases.md#test-0210) substitutes a manifest-bound friend
component in its own exact fixture envelope; it never changes a production
manifest or export.

The document-local producer graph derives unique producer tables for every model
and capability, but its node universe is exactly the payload-schema, semantic-
model-parser, context-index, and acquisition-demand-projector declarations.
Model and capability identities, slots, selectors, evaluators, proof contracts,
components, artifacts, and demand-frame schema tokens are not graph nodes.
Edges are prerequisite to dependent: model/capability producers point to every
consuming parser or index; the governed-reference capability producer points to
the repository-target projector; and that projector points to the output slot
requirement's repository-target-resolution schema producer. The exact graph has
ten nodes: three schema, two parser, four index, and one projector.

Roots are computed as producer nodes with indegree zero. The exact positive
ten-node successor roots are governed-text and repository-tree schemas; the
repository-target-resolution schema is projected and therefore is not a
successor root. Jointly removing the projector declaration and its component
removes that inbound edge, so the valid nine-node predecessor has governed-text,
repository-target-resolution, and repository-tree schema roots. For the
structurally unique union of every rule's applicability and evaluation slots,
validation seeds each slot's schema and capability producers, walks prerequisite
edges in reverse, and requires the union of all slot closures to equal all
producer nodes. Unresolved inputs, duplicate producer owners,
duplicate output-slot projector owners, ambiguous component-to-artifact owners,
self-edges, input/output identity collisions, cycles, or unreachable producers
fail. Kahn ordering uses component key/version, declaration key/version, then
family rank `Schema < Parser < Index < Projector` as its total ready-node
comparator. Every rule-slot capability must resolve to one producer.
The resulting codec/parser/index/demand-projector/selector/evaluator plus
model/capability type closure is the 27-row Policy logical producer/type-
contract manifest partition. ContractSlice A owns its exact declaration rows,
component identities, ordinal order, artifact mappings, DAG, reachability, and
the 35-row manifest union below; it makes no executable-registration claim.
ContractSlice C first requires that same 27-row partition to biject with the
export's six internal typed registration lists, model/capability type tokens,
and public `Components` projection. Missing, extra, duplicate, foreign, or
wrong-generic registration/type-token rows are `RegistrationMismatch`. Of
those rows, 23 implementations/types are in Policy and four capability-
interface identities are in Abstractions. The runtime
artifact-anchor partition is the exact four-row table above and must biject
with the loaded Domain, Abstractions, Conformance, and Markdig artifacts. The
activation-proof partition is the one exact
`ActivationProofContractDeclaration` component and must biject with the actual
activation-proof type/artifact. The admission-proof partition is the exact
`AdmissionProofContractDeclaration` component set and must biject with the
activated observed/failed/no-input proof types/artifacts. The four partitions
are component-key/type disjoint; one functional component identity cannot serve
two declaration roles across activation proof, admission proof, payload codec,
model type, parser, index, capability type, projector, selector resolver, or
evaluator. Their ordinal union must equal the manifest
`components` and component/artifact mappings exactly. No partition may absorb,
omit, or duplicate another. The initial production union is therefore exactly
35 component rows: 27 Policy registration/type-contract rows, four runtime
anchors, one activation proof, and three admission proofs.

The corresponding initial production artifact set is exactly
`MeAndAI.Protocol.Domain.dll`,
`MeAndAI.Protocol.Conformance.Abstractions.dll`,
`MeAndAI.Protocol.Conformance.dll`, `MeAndAI.Protocol.Policy.dll`,
`MeAndAI.Protocol.Application.dll`, and `Markdig.dll`. Every file is referenced
by at least one component and the proof verifies every byte of all six files.
The locked restore graph pins NuGet package `Markdig` exactly to `1.3.2` at
source commit
[`fc705234fa211d179ee1d5e7656b51ab99f70ca9`](https://github.com/xoofx/markdig/commit/fc705234fa211d179ee1d5e7656b51ab99f70ca9).
The only accepted
.NET 10 asset is `lib/net10.0/Markdig.dll`, length `493056`, SHA-256
`6231C6A7216466CBE7FDEAB7463A30ED29275CF90042BA64B49E1205D45E7EB5`, assembly
identity `Markdig, Version=1.3.0.0, Culture=neutral, PublicKeyToken=null`, file
version `1.3.2.0`, and product version
`1.3.2+fc705234fa211d179ee1d5e7656b51ab99f70ca9`. The loaded Policy references
for both `Markdig.Markdown` and `Markdig.Helpers.LinkHelper` must resolve to
that same verified Assembly object, never another target-framework asset or
load-context copy. Package lock/version, resolved identity, length, and digest
must all agree; shipped notices retain Markdig's BSD-2-Clause license. The
ContractSlice D qualification-mirror manifest replaces only the Application
proof-component rows/artifact with exact test-only friend proof types in
`MeAndAI.Protocol.Conformance.Tests.dll`; it retains the other five production
artifacts. ContractSlice C instead uses the exact five-file synthetic set and
Tests-owned semantic/proof substitutions declared above; B uses only its closed
codec subset of that Tests artifact. Every variant is private to [TEST-0210](test-cases.md#test-0210) and
cannot be used as a production manifest.

The common catalog owns only semantic material roles and target selectors:

```text
protocol.material.repository-tree
protocol.material.governed-text
protocol.material.repository-target-resolution

protocol.target.repository-snapshot
protocol.target.repository-governed-body-set
protocol.target.provider-governed-body-set
protocol.target.repository-target-resolution-set
```

Schema 1 closes target-selector semantics. The repository-snapshot,
repository-governed-body-set, and repository-target-resolution-set selectors each
resolve the one plan target whose Surface is Repository and whose SnapshotKind
equals the plan profile. The provider-governed-body-set selector resolves the
one plan target whose Surface is Provider and whose SnapshotKind equals the
profile. All plan targets already share one exact SubjectIdentity. Zero or more
than one predicate match is `PlanStateInvalid`; no input order, target ordinal,
adapter availability, or [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) choice breaks the tie. The kernel retains
the exact internal SlotKey-to-AcquisitionTarget mapping in the opaque plan.
Unknown selectors fail activation in schema 1.

It never owns an adapter key, source-contract key, provider object-type string,
pagination cursor, or permission. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
maps exact semantic slots to routes, coalesces same-contract requests, and
returns manifest-bound proof candidates. Missing or extra route mappings fail reconciliation.
Capability or authority denial is an attempted/unavailable acquisition and can
never be represented as semantic `Absent`.

### Topological dynamic acquisition demand

The schema registry owns acquisition demand projection as another pure Policy
component. The initial declaration is exact:

| Field | Value |
| --- | --- |
| Projector key/version | `protocol.projector.repository-target-resolution-demand` / `1` |
| Component | `protocol.projector.repository-target-resolution-demand` / `1`; `MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector` in `MeAndAI.Protocol.Policy` |
| Input capability | `protocol.capability.governed-reference-index` / `1` |
| Input slots | `protocol.slot.provider-governed-text`, `protocol.slot.repository-governed-text` in ordinal order |
| Output slot | `protocol.slot.repository-target-resolution` |
| Demand schema | `protocol.repository-target-resolution-demand` / `1` |
| Budget | `(33554432, 64, 100000, 5000000)` |
| Failure codes | `protocol.budget.exhausted` |

All active `InputSlotKeys` are readiness prerequisites, but aliased capability
handles are canonicalized to a unique union before projection. In the initial
graph both slot aliases resolve to the same one per-plan
`IGovernedReferenceIndex`; `DemandProjectionInput.Inputs` therefore contains
exactly one value whether one or both governed-text slots are active. Duplicate
alias delivery is `PlanStateInvalid`, not a second projector invocation.

The exact implementation is
`IAcquisitionDemandProjector<IGovernedReferenceIndex>`. It reads only the
immutable provider-neutral capability and Conformance's closed authority rows;
it has no raw body, adapter/provider DTO, route, credential, network,
filesystem, service provider, clock, or I/O. It emits one candidate for every
canonical view whose Resolution is `ExternalEvidenceRequired`, regardless of
reference Kind, and none for any other view. The candidate copies exactly one
CommitObject, TagRoot, or CapturedSnapshotPath selector plus the source-
reference and source-authority handles. Different source occurrences are never
collapsed even when their selector tuples are equal.

Before projection Conformance places two authority-free depth lists in the exact
`DemandProjectionInput<IGovernedReferenceIndex>` used by both `Project` and
`MeasureLocal`. The source-reference list has one
non-negative derivation count for every canonical input governed-reference view
in that view comparator order, including views that emit no candidate. Values
come only from Conformance's private qualified-handle map; the projector cannot
supply or change them, and the projection input exposes no derivation factory,
ledger, or handle-mint operation. The authority list has exactly one row for
every external-evidence view in that same relative order; the source-authority
depth list has the same count/order and contains each row's `AuthorityProof`
derivation count. Empty input has all three lists empty and meters depth 1;
otherwise MaxDepth is the maximum count in either depth list plus one.
Conformance requires source-handle equality, exact selector-
tuple equality, and `AuthorityProof` reachability from the source reference's
sealed lexical target or qualified snapshot/context proof. A captured selector
requires the exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) capture-manifest entry proof; a capture string or
source view alone cannot mint it. Count/order/reachability mismatch is
`IntentInvalid`. The projector cannot supply/change any list and receives no
derivation factory, ledger, or handle-mint operation.

Absolute schema-1 repository targets are the exact lowercase-`https` GitHub
families `https://github.com/<owner>/<repo>/commit/<full-sha>`,
`.../blob/<full-sha>/<normalized-path>[#fragment]`, and
`.../tree/<normalized-one-segment-tag>`. Authority is lowercase `github.com`
with no userinfo/port; owner/repository are non-empty canonical path segments;
the repository has no `.git` suffix. URI structure is split into path, query,
and fragment before any percent decoding; a query is forbidden. Percent escapes
use uppercase hex, never encode `/` or an unreserved character, and each path,
tag, or fragment component is decoded exactly once before its own validation.
An absolute GitHub schema-1 URL always uses a lowercase 40-hex SHA. A 64-hex
`CommitObjectId` exists only when independently derived from an already
qualified non-GitHub repository object format; it is never accepted in those
GitHub URL families. Blob paths use the accepted
[SUBF-0153](README.md#subf-0153) [repository-relative path grammar](subf-0153-evidence-contract-design.md#typed-location-family)
(`/` only, 1..4096 UTF-16 code units, with the declared empty/dot/dot-dot/
backslash/drive/control/NUL/ill-formed exclusions) and do not consult current-
tree membership. The schema-1 tag is one decoded Git-ref-safe
segment of at most 255 strict-UTF-8 bytes: no slash, control, space, `~`, `^`,
`:`, `?`, `*`, `[`, backslash, `..`, `@{`, leading dot, trailing dot, or
`.lock`; it is not single `@`. A tag URL has no suffix path or fragment.
`OwningRepositoryIdentity` is exactly
`https://github.com/<owner>/<repo>` with no trailing slash.

A current relative non-Markdown line link is not reparsed as an absolute URL.
For ExactCommit, Conformance derives owner/full SHA from the already qualified
source scope; for Candidate/CapturedEvidence it derives owner/capture identity
from the verified capture manifest. Current Markdown fragments and relative
no-fragment existence do not project. Every emitted field proves only canonical
selector syntax/provenance until the target-resolution payload is admitted; it
does not prove target existence.

Conformance sorts candidates by their source handle's qualified-reference
comparator and assigns globally contiguous `ItemId` values `0..count-1`. It
retains an internal exact `ItemId -> (SourceReference, SourceAuthority)` map,
then shards
the candidates by `OwningRepositoryIdentity` in ordinal owner order. The public
demand item contains only the global ordinal and closed selector tuple; proof
handles remain private. One dynamic
instruction contains exactly one non-empty owner shard; items retain global
ItemId order within the shard. The demand frame is:

```text
ASCII "protocol.acquisition-demand/1\n"
u8 demand kind: none=0, repository-target-resolution=1
u32-be item count
repeat for repository-target items in ItemId order:
  u32-be ItemId
  text OwningRepositoryIdentity
  u8 selector: CommitObject=0, TagRoot=1, CapturedSnapshotPath=2
  CommitObject:
    text CommitObjectId
    u8 path-present; when 1: text NormalizedRepositoryRelativePath
    u8 fragment-present; when 1: text NormalizedFragment
  TagRoot:
    text NormalizedTagName
  CapturedSnapshotPath:
    text CapturedSnapshotIdentity
    text NormalizedRepositoryRelativePath
    text NormalizedFragment
```

`text` is uint32-be byte length plus strict UTF-8 bytes. `none` requires zero
items; repository-target requires at least one, every item in that frame has
the same owner, and every nullable public tuple validates as exactly one closed
selector. SHA-256 of the exact frame is
`DemandDigest`. The exact demand-frame bytes are retained privately beside the
digest and public items; they are part of instruction identity even though the
instruction frame embeds only the digest. Equal demand digests over unequal
frames/items are `PlanStateInvalid` during planning and
`AdmissionProofInvalid` during qualification/admission. Static instructions
use the one canonical none digest/frame and an empty `DemandItems` list. Only
the repository-target output slot may carry a non-empty demand in schema 1.

The instruction frame is:

```text
ASCII "protocol.acquisition-instruction/1\n"
ManifestDigest exact 32 bytes
u8 phase: applicability=0, evaluation=1
u32-be RoundOrdinal
text SlotKey
text Target.SubjectIdentity
text Target.SourceIdentity
text Target.Surface.Value
text Target.SnapshotKind.Value
text Target.TargetIdentity
DemandDigest exact 32 bytes
```

SHA-256 of that frame is `InstructionDigest`. Every instruction in one plan
has the same non-negative RoundOrdinal. Every `EvaluationPlan` has at least one
instruction. An `ApplicabilityPlan` may instead have zero Slots and zero
Instructions exactly when the selected rules declare no active applicability
slot; it then closes only with an empty proof set and evaluates their
catalog-universal applicability. Conformance retains and compares both private
instruction-frame and nested demand-frame collision bytes as well as both
digests; equal digests over unequal frames are `PlanStateInvalid` while
planning and `AdmissionProofInvalid` while admitting. A candidate is admitted only for the exact issued
instruction object and current private plan stamp, so a deterministic digest
cannot be replayed across plans.

The two internal instruction factories derive both digests and never accept a
caller-supplied digest. `CreateApplicability` always writes phase Applicability,
RoundOrdinal `0`, and the none demand. `CreateEvaluation` writes phase
Evaluation, requires the current completed-round ordinal, and chooses none or
repository-target demand solely from its validated item list.

Plan `Slots` remain structurally unique. A static SlotKey has exactly one
instruction. The projected repository-target SlotKey may recur across
instructions only in
the same round/target and only as disjoint non-empty owner shards whose union
equals the projector's complete candidate set. Instructions are ordered by
SlotKey, target structural order, demand kind, owning repository identity, then
first ItemId; duplicate owner shards, item overlap/gap, or any other repeated
SlotKey is `PlanStateInvalid`.

At runtime, projection runs only after all active input slots and their declared
capability are terminal and qualified. One output slot has at most one
projector, and projected slots are evaluation-only. The manifest dependency
edges are the same document-local governed-reference-producer to projector and
projector to repository-target-resolution-schema-producer edges frozen above.
Unknown input/output slots or capabilities, duplicate output ownership, a
projected applicability slot, self-dependency, cycle, unreachable output, or a
rule path that demands the output before its inputs is document-local
`ParseCanonical` `FormatException`. ContractSlice A proves only the canonical
manifest bytes, typed projection, bindings, ownership, DAG, reachability, and
order; ContractSlice C first activates registrations and observes runtime
execution order.

A zero-candidate product emits no repository-target instruction, proof request,
external call, payload, codec invocation, or historical parser invocation. The
registered target index still runs exactly once with zero target models, zero
target-Markdown models, plus the qualified governed-reference capability and
produces the manifest-declared empty `IRepositoryTargetResolutionIndex`; its input
evidence/context proof supplies vacuous provenance. A non-empty product emits
exactly one repository-target instruction per distinct owner for the shared
slot/target. Schema 1 then requires one proof candidate, payload binding/target
model, and, for each successful target-Markdown parser invocation, exactly one
set model per instruction, followed by one shared per-plan target-index
invocation over both canonical model unions. A declared parser failure retains
its typed semantic failure, creates no set model, skips that shared index, and
terminalizes the dependent evaluation as `NotEvaluated`; it is not a pairing
integrity defect. A projector failure emits no dependent instruction and
terminalizes the dependent evaluation as `NotEvaluated`.

The instruction target remains the governed subject scope. Each item's
`OwningRepositoryIdentity` names the referenced object's custody repository
and may differ from Target.SourceIdentity for an external permalink; it is not
a nested EvidenceScope and cannot replace the instruction target. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
routes each owner-sharded instruction and binds provider/object-to-owner proof
in its receipt. One `AcquisitionRequest` therefore describes exactly one
owner-resolved adapter/source-contract route; it never pretends a multi-owner
batch used one route. Policy never maps an owner to an endpoint or credential.
The same commit/tag/capture/path tuple under different owners is a different
demand, and a caller cannot add an external item not derived from a qualified
source reference plus its exact private authority proof.

## Admission coordinator and proof boundary

The public joint seam deliberately exposes proof *candidates*, never trusted
receipts:

```csharp
public interface IAdmissionProofCandidate
{
    IReadOnlyList<string> SlotKeys { get; }
    string ContractKey { get; }
    string ContractVersion { get; }
    ExactSha256Digest ManifestDigest { get; }
    ExactSha256Digest InstructionDigest { get; }
    ExactSha256Digest ReceiptDigest { get; }
    AcquisitionRequest Request { get; }
}

public interface IObservedQualificationProof : IAdmissionProofCandidate
{
    ObservedAcquisitionResult Result { get; }
    IReadOnlyList<ComponentArtifactBinding> QualifiedCodecs { get; }
}

public interface IFailedAttemptProof : IAdmissionProofCandidate
{
    FailedAcquisitionResult Result { get; }
}

public interface INoInputRoutingProof : IAdmissionProofCandidate
{
}

public sealed class AcquisitionProofSet
{
    public IReadOnlyList<IObservedQualificationProof> Observed { get; }
    public IReadOnlyList<IFailedAttemptProof> Failed { get; }
    public IReadOnlyList<INoInputRoutingProof> NoInput { get; }
    public static AcquisitionProofSet Create(
        IEnumerable<IObservedQualificationProof> observed,
        IEnumerable<IFailedAttemptProof> failed,
        IEnumerable<INoInputRoutingProof> noInput);
}
```

`ReceiptDigest` is derived, never caller-selected. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)'s exact
`MeAndAI.Protocol.Application` proof implementation owns construction; the
Conformance admission coordinator independently reframes and compares it. The
frame starts with ASCII `protocol.admission-receipt.v1\n`, uses the tagged/
length framing primitives defined for cache keys, and then writes, in order:

```text
ManifestDigest
InstructionDigest
leaf-kind rank Observed=0, Failed=1, NoInput=2
ContractKey, ContractVersion
SlotKeys in canonical ordinal order
manifest-resolved proof component reference, artifact filename, artifact digest
AcquisitionRequest recursively in accepted public-property order
Observed: ObservedAcquisitionResult, then QualifiedCodecs in component order,
          then internal qualified-model contract/producer/binding,
          InstructionDigest, DemandDigest, exact DemandItems, and claimed-local
          GeneratedBytes, LayerDepth, LayerNodes, AdditionalComplexity
Failed:   FailedAcquisitionResult
NoInput:  no variant tail
```

Each qualified codec component/artifact pair must resolve exactly through the
same manifest; the manifest supplies its artifact digest. `QualifiedCodecs` is
the canonical unique component/artifact set ordered by component key/version,
not a per-binding multiset. The internal model rows remain binding-bijective,
and the distinct producer component/artifact projection from those rows must
equal `QualifiedCodecs` exactly. Their copied
instruction/demand digests and demand-item frames must equal the current issued
instruction and the codec input byte-for-byte; an equal digest with unequal
items/frame is rejected. Model object/AST bytes are not serialized. Application
can frame only the exact canonical payload, deterministic codec component and
artifact, model contract/type, binding, and producer-computable claimed-local
fields. Conformance has already measured those fields exactly once during
qualification before returning the closed state. Admission compares the receipt
claim with that retained measured tuple, revalidates and derives the private
ledger, and seals aggregate usage without invoking Policy or the meter again;
neither aggregate `Usage` nor ledger rows cross the proof-candidate boundary.
SHA-256 over this whole frame is `ReceiptDigest`. Any frame mismatch is
`AdmissionProofInvalid`; an equal digest over unequal framed bytes is also
rejected during receipt/admission validation. Codec cache lookup necessarily
precedes the post-qualification receipt and is independently collision-checked
against its pre-codec key bytes. The removed notion of a separate public envelope
digest is intentionally absent: `ManifestDigest`, exact verified artifact set,
proof component/artifact, and `Proves(...)` already form the activation
binding, while [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md) owns its outer release-plan/report serialization.

`AcquisitionProofSet.Create` accepts candidates but grants no authority. During
`CloseApplicability` or `AdvanceEvaluation`, the Conformance-owned admission coordinator
validates the exact proof implementation type and artifact against the
activated manifest, then mints internal observed/failed/no-input receipts. No
public receipt type or factory exists.

Activation first validates the manifest union, canonical projection, artifact
graph, schema DAG, and component graph without invoking code. It then requires
the activation proof contract/version and actual CLR proof type to equal the
manifest declaration, `ManifestDigest` to match, and `VerifiedArtifacts` to
equal every manifest artifact by filename/length/digest/order. Because the
manifest was already accepted by the predecessor-trusted release resolver,
only that exact non-publicly-created proof component may attest an export
instance. The export family, public logical projection, and internal ordinal
Policy registration/type-token graph must equal the manifest's 27-row Policy
registration/type-contract partition bijectively. Activation and admission
partitions and the four runtime artifact anchors are validated separately as
specified above; their union with Policy registrations must equal the full
35-row manifest graph. `Proves(policy)` binds the actual export instance and loaded
Assembly object to the proof's private verified-artifact map; assembly name,
MVID, or a self-asserted digest is insufficient.

For each admission call, candidates are enumerated once and must biject with
the exact issued `AcquisitionInstruction` list. Every schema-1 candidate has
the singleton `SlotKeys` list containing its instruction's SlotKey and echoes
that instruction's `InstructionDigest`. Nulls, duplicate object/receipt/
instruction identity, a candidate implementing zero or multiple leaf variants,
a non-singleton/wrong SlotKeys list, or a missing/extra candidate fails.
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) may coalesce transport work internally, but it must return one
separately framed proof candidate per instruction.

For each candidate, the kernel resolves exactly one admission declaration by
contract key/version and derived leaf kind; validates the actual CLR type,
component/artifact, allowed surface/material roles, unique receipt digest, and
activation-proof `Proves(candidate)` result; independently recomputes the
instruction frame/digest; and requires its Request's exact requirement set to
equal the one complete requirement declared by that instruction's slot. The
target must equal the instruction target and the plan's exact target-selector
resolution. Merely matching another same-surface target is insufficient.
Missing, extra, substituted, wrong-round, ambiguous, stale, partial, or
wrong-route input aborts the call atomically.

Admission is exact and variant-specific:

1. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) resolves routing and maps the singleton instruction/request response
   into one bounded write-source intent. The plan-bound Conformance service
   validates that intent and invokes the manifest codec writer exactly once for
   the binding. Source-intent or writer rejection yields an instruction-bound
   Failed proof; no structural Observed result or observed proof candidate exists,
   and neither qualifier nor the Observed-proof admission path is invoked. The
   separately framed Failed candidate is admitted normally. After a successful write, Application constructs the
   structural observed result around the returned payload and calls `Qualify`.
   Qualification invokes the paired codec exactly once per exact cache miss.
   Qualification rejection also yields a Failed proof with no Observed candidate.
   Only a qualified result becomes an observed proof candidate. That proof binds
   the instruction, request, source/provenance/freshness/completeness, payload/
   location coherence, deterministic codec budget, and activated codec artifact.
   Admission verifies the retained post-qualification state and reruns neither
   writer nor qualifier.
2. Failed proof binds its singleton instruction/slot, attempted request, interval,
   complete failure-code coverage, and proof that no valid partial context was
   produced. It admits a failed requirement, never a context.
3. No-input proof binds its singleton instruction/slot/request and proves both no
   input and no acquisition attempt. Only the kernel may synthesize semantic
   absence from it.
4. A caller-authored `AbsentAcquisitionResult`, forged proof, stale release,
   mismatched slot/request, partial receipt, duplicate proof, missing expected
   slot, extra proof, or wrong proof implementation is rejected.

Public Domain results remain structural untrusted carriers. Authority derives
from the activated exact route plus kernel validation, not from serialization,
interface implementation, constructor privacy, or an assertion inside the
proof candidate.

The stage classification is singular:

| Stage | Failure owner and result |
| --- | --- |
| Bounded source and canonical writer | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) submits the schema/scope/location-bound source intent; source rejection invokes no Policy, writer rejection invokes no qualifier, and either produces only an instruction-bound Failed proof |
| Codec qualification and embedded identity/location coherence | After one successful write [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) constructs the structural Observed result; the plan-bound service invokes the paired qualifier once per binding/cache miss, and declared rejection produces Failed proof with no Observed admission |
| Semantic model/Markdown parser over already qualified canonical input | Typed `RuleEvaluationFailure`; rule becomes `NotEvaluated` |
| Context/location indexer over qualified models and roots | Typed `RuleEvaluationFailure`; rule becomes `NotEvaluated` |
| Catalog/release/artifact/registration/intent/reference mismatch | `CatalogIntegrityException`; evaluation aborts |
| Host timeout or cancellation | Operational cancellation; no semantic result and no cache entry |

## Sealed context, references, and absence provenance

`SealedEvaluationContext` has no public constructor/factory and exposes only
safe release, catalog, schema, slot, and scope identities. It never exposes raw
payload bytes or a public context digest. The kernel maps internal
`QualifiedEvidenceHandle` values to one closed output reference family:

| Reference kind | Exact meaning |
| --- | --- |
| `ContextProof` | Whole qualified request/context and completeness/convergence proof, including a zero-binding complete context |
| `Root` | Admission-qualified projection of one [SUBF-0153](README.md#subf-0153) `RootEvidenceReference` |
| `Derived` | Exact root plus decoder/parser/index artifact and typed node/span with validated same-or-narrower location |
| `ExpectedSelector` | Allowed sealed parent plus catalog-owned expected selector for a missing path/member/record; never a fabricated root or location |

The exact public projections have no public constructor or factory:

```csharp
public sealed class SealedEvaluationContext
{
    public CatalogAuthorityKind AuthorityKind { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public CatalogVersion CatalogVersion { get; }
    public IReadOnlyList<string> AdmittedSlotKeys { get; }
    public IReadOnlyList<EvidenceScope> Scopes { get; }
}

public sealed class QualifiedEvidenceSelector
{
    public string SelectorKey { get; }
    public string SelectorSchemaKey { get; }
    public string CanonicalValue { get; }
}

public sealed class QualifiedEvidenceDerivation
{
    public ComponentTypeIdentity Component { get; }
    public string ArtifactFileName { get; }
    public ExactSha256Digest ArtifactDigest { get; }
    public ModelContractIdentity? OutputModel { get; }
    public CapabilityContractIdentity? OutputCapability { get; }
    public string TypedNodeKind { get; }
    public string TypedNodeIdentity { get; }
    public EvidenceLocation Location { get; }
}

public sealed class QualifiedEvidenceReference
{
    public QualifiedEvidenceReferenceKind Kind { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public CatalogVersion CatalogVersion { get; }
    public string SlotKey { get; }
    public string RequirementKey { get; }
    public EvidenceScope Scope { get; }
    public ExactSha256Digest QualificationProofDigest { get; }
    public RootEvidenceReference? Root { get; }
    public EvidenceLocation? Location { get; }
    public IReadOnlyList<QualifiedEvidenceDerivation> Derivations { get; }
    public QualifiedEvidenceReferenceKind? ExpectedSelectorParentKind { get; }
    public QualifiedEvidenceSelector? Selector { get; }
}
```

`QualifiedEvidenceDerivation` and `QualifiedEvidenceReference` have no public
constructor or factory. A derivation step's component/file/digest must equal
one manifest component/artifact binding; exactly one of `OutputModel` and
`OutputCapability` is non-null and equals the bound payload-codec output model,
parser output model, or index output capability for that exact component;
`TypedNodeKind` is an open namespaced token;
`TypedNodeIdentity` is one bounded opaque, well-formed UTF-16 identity; and its
location is same-or-narrower than the preceding root/step. The ordered,
non-empty derivation list is the exact codec/parser/index-produced typed
node/span path; it contains no raw content.

“Same-or-narrower” is the following closed relation. EvidenceScope must always
be structurally equal. A Snapshot leaf may remain the equal Snapshot or refine
to any schema-valid Repository, Provider, or ReleaseAsset leaf in that scope
when the manifest-declared component actually produced it. After a Repository
leaf, every later leaf is Repository with identical RepositoryRelativePath and
BlobIdentity; Line, Anchor, and Property may only remain equal or refine from
null to one valid contained value. After a Provider leaf, every later leaf is
Provider with identical ProviderServiceIdentity, ObjectType,
StableObjectIdentity, and VersionIdentity; Field, Line, and Fragment may only
remain equal or refine null to one contained value. A ReleaseAsset leaf can
only remain structurally equal, including object, tag, name, and digest. A
specific optional value can never be cleared or changed; no leaf can widen,
switch sibling path/object, or change family. Thus a repository-tree Snapshot
may refine to its exact entry path, and a governed-text Repository/Provider
root may refine to Markdown node line/anchor/fragment coordinates, while the
reverse transitions are invalid. Containment is checked against the qualified
typed parent model/index, never caller text or numeric range alone.

`ContextProof` has all four nullable projection fields null and an empty
derivation list. `Root` has an exact root and its exact location with an empty
derivation list. `Derived` has a root, a validated same-or-narrower location,
and at least one derivation; its top-level `Location` equals the final
derivation step's `Location` structurally. `ExpectedSelector` has a selector
and parent kind;
a ContextProof parent has no root/location/derivation, a Root parent has no
derivation, and a Derived parent retains its real root/location/derivation.
No expected target root or location is invented. The manifest-bound resolver
derives `CanonicalValue`; the evaluator can supply only an allowed sealed
parent handle, never a raw path/member/value.
`ExpectedSelectorDeclaration.AllowedParentKinds` may contain only
ContextProof, Root, and Derived; selector-on-selector nesting is invalid in
schema 1. The parent must also belong to the declaration's exact SlotKey, the
same rule, kernel/session, manifest, and catalog version. A handle from another
slot is `ReferenceInvalid` even when its typed-node kind/value happens to be
equal.

The in-memory reference comparator is, in order: manifest digest ordinal;
catalog version numeric; SlotKey; RequirementKey; accepted [SUBF-0153](README.md#subf-0153)
EvidenceScope tuple; kind rank ContextProof, Root, Derived, ExpectedSelector;
qualification proof digest; null-before parent kind; null-before root using the
accepted root/binding tuple; null-before location using leaf rank Repository,
Provider, ReleaseAsset, Snapshot and accepted leaf fields; derivations by
component key/version, artifact filename/digest, null-before output model,
null-before output capability, typed-node kind/identity, and accepted location;
null-before selector by selector
key/schema/value. Strings are ordinal; sequences compare elementwise with
shorter equal prefixes first. This is not a report stable key or digest. A
finding has exactly one primary reference and a canonical unique related list,
allowing link source, target, and repository-target-resolution proof to remain one finding
without raw content. The kernel validates primary and related kinds against
their distinct `FindingDeclaration` allowlists.

## Two-tier deterministic caches

Every cache is bounded to one exact activated release and evaluation session.
Eviction can affect only performance, never semantics or ordering.

The decode/model cache key is a tagged union. Every variant starts with exact
`AuthorityKind`, `ManifestDigest`, and numeric `CatalogVersion`; this is the
exact release/catalog identity. Its codec-model variant then contains:

```text
payload schema key and version
InstructionDigest plus exact private instruction-frame collision bytes
DemandDigest plus exact ordered DemandItems
exact structural AcquisitionRequest and EvidenceBinding identity
codec component and artifact digest
content digest and byte length
output model identity including implementation type
semantic resource budget
```

Its parser-model variant replaces the output-only tail with the parser key/
version/component/artifact digest, the ordered exact input model/capability
handle identities, the output model identity, and the parser semantic budget.
For `protocol.parser.repository-target-markdown`, that identity includes the
exact parent target-model handle, its canonical payload digest/byte length, and
the ordered input content-key/ordinal/digest/byte-length rows from the qualified
target model; the zero-content input is represented by an exact zero row count.
`ParsedMarkdown`, `InvalidText`, and the output set's zero/nonzero entry count
are parser results and are never cache-key inputs. They are retained in the
cache value, revalidated against that exact input content table on a hit, and
remain covered by the collision-checked output model identity. Thus lookup does
not duplicate parser semantics, and a target model can never pair with another
shard's or another plan's Markdown set.
Both variants retain the exact canonical bytes separately for the collision
check; those bytes are not duplicated into the sorted key frame.
The post-codec receipt digest does not exist at cache lookup time and is never
part of this key. It is framed and validated after qualification; a cache hit
still produces a fresh instruction/request-bound proof-state row and receipt.

The index cache key is the exact tuple:

```text
AuthorityKind, ManifestDigest, CatalogVersion
IndexInvocationScope
ordered exact structural contributing EvidenceContext values
ordered qualified parent root references
ordered exact input model and capability handle identities
index key and version
indexer artifact digest
semantic resource budget
tagged index auxiliary tail
```

The auxiliary tail is rank `0`/empty for every non-target index. It is rank `1`
only for the activation-guarded repository-target-resolution index and then
contains, in global ItemId order, the complete CommitObject/TagRoot/
CapturedSnapshotPath selector tuple, its mapped qualified source-reference and
source-authority structural handle identities, owning instruction/demand
digests, both retained instruction/demand collision frames, and, for a captured
selector only, the retained capture-manifest identity/path/expected-content
tuple. It also
contains the ordered owner-shard instruction list and exact target-model to
target-Markdown-set pair identities. Thus cache lookup replays the full
selector/source/authority correlation and can never reuse an earlier plan's
correlation under merely equal model/capability keys.

“Exact cache-key bytes” use one private framing schema,
`protocol.cache-key.frame.v1`. The frame begins with the exact ASCII schema
name plus LF, then a one-byte key-kind rank (`0` codec model, `1` parser model,
`2` context index), followed by fields in the tuple order above. Every field is
tagged and length-framed: null `0x00`; non-null `0x01`; UTF-8 string as
uint32-be byte length plus exact bytes; boolean as `0x00`/`0x01`; int32/uint32/
int64/uint64 as fixed-width big-endian; digest as its exact 32 bytes; list as
uint32-be count plus framed elements. A byte is one raw octet and a byte list is
the special-case uint32-be byte length followed by those raw bytes, not a list
of individually tagged integers. Text is never normalized. Zero-offset
`DateTimeOffset` is signed int64 UTC ticks.

Composite Domain/Abstractions values are recursively framed in the exact
public-signature property order; closed values use their exact token; closed
unions first write their declared variant rank; locations use Repository,
Provider, ReleaseAsset, Snapshot rank; model/capability/component identities
use their manifest field order. `EvidenceContext` includes every structural
request, requirement-acquisition, binding/payload/location, page, status, and
root-reference field; canonical collections are already in their accepted
order. Qualified handles/references use the exact comparator field order in
this design. This private frame is used only for cache equality, single-flight
order, and deterministic eviction; it is never persisted, reported, published,
or treated as [SUBF-0154](README.md#subf-0154) stable identity.

On a digest-key candidate hit, byte length and exact bytes are compared before
reuse. Same identity with different bytes is an integrity failure. A same-byte
document at another path/scope cannot reuse a relative-link or record index.
Thread-safe deterministic single-flight ensures one attempt per exact key.
Deterministic codec/parser/index success and their declared typed semantic
failure may be cached under the exact key family above.
Cancellation, host timeout, unexpected exception, and runtime integrity failure
are never cached. A cached parser/index semantic failure retains its canonical
session-qualified primary/related handles and exact failure frame. Reuse is
permitted only in the same Conformance session on byte-equal manifest,
component, invocation, context/root/location, and input-ledger key bytes; every
retained handle is revalidated against that live session map before projection.
No handle or location is reminted, rebound, or reused across another key,
context, session, or release. A missing/foreign handle or equal digest with
unequal failure bytes is an integrity failure rather than a cache miss.

Attempt budgets come from each component's `SemanticResourceBudget`; retention
and concurrency come only from `SessionCacheBudget`. Decode entry cost is exact
canonical byte count for codec/parser success or failure. Successful index entry
cost is its validated ledger Nodes. Failed index entry cost is checked unique
family-selected input-ledger Nodes plus one failure node, one primary-reference
node, and one node per related reference; it does not invent a product Usage.
These costs are never CLR heap size. After completion, eligible entries are sorted
by exact cache-key bytes and greedily retained only when both count and cost
ceilings remain satisfied; iteration continues after an oversized entry.
In-flight single-flight entries are not eviction candidates, excess work queues
in canonical key order, and plan-local results survive session-cache eviction.
Zero retention ceilings disable retention. Eviction can change reuse only, not
semantic output or order.

Demand projection has no session-cache key or retention entry. Its success or
declared failure is invoked at most once for the exact plan/output-slot/target,
single-flight shared only inside that invocation, and then committed as plan-
local state. It is never memoized across plans or under decode/index budgets.

Retention count/cost ceilings are non-negative and concurrency ceilings are
positive; all semantic attempt-budget fields are positive. Invalid or
overflowing arithmetic fails declaration construction/activation.

Canonical writing and codec qualification remain post-routing under one
Conformance-owned plan-bound service. Only qualification uses the shared
decode/model cache:

```csharp
internal abstract class ObservedEvidenceQualificationIntent
{
    private ObservedEvidenceQualificationIntent();
    internal static ObservedEvidenceQualificationIntent Qualified(
        IEnumerable<ICodecModelHandle> models);
    internal static ObservedEvidenceQualificationIntent Rejected(
        IEnumerable<AcquisitionFailure> failures);
    internal abstract TResult Accept<TResult>(
        IObservedEvidenceQualificationIntentVisitor<TResult> visitor);
}

internal interface IObservedEvidenceQualificationIntentVisitor<TResult>
{
    TResult VisitQualified(IReadOnlyList<ICodecModelHandle> models);
    TResult VisitRejected(IReadOnlyList<AcquisitionFailure> failures);
}

internal interface IPlanBoundEvidenceSession
{
    CanonicalPayloadWriteIntent WriteCanonicalPayload(
        AcquisitionInstruction instruction,
        CanonicalPayloadWriteSourceIntent source,
        CancellationToken cancellationToken);
    ObservedEvidenceQualificationIntent Qualify(
        AcquisitionInstruction instruction,
        ObservedAcquisitionResult result,
        CancellationToken cancellationToken);
}
```

This later union has exactly two private sealed nested CLR leaves,
`QualifiedCase` and `RejectedCase`; `Qualified`/`Rejected` remain the static
factory names. No friend can derive or add a third result shape.

`ApplicabilityPlan` and every `EvaluationPlan` expose their one internal
`EvidenceSession` instance only to the exact Application/Tests friends.
[FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) performs routing/I/O, maps each successful provider response through
an exact bounded write-source intent, obtains its canonical payload from this service, and
constructs the structural observed result around those returned payload
objects. It then calls `Qualify`; it never invokes a Policy codec directly and
never writes a protocol wire.

Before `WriteCanonicalPayload` can invoke Policy, the service proves the exact
instruction object/private frame belongs to the live unconsumed plan. A
SourceIntent Rejected schema key/version, scope, location, InstructionDigest,
and DemandDigest must match that instruction and source kind exactly, and its
code must belong to that schema's
`CodecFailureCodes`; the service converts it to the instruction-bound
CanonicalPayloadWriteIntent Rejected without invoking Policy or qualification.
That declared rejection terminal-fails the instruction write phase and discards
every previously retained source/write product for it. For SourceIntent Created, the
source Scope.Target and Location.Scope equal the instruction Target; its two
digests equal the instruction's exact retained frames; the
source leaf is the sole leaf allowed by the instruction slot schema; the next
binding count does not exceed `MaxBindingsPerInstruction`; static
instructions carry the canonical none demand; and a repository-target source
has exactly the instruction's owner-shard rows, ItemIds, complete selector
tuples, private source/authority plan bindings, retained demand frame, and
digest. It creates `CanonicalPayloadWriteInput`, resolves the
manifest codec registration through its generic visitor, and invokes that
paired writer exactly once. Conformance independently checks the returned
payload's schema/version, copied byte length, recomputed digest, byte budget,
and object identity. It uses checked arithmetic to add the exact canonical byte
count to the instruction's pending write set and retains the product only when
the result is at most `MaxRetainedCanonicalBytesPerInstruction`. A count one-
over is rejected before Policy invocation; a byte one-over can be known only
after the paired writer returns, is never retained, terminal-fails the whole
write phase, and discards all earlier products. The finite count ceiling bounds
writer invocations even on many-small inputs. The release-qualified paired Policy component and [TEST-0210](test-cases.md#test-0210)
golden/round-trip vectors own source-to-wire field mapping and deterministic
framing; Conformance does not duplicate the persistent encoder/decoder. The
later qualifier independently rejects malformed grammar and embedded scope/
location mismatch. A declared Policy writer rejection has the same atomic
terminal-failure/discard behavior. Rejected contains only catalog-declared failures.
Writing is deliberately not cached and never mints a model or evidence proof.
Call order is irrelevant: successful outputs are canonicalized by the accepted
source/location comparator, an exact duplicate source/write is invalid, and
qualification consumes the complete retained set exactly once.
Once an instruction write phase terminal-fails, later writes and `Qualify` are
rejected without Policy work; only its separately framed Failed proof candidate
may consume that state through normal admission. Cancellation or host failure
retains no product for the current call but preserves earlier completed products
and permits the exact same binding to retry. No declared rejection can expose a
partial retained set.
`CanonicalPayloadWriteIntent.Rejected` ends the observed path: Application
creates the instruction-bound Failed proof and must not call `Qualify`.

Before `Qualify` performs any cache lookup or codec work, the service proves the exact
instruction object/private frame belongs to that live unconsumed plan; the
result/context Request is structurally identical and its Target equals the
instruction Target; RequestedRequirements is the exact singleton structural
slot Requirement; Scope.Target equals that target; every binding contributes
to that requirement, has its exact schema key/version, and bijects the complete
successfully retained writer-output set object-identically and in exact source
structural binding/location order; static instructions
carry the canonical none demand; repository-target instructions carry exactly one binding
and the exact retained demand-frame bytes/items/digest for their owner shard;
and result/context/binding scope-location coherence satisfies [SUBF-0153](README.md#subf-0153). An
omitted, duplicated, reordered, foreign, or orphaned write product, a prior
Rejected write attempt, or any other mismatch, is immediate `AdmissionProofInvalid`, produces no qualification
intent/proof, cache entry, or codec invocation. At this stage
`ObservedEvidenceQualificationIntent.Rejected` is reserved only for a declared
codec qualification failure over structurally coherent, complete retained
writes. Only then the service
constructs the exact `CodecQualificationInput`, resolves the manifest registration through its
generic visitor, owns single-flight/cache accounting, and returns the canonical
closed qualification intent. Qualified carries canonical model handles in
binding order and Application copies them into its observed proof state.
Rejected carries the canonical declared `AcquisitionFailure` list and
Application produces a Failed proof with no observed context/model state.
Cancellation, timeout, and unexpected host failure remain out of band.
Admission validates successful handles without rerunning the writer or codec.
Thus codec and parser entries share the one session cache/budget/eviction
authority claimed above; no persistent-wire encoder, cache, or semantic decoder
exists in Application. The same manifest codec component/artifact therefore
owns both persistent encoding and qualification, while Conformance owns live
instruction binding, dispatch, cache, sealing, and admission.

## Two-phase applicability and evaluation API

A one-shot `Evaluate(ExecutionProfile, context)` API is prohibited. Both kernel
families enforce this exact state sequence:

```csharp
public sealed class CatalogSliceKernel
{
    public static CatalogSliceKernel Activate(
        FinalizedPolicyManifest manifest,
        PolicyQualificationSliceExport policy,
        IPolicyActivationProof activationProof);

    public ApplicabilityPlan PlanApplicability(
        ExecutionProfile diagnosticProfile,
        IEnumerable<AcquisitionTarget> targets);
    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default);
    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default);
    public EvaluationAdvanceResult AdvanceEvaluation(
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default);
    public CatalogSliceEvaluation Evaluate(
        EvaluationClosure closure,
        CancellationToken cancellationToken = default);
}

public sealed class ConformanceKernel
{
    public static ConformanceKernel Activate(
        FinalizedPolicyManifest manifest,
        CompletePolicyPackExport policy,
        IPolicyActivationProof activationProof,
        CompleteCatalogSnapshot? predecessor);

    public CompleteCatalogSnapshot Catalog { get; }
    public NamedExecutionProfile ResolveNamedProfile(string name);
    public ApplicabilityPlan PlanApplicability(
        NamedExecutionProfile profile,
        IEnumerable<AcquisitionTarget> targets);
    public ApplicabilityClosure CloseApplicability(
        ApplicabilityPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default);
    public EvaluationAdvanceResult PlanEvaluation(
        ApplicabilityClosure closure,
        CancellationToken cancellationToken = default);
    public EvaluationAdvanceResult AdvanceEvaluation(
        EvaluationPlan plan,
        AcquisitionProofSet proofs,
        CancellationToken cancellationToken = default);
    public CompleteCatalogEvaluation Evaluate(
        EvaluationClosure closure,
        CancellationToken cancellationToken = default);
}

public sealed class CompleteCatalogSnapshot
{
    public string ProtocolVersion { get; }
    public CatalogVersion CatalogVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest CompleteInventoryDigest { get; }
    public CatalogPredecessorBinding Predecessor { get; }
    public string BaselineProfileName { get; }
    public IReadOnlyList<RuleDeclaration> Rules { get; }
    public IReadOnlyList<NamedProfileDeclaration> NamedProfiles { get; }
}

public sealed class NamedExecutionProfile
{
    public string Name { get; }
    public ExecutionProfile Axes { get; }
    public IReadOnlyList<RuleId> RuleIds { get; }
}

public sealed class AcquisitionInstruction
{
    public EvidenceSlotDeclaration Slot { get; }
    public AcquisitionTarget Target { get; }
    public int RoundOrdinal { get; }
    public IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    public ExactSha256Digest DemandDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    internal static AcquisitionInstruction CreateApplicability(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target);
    internal static AcquisitionInstruction CreateEvaluation(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        int roundOrdinal,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems);
}

public sealed class SealedAcquisitionAttempt
{
    public AcquisitionInstruction Instruction { get; }
    public AdmissionProofKind AdmissionKind { get; }
    public AcquisitionStatus Status { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public EvidenceScope? Scope { get; }
    public RequirementAcquisition? RequirementAcquisition { get; }
    public IReadOnlyList<AcquisitionFailure> Failures { get; }
}

public sealed class SealedAcquisitionOutcome
{
    public EvidenceSlotDeclaration Slot { get; }
    public AcquisitionTarget Target { get; }
    public AcquisitionStatus Status { get; }
    public bool IsProjected { get; }
    public ExactSha256Digest OutcomeDigest { get; }
    public EvidenceScope? Scope { get; }
    public RequirementAcquisition? RequirementAcquisition { get; }
    public QualifiedEvidenceReference? ContextProof { get; }
    public IReadOnlyList<SealedAcquisitionAttempt> Attempts { get; }
    public IReadOnlyList<AcquisitionFailure> Failures { get; }
}

public sealed class ApplicabilityPlan
{
    public CatalogAuthorityKind AuthorityKind { get; }
    public ExecutionProfile Profile { get; }
    public IReadOnlyList<AcquisitionTarget> Targets { get; }
    public IReadOnlyList<RuleId> RuleIds { get; }
    public IReadOnlyList<EvidenceSlotDeclaration> Slots { get; }
    public IReadOnlyList<AcquisitionInstruction> Instructions { get; }
    internal IPlanBoundEvidenceSession EvidenceSession { get; }
}

public sealed class ApplicabilityClosure
{
    public ApplicabilityPlan Plan { get; }
    public SealedEvaluationContext Context { get; }
    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }
    public IReadOnlyList<RuleEvaluation> TerminalEvaluations { get; }
}

public abstract class EvaluationAdvanceResult
{
    private protected EvaluationAdvanceResult(int completedRoundCount);
    public int CompletedRoundCount { get; }
}

public sealed class EvaluationPlan : EvaluationAdvanceResult
{
    public ApplicabilityClosure Applicability { get; }
    public IReadOnlyList<EvidenceSlotDeclaration> Slots { get; }
    public IReadOnlyList<AcquisitionInstruction> Instructions { get; }
    internal IPlanBoundEvidenceSession EvidenceSession { get; }
}

public sealed class EvaluationClosure : EvaluationAdvanceResult
{
    public ApplicabilityClosure Applicability { get; }
    public SealedEvaluationContext Context { get; }
    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }
    public IReadOnlyList<RuleEvaluation> TerminalEvaluations { get; }
}

public sealed class CatalogSliceEvaluation
{
    public CatalogSliceDeclaration Catalog { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExecutionProfile Profile { get; }
    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }
    public IReadOnlyList<RuleEvaluation> Evaluations { get; }
    public bool HasKnownViolation { get; }
    public bool HasUnresolvedRequiredEvaluation { get; }
}

public sealed class CompleteCatalogEvaluation
{
    public CompleteCatalogSnapshot Catalog { get; }
    public NamedExecutionProfile Profile { get; }
    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }
    public IReadOnlyList<RuleEvaluation> Evaluations { get; }
    public bool HasKnownViolation { get; }
    public bool HasUnresolvedRequiredEvaluation { get; }
    public ConformanceVerdict Verdict { get; }
}

public sealed class CatalogIntegrityException : InvalidOperationException
{
    public CatalogIntegrityCode Code { get; }
}
```

`AcquisitionInstruction` and every type from it through the second half of the
block have no public constructor or factory. `ApplicabilityPlan.Instructions`
contains exactly one row per `Slots` row, sorted by SlotKey, and each row pairs
that exact structural slot with the target produced by its declared selector.
`EvaluationPlan.Slots` is also structurally unique: every static slot has
exactly one instruction, while the projected repository-target slot has one or more
owner-sharded instructions under the exact multiplicity/order rules above.
The kernel-proven empty repository-target demand creates no EvaluationPlan row at all.
The plan's target/slot/instruction projections are therefore the complete
provider-neutral acquisition instructions; the pairing is not hidden private
state and is not caller-created. [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) translates each exact requirement/
material/resolved-target tuple into an adapter/source-bearing
`AcquisitionRequest`; admission then proves that translation exactly.
Plans, closures, snapshots, profiles, and results additionally carry an opaque
internal kernel/session stamp.

`CatalogSliceEvaluation.Catalog` is the exact activated qualification-slice
declaration object and `ManifestDigest` is the exact activated manifest digest;
both are minted from the same kernel/session stamp as the closure. They make a
standalone slice result release/slice-identifiable even when its acquisition
and evaluation lists are empty. A caller-supplied equal-looking declaration,
another manifest, or another kernel stamp cannot be substituted. The complete
result obtains the same self-contained identity through
`CompleteCatalogEvaluation.Catalog`.

`EvaluationAdvanceResult` is a return-family base, not an authority token. The
only authoritative exact runtime types are the sealed kernel-minted
`EvaluationPlan` and `EvaluationClosure`, each carrying the current private
session stamp. A friend-defined derived base value may be expressible under the
CLR friend/access rules but is never returned by a kernel and no kernel method
accepts it; any attempted substitution is `PlanStateInvalid`. [TEST-0210](test-cases.md#test-0210) checks
the exact runtime-type allowlist and stamp rather than claiming the public
hierarchy is CLR-unextendable.

Every plan/closure carries an opaque kernel/session identity. Cross-kernel,
cross-release, cross-profile, stale, repeated, skipped-phase, or modified plan
use fails integrity validation.

Static selection and dynamic applicability are separate:

1. A catalog slice uses a caller-created `ExecutionProfile` only for
   diagnostic qualification and can return only a slice result. It selects a
   rule exactly when SubjectRole, Operation, and SnapshotKind are declared and
   profile Surfaces intersect rule Surfaces; EnforcementPhase never changes
   baseline semantics.
2. A complete kernel resolves an immutable release-declared
   `NamedExecutionProfile`. The caller cannot narrow its rule or evidence set.
3. Targets are enumerated once, structurally unique, share one SubjectIdentity,
   SnapshotKind, and TargetIdentity, and equal the canonical unique target-
   selector resolutions for every potential profile-filtered applicability,
   evaluation, or projected slot; an unused extra target is invalid. Slot
   `ProfileSurfaces` is a profile-activation predicate, not the required
   evidence Target.Surface. A Provider profile may therefore require a distinct
   Repository support target with the same SubjectIdentity/SnapshotKind/
   TargetIdentity and `SourceIdentity == SubjectIdentity`, alongside its
   Provider body target. This support target resolves repository governed-text
   and repository-target-resolution slots; it does not add Repository to the
   profile axes.
   `PlanApplicability` unions applicability slots whose ProfileSurfaces
   intersect the current profile for every selected rule. Shared structurally
   equal slots are acquired once.
4. `CloseApplicability` admits those slots and obtains exactly one
   `Applicable`, `NotApplicable`, or `Unresolved` intent per selected rule.
5. Proven false creates referenced, zero-finding, zero-failure
   `NotApplicable`; it activates no evaluation-only slot.
6. Proven true activates exactly that rule's evaluation slots whose
   `ProfileSurfaces` intersect the current profile. An out-of-profile slot is
   neither acquired nor unresolved and is unavailable through the rule input.
7. Missing, failed, unqualified, model/index-failed, or semantically unresolved
   applicability creates `NotEvaluated`, never `NotApplicable`.
8. `PlanEvaluation` reuses already admitted shared slots, runs the pure
   currently-ready producer DAG to a fixed point, and returns either the first
   non-empty `EvaluationPlan` or a zero-round `EvaluationClosure` when no
   external acquisition remains.
9. `AdvanceEvaluation` admits one plan's exact proof set, consumes that plan
   exactly once, advances codec/parser/index/projector nodes to the next fixed
   point, and returns either the next non-empty plan or a ready closure.
10. `Evaluate(EvaluationClosure)` accepts no proof, performs no acquisition,
    codec, parser, index, or demand projection, and invokes only the selected
    rule evaluators plus aggregation over the sealed ready closure.

`EvaluationAdvanceResult.CompletedRoundCount` is zero before any evaluation
plan is consumed and increments by exactly one per successful
`AdvanceEvaluation`. Every instruction in a plan has `RoundOrdinal` equal to
that plan's completed-round count. Empty `EvaluationPlan` values are never exposed. The general
contract permits deterministic zero, one, or N acquisition rounds; the initial
schema-1 graph has at most one static evaluation round followed by at most one
dynamic repository-target-resolution round.

The general N-round contract has a finite progress measure. A projector may run
at most once for each `(session, output SlotKey, resolved target)`; a terminal
or admitted output is never projected again. Every successful Advance consumes
one previously unconsumed acquisition layer and either increases the set of
terminal producer-DAG nodes or returns the closure. The upper bound is one
static external-acquisition layer plus the finite count of reachable projected-
output layers in the activated acyclic manifest. Repeated demand, a second
projector invocation, or a successful-looking step with no strict progress is
`PlanStateInvalid`.

Every plan/closure carries the exact predecessor state stamp as well as the
kernel/session stamp. Reuse, skipped or reordered rounds, a proof from another
instruction/plan, a next-plan advanced from the wrong predecessor, or a
closure evaluated twice is `PlanStateInvalid`. A Failed/NoInput or semantic
producer failure prevents dependent projectors from running and terminalizes
only the dependent rule/slot as `NotEvaluated`. Applicability has no projected
slot in schema 1 and `CloseApplicability` remains a single acquisition round.

All state-consuming calls use an atomic prepare/commit boundary. A plan or
closure becomes consumed only when its public call returns successfully.
Matching cancellation, timeout, or unexpected host failure publishes no
partial plan/closure/result, handle, admission row, or new cache entry and
leaves that predecessor retryable; completed cache entries from earlier calls
remain valid. In-flight single-flight work is discarded. A later successful
retry commits once, after which reuse is `PlanStateInvalid`. This rule applies
to `CloseApplicability`, `PlanEvaluation`, `AdvanceEvaluation`, and `Evaluate`.

### Exact closure and projected-slot aggregation

`ParseCanonical` requires one global structural declaration per SlotKey and one
global SlotKey owner per RequirementKey. Reusing a RequirementKey under a
different SlotKey is document-local `FormatException`. This makes the public acquisition
projection reversible without adding another wrapper type.

A `SealedAcquisitionAttempt` is minted for every issued instruction and keeps
the safe independent acquisition dimension after untrusted candidates are
gone. Observed derives Status from its context, has non-null Scope and matching
RequirementAcquisition, and copies that row's failures. Failed has Status
Failed, null Scope/acquisition, and the verified attempted-result failures.
NoInput has Status Incomplete, null Scope/acquisition, and no failures. Each
attempt retains the exact instruction, leaf kind, and verified ReceiptDigest;
attempts are in canonical instruction order. It exposes no Request adapter/
source-contract detail, raw payload, provider DTO, message, or exception.

A static slot has one attempt and one `SealedAcquisitionOutcome`. Observed
Complete admits the slot, mints its ContextProof from the observed Scope with
`QualificationProofDigest == ReceiptDigest`, and carries the exact complete
RequirementAcquisition. Observed Incomplete preserves its Scope, incomplete
RequirementAcquisition, failures, and proof digest in the outcome but mints no
ContextProof/capability. Failed and NoInput likewise remain visible as Failed
or Incomplete outcomes with no Scope/acquisition/ContextProof. Thus no valid
attempt disappears merely because the rule becomes NotEvaluated.

The projected repository-target slot has one Conformance-minted aggregate outcome for both
the zero-demand and owner-sharded cases. The manifest-declared demand projector
runs first; acquisition aggregation then closes before the registered
repository-target-resolution index,
so a later semantic index failure cannot rewrite a Complete acquisition as
Failed. For non-empty demand, every owner-shard instruction must have one
Observed, Complete context; its exact singleton RequirementAcquisition values
must be structurally equal. Any Failed shard makes the aggregate Status Failed.
Otherwise any valid NoInput or Observed-Incomplete attempt makes it Incomplete.
A set of otherwise valid Observed-Complete shards whose canonical union crosses
a declared plan-global target retention limit instead produces the
`projected-resource-failed` Status Failed shape described above; the individual
attempts remain Observed-Complete and the aggregate alone owns the singleton
safe resource failure.
A cross-shard metadata disagreement, missing/extra candidate, instruction, or
shard remains `AdmissionProofInvalid`/`PlanStateInvalid` and aborts atomically;
it is never relabeled as a semantic outcome. Neither valid non-Complete case mints a ContextProof or partial repository-target
capability and dependent rules are NotEvaluated, but every shard attempt and
safe failure remains in the outcome. For empty demand there
is no instruction/receipt/context; Conformance synthesizes the one output
RequirementAcquisition with the declared repository-target requirement,
`ObjectVersionBound`, `EvidenceRedaction.None`, no failures, and therefore
Complete status. The zero-model repository-target-resolution index is then still invoked exactly
once; its semantic success/failure affects rule readiness, not acquisition
Status.

Conformance first computes a non-circular projected boundary seed over:

```text
ASCII "protocol.projected-slot-boundary/1\n"
AuthorityKind, ManifestDigest, CatalogVersion
RoundOrdinal
exact output Slot declaration and resolved AcquisitionTarget
ordered parent rows: SlotKey, QualificationProofDigest, exact EvidenceScope
u8 demand mode: none=0, owner-sharded=1
none: canonical none DemandDigest
owner-sharded: u32 shard count, then for each owner shard in instruction order:
  InstructionDigest, DemandDigest, ReceiptDigest, exact observed EvidenceScope
  exact retained instruction-frame and demand-frame collision bytes
```

Parent rows are the canonical unique context proofs for every active projector
input SlotKey. The contributing-scope set is those parent scopes plus observed
shard scopes and is never empty. Its aggregate interval is minimum StartedAtUtc
through maximum CompletedAtUtc. The aggregate `EvidenceScope.Target` is the
projected slot's resolved target and its boundary SnapshotKind is the same. For
ExactCommit, Candidate, or CapturedEvidence, BoundaryIdentity is the target's
TargetIdentity as required by Domain. For ProviderEvent or
ProviderFullInventory it is the lowercase SHA-256 of the exact boundary-seed
frame; the aggregate qualified proof, rather than a caller-created Domain
value, proves that derived cross-surface boundary relation.

Every static or projected slot also has one exact outcome frame:

```text
ASCII "protocol.acquisition-outcome/1\n"
AuthorityKind, ManifestDigest, CatalogVersion
exact Slot declaration and resolved AcquisitionTarget
u8 outcome mode: static=0, projected-none=1, projected-owner-sharded=2,
  projector-failed=3, projected-resource-failed=4
AcquisitionStatus
ordered parent proof rows (empty for static)
projected-only projector and declared repository-target-resolution-index
  component/artifact bindings
static: no projected tail
projected-none: canonical none DemandDigest
projected-owner-sharded: exact retained demand/instruction collision frames
projector-failed: no demand/instruction frames; projector invocation frame and
  digest, EvaluationFailureCode, primary/related qualified-reference frames,
  in their accepted structural order
projected-resource-failed: exact retained demand/instruction collision frames,
  u8 limit rank unique-content-count=0, aggregate-content-bytes=1,
  complete-payload-bytes=2; uint64-be ceiling and checked would-be value;
  first canonical crossing InstructionDigest
ordered attempts, each with instruction, AdmissionKind, Status, ReceiptDigest,
  optional Scope, optional RequirementAcquisition, and ordered failures
optional aggregate Scope; optional aggregate RequirementAcquisition
canonical unique aggregate failures
```

`IsProjected` is derived exactly as outcome mode other than static.
`OutcomeDigest` is SHA-256 of that retained frame. Aggregate failures are the
canonical unique `(RequirementKey, Code)` union of attempt failures, except that
`projected-resource-failed` adds its exact one mode-owned singleton after that
union; no other mode synthesizes an acquisition failure. Attempt rows preserve
which owner-sharded instruction supplied an otherwise duplicate failure. A static
outcome has exactly one attempt. A projected outcome has zero attempts for
empty demand/projector-before-I/O failure or one per owner-sharded instruction.
Its aggregate Status precedence is Failed, then Incomplete, then Complete.
`Target` is always the slot's exact resolved target and remains available even
when a projected outcome has no attempt or Scope. A projector semantic failure
before I/O produces the distinct valid shape IsProjected=true, Status
Incomplete, zero attempts, null Scope/acquisition/ContextProof, and empty
acquisition failures. The `projector-failed` tail binds the exact independent
typed failure without misrepresenting it as an acquisition attempt; its
declared `RuleEvaluationFailure` remains in the rule-evaluation dimension.
Every projected outcome whose Status is not Complete has null aggregate Scope,
RequirementAcquisition, and ContextProof, even though its attempt rows retain
their own safe scopes/acquisitions. Every Complete projected outcome requires
all three aggregate members non-null. The projected boundary seed and aggregate
ContextProof are computed only for Complete projected modes `projected-none`
and `projected-owner-sharded`; modes `projector-failed` and
`projected-resource-failed` never have a boundary seed or projected proof and
never invoke the repository-target-resolution index. The resource-failed mode
has one attempt per issued owner shard, Status Failed, the exact singleton
aggregate resource failure, and null aggregate Scope/acquisition/ContextProof;
it is the only valid shape in which all attempt rows may be Observed-Complete
while the projected aggregate is Failed.

For a Complete projected outcome, the final aggregate proof frame is:

```text
ASCII "protocol.projected-slot-proof/1\n"
the exact boundary-seed frame and its SHA-256
the exact aggregate EvidenceScope
projector component, artifact filename, artifact digest
repository-target-resolution index component, artifact filename, artifact digest
the one canonical output RequirementAcquisition
```

The aggregate proof frame additionally binds `OutcomeDigest`. SHA-256 of that
frame is the projected slot's one `QualificationProofDigest`; equal digests over unequal retained frames are
`ReferenceInvalid`. The resulting ContextProof has that aggregate Scope and
SlotKey. The sealed repository-target capability is bound to this ContextProof plus the
canonical row `ResolutionEvidence`/exact-commit derivations; `GetContextProof`
therefore has the same honest singular meaning for zero, one, or many owner
shards. No shard receipt is exposed as if it alone qualified the whole slot.

`SealedEvaluationContext` is a cumulative monotonic projection. Its
`AdmittedSlotKeys` is the unique ordinal SlotKey list for exactly the Complete
outcomes; `Scopes` is the structural unique list of their ContextProof scopes
under the accepted EvidenceScope comparator. A closure's `Acquisitions`
contains exactly one `SealedAcquisitionOutcome` per activated SlotKey in
SlotKey order, including Complete, Incomplete, and Failed; shared rule use and
projected owner shards never duplicate it. `ApplicabilityClosure` contains the
outcomes for activated applicability slots. `EvaluationClosure` carries those
rows forward and adds every activated evaluation/projected slot; it never drops
or rewrites a predecessor outcome. Both final evaluation result types copy the
same cumulative outcome list, so [SUBF-0154](README.md#subf-0154) can report acquisition and rule
evaluation as independent dimensions without re-reading untrusted candidates.

`ApplicabilityClosure.TerminalEvaluations` contains exactly the selected rules
already terminal as NotApplicable or NotEvaluated after applicability, ordered
by RuleId/revision; Applicable rules are absent. `EvaluationClosure` carries
those rows forward and adds exactly the rules made NotEvaluated by unresolved
evaluation acquisition or producer failure. Ready Applicable rules remain
absent until `Evaluate`, which invokes each exactly once and returns the
canonical union with the terminal rows. A terminal rule is never reevaluated.

Adapter availability, grants, source permissions, and routing capability never
change semantic applicability. Their failure changes acquisition/evaluation
readiness only.

[TEST-0210](test-cases.md#test-0210) uses the internal friend factory in the staged non-interchangeable
modes above. B activates no public export. C may activate only its explicitly
synthetic complete catalog/export/predecessor proof to exercise complete-
catalog transition and verdict truth tables; it contains no real Policy
registration. D may activate the non-authoritative qualification mirror,
substituting exactly the Tests activation/admission proof declarations while
retaining the object-identical real Policy registration projection, to qualify
the initial five real rule paths.

D separately asserts the real `InitialRuleQualificationPolicy.Export` public
and internal projections and then proves mirror equality/substitution field by
field. It never reports the mirror as the real export instance. C's synthetic
complete fixture cannot contain, relabel, or claim completeness for the real
qualification-only Policy export. Each test envelope binds only its immutable
test-fixture source commit, cannot satisfy a production release-source claim,
cannot escape the test assembly, and cannot serve as release/consumer evidence.
The real Policy assembly still exposes no `CompletePolicyPackExport` in this
slice.

## Kernel-minted findings and evaluations

The Conformance output contracts are:

```csharp
public sealed class RuleFinding
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public FindingCode Code { get; }
    public FindingSeverity Severity { get; }
    public RemediationKey Remediation { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}

public sealed class RuleEvaluationFailure
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public EvaluationFailureCode Code { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}

public sealed class RuleEvaluation
{
    public RuleId RuleId { get; }
    public RuleRevision RuleRevision { get; }
    public RuleEvaluationStatus Status { get; }
    public bool IsApplicabilityUnresolved { get; }
    public IReadOnlyList<QualifiedEvidenceReference> ApplicabilityReferences { get; }
    public IReadOnlyList<string> UnresolvedSlotKeys { get; }
    public IReadOnlyList<RuleFinding> Findings { get; }
    public IReadOnlyList<RuleEvaluationFailure> Failures { get; }
}
```

Only the kernel supplies RuleId/revision, severity, remediation, final
references, and status. Invariants are exact:

| Status | Required shape |
| --- | --- |
| `Satisfied` | Applicable and evaluation-ready; IsApplicabilityUnresolved false; zero findings; zero failures; zero unresolved slots |
| `Violated` | Applicable and evaluation-ready; IsApplicabilityUnresolved false; at least one finding; zero failures; zero unresolved slots |
| `NotApplicable` | Proven false applicability; IsApplicabilityUnresolved false; referenced proof; zero findings; zero failures; zero unresolved slots |
| `NotEvaluated` | Exactly one cause family is present: a validated `ApplicabilityIntent.Unresolved` sets IsApplicabilityUnresolved true with non-empty applicability references even when every slot is Complete, or acquisition/model/index/evaluator inability leaves it false and supplies at least one unresolved slot or typed failure; may retain already proven partial findings |

The dedicated boolean preserves semantic applicability uncertainty instead of
falsely marking a Complete slot unresolved. It is kernel-derived only from the
closed `ApplicabilityIntentKind.Unresolved`; callers/evaluators cannot set it,
and no other status may carry it.

The slice result exposes canonical acquisition outcomes, evaluations,
`HasKnownViolation`, and `HasUnresolvedRequiredEvaluation`. It has no
`ConformanceVerdict`. The complete result additionally exposes its exact named
profile and one `ConformanceVerdict`. The unresolved flag is true when any
activated required acquisition outcome is Incomplete/Failed or any required
rule is NotEvaluated; the violation flag remains independent:

| Unresolved required evaluation | Known violation | Verdict |
| --- | --- | --- |
| true | either | `Indeterminate` |
| false | true | `NonConforming` |
| false | false | `Conforming` |

`NotApplicable` affects neither flag. Every selected active rule has exactly
one evaluation; missing, extra, duplicate, retired, or wrong-revision
evaluation is integrity failure. Evaluation order is RuleId/RuleRevision;
finding order is code then primary/related reference identity; failure order is
code then reference identity, all ordinal. Input order, dictionary order,
culture, OS, and concurrency cannot change output.

[SUBF-0143](README.md#subf-0143) does not mint `EnforcementDecision`, extension,
waiver, debt, disposition, report stable key, canonical JSON, report bytes, or
report digest. Those remain with [SUBF-0144](README.md#subf-0144) and
[SUBF-0154](README.md#subf-0154).

## Normative Markdown and governed-reference semantics

The Markdown semantic authority is fixed rather than implementation-selected.
Core block/inline parsing is [CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/);
the relevant table and extended-autolink behavior is the fixed
[GitHub Flavored Markdown 0.29](https://github.github.com/gfm/) contract; and the
only parser package is [Markdig 1.3.2](https://github.com/xoofx/markdig/tree/1.3.2).
The exact `Markdig.dll` bytes are independently bound by the runtime anchor
above. A package update, pipeline-option change, extension-order change, parser
normalization change, or semantic truth-table change is a reviewed component/
artifact change and cannot arrive through a floating dependency.

Each `MarkdownDocumentParser` invocation builds one fresh pipeline in this exact
order, uses it for that invocation only, and then discards it. A pipeline is
never shared across concurrent parses because Markdig does not declare the
pipeline thread-safe:

```csharp
var builder = new MarkdownPipelineBuilder
{
    MaximumNestingDepth = 512
};

builder
    .UsePreciseSourceLocation()
    .UsePipeTables(new PipeTableOptions
    {
        RequireHeaderSeparator = true,
        UseHeaderForColumnCount = true,
        InferColumnWidthsFromSeparator = false
    })
    .UseFootnotes()
    .UseAutoLinks(new AutoLinkOptions
    {
        ValidPreviousCharacters = "*_~(",
        OpenInNewWindow = false,
        AllowDomainWithoutPeriod = false,
        UseHttpsForWWWLinks = false
    });

var pipeline = builder.Build();
```

No `UseAdvancedExtensions`, ambient extension, media/Jira/custom-autolink
provider, generic attribute, YAML, grid-table, soft-break, or HTML-disable call
is permitted. `.UseAutoIdentifiers(...)` is deliberately absent. Raw HTML
parsing remains enabled. The parser walks the AST and
original source spans; it calls
`Markdig.Markdown.Parse(source, pipeline, context: null)` and never invokes a
renderer or reparses a rendering. The
declared semantic MaxDepth is 256 and is measured by Policy's own bounded,
iterative structural walker: depth 256 succeeds and the first node at depth 257
or node 500,001 returns `protocol.budget.exhausted` through the normal producer
failure intent.
`MaximumNestingDepth = 512` is Markdig's configured block-container guard during
inline processing, not a universal AST guard; pinned internal block/inline
helpers retain their separate 10,240 safety limit. In Markdig 1.3.2 both guards
throw `ArgumentException` with the exact ordinal base message
`Markdown elements in the input are too deeply nested - depth limit exceeded. Input is most likely not sensible or is a very large table.`
Markdig exposes no public depth-error discriminator. Policy therefore maps only
`ex.GetType() == typeof(ArgumentException)`, null `ParamName`, and an ordinal-
exact `Message` equal to that constant from the manifest-bound artifact to
`protocol.budget.exhausted`. Any other Markdig/package exception is an
unexpected host failure and propagates. The configured value, Policy depth
walker, pinned internal guard, and exception discrimination are [TEST-0210](test-cases.md#test-0210)
golden oracles; no localized or substring match is accepted.

After parsing, Policy orders all `HeadingBlock` values by strictly increasing
`Span.Start` and builds each heading's visible strip text with the same bounded
iterative inline walk used for semantic metering. It appends
`LiteralInline.ContentSpan`, `CodeInline.ContentSpan`,
`HtmlEntityInline.Transcoded`, and `AutolinkInline.Url`; for `DelimiterInline`
it appends `ToLiteral()` then visits children; and for `LinkInline`,
`EmphasisInline`, and every other container it visits children in source order.
It appends nothing for `HtmlInline`, `LineBreakInline`, `FootnoteLink`, or an
unknown leaf. Link/image labels remain visible; raw tags and footnote markers
do not.

Policy calls the manifest-bound public
`Markdig.Helpers.LinkHelper.UrilizeAsGfm(ReadOnlySpan<char>)`. The pinned
algorithm retains UTF-16 characters for which `char.IsLetterOrDigit` is true
plus `-` and `_`, lowercases retained letters/digits through
`char.ToLowerInvariant`, replaces only U+0020 SPACE with `-`, and drops every
other UTF-16 code unit. It performs no Unicode/whitespace normalization,
collapsing, or trim; surrogate halves of astral letters are therefore dropped.
Empty output becomes literal `section`. Generated IDs are assigned in heading
source order from one document-global ordinal set: the first unused base wins,
otherwise the smallest unused `base-<positive invariant ASCII decimal>` wins.
The result is never written into Markdig's AST and no renderer is invoked.
Generated IDs participate only in target uniqueness. [TEST-0210](test-cases.md#test-0210) pins whitespace,
entity/code/link/image/autolink visibility, Unicode, empty-slug, collision-order,
and a deeply nested heading below semantic depth 256, including
`X, X, X-1, X -> x, x-1, x-1-1, x-2`.

Markdig is the syntax engine, not the whole governance classifier. Precise
source positions are zero-based UTF-16 code-unit spans over the one strict-UTF-8
decoded source string. Policy builds a non-overlapping protected/rendering-span
map from the AST and performs one bounded ordinal residual scan over the
original source. That scanner recognizes only the closed grammars below; it is
not a second Markdown parser and uses no regex backtracking. It is required
because unresolved reference syntax and unused/duplicate reference definitions
do not all survive as ordinary `LinkInline` nodes. Footnote definitions and
references are excluded from generic reference-definition handling, while
their rendered Markdown bodies remain recursively governed. Count, span, and
byte accounting uses the same parser allowance and stops at the first one-over.

Every source code unit belongs to exactly one of four authored-region classes:
an active link label/destination region, visible rendered text outside links, a
code-span/code-block region, or a hidden authoring region (HTML comments,
non-rendering raw-HTML bodies, and unused definition material). All four are
scanned for the closed governed-occurrence families. Only an active non-image
HTTP(S) link region can supply `Clickable` coverage. Code and hidden placement
supplies no coverage and is not itself an exemption: an occurrence there is
`DeclaredLiteral` only when the exact context classifier below matches;
otherwise it remains the family-appropriate `NonClickable` or
`UnsupportedAuthoringForm` occurrence. Region boundaries never concatenate or
suppress occurrences.

### Renderer-active syntax truth table

An occurrence is clickable only when its complete visible source span is
covered by exactly one non-image link row. Partial labels, adjacent markup that
composes the visible identity, or one link covering multiple independent stable
identities do not satisfy any occurrence.

| Source form | Parser/index classification |
| --- | --- |
| `[label]` plus `(destination "optional title")` | One inline `Clickable` link after CommonMark escape/entity processing. |
| `[label][key]`, `[label][]`, `[label]` | One `Clickable` link only when the case-insensitive normalized key resolves to the first definition. Missing key is retained as an unresolved, non-clickable occurrence. A later duplicate definition never changes the first winner and is retained as a duplicate definition occurrence. |
| `<http://host/path>` or `<https://host/path>` | One CommonMark absolute HTTP(S) `Clickable` autolink only as an `AutolinkInline` with `IsEmail == false` and that exact angle-delimited original source family. ASCII scheme comparison is case-insensitive; canonical target projection lowercases the scheme. |
| bare `http://host/path` or `https://host/path` | One extended `Clickable` autolink only as a non-image `LinkInline` with `IsAutoLink == true` under the fixed GFM/AutoLink boundary, balanced-parenthesis, trailing-punctuation, entity, and domain rules. Markdig 1.3.2 recognizes only lowercase bare `http://`/`https://`; mixed/uppercase bare schemes are visible `NonClickable`. A URL split by emphasis, comment, entity markup, or another node is never reassembled. |
| `www.host`, `ftp:`, `mailto:`, `tel:`, image syntax, or a package/provider custom autolink | Never a governed clickable HTTP(S) reference, even if Markdig creates a link. Ordinary explicit/reference `LinkInline` rows are classified by their own syntax; neither they nor CommonMark `AutolinkInline` rows are tested through the extended bare-link `IsAutoLink` predicate. |
| a bare scheme preceded by a letter/digit, `-`, `]`, or another character outside the exact configured boundary; a domain without the required period; an underscore in either final domain segment; or a markup-split URL | Visible `NonClickable`; a parser-recognized suffix may not suppress the whole occurrence. |
| raw HTML `<a href=...>visible identity</a>` | `UnsupportedAuthoringForm`, never a governed link. The visible inner identity remains governed and cannot be hidden by the `href`. |
| `CodeInline` | Supplies no clickable coverage. A stable ID, path, title, issue/PR/comment identity, or human-facing SHA inside it is still governed unless the exact literal classifier below applies. |
| fenced/indented code, HTML comment, `script`, `style`, `template`, or another non-rendering HTML body | Supplies no clickable coverage and creates no target anchor. Governed occurrences are retained in the code/hidden region; only an exact match to the `DeclaredLiteral` classifier below exempts one. All others remain `NonClickable` or `UnsupportedAuthoringForm` as required by their occurrence family. |
| unused reference definition containing a governed target/identity | `NonClickable`; definitions are authoring support, not a hidden reference inventory. Unresolved, duplicate, and unused definitions remain distinct residual rows. |

The custom-anchor grammar is deliberately narrower than general HTML. A
canonical target is exactly lowercase ASCII
`<a name="<lowercase-stable-id>"></a>` with lowercase `a`/`name`, double
quotes, no whitespace inside the quoted name, no additional attribute, no
self-close, and the exact closing tag. It must be an active `HtmlInline`/
`HtmlBlock` source span inside the canonical declaration span. Single quotes,
`id=`, uppercase tag/attribute/name, extra attributes, self-closing syntax,
code/comment/non-rendering placement, or placement outside the declaration does
not satisfy the anchor. Policy-generated GFM heading IDs participate
only in target uniqueness: a heading ID colliding with the required custom
anchor makes the target non-unique; a heading never substitutes for the custom
anchor.

### Record, occurrence-intent, and literal grammar

The stable-ID token grammar is the ordinal uppercase union
`BUG|DEC|EPIC|FEAT|FIND|IDEA|RISK|RULE|SUBF|TASK|TEST`, one hyphen, and exactly
four ASCII digits, bounded on both sides by the absence of an ASCII letter,
digit, underscore, or hyphen. Repository document paths ending in `.md` with an
optional fragment, registered document titles, GitHub issue/PR/comment/review
shorthands, absolute HTTP(S) URLs, and candidate commit SHAs are separate
governed occurrence families. The scanner retains source surface, AST node/
span, normalized visible value, and one closed internal occurrence intent; an
adapter cannot label an occurrence exempt.

Canonical declarations are recognized only from these rendering shapes:

| Record shape | Exact declaration rule |
| --- | --- |
| file-owned `FEAT`, `DEC`, or `IDEA` | The path has the matching uppercase ID prefix in its canonical `docs/features`, `docs/decisions`, or `docs/ideas` location and the first H1 begins with the same whole ID. |
| embedded `TEST`, `SUBF`, `FIND`, or `RISK` table record | A pipe-table body row whose first cell begins with one code-inline whole ID and contains the exact custom anchor in that same cell. |
| embedded heading record | One ATX H1-H6 whose visible content begins with the one whole ID and whose exact custom anchor is inside that heading span. |
| embedded checklist record | One list item beginning with a task marker and one code-inline whole ID, with the exact custom anchor in that list-item declaration span. |

One ID has exactly one canonical declaration across the qualified inventory.
A second declaration-shaped occurrence is invalid. The canonical declaration's
own identity and a non-declaration-shaped ordinary repetition in the same
declaring document are `OwnCanonicalIdentity`/`OwnDocumentRepetition` and need
no self-link. Every occurrence in another document is `CrossRecord`. On a
non-rendering provider title, every governed occurrence is non-clickable except
the one exact leading identity that names the title's own provider record. Code
formatting is never a cross-record bypass.

A candidate commit token is an isolated 7..40 ASCII hex sequence. A short token
containing digits only is a candidate only when its same-line left context ends
in the whole word `commit`, `head`, `sha`, or `oid`. A candidate is
`HumanCommit` when it is the visible label/target of a commit link or its line
contains one of the exact whole phrases `commit`, `merge commit`, `commit sha`,
`commit hash`, or `head commit`. Inline code does not by itself make that token
literal. Exactly these context families mint `DeclaredLiteral` instead:

- a fenced/indented command, source, fixture, or structured-data block;
- a line beginning with `$`, `PS>`, `git`, `gh`, `curl`, `pwsh`, `powershell`,
  `dotnet`, `npm`, or `npx` followed by whitespace/end;
- an explicit tag/blob/tree/object, merge-tree, fixture/placeholder/synthetic,
  machine/sample/test-vector, source-example/value, Git-object-input, opaque-
  marker, checksum/digest, SHA-1, or SHA-256 label on the same line; or
- an exact structured field/property/assignment key `sourceCommit`,
  `expectedCommit`, `mergeCommitSha`, `commitSha`, `commitOid`, `objectId`,
  `treeSha`, `sha1`, `sha256`, or `digest`, including an explicitly named JSON
  field.

No other adjective, adapter metadata, casing variant, or nearby punctuation
creates a literal exemption. The exact positive and negative phrase boundaries
are immutable [TEST-0210](test-cases.md#test-0210) vectors. One exact commit permalink containing its SHA
is one Commit occurrence, not a second free-text SHA occurrence.

### Target normalization and resolution

Markdown supplies both its decoded link destination and the exact authored
destination source slice, including a referenced definition's destination span
when applicable. Policy splits the authored destination into path, query, and
fragment on literal delimiters before percent decoding, validates every escape,
decodes once, and requires the result to equal Markdig's destination ordinally.
An absent/ambiguous authored destination slice, empty target, control,
backslash, userinfo, invalid percent escape, encoded `/`, dot-segment escape
above repository root, or target longer than 4096 strict-UTF-8 bytes is
unresolved. Queries are forbidden for governed repository/provider record
targets. Percent escapes use uppercase hex and an unreserved character must not
remain escaped.

| Source/target family | Exact resolution |
| --- | --- |
| repository body -> current repository record/location | Destination must be repository-relative. Resolve `.`/`..` against the source document directory without escaping root; compare the normalized `/` path ordinally with the repository tree/record index. An addressable record requires its exact case-sensitive fragment. |
| repository body -> immutable historical blob | An absolute GitHub `https://github.com/<owner>/<repo>/blob/<40-lower-hex>/<path>` with an optional fragment becomes a CommitObject selector. CrossRecord may omit a fragment when the classified target is the blob itself; EmbeddedRecord retains omission for later `MissingFragment`. It never consults current-tree membership and never substitutes for a required relative current-record link. |
| repository/provider body -> immutable tag root | Exact GitHub `https://github.com/<owner>/<repo>/tree/<one-canonical-tag-segment>` with no query, fragment, or suffix path becomes a CrossRecord TagRoot selector. The qualified result must prove the exact `refs/tags/<tag>` ref and its finite terminal commit peel. `/-/tree/`, a slash-bearing tag, or a branch/tree-path interpretation is unresolved in schema 1. |
| current relative non-Markdown line target | Resolve the path against the source document directory first, then require canonical `#Lstart` or `#Lstart-Lend`. ExactCommit source authority emits CommitObject with the qualified owner and full 40/64-hex commit; Candidate/CapturedEvidence emits CapturedSnapshotPath with the exact capture-manifest identity and expected file identity. Current Markdown fragments use the current governed-text parser/index and do not project; a current relative target without a fragment uses the current repository indexes and does not project. |
| provider body -> repository record/location | Exact absolute immutable GitHub blob URL with full 40-hex commit, normalized path, and required case-sensitive fragment; the qualified provider/repository roots must prove that owner/repository/commit/path relation. |
| issue, pull request, discussion, review, issue comment, review comment, or commit comment | Exact absolute HTTPS provider permalink for the qualified target kind/number/comment identity. A containing issue/PR URL is wrong for a comment/review-comment occurrence. |
| embedded stable ID | The normalized target must resolve to the one `ProtocolRecordView` for that ID and to its exact lowercase custom-anchor fragment. No fragment is `MissingFragment`; a different/case-folded fragment is `WrongFragment`. |
| human-facing commit | Exact absolute GitHub `https://github.com/<owner>/<repo>/commit/<40-lower-hex>` with no query/fragment. A 7..40 visible label must equal a unique prefix of that full SHA. The qualified repository-target projection, not URL syntax alone, proves owning repository and commit object. Branch/tree/blob targets never satisfy it. |

Every resolved target carries a sealed target handle; target inference from only
a string, current repository default, adapter route, or dictionary winner is
forbidden. Zero target candidates is `Unresolved`; multiple candidates is the
declared evaluator ambiguity failure and never an arbitrary first match.

### Initial rule truth tables

The first five evaluators are deterministic projections of the common indexes.
For one occurrence, each rule emits at most one finding from its own precedence
row; distinct occurrences and distinct rules remain independently reportable.

| Rule | Ordered input state -> exact outcome |
| --- | --- |
| RULE-0001 | For each canonical `docs/features/FEAT-NNNN-*` directory: terminal kind other than File or missing `README.md` -> `protocol.feature.readme-missing`; terminal kind other than File or missing `test-cases.md` -> `protocol.feature.test-cases-missing`; both File -> no finding. Each missing child uses its exact ExpectedSelector primary and the feature-directory Derived proof as related evidence. |
| RULE-0002 | A referenced `DEC-NNNN` with no canonical decision record -> `protocol.decision.record-missing` and the exact decision ExpectedSelector. An existing record is valid only with H1 `DEC-NNNN - <nonempty title>`, one ordered metadata list (`Classification`, `Status`, `Date`, `Decision owners`, `Related features`, `Related decisions`), and exactly one nonempty H2 section in order `Context`, `Decision`, `Consequences`, `Alternatives considered`, `Review condition`; otherwise `protocol.decision.structure-invalid`. |
| RULE-0003 | `UnsupportedAuthoringForm` -> `protocol.reference.unsupported-authoring-form`; else `NonClickable` or incomplete visible coverage -> `protocol.reference.not-clickable`; else `ExternalEvidenceRequired` without its exact admitted final overlay is not ready and the rule is `NotEvaluated`; else unresolved/ambiguous containing target -> `protocol.reference.unresolved-target`; else `WrongTarget`, a non-Commit `WrongRepository`/`WrongObject`, or a CrossRecord `MissingFragment`/`WrongFragment` -> `protocol.reference.wrong-target`; else an EmbeddedRecord `MissingFragment`/`WrongFragment` whose containing target is otherwise exact -> no RULE-0003 finding because RULE-0004 owns that specialized fragment outcome; else final Exact -> no finding. Tag-root, historical/current blob, captured-snapshot line, repository-relative, and provider-authored targets follow this same precedence. Commit-kind WrongRepository/WrongObject remains RULE-0005's specialized mapping. |
| RULE-0004 declaration | zero exact in-declaration custom anchors -> `protocol.record.anchor-missing`; more than one case-insensitive custom anchor or any heading/custom target collision for the lowercase ID -> `protocol.record.anchor-duplicate`; exactly one unique exact anchor -> no declaration finding. Wrong-case/noncanonical HTML counts as missing unless it also creates a target collision. |
| RULE-0004 reference | Proven EmbeddedRecord intent whose exact current or final repository-target state has no required fragment -> `protocol.reference.fragment-missing`; with a non-exact fragment or zero/multiple/other active historical targets -> `protocol.reference.fragment-wrong`; exact unique target -> no finding. If the containing target itself is `Unresolved`, `WrongTarget`, `WrongRepository`, or `WrongObject`, or its external overlay is unavailable, RULE-0003 reports it or the rule is NotEvaluated and RULE-0004 emits no fabricated specialized finding. CrossRecord fragment failures remain RULE-0003 wrong-target findings, not specialized RULE-0004 findings. |
| RULE-0005 | Proven HumanCommit/Commit intent whose clickable target is not the exact full-SHA commit form -> `protocol.commit-reference.not-permalink`; exact form naming another owner/repository -> `protocol.commit-reference.wrong-repository`; qualified Missing/no commit object -> `protocol.commit-reference.unresolved`; qualified wrong type/OID -> `protocol.commit-reference.wrong-object`; exact owner/full SHA/commit object -> no finding. Ambiguous intent becomes the declared evaluator failure, not a guessed finding. |

Overlap is intentional. The same bad stable-ID/SHA text may produce distinct
RULE-0003 and RULE-0005 findings; an embedded reference may produce RULE-0003
and RULE-0004 findings. Raw `href` suppresses neither. RULE-0001/0002 absence,
RULE-0003 exact-target resolution, RULE-0004 embedded fragments, and RULE-0005
commit-object proof are
independent axes; the kernel retains every proven co-report in canonical
RuleId/finding/reference order.

[TEST-0210](test-cases.md#test-0210) owns the immutable semantic corpus for every table row: CommonMark
link escapes and nesting; full/collapsed/shortcut reference definitions;
unresolved/unused/duplicate definitions; footnotes; GFM bare/angle autolink
boundaries, punctuation, balanced parentheses, entity and markup splits; raw
HTML, custom-anchor placement/collision, code/comment/non-rendering spans;
stable-ID own/cross-document and title modes; every literal/HumanCommit boundary;
repository/provider target normalization; and every single/co-report outcome.
Parser/package golden vectors, AST/source-span projections, and final capability
rows are compared across Windows/Linux and invariant cultures. Finite examples
do not replace these exact algorithms; they prove them.

## Initial rule declarations and overlap semantics

The concrete export constants are exact:

| Field | Value |
| --- | --- |
| Export key/version | `protocol.policy.initial-rule-qualification` / `1` |
| Slice key/version | `protocol.catalog-slice.initial-common-rules` / `1` |
| Protocol/catalog version | `0.17.0` / `CatalogVersion.Create(1)` |
| Policy artifact file | `MeAndAI.Protocol.Policy.dll` |
| Rule lifecycle | `IntroducedIn=0.17.0`; `DeprecatedIn=null`; `RetiredIn=null`; empty compatibility aliases |
| Common axes | SubjectRole ProtocolAuthoritySelfConsumer + Consumer; ProtocolOperation Conformance; no applicability slot; caller profile EnforcementPhase does not change conformance semantics |

Every component in the 27-row Policy registration/type-contract partition is
version `1`. Its 23 Policy-implemented rows belong to assembly simple name
`MeAndAI.Protocol.Policy` and map to `MeAndAI.Protocol.Policy.dll`; its four
capability-interface rows belong to
`MeAndAI.Protocol.Conformance.Abstractions` and map to
`MeAndAI.Protocol.Conformance.Abstractions.dll`. Codec, parser, and index
component keys/types are fixed in the registry table above. The remaining
exact Policy-implemented component identities are:

| Component key | Full type name |
| --- | --- |
| `protocol.evaluator.rule-0001` | `MeAndAI.Protocol.Policy.Rules.FeaturePacketRuleEvaluator` |
| `protocol.evaluator.rule-0002` | `MeAndAI.Protocol.Policy.Rules.DecisionRecordRuleEvaluator` |
| `protocol.evaluator.rule-0003` | `MeAndAI.Protocol.Policy.Rules.ClickableExactTargetRuleEvaluator` |
| `protocol.evaluator.rule-0004` | `MeAndAI.Protocol.Policy.Rules.StableFragmentRuleEvaluator` |
| `protocol.evaluator.rule-0005` | `MeAndAI.Protocol.Policy.Rules.CommitPermalinkRuleEvaluator` |
| `protocol.selector.feature-readme` | `MeAndAI.Protocol.Policy.Selectors.FeatureReadmeSelectorResolver` |
| `protocol.selector.feature-test-cases` | `MeAndAI.Protocol.Policy.Selectors.FeatureTestCasesSelectorResolver` |
| `protocol.selector.decision-record` | `MeAndAI.Protocol.Policy.Selectors.DecisionRecordSelectorResolver` |

`PolicyQualificationSliceExport.Components` is the ordinal union of exactly
those eight evaluator/selector components, the nine codec/parser/index
components, the one demand-projector component declared above, five internal
model-type components, and four public capability-interface type components:
27 rows. Its internal typed registration graph
binds every row. Activation-proof and admission-proof components are separate
envelope partitions, and the four runtime artifact anchors are a separate
manifest partition; none is a Policy registration. The full manifest has
exactly 35 component rows for this production slice.

The four reusable slot declarations are exact. Consistency lists appear in
accepted schema order and every slot is evaluation-phase only for the initial
five rules:

| Slot | Exact EvidenceRequirement | Profile surfaces / material / target selector | Capabilities |
| --- | --- | --- | --- |
| `protocol.slot.repository-tree` | key `protocol.requirement.repository-tree`; Surface Repository; kind `protocol.evidence.repository-tree`; completeness `protocol.completeness.full-tree`; schema `protocol.repository-tree` / `1`; ExactSnapshot, ObjectVersionBound, BoundedNonAtomicObservation | Repository / `protocol.material.repository-tree` / `protocol.target.repository-snapshot` | repository-tree |
| `protocol.slot.repository-governed-text` | key `protocol.requirement.repository-governed-text`; Surface Repository; kind `protocol.evidence.governed-text-set`; completeness `protocol.completeness.all-governed-bodies`; schema `protocol.governed-text` / `1`; ExactSnapshot, ObjectVersionBound, BoundedNonAtomicObservation | Repository + Provider / `protocol.material.governed-text` / `protocol.target.repository-governed-body-set` | protocol-record-index + governed-reference-index |
| `protocol.slot.provider-governed-text` | key `protocol.requirement.provider-governed-text`; Surface Provider; kind `protocol.evidence.governed-text-set`; completeness `protocol.completeness.all-governed-bodies`; schema `protocol.governed-text` / `1`; ExactSnapshot, ObjectVersionBound, BoundedNonAtomicObservation | Provider / `protocol.material.governed-text` / `protocol.target.provider-governed-body-set` | protocol-record-index + governed-reference-index |
| `protocol.slot.repository-target-resolution` | key `protocol.requirement.repository-target-resolution`; Surface Repository; kind `protocol.evidence.repository-target-resolution-set`; completeness `protocol.completeness.all-projected-target-resolutions`; schema `protocol.repository-target-resolution` / `1`; ExactSnapshot, ObjectVersionBound | Repository + Provider / `protocol.material.repository-target-resolution` / `protocol.target.repository-target-resolution-set` | repository-target-resolution-index |

Capability names in this table mean their exact `protocol.capability.*` / `1`
identities and interface types declared above. Repeated SlotKeys across rules
reuse byte-for-byte equal declarations. Repository profiles activate repository
tree/governed text but not provider governed text. Provider profiles activate
provider governed text plus repository governed-text support needed to resolve
target records; RULE-0003, RULE-0004, and RULE-0005 also declare the Repository-
targeted projected resolution slot, which emits no instruction when their
qualified preliminary views contain no external-evidence demand. The
support acquisitions remain Repository requirements/targets and do not relabel
provider evidence or broaden the profile surface.

The exact per-rule declaration projection is:

| Rule | Surfaces / snapshot kinds | Evaluation slots | Expected selectors | Qualification scenarios |
| --- | --- | --- | --- | --- |
| RULE-0001 rev 1 | Repository / ExactCommit, Candidate, ProviderFullInventory, CapturedEvidence | repository-tree | `protocol.selector.feature-readme`, SlotKey `protocol.slot.repository-tree`, schema `protocol.selector.relative-child.v1`, feature-readme resolver, parent Derived, finding `protocol.feature.readme-missing`; `protocol.selector.feature-test-cases`, the same SlotKey/schema, feature-test-cases resolver, parent Derived, finding `protocol.feature.test-cases-missing` | [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) |
| RULE-0002 rev 1 | Repository / ExactCommit, Candidate, ProviderFullInventory, CapturedEvidence | repository-tree; repository-governed-text | `protocol.selector.decision-record`, SlotKey `protocol.slot.repository-governed-text`, schema `protocol.selector.decision-record-by-id.v1`, decision-record resolver, parent Derived, finding `protocol.decision.record-missing` | [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005) |
| RULE-0003 rev 1 | Repository + Provider / ExactCommit, Candidate, ProviderEvent, ProviderFullInventory, CapturedEvidence | repository-governed-text; provider-governed-text; repository-target-resolution | none | [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) |
| RULE-0004 rev 1 | Repository + Provider / ExactCommit, Candidate, ProviderEvent, ProviderFullInventory, CapturedEvidence | repository-governed-text; provider-governed-text; repository-target-resolution | none | [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) |
| RULE-0005 rev 1 | Repository + Provider / ExactCommit, Candidate, ProviderEvent, ProviderFullInventory, CapturedEvidence | repository-governed-text; provider-governed-text; repository-target-resolution | none | [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) |

The evaluator component is the matching `protocol.evaluator.rule-NNNN` entry;
CatalogVersion is 1; normative fragments/digests are the exact earlier table;
all applicability lists are empty; common axes/lifecycle are the constants
above. Selector resolvers may derive a bounded child/member identifier only
from their declaration plus sealed parent model; ambiguity is integrity
failure, never evaluator-authored text.

The exact qualification links are:

| Rule | Canonical existing siblings | Deferred final activation |
| --- | --- | --- |
| [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001) | [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004) | [TEST-0210](test-cases.md#test-0210) |
| [RULE-0002](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0002) | [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005) | [TEST-0210](test-cases.md#test-0210) |
| [RULE-0003](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0003) | [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) | [TEST-0210](test-cases.md#test-0210) |
| [RULE-0004](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0004) | [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177) | [TEST-0210](test-cases.md#test-0210) |
| [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005) | [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) | [TEST-0210](test-cases.md#test-0210) |

The current admitted counts are `[1,1,3,1,1]`, total `7`. The older scenarios
remain their own canonical semantic owners. While [TEST-0210](test-cases.md#test-0210)
is `Planned`, its deferred column is not part of `QualificationScenarios`.
Final atomic activation appends it to all five declarations, yielding
`[2,2,4,2,2]`, total `12`. The scenario directly executes fresh C# fixtures; it
never consumes a sibling result.
[TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176) retains provider enumeration, pagination, freshness, and I/O
ownership. [TEST-0210](test-cases.md#test-0210) receives only already sealed provider-neutral material.

The initial exact finding inventory is:

| Rule | Declared finding codes | Remediation | Allowed reference kinds |
| --- | --- | --- | --- |
| RULE-0001 | `protocol.feature.readme-missing`; `protocol.feature.test-cases-missing` | `protocol.remediation.feature-packet` | ExpectedSelector primary; ContextProof/Root/Derived related |
| RULE-0002 | `protocol.decision.record-missing`; `protocol.decision.structure-invalid` | `protocol.remediation.decision-structure` | missing: ExpectedSelector; structure: Root/Derived; ContextProof/Root/Derived related |
| RULE-0003 | `protocol.reference.not-clickable`; `protocol.reference.unsupported-authoring-form`; `protocol.reference.wrong-target`; `protocol.reference.unresolved-target` | `protocol.remediation.exact-link` | Derived primary; Root/Derived related |
| RULE-0004 | `protocol.record.anchor-missing`; `protocol.record.anchor-duplicate`; `protocol.reference.fragment-missing`; `protocol.reference.fragment-wrong` | `protocol.remediation.stable-fragment` | Derived primary; Root/Derived related |
| RULE-0005 | `protocol.commit-reference.not-permalink`; `protocol.commit-reference.wrong-repository`; `protocol.commit-reference.wrong-object`; `protocol.commit-reference.unresolved` | `protocol.remediation.commit-permalink` | Derived primary; Root/Derived related |

All initial findings use `protocol.finding.error`. Evaluator-emittable failure
codes are empty for RULE-0001/RULE-0002,
`protocol.evaluator.reference-ambiguity` for RULE-0003/RULE-0004, and that code
plus `protocol.evaluator.commit-intent-ambiguity` for RULE-0005. A parser or
index failure is minted by the kernel only from that component declaration; an
evaluator cannot emit it.

Exact component-stage evaluation failures are
`protocol.model.invalid-markdown`,
`protocol.index.repository-tree-unavailable`,
`protocol.index.record-unavailable`,
`protocol.index.reference-unavailable`,
`protocol.index.repository-target-resolution-unavailable`, and
`protocol.budget.exhausted`. Exact canonical-codec qualification failures are
`protocol.codec.invalid-utf8`, `protocol.codec.noncanonical-encoding`,
`protocol.codec.invalid-repository-tree`,
`protocol.codec.invalid-repository-target-resolution`,
`protocol.codec.embedded-identity-mismatch`,
`protocol.codec.payload-location-mismatch`, and
`protocol.codec.resource-limit-exceeded`. Each schema/parser/index declaration
contains only the applicable subset. Codec codes map to acquisition failure
and never become `RuleEvaluationFailure`.

`protocol.codec.payload-location-mismatch` means the embedded location leaf,
surface, or schema-specific tail is itself disallowed: repository-tree and
repository-target-resolution
require Repository surface plus Snapshot location; governed-text permits only
the stated Repository/Provider leaf and null/non-null tail matrix.
`protocol.codec.embedded-identity-mismatch` means both embedded values are
otherwise structurally valid but their Scope/Location do not equal the
enclosing EvidenceContext/Binding. The two codes are mutually exclusive.

| Declaration | Exact allowed failure codes |
| --- | --- |
| repository-tree schema | `protocol.codec.invalid-repository-tree`; `protocol.codec.embedded-identity-mismatch`; `protocol.codec.payload-location-mismatch`; `protocol.codec.resource-limit-exceeded` |
| governed-text schema | `protocol.codec.invalid-utf8`; `protocol.codec.noncanonical-encoding`; `protocol.codec.embedded-identity-mismatch`; `protocol.codec.payload-location-mismatch`; `protocol.codec.resource-limit-exceeded` |
| repository-target-resolution schema | `protocol.codec.invalid-repository-target-resolution`; `protocol.codec.embedded-identity-mismatch`; `protocol.codec.payload-location-mismatch`; `protocol.codec.resource-limit-exceeded` |
| Markdown parser | `protocol.model.invalid-markdown`; `protocol.budget.exhausted` |
| repository-target Markdown parser | `protocol.budget.exhausted` (InvalidText is a typed model row, not parser failure) |
| repository-tree index | `protocol.index.repository-tree-unavailable`; `protocol.budget.exhausted` |
| protocol-record index | `protocol.index.record-unavailable`; `protocol.budget.exhausted` |
| governed-reference index | `protocol.index.reference-unavailable`; `protocol.budget.exhausted` |
| repository-target-resolution index | `protocol.index.repository-target-resolution-unavailable`; `protocol.budget.exhausted` |
| repository-target demand projector | `protocol.budget.exhausted` |

One `IGovernedReferenceIndex` classifies each intent exactly once as
`CrossRecord`, `EmbeddedRecord`, or `Commit`, and independently classifies its
syntax and resolution. Rule overlap is explicit and fail-closed:

- RULE-0003 evaluates the common clickable/exact-target axes for all three
  reference kinds.
- RULE-0004 additionally evaluates anchor/fragment semantics only for
  `EmbeddedRecord`.
- RULE-0005 additionally evaluates owning-repository/full-SHA/commit-object
  semantics only for `Commit`.
- A proven embedded or commit intent may therefore produce distinct RULE-0003
  plus RULE-0004 or RULE-0003 plus RULE-0005 findings. There is no silent
  suppression.
- A specialized finding is emitted only when qualified evidence proves the
  specialized intent. Ambiguity yields unresolved evaluation; it never
  fabricates an anchor or commit finding.

Missing required documents/records use `ContextProof` plus the catalog-owned
`ExpectedSelector`. A missing member never receives a fabricated member root.

## Catalog evolution and complete activation

Complete activation never trusts the current manifest to prove its own
completeness. A genesis predecessor binding requires a null predecessor
snapshot, Added transitions for every current rule, and activation-proof
genesis authority. An existing binding requires a kernel-minted predecessor
snapshot whose catalog version and manifest/inventory digests match exactly and
whose CatalogVersion is lower. The snapshot retains the complete predecessor
manifest projection internally even though its public surface is bounded.

The kernel recomputes the current inventory digest, takes the ordinal union of
predecessor/current RuleIds, and requires exactly one transition row for every
member and no other row:

- `Unchanged` requires equal revision and semantic contract;
- `Added` has no previous revision and requires introduction authority;
- `Revised` has both revisions, a strictly greater current revision, and
  reviewed normative or defect/differential authority; and
- `Retired` has no current revision and requires retirement authority.

An artifact-only refactor retains `Unchanged`, keeps the rule revision and
normative digest, changes the artifact binding, and requires same-evidence
differential qualification. A behavior-changing defect is `Revised` even when
the prose bytes are unchanged.

For `Unchanged`, activation compares normative digest; both slot lists and
their requirement/material/target/capability contracts; expected selectors;
subject/surface/snapshot/operation axes; findings; evaluator failure codes; and
lifecycle/compatibility values. It excludes containing-blob/path selectors,
qualification-scenario lists, implementation/artifact identity, and enclosing
CatalogVersion. If executable component closure or artifact mapping changed,
ReviewedAuthority is mandatory and the trusted activation proof must attest
same-evidence differential qualification. Added, Revised, and Retired always
require ReviewedAuthority; its permalink and immutable-object proof are both
verified.

Every named-profile RuleId must be current and every named profile's RuleIds
must equal the full statically compatible active-rule subset for its exact
axes. `BaselineProfileName` resolves exactly one such complete default profile;
no caller or release author may narrow a verdict-bearing profile. Only after
these checks does the kernel mint the new snapshot. No SemVer range infers compatibility. A partial catalog, missing
transition, duplicate rule, transition/revision mismatch, unmapped
finding/failure, incompatible/omitted named-profile rule, or narrowed baseline
blocks complete activation.

## Failure, redaction, and report ownership

| Failure family | Owner | Semantic output |
| --- | --- | --- |
| Acquisition routing/source/provenance/freshness/completeness | [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) | Observed/failed/no-input proof candidate |
| Canonical codec/admission rejection | Joint [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)/[SUBF-0143](README.md#subf-0143) seam | Acquisition failure; no Observed context |
| Semantic model/index/evaluator inability | [SUBF-0143](README.md#subf-0143) catalog/kernel | Typed redacted `RuleEvaluationFailure` and `NotEvaluated` |
| Catalog/manifest/release/artifact/registration/intent/reference integrity | [SUBF-0143](README.md#subf-0143) activator/kernel | Stable `CatalogIntegrityCode`; abort, no semantic evaluation result |
| Host timeout/cancellation/unexpected runtime failure | Application/host | Operational failure; no cached semantic result |
| Stable report keys/messages/redaction/canonical bytes/JSON/digest | [SUBF-0154](README.md#subf-0154) | Later sealed report only |

No final finding/failure contains raw input, arbitrary message, exception text,
credential, cursor, ETag, provider DTO, machine path, or report serialization
metadata.

## Prior art and WIP disposition

The accepted [WIP extraction ledger](../../architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
remains canonical. The preserved code is design input only:

- `FeatureRecordRequiredPairRule` and
  `DecisionRecordRequiredStructureRule` contribute semantic seeds for
  RULE-0001/RULE-0002 after fresh implementation and qualification.
- `MarkdownDocumentIndex` and `ProtocolRecordIndex` contribute parse-once ideas
  after provider-neutral, release/schema/artifact-bound redesign.
- The hard-coded two-rule catalog, repository-only analysis context,
  caller-facing rule interface that emits final findings, report/CLI/exit/
  authority state, old projects/locks/workflow, and passing WIP state are
  rejected as carry-forward.
- RULE-0003 through RULE-0005 require fresh C# implementation.

No WIP source is extracted under the current directive.

## Distinct test intent and recurrence review

Active same-contract recurrence match: explicit `None`.

The full sibling inventory is:

| Scenario | Classification for [TEST-0210](test-cases.md#test-0210) |
| --- | --- |
| [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177), [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) | `Distinct`; existing semantic/route scenarios remain canonical while [TEST-0210](test-cases.md#test-0210) proves the shared typed C# kernel directly |
| [TEST-0220](test-cases.md#test-0220) and [TEST-0221](test-cases.md#test-0221) | `Distinct predecessor`; exact Domain vocabulary and evidence-carrier APIs remain separately owned |
| [TEST-0209](test-cases.md#test-0209) and [TEST-0222](test-cases.md#test-0222) | `Distinct future composition/report`; no child-result aggregation or premature serialization |
| [TEST-0211](test-cases.md#test-0211) | `Distinct future policy`; debt, waiver, extension, self-consumption, and enforcement remain outside this slice |
| [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) | `Distinct InfrastructureContract`; owns workflow invocation topology, never kernel semantics |
| preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) | `Distinct historical WIP`; collapsed repository/report/CLI model is not reused |
| [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191) and [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192) | `Distinct foundation`; portable runtime/process foundations are not catalog behavior |

### Frozen `B-RESOURCE-01` codec-local ledger contract

The repository-target implementation is exact-head hosted green and the owning
B wire ledger retains exact commit/run custody; R=0004 remains diagnostic-only
and canonical R=0005 remains immutable. At the resource design checkpoint B was `6/11`, cumulative A+B was `38/43`. The resource packet is a
Tests-owned conformance mirror of the already accepted production contract. It
adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBResourceLedgerTests.cs`,
changes no retained file, production/interface/project/package/lock/workflow,
and may contain at most `1,200` normalized lines. It does not activate cache,
admission, sealed-context, qualified-reference, Policy, C/D, Scenario, or
workflow behavior.

The test-owned declarations are exact:

```csharp
internal sealed class SemanticResourceUsageMirror
{
    internal long Bytes { get; }
    internal int MaxDepth { get; }
    internal long Nodes { get; }
    internal long Complexity { get; }
    internal static SemanticResourceUsageMirror Create(
        long bytes, int maxDepth, long nodes, long complexity);
}

internal sealed class SemanticResourceLocalUsageMirror
{
    internal long GeneratedBytes { get; }
    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal long AdditionalComplexity { get; }
    internal static SemanticResourceLocalUsageMirror Create(
        long generatedBytes, int layerDepth, long layerNodes,
        long additionalComplexity);
}

internal sealed class SemanticResourceBudgetMirror
{
    internal long MaximumBytes { get; }
    internal int MaximumDepth { get; }
    internal long MaximumNodes { get; }
    internal long MaximumComplexity { get; }
    internal static SemanticResourceBudgetMirror Create(
        long maximumBytes, int maximumDepth, long maximumNodes,
        long maximumComplexity);
}

internal sealed class SemanticResourceAllowanceMirror
{
    internal SemanticResourceBudgetMirror AggregateBudget { get; }
    internal SemanticResourceUsageMirror SelectedBaseline { get; }
    internal static SemanticResourceAllowanceMirror Create(
        SemanticResourceBudgetMirror aggregateBudget,
        SemanticResourceUsageMirror selectedBaseline);
    internal ResourceFitMirror FitLocal(
        SemanticResourceLocalUsageMirror localUsage);
}

internal enum ResourceCounterMirror { None, Bytes, MaxDepth, Nodes, Complexity }

internal sealed class ResourceFitMirror
{
    internal bool Fits { get; }
    internal ResourceCounterMirror FirstExceeded { get; }
    internal SemanticResourceUsageMirror? Aggregate { get; }
}

internal sealed class SemanticResourceContributionMirror
{
    internal int KindRank { get; }
    internal string RowKey { get; }
    internal SemanticResourceUsageMirror Usage { get; }
    internal static SemanticResourceContributionMirror Payload(
        string rowKey, long bytes);
    internal static SemanticResourceContributionMirror GeneratedBytes(
        string rowKey, long bytes);
    internal static SemanticResourceContributionMirror Layer(
        string rowKey, int depth, long nodes);
    internal static SemanticResourceContributionMirror ComplexityTerm(
        string rowKey, long amount);
}

internal sealed class SemanticResourceLedgerMirror
{
    internal IReadOnlyList<SemanticResourceContributionMirror> Contributions { get; }
    internal SemanticResourceUsageMirror Usage { get; }
    internal static SemanticResourceLedgerMirror Create(
        IEnumerable<SemanticResourceContributionMirror> contributions);
}

internal sealed class RepositoryTargetResourceInputMirror
{
    internal SemanticResourceAllowanceMirror Allowance { get; }
    internal SemanticResourceContributionMirror SelectedPayload { get; }
    internal static RepositoryTargetResourceInputMirror Create(
        SemanticResourceAllowanceMirror allowance,
        SemanticResourceContributionMirror selectedPayload);
}

internal sealed class RepositoryTargetResourceShapeMirror
{
    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal string InvocationDigest { get; }
    internal static RepositoryTargetResourceShapeMirror Create(
        int layerDepth, long layerNodes, string invocationDigest);
}

internal interface ISemanticResourceMeterMirror<TInput, TValue>
{
    SemanticResourceLocalUsageMirror MeasureLocal(
        TInput input, TValue value, CancellationToken cancellationToken);
}

internal enum ResourceFailureMirror
{
    ProducerRejected,
    RegistrationMismatch,
    IntentInvalid
}

internal abstract class ResourceProducerIntentMirror<TValue>
{
    private ResourceProducerIntentMirror();
    internal static ResourceProducerIntentMirror<TValue> Produced(
        TValue value, SemanticResourceLocalUsageMirror claimedLocalUsage);
    internal static ResourceProducerIntentMirror<TValue> Rejected(
        ResourceFailureMirror failure);
    internal abstract TResult Accept<TResult>(
        IResourceProducerIntentMirrorVisitor<TValue, TResult> visitor);
}

internal interface IResourceProducerIntentMirrorVisitor<TValue, TResult>
{
    TResult VisitProduced(
        TValue value, SemanticResourceLocalUsageMirror claimedLocalUsage);
    TResult VisitRejected(ResourceFailureMirror failure);
}

internal abstract class ResourceQualificationMirrorResult
{
    private ResourceQualificationMirrorResult();
    internal static ResourceQualificationMirrorResult Qualified(
        SemanticResourceLocalUsageMirror measuredLocalUsage,
        SemanticResourceLedgerMirror ledger);
    internal static ResourceQualificationMirrorResult Rejected(
        ResourceFailureMirror failure);
    internal abstract TResult Accept<TResult>(
        IResourceQualificationMirrorVisitor<TResult> visitor);
}

internal interface IResourceQualificationMirrorVisitor<TResult>
{
    TResult VisitQualified(
        SemanticResourceLocalUsageMirror measuredLocalUsage,
        SemanticResourceLedgerMirror ledger);
    TResult VisitRejected(ResourceFailureMirror failure);
}

internal sealed class RepositoryTargetResourceCoordinatorMirror
{
    internal ResourceQualificationMirrorResult Qualify(
        RepositoryTargetResourceInputMirror input,
        ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror> intent,
        ISemanticResourceMeterMirror<RepositoryTargetResourceInputMirror,
            RepositoryTargetResourceShapeMirror>? meter,
        CancellationToken cancellationToken);
}

internal sealed class ResourceLedgerCollisionMirrorException : Exception
{
    internal string RowKey { get; }
    internal ResourceLedgerCollisionMirrorException(string rowKey);
}
```

Every factory has a private instance constructor and defensively copies input.
Each abstract union owns exactly its two private nested sealed leaves; factories
construct those leaves and `Accept` dispatches only to the correspondingly
named visitor member. The collision exception copies its nonempty ordinal key
and has exact message `Conflicting resource row: <rowKey>.`.
Null top-level arguments fail with the exact argument name. Negative scalar,
empty/non-64-uppercase-hex digest, inconsistent `(depth=0,nodes>0)` or
`(depth>0,nodes=0)`, and depth outside `0..4` fail at construction before any
meter call. `RepositoryTargetResourceShapeMirror.Create(5, ...)` is the exact
schema-unreachable vector and is never described as budget exhaustion.
`RepositoryTargetResourceInputMirror.Create` accepts only a rank-0 payload row
whose one-row ledger usage is field-for-field equal to `SelectedBaseline`; a
wrong rank or baseline mismatch is `ArgumentException` with parameter
`selectedPayload`, also before metering.

Contribution ranks are payload `0`, generated bytes `1`, semantic layer `2`,
and additional complexity `3`. Payload/generated rows require positive Bytes
and contribute no depth/nodes; layer rows require positive depth and nodes and
contribute no bytes; complexity rows require positive Complexity. Zero
generated-byte and zero complexity terms are omitted. Ledger input is copied,
ordinal-sorted by rank then key, and must contain unique canonical keys. Exact-
equal duplicates collapse to one; the same key with unequal rank or usage throws
only `ResourceLedgerCollisionMirrorException` carrying that key. The coordinator
maps exactly that exception to `IntentInvalid`; it does not swallow any other
exception. Checked sums derive `Bytes = rank0 + rank1`, `MaxDepth = max
rank2 depth`, `Nodes = sum rank2 nodes`, and `Complexity = Bytes + Nodes + rank3`.

`FitLocal` uses checked 64-bit arithmetic and exactly these formulas:

```text
Bytes      = SelectedBaseline.Bytes      + local.GeneratedBytes
MaxDepth   = max(SelectedBaseline.MaxDepth, local.LayerDepth)
Nodes      = SelectedBaseline.Nodes      + local.LayerNodes
Complexity = SelectedBaseline.Complexity + local.GeneratedBytes
           + local.LayerNodes + local.AdditionalComplexity
```

It accepts equality and returns the aggregate; overflow is non-fit. First
exceeded order is exactly Bytes, MaxDepth, Nodes, Complexity. The canonical
budget is `(33554432,64,500000,34054432)`. Boundary vectors use arithmetic-only
fixtures without allocating proportional data: byte equality and first one-
over, node equality and first one-over, complexity equality and first one-over,
the legal repository-target depth `4`, first illegal depth `5` before metering,
and a combined node-plus-complexity one-over whose deterministic first failure
is Nodes. No impossible depth-64 repository-target success is fabricated.

The golden payload row key is
`0|protocol.repository-target-resolution|1|936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0`;
the codec layer key is
`2|protocol.codec.repository-target-resolution|1|0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF`.
Selected payload usage is `(1465,0,0,1465)` and independently measured local
usage is `(0,4,61,0)`. Qualified output contains exactly payload then layer and
aggregate `(1465,4,61,1526)`.

Qualification order is fail-closed: argument boundaries; cancellation;
producer intent. A rejected producer is propagated and never metered. A missing
meter returns `RegistrationMismatch`. A produced value is metered exactly once
with the same input/value/token; cancellation and any other meter exception
propagate unchanged. Claimed/measured inequality, invalid/overflowing ledger,
collision, or over-budget success returns `IntentInvalid` and no ledger escapes.
Only a completely valid result is Qualified. Meter output cannot inspect or
echo the claim. No cache entry, handle, admission, plan, outcome, or later
packet object is created here.

The one direct Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger`,
with only `ContractSlice=B`, no Scenario/Theory/class trait, and exact marker
`TEST-0210-B-BEHAVIOR-RED-0006`. Red replaces only the final valid coordinator
result with `null!`; only that null reaches direct `Assert.Fail(marker)`. The
packet-specific canonical invocation is exactly:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0006.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger"
```

One fresh external runner specializes the prior fail-closed custody contract to
that sole new source: exact hosted design HEAD/upstream/branch/status, source and
runner identities at four gates, six locks, warning-as-error Release build,
fresh DLL/PDB, `--no-build`, fresh one-file root, child-only timeout `300`, outer
`420000` ms, complete `8,388,608`-byte logs, `1,048,576`-byte report, secure XML,
native exit `1`, exact result/definition/entry/FQN/marker/sixteen counters, and no
forbidden diagnostics/attachments. `InvocationCommitted` irrevocably consumes
R=0006 for every outcome; no changed or unchanged retry exists. Green is focused
`1/1`, B `7/7`, A+B/full Conformance `39/39`, Domain `98/98`, and all retained
build/format/locks/diff/StructureOnly/publication/review gates. That exact
twelve-record design head passed hosted validation before canonical R=0006.

Canonical R=0006 was accepted once with native exit `1` and runner exit `0`;
report SHA-256 is `44A095FDE501917EE56823CE5BABBCF95AB83EE53E7A1ACA430B2614C5DD6A0E`
and TRX SHA-256 is `EC2AF7C6ECC03F039F2DEAC0258D34DCD07ACBAC5FBC6CC68E2B2644087E7518`.
Bounded green changes only the valid-success return, remains `1,176/1,200`
lines with zero production delta, and passes `1/1`, `7/7`, `39/39`, and `98/98`.
The resource packet is immutable `ReviewedHostedGreen`; its exact implementation
and hosted-run identities are owned by the canonical B ledger. Ubuntu passed in
`15m52s` and Windows in `49m31s`, while publication verification was correctly
skipped. Every B-CACHE/downstream hold remained through that gate.

### Frozen `B-CACHE-01` codec-model cache contract

`B-CACHE-01` starts only from the exact hosted-green resource predecessor above.
At this design checkpoint B is `7/11` and cumulative A+B is `39/43`. The packet
adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBDecodeModelCacheTests.cs`,
changes no retained source/test file and no production, interface, project,
package, lock, workflow, Scenario, admission, sealed-context, reference, Policy,
C, or D surface. The new file may contain at most `1,200` normalized lines;
`1,201` requires a reviewed redraw before build or red. The design cohort remains
the same twelve Markdown/memory paths, adds no tracked node, and must preserve at
least `2,048` bytes of typed-design per-blob headroom under schema 2.
P is `NotApplicable`: no retained compile seam is required. R adds the complete
new test-owned cache mirror with only its final valid aggregate result set to
`null!`; G changes only that final return to the already computed non-null
aggregate. No intermediate source identity is deliverable.

The Tests-owned cache mirror receives already validated codec-model canonical
key bytes; it does not duplicate writer, qualifier, resource-meter, or admission
semantics. Its exact declarations are:

```csharp
internal sealed class CodecModelCacheKeyMirror : IComparable<CodecModelCacheKeyMirror>
{
    internal string ReleaseIdentity { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes { get; }
    internal ReadOnlyMemory<byte> Digest { get; }
    internal static CodecModelCacheKeyMirror Create(
        string releaseIdentity, ReadOnlyMemory<byte> canonicalBytes);
    internal static CodecModelCacheKeyMirror CreateCollisionProbe(
        string releaseIdentity, ReadOnlyMemory<byte> canonicalBytes,
        ReadOnlyMemory<byte> forcedDigest);
    public int CompareTo(CodecModelCacheKeyMirror? other);
}

internal sealed class DecodeModelValueMirror
{
    internal string Identity { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes { get; }
    internal static DecodeModelValueMirror Create(
        string identity, ReadOnlyMemory<byte> canonicalBytes);
}

internal sealed class DeclaredDecodeFailureMirror
{
    internal string Code { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes { get; }
    internal static DeclaredDecodeFailureMirror Create(
        string code, ReadOnlyMemory<byte> canonicalBytes);
}

internal abstract class DecodeAttemptMirror
{
    private DecodeAttemptMirror();
    internal static DecodeAttemptMirror Succeeded(DecodeModelValueMirror value);
    internal static DecodeAttemptMirror DeclaredFailure(
        DeclaredDecodeFailureMirror failure);
    internal abstract TResult Accept<TResult>(IDecodeAttemptMirrorVisitor<TResult> visitor);
}

internal interface IDecodeAttemptMirrorVisitor<TResult>
{
    TResult VisitSucceeded(DecodeModelValueMirror value);
    TResult VisitDeclaredFailure(DeclaredDecodeFailureMirror failure);
}

internal enum DecodeCacheDispositionMirror { Produced, Joined, Retained }

internal sealed class DecodeCacheResultMirror
{
    internal DecodeAttemptMirror Attempt { get; }
    internal DecodeCacheDispositionMirror Disposition { get; }
}

internal sealed class DecodeModelCacheMirror
{
    internal static DecodeModelCacheMirror Create(
        string releaseIdentity, string sessionIdentity,
        int maximumEntries, long maximumCanonicalBytes,
        int maximumConcurrentAttempts);
    internal Task<DecodeCacheResultMirror> GetOrAddAsync(
        CodecModelCacheKeyMirror key,
        Func<CancellationToken, Task<DecodeAttemptMirror>> attempt,
        CancellationToken cancellationToken);
}

internal sealed class DecodeCacheIntegrityMirrorException : Exception
{
    internal string Code { get; }
    internal DecodeCacheIntegrityMirrorException(string code);
}
```

Every carrier has a private instance constructor, copies all text/bytes, rejects
null/empty identity and empty canonical bytes, and exposes no mutable array.
`Create` computes SHA-256 over exact key bytes. `CreateCollisionProbe` is the sole
test-only cryptographic-collision seam; it requires an exact 32-byte digest and
is used only to prove unequal-byte collision rejection. Ordering is unsigned
lexicographic canonical bytes, then shorter equal prefix first. The cache copies
its release/session identities, requires nonnegative retention count/bytes and a
positive concurrency ceiling, and owns no real `SessionCacheBudget` instance.
Exact null parameter names are `releaseIdentity`, `sessionIdentity`,
`canonicalBytes`, `forcedDigest`, `key`, and `attempt`. `GetOrAddAsync` order is
argument boundaries, pre-cancellation, release identity, digest/byte collision,
existing retained/in-flight lookup, then new queue registration. A producer that
returns null throws `InvalidOperationException` with exact message
`Decode attempt returned null.`, is removed, and is not cached.
Negative `maximumEntries`/`maximumCanonicalBytes` and nonpositive
`maximumConcurrentAttempts` throw `ArgumentOutOfRangeException` with that exact
parameter name before any cache state exists.

The three deterministic fixture keys are opaque, already validated upstream
cache-key frames; this packet intentionally does not reimplement key grammar.
Each is exactly `89` bytes. A/B/C Base64 and SHA-256 identities are respectively:

```text
A cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUE=
  3966ED0A5CD736B311F695A3746090A405345C47E8584888C7201D13F7583959
B cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUI=
  585852BDC1A3395DFC01611685BCDB7337C1AD6377142CAD63F946EADBF9A842
C cHJvdG9jb2wuY2FjaGUta2V5LmZyYW1lLnYxCgBxdWFsaWZpY2F0aW9uLXNsaWNlfG1hbmlmZXN0fDF8cmVwb3NpdG9yeS10cmVlfGluc3RydWN0aW9uLUM=
  AC7CB7EF1168A6590480B247EA91A1F75CC7F5CCE7B57F95F293B7410E7F94C4
```

They begin with the exact schema header and codec-model rank, share the frozen
release/schema/model fixture, differ only in the final discriminator, and sort
A < B < C. The collision probe uses B bytes with A's digest. A different release
identity or cache session uses a distinct cache and must invoke a fresh attempt;
passing a foreign-release key to an existing cache throws
`DecodeCacheIntegrityMirrorException` code
`protocol.cache.release-identity-mismatch` before registration.

The exact cache release identity is `qualification-slice|manifest|1` and session
identity is `session-01`; isolation probes use
`qualification-slice|manifest-foreign|1` and `session-02`. Successful model
identities are `model-a`, `model-b`, and `model-c`; declared failure is
`protocol.codec.invalid-repository-tree`. Canonical result/failure byte arrays
are deterministic repeated-byte fixtures whose lengths are chosen explicitly by
each boundary vector; their content is independently asserted before use.

For one cache, digest is the primary candidate bucket, but reuse additionally
requires exact release, byte length, and byte equality. Unequal bytes under one
digest throw only `protocol.cache.key-collision`, with exact message
`Conflicting decode cache key bytes.`, invoke no producer, publish no entry, and
are never cached. An exact queued or running key joins the same Task; the
producer is invoked once. A lock-held dispatcher sorts pending new keys by
canonical bytes and starts at most `maximumConcurrentAttempts`; joining callers
do not consume another slot. In-flight entries are never eviction candidates.
The owner receives `Produced`, callers attached before completion receive
`Joined`, and a later retained reuse receives `Retained`; all observe the same
immutable `DecodeAttemptMirror` instance. A producer delegate supplied on a
join or retained call is never invoked.

The single-flight schedule uses asynchronous run continuations and explicit
gates, never sleeps. Three A callers attach before the owner gate releases and
prove one invocation plus `Produced/Joined/Joined`. With concurrency `1`, A is
held running while C then B are queued; after A releases the observed start
order is exactly A, B, C. Cancellation of the owner or a thrown timeout/host
exception is observed by all joiners, removes the entry, and a later success
invokes exactly once again.

Only `Succeeded` and `DeclaredFailure` completions are retainable. Success cost
is exact model canonical-byte length; declared-failure cost is its exact failure
frame length. Cancellation, `TimeoutException`, any other unexpected exception,
and cache-integrity failure remove the in-flight entry, propagate unchanged,
and leave no retained entry; the next call is a fresh attempt. The first caller's
token owns the shared attempt. A pre-cancelled token fails before registration;
joiners observe the shared result and cannot substitute a different producer.

After each cacheable completion, the retained set plus that completion is sorted
by exact key bytes and greedily retained while both count and checked byte-cost
ceilings fit. Iteration continues after an oversized entry. Thus a later lower
key may evict a higher retained key, while an evicted/rejected higher key can
never become eligible after additional lower keys arrive. Count or byte ceiling
zero disables retention without disabling single-flight. Equality at both
ceilings succeeds; the first count or byte over rejects only the crossing entry.
Eviction changes reuse/invocation counts only, never returned semantic bytes.

Exact retention vectors are allocation-small. With count `2`/bytes `10`, A cost
`4` plus B cost `6` reaches both equalities and both retain; C cost `1` is the
first crossing entry and is produced but not retained. Starting with B/C cost
`5` each retains both; subsequently producing A cost `5` deterministically keeps
A/B and evicts C. B cost `11` is skipped as oversized while later C cost `4`
retains, proving iteration continues. Count `0` or bytes `0` produces twice for
two sequential calls. Checked cost overflow rejects retention and throws
`DecodeCacheIntegrityMirrorException` code
`protocol.cache.retention-cost-overflow`; it never wraps or evicts an unrelated
valid entry.

The one direct Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction`,
with only `ContractSlice=B`, no Scenario/Theory/class trait, and exact marker
`TEST-0210-B-BEHAVIOR-RED-0007`. It proves exact A/B/C key ordering, byte-equal
retained hit, forced collision, same-key concurrent single-flight, concurrency ceiling,
success and declared-failure retention, cancellation/timeout/host/integrity
non-retention, release/session isolation, zero retention, count/byte equality,
first-one-over, oversized-entry continuation, and deterministic low-key
eviction. Red replaces only the final valid aggregate outcome with `null!`; only
that null reaches direct `Assert.Fail(marker)`.

The packet-specific red command is exactly:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0007.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction"
```

One fresh external runner specializes the accepted R=0006 custody contract to
the sole new source and marker. It binds exact hosted design HEAD/upstream/
branch/status, source and self identities at start/pre-build/pre-test/post-test,
the six locks, warning-as-error Release build, fresh DLL/PDB, child-only timeout
`300`, monotonic outer bound `420000` ms, complete `8,388,608`-byte stdout/stderr
logs, `1,048,576`-byte report, secure XML, native exit `1`, exact one-result TRX,
sixteen counters, and zero forbidden diagnostics/attachments.
`InvocationCommitted` irrevocably consumes R=0007 for every outcome; no changed
or unchanged retry exists. Green is focused `1/1`, B `8/8`, A+B/full
Conformance `40/40`, Domain `98/98`, plus build/format/locks/diff/StructureOnly/
publication and two fresh `0/0/0` reviews. B-ADMISSION and every later packet
remain held until the exact cache implementation head is hosted green.

The exact design head passed Ubuntu in `20m54s` and Windows in `47m35s`, with
publication verification skipped. After one compile-only diagnostic and one
ValidateOnly runner-shape diagnostic, neither of which started the canonical
child, fresh runner identity `35,007` bytes / SHA-256 `5967E18E...FEA0AC`
accepted the sole R=0007: native/runner exit `1/0`, report SHA-256
`3B380FBB...9D3291`, and TRX SHA-256 `514CCAE6...FBFE52`. The red source was
`1,063/1,200` lines / SHA-256 `999B4E84...EDB9E`; the TRX sealed one exact
Failed result/definition/entry, all sixteen counters, and zero forbidden
attachments/collector data. Bounded green changes only the final aggregate
return and is `1,063/1,200` lines / `38,102` bytes / SHA-256
`41F3FC40...4717E4`, with zero production delta, build `0/0`, focused/B/full/
Domain `1/1`, `8/8`, `40/40`, `98/98`, and clean format/diff. Exact-tree
StructureOnly is green; publication evidence is `7/7` without a publication
claim; fresh code/test and evidence/scope reviews each closed `0/0/0`.
The owning ledger's exact cache implementation identity passed Ubuntu in
`20m42s` and Windows in `49m17s`; publication verification was skipped.
B-CACHE is immutable exact-head hosted history.

### Reviewed-local-green `B-ADMISSION-01` proof-candidate admission contract

`B-ADMISSION-01` started only from the exact hosted-green cache predecessor
above. At its design checkpoint B remained `8/11` and cumulative A+B remained
`40/43`; accepted R=0011 and bounded green now move them to `9/11` and `41/43`.
The executable mutation allowlist is exactly:

- modify
  `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBActivationTests.cs`;
- add
  `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBAdmissionProofTests.cs`.

Their combined normalized changed-line count is at most `2,400`; `2,401`
requires a reviewed redesign before build or red. This admission-only exception
does not change the general `1,200`-line B ceiling: the packet must close three
proof leaves, instruction and receipt framing, and the entire bijection/
lifecycle negative matrix in one test-owned boundary. Production, other retained
tests, project, package, lock, workflow, Scenario, Policy, C, D,
sealed-context, and qualified-reference deltas are zero. The design cohort is
exactly the twelve existing Markdown/memory paths frozen by the B plan; it adds
no tracked node or unique Markdown relation and retains schema-2 `512` nodes /
`8,192` relations / `1,048,576` bytes per blob / `8,388,608` aggregate. P is `NotApplicable`.
R contains the complete test-owned admission mirror and changes only the final
valid aggregate return to `null!`; G restores the already computed non-null
aggregate. The existing activation Fact stays green through R and G.

The retained activation file changes only two test seams. Its existing
`CreateManifest` helper becomes `internal static`. `ContractSliceBActivationProof`
accepts one optional enumerable of exact `IAdmissionProofCandidate` references,
materializes it once, rejects null elements/duplicates, and stores a private
read-only copy; the omitted/default collection is empty. Its existing codec
proof behavior is byte-semantically unchanged. `Proves(IAdmissionProofCandidate)`
returns true only for the same allowlisted object reference and false for null,
an equal-but-distinct object, or every default activation construction. It
never validates candidate contents itself and therefore grants no public
receipt authority.

The new Tests-owned declarations are exact:

```csharp
internal sealed class AdmissionInstructionMirror
{
    internal string SlotKey { get; }
    internal AdmissionProofKind Kind { get; }
    internal string ContractKey { get; }
    internal string ContractVersion { get; }
    internal string MaterialRole { get; }
    internal AcquisitionRequest Request { get; }
    internal ExactSha256Digest ManifestDigest { get; }
    internal ExactSha256Digest InstructionDigest { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes { get; }

    internal static AdmissionInstructionMirror Create(
        FinalizedPolicyManifest manifest,
        string slotKey,
        AdmissionProofKind kind,
        string materialRole,
        AcquisitionRequest request);
}

internal sealed class ClosedQualificationStateMirror
{
    internal ExactSha256Digest InstructionDigest { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal ModelContractIdentity OutputModel { get; }
    internal EvidenceBinding Binding { get; }
    internal ComponentArtifactBinding Codec { get; }
    internal SemanticResourceLocalUsageMirror ClaimedUsage { get; }
    internal SemanticResourceLocalUsageMirror MeasuredUsage { get; }
    internal DecodeCacheDispositionMirror CacheDisposition { get; }

    internal static ClosedQualificationStateMirror Create(
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        ModelContractIdentity outputModel,
        EvidenceBinding binding,
        ComponentArtifactBinding codec,
        SemanticResourceLocalUsageMirror claimedUsage,
        SemanticResourceLocalUsageMirror measuredUsage,
        DecodeCacheDispositionMirror cacheDisposition);
}

internal sealed class ObservedQualificationProofMirror : IObservedQualificationProof
{
    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    public ObservedAcquisitionResult Result { get; }
    public IReadOnlyList<ComponentArtifactBinding> QualifiedCodecs { get; }
    internal ClosedQualificationStateMirror State { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes { get; }

    internal static ObservedQualificationProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        ObservedAcquisitionResult result,
        IEnumerable<ComponentArtifactBinding> qualifiedCodecs,
        ClosedQualificationStateMirror state,
        ExactSha256Digest? forcedReceiptDigest = null);
}

internal sealed class FailedAttemptProofMirror : IFailedAttemptProof
{
    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    public FailedAcquisitionResult Result { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes { get; }

    internal static FailedAttemptProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        FailedAcquisitionResult result,
        ExactSha256Digest? forcedReceiptDigest = null);
}

internal sealed class NoInputRoutingProofMirror : INoInputRoutingProof
{
    public IReadOnlyList<string> SlotKeys { get; }
    public string ContractKey { get; }
    public string ContractVersion { get; }
    public ExactSha256Digest ManifestDigest { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest ReceiptDigest { get; }
    public AcquisitionRequest Request { get; }
    internal ReadOnlyMemory<byte> CanonicalReceiptBytes { get; }

    internal static NoInputRoutingProofMirror Create(
        FinalizedPolicyManifest manifest,
        AdmissionInstructionMirror instruction,
        ExactSha256Digest? forcedReceiptDigest = null);
}

internal abstract class AdmissionReceiptMirror
{
    internal string SlotKey { get; }
    internal ExactSha256Digest ReceiptDigest { get; }
    internal ReadOnlyMemory<byte> CanonicalBytes { get; }
    internal abstract TResult Accept<TResult>(IAdmissionReceiptMirrorVisitor<TResult> visitor);
}

internal sealed class ObservedAdmissionReceiptMirror : AdmissionReceiptMirror
{
    internal ObservedAcquisitionResult Result { get; }
    internal ClosedQualificationStateMirror State { get; }
    internal override TResult Accept<TResult>(IAdmissionReceiptMirrorVisitor<TResult> visitor);

    internal static ObservedAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        ObservedAcquisitionResult result,
        ClosedQualificationStateMirror state);
}

internal sealed class FailedAdmissionReceiptMirror : AdmissionReceiptMirror
{
    internal FailedAcquisitionResult Result { get; }
    internal override TResult Accept<TResult>(IAdmissionReceiptMirrorVisitor<TResult> visitor);

    internal static FailedAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        FailedAcquisitionResult result);
}

internal sealed class NoInputAdmissionReceiptMirror : AdmissionReceiptMirror
{
    internal AcquisitionRequest Request { get; }
    internal override TResult Accept<TResult>(IAdmissionReceiptMirrorVisitor<TResult> visitor);

    internal static NoInputAdmissionReceiptMirror Create(
        string slotKey,
        ExactSha256Digest receiptDigest,
        ReadOnlyMemory<byte> canonicalBytes,
        AcquisitionRequest request);
}

internal interface IAdmissionReceiptMirrorVisitor<TResult>
{
    TResult VisitObserved(ObservedAcquisitionResult result, ClosedQualificationStateMirror state);
    TResult VisitFailed(FailedAcquisitionResult result);
    TResult VisitNoInput(AcquisitionRequest request);
}

internal sealed class ContractSliceBAdmissionCoordinatorMirror
{
    internal IReadOnlyList<AdmissionReceiptMirror> Admit(
        FinalizedPolicyManifest manifest,
        IPolicyActivationProof activationProof,
        IReadOnlyList<AdmissionInstructionMirror> instructions,
        AcquisitionProofSet candidates,
        CancellationToken cancellationToken);
}
```

All concrete instance constructors are private; the abstract receipt base uses
one `private protected` constructor, and its leaf `Create` factories above are
the only construction route. The activation proof constructor appends
exactly `IEnumerable<IAdmissionProofCandidate>? admissionCandidates = null`
after its retained `bool provesMirror = true` parameter, materializes it once,
rejects null elements and duplicate object references with parameter name
`admissionCandidates`, and stores a read-only copy using reference equality.
Exact `Create` factories above copy every
text/list/byte input once, reject null/empty values with exact parameter names,
and expose only read-only projections. Candidate classes implement exactly one
public leaf interface; their common properties are the exact retained
`IAdmissionProofCandidate` properties. The Observed factory additionally takes
one canonical unique codec-binding list and one private
`ClosedQualificationStateMirror`; Failed takes one `FailedAcquisitionResult`;
NoInput has no result or state tail. The optional forced digest is accepted only
by these Tests-owned negative factories; it never changes canonical receipt
bytes. A negative-only dual-leaf implementation is confined to this Fact and
never forms a valid result. Receipt leaves are created only inside `Admit`, use
private constructors, and retain the independently recomputed canonical bytes.

The fixture starts from `ContractSliceBActivationTests.CreateManifest()` and
rebuilds only the three admission declarations/component bindings. Their exact
mapping is:

| Kind/rank | Contract key/version | Exact Tests-owned proof component | Surface / material |
| --- | --- | --- | --- |
| Observed / `0` | `protocol.admission.observed` / `1` | `MeAndAI.Protocol.Conformance.Tests.ObservedQualificationProofMirror` | Repository / `protocol.material.repository-tree` |
| Failed / `1` | `protocol.admission.failed` / `1` | `MeAndAI.Protocol.Conformance.Tests.FailedAttemptProofMirror` | Provider / `protocol.material.governed-text` |
| NoInput / `2` | `protocol.admission.no-input` / `1` | `MeAndAI.Protocol.Conformance.Tests.NoInputRoutingProofMirror` | Repository / `protocol.material.repository-target-resolution` |

For each row, component key/version are copied exactly from the corresponding
source admission declaration; only assembly/type become the named Tests-owned
proof type. The matching same-key old component binding is replaced once and
the new component is bound to the already present
`MeAndAI.Protocol.Conformance.Tests.dll` artifact. After those replacements the
source `MeAndAI.Protocol.Application.dll` artifact has no remaining component:
its exact row must be removed, while every other artifact filename/length/
digest/order remains byte-identical. Contract key/version, kind, activation
proof, payload schemas, cache budget, every non-admission component, catalog
slice, and complete catalog stay unchanged. Canonical write plus reparse must
preserve the new manifest digest, all three declaration/type bindings, and the
complete no-unbound-artifact component/artifact closure.

The three issued instructions are canonical by SlotKey and each owns exactly
one request/requirement:

| Slot / leaf | Target and request | Requirement |
| --- | --- | --- |
| `protocol.slot.provider-governed-text` / Failed | Provider / ProviderEvent, subject `protocol.test.subject`, source `protocol.test.provider`, target `provider-event-0001`; adapter `protocol.adapter.test` / `1`, source contract `protocol.source.test` / `1` | `protocol.requirement.provider-governed-text`, governed-text schema `1`, Provider |
| `protocol.slot.repository-target-resolution` / NoInput | Repository / ExactCommit, subject `protocol.test.subject`, source `protocol.test.repository`, target fixture commit: `0123456789abcdef0123456789abcdef01234567`; same adapter/source versions | `protocol.requirement.repository-target-resolution`, repository-target schema `1`, Repository |
| `protocol.slot.repository-tree` / Observed | the same Repository target/request identities | `protocol.requirement.repository-tree`, repository-tree schema `1`, Repository |

Every requirement retains the manifest slot's exact evidence kind,
completeness contract, accepted consistency classes, payload schema, and
material role. Request collections and `AcquisitionProofSet.Create` inputs use
single-use enumerables and must be enumerated once. Mutating any source array or
list after construction changes no instruction, candidate, or receipt.

Both instruction and receipt framing use strict UTF-8, no BOM, no trailing
bytes, unsigned big-endian `u32` counts/lengths, signed big-endian UTC ticks,
one-byte closed ranks, and lowercase 64-hex digest text. Exact ranks are leaf
Observed=`0`, Failed=`1`, NoInput=`2`; surface Repository=`0`, Provider=`1`,
Workflow=`2`, Release=`3`; snapshot ExactCommit=`0`, Candidate=`1`,
ProviderEvent=`2`, ProviderFullInventory=`3`, CapturedEvidence=`4`; status
Complete=`0`, Incomplete=`1`, Failed=`2`; cache Produced=`0`, Retained=`1`.
Joined and every unknown value are unencodable and invalid. Every `text` is
`u32 byte-length || bytes`; every nullable digest is one byte `0` for absent or
`1 || lowercase 64-byte hex` for present. The instruction header is exact ASCII
`protocol.test.admission-instruction/1\n`, followed by SlotKey, manifest digest,
leaf rank, contract key/version, material role, then the request target fields
`SubjectIdentity`, `SourceIdentity`, surface, snapshot kind, target identity;
adapter key/version; source key/version; and the one ordered requirement with
all accepted-consistency values. SHA-256 of all bytes is InstructionDigest.

The receipt header is exact ASCII `protocol.test.admission-receipt/1\n`,
followed by the complete length-prefixed instruction frame, singleton SlotKey,
proof component key/version/assembly/type, artifact filename/signed `i64`
length/digest, and the
variant tail. Observed writes status, complete scope target/boundary/timestamps,
ordered requirement-acquisition count plus each requirement key/status/failure
pair, ordered binding count plus each full location/payload schema/version/
digest/requirement-key set, ordered page count plus sequence/nullable cursor
digests/source-object count, total source-object count, one codec component/
artifact binding, then closed-state instruction/demand/model/binding, cache
disposition rank Produced=`0`/Retained=`1`, and claimed plus measured
`GeneratedBytes`, `LayerDepth`, `LayerNodes`, `AdditionalComplexity`. The
derived root-reference set must equal the binding-derived set but is not written
a second time. Failed
writes Started/Failed UTC ticks and canonical failure requirement/code pairs.
NoInput writes no variant tail. SHA-256 of the complete bytes is ReceiptDigest;
it is derived, copied, and never trusted from caller text.

The Observed vector uses a complete exact-snapshot repository-tree context,
one canonical binding and the manifest repository-tree codec binding. Its
closed state uses the same InstructionDigest, a deterministic DemandDigest,
the repository-tree output model/binding, equal claimed/measured local usage
`(GeneratedBytes=4, LayerDepth=1, LayerNodes=2, AdditionalComplexity=3)`, and
Produced cache disposition. A second valid vector uses Retained and yields the
same admitted semantics. Joined is deliberately not admission-stable: a joined
caller must consume the producer's Produced candidate or a later Retained
candidate, so a Joined closed state is `AdmissionProofInvalid`. Failed covers
its complete singleton requirement with
`protocol.source.unavailable` over fixed UTC interval
`2026-08-10T00:00:00.0000000Z` through `2026-08-10T00:01:00.0000000Z`.
NoInput has no acquisition result, failure, codec, resource, or cache state.

`Admit` order is exact: null arguments; cancellation; immutable manifest/
instruction canonical order and uniqueness; one-time candidate flattening;
null, exact-one-leaf, object-reference, SlotKey, and InstructionDigest
uniqueness; candidate/instruction bijection; manifest contract, kind/key/version,
exact CLR type, component/artifact, allowed surface/material, manifest digest,
request, activation-proof contract key/version/manifest digest/exact artifact
list, and `Proves(candidate)` reference result; instruction frame; variant tail; then
receipt-frame recomputation, supplied-digest collision partition, and digest
equality. Each successful receipt list follows instruction SlotKey order and is
privately closed; no caller candidate escapes.

For equal supplied ReceiptDigest values across distinct canonical slots, the
coordinator first compares the independently recomputed receipt frames. Their
embedded instruction/SlotKey fields make them unequal, so the pair fails with
`CatalogIntegrityCode.CacheIdentityCollision`. Same-object, same-slot, or same-
instruction duplicates have already failed as `AdmissionProofInvalid`. After
collision closure, any supplied digest unequal to its own SHA-256 frame is
`AdmissionProofInvalid`. Every other null, missing,
extra, duplicate, dual/zero leaf, multi/empty/wrong SlotKeys, foreign or stale
manifest, wrong instruction/request/contract/kind/type/component/artifact/
surface/material/activation reference, noncanonical order, incomplete Failed
coverage, Observed result/request/scope/acquisition/binding/page/source/reference
mismatch, codec-set mismatch, open/partial qualification state,
claimed/measured resource mismatch, foreign instruction/
demand/model/binding, or disallowed cache disposition is atomically
`AdmissionProofInvalid`. No prefix receipt set is returned.

No additional lifecycle class, interface, adapter, or reusable seam is added.
The Fact uses four local recording delegates over the already test-owned writer,
qualifier, meter, and cache objects solely to prove the following order/count
matrix. Source-intent rejection
calls writer/qualifier/meter/cache zero times and constructs only Failed. Writer
rejection calls writer once, the later three zero times, and constructs only
Failed. Successful write followed by qualifier rejection calls writer and
qualifier once, meter/cache zero times, and constructs only Failed. Only
successful write, qualification, one exact measured-state closure, and one
collision-checked cache completion construct Observed. A cache integrity or
host failure propagates and constructs no candidate. NoInput calls writer,
qualifier, meter, and cache zero times. Cancellation or timeout propagates
unchanged, constructs no candidate, admits nothing, and is never cached.
Admission itself reruns none of writer, qualifier, meter, or cache.

The one direct Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs`,
with only `ContractSlice=B`, no Scenario/Theory/class trait, and corrected exact
marker `TEST-0210-B-BEHAVIOR-RED-0011`. Before calling `Admit`, it assembles each
expected instruction/receipt vector through an independent Fact-local sequence
of explicit strict-UTF8 and `BinaryPrimitives` writes that shares no production
or mirror frame helper, then asserts byte equality and SHA-256 equality. It
proves three valid leaf receipts, canonical input-order independence, defensive
copies, exact lifecycle call counts, every failure partition above, no partial
escape, and unchanged activation behavior.
Red replaces only the final valid aggregate with `null!`; only that null reaches
direct `Assert.Fail(marker)`.

R=0008 is immutable diagnostic/no-success and is never rerun. The sole
committed child built with zero warnings/errors, selected the exact Fact, and
failed before the marker at `CreateAdmissionManifest` because the first design
retained the now-unbound `MeAndAI.Protocol.Application.dll` artifact. The exact
error was `System.FormatException: The manifest artifactFiles array must be
fully bound.` Its one-result TRX was `8,057` bytes with SHA-256
`A03E01BB075E75CA16B78D5A71C36DE18A4782A00BA0B86C61147757080F564A`;
raw marker count was `0`, so the runner correctly ended `OracleRejected`.
Report SHA-256 was
`81A6867573F55C4AB053A742A676DF67DA052E6B1389E7FB341BCB6FD12BA778`.
That failed attempt contributes no expected-red or green evidence.

R=0009 is also immutable diagnostic/no-success and is never rerun. The owning
ledger's exact linked first-correction design head/run passed Ubuntu `21m06s`,
Windows `50m29s`, with publication verification skipped. The sole committed
child rebuilt warning-free and
selected the exact Fact, but `CreateInstructions` called `Rules.Single()` on
the exact five-rule catalog and failed before the marker with
`System.InvalidOperationException: Sequence contains more than one element`.
Its sole TRX was `6,588` bytes / SHA-256
`CE7F41C8E07180DB5437B8EBA238E392E7070991D62BE6EBCBED9048E705A299`;
report/stdout/stderr were `575` / `2,878` / `196` bytes at SHA-256
`4C465CB3CB41F3B80282755551EC5678A6BFAB10A51722888F8B09B362BFD9C5` /
`0CED23BCD36169539D28B0DC509BD3C58E9BFD541E594B62E4CF079FC7280079` /
`DEF57F2B782F8E9BD59E6FD711410E10C460E911C416CB9CF2D47E00ABE6CE13`.
The TRX has one Failed result/definition/entry, exact `1/1/1` total/executed/
failed counters, raw marker count `0`, and exact stack ownership at
`CreateInstructions`; the runner correctly ended `OracleRejected`.

R=0010 is a third immutable diagnostic/no-success and is never rerun. The
owning ledger's exact linked second-correction design head and run passed
hosted validation (Ubuntu `21m14s`, Windows
`43m27s`, publication verification skipped). The sole committed child rebuilt
warning-free and selected the exact Fact, but the Joined-state negative vector
reached `AdmissionMirrorFrame.WriteObserved`. The existing frame switch encoded
only Produced/Retained and threw marker-free `System.InvalidOperationException:
Operation is not valid due to the current state of the object.` before the
coordinator could reject Joined. The one-result TRX was `8,395` bytes / SHA-256
`584BC5F27E66E38659E052791C5B01D10720AD3BE87A1E0A97FC43E45F83FEC2`,
had exact `1/1/1` total/executed/failed counters and raw marker count `0`, and
the runner ended `OracleRejected`. The owning ledger retains exact runner,
root, report, and log custody.

The retained second correction changes only the slot-selection fixture.
`RequireCanonicalSlot(manifest, slotKey, expectedOccurrences)` flattens the
catalog rules in their canonical manifest order, filters by exact ordinal
SlotKey, requires Provider governed-text=`3`, repository-target=`3`, and
repository-tree=`2`, and retains the first declaration only after every later
occurrence equals it in `Requirement`, `ProfileSurfaces`, `MaterialRole`,
`TargetSelectorKey`, and the ordered `Capabilities` sequence. Missing, extra,
or semantically unequal repeated declarations fail marker-free before any
instruction or candidate is constructed. No dictionary collapse, manifest
mutation, new carrier, admission behavior change, or line-cap exception is
permitted. Third-corrected R=0011 additionally maps only the test-owned receipt
frame's `DecodeCacheDispositionMirror.Joined` to byte rank `2`; Produced stays
`0`, Retained stays `1`, and every unknown value remains unencodable. Rank `2`
is deterministic invalid-candidate identity only: the coordinator must still
reject Joined as `AdmissionProofInvalid`, and no admitted semantics change.
The final valid aggregate remains `null!` for R and is exactly
`new AdmissionAggregateMirror(receipts, (1, 1, 1), true)` for G.

The packet-specific red command is exactly:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0011.trx" --filter "ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs"
```

A fresh external runner specializes the accepted R=0007 custody contract to
the two exact source paths, combined `2,400`-line ceiling, marker/FQN, fresh
R=0011 root/report/log paths, exact source/self/HEAD/upstream/branch/status and
six-lock identities at start/pre-build/pre-test/post-test, warning-as-error
Release build, fresh DLL/PDB, `--no-build`, child-only
`VSTEST_CONNECTION_TIMEOUT=300`, monotonic `420000`-ms bound, complete
`8,388,608`-byte stdout/stderr logs, `1,048,576`-byte atomic report, secure XML,
native exit `1`, exact one-result TRX, sixteen counters, and zero forbidden
diagnostics/attachments. The exact error Message is marker-only; the same
result's StdOut may contain zero or one byte-identical marker echo, and the TRX
may contain zero or one marker-free same-FQN `[FAIL]` RunInfo. Raw marker count
is therefore exactly one or two; no other marker or diagnostic is accepted.
`InvocationCommitted` irrevocably consumes R=0011 for
every process-create, timeout, exit, interruption, artifact, or oracle outcome;
no changed or unchanged retry exists. Only pre-commit preflight/build failures
may be corrected under a new reviewed source/runner identity.

Green is focused `1/1`, B `9/9`, A+B/full Conformance `41/41`, Domain `98/98`,
warning/error-free Release build, format/locks/diff/StructureOnly/publication,
and fresh code/test plus evidence/scope reviews `0/0/0`. At that design
checkpoint, B-SEALED-CONTEXT and every later packet remained held until the
exact admission implementation head became hosted green. The immutable evidence
below closes that predecessor gate; this historical admission design granted no
successor R or implementation authority by itself.

R=0011 is accepted/immutable under the exact one-shot custody in the owning
ledger. It proves the direct Fact, marker-only assertion path, exact
result/definition/entry identity, sixteen counters, source/runner/lock/build/
DLL/PDB closure, native exit `1`, runner exit `0`, and no forbidden diagnostic
or attachment. Bounded green changes only the final aggregate return and passes
focused `1/1`, B `9/9`, full Conformance `41/41`, Domain `98/98`, warning-free
Release build, format/diff, publication `7/7` without publication claim, and
StructureOnly. Code/test and evidence/scope reviews are each `0/0/0`.
B-ADMISSION then passed exact-head hosted validation: Ubuntu `20m17s`, Windows
`42m17s`, with publication verification skipped. It is immutable hosted-green
history and opens only the following design freeze.

### Frozen `B-SEALED-CONTEXT-01` ContextProof/Root contract

The packet reuses the already admitted, lifecycle-closed Tests-owned aggregate
without reopening admission. Its executable allowlist is exactly:

```text
modify tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBAdmissionProofTests.cs
add    tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBSealedContextTests.cs
```

The retained file changes `ExecuteContract` and `CreateAdmissionManifest` from
`private static` to `internal static`; prepends `CatalogAuthorityKind
AuthorityKind`, `ExactSha256Digest ManifestDigest`, and `CatalogVersion
CatalogVersion` to the Tests-owned `AdmissionAggregateMirror`; and populates
those three fields from the admitted manifest in its sole successful aggregate
return. Its Fact, marker R=0011, fixture, canonical frames, candidates,
receipts, negative matrix, and every existing assertion remain byte-
semantically unchanged. The identity extension is successor-owned, introduces
no second aggregate, and is the only detached manifest-authority carrier. The
new file plus these retained-file edits are at most `1,200` normalized changed
lines; `1,201` requires a new reviewed design. Production, public API, project,
package, lock, workflow, Policy, Scenario, C, and D deltas are zero.

The new file declares exactly this Tests-owned mint surface:

```csharp
internal sealed record SealedContextProjectionMirror(
    SealedEvaluationContext Context,
    QualifiedEvidenceReference ContextProof,
    IReadOnlyList<QualifiedEvidenceReference> Roots);

internal static class ContractSliceBSealedContextCoordinatorMirror
{
    internal static SealedContextProjectionMirror? Seal(
        FinalizedPolicyManifest manifest,
        AdmissionAggregateMirror aggregate);
}
```

There is no overload, generic variant, adapter, second aggregate, production
coordinator, public constructor/factory, raw-byte parameter, caller-supplied
digest, selector, or derivation seam. The coordinator uses the existing
assembly-internal constructors of the actual public `SealedEvaluationContext`
and `QualifiedEvidenceReference` carriers. The projection record copies its
root list; both product carriers retain their existing defensive copies.

The valid fixture is rebuilt twice from the same canonical A manifest graph:
`CreateAdmissionManifest()` supplies the exact finalized manifest, while
`ExecuteContract()` supplies the exact accepted aggregate. Their manifest
identities must be structurally and digest equal; object identity is not
required. The aggregate's frozen leading identity fields are exactly
`manifest.AuthorityKind`, `manifest.ManifestDigest`, and
`manifest.Slice!.CatalogVersion`; `Seal` compares all three before inspecting
any receipt. The manifest has `CatalogAuthorityKind.QualificationSlice`, a
non-null `CatalogSliceDeclaration`, null complete catalog, and catalog version
`1`. The aggregate has lifecycle closed, leaf counts `(1,1,1)`, and these exact
ordinal receipts:

```text
protocol.slot.provider-governed-text        Failed
protocol.slot.repository-target-resolution NoInput
protocol.slot.repository-tree              Observed
```

Failed and NoInput remain safe acquisition-attempt evidence but are not
admitted, add no scope, and mint no reference. Only the complete Observed
repository-tree receipt is eligible. Its slot occurs exactly twice in the
manifest rules with semantically equal declarations; the canonical declaration
owns requirement `protocol.requirement.repository-tree`. Its context has one
Complete requirement acquisition, one binding, no page, one source object, one
root, exact Repository/ExactCommit scope at the synthetic commit value: `0123456789abcdef0123456789abcdef01234567`,
and the privately retained
qualification binding equal to that context binding.

The resulting `SealedEvaluationContext` is exact:

- authority, manifest digest, and catalog version equal the finalized manifest;
- admitted slot keys are exactly `protocol.slot.repository-tree`;
- scopes contain exactly the one structural Observed scope;
- both lists are ordinal, unique, read-only defensive copies; and
- no payload bytes, context digest, proof candidate, receipt bytes, request,
  binding, cache/resource state, or failure object is exposed.

The ContextProof `QualifiedEvidenceReference` has kind `ContextProof`, exact
manifest/catalog/slot/requirement/scope, and
`QualificationProofDigest == ObservedAdmissionReceiptMirror.ReceiptDigest`.
Its Root, Location, ExpectedSelectorParentKind, and Selector are null and its
Derivations list is empty. Exactly one Root reference is minted from the one
accepted `RootEvidenceReference`; it retains the same top-level identities and
proof digest, has kind `Root`, exact structural Root and `Root.Location`, empty
Derivations, and null parent/selector. Neither reference can be widened into a
Derived or ExpectedSelector row in this packet.

Validation and error precedence are closed:

1. null manifest/aggregate or null collection element is the corresponding
   argument-boundary exception;
2. wrong authority, missing/wrong slice/complete-catalog state, catalog version,
   or any manifest-to-aggregate authority/digest/version inequality is
   `CatalogIntegrityCode.ManifestInvalid`;
3. open lifecycle, wrong leaf counts, null/duplicate/non-ordinal receipts,
   wrong receipt leaf partition, receipt-byte/digest drift, unknown/foreign
   slot, or failed/no-input admission is `AdmissionProofInvalid`; and
4. Observed request/slot/requirement/status/context/binding/root/qualification
   mismatch is `AdmissionProofInvalid`.

All negative vectors are marker-free and no partial context/reference set
escapes. Reordered input is rejected rather than silently sorted; accepted
output is already canonical. Input arrays/lists are mutated after sealing to
prove defensive copies. Equality is structural and ordinal; reference object
identity is never authority.
The coordinator accepts no caller-supplied reference, derivation, parent, or
selector. Its ContextProof/Root null-empty/exact-location shapes are therefore
positive output postconditions, not a synthetic `ReferenceInvalid` negative
seam. Malformed/foreign-session derived-reference rejection remains exclusively
owned by `B-CODEC-DERIVATION-01`, whose reference frame carries that identity;
this packet neither invents nor infers a session value.

The sole Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references`.
It is one direct non-skipped Fact with only `ContractSlice=B`, no Scenario,
Theory, class trait, overload, or second method. The canonical marker/TRX stem is
`TEST-0210-B-BEHAVIOR-RED-0012`. P is `NotApplicable`. R completes every valid
and negative assertion, then only the fully prepared valid `Seal` return is
`null!`; only that null reaches `Assert.Fail(Marker)`. G changes only the final
return to the already computed `SealedContextProjectionMirror`.

Canonical R is one exact Release `--no-restore --no-build --nologo --verbosity
minimal` test command with a fresh result root, exactly one R=0012 TRX logger,
and filter
`ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references`.
The packet retains process-scoped `VSTEST_CONNECTION_TIMEOUT=300`, monotonic
`420000`-ms child custody, complete stdout/stderr `8,388,608`-byte ceilings,
report `1,048,576`-byte ceiling, exact source/runner/build/PDB/lock/status
binding, and secure one-result TRX/16-counter/no-attachment oracle.
`InvocationCommitted` irrevocably consumes R=0012; no process-create, timeout,
exit, interruption, root/TRX, source/binary, or oracle failure may be retried.
Only pre-commit preflight/build failures may be corrected under a newly reviewed
identity without creating R.

Green is focused `1/1`, B `10/10`, A+B/full Conformance `42/42`, Domain `98/98`,
warning/error-free Release build, format, six locks, diff, StructureOnly,
publication evidence without publication claim, and fresh code/test plus
evidence/scope reviews `0/0/0`. B-CODEC-DERIVATION, B-CONVERGE, parent
[TEST-0210](test-cases.md#test-0210) activation, C/D, the runtime-efficiency
scenario, merge, release, publication, and DoD remain held. At that historical
freeze checkpoint, no red or implementation authority existed until the exact
design head became hosted green.

### Accepted `B-SEALED-CONTEXT-01` evidence and local-green closure

The corrected B-SEALED design predecessor passed exact-head hosted validation.
The sole canonical R=0012 invocation then produced native exit `1`, runner exit
`0`, and exactly one marker-owned Failed result/definition/entry. Its sole TRX
is `4,842` bytes / SHA-256
`24B78DD8AEF0B7D95B7D9FB653A233B333D2EB10DB71893516C00F01D73A98B4`;
the append-state report SHA-256 is
`3764392A7E5CDCC3E1A2F7C447067492053D25340C60DE408A765A77A15E3A21`.
The exact 16-counter, stack/echo/RunInfo, no-attachment, source/runner/build/
binary/lock/status oracle passed. R=0012 is accepted, immutable, and never
rerun.

Green removes the marker/null branch and restores only the already computed
projection. The retained admission source is `64,871` bytes / SHA-256
`D6E34E10A121447FE25906451FEAE2623D3B18D0B0AA1CD6EC2C1123C5066E63`;
the final sealed-context source is `534` lines, `20,197` bytes / SHA-256
`D83BB1E5A729F5890F8D2B577209C200802478EDEE6D0068C1D909BAF89F1AC6`;
combined changed lines are `549/1,200`. Focused/B/full Conformance/Domain are
`1/1`, `10/10`, `42/42`, `98/98`; warning/error-free Release build, format and
diff are green. B-SEALED is `ReviewedLocalGreen`; the exact implementation head
remains hosted pending and grants no successor execution authority by itself.

### Frozen `B-CODEC-DERIVATION-01` qualified-reference contract

This is the final executable B packet. Its exact mutation allowlist is:

```text
add tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBQualifiedReferenceTests.cs
```

No existing file changes. Production, public API, project, package, lock,
workflow, Policy, Scenario, C, and D deltas are exactly zero. The new file has a
normal B packet ceiling of `1,200` normalized lines; `1,201` requires reviewed
redesign.

The Tests-owned callable surface is exact:

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

No overload, generic variant, alternate codec/adapter, public factory,
production coordinator, raw payload/digest seam, selector, parser, index,
capability, cache, resource, admission, or kernel surface exists. `Seal`
defensively copies the frame collection and constructs only existing internal
`QualifiedEvidenceReference` / `QualifiedEvidenceDerivation` carriers.

The exact input session is the structural tuple already carried by the accepted
root: manifest digest, catalog version, slot, requirement, scope,
qualification-proof digest, root, and root location. A separately constructed
but field-equal parent is accepted; object identity is never authority. Any
inequality in that tuple is a foreign session and is rejected. The manifest
must be a QualificationSlice with null CompleteCatalog, and the supplied sealed
context must exactly match authority/digest/catalog, admitted slot and scope.

The canonical repository-tree slot/schema resolves exactly one manifest codec
component binding. That binding's artifact basename resolves exactly one
`ArtifactFileBinding`, and the schema's output model is the only accepted model.
The frame's component, artifact basename, artifact digest and output model must
be field-equal to those manifest-owned values. Component equality is ordinal
across key/assembly/type; model equality is ordinal across key/version/
implementation type; artifact identity is ordinal basename plus exact digest.

The valid frame list contains exactly two rows, already strictly ordinal by
`(TypedNodeKind, TypedNodeIdentity)`:

| Rank | Typed node kind | Typed node identity | Location |
| --- | --- | --- | --- |
| 0 | `protocol.codec-output.repository-tree` | `<model-key>@<model-version>` | the exact parent `SnapshotEvidenceLocation` |
| 1 | `protocol.codec-output.repository-tree` | `<model-key>@<model-version>#AGENTS.md` | `RepositoryEvidenceLocation` with the same exact scope, path `AGENTS.md`, blob identity equal to the ExactCommit target, and null line/anchor/property |

Snapshot equality and that one Repository refinement are the only
same-or-narrower forms. A changed scope, Provider/ReleaseAsset location,
repository path other than `AGENTS.md`, missing/foreign blob, or any refinement
is widening/drift and fails. The repository factory continues to own lexical
path/blob validity; this coordinator owns contextual narrowing.

Each output is a `QualifiedEvidenceReferenceKind.Derived` reference. It retains
the parent's exact manifest/catalog/slot/requirement/scope/proof/root, takes the
frame location, contains exactly one derivation, and has null
ExpectedSelectorParentKind and Selector. The derivation contains exact codec
component, artifact basename/digest, output model, null output capability,
exact typed-node kind/identity, and the same frame location. Outputs preserve
input ordinal order and the returned list is read-only/defensively copied.

Validation/error precedence is exact and no partial output escapes:

1. null `manifest`, `context`, or `frames` is its corresponding
   `ArgumentNullException`; a null frame row is `ArgumentException` with
   `ParamName=frames`;
2. wrong manifest authority/slice/complete-catalog state or sealed-context
   authority/digest/catalog/admitted-slot/scope drift throws
   `CatalogIntegrityCode.ManifestInvalid`;
3. a parent not structurally identical to the sole sealed Root, including
   foreign manifest/catalog/proof/scope/root/location identity or a non-Root,
   non-empty derivation, parent-kind, or selector field, throws
   `CatalogIntegrityCode.ReferenceInvalid`;
4. codec component/artifact/model drift or non-unique/missing manifest
   resolution throws `ReferenceInvalid`;
5. null/empty/whitespace or non-exact typed-node values, a widened/drifted
   location, or a location unequal to its derivation location throws
   `ReferenceInvalid`; and
6. non-strict ordinal input, duplicate `(kind,identity)` keys, an exact
   duplicate, or same-key unequal rows are collisions and throw
   `ReferenceInvalid` before construction.

The structural comparator covers reference kind, manifest, catalog, slot,
requirement, scope, proof, root, location, ordered derivations and null parent/
selector fields; each derivation comparator covers component, artifact,
artifact digest, model/capability, typed-node kind/identity, and location.
Repeating `Seal` with separately built field-equal inputs produces a field-equal
ordered result. Mutating the caller frame array after return cannot change it.

The sole Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing`.
It is one direct non-skipped Fact with only `ContractSlice=B`, no Scenario,
Theory, class trait, overload, or second method. Corrected marker/TRX stem is
`TEST-0210-B-BEHAVIOR-RED-0014`. P is `NotApplicable`. R executes all negative
and deterministic assertions, prepares both valid references, then changes only
the final nullable `Seal` return to `null!`; only that null reaches direct
`Assert.Fail(Marker)`. G restores only the prepared read-only result.

R=0013 is an immutable infrastructure diagnostic/no-success. ValidateOnly
proved exact head/upstream/branch/status, source/runner identities, six locks,
line budget, and absent artifacts. The sole Execute reached
`InvocationCommitted`, but VSTest failed before the Fact with
`SocketException (10055)` while binding its communication socket. Its TRX has
zero result/definition/entry nodes, all sixteen counters zero, one Error RunInfo,
and raw marker count zero. The preserved runner/report/TRX/log hashes are owned
by the B codec evidence ledger; R=0013 is never rerun.

Corrected R=0014 retains the same FQN and semantic null seam, follows one
warning-free Release `--no-restore` build, and uses one exact command:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory <fresh-root> --logger trx;LogFileName=TEST-0210-B-BEHAVIOR-RED-0014.trx --filter ContractSlice=B&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing
```

This is the R=0014-scoped replacement of the generic template. Its fresh
external regular/non-reparse CreateNew runner/report/stdout/stderr paths, exact
runner bytes/SHA/AST, exact source/head/upstream/branch/full porcelain status at
start/pre-build/pre-test/post-test, six locks, warning/error-free build,
fresh DLL/PDB, absent-then-empty result root, a single-node/non-reuse build
(`-m:1 /nr:false` and disabled shared compilation), process-only
`VSTEST_CONNECTION_TIMEOUT=300`, one child/logger, `420000`-ms monotonic bound,
complete `8,388,608`-byte log ceilings, `1,048,576`-byte report ceiling, native
integer exit `1`, secure no-DTD/no-external-resolution XML, and exact one-result
marker/optional-stack/echo/RunInfo/16-counter/no-diagnostic/no-attachment oracle
are mandatory. Overflow or truncation is `OracleRejected`.
Immediately before commit, no matching dotnet-test/testhost/vstest process may
exist and sixteen simultaneous loopback ephemeral listeners must open, remain
held, and dispose successfully. Failure is preflight-only. TRX structural/result
and infrastructure checks precede marker counting, so zero-result RunInfo
failure cannot be mislabeled as marker drift.
`InvocationCommitted` irrevocably consumes R=0014: process-create failure,
timeout, unexpected exit, interruption/crash, missing/malformed/extra TRX, or
any oracle rejection is immutable no-success/no-retry. Only a failure before
that atomic state may be corrected and revalidated without creating R.

The synchronized R=0014 design head passed exact-head Ubuntu/Windows hosted
validation before execution. The fresh `37,763`-byte runner, SHA-256
`0E437E0D6269D4A7691388E9AF9F340587B5C4DD0BDD8ACA08A96241B93532DE`,
parsed at `5,417` tokens / `40` statements / zero errors. ValidateOnly closed
all static, source, lock, socket, process, and absent-path predicates. The sole
Execute then accepted canonical R=0014 with native exit `1`, runner exit `0`,
one exact Failed result/definition/entry, marker count two, and exact counters.
The owning codec ledger retains the report/TRX/log paths and hashes. Green
changed only the final `null!` return to the prepared read-only result; Release
build was `0/0`, focused/B/full/Domain were `1/1`, `11/11`, `43/43`, and
`98/98`, and format was unchanged.

Green requires focused `1/1`, B `11/11`, A+B/full Conformance `43/43`, Domain
`98/98`, warning/error-free Release build, format, six locks, diff,
StructureOnly, publication evidence without publication claim, and fresh
code/test plus evidence/scope reviews `0/0/0`. `B-CONVERGE-01` remains a pure
P/R/G `NotApplicable` cumulative audit. Parent [TEST-0210](test-cases.md#test-0210), final
Scenario/status/owner and both workflow filters,
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), C/D,
activation, merge, release, publication, and DoD remain held. R=0014 is
immutable and never reruns. Its implementation is exact-head hosted green;
B-CONVERGE is merged/exact-main green.

## [TEST-0210](test-cases.md#test-0210) expected-red contract

[TEST-0210](test-cases.md#test-0210) is project-neutral, table-driven, and
fresh. It is one canonical composed scenario divided while `Planned` by the
sole exact partition trait `ContractSlice=A`, `B`, `C`, or `D`. Before final
activation, the activation packet freezes the complete retained-fact identity
inventory and proves that each identity has exactly one A-D `ContractSlice`
and no `Scenario` trait. One atomic candidate then adds
the `Scenario` trait for [TEST-0210](test-cases.md#test-0210) to that frozen inventory together with status, automation,
scenario-owner, both stable workflow test steps' run-block form, solution target, and
filter, plus
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).
Post-mutation validation proves both the ContractSlice and Scenario identity
sets equal the frozen inventory exactly. No new stable test ID is allocated by
this design.

| Slice | Direct contract |
| --- | --- |
| A | Catalog declarations, normative provenance/digests, canonical manifest parse/digest/typed projection, acyclic declaration/artifact/component/projector graph, predecessor transitions, exact cumulative-A exports, exact friend matrix, and negative public surface; no executable export, typed registration list, activation, or kernel |
| B | Cumulative-B 72 export shape; exactly the codec-registration/model-token subset; three protocol-writer-owned persistent payload wires; Tests-only private-stamp writer/qualifier/admission; decode/model cache; codec-local four-counter meter/ledger; ContextProof, Root, and codec-derived reference sealing; collision, ceiling, concurrency, cancellation, and host-failure lifecycle. B does not claim parser/index/projector/selector behavior, provider-neutral capability semantics, index cache, shared-root ledgers, or zero-candidate planning. |
| C | Cumulative-C 95 exports; first executable export activation and `CatalogSliceKernel`; a Tests-owned synthetic-complete graph with all six registration families plus exact registration/type-token/public-projection bijection and mismatch negatives; synthetic parser/index/projector/selector/evaluator implementations; provider-neutral capability semantics; both Markdown parsers; repository-tree, record, governed-reference, and repository-target indexes; staged Plan/Advance/Closure API; zero-to-N rounds and owner-sharded projected-slot aggregation; index cache/shared-root ledger; retained outcomes; applicability; kernel outputs/order/flags; transition/verdict truth tables. C consumes no real Policy registration or result. |
| D | Final cumulative 96 exports including the real qualification-only Policy entrypoint; direct real-Policy repetition of every B codec and C registration/parser/index/projector/selector/evaluator vector; fresh positive/negative/boundary/malformed RULE-0001..0005 repository/provider fixtures; exact code/provenance; overlap/co-report; sibling-equivalent outcomes. |

Each slice follows its own red/review/green gate after a later implementation
directive. Do not prewrite all four red groups and then implement one large
production block.

### Required [TEST-0210](test-cases.md#test-0210) groups

The future executable scenario directly covers:

- exact per-assembly public type/member/nullability/factory inventory and zero
  Domain export delta;
- no public constructor/factory on either Policy export;
  `RuleApplicabilityInput`/`RuleEvaluationInput`; `QualifiedEvidenceHandle` and
  final qualified-reference/selector values; kernel-minted `RuleFinding`,
  `RuleEvaluationFailure`, and `RuleEvaluation`; or plans, closures, and final
  results. The deliberately public Policy intent factories remain allowed;
- no consumer registration, `Add`/`Register`, reflection/DI discovery,
  `IServiceProvider`, `object`, `dynamic`, raw DTO/JSON, I/O, host, CLI,
  enforcement, debt, waiver, report, publication, or authority API;
- qualification-slice activation and real-policy refusal to expose a complete
  pack or verdict;
- authoritative rejection of partial, extra, duplicate, retired, unmapped,
  transition-incomplete, profile-narrowed, manifest-tampered, artifact-
  mismatched, or cyclic/self-digest input;
- every exact normative selector, fragment byte length/digest, rule digest,
  qualification link, revision, and Unchanged/Added/Revised/Retired evolution;
- behavior-changing defect versus artifact-only refactor;
- observed/failed/no-input proof candidates, forged/mismatched/stale/partial
  candidates, exact route reconciliation, and kernel-only absence;
- route/authority/capability denial never becoming Absent;
- one manifest codec component owns both canonical writer and qualifier;
  Application/provider adapters contain no wire encoder; writer bytes match
  golden vectors and round-trip through the paired qualifier; one writer per
  retained binding, one qualifier per cache miss, then one Conformance admission
  coordinator with neither operation rerun;
- repository/provider inputs producing the same common typed capability with
  distinct qualified locations;
- decode-key isolation, exact byte/length collision rejection, cross-release
  isolation, deterministic single-flight, semantic-failure memoization, and no
  timeout/cancellation caching;
- index-key structural context/root/location isolation, same bytes at another
  path, session bounds, and deterministic eviction;
- exact family-specific ledger row selection, success-only `MeasureLocal`
  invocation, meter/claimed-local equality, over-budget success rejection, zero-demand
  row omission, and a closed derivation factory during metering;
- context-proof/root/derived/expected-selector variants, zero-binding proof,
  same-or-narrower refinement, foreign handle rejection, and missing-member
  provenance without fabricated locations;
- static selection versus applicability `Applicable`, `NotApplicable`, and
  `Unresolved`; false avoids evaluation-only acquisition; unresolved becomes
  `NotEvaluated`; shared slots acquire once;
- unknown/duplicate finding/failure intents, foreign handles, disallowed
  reference kind, missing/extra/duplicate evaluation, and runtime-integrity
  abort;
- `Satisfied`, `Violated`, `NotApplicable`, and `NotEvaluated` exact shapes,
  including `IsApplicabilityUnresolved` and retained proven partial findings;
- one sealed acquisition outcome per activated slot, all static/projected
  Complete/Incomplete/Failed attempt shapes, exact target retention,
  `projector-failed` zero-attempt framing, `projected-resource-failed`
  all-attempt aggregate-failure framing, OutcomeDigest collision checks,
  missing/extra candidate integrity abort, cumulative closure/final-result
  copying, and acquisition/rule-status independence;
- slice flags without verdict and complete-catalog
  `HasKnownViolation`/`HasUnresolvedRequiredEvaluation`/verdict precedence plus
  self-contained slice Catalog/ManifestDigest identity;
- deterministic order across input permutations, dictionary order,
  concurrency, culture, line endings, OS, and cache eviction;
- semantic byte/depth/node/complexity exhaustion versus operational host
  timeout/cancellation; and
- every RULE-0001..0005 positive, negative, boundary, malformed, absence,
  repository body, provider body, and explicit co-report case.

The slice-specific matrix is also mandatory and may not be deferred to a later
scenario:

- A proves exact cumulative count 48, the 27-row manifest logical producer/type-
  contract partition and 35-row full component union, the demand-projector
  declaration/manifest field order, missing/extra/duplicate projector
  declaration or component mapping, input/output slot/capability closure,
  projected-applicability rejection, the exact numbered twenty-two topology
  mutations in the current frozen contract, computed successor/predecessor
  roots, canonical byte/digest/typed-projection behavior, and the exact
  no-extra-friend matrix. It proves no executable registration or activation.
- B proves cumulative count 72 and the non-authoritative Tests-owned codec
  mirror through private-stamp `Activate ->
  WriteCanonicalPayload -> Qualify -> Admit` mirror; golden writer byte vectors,
  writer/qualifier round trips, and malformed header/UTF-8/length/rank/order/
  duplicate/trailing-byte cases for repository-tree, governed-text, and
  repository-target-resolution. The target wire covers CommitObject, TagRoot,
  CapturedSnapshotPath, content ordinal/deduplication, path-only versus retained
  content, per-content/per-instruction codec ceilings, and self-inconsistent
  identity rejection. B also proves exact scope/location echo; forged/stale
  instruction or demand collision frames; one private stamp/candidate per
  instruction; binding-to-codec bijection; same OID/different owner; Missing
  versus failed acquisition; success-only codec-local typed metering, every
  reachable governing four-counter equality/one-over boundary, and each
  algebraically dominated counter/first-governing-rank vector plus every
  schema-unreachable maximum/structural-rejection vector; decode/model-cache identity,
  collision, single-flight, eviction, cancellation/host-failure behavior;
  ContextProof/Root/codec-derived reference sealing; and no admission writer/
  codec rerun. It claims no parser/index/projector/selector, provider-capability,
  index-cache, shared-root-ledger, zero-candidate, or public-plan behavior.
- C proves cumulative count 95, first executable export activation, all six
  final registration lists and their exact count/order/bijection with the
  27-row manifest partition, model/capability type tokens, and public
  `Components` projection. Missing/extra/duplicate codec/parser/index/projector/
  selector/evaluator registration, a foreign or wrong generic CLR type/instance,
  and public projection drift are `RegistrationMismatch`. C also proves
  Tests-owned synthetic implementations for both Markdown parsers and every
  index/projector/selector/evaluator family, and
  `PlanApplicability -> CloseApplicability -> PlanEvaluation ->
  EvaluationPlan|EvaluationClosure`, no early repository-target request, first
  static Advance, later owner-sharded target Advance, proof-free Evaluate, and
  synthetic deterministic zero/one/N graphs. It covers CommitObject, TagRoot,
  CapturedSnapshotPath, historical Markdown InvalidText/anchor and non-Markdown
  line paths; empty demand as zero instruction/I/O/codec but exactly one zero-
  model Tests synthetic target-index invocation; shared projector exact-once;
  globally contiguous ItemId with duplicate selector occurrences retained; one
  instruction per owner; equality/one-over for the 64 unique-content-key,
  16,777,216 aggregate unique-content-byte, and 67,108,864 complete-payload-byte
  plan-global ranks plus deterministic first-crossing framing;
  capture-manifest expected-content authority; target-parser 33,554,432-byte
  equality/one-over budget; target-model/target-Markdown success pairing versus
  declared semantic failure; input-only parser-model cache identity with
  output classification excluded and zero-row/hit/cross-shard-plan isolation;
  index-cache
  full source/authority/selector identity; selected-row ledger union without
  shared-root double count; zero-candidate row omission; all-shards-or-no-slot
  aggregate proof/scope/acquisition; Complete/Incomplete/Failed static and
  projected outcomes, `projector-failed` and `projected-resource-failed` modes,
  target/outcome digest, invalid-
  candidate abort, self-contained slice identity, cumulative closure and terminal-rule
  projections; input permutation/culture/concurrency/cache-eviction digest
  equality; skipped/reused/foreign/wrong-round/no-progress rejection; and
  cancellation at PlanEvaluation/Advance/Evaluate without consuming state. No
  C fixture names or invokes a real Policy type.
- D proves final cumulative count 96 and first proves the exact real
  `InitialRuleQualificationPolicy.Export` graph. Every real Policy paired writer/
  codec then repeats B's golden/malformed/round-trip/resource vectors and every real
  parser/index/projector/selector/evaluator registration repeats C's vectors
  without a Policy Tests friend or a consumed B/C result. Only after the D-owned
  real writer/codec/parser/index/projector/kernel path is green does that same
  D mirror/session construct a fresh Conformance-registered RULE-0001 input from
  C's immutable fixture definitions/data; it never imports a C handle, cache
  entry, runtime result, or assertion. RULE-0003/0004 cover
  tag-root, historical/current blob, captured-snapshot line, Markdown anchor,
  wrong containing target, and fragment specialization; RULE-0005 covers same/
  external repository, same SHA under different owners, duplicate/zero commit
  references, qualified Missing, wrong owner, wrong object type/OID, and Exact.
  Repository/provider equivalence, RULE-0003/0005 co-reporting, and every initial
  rule's positive/negative/boundary/malformed cases are direct D assertions.

### Exact expected-red oracle

After a later directive, Gate 3 proceeds one ContractSlice at a time and splits
surface absence from behavioral absence. The later authorized scaffold step
first creates all reviewed empty product projects, the Conformance.Tests
project/reference graph, and locked restore graph; no product type exists yet.
Every red starts from the accepted exact-main predecessor plus all earlier
slices green, performs one exact locked restore, records every lock SHA-256,
and proves lock bytes unchanged.

`SurfaceRed` adds exactly one permanent ten-line compile anchor and runs:

```text
dotnet build tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --nologo --verbosity minimal
```

The exact file shape is namespace/open brace, an internal static
`ContractSliceXSurfaceRed` class/open brace, line 5
`        internal static void Require(<Anchor> value)`, a body that assigns
`_ = value`, then the three closing braces. A valid SurfaceRed has zero
warnings and exactly one normalized compiler diagnostic:

| Slice | Exact diagnostic tuple `(Id, path, start, endExclusive, token, semantic FQN)` |
| --- | --- |
| A | `CS0246`, `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceA.SurfaceRed.cs`, `5:38`, `5:52`, `CatalogVersion`, `MeAndAI.Protocol.Conformance.Abstractions.CatalogVersion` |
| B | `CS0246`, `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceB.SurfaceRed.cs`, `5:38`, `5:65`, `IObservedQualificationProof`, `MeAndAI.Protocol.Conformance.Abstractions.IObservedQualificationProof` |
| C | `CS0246`, `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceC.SurfaceRed.cs`, `5:38`, `5:52`, `IRuleEvaluator`, `MeAndAI.Protocol.Conformance.Abstractions.IRuleEvaluator` |
| D | `CS0246`, `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceD.SurfaceRed.cs`, `5:38`, `5:68`, `InitialRuleQualificationPolicy`, `MeAndAI.Protocol.Policy.InitialRuleQualificationPolicy` |

The anchor file declares the semantic FQN's namespace, so the unqualified
token is the only unresolved symbol. SurfaceRed makes no test-discovery claim.
Any additional compiler diagnostic or any NU/MSB/analyzer/project/reference/
predecessor/environment error is invalid red.

After reviewed SurfaceRed, implement only that slice's complete structural
delta until the anchor and exact API tests compile. Then add only the reviewed
partial test belonging to [TEST-0210](test-cases.md#test-0210) for the slice's
first semantic increment. While the canonical scenario remains `Planned`, the
test has exactly one matching `[Trait("ContractSlice", "<A|B|C|D>")]` and no
`Scenario` trait; its exact FQN and packet record preserve the parent-scenario
link. The final activation uses this closed order:

1. In the exact pre-activation parent, freeze one ordinal table `E` from every
   retained test-method FQN to its A-D slice, its derived per-slice counts, the
   table digest, and the parent SHA. `E` includes the exact C# verifier FQN
   `MeAndAI.Protocol.Conformance.Tests.ContractSliceActivationTopologyTests.Matches_exact_contract_slice_scenario_inventory`.
   Run `ContractSlice=A|ContractSlice=B|ContractSlice=C|ContractSlice=D` and
   require selected = discovered = executed = passed = `|E|`, failed = skipped
   = zero, and the executed FQN set = `E.Keys`.
2. The verifier reflects over direct, non-skipped `[Fact]` methods in its
   executing assembly. For `E`, `[Theory]`, inherited/generic/overloaded facts,
   class-level partition/scenario traits, duplicate FQNs, and a second
   handwritten count are forbidden. It requires the reflected A-D
   ContractSlice identities to equal `E.Keys`, exactly one direct
   ContractSlice per identity equal to `E[FQN]`, pairwise-disjoint slices, no
   foreign A-D fact, and the cardinality equality
   `|E| = |A| + |B| + |C| + |D|`. Its own direct Scenario-trait cardinality is
   the phase selector: zero requires zero target Scenario traits on all `E`
   facts; exactly one target trait requires the target Scenario identity set to
   equal `E.Keys` with exactly one target Scenario trait per fact; any other
   self state or any other Scenario value on an `E` fact fails. Before
   activation, it constructs the target ID from split fragments so a planned
   source does not assert the scenario.
3. In one reviewed candidate with no published intermediate, add exactly one
   literal `Scenario` trait for [TEST-0210](test-cases.md#test-0210) to every `E` fact and change status,
   automation, scenario-owner, both stable workflow test steps' run-block form,
   solution target, and filter, plus
   [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
   together. No FQN, method, `E` row, slice, production, project, package, or
   lock mutation is permitted in this activation commit. A partial mutation is
   invalid and cannot be committed.
4. At the candidate head, rerun the A-D ContractSlice union, then the focused
   `Scenario` filter for [TEST-0210](test-cases.md#test-0210), then the final solution-level combined route.
   Each applicable run must have zero failed/skipped tests and exact
   selected/discovered/executed/passed cardinality. Both focused identity sets
   must equal the same `E.Keys`; the always-selected verifier must prove the
   post-activation mapping above.

This C# fact is introduced as the last retained D fact before activation with
only `ContractSlice=D`; its method body, FQN, and `E` table remain
byte-identical in the activation commit, while only its direct trait metadata
gains the Scenario trait that selects the final phase. It is executable
ownership of the bijection and remains part of
[TEST-0210](test-cases.md#test-0210); it allocates no additional stable scenario ID. [TEST-0074](../FEAT-0012-v082-correction/test-cases.md#test-0074) retains
the distinct lifecycle/authority check, and
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
retains workflow-invocation ownership.

The structural-delta checkpoint has one reproducible, compile-green temporary
red state and no discretionary stub behavior. In the uncommitted red worktree,
the one parse/activation/export member used by the first increment returns
`null!` from its declared non-null reference return/property and performs no
other work: A uses `FinalizedPolicyManifest.ParseCanonical`, B uses
`ContractSliceBAdmissionHarness.Activate`, C uses `ConformanceKernel.Activate`,
and D uses `InitialRuleQualificationPolicy.Export`. Nullable analysis therefore
emits no warning. The exact absent-behavior predicate is that A returned null
instead of the parsed non-null manifest, or B/C/D returned null instead of
their exact activated harness/kernel/export. Only that predicate calls
`Assert.Fail(exactMarker)`. An exception from A's positive canonical fixture, a
non-null but structurally wrong projection/digest, a wrong B/C/D exception/code,
or a structurally wrong non-null graph uses marker-free exact assertions or
propagates and cannot masquerade as the planned red. No throwing placeholder,
`default` factory graph, permissive parse/activation, clock/random input, or already-green
implementation is an admissible first-red predecessor. The temporary `null!`
body and red test are removed/replaced within that slice's reviewed red-to-green
operation and are never committed or pushed as an active red state.

Create one fresh absolute directory outside the repository under the operating-
system temporary root. Its basename is exactly
`meandai-test-0210-<lowercase-slice>-<32-lowercase-hex-guid>`; it did not exist
before creation and is empty immediately before the command. Record its
resolved path and run exactly one test CLI invocation. Do not run a discovery
pre-pass, `--list-tests`, retry, or second logger:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --nologo --verbosity minimal --results-directory "<fresh-absolute-temp-directory>" --logger "trx;LogFileName=<exact-marker>.trx" --filter "ContractSlice=<slice>&FullyQualifiedName=<exact-test-fqn>"
```

That planned-phase filter deliberately uses only `ContractSlice` plus exact
FQN. A `Scenario` filter for [TEST-0210](test-cases.md#test-0210) is valid only after the final atomic
activation above.

The first required `BehaviorRed` identities are:

| Slice | Exact test FQN | Exact marker and TRX filename |
| --- | --- | --- |
| A | `MeAndAI.Protocol.Conformance.Tests.ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest` | `TEST-0210-A-BEHAVIOR-RED-0001` / `TEST-0210-A-BEHAVIOR-RED-0001.trx` |
| B | `MeAndAI.Protocol.Conformance.Tests.ContractSliceBActivationTests.Activates_exact_codec_mirror` | `TEST-0210-B-BEHAVIOR-RED-0001` / `TEST-0210-B-BEHAVIOR-RED-0001.trx` |
| C | `MeAndAI.Protocol.Conformance.Tests.ContractSliceCActivationTests.Activates_exact_synthetic_registration_graph` | `TEST-0210-C-BEHAVIOR-RED-0001` / `TEST-0210-C-BEHAVIOR-RED-0001.trx` |
| D | `MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyExportTests.Exports_exact_real_registration_graph` | `TEST-0210-D-BEHAVIOR-RED-0001` / `TEST-0210-D-BEHAVIOR-RED-0001.trx` |

The exact A fixture is the strict UTF-8 encoding of the following one-line JSON
followed by exactly one LF and no BOM:

```json
{"schema":"protocol.policy-manifest.v1","authorityKind":"qualification-slice","sourceCommit":"0000000000000000000000000000000000000001","protocolVersion":"0.0.0","catalogVersion":1,"slice":{"sliceKey":"protocol.catalog-slice.test-empty","sliceVersion":"1","rules":[]},"schemaRegistry":{"payloadSchemas":[],"parsers":[],"indexes":[],"demandProjectors":[],"admissionProofContracts":[],"cacheBudget":{"maxDecodeEntries":1,"maxDecodeCanonicalBytes":1,"maxIndexEntries":1,"maxIndexNodes":1,"maxConcurrentDecodeAttempts":1,"maxConcurrentIndexAttempts":1,"retentionPolicy":"retain-lowest-canonical-keys"}},"activationProofContract":{"contractKey":"protocol.activation-proof.test","contractVersion":"1","proofComponent":{"componentKey":"protocol.activation-proof.test","componentVersion":"1"}},"artifactFiles":[{"fileName":"ContractSliceA.Proof.dll","byteLength":1,"artifactDigest":"6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d"}],"components":[{"component":{"componentKey":"protocol.activation-proof.test","componentVersion":"1","assemblyName":"MeAndAI.Protocol.Conformance.Tests","typeName":"MeAndAI.Protocol.Conformance.Tests.ContractSliceAActivationProof"},"artifactFileName":"ContractSliceA.Proof.dll"}]}
```

A green first increment returns a non-null manifest whose authority, commit,
protocol/catalog/slice identity, empty rule/registry arrays, positive cache
budget, activation-proof component, artifact/component mapping and order equal
that fixture; `CompleteCatalog` is null; `ManifestDigest` is SHA-256 of those
exact 1,222 bytes including the LF,
`59ef47142c3c0d1e39825bd0e2e11d8f28093bed1ad93c12e251bb95cf5a4d64`.
Mutating the caller-owned source array after the call changes neither the
digest nor any projection. Source review, not that black-box assertion alone,
proves the required copy-at-entry and no-retained-raw-bytes implementation.

These are deliberately the first topological behavior of each slice. A parses
the exact minimal positive qualification manifest above, proves its SHA-256
digest, full typed projection, and mutation-independent public result; source
review proves copy-at-entry and discarded raw bytes. It
constructs no export and activates no kernel. B proves only codec-mirror
activation before admission cases. C proves the Tests-owned synthetic complete
registration graph before any plan/evaluator behavior and is the first
executable export/kernel activation. The old A missing-registration oracle is a
later C registration-mismatch increment and may not reuse A's marker; its exact
transient predecessor and C marker require review immediately before that red. D
loads the real `InitialRuleQualificationPolicy.Export` and proves only its exact
public/internal registration graph. The planned later FQN
`MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0001_against_fresh_qualified_fixture`
is not D's second increment and receives no marker until the preceding real
Policy writer/codec/parser/index/projector/kernel vectors are enumerated,
reviewed, and green. Its fixture then contains one canonical feature directory,
its valid `test-cases.md`, and no `README.md`; the D mirror/session freshly
qualifies it into a Conformance-registered input. Green requires exactly one
`protocol.feature.readme-missing` finding with the designed primary/related
references and zero failures. Its exact transient empty-intent predecessor,
marker/TRX, and single absent-behavior predicate must be reviewed immediately
before that later red; no C runtime handle/result may shortcut the dependency.
Forged-admission, false-applicability, and other end-to-end cases follow the
same dependency-closed increment rule.

The reviewed test calls `Assert.Fail(exactMarker)` only on the one exact absent-
behavior predicate named by that increment. Source review plus the immutable
locked xUnit `2.9.3` contract proves that direct call throws
`Xunit.Sdk.FailException`; the standard TRX schema/adapter does not serialize
the runtime exception type and the TRX must not claim that it does. The sole
mapped failed `UnitTestResult` has exactly one `Output/ErrorInfo/Message` node
whose normalized text equals the marker byte-for-byte. The same `ErrorInfo` may
also contain zero or one nonempty, marker-free sibling `StackTrace` containing
the locked adapter's standard failed-result assertion stack. Its absolute paths,
framework frames, indentation, and source line numbers are recorded non-oracles;
it is same-result serialization rather than an independent diagnostic. No other
`ErrorInfo` child or content is allowed. Except for the one permitted run-summary
echo described next, no other test-result message, stack, attachment, warning,
error, attribute, or node contains the marker. Across
`ResultSummary/Output/StdOut` and `StdErr`, the adapter may
record zero or one additional byte-identical marker echo. That bounded echo is
neither a second result nor assertion-type proof. Unexpected production
exceptions propagate and are not caught or relabeled; every other incorrect
non-exception outcome uses a marker-free assertion. Source review proves those
branches before the run.

`ResultSummary/RunInfos` is absent or has exactly one `RunInfo`. If present,
that node has exactly the `computerName`, `outcome`, and `timestamp` attributes,
`outcome="Error"`, exactly one `Text` child, and no other content. The marker is
absent and raw `Text` matches only
`^\[xUnit\.net [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{2}\][ ]+<exact-test-fqn>[ ]\[FAIL\]$`.
Machine, timestamp, adapter elapsed time, and indentation are recorded but not
equality oracles. This locked-adapter same-FQN notification is bookkeeping for
the sole failed result, not a second result, assertion-type proof, independent
diagnostic, or infrastructure failure. It is accepted only with the sole mapped
Failed `UnitTestResult`, Failed summary, exact failed-result message, all 16
counters including `error=0`, and no attachment or other diagnostic.

A valid first-increment BehaviorRed has nonzero process exit and exactly one
TRX at `<fresh-directory>/<exact-marker>.trx`. `ResultSummary/@outcome` is
`Failed`; exactly one `UnitTestResult` maps through `testId` to one
`UnitTest/TestMethod` composing the exact FQN above; and that result is Failed
with the exact node-scoped message contract above. The assertion-type contract
is the separate reviewed-source plus immutable-lock proof above. Its counters are exactly
`total=1`, `executed=1`, `passed=0`, `failed=1`, `error=0`, `timeout=0`,
`aborted=0`, `inconclusive=0`, `passedButRunAborted=0`, `notRunnable=0`,
`notExecuted=0`, `disconnected=0`, `warning=0`, `completed=0`,
`inProgress=0`, and `pending=0`. GUIDs, execution IDs, timestamps, duration,
machine name, absolute temp root, and stack-frame line numbers are recorded but
are not equality oracles.

The red is invalid if restore/lock bytes changed; compilation did not succeed;
the TRX is absent, duplicated, malformed, stale, extra, or outside the fresh
directory; the full FQN/traits/filter did not select exactly one test; any
counter differs; the exact failed-result message node is absent, duplicated,
or unequal; the marker occurs anywhere outside that node and the one allowed
run-summary echo; more than one run-summary echo exists; reviewed source no
longer has one direct null-branch `Assert.Fail(exactMarker)` call; the immutable
xUnit contract differs; more than one `RunInfo` exists; its attribute/child/
outcome/text/FQN/marker contract differs; any other RunInfo, attachment,
independent warning/error/diagnostic, any `StackTrace` outside the permitted
marker-free `ErrorInfo/StackTrace`, exception, or infrastructure text exists; an
unexpected exception was relabeled; or any
NU/MSB/compiler/analyzer/project/reference/predecessor/
environment/infrastructure failure occurred. Console text never overrides
incomplete or contradictory TRX evidence.

Every run observed before its applicable append-only evidence clarification
remains diagnostic and noncanonical even when its raw output happens to satisfy
the corrected oracle. Only a fresh post-packet-synchronization invocation may
become the canonical first A BehaviorRed.

The fresh post-packet-synchronization A invocation used a newly created,
initially empty external directory, the exact filter, and one TRX logger,
exited nonzero, and left exactly one TRX at
`D:\Temp\meandai-test-0210-a-canonical-54b33df16d7446be918f0a3cb75d3c28\TEST-0210-A-BEHAVIOR-RED-0001.trx`.
That TRX contains exactly one mapped Failed result for
`MeAndAI.Protocol.Conformance.Tests.ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest`,
one normalized failed-result `ErrorInfo/Message` equal to
`TEST-0210-A-BEHAVIOR-RED-0001`, one permitted byte-identical `StdOut` echo, and
one exact-shape marker-free same-FQN `[FAIL]` `RunInfo` with
`outcome="Error"`. Its `ResultSummary` is Failed and its counters are exactly
`total=1`, `executed=1`, `passed=0`, `failed=1`, `error=0`, `timeout=0`,
`aborted=0`, `inconclusive=0`, `passedButRunAborted=0`, `notRunnable=0`,
`notExecuted=0`, `disconnected=0`, `warning=0`, `completed=0`, `inProgress=0`,
and `pending=0`. The sole result's standard assertion stack is marker-free;
there is no independent diagnostic or attachment. IDs, machine, timestamps,
durations, indentation, absolute paths, and stack line numbers are recorded
non-oracles. This run is the canonical first A BehaviorRed; every earlier run
remains diagnostic. It is retained as the predecessor evidence for the first
limited green below.

The first limited ParseCanonical implementation replaced the reviewed `null!`
sentinel. Its Release `--no-restore` production build completed with zero
warnings and zero errors. With the original red oracle still unchanged, the
exact same FQN passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-91b9a19a6db741c6af2e5bac3a1a22b0\TEST-0210-A-GREEN-0001.trx`.
The transient marker constant and null-only `Assert.Fail` branch were then
removed, and canonical equality was moved before digest/object construction.
Format verification and the final six-project Release build passed with zero
warnings and zero errors. The final-source exact FQN passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-62a34655387e4306b0bc26c9203fb97d\TEST-0210-A-GREEN-FINAL-0001.trx`,
and the cumulative `ContractSlice=A` checkpoint passed `12/12`.

That first green validates the exact 1,222-byte fixture, manifest and artifact
digests, complete typed projection and order, null `CompleteCatalog`, and
caller-buffer mutation independence specified above. Source review confirms the
16 MiB length check precedes copying; parsing and hashing use only a private
`ToArray` copy; canonical typed reserialization must equal those private input
bytes; and no raw byte field is retained. The private input copy and writer-
returned reserialization byte array are zeroed in `finally`; the
`ArrayBufferWriter` internal buffer becomes unreachable and is not retained by
the manifest but is not explicitly zeroed. The proven contract is copy-at-entry
and no retained raw bytes, not universal buffer zeroization. This is only the
first limited ContractSlice A behavior increment. It does not
complete [TEST-0210](test-cases.md#test-0210), authorize a later slice, or
satisfy any remaining A increment.

The first-green support review classified the canonical-string boundary as an
unnumbered remaining-A coverage `Important`, not a defect in that accepted first
green. The then-current `CanonicalManifestWriter` used
`UnsafeRelaxedJsonEscaping`; that was exact for the reviewed ASCII 1,222-byte
fixture but was not proof of the complete string contract above. The reviewed
second A increment below froze the exact FQN, marker, writer-owned codec
topology, fixture matrix, and absent-behavior predicate needed to obtain that
proof. Its bounded green evidence now closes that `Important`; ContractSlice A
itself remains incomplete.

Final support review closed with `0 Blocking`, that one unnumbered remaining-A
coverage `Important`, and no unresolved `Minor`. The ordering Minor is closed by
the equality-before-digest/object refactor, and the zeroization wording is
corrected by the exact buffer-lifetime statement above. Neither observation
downgraded the accepted first fixture green.

Every later semantic increment receives a separately reviewed exact FQN,
marker, absent-behavior predicate, single-invocation filter, and exact TRX
counter/result inventory before implementation. Markers are transient evidence
labels, not stable scenario IDs. Only then may bounded production semantics
turn the increment green.

### Second A increment - canonical quoted UTF-8 strings

This reviewed increment remains inside [TEST-0210](test-cases.md#test-0210)
with `[Trait("ContractSlice", "A")]` and no `Scenario` trait while the parent
scenario is `Planned`. The exact FQN and this record preserve the parent link;
the trait is deferred to final A-D activation. The increment allocates no new
stable scenario or public API. The exact test identity is:

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding
```

Its exact marker and TRX filename are
`TEST-0210-A-BEHAVIOR-RED-0002`. The test is one `[Fact]`, so the exact filtered
red still selects, executes, and fails one result only. It uses the same fresh
external-directory, one-invocation, one-logger, failed-result message,
optional byte-identical summary echo, optional exact marker-free same-FQN
RunInfo, and complete 16-counter oracle as the accepted first A BehaviorRed.
No runner observation may broaden that oracle retroactively.

`CanonicalManifestWriter` remains the single serializer owner. Its internal
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)` returns exactly one
validated quoted UTF-8 JSON string token. The pre-red structural extraction is
behavior-preserving: it moves the existing `UnsafeRelaxedJsonEscaping` string
result behind that codec, while the writer feeds the returned token through
`Utf8JsonWriter.WriteRawValue` with input validation enabled. The original
1,222-byte fixture and digest must remain byte-identical. This extraction adds
no public export or friend and is not itself the semantic green.

The red's exact probe is the following UTF-16 code-unit sequence:

```text
0051 0022 005C 0008 000C 000A 000D 0009 001F 007F 0085 009F 3000 D842 DF9F
```

The behavior-preserving extraction produces this exact legacy quoted-byte hex:

```text
22515C225C5C5C625C665C6E5C725C745C75303031465C75303037465C75303038355C75303039465C75333030305C75443834325C754446394622
```

Only that complete legacy result invokes `Assert.Fail` with
`TEST-0210-A-BEHAVIOR-RED-0002`. A null result, exception, partial change,
different byte sequence, wrong positive fixture, wrong exception category, or
unrelated failure is marker-free and invalid red. The bounded green changes the
same codec to this exact quoted-byte hex:

```text
22515C225C5C5C625C665C6E5C725C745C75303031665C75303037665C75303038355C7530303966E38080F0A0AE9F22
```

This means quote and backslash use their exact short escapes, slash stays raw,
the five named C0 characters use `\b`, `\f`, `\n`, `\r`, and `\t`, the
remaining C0 value uses lowercase `\u001f`, `DEL` and the two C1 values use
lowercase `\u007f`, `\u0085`, and `\u009f`, and `U+3000` plus supplementary
scalar `U+20B9F` are raw UTF-8. The codec never normalizes, replaces, or combines
valid scalars. The non-normalization oracle also passes contextual values `é`
(`U+00E9`) and `é` (`U+0065 U+0301`) separately: their raw strict-UTF-8 value
bytes are respectively `C3 A9` and `65 CC 81`, remain ordinally distinct, and
neither input may be converted to the other.

The positive integration fixture changes only the original minimal fixture's
`assemblyName` from `MeAndAI.Protocol.Conformance.Tests` to
`MeAndAI.Protocol.　Unicode.𠮟.Tests`. Its strict UTF-8 document is exactly
1,226 bytes including the final LF and has SHA-256
`5195e1a4b36b8b57a96fbd774fb78c5d46878948f91ee597e66ef6f44821a928`.
The raw byte sequences `E3 80 80` and `F0 A0 AE 9F` each occur exactly once.
The parsed `AssemblyName` preserves the exact scalar sequence and the manifest
digest equals that exact document. The original ASCII fixture remains an
independent unchanged regression.

The one test owns this complete labeled matrix:

| Group | Exact vectors and result |
| --- | --- |
| Quoting | Quote and backslash use `\"` and `\\`; slash is raw. |
| Named C0 | Backspace, form feed, LF, CR, and tab use only `\b`, `\f`, `\n`, `\r`, and `\t`. |
| Remaining controls | Remaining C0, `DEL`, and C1 use lowercase `\u00xx`; uppercase hex, long-form alternatives for named controls, and raw C1 are lexically rejected before typed factories. |
| Printable scalars | `U+3000` and `U+20B9F` are raw UTF-8. Contextual `é` (`U+00E9`) emits raw value bytes `C3 A9`, while `é` (`U+0065 U+0301`) emits raw value bytes `65 CC 81`; the two outputs are ordinally distinct and neither is normalized. |
| Positive manifest | The exact 1,226-byte assembly-name fixture parses, preserves the typed value, and yields the exact digest above. |
| Escaped printable alternatives | Escaped `U+3000` and both lowercase and uppercase valid surrogate-pair spellings for `U+20B9F` are noncanonical `FormatException`. |
| Canonical control lexemes in an opaque field | Lowercase canonical control spellings pass lexical validation, then the typed opaque-identity factory rejects the decoded control; that document-caused `ArgumentException` is wrapped as public `FormatException`. |
| Malformed raw UTF-8 | Isolated continuation, overlong form, UTF-8 surrogate, truncated sequence, and value above `U+10FFFF` are `FormatException`. |
| Malformed escaped Unicode | Lone high surrogate, lone low surrogate, reversed pair, and high-surrogate-plus-ASCII are `FormatException`. |
| Internal argument boundary | Direct `CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)` input containing malformed .NET UTF-16 throws `ArgumentException`; it is not a document parse and is not relabeled. |

The reader therefore distinguishes two owners. `BoundedJsonReader.ReadString`
captures the current token's complete quoted bytes from the original private
input using the exact half-open range `TokenStartIndex..BytesConsumed`. It calls
`Utf8JsonReader.GetString()` and catches only an `InvalidOperationException`
thrown by that call, translating it to `FormatException`. It then re-encodes
the decoded value through the same
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)` used by the writer
and requires ordinal byte equality with that complete original quoted token.
Any mismatch is `FormatException` before a typed factory. This is the sole
lexical-canonicality oracle: no second string grammar, parser, escape scanner,
or independently maintained allowlist exists.

Public `ParseCanonical` malformed raw or escaped document bytes always fail
with `FormatException`. When this document-owned re-encode calls the codec, only
an `ArgumentException` caused by the decoded document value is translated to
`FormatException`. A direct internal codec caller that supplies malformed .NET
UTF-16 has violated an argument boundary and receives `ArgumentException`.
Typed-factory argument failures caused by already decoded document values keep
the existing separately owned `FormatException` wrapping rule. No test depends
on exception-message text, and no per-negative fixture digest is required
because the transformations and exception categories above are the exact
oracle.

Green is deliberately narrow: replace the no-op legacy codec behavior with the
exact encoding contract, retain validated `WriteRawValue`, extend only the
reader lexical checks needed by this matrix, and preserve every manifest
schema/order/resource/copy/digest boundary already green. It adds no second
serializer, public surface, project/reference/package/lock/friend change,
normalization, executable export, registration, activation, kernel, or later-A
behavior. Exact-FQN green, cumulative `ContractSlice=A`, zero-warning/error
Release build, format, byte-identical locks, and fresh-diff review are required
before this increment can close.

Transient red is never pushed or published and never receives root,
StructureOnly, combined, or hosted validation. Red source is not registered in
scenario ownership. Production implementation may begin only after the exact
red is reviewed and no unrelated failure exists.

### Bounded green evidence

The behavior-preserving seam predecessor retained the exact old FQN and passed
`1/1` at
`D:\Temp\meandai-test-0210-a-seam-1d7c48a903be4f31a6e2c59b708d4fa1\TEST-0210-A-SEAM-NOOP-0002.trx`.
The valid canonical BehaviorRed then passed review with `0 Blocking`,
`0 Important`, and `0 Minor` at
`D:\Temp\meandai-test-0210-a-8b7f24d6c19a4e03b5f1728a90c4d6e1\TEST-0210-A-BEHAVIOR-RED-0002.trx`.
The bounded production-source review also closed `0 Blocking`, `0 Important`,
and `0 Minor`.

With the marker and exact legacy branch still present, the original-oracle
green passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-3c6d91a5e8f247b0a1c4d7e9f2b5a630\TEST-0210-A-GREEN-0002.trx`.
The marker and legacy branch were then removed and source search confirmed both
absent. The final-source exact FQN passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-5e2a7c91d4f84360b8e1a3c6f9072d54\TEST-0210-A-GREEN-FINAL-0002.trx`,
and cumulative `ContractSlice=A` passed `13/13` at
`D:\Temp\meandai-test-0210-a-cumulative-7a3e6d20f9514bc8a2d5e7f039c6b184\TEST-0210-A-GREEN-CUMULATIVE-0002.trx`.

Locked restore succeeded. The six lock SHA-256 fingerprints remain Domain
`03EEADC5...CB46`, Abstractions `D79FF118...F799`, Conformance
`20E6BA80...70E7`, Policy `C57F6AFA...4309`, Domain.Tests
`D2065F11...00BC`, and Conformance.Tests `BA8D8C65...16C0`. The standard
`dotnet format --verify-no-changes --no-restore` check and `git diff --check`
passed, and the six-project Release build completed with zero warnings and zero
errors. A separate non-gating severity-info full scan exposed pre-existing flat-
namespace/informational backlog and suggestions; this record does not claim
that scan clean.

This evidence closes only the canonical-string coverage `Important` and this
second A increment. [TEST-0210](test-cases.md#test-0210) remains `Planned` and
remaining A is pending. ContractSlice B/C/D, workflow/scenario-trait/scenario-owner/
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), root,
combined, hosted, WIP extraction, consumer, release, and publication scope
remain held.

## Public API and project-graph ownership transition

The future transition is list-derived:

- [TEST-0220](test-cases.md#test-0220) retains exact shape/behavior ownership of its original Domain
  predecessor inventory and Domain's BCL-only boundary.
- After [SUBF-0153](README.md#subf-0153) implementation, [TEST-0221](test-cases.md#test-0221) retains exact shape/behavior of its
  SliceInventory and the then-current Domain predecessor export set.
- [TEST-0210](test-cases.md#test-0210) owns exact equality between Domain exports and the ordinal union of
  those two predecessor inventories; it does not weaken their member or
  behavior assertions.
- [TEST-0210](test-cases.md#test-0210) owns the exact cumulative A, B, C, then D export union for
  Abstractions, Conformance, and Policy plus the total solution/project/
  reference/package/lock/effective-restore graph. At each slice boundary the
  one total-equality oracle transfers to the next cumulative union while every
  earlier delta retains exact type/member/nullability/factory presence.

Before the first [TEST-0210](test-cases.md#test-0210) red, a separately authorized atomic transition must
change predecessor *total-equality* assertions only to exact predecessor
presence/shape, without weakening any member contract. The transient new total
graph is then owned by [TEST-0210](test-cases.md#test-0210) source and must never be published as an active
red head.

The exact planned ContractSlice A-D solution graph is:

```text
src/MeAndAI.Protocol.Domain
src/MeAndAI.Protocol.Conformance.Abstractions -> Domain
src/MeAndAI.Protocol.Conformance -> Domain + Abstractions
src/MeAndAI.Protocol.Policy -> Domain + Abstractions
tests/dotnet/MeAndAI.Protocol.Domain.Tests -> Domain
tests/dotnet/MeAndAI.Protocol.Conformance.Tests
  -> Domain + Abstractions + Conformance + Policy
```

Domain, Conformance.Abstractions, and Conformance have zero external package
references. Policy has exactly one external package reference, `Markdig`
`1.3.2`, solely for the two manifest-bound Markdown parser components, which
share the same pinned pipeline and `LinkHelper` algorithm; it has no other external
package. The new test project uses only the repository's already locked test/
analyzer package set and receives Markdig transitively through Policy.
Every project and lock is explicitly included in `MeAndAI.Protocol.slnx` and
the locked restore graph. No project references `MeAndAI.Operations`, a host,
adapter, provider SDK, consumer, or PowerShell asset.
`MeAndAI.Protocol.Application` is an exact reserved future friend identity, not
a project added by [SUBF-0143](README.md#subf-0143). A separately authorized [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) slice must add
that exact project/AssemblyName and its Domain + Abstractions + Conformance
dependency path atomically before exercising the internal codec/proof seam; it
does not reference Policy directly because bootstrap passes the Abstractions-
typed export. [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md) later hosts its manifest-finalization use case in that
same exact Application assembly.

## Future combined and hosted route

Only after all four focused groups and the combined local run are green may a
separately authorized packet execute the four-step activation order in the
[expected-red contract](#test-0210-expected-red-contract): freeze and prove
`E` in the exact parent; make one atomic candidate that adds the `Scenario`
trait for [TEST-0210](test-cases.md#test-0210) to every `E` fact and updates [TEST-0210](test-cases.md#test-0210)
Status/Automation, scenario-owner, both stable workflow test steps' run-block
form, solution target, and filter, plus
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146);
then prove both focused identity sets and the final combined route at the exact
candidate head. No subset of that mutation is a valid activation.

Each existing stable job retains exactly one protocol locked-restore
invocation and one protocol test invocation. The Ubuntu step retains
`shell: bash`, the Windows step retains `shell: pwsh`, and neither shell is
switched. In both steps, the atomic activation changes the run scalar from
folded `run: >-` to literal `run: |`, changes the test target from the
Domain.Tests project to `MeAndAI.Protocol.slnx`, and installs the applicable
exact script below. This run-block/target/filter transition is part of the
activation and [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
contract, not an implied implementation choice.

The split-fragment variables below denote [TEST-0220](test-cases.md#test-0220),
[TEST-0221](test-cases.md#test-0221), and
[TEST-0210](test-cases.md#test-0210), respectively. The exact Ubuntu Bash
`run: |` body is:

```text
test_prefix='TEST-'
domain_scenario="${test_prefix}0220"
evidence_scenario="${test_prefix}0221"
kernel_scenario="${test_prefix}0210"
activation_verifier='MeAndAI.Protocol.Conformance.Tests.ContractSliceActivationTopologyTests.Matches_exact_contract_slice_scenario_inventory'
dotnet test MeAndAI.Protocol.slnx --configuration Release --no-restore --nologo --verbosity minimal --filter "Scenario=${domain_scenario}|Scenario=${evidence_scenario}|Scenario=${kernel_scenario}|ContractSlice=A|ContractSlice=B|ContractSlice=C|ContractSlice=D|FullyQualifiedName=${activation_verifier}"
```

The first Bash assignment is exactly `test_prefix='TEST-'` without a leading
`$`; the rendering above intentionally distinguishes assignment from
expansion. The exact Windows PowerShell `run: |` body is:

```text
$domainScenario = 'TEST-' + '0220'
$evidenceScenario = 'TEST-' + '0221'
$kernelScenario = 'TEST-' + '0210'
$activationVerifier = 'MeAndAI.Protocol.Conformance.Tests.ContractSliceActivationTopologyTests.Matches_exact_contract_slice_scenario_inventory'
dotnet test MeAndAI.Protocol.slnx --configuration Release --no-restore --nologo --verbosity minimal --filter "Scenario=$domainScenario|Scenario=$evidenceScenario|Scenario=$kernelScenario|ContractSlice=A|ContractSlice=B|ContractSlice=C|ContractSlice=D|FullyQualifiedName=$activationVerifier"
```

One solution-level invocation may deliberately create a Domain.Tests testhost
and one new bounded Conformance.Tests testhost. This is not described as one OS
process. It adds no workflow job, step, restore invocation, test invocation,
trigger, path filter, wrapper, retry, `continue-on-error`, or timeout.

The ContractSlice union and exact verifier FQN are deliberate permanent
reachability barriers, not extra semantic inventory. The OR filter still runs
each discovered fact once. They keep the activation-integrity fact executable
when its own Scenario trait or another fact's Scenario trait is missing; a
scenario-only filter cannot prove the frozen bijection.

[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) must construct every scenario ID from split fragments, count every
protocol restore/test invocation before positive matching, require exactly one
full non-continued invocation per existing stable job, require the exact
Bash/pwsh shell, literal run-block form, solution target, assignments, and
filter terms above, and reject alternate, wrapped, or extra commands. Hosted evidence must reconcile selected,
discovered, executed, passed, failed, and skipped counts per test project, not
only static command text.

The Windows job retained its 35-minute timeout until the first exact hosted head
did not fit and required design review. The first reviewed ceiling was 45
minutes. The exact record-delivery closure later reached that ceiling after all
emitted suites passed and triggered a second design review. The reviewed
single-job ceiling is now 55 minutes with coverage, topology, and invocation
count unchanged. If a later exact hosted head still does not fit, stop for
design review again; do not
automatically raise the timeout, split or remove coverage, add another
invocation, or weaken
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146).

## Frozen ContractSlice C delivery overlay

ContractSlice B is merged and exact-main hosted green; exact identities and
durations remain owned by the C handoff. At the C design checkpoint,
ContractSlice C was `FrozenDesign`/inactive: that cohort and its exact hosted
gate preceded every C# mutation and canonical C red.

The normative C delivery order is:

```text
C-SURFACE-ACTIVATION-01
  -> C-REGISTRATION-MISMATCH-01
  -> C-PRODUCER-PIPELINE-01
  -> C-APPLICABILITY-PLAN-01
  -> C-APPLICABILITY-CLOSURE-01
  -> C-EVALUATION-PLAN-01
  -> C-EVALUATION-ADVANCE-01
  -> C-INTENT-RESULT-01
  -> C-AGGREGATION-01
  -> C-CONVERGE-01
```

Delivery preserves that exact dependency order through four C-only cohorts:
Activation owns the first three packets, Applicability the next two,
Evaluation the next two, and Results/closure the final three. Inside a cohort,
each package must close its canonical red, focused and cumulative local gates,
Release build, diff/format/structure checks, independent review, record sync,
and focused local commit as `ReviewedLocalGreen`; those commits are not pushed
individually. The cohort then runs full C cumulative, A-through-cohort, full
Conformance and Domain, build/format/locks/API/ownership/graph/StructureOnly/
publication-evidence and full-diff gates, pushes the ordered commit sequence
once, and becomes `ExactHeadHostedGreen` only after exact-head Ubuntu/Windows
success. The next cohort remains inactive until that hosted boundary. A hosted
failure reopens only its cohort and owning package; the entire local cohort gate
must be repeated before a new exact-head push.

The exact C Fact inventory is the eleven ordinal FQNs owned by the
[C micro-delivery plan](subf-0143-contractslice-c-micro-delivery-plan.md).
Structural, Ownership, and Activation belong to the first packet; each later
semantic packet owns one Fact; convergence is P/R/G `NotApplicable` and adds
none. Final C is `11/11`, cumulative A+B+C/full Conformance `54/54`, and Domain
remains `98/98`.

`C-SURFACE-ACTIVATION-01` atomically introduces the already-specified eight
Abstractions and fifteen Conformance supported types, final six internal
registration families, and Tests-owned synthetic complete export/proof. The
only first-red seam is the fully prepared valid
`ConformanceKernel.Activate(...)` returning `null!`; only that null calls
`Assert.Fail("TEST-0210-C-BEHAVIOR-RED-0001")`. Its retained exact FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCActivationTests.Activates_exact_synthetic_registration_graph`.
The packet proves exact success only; the next packet owns the exhaustive
registration-mismatch matrix.

The first-packet source allowlist is exact:

```text
src/MeAndAI.Protocol.Conformance.Abstractions/Exports/CompletePolicyPackExport.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Exports/PolicyQualificationSliceExport.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/ApplicabilityIntent.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/EvaluationFailureIntent.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/EvaluationIntent.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/FindingIntent.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/IRuleEvaluator.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/RuleApplicabilityInput.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Evaluation/RuleEvaluationInput.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Tokens/ApplicabilityIntentKind.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/ProducerRegistrationContracts.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/ParserRegistration.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/IndexRegistration.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/DemandProjectorRegistration.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/SelectorRegistration.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/RuleEvaluatorRegistration.cs
src/MeAndAI.Protocol.Conformance/Activation/CatalogSliceKernel.cs
src/MeAndAI.Protocol.Conformance/Activation/ConformanceKernel.cs
src/MeAndAI.Protocol.Conformance/Activation/KernelActivationCore.cs
src/MeAndAI.Protocol.Conformance/Planning/AcquisitionInstruction.cs
src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityPlan.cs
src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityClosure.cs
src/MeAndAI.Protocol.Conformance/Planning/EvaluationAdvanceResult.cs
src/MeAndAI.Protocol.Conformance/Evaluation/CatalogSliceEvaluation.cs
src/MeAndAI.Protocol.Conformance/Evaluation/CompleteCatalogEvaluation.cs
src/MeAndAI.Protocol.Conformance/Evaluation/RuleEvaluation.cs
src/MeAndAI.Protocol.Conformance/Evaluation/RuleEvaluationFailure.cs
src/MeAndAI.Protocol.Conformance/Evaluation/RuleFinding.cs
src/MeAndAI.Protocol.Conformance/Evidence/SealedAcquisitionAttempt.cs
src/MeAndAI.Protocol.Conformance/Evidence/SealedAcquisitionOutcome.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCStructuralTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCOwnershipTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCActivationTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAPublicApiTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceBStructuralTests.cs
```

The two retained predecessor paths change only predecessor-only C-absence and
successor-safe A+B subset assertions while retaining A export internals and B
negative ownership. Their A/B surface, FQN, and trait authority is otherwise
immutable, while the C structural Fact owns exact current A+B+C export equality.
They add no C Fact. No sixth test path or other source path is permitted.
The six registration
containers have their final generic identities, declarations, tokens, visitors,
and object references now. Component-operation interfaces are introduced on
those same identities as memberless staging seams; only
`C-PRODUCER-PIPELINE-01` adds their already-accepted final methods and carriers.
It may not replace an identity, add an adapter, or alter a registration object.
Public intent factories and later kernel calls expose their final signatures
but retain marker-free integrity rejection until their owning packets implement
the accepted behavior. This staging changes no final architecture or ownership.
The previously frozen compile-only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceC.SurfaceRed.cs`
is a transient P input only: it produces its exact one CS0246 observation once
before the surface exists and is removed before retained BehaviorRed source or
green. It is not a fourth retained test path and never enters a package commit.

The exact fixture derives the retained five-rule declaration data into one
complete genesis catalog. It maps the twenty-three Policy implementation rows
to Tests-owned concrete types and preserves the four Abstractions capability
interfaces, producing the exact twenty-seven registration/type-contract rows.
Its artifacts are ordinally exactly `Markdig.dll`,
`MeAndAI.Protocol.Conformance.Abstractions.dll`,
`MeAndAI.Protocol.Conformance.Tests.dll`,
`MeAndAI.Protocol.Conformance.dll`, and `MeAndAI.Protocol.Domain.dll`; neither
Policy nor Application appears. The successful Fact observes the exact three
codec, two parser, four index, one projector, three selector, and five evaluator
registration objects in their canonical lists; it asserts the public component
union and catalog projection object-identically. No mismatch mutation or
component invocation belongs to this packet.

Canonical C reds specialize the universal BehaviorRed contract with Release
`--no-restore --no-build`, one exact `ContractSlice=C&FullyQualifiedName=...`
child, process-scoped `VSTEST_CONNECTION_TIMEOUT=300`, a `420000` ms outer
bound, one exact marker TRX, native exit `1`, runner exit `0`, complete sixteen-
counter and source/binary/lock custody, and irrevocable ordinal consumption at
`InvocationCommitted`. No discovery prepass, fallback, retry, or red commit is
permitted.

### Frozen `C-REGISTRATION-MISMATCH-01` boundary

This packet starts only from local commit
[`8812b22c7cc8a1785d24376f3e91a20fb0fe6cc0`](https://github.com/hasanmanzak/meAndAI/commit/8812b22c7cc8a1785d24376f3e91a20fb0fe6cc0);
that surface predecessor is
`ReviewedLocalGreen` and remains unpushed. The sole Fact is
`ContractSliceCRegistrationTests.Rejects_registration_mismatch_without_kernel_activation`,
with only `ContractSlice=C`, no Scenario, and canonical marker
`TEST-0210-C-BEHAVIOR-RED-0002`. The fully prepared valid
`CatalogSliceKernel.Activate(...)` call is the sole null semantic seam and the
only route to `Assert.Fail(marker)`; setup, mismatch, proof, and exception paths
are marker-free.

The exact executable allowlist modifies only
`KernelActivationCore.cs`, `CatalogSliceKernel.cs`, and
`ContractSliceCActivationTests.cs`, and adds only
`ContractSliceCRegistrationTests.cs`. The predecessor test change exposes its
Tests-owned fixture factory and immutable carriers internally; it changes no
Fact, FQN, trait, or assertion. No public surface, project, package, lock,
workflow, Policy, Application, Domain, producer execution, or later C path may
change. The packet cap is two production paths, two test paths, and `1,800`
normalized changed C# lines; first-one-over requires redraw.

The qualification fixture reuses the predecessor's object-identical six-family
registrations and Tests-owned components, creates one `QualificationSlice`
manifest/export/proof envelope, and contains no Policy artifact or type. Exact
validation order is null/authority/catalog/schema/proof identity and artifact
attestation, then registration comparison. The latter requires each presented
family to equal its manifest-owned canonical declaration order and multiplicity:
codecs `3`, parsers `2`, indexes `4`, demand projectors `1`, selectors `3`, and
evaluators `5`. Every declaration is the same object; each CLR generic argument
matches the manifest model/capability/component identity; selector resolver and
schema pairs equal the unique ordinal selector declarations; evaluators map
one-to-one and in order to the five rules; the public component projection is
the exact 18-member runtime-type union and every member has one manifest map.

Missing, extra, duplicate, reordered, structurally equal but foreign,
wrong-generic, or public-projection-drift input throws
`CatalogIntegrityException(RegistrationMismatch)` before a kernel exists. A
wrong contract/version/digest/artifact/export proof instead remains the earlier
`ActivationProofInvalid`; argument-boundary nulls retain their argument
exceptions. One valid envelope returns a non-null kernel. The mismatch matrix
tests every family, both order-sensitive edges, foreign declarations,
wrong-generic model/capability/component identities, exact proof precedence,
and no leaked kernel. Green requires focused `1/1`, C `4/4`, full Conformance
`47/47`, Domain `98/98`, warning-free Release build, format/diff/locks, required
structure, independent review, record sync, and a second unpushed local commit.

That contract is now `ReviewedLocalGreen`. Canonical R=0004 is immutable and
owned in the C evidence ledger; green proves the exact declaration reference,
order, multiplicity, mapped CLR identity, selector/evaluator, 18-component,
proof-precedence, and no-kernel boundaries. Focused `1/1`, C `4/4`, full
Conformance `47/47`, Domain `98/98`, warning-free Release build, format/diff,
StructureOnly `429.279s`, and code/evidence/traceability reviews `0/0/0` passed.
At that registration checkpoint no intermediate push or hosted-green claim was
made; producer-pipeline was next after the separate registration packet commit.

### Frozen `C-PRODUCER-PIPELINE-01` activation graph contract

This packet preserves the final internal declarations already frozen in the
canonical producer/resource sections above. It adds their callable members on
the same registered component objects and introduces only the internal carrier,
handle, intent, allowance, ledger, and activation-graph implementations needed
by those exact signatures. No alternate adapter, object/dynamic dispatch,
reflection, service lookup, provider DTO, I/O, Policy implementation, cache
authority, plan state, or evaluator result is introduced.

The final operation interfaces retain fail-closed `NotSupportedException`
default bodies solely so predecessor negative-registration fixture types outside
this packet's test allowlist remain compile-valid. Those defaults are never
canonical graph components or an alternate execution seam. Every one of the
exact eighteen registered fixture objects supplies its own packet-local final
operation implementation; before later behavior packets own semantic products,
those methods expose only argument validation and marker-free closed rejection
or empty-result intent shapes. The owning Fact proves the concrete operations
are callable on the same registered objects and never reaches a default body.

The exact source allowlist is the twelve paths listed by the C micro-plan: six
Abstractions registration/contract files, four Conformance activation files,
the retained activation fixture, and one new producer-pipeline Fact. The cap is
exactly `10` production/Abstractions paths, two C test paths, and `3,500` normalized
changed C# lines. Domain, Policy, Application, project/package/lock/workflow,
Scenario/status/owner, runtime-efficiency, D, merge/release/publication, and all
later C packet paths remain immutable.

Activation validates exactly `18` object-identical registrations with family
cardinality codec/parser/index/projector/selector/evaluator `3/2/4/1/3/5`.
The producer DAG itself is exactly the already accepted ten Schema/Parser/
Index/Projector nodes; selector/evaluator rows are attached activation maps and
are not DAG nodes. Every parser/index binder input list is structurally equal to
its declaration, including order and minimum/maximum counts. Dependencies are
the accepted model/capability/projector-slot edges; Kahn readiness uses the
existing component key/version, declaration key/version, then
`Schema < Parser < Index < Projector` ordering.

The two roots are governed-text Schema and repository-tree Schema. The exact
ordered DAG is governed-text Schema, repository-tree Schema, repository-tree
Index, Markdown Parser, protocol-record Index, governed-reference Index,
repository-target-resolution-demand Projector, repository-target-resolution
Schema, repository-target-Markdown Parser, and repository-target-resolution
Index. A missing, duplicate, foreign, cyclic, cardinality-invalid, unreachable,
or unbound edge is `RegistrationMismatch` and exposes no graph/kernel.

`CatalogSliceProducerGraph` owns the ordered ten-node projection plus the exact
six object-identical registration lists. Both `CatalogSliceKernel` and
`ConformanceKernel` retain one non-null graph created from their validated
export; neither recomputes or replaces registration objects. The internal test
projection exposes immutable node family/key/version/component/input/scope
metadata only, never `object`, dynamic dispatch, mutable collections, or a
second execution authority.

Invocation expansion remains exactly the accepted architecture: one codec per
admitted binding and none for a zero-binding context; one parser per matching
sealed model/binding; `PerContext` indexes once per exact slot/target/context,
including the empty protocol-record capability case; `PerPlan` indexes once
over the canonical unique union; the projector once over its coalesced
capability union; selectors by exact declared key/parent; evaluators only after
all declared inputs. Aliases sharing identical handles schedule once, out-of-
range ready input is `PlanStateInvalid`, and a failed/no-input predecessor
suppresses its dependent invocation. Resource claims stay producer-local;
allowance comparison, immutable ledger construction, and sealed handle
ownership remain Conformance-only.

The sole Fact and marker are
`ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph`
and `TEST-0210-C-BEHAVIOR-RED-0003`, with only `ContractSlice=C` and no
Scenario. Canonical R=0005 has the complete source/fixture/oracle present and
changes only the synthetic complete `ConformanceKernel` graph result to
`null!`; only that null calls the marker. Green changes only that semantic seam
and wires the identical graph state into both kernel variants. It requires
focused `1/1`, C `5/5`, full Conformance `48/48`, Domain `98/98`, build/format/diff/locks/
structure/reviews/record sync, and closes in a third separate unpushed local
commit. The Activation cohort is pushed only after its full local cohort gate;
the Applicability cohort remains held until exact-head hosted green.

Canonical R=0005 is accepted and immutable; it is never rerun. The fresh
`41,565`-byte runner has SHA-256 `CD92BAD1...D82169B`, its `18,126`-byte report
has SHA-256 `5563029B...E4E992`, and the sole `4,908`-byte TRX has SHA-256
`2E55C738...34AF2`. Native/runner exits are `1/0`; one Failed
result/definition/entry owns marker count `2`, exact failed `1/1/1` counters,
all other thirteen counters zero, and no attachment/collector evidence. Green
is focused `1/1`, C `5/5`, full Conformance `48/48`, Domain `98/98`, build
`0/0`, clean format/diff, StructureOnly green in `434.832s`, and
code/evidence/traceability reviews `0/0/0`. Producer-pipeline is
`ReviewedLocalGreen`; no push or hosted claim is made here.

The ordered three-commit Activation cohort later passed its single exact-head
hosted gate: Ubuntu `22m23s`, Windows `18m57s`, publication verification
skipped, hosted defects `0`. That external cohort result activates only the
next C packet and does not change C from `5/11` or lift any downstream hold.

### Frozen `C-APPLICABILITY-PLAN-01` planning contract

This packet implements only the already accepted `PlanApplicability` phase and
the internal static instruction factory. The initial five-rule catalog has no
applicability-phase slots, so its normative output is deliberately a non-null
plan with zero `Slots` and zero `Instructions`. The complete named Provider
profile selects the exact catalog RULE-0003, RULE-0004, and RULE-0005 objects;
the slice Repository diagnostic profile selects exact RULE-0001..0005. Empty
instructions are therefore catalog-universal applicability, not a shortcut,
and later closure alone invokes the selected evaluators.

One internal `ApplicabilityPlanningCore` owns both kernel paths. Activation
creates one opaque `KernelPlanningSession` per kernel, bound to authority kind,
manifest digest, catalog rules, and the producer graph identity. A resolved
`NamedExecutionProfile` retains that exact session privately. A plan retains
the same session through its existing `IPlanBoundEvidenceSession`; no public
token, constructor, factory, reflection path, or equal-looking value can mint
or replace it. Cross-kernel, cross-profile, foreign named-profile, stale, or
modified input fails `CatalogIntegrityCode.PlanStateInvalid`.

Rule selection is exact. Slice selection requires declared SubjectRole,
Operation, SnapshotKind, and an intersection between profile and rule Surfaces;
EnforcementPhase never changes membership. Complete selection first requires
the exact kernel-resolved named-profile session and then selects its declared
RuleIds object-identically from the catalog. Output RuleIds follow ordinal
RuleId order. A missing/duplicate/foreign declared rule or profile is
`PlanStateInvalid`.

Targets are enumerated once and copied. Every element is non-null and
structurally unique; all values share one exact SubjectIdentity, SnapshotKind,
and TargetIdentity. The required set is computed from every selected rule slot
whose `ProfileSurfaces` intersects the profile, across applicability and
evaluation phases. Schema-1 selector mapping remains exactly:

```text
protocol.target.repository-snapshot -> Repository
protocol.target.repository-governed-body-set -> Repository
protocol.target.repository-target-resolution-set -> Repository
protocol.target.provider-governed-body-set -> Provider
```

Each required surface has exactly one target; zero, multiple, extra, unknown,
wrong-snapshot, or incoherent values fail `PlanStateInvalid`. Provider planning
therefore retains the Repository support target without adding Repository to
the profile axes. Output order is schema surface order Repository, Provider,
Workflow, Release, then ordinal SourceIdentity; input order cannot repair or
break ambiguity.

Active applicability slots are the structurally equal SlotKey union over the
selected rules, filtered by profile-surface intersection and ordered by
SlotKey. A shared SlotKey with unequal requirement/profile/material/selector/
capability shape is `PlanStateInvalid`. Each active slot maps to its exact
resolved target and one `AcquisitionInstruction.CreateApplicability`; the
initial accepted catalog produces none. A future valid non-empty catalog uses
the already frozen canonical frames without another seam:

```text
Demand = ASCII "protocol.acquisition-demand/1\n" || u8 none=0 || u32-be 0
Instruction = ASCII "protocol.acquisition-instruction/1\n"
  || ManifestDigest raw 32 bytes || u8 applicability=0 || u32-be round=0
  || text SlotKey || text SubjectIdentity || text SourceIdentity
  || text Surface.Value || text SnapshotKind.Value || text TargetIdentity
  || DemandDigest raw 32 bytes
```

`text` is u32-be strict-UTF-8 byte length plus bytes. Both digests are SHA-256
of the exact retained frames; the caller supplies neither. DemandItems is the
empty immutable list. Null arguments use their argument exceptions; frame,
overflow, selector, collision, or plan-shape failures are `PlanStateInvalid`.

The owning fixtures are exact. Complete uses the release-declared profile
`protocol.profile.consumer-provider-exact-commit-conformance-audit`, axes
Consumer/Conformance/ExactCommit/Provider/Audit, and reversed input targets:
Repository `(repo, repo)` and Provider `(repo, github)`. Both use the target
identity formed by separator-free ordinal concatenation of
`0123456789abcdef`, `0123456789abcdef`, and `01234567`; output restores
Repository then Provider. Slice uses Consumer/Conformance/ExactCommit/
Repository/Audit and
only the Repository target. Plans preserve exact authority kind, axes object,
catalog RuleIds, targets, session, manifest identity, and immutable snapshots;
they contain no adapter/provider DTO, route, I/O, cache, admission, clock,
Application, or Policy implementation.

The sole Fact is
`ContractSliceCApplicabilityPlanTests.Plans_exact_static_applicability_instructions`
with only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0004`. Canonical R=0006 replaces only the fully
prepared complete-kernel plan with `null!`; only that null calls the marker.
The exact eight-path allowlist and `2,400` normalized changed-line ceiling are
owned by the C micro-plan. Green is focused `1/1`, C `6/6`, full Conformance
`49/49`, Domain `98/98`, build/format/diff/locks/structure/reviews/record sync,
and one separate unpushed `ReviewedLocalGreen` commit. Closure and the cohort
push remain held. R=0006 produced the exact behavior-red TRX but its runner
retained the predecessor producer method name in the `TestMethod.name` oracle,
so it ended `OracleRejected`; it is immutable diagnostic/no-success and never
reruns. Corrected R=0007 changes only that predicate. Its fresh runner is
`42,368` bytes / SHA-256
`9EA4B00ADCF91B8CE2CB49F6FA9BD24005B5521E15411F996262C72AE67DD19F`,
AST `6,038` tokens / `0` errors, and was inactive until the corrected
records/design head passed exact-head hosted validation.

That corrected head `d251b377...c044` passed exact hosted validation; the sole
R=0007 was accepted with native/runner exit `1/0`, report SHA-256
`6DA8C76C...2384`, and TRX SHA-256 `DC1A4426...8250`. The bounded green is
focused `1/1`, C `6/6`, full Conformance `49/49`, Domain `98/98`, Release
build `0/0`, clean packet format/diff/locks/StructureOnly, and reviews
`0/0/0`. The packet is `ReviewedLocalGreen`; at that checkpoint closure was
next/`FrozenDesign` and no Applicability cohort push or hosted claim existed.

Closure now admits exact Observed/Failed/NoInput proofs into independent
Complete/Incomplete/Failed outcomes, seals ContextProof references, emits
NotApplicable/Unresolved terminals, and enforces cancellation/retry atomicity.
R=0008/R=0009/R=0010 are immutable fixture/reference diagnostics; corrected
R=0011 is accepted/immutable. Green is focused `1/1`, C `7/7`, full `50/50`,
Domain `98/98`, and the package is `ReviewedLocalGreen`. The two-commit cohort
then passed exact-head hosted run `31635734392`. At that cohort checkpoint,
Evaluation Plan R=0012 was inactive until its synchronized freeze head became
hosted green.

The first packet is capped at `52` production paths, three C test paths plus two
bounded predecessor-test adaptations, and `7,000` normalized changed C# lines.
Every later packet defaults to ten
production paths, one owning test path, and `3,500` changed lines. Crossing a
cap requires a pre-red design amendment; it never silently raises a limit.
Real Policy, Application routing/I/O, D, Scenario/status/owner, both workflow
filters, runtime-efficiency activation, feature DoD, merge, release, and
publication remain outside C authority.

The owning C plan records per-cohort local and hosted durations, hosted defect
count, owner-identification time, correction/revalidation cost, estimated time
saved against package-by-package hosted validation, and any consistency or
traceability loss. C completion still requires final convergence, atomic record
sync, and exact-head hosted green; `CompletionRecommended` or a local commit is
insufficient.

After C is merged and exact-main hosted green, a separate D micro plan may use
those measured delivery results but no C product evidence. Accepted D topology
must be frozen by pre-D D/RT into roughly two-to-four-package cohorts without
combining distinct expected-red or ownership boundaries. Separate cohorts must
retain real Policy export/registration activation; real codec/parser/index/
projector infrastructure; RULE-0001/0002; RULE-0003/0004/0005 with
specialization/co-report; and repository/provider equivalence plus D-CONVERGE.
D remains inactive here and must freshly prove required B/C behavior against
real Policy registrations.

### `C-EVALUATION-PLAN-01` executable freeze

The first Evaluation packet implements only `PlanEvaluation`; Advance and
Evaluate remain integrity failures. Its one direct Fact is
`ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round`, with
only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0006`. The complete Tests-owned fixture has one ready
Applicable rule with an admitted repository-tree slot, a static repository-
governed-text slot, and the projected repository-target slot. Projector output
is the canonical ItemId sequence `0..2` with owners `alpha,alpha,omega`; the
plan reuses the admitted slot, emits one round-0 none-demand static instruction,
then two round-0 owner shards ordered `alpha` before `omega`. The empty-projector
variant emits no projected instruction or proof/I/O; an applicability-unresolved
predecessor terminalizes the rule and emits no evaluation instruction.

`AcquisitionInstruction.CreateEvaluation` derives both frames/digests, accepts
only canonical contiguous ItemIds and one owner per non-empty shard, and never
accepts caller digests. Planning snapshots all public projections, binds the
same session/predecessor stamp, rejects foreign/stale/reused inputs, and commits
consumption only after a successful non-null result. R replaces only that final
prepared result with `null!`; every negative is marker-free. The exact eight-
path executable allowlist and `1,900/650` normalized line caps are owned by the
C micro-plan; no Abstractions, Domain, Policy, project/package/lock/workflow, or
held packet surface changes. Green is `1/1`, C `8/8`, full Conformance `51/51`,
Domain `98/98`, with Release/format/diff/locks/structure/reviews/record sync and
one unpushed `ReviewedLocalGreen` commit. Canonical red uses the common fresh
one-shot runner, exact FQN filter, marker TRX, native exit `1`, and consumes its
identity irrevocably after `InvocationCommitted`.

Diagnostic R=0012 passed ValidateOnly and executed exactly once, but its sole
Failed TRX returned `EvaluationClosure` before the marker because the retained
fixture had copied all three evaluation slots into applicability. Raw marker
count was `0`; R=0012 is immutable `OracleRejected`/no-success/no-retry. The
bounded correction changes only fixture readiness: applicability retains the
already admitted repository-tree slot, while governed-text and projected-target
slots remain evaluation-ready. R=0013 then reached the marker and passed its
TRX oracle, but immediate green proved that a positional `CloneRule` argument
had replaced evaluation slots instead of applicability slots. Its actual slot
set retained provider-governed text and omitted repository-tree, so R=0013 is
also immutable diagnostic/no-success/no-retry. Corrected R=0014 named both
arguments, constructed the exact repository-governed/repository-target/
repository-tree evaluation set, retained the same FQN, marker, semantic null
seam, argv, allowlist, caps, and oracle, and executed once from its distinct
fresh runner/report/root after the synchronized correction head became hosted
green. R=0014 is accepted/immutable; its green is focused `1/1`, C `8/8`, full
Conformance `51/51`, Domain `98/98`, Release `0/0`, with format/diff,
StructureOnly, publication evidence, and reviews green.

### `C-EVALUATION-ADVANCE-01` executable freeze

The second Evaluation packet implements only `AdvanceEvaluation`; Evaluate
remains an integrity failure. It consumes one exact issued plan, admits the
instruction-digest-bijective proof set, seals static and owner-sharded
projected outcomes, invokes the target index exactly once after Complete
aggregate admission, and returns the schema-1 round-1 closure. Zero projected
demand yields a zero-attempt Complete target outcome and the same single index
invocation. Cancellation or an index host exception before successful return
leaves the predecessor retryable; successful return consumes it, and replay or
foreign/colliding state fails closed. Intent/result and aggregation remain held.

The exact FQN, marker, semantic-null red seam, packet argv, ten-path executable
allowlist, `1,200/260` caps, one-shot runner custody, and package/cohort green
gates are normative in the C micro-delivery plan. No Abstractions, Domain,
Policy, project/package/lock/workflow surface changes. Green advances only to C
`9/11` and full Conformance `52/52`; it does not activate Results/closure before
the Evaluation cohort exact-head hosted gate.

The Evaluation cohort is now immutable `ExactHeadHostedGreen` at exact
[`18a8e3fa28160ec2e622752005b964e0ca98b838`](https://github.com/hasanmanzak/meAndAI/commit/18a8e3fa28160ec2e622752005b964e0ca98b838)
through [run 31660382684](https://github.com/hasanmanzak/meAndAI/actions/runs/31660382684):
Ubuntu `21m26s`, Windows `17m52s`, publication skipped, hosted defects `0`.

### `C-INTENT-RESULT-01` executable freeze

This packet introduces one internal pure transformation and no public member:

```csharp
internal static class EvaluationIntentCore
{
    internal static IReadOnlyList<RuleEvaluation> Mint(
        EvaluationClosure closure,
        CancellationToken cancellationToken);
}
```

`Mint` requires a closure backed by the object-identical `KernelPlanningSession`
and accepted manifest/catalog/export. The closure must contain every catalog
rule exactly once across terminal and evaluation-ready partitions. Every ready
rule's evaluation slot must have exactly one retained acquisition outcome. A
Complete outcome must have one context proof; Incomplete/Failed produces an
ordinal unresolved slot and suppresses that rule's evaluator. Only a rule whose
outcomes are all Complete is evaluation-ready. The core creates one opaque
`QualifiedEvidenceHandle` per Complete proof and an internal handle-to-reference
map, creates `RuleEvaluationInput` with the exact rule identity/profile and
proof map, invokes the object-identical registered evaluator once, and validates
its returned `EvaluationIntent`. It
is deterministic and idempotent and performs no session mutation; the later
aggregation packet alone owns atomic public-kernel consumption.

Intent carrier invariants are final here. Every applicability-reference list
is a defensive unique snapshot; NotApplicable/Unresolved remain non-empty.
Finding/failure related-reference
sequences are defensive snapshots, contain no null or duplicate handle, and do
not repeat their primary handle. An `EvaluationIntent` snapshots both
collections and contains no duplicate semantic tuple. A finding code must map
to exactly one declaration on its rule; its primary and every related reference
kind must be allowed by that declaration. A failure code must occur in the
rule's exact `EvaluationFailureCodes`. Every handle must have been minted for
the same closure. Foreign/stale closure identity, a missing/duplicate outcome,
partition mismatch, or a Complete outcome without proof is
`CatalogIntegrityException(PlanStateInvalid)`. A null intent, unknown/foreign
handle or code, duplicate, disallowed reference kind, or evaluator-registration
mismatch is `CatalogIntegrityException(IntentInvalid)`. Evaluator
exceptions propagate without partial result; cancellation is observed before
each evaluator and before return.

The core converts a valid ready intent by this closed truth table:

| Intent shape | Minted status | Minted payload |
| --- | --- | --- |
| zero findings, zero failures | `Satisfied` | no findings/failures; applicability resolved |
| one or more findings, zero failures | `Violated` | kernel-owned rule identity plus declaration-owned severity/remediation and exact references |
| any failures | `NotEvaluated` | validated failures and any partial findings; applicability resolved, no unresolved slots |
| any Incomplete/Failed evaluation outcome | `NotEvaluated` | evaluator not invoked; no findings/failures; applicability resolved; ordinal unresolved slot keys |

Existing terminal `NotApplicable` and applicability-unresolved `NotEvaluated`
results are preserved value-for-value and merged with ready results in ordinal
RuleId/revision order. Within a result, findings and failures are ordered by
code, primary reference, then related-reference sequence. The reference tuple
is kind, slot key, requirement key, scope target/surface/snapshot identities,
qualification digest, and any root/location/derivation/selector identity.

The exact project-neutral fixture uses the Evaluation-ready closure. Synthetic
RULE-0001 is empty/Satisfied; synthetic RULE-0002 emits exact finding
`protocol.decision.record-missing` over the repository-tree context proof and
is Violated; synthetic RULE-0003 remains terminal
NotApplicable; synthetic RULE-0004 remains terminal applicability-unresolved
NotEvaluated; synthetic RULE-0005 emits exact failure
`protocol.evaluator.reference-ambiguity` and is NotEvaluated. Only
the cloned synthetic RULE-0002 finding declaration extends its existing first
finding's allowed primary kinds with `ContextProof`; code, severity,
remediation, and every real Policy declaration remain unchanged. A second
fixture variant makes one evaluation acquisition Incomplete and proves the
exact unresolved-slot result plus zero evaluator invocation. Expected-
selector resolution, capability-backed rule semantics, real Policy RULE-0001
through RULE-0005, aggregation/verdict, and session consumption remain owned by
later packets/D.

The test fixture callback shape is closed rather than invented during red.
`RuleEvaluatorMirror` owns optional applicability and evaluation delegates,
checks cancellation in both methods, and defaults evaluation to the empty
intent. Each derived RULE mirror forwards those two delegates. The activation
and applicability-closure fixture factories accept an optional ordinal map from
RuleId value to evaluation delegate, reject an unknown key, and bind it only to
the matching object-identical `RuleEvaluatorRegistration`. This seam is Tests-
owned and never appears in production or public API.

```csharp
internal static CFixture CreateFixture(
    IReadOnlyDictionary<string,
        Func<RuleEvaluationInput, EvaluationIntent>>? evaluationByRule = null);

internal static ClosureFixture CreateFixture(
    bool terminalizeEvaluationRule = false,
    bool evaluationReady = false,
    IReadOnlyDictionary<string,
        Func<RuleEvaluationInput, EvaluationIntent>>? evaluationByRule = null);
```

The one Fact is
`ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures`, with only
`ContractSlice=C`, no Scenario/Theory/class trait, and sole marker
`TEST-0210-C-BEHAVIOR-RED-0008`. R=0016 replaces only the fully prepared valid
`Mint` result with `null!`; only that semantic null calls the marker assertion.
All construction, invalid, order, repeat, cancellation, host-exception, and
assertion paths are marker-free. The exact packet argv is:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0008.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures"
```

The exact eight-path executable allowlist and `2,400/900` normalized line caps
are owned by the C micro-plan. R=0016 uses a fresh ValidateOnly/Execute runner,
warning-free Release rebuild, source/runner/HEAD/upstream/status/lock/DLL/PDB
custody, one fresh secure TRX, native exit `1`, connection timeout `300`, outer
bound `420s`, exact marker/result/definition/entry/16-counter oracle, and
irreversible no-retry authority after `InvocationCommitted`. Green is focused
`1/1`, C `10/10`, full Conformance `53/53`, Domain `98/98`, with Release,
format, diff, locks, StructureOnly, publication evidence, reviews, record sync,
and one separate unpushed `ReviewedLocalGreen` commit. Aggregation remains held
until that commit exists; canonical R=0016 remains held until this exact twelve-
record design head is committed, pushed, and exact-head hosted green.

## Internal implementation slices

ContractSlice A's historical delivery is owned by its
[micro-delivery control plan](subf-0143-micro-delivery-plan.md). ContractSlice
B's completed merged delivery is owned by the
[B micro-delivery plan](subf-0143-contractslice-b-micro-delivery-plan.md).
Surface, codec activation, all three wires, B-RESOURCE, B-CACHE, B-ADMISSION,
and B-SEALED-CONTEXT are hosted green; repository-target R=0004 is diagnostic-only, while canonical
R=0005, resource R=0006, cache R=0007, admission R=0011, and sealed-context
R=0012 and corrected codec-derivation R=0014 are accepted/immutable. B is
`11/11`, A+B is `43/43`. Admission
R=0008/R=0009/R=0010 and codec-derivation R=0013 are immutable
diagnostics/no-success. Corrected R=0014 is exact-head hosted green.
B-CONVERGE is merged/exact-main green.
ContractSlice C is decomposed by the current
[C micro-delivery plan](subf-0143-contractslice-c-micro-delivery-plan.md), whose
design head is hosted green. Activation, Applicability, and Evaluation are
exact-head hosted green. C is `9/11`, current A+B+C is `52/52`, R=0012/R=0013
are immutable diagnostics, and R=0014/R=0015 are accepted/immutable.
`C-INTENT-RESULT-01` is `FrozenDesign`/inactive until this synchronized
records/design head becomes exact-head hosted green.

C implementation and D still require separate packet activation, and no
packet is active merely from this list. No directive here allocates new stable
IDs; the four independently reviewable internal slices remain ordered:

1. **A - Catalog and manifest preflight:** exact declarations, canonical
   manifest parse/digest/typed projection, normative fragments, declaration/
   artifact/component closure, slice/complete separation, public export
   projections without executable construction, predecessor/evolution, and
   negative public/friend surface. A declares no kernel and performs no export
   activation or typed-registration validation.
2. **B - Codec admission and typed roots:** codec-registration/model-token
   subset, persistent writer/qualifier pairs, private ticket/proof admission,
   decode/model cache, codec-local ledgers, and ContextProof/Root/codec-derived
   reference sealing.
3. **C - First executable export activation and synthetic complete evaluation
   kernel:** final six-list factory and registration/type-token/public-
   projection bijection plus mismatch negatives; Tests-owned complete six-family
   registration graph, provider-neutral models/capabilities, both parsers,
   indexes/projector/selectors, index cache/shared ledgers, two-phase plans,
   applicability/intents, finding/evaluation minting, status, ordering, and
   aggregation without real Policy code.
4. **D - Real initial-rule qualification:** real Policy repetition of B/C
   vectors, fresh RULE-0001..0005 implementations, and the complete repository/
   provider fixture matrix.

Each slice receives expected red, review, bounded implementation, focused
green, and fresh-diff review before the next begins. [TEST-0210](test-cases.md#test-0210) remains the one
composed canonical scenario.

## External follow-ups that do not weaken this design

- [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  must replace superseded “one typed acquisition envelope” wording, close its
  exact proof implementation/type/artifact contracts, enforce a non-lowerable
  transport hard ceiling before constructing Domain payload carriers, and
  reconcile its exact first live provider surface inventory. [SUBF-0143](README.md#subf-0143) may
  qualify provider-neutral captured fixtures but does not claim live coverage
  for commit comments, labels, checks, or rulesets before [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) does.
- [FEAT-0068](../FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
  must supply the predecessor-trusted release envelope and loaded-artifact
  proof. This slice defines what activation consumes, not release I/O or
  authority transfer.
- Completion of the full normative rule inventory remains a later
  [FEAT-0065](README.md)/[issue #165](https://github.com/hasanmanzak/meAndAI/issues/165)
  owner. Until it exists, the real Policy assembly exposes only the
  qualification slice.

These follow-ups block their respective implementation/authority claims. They
do not create a competing schema, admission, evaluator, or verdict path.

## Gate 2 completion and ContractSlice A correction gate

The historical Gate 2 packet is accepted, merged, and exact-main validated.
Before the corrected ContractSlice A topology may enter C# mutation:

- [x] [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) and the [SUBF-0153](README.md#subf-0153) Gate 2 design are accepted, merged, and
  exact-main validated at the declared input baseline.
- [x] [TEST-0210](test-cases.md#test-0210) siblings, four internal slices, expected-red purity, project/
  lock/workflow transition, and unchanged Windows budget are exact.
- [x] The historical packet's independent bounded red-team found no unresolved
  `Blocking` or `Important` issue, the maintainer accepted it, and it merged at
  exact main [`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7).
- [x] [SUBF-0153](README.md#subf-0153) completed through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173), and exact-main [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256) passed at the A implementation baseline.
- [x] Renewed fresh-diff architecture review of [FIND-0438](README.md#find-0438) and
  [FIND-0439](README.md#find-0439) closed with `0 Blocking`, `0 Important`, and
  `0 Minor`; packet-consistency closure remains separate from that verdict.
- [x] Renewed review of the append-only RunInfo evidence correction and
  [FIND-0440](README.md#find-0440) has no unresolved `Blocking` or `Important`
  finding.
- [x] Historical first-red, ParseCanonical, canonical-string, and
  `A-SCHEMA-SLOT-01` green/review evidence is owned by the micro-delivery ledger;
  it adds no current authority.
- [x] The corrected [maintainer directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228), append-only [BehaviorRed message/echo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054), and append-only [RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849) authorize each separately reviewed
  [TEST-0210](test-cases.md#test-0210) ContractSlice A increment in the exact
  order source/preparation -> exact red -> review -> smallest bounded green,
  one increment at a time. That authority does not accumulate or activate
  ContractSlice B/C/D.

`A-FINDING-01` retained its `R=NotApplicable` / `TestOnlyGreen` /
production-zero route and is exact-head hosted green at
[`2430a67e0140a6c8ce0f26eaebae8aed35259134`](https://github.com/hasanmanzak/meAndAI/commit/2430a67e0140a6c8ce0f26eaebae8aed35259134),
git tree identity `893e6f6dc1a6f0a246dc209be650f906e5f5c702`, and
[run 30767103072](https://github.com/hasanmanzak/meAndAI/actions/runs/30767103072).
The admission FrozenDesign delivery
[`f298e87f98cb0896904a21078e2e3f391b2b8dcd`](https://github.com/hasanmanzak/meAndAI/commit/f298e87f98cb0896904a21078e2e3f391b2b8dcd),
git tree identity `6debfc2f3648ec7972d3e1f21d1f1cc224b35a4a`, and
[run 30774470978](https://github.com/hasanmanzak/meAndAI/actions/runs/30774470978).
It remains the design predecessor, not the admission implementation delivery.
At that historical checkpoint, the exact hosted boundary was admission record-evidence delivery
[`b735853a2153338fd97c366bcd8c212f78bc1bce`](https://github.com/hasanmanzak/meAndAI/commit/b735853a2153338fd97c366bcd8c212f78bc1bce),
git tree identity `fc5ae301331f55f1435b4262c300489e3cbcff2f`, and
[run 30781516326](https://github.com/hasanmanzak/meAndAI/actions/runs/30781516326),
with Windows green in `17m10s`, Ubuntu green in `19m02s`, and publication
verification correctly skipped. `A-ADMISSION-01` remains packet-local
`ReviewedLocalGreen`. `A-PROJECTOR-DAG-01` is packet-local
`ReviewedLocalGreen` with exact packet-local implementation/evidence; hosted
run `30798854880` passed
Windows in `14m58s` and Ubuntu in `19m00s`, with publication verification
correctly skipped. Never-activated `A-CONVERGE-01` is retired. Current A state
and all downstream holds are routed by the header and owning freeze ledger.
