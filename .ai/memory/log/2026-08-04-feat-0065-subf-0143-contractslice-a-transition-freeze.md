# ContractSlice A transition FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-04 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Parent | ContractSlice A typed-kernel subfeature and its planned scenario |
| State | `A-TRANSITION-01` is `FrozenDesign` and inactive |
| Activation predecessor | `A-PREDECESSOR-01` is the immutable exact hosted-green activation predecessor recorded in the canonical owning finding |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes`; ordinal `0015`; marker/TRX stem `TEST-0210-A-BEHAVIOR-RED-0015` |
| Review | Design and red-team reviews each closed `0 Blocking / 0 Important / 0 Minor` |
| Progress | Sixteen of twenty live packets are `ReviewedLocalGreen` (`80%`); cumulative A is `29/29`; the parent scenario remains `Planned` |

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

## Frozen carrier and ownership

- The positive Existing carrier uses protocol `0.18.0`, current/predecessor catalog versions `2/1`, current rules `RULE-0001`, `RULE-0002`, `RULE-0003`, and `RULE-0005`, with `RULE-0002` at revision `2` and every other current rule at revision `1`.
- Canonical transitions sort by RuleId as `Unchanged`, `Revised`, `Unchanged`, `Retired`, `Added`. `RULE-0004` is absent current; `RULE-0005` is absent predecessor. The current compatible profile contains exactly `RULE-0003` and `RULE-0005`.
- `Unchanged` carries equal previous/current revisions and optional `reviewedAuthority`; `Added` omits previous revision; `Revised` carries both revisions with current strictly greater; `Retired` omits current revision.
- Reader owns strict wire grammar/projection, Writer canonical variant serialization, and `CompleteCatalogDeclaration` RuleId-based current/absent membership. Positional zipping is forbidden.
- Production is limited to `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`, and `CompleteCatalogDeclaration.cs`; tests to new `ContractSliceATransitionManifestTests.cs` plus deletion-only cleanup in `ContractSliceAPredecessorManifestTests.cs`.
- Public API, `RuleTransitionDeclaration`, project/friend/lock/workflow files, lifecycle, resources, predecessor authenticity/coherence, and downstream activation remain outside this packet.

## Frozen expected-red

- P is `NotApplicable`. Canonical R runs exactly once at the exact FQN, with one Fact, only `ContractSlice=A`, and no Scenario.
- All valid setup, factories, and carrier construction occur outside the guard; only assignment from `CanonicalManifestWriter.Write(parsedExisting)` is guarded.
- Only exact `InvalidOperationException` with message `This writer increment supports only the minimal qualification slice.` may emit the marker. Type/message mismatch, Reader/setup failure, and every other exception remain marker-free.
- The TRX must contain exactly one selected/discovered/executed/failed result, zero passed/skipped, and satisfy all sixteen established oracles. R is immutable after acceptance and never rerun.

## Frozen retained matrix

- Reader owns `91` valid-JSON negatives: four variant required-field matrices, optional-authority errors, unknown kind, illegal variant fields, Unchanged/Revised revision relations, every adjacent property swap, and one unexpected property.
- Catalog owns `7` direct vectors: missing/duplicate mappings, absent-current non-Retired, current Retired, and Unchanged/Added/Revised current-revision mismatches. Each is exact `ArgumentException`, `ParamName=transitions`.
- Every Reader mutation changes one unique object, preflights as valid JSON, and reaches outer `FormatException`; `RULE-9998` is reserved only for the absent-current non-Retired negative.
- The new test owns `CreateMixedTransitionManifest()` and all helpers; the later lifecycle packet may consume this seam unchanged.

## Caps, cleanup, and continuation

- Production caps are Reader `125`, Writer `45`, Catalog `70`, total `240`; retained new-test source `377` lines; gross tests `450`; combined `690`. Production above `240` reopens D/RT; `700+` redesigns.
- Predecessor cleanup is exactly `73` physical deletions: message constant `1`, call `1`, boundary helper `22`, cases `20`, rejection helper `6`, array `2`, JSON `21`; it is audited separately and never netted.
- After freeze-delivery hosted green: canonical R; RuleId Catalog partition; atomic Writer guard/serializer; atomic Reader raw/parser/projection/validator; exact `91+7` green matrix; exact cleanup; cumulative validation.
- `A-LIFECYCLE-01`, `A-RESOURCE-01`, and `A-CONVERGE-02` remain Candidate/inactive. B/C/D, final activation, merge, release, publication, consumer mutation, and authority transfer remain held.
