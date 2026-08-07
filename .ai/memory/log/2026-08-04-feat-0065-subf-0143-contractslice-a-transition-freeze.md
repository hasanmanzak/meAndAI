# ContractSlice A transition ReviewedLocalGreen handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-04 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Parent | ContractSlice A typed-kernel subfeature and its planned scenario |
| State | `A-TRANSITION-01` is packet-local `ReviewedLocalGreen`; downstream packets remain inactive |
| Activation predecessor | `A-PREDECESSOR-01` is the immutable exact hosted-green activation predecessor recorded in the canonical owning finding |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes`; canonical-R ordinal `0015` |
| Review | Design, red-team, final code/test, and evidence/scope reviews each closed `0 Blocking / 0 Important / 0 Minor` |
| Progress | Seventeen of twenty live packets are `ReviewedLocalGreen` (`85%`); cumulative A is `30/30`; the parent scenario remains `Planned` |

The records-head gate that permits this design freeze is exact-hosted-green:

```text
deliveryCommitSha=8092b5b4b8865284c16b44c20d141ead97bce87f
deliveryTreeSha=efda8d73a991a6114c67f61ac5abf5f31e7c8cd1
workflowRunId=30893199151
workflowStatus=completed
workflowConclusion=success
ubuntuJobId=91939879598
ubuntuJobConclusion=success
ubuntuJobDuration=00:12:57
windowsJobId=91939879516
windowsJobConclusion=success
windowsJobDuration=00:47:19
publicationJobId=91939880281
publicationJobConclusion=skipped
```

The distinct freeze-delivery head also passed exact hosted validation before
implementation began:

```text
freezeDeliveryCommitSha=ff6932e027cc4ffffe5da3bb1716f5f231f1c4d1
freezeDeliveryTreeSha=535e31a78b01d43b142e6d582f99281a2cd73bab
workflowRunId=30901158080
workflowConclusion=success
ubuntuJobDuration=00:19:52
windowsJobDuration=00:38:52
publicationJobConclusion=skipped
```

## Retained carrier and ownership

- The positive Existing carrier uses protocol `0.18.0`, current/predecessor catalog versions `2/1`, current rules `RULE-0001`, `RULE-0002`, `RULE-0003`, and `RULE-0005`, with `RULE-0002` at revision `2` and every other current rule at revision `1`.
- Canonical transitions sort by RuleId as `Unchanged`, `Revised`, `Unchanged`, `Retired`, `Added`. `RULE-0004` is absent current; `RULE-0005` is absent predecessor. The current compatible profile contains exactly `RULE-0003` and `RULE-0005`.
- `Unchanged` carries equal previous/current revisions and optional `reviewedAuthority`; `Added` omits previous revision; `Revised` carries both revisions with current strictly greater; `Retired` omits current revision.
- Reader owns strict wire grammar/projection, Writer canonical variant serialization, and `CompleteCatalogDeclaration` RuleId-based current/absent membership. Positional zipping is forbidden.
- Production is limited to `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`, and `CompleteCatalogDeclaration.cs`; tests to new `ContractSliceATransitionManifestTests.cs` plus deletion-only cleanup in `ContractSliceAPredecessorManifestTests.cs`.
- Public API, `RuleTransitionDeclaration`, project/friend/lock/workflow files, lifecycle, resources, predecessor authenticity/coherence, and downstream activation remained outside this packet.

## Accepted canonical red

- P is `NotApplicable`. Canonical R ran exactly once at the exact FQN, with one Fact, only `ContractSlice=A`, and no Scenario.
- All valid setup, factories, and carrier construction occur outside the guard; only assignment from `CanonicalManifestWriter.Write(parsedExisting)` is guarded.
- Only exact `InvalidOperationException` with message `This writer increment supports only the minimal qualification slice.` may emit the marker. Type/message mismatch, Reader/setup failure, and every other exception remain marker-free.
- The accepted TRX is `D:\Temp\meandai-test-0210-a-d396aa32b6504bf8b8d782f93f1ae9b9\TEST-0210-A-BEHAVIOR-RED-0015.trx`, SHA-256 `8E08CAF887D69FF38B247960501AF470DB0DC840154586DF2D4A78CD77D8780E`. Its transient source was `353` lines at SHA-256 `5593A547D7347224081A28755D6F09B70D8CC5C7C5269B5DDBD1D756DEEBC428`.
- The programmatic oracle proved one selected/discovered/executed/failed result, zero passed/skipped, all sixteen counters, exact marker custody, no attachment, and no orphan testhost. Canonical R was never rerun.

## [`FIND-0461`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0461) fixture correction

- After the production correction allowed Writer to return, the first exact-FQN validation failed marker-free and console-only with `FormatException: protocol.manifest.component-closure`; no TRX was requested or produced, so this is neither canonical R nor green evidence.
- The Existing fixture retired current `RULE-0004` but still inherited the A-FULL component binding `protocol.evaluator.rule-0004`. Reader correctly rejected that orphan functional component.
- The bounded test-only correction removed only that inherited component mapping, retained the shared Policy artifact, and changed no production, public API, project, package, lock, or workflow surface. Corrected original-oracle source was `364` lines at SHA-256 `17FD5051B63EB14D44BDF501E108FC15D3FC10E1D666C853C52BC5FC630C5B09` and passed the exact FQN `1/1` console-only.
- Canonical R remains accepted and immutable because its sole Writer guard/type/message/marker observation preceded Reader and was independent of the downstream orphan. The defect is `VerifiedDefect`, `Resolved`, severity `medium`, confidence `high`, priority `p0`, and owned by the test fixture.

## Marker-free retained matrix

- Reader owns `91` valid-JSON negatives: four variant required-field matrices, optional-authority errors, unknown kind, illegal variant fields, Unchanged/Revised revision relations, every adjacent property swap, and one unexpected property.
- Catalog owns `7` direct vectors: missing/duplicate mappings, absent-current non-Retired, current Retired, and Unchanged/Added/Revised current-revision mismatches. Each is exact `ArgumentException`, `ParamName=transitions`.
- Every Reader mutation changes one unique object, preflights as valid JSON, and reaches outer `FormatException`; `RULE-9998` is reserved only for the absent-current non-Retired negative.
- The new test owns `CreateMixedTransitionManifest()` and all helpers; the later lifecycle packet may consume this seam unchanged.
- Final custody cleanup removed the marker, legacy message, and guard. Marker-free retained source is `351` lines at SHA-256 `44A7F1B6A016105D088005DFECC6AE8B516890295890B7AA5FF10C13F5A1E4C6`.

## Green evidence, caps, and continuation

- Production additions are Reader `98/125`, Writer `12/45`, Catalog `55/70`, total `165/240`. The final new test is `351/377` lines and `351/450` gross test additions; combined additions are `516/690`.
- Predecessor cleanup is exactly `73` physical deletions: message constant `1`, call `1`, boundary helper `22`, cases `20`, rejection helper `6`, array `2`, JSON `21`; the source moved from `410` to `337` lines at SHA-256 `AFC1D669C574D88C30DCF6C2F4DBB0E719867BA781489D09DBEF020F359BB26E`. It is audited separately and never netted.
- Marker-free focused `1/1` evidence is `D:\Temp\a-transition-green-final-b499d81a22d745938d2f47176fb48e83\TEST-0210-A-GREEN-FINAL-0015.trx`, SHA-256 `4379CF7870B15513B1F2066A3A0830AD19770B2E55C690AF4B5C3226DEA0A04C`.
- Retained predecessor `1/1` evidence is `D:\Temp\a-predecessor-retained-final-18688052cc844581bcd792e39afac5e5\TEST-0210-A-PREDECESSOR-RETAINED-FINAL.trx`, SHA-256 `DFA4FD289FD342CBA76797FCA53BF71CF91AE4EDBFE672703EB0C9634DED94F8`.
- Cumulative A `30/30` evidence is `D:\Temp\a-transition-final-cumulative-0f450a6aa3da4f74974a53f6465a9999\TEST-0210-A-TRANSITION-CUMULATIVE.trx`, SHA-256 `E3AF629531B429E4775668676E9B2CB2E9F95204E291244591E8130A8AAF1EE0`. Full Conformance is the identical `30/30` identity set at SHA-256 `69C6596C0F4B50BC093C4F4370C5C9498001F51365DCA95E5673D7DF99E3B85F`; full Domain is `98/98` at SHA-256 `F75A09C4865FCDAB8288FD90423E59CAA1FB990B91D5651F73C2BA2967BDE959`.
- All three pass TRX oracles have exact counters, no diagnostics or attachments, and no orphan testhost. Full Release build is `0` warnings/errors; format, diff, all `15` lock fingerprints, and final reviews are green.
- This record makes no hosted claim for the implementation worktree or its future commit. Exact implementation and record-delivery identities belong to the later hosted evidence closure.
- `A-LIFECYCLE-01`, `A-RESOURCE-01`, and `A-CONVERGE-02` remain Candidate/inactive. B/C/D, final activation, merge, release, publication, consumer mutation, and authority transfer remain held.
