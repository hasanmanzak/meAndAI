# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-08-13**<br>
Protocol version: **0.16.0**<br>
Latest immutable release before this unmerged development: **0.16.0**

The bounded-capacity delivery is complete through
[FEAT-0069](../../docs/features/FEAT-0069-instruction-graph-capacity/README.md):
the prospective `v0.17.0` schema-2 profile selects `8192` edges, `1048576`
bytes per parsed blob, and `8388608` aggregate parsed bytes while every target
through `v0.16.0` remains immutable. The bounded per-blob amendment is
exact-head hosted green; release and publication remain separate.
Focused graph, quick-adoption profile, StructureOnly, and publication-evidence
gates plus merged exact-main Ubuntu/Windows validation are green; canonical
details remain in the
[capacity handoff](log/2026-08-09-feat-0069-instruction-graph-capacity.md).

The maintainer accepted
[DEC-0035](../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
on 2026-07-29. Follow the accepted
[architecture](../../docs/architecture/protocol-governance-and-execution/README.md),
[successor plan](../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md),
[WIP extraction ledger](../../docs/architecture/protocol-governance-and-execution/wip-extraction-ledger.md),
the accepted and historical delivery evidence cataloged by the canonical
continuation route below,
the current ContractSlice A predecessor-manifest exact-head hosted-green
`ReviewedLocalGreen` state,
and the maintainer-approved
[SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
[micro-delivery control plan](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-micro-delivery-plan.md).
The product is one versioned executable protocol platform implemented in C#,
not a collection of CLI products. [SUBF-0152](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
and [TEST-0220](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
are complete through [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170),
exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).

[SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
and [TEST-0221](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
are complete through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173)
at exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd).
[Run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256)
passed both stable jobs. The prior local-candidate state and discarded
`NETSDK1064` attempt remain historical only.

The accepted Gate 2
[typed-evaluation-kernel design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md)
now includes the maintainer-approved ParseCanonical-only ContractSlice A
topology correction. Its
topology-correction handoff in the [canonical log index](log/README.md)
and
the related historical correction evidence cataloged by the
[canonical log index](log/README.md)
are historical; the hosted-green
target parser/index/slot reviewed-local-green handoff in the canonical log index
is also historical. The admission-proof reviewed-local-green handoff is
historical. ContractSlice A was delivered through
[merged PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) and its
historical umbrella authority; follow the corrected historical
[Gate 3 directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228).
[The append-only BehaviorRed evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
governs the exact TRX message/echo/type oracle.
[The append-only RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
permits only one exact marker-free same-FQN xUnit `[FAIL]` bookkeeping node and
keeps every other diagnostic invalid.
[The append-only assertion-stack clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5150679793)
permits zero or one nonempty marker-free standard assertion StackTrace in the
same failed result and keeps every other ErrorInfo content invalid.
[FIND-0439](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0439)
closes the parser resource, exception, component-reachability, and trusted-
provenance boundaries.
[FIND-0440](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0440)
records the RunInfo correction; its mandatory fresh rerun is now satisfied by
the accepted post-synchronization canonical A BehaviorRed.
[TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`; the A scaffold, exact SurfaceRed, 48-type structural surface,
and focused `11/11` checkpoint exist locally. Topology/parser and RunInfo
reviews passed `0 Blocking` / `0 Important` / `0 Minor`. Pre-applicable-
clarification BehaviorRed observations are diagnostic
only. The fresh exact-FQN run recorded in the historical
correction handoff in the canonical log index
passed the complete clarified oracle as canonical BehaviorRed. The first limited
ParseCanonical increment then passed the original-oracle and final-source exact-
FQN checks `1/1`, cumulative A `12/12`, format verification, a warning/error-
free final six-project Release build, and private-byte source review. That first-
green support review had `0 Blocking`, one unnumbered remaining-A coverage
`Important`, and no unresolved `Minor`. The historical correction evidence
cataloged by the [canonical log index](log/README.md) preserves the second A
exact-red FQN/marker and records its bounded green. The
writer-owned
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)`, legacy/green byte
probe, 1,226-byte Unicode fixture and digest, exact `é` (`C3 A9`) versus `é`
(`65 CC 81`) non-normalization, and the lexical/malformed matrix. The reader
re-encodes with that same codec and ordinal-compares the complete original
quoted token without a second grammar; only `GetString()`'s
`InvalidOperationException` is caught at that call boundary. Direct malformed
UTF-16 remains codec-argument `ArgumentException`, while only document-caused
codec failure maps to public `FormatException`. Its seam predecessor passed
`1/1`, red and bounded source reviews closed `0 Blocking`/`0 Important`/
`0 Minor`, original-oracle and final-source greens passed `1/1`, and cumulative
A passed `13/13`. Locked restore, unchanged six lock fingerprints, standard
format, clean diff check, and the zero-warning/error six-project Release build
passed; the non-gating severity-info scan exposed pre-existing informational
backlog/suggestions and is not claimed clean. The canonical-string coverage
`Important` is closed, but remaining A is pending and [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`. At that historical checkpoint, each reviewed A source, exact
red, and smallest green proceeded separately and no later A increment was active;
the [FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442)
correction paragraph below now owns current routing. A constructs
no executable export and declares no kernel. B/C/D, workflow/scenario-owner/
[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
WIP extraction, consumer, release, publication, authority-transfer, and
PowerShell-retirement changes remain unauthorized.

The maintainer-approved micro-delivery plan now routes through bounded
[FIND-0441](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0441)
recovery. Historical cumulative `13/13` content is
[`5fa7f7d`](https://github.com/hasanmanzak/meAndAI/commit/5fa7f7d02e64032e867d7c84d42662ba080b3c90),
with records synchronized by
[`9107a49`](https://github.com/hasanmanzak/meAndAI/commit/9107a4936449048a057156e4714a99165ba1f24f).
Exact pushed
[`7f60e0c`](https://github.com/hasanmanzak/meAndAI/commit/7f60e0c66a49056b9e9854ccc353acfe67f65ed5)
is recovery input, not an
accepted predecessor: it contained 18 static A facts, no valid `18/18` run, and
no retained per-packet red/RT/review evidence. Recovery consolidates the rule
fact and now passes four exact focused filters `1/1` plus cumulative A `17/17`
locally. Final local V passed locked restore with the six relevant lock
fingerprints unchanged, zero-warning/error Release build, format, diff/marker
checks, and fresh full-diff review `0/0/0`. Audited
git tree: `4ca02623e1f14233e847ebf64bc52d3cfe8869b8` was committed and pushed as
[`f64860ef456380232c23dfc4729a0d87f257483d`](https://github.com/hasanmanzak/meAndAI/commit/f64860ef456380232c23dfc4729a0d87f257483d)
on draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174). Its first
hosted validation exposed
[FIND-0442](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0442):
17 partial facts carried the final
[Scenario trait for TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
while the A-D
scenario remained `Planned`. The correction is complete at remote-equal
[`c88beefee54f3f0d0e0e623807eb8a4c9bf48032`](https://github.com/hasanmanzak/meAndAI/commit/c88beefee54f3f0d0e0e623807eb8a4c9bf48032),
using that commit's exact tree, with exact-head hosted
[run 30659970794](https://github.com/hasanmanzak/meAndAI/actions/runs/30659970794)
green. It is the frozen predecessor for packet-local `ReviewedLocalGreen`
`A-SCHEMA-SLOT-01`; its historical evidence remains in the
schema-slot handoff in the canonical log index.
Partial facts retain only `ContractSlice`; final scenario traits still join the
atomic final scenario-status/scenario-owner/workflow-test-step target-and-filter/
[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
activation. All three prior 0003 attempts remain diagnostic. The
[FIND-0443](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0443)
recurrence set is exactly the `cf51...` and `9a39...` runs. The `c96...` TRX is
a separate zero-discovery VSTest infrastructure abort, not R. Canonical R is
accepted at
`D:\Temp\meandai-test-0210-a-96ff2a5352c141f78f8bebbfc0f957f0\TEST-0210-A-BEHAVIOR-RED-0003.trx`,
SHA-256 `4B7B8398362E23B9364BBB7C11C4A538BA984B3474A52F2D95567CB340545FDE`.
It used exactly one invocation under the active
[VSTest timeout recurrence](project.md#vstest-testhost-connection-aborts-before-discovery),
with a process-scoped 300-second child connection timeout, an exact 420-second
outer bound, the complete oracle passing, and the parent environment remaining
unset. Do not rerun it. Original-oracle green passed `1/1` in the exact
`d223...` TRX, final topology-clean focused green passed `1/1` in `6423...`,
and cumulative A passed `18/18` in `c93d...`; the exact paths and SHA-256 values
are retained in the historical
schema-slot handoff in the canonical log index.
Final test source is 436 lines with SHA-256
`FC43FDDA4B273BFCBED442FB145E28BA207EE433A08A9D3E43BEA88574154480`;
production `256` plus test `436` is `692/700` changed lines and the estimated
`+2` remains inside the hard cap. Release build passed with zero warnings and
errors, format passed, and all six locks remained unchanged.

[TEST-0074](../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0074)
first exposed a fixture-data
[TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
literal; it is corrected to neutral
[TEST-0001](../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001)
with no `Scenario` trait. Corrected local StructureOnly was
inconclusive at a controlled 300-second active timeout with no orphan; the
earlier full suite was likewise inconclusive at 600 seconds, below the official
20/35-minute budgets. These are infrastructure observations, not red or green
evidence. Fresh full-diff review pass 2, performed after the pass-1
traceability correction, closed `0 Blocking / 0 Important / 0 Minor`.
A-SCHEMA-SLOT-01 handoff in the canonical log index
now records pushed candidate
[`3b93c9e4...`](https://github.com/hasanmanzak/meAndAI/commit/3b93c9e4b93e19baa150b57d8a2c99c4038689d8)
and hosted [run 30699069580](https://github.com/hasanmanzak/meAndAI/actions/runs/30699069580),
where both stable jobs failed only clickable-reference
[TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175).
[FIND-0444](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0444)
is resolved at exact remote-equal
[`c73977d...`](https://github.com/hasanmanzak/meAndAI/commit/c73977d4af922aa66c464f6caced0d1aae473665),
git tree identity: `99095c781e67be1cbeed9fe5cfb1d7004803ce6e`, with exact-head hosted
[run 30704338972](https://github.com/hasanmanzak/meAndAI/actions/runs/30704338972)
green. The oversized parser/index candidate was strictly redrawn under the hard
line cap. `A-INDEX-SLOT-01` is now `ReviewedLocalGreen`: original-oracle and
topology-clean focused green passed `1/1`, cumulative A passed `19/19`, and the
final `642/690` packet plus validation and three live `0/0/0` reviews are
recorded in the
[D/RT disposition](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-micro-delivery-plan.md#a-index-slot-01-drt-observation),
whose historical first `0/1/0` finding and renewed RT `0/0/0` remain evidence.
[TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
stays `Planned`; the parser-record packet's historical cumulative A is green
`20/20`. Exact remote-equal
[`25e26f908e1f123640c758e42e1db92d5eea6dde`](https://github.com/hasanmanzak/meAndAI/commit/25e26f908e1f123640c758e42e1db92d5eea6dde),
git tree identity: `9a0dc5bb9b41c9509366ab92bc7de642724938b6`, passed Ubuntu and Windows in
[run 30716919833](https://github.com/hasanmanzak/meAndAI/actions/runs/30716919833).
[FIND-0445](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0445)
and [FIND-0446](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0446)
are resolved. Strict D/RT retires never-activated `A-PARSER-INDEX-01` as a
non-live `RetiredBeforeActivation` tombstone and replaces it with three ordered
packets. `A-PARSER-RECORD-SLOT-01` is exact-head `ReviewedLocalGreen`;
renewed Writer-first D/RT closed `0/0/0` in three independent current-tree
reviews and StructureOnly is green.
[FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447)
is resolved at exact [`3fa66695eb978954b321545e2d226c1effa6ead4`](https://github.com/hasanmanzak/meAndAI/commit/3fa66695eb978954b321545e2d226c1effa6ead4) /
[run 30746985780](https://github.com/hasanmanzak/meAndAI/actions/runs/30746985780).
[FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448)
is resolved by exact
[`561a760401cf7312a15cadea3e6bf9f56b488d5d`](https://github.com/hasanmanzak/meAndAI/commit/561a760401cf7312a15cadea3e6bf9f56b488d5d),
git tree identity: `8f120c396bd531e7b33d9c00a1265e0a7be6d1ba`, and successful
[run 30748757145](https://github.com/hasanmanzak/meAndAI/actions/runs/30748757145).
`A-GOVERNED-REFERENCE-SLOTS-01` is `ReviewedLocalGreen`; exact remote-equal
[`6b49de76d7420c33a3707c3aeeab78b4362fb602`](https://github.com/hasanmanzak/meAndAI/commit/6b49de76d7420c33a3707c3aeeab78b4362fb602),
git tree identity: `15cb1b6d048b40436a676df53472d4ad9dc23441`,
passed Ubuntu and Windows in
[run 30753246121](https://github.com/hasanmanzak/meAndAI/actions/runs/30753246121).
Its exact R/G evidence and focused `1/1`, cumulative A `21/21`, validation, and
reviews are cataloged by the [canonical log index](log/README.md).
Historical target-freeze head
[`e1dc05637e316cb27d54050b06dfa26683fecb85`](https://github.com/hasanmanzak/meAndAI/commit/e1dc05637e316cb27d54050b06dfa26683fecb85),
git tree identity: `4d60d8814d28fe025248540fd3ad0237b22d37e7`, made Windows
green while Ubuntu failed only
[TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) in
[run 30756586843](https://github.com/hasanmanzak/meAndAI/actions/runs/30756586843).
[FIND-0449](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0449)
is resolved by exact
[`9180b1ff300534ab38d34d2227ab2f79878c9007`](https://github.com/hasanmanzak/meAndAI/commit/9180b1ff300534ab38d34d2227ab2f79878c9007),
git tree identity: `1ebabf4091d9ee9d2a77ef9eb22fa7be1bc4c434`, and successful
[run 30758284884](https://github.com/hasanmanzak/meAndAI/actions/runs/30758284884).
The exact hosted-green selector delivery is
[`2bbd36f5dd9ee975778063719fe8f879873e00d5`](https://github.com/hasanmanzak/meAndAI/commit/2bbd36f5dd9ee975778063719fe8f879873e00d5),
git tree identity `fe543889cc68fad6a61139f0125a41ca4050ce40`, with Ubuntu and Windows green in
[run 30772197693](https://github.com/hasanmanzak/meAndAI/actions/runs/30772197693).
It follows the exact hosted-green finding delivery
[`2430a67e0140a6c8ce0f26eaebae8aed35259134`](https://github.com/hasanmanzak/meAndAI/commit/2430a67e0140a6c8ce0f26eaebae8aed35259134),
git tree identity `893e6f6dc1a6f0a246dc209be650f906e5f5c702`, and
[run 30767103072](https://github.com/hasanmanzak/meAndAI/actions/runs/30767103072).
At the historical full-manifest checkpoint, fourteen of twenty live packets
were `ReviewedLocalGreen` (`70%`) and cumulative A was `27/27`.
[TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`; `A-FINDING-01` is packet-local `ReviewedLocalGreen`; its exact
evidence is cataloged by the [canonical log index](log/README.md), with
`R=NotApplicable`, `TestOnlyGreen`, production delta `0`, and exact-head hosted
delivery complete. `A-SELECTOR-01` is packet-local `ReviewedLocalGreen`; its
exact evidence is cataloged by the [canonical log index](log/README.md):
canonical R is exact, production gross delta is `12/20`, retained test source
is `370` lines, cumulative A is `24/24`, and exact-head hosted delivery is
complete. `A-ADMISSION-01` is packet-local `ReviewedLocalGreen`; its exact
evidence is cataloged by the [canonical log index](log/README.md),
after exact frozen-design predecessor [`f298e87f98cb0896904a21078e2e3f391b2b8dcd`](https://github.com/hasanmanzak/meAndAI/commit/f298e87f98cb0896904a21078e2e3f391b2b8dcd),
git tree identity `6debfc2f3648ec7972d3e1f21d1f1cc224b35a4a`, and
[run 30774470978](https://github.com/hasanmanzak/meAndAI/actions/runs/30774470978).
The immutable admission implementation delivery is
[`c1653d45c99eb01291bc571e93d74db80d94d9e8`](https://github.com/hasanmanzak/meAndAI/commit/c1653d45c99eb01291bc571e93d74db80d94d9e8),
git tree identity `7f547daa92ca22d4f4f288e5ac8a97f890185bd7`; Ubuntu passed in `18m12s`,
Windows passed in `17m28s`, and publication verification was correctly skipped
in [run 30778711538](https://github.com/hasanmanzak/meAndAI/actions/runs/30778711538).
The bounded records-only correction retains the exact hosted-green admission
predecessor and first-freeze failure evidence. `A-PROJECTOR-DAG-01` is now
packet-local `ReviewedLocalGreen` with immutable marker
`TEST-0210-A-BEHAVIOR-RED-0010`, exact FQN, 26/3 successor, 25/3 reproduction,
the enumerated 103-case role-aware producer-DAG contract, exact `26/26`
cumulative green, final `0/0/0` review, and accepted `770/770` combined line
budget. The exact implementation identity and hosted evidence are retained in
the canonical projector handoff. Exact-head hosted validation passed Windows in
`14m58s` and Ubuntu in `19m00s`; publication verification was correctly skipped.
Never-activated `A-CONVERGE-01` is retired and excluded from the denominator.
Its one-for-one replacement `A-FULL-MANIFEST-01` is
packet-local `ReviewedLocalGreen`. Canonical R ran once and remains immutable at
SHA-256 `F586F5BC8FFD5964EB1857512FA089FC8E5E5D3A054E39F28850057BE75DC0DB`;
the post-fix sentinel is diagnostic only, and the corrected-original green is
`264F9BEA27ED1B458C8E74AF0448D710356B95218E385F8DF7EFCB2E06128986`.
The historical `A-FULL-MANIFEST-01` checkpoint retained two bounded
sibling/fixture corrections that changed only stale applicability assertions
and premature planned-scenario fixture literals after the immutable `25/27`
observation. Final FullManifest is `1/1` at
`B11EBABED2AE2D938B65F3C8202694B88364DA1AF0E2DDADBCC69754EC450489`,
cumulative A is `27/27` at
`0392900A44314848BD0EDBC7425A0ABE5767B2E960726AD29DBF5AC78AB77A90`,
full Conformance is `27/27`, full Domain is `98/98`, StructureOnly is green at
`elapsedMs=484633`, and publication evidence is `7/7` in `329.3s` without a
published-state claim. Implementation commit/push completed; the first hosted
head passed Windows and failed Ubuntu only on the instruction-graph edge budget.
The bounded records-only correction is exact-head hosted-green at
`canonical owning-finding correction head`, tree
`canonical owning-finding correction tree`, and run `30834117740`;
Windows passed in `15m53s`, Ubuntu in `17m50s`, publication verification was
correctly skipped, and that correction graph is `4094/4096`. This record closure
adds only the two reserved evidence relations, so its final delivery graph is
`4096/4096` and is closed by the exact evidence in the canonical owning
finding; Windows passed in `17m28s`, Ubuntu in `12m28s`, and publication
verification was correctly skipped.
`A-COMPLETE-PROFILE-01` is now exact-head hosted-green
`ReviewedLocalGreen` at the exact implementation commit and replacement hosted
run recorded in the canonical feature finding; its git tree identity is recorded
there.
Windows passed in `44m13s`, Ubuntu passed in `11m50s`, publication verification
was correctly skipped, and the implementation tree graph is `4095/4096`.
`A-PREDECESSOR-01` is immutable exact hosted-green predecessor history
recorded in the canonical owning finding. Its subsequent records
synchronization also passed exact-head hosted validation; publication
verification was correctly skipped. Canonical R `0014` and `0015` are
immutable and were not rerun.
The lifecycle records-only freeze head is exact-hosted-green: Ubuntu passed in
`20m44s`, Windows in `46m51s`, and publication verification was correctly
skipped. The exact lifecycle implementation identity recorded in the canonical
handoff passed Ubuntu in `19m36s` and Windows in `36m02s`; publication verification was
correctly skipped. ContractSlice A, B, and C are merged/exact-main green; C is `11/11`. Policy activation, real producer infrastructure, and the first-rules cohort are `ExactHeadHostedGreen`; `D-RULE-0003-01` and `D-RULE-0004-01` are `ReviewedLocalGreen`; D is `8/11` and A+B+C+D/full Conformance is `62/62`. The specialized-rules cohort is local `2/3` with push held; RULE-0005 is next/inactive, and the parent scenario and final activation remain held.
The exact record-delivery closure reached the full `4096/4096` instruction-graph
budget. Ubuntu passed in `19m52s`; Windows reached its exact 45-minute job
ceiling after every emitted suite result was successful. The bounded correction
removed six redundant root-memory navigation relations whose targets remain in
the canonical history index and changed only the measured Windows job ceiling
from 45 to 55 minutes after a second test-first infrastructure review; topology,
invocation count, coverage, and all packet semantics remain unchanged.
The exact same-owner timeout oracle produced one deliberate failure in
`482.2s` while Windows remained at 45 minutes and passed in `447.4s` after only
that bound became 55. Root StructureOnly passed in `437.1s`, publication
evidence passed `7/7` in `293.8s` without a published-state claim, and the exact
workflow route/efficiency owner passed. Final independent reviews closed
`0/0/0`. The canonical feature finding retains the exact immutable correction
identity and hosted run. Ubuntu passed in `19m24s`, Windows in `42m54s`,
publication verification was correctly skipped, and the correction graph is
`350/4092`.
The records-only delivery adds exactly the two reserved immutable-evidence
relations and prospectively validates at `350/4094`, but does not claim hosted
proof for its own future head. At that historical checkpoint,
`A-PREDECESSOR-01` remained Candidate/inactive until the delivery head became
exact-hosted-green.
The governed-reference packet's historical exact implementation predecessor was
remote-equal
[`fca0778663238b83bb2ede7cba5ab52012414689`](https://github.com/hasanmanzak/meAndAI/commit/fca0778663238b83bb2ede7cba5ab52012414689),
git tree identity `05c7591565d965966285cd51226446b2f54c81bc`, with Ubuntu and Windows green in
[run 30722890590](https://github.com/hasanmanzak/meAndAI/actions/runs/30722890590).
Exact activation head
[`cf8920e...`](https://github.com/hasanmanzak/meAndAI/commit/cf8920e6a42b9118761c30599f8fcb9f87f5335f)
made Windows green while Ubuntu failed only
[TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
in [run 30744358545](https://github.com/hasanmanzak/meAndAI/actions/runs/30744358545);
the thirteen-label correction is resolved by the exact
[FIND-0447](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0447)
evidence above. The separate Writer-first activation hold is resolved by the
exact [FIND-0448](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0448)
evidence above. The
packet-local evidence remains unchanged, but pushed head
[`bfa961d...`](https://github.com/hasanmanzak/meAndAI/commit/bfa961d1f661588dc48f337720cae2ef741887a7),
git tree identity: `07ceea87ae934c53e64eb2bd9e3ecf2904fa3943`, failed only
[TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175)
record authoring in
[run 30712296217](https://github.com/hasanmanzak/meAndAI/actions/runs/30712296217).
[FIND-0445](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0445)
records that historical failure. Intermediate correction head
[`43c1800...`](https://github.com/hasanmanzak/meAndAI/commit/43c1800b551c0f7d337a20dd290390094d72311c),
git tree identity: `2d550a6a894f6dcaa43b73bf156cb72d7c13e9e3`, made Windows
green while Ubuntu failed only
[TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178)
with twenty-three ambiguous Git tree identities in
[run 30714966450](https://github.com/hasanmanzak/meAndAI/actions/runs/30714966450).
[FIND-0446](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0446)
owns their documentation/memory-only object classification correction; both
findings close at the exact hosted-green predecessor above. Follow the
[canonical log index](log/README.md) for the current transition
`ReviewedLocalGreen` handoff. The complete-profile, admission-proof, and target parser/index/slot
reviewed-local-green handoffs cataloged there are historical.
Do not let a
small-context agent select its own contract, evidence ordinal, FQN, marker,
oracle, allowlist, or held-scope exception.

Immutable [v0.16.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.16.0)
is published at
[2329f944694d24523f85b3a60352743918f0e5cd](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
[PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) and
[issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) retain the
merge, test, and immutable publication evidence for
[FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md).

The immutable [v0.15.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.6)
release is complete at
[`5321f1f1aa5966114c69b46bf6ed9191df109e6b`](https://github.com/hasanmanzak/meAndAI/commit/5321f1f1aa5966114c69b46bf6ed9191df109e6b).
[PR #152](https://github.com/hasanmanzak/meAndAI/pull/152) and
[issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) retain the
delivery, review, test, and publication evidence for
[FEAT-0058](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md).

[FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
is the completed shared technical prerequisite. Follow the historical
portable-package completion handoff in the canonical log index
for its slice evidence. Its release does not authorize any successor feature,
consumer change, or authority migration.

[FEAT-0048](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md)
/ [BUG-0031](https://github.com/hasanmanzak/meAndAI/issues/117),
[SUBF-0092](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md#subf-0092),
[TEST-0179](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0179),
[TEST-0180](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180),
and [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) own the
bounded v0.14.3 API-2026 merge-evidence propagation correction. Follow the
v0.14.3 handoff in the canonical log index.

[FEAT-0049](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/README.md)
/ [BUG-0032](https://github.com/hasanmanzak/meAndAI/issues/119),
[SUBF-0093](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/README.md#subf-0093),
[TEST-0181](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181),
and [issue #119](https://github.com/hasanmanzak/meAndAI/issues/119) own the
bounded `v0.14.4` runtime-shape correction. Follow the
v0.14.4 handoff in the canonical log index.

[FEAT-0050](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md)
/ [BUG-0033](https://github.com/hasanmanzak/meAndAI/issues/121),
[SUBF-0094](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md#subf-0094),
[TEST-0182](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182),
and [issue #121](https://github.com/hasanmanzak/meAndAI/issues/121) own the
bounded `v0.14.5` basename-label correction. Follow the
v0.14.5 handoff in the canonical log index.

This directory is the portable, curated handoff between the maintainer and AI
collaborators. It is not the common memory of consuming projects. Each consumer
creates its own `.ai/memory` outside the protocol submodule.

Read in this order:

1. [Project snapshot](project.md)
2. The current continuation identified in the [log index](log/README.md)
3. Canonical feature and decision documents linked by those records

Memory ownership and boundaries are defined by
[DEC-0002](../../docs/decisions/DEC-0002-project-local-memory.md).

## Recording rules

- Store durable project facts and collaboration constraints, not raw chat.
- Mark assumptions and open questions explicitly.
- Link to issues, pull requests, features, decisions, tests, or commits.
- Keep current tool, environment, integration, and implementation routes in the
  [Active recurrence knowledge](project.md#active-recurrence-knowledge) section
  of the project snapshot. These entries are routing evidence, never executable
  regression evidence. Retain a concise `Stale` or `Superseded` routing
  tombstone in the active index and move only its detailed history to dated
  logs.
- Date facts that may become stale.
- Correct obsolete entries with a new record; do not silently rewrite history.
- Never store credentials or unrelated project details here.
