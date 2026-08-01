# [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) ContractSlice A index-slot handoff

| Field | Value |
| --- | --- |
| State | `A-INDEX-SLOT-01` `ReviewedLocalGreen`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |
| Predecessor | Remote-equal [`c73977d4af922aa66c464f6caced0d1aae473665`](https://github.com/hasanmanzak/meAndAI/commit/c73977d4af922aa66c464f6caced0d1aae473665), tree `99095c781e67be1cbeed9fe5cfb1d7004803ce6e`; exact-head [run 30704338972](https://github.com/hasanmanzak/meAndAI/actions/runs/30704338972) Ubuntu/Windows green and publication verifier skipped; separate [PR #174 checks](https://github.com/hasanmanzak/meAndAI/pull/174/checks) report GitGuardian green |
| Authority | Maintainer umbrella on [draft PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) covers ordered remaining A through `A-CONVERGE-02`; exact predecessor, D/RT, evidence, and one-mutating-packet gates remain mandatory |
| D/RT | Original parser/index candidate exceeded the hard line boundary and was strictly redrawn. First pass `0 Blocking / 1 Important / 0 Minor`: activation/RT closure were premature while exact identities, budget/failure order, full matrix, writer-first order, both `(0,0)` factories, and parser/other-index rejection were under-specified. Activation reverted to `FrozenDesign`; the complete freeze assigns all of those values and only the exact writer absent-predicate exception/message may emit the marker. Renewed RT `0 Blocking / 0 Important / 0 Minor`; only then restored `MaintainerActivated / PreRed` |
| Identity | `TEST-0210-A-BEHAVIOR-RED-0004`; `MeAndAI.Protocol.Conformance.Tests.ContractSliceAIndexSlotManifestTests.Enforces_exact_repository_tree_index_and_slot_capability_closure`; only `ContractSlice=A` |
| Budget | Production `210-270`, test `330-390`, total `540-660`; packet ceiling `690`; `700+` forces redraw |
| Progress | `6/18` packets `ReviewedLocalGreen` (`33%`); packet-local cumulative A is green `19/19` |
| LR/P | Single locked restore complete with six lock fingerprints unchanged. P `NotApplicable`; unchanged-source schema-slot focused `1/1` at `D:\Temp\meandai-test-0210-a-index-slot-p-schema-ae918b5eb8a74a6e9126831803ab815d\TEST-0210-A-PREDECESSOR-SCHEMA-SLOT-0004.trx` / `4FBD396466F80A5373A33B8E3C8E0C4CA55995699B7B761AF997644057F3BE60`; cumulative A `18/18` at `D:\Temp\meandai-test-0210-a-index-slot-p-cumulative-bd86c6e63c7d4c1593a9ead3903ef8b6\TEST-0210-A-PREDECESSOR-CUMULATIVE-0004.trx` / `8D8F84F25712CDE59845E99C88C3A34AAAA5C9E5AD5383449CB828EB23508B5E`; each fresh, exact, one invocation, `--no-restore`; neither is R |
| R source | One Fact / only `ContractSlice=A`; `388` lines; SHA-256 `996CDD4A7244A39E702530DF4E45152CAE3EBBE6B430CA3E79FA63FF3756EBF0`; Release `--no-restore` build `0` warnings/errors. Source pass `0/2/0` corrected; two fresh reviews `0/0/0` and `0/0/0` |
| Canonical R | `D:\Temp\meandai-test-0210-a-index-slot-red-a4e9fd0d6c8e44cd9e0e20c65eea37fd\TEST-0210-A-BEHAVIOR-RED-0004.trx`; SHA-256 `72788214F782CE347C68E646D0B3AB82E58B92F7C18EA4B2B07ED60DDC7053A4`; one exact-FQN Failed result and marker Message; permitted marker-free stack, one marker echo, same-FQN `[FAIL]` RunInfo; exact sixteen counters with `total=1`, `executed=1`, `failed=1`; no attachment/infrastructure diagnostic/orphan; timeout restored; programmatic oracle passed; no retry authorized |
| Green | Original-oracle focused `1/1` at `D:\Temp\meandai-test-0210-a-index-slot-green-original-5f90b4d8a1724f5da17984eeb4221ae6\TEST-0210-A-GREEN-ORIGINAL-0004.trx`, SHA-256 `66F8DC42BD29C603E8004EDAB5EF634F69659854F64618FE34889B2A8640CB4F`; final LF-normalized marker-free focused `1/1` at `D:\Temp\meandai-test-0210-a-index-slot-green-lf-final-5793a27fa8f445cbb07582683c308256\TEST-0210-A-GREEN-LF-FINAL-0004.trx`, SHA-256 `B755D5DD4A7ED5E269410A72CB422AF0995B80362712EDDFE4FC9DE4BAFB91EE`; final LF-normalized cumulative A `19/19` at `D:\Temp\meandai-test-0210-a-index-slot-green-lf-cumulative-f13b37ea9fec4fb8b973697898eaac3c\TEST-0210-A-GREEN-LF-CUMULATIVE-0004.trx`, SHA-256 `5BAAFF3717BFA1E5FBEC755F187766D627EBFB52A360749A2F5C06D9AFAF06E6`; each exact and diagnostics-free |
| V | Final LF-normalized source `377` lines / SHA-256 `F94B6138B87EBABBE8D0E4033B94CD41F6B44BF9FA37B58948513D3DA52D280B`; production delta `265`, packet total `642/690`; marker/catch absent; six-project Release build `0` warnings/errors; full format and `git diff --check` clean; six lock fingerprints unchanged. Staging hygiene found two residual CRLF line endings (`w/mixed`); they were normalized to the repository's required LF, then format/build and final focused/cumulative green were rerun. Code/test review was three times `0/0/0`. Post-sync review pass 1 found `0 Blocking / 1 Important / 1 Minor` in stale current-state wording and one sentence flow; all were corrected, then three independent fresh pass-2 reviews each closed `0 Blocking / 0 Important / 0 Minor` |

## Frozen Fact

The retained predecessor zero-capability shape remains valid. The new closed
shape is repository-tree schema/model -> `protocol.index.repository-tree` / `1`
`PerContext`, model input `protocol.model.repository-tree` / `1` at `(1,1)` ->
`protocol.capability.repository-tree` / `1` -> existing repository-tree slot.

Indexer component: `protocol.index.repository-tree` / `1`, assembly
`MeAndAI.Protocol.Policy`, type
`MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex`. Output interface
component: `protocol.type.capability.repository-tree` / `1`, assembly
`MeAndAI.Protocol.Conformance.Abstractions`, type
`MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree`. Exact budget is
`(16777216, 64, 200000, 2000000)`. Canonical failure-code order is
`protocol.budget.exhausted`, then
`protocol.index.repository-tree-unavailable`.

Transient source constructs the otherwise valid graph and invokes the writer
before every direct factory/matrix assertion. Only the exact current writer
`InvalidOperationException` message `This writer increment supports only the
minimal qualification slice.` may emit marker 0004; all other outcomes remain
marker-free.

Positives own byte/digest round trip, exact projection and `TryGetIndex`, nested
field order, slot/producer equality, direct `(1,1)`, and retained zero-capability
closure. Negatives own nested spelling/null/duplicate/order, collection order,
scope/input/model/cardinality, output/interface, producer reachability and
uniqueness, budget/failure codes, component/artifact references, both public
`(0,0)` factory rejections, and explicit parser/other-index rejection. Existing
canonical-number tests retain session-cache numeric boundaries.

## Allowlist and gates

Production: `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`,
`CatalogSliceDeclaration.cs`, and `ComponentInputDeclaration.cs`. Test: one new
`ContractSliceAIndexSlotManifestTests.cs`. Packet records: micro plan,
[TEST-0210 cases](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210),
typed design, and this handoff; the broader authority cohort is
record-only. Public API, project/package/reference/lock/workflow files are held.

Run locked restore once, then predecessor schema-slot focused `1/1` and
cumulative A `18/18`. P is `NotApplicable`. R is one exact filtered invocation
in a fresh GUID directory with one TRX, child-only
`VSTEST_CONNECTION_TIMEOUT=300`, and exact 420-second outer bound; no retry.
Green requires marker-present original-oracle `1/1`, marker-free final focused
`1/1`, cumulative A `19/19`, Release build, standard format, six unchanged lock
hashes, clean diff, and renewed full review.

All green and V requirements above were achieved. The retained source contains
neither marker 0004 nor its legacy catch. The exact production allowlist changed
`265` lines; the final test is `377` lines, for packet total `642/690`. Three
fresh code/test reviews independently closed `0 Blocking / 0 Important /
0 Minor`. Post-sync review pass 1 found one Important stale-state root cause and
one Minor sentence-flow issue; both were corrected, and three independent fresh
pass-2 reviews each closed `0 Blocking / 0 Important / 0 Minor`.
Staging then exposed two residual CRLF endings in the otherwise LF test. After
mechanical LF normalization, source hash, standard format, six-project Release
build, focused `1/1`, and cumulative A `19/19` were all re-established with the
final evidence above.

## Held scope

`A-PARSER-INDEX-01` and all later A packets remain Candidate/inactive. No parser,
other index, projector, admission, finding, selector, complete-profile,
lifecycle, or convergence implementation is active. Final
[TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
Scenario/status/owner/workflow/
[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
B/C/D, WIP/consumer work, merge, release, publication,
and authority transfer remain held.
