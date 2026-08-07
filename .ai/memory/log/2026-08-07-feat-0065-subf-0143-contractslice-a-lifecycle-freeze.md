# ContractSlice A lifecycle FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-07 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Parent | ContractSlice A typed-kernel subfeature and its planned scenario |
| State | `A-LIFECYCLE-01` is `FrozenDesign` and inactive |
| Activation predecessor | `A-TRANSITION-01` records synchronization is the immutable exact hosted-green predecessor below |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceALifecycleManifestTests.Enforces_rule_lifecycle_against_transitions_and_active_profiles`; `R=NotApplicable`; no ordinal, marker, or red TRX |
| Green route | `TestOnlyGreen`; one new Fact with only `ContractSlice=A`; no Scenario; production delta `0` |
| Review | Design and independent red-team reviews each closed `0 Blocking / 0 Important / 0 Minor` |
| Progress | Seventeen of twenty live packets are `ReviewedLocalGreen` (`85%`); cumulative A is `30/30`; the parent scenario remains `Planned` |

The records-head gate that permits this design freeze is exact-hosted-green:

```text
deliveryCommitSha=44243dbc8d3e9a1940873545afea3bb16c19fd40
deliveryTreeSha=a0e3ffd1f784c9b60c5c2de5d5fcadfb068725a1
workflowRunId=31174282549
workflowStatus=completed
workflowConclusion=success
ubuntuJobId=92852730737
ubuntuJobConclusion=success
ubuntuJobDuration=00:18:50
windowsJobId=92852730686
windowsJobConclusion=success
windowsJobDuration=00:46:37
publicationJobId=92852731435
publicationJobConclusion=skipped
```

## Frozen carrier and lifecycle truth

- The test consumes `ContractSliceATransitionManifestTests.CreateMixedTransitionManifest()` unchanged: protocol `0.18.0`, current/predecessor catalog versions `2/1`, current rules `RULE-0001`, `RULE-0002`, `RULE-0003`, and `RULE-0005`, plus the sorted Unchanged/Revised/Unchanged/Retired/Added transition set.
- `IntroducedIn` may be earlier than or equal to the enclosing protocol version. Added does not imply that `IntroducedIn` equals the current version.
- A non-null `DeprecatedIn` may be earlier than or equal to the enclosing protocol version. A deprecated but non-retired current rule remains active and remains in every exact compatible named/baseline profile.
- A current rule must have `RetiredIn == null`. Retirement is represented only by an absent-current `Retired` transition; `RULE-0004` therefore remains absent from current rules and profiles.
- This packet does not infer predecessor lifecycle values, require deprecation to imply Revised, authenticate predecessor state, or compare compatibility aliases across snapshots.

## Frozen regression matrix

- Positive P0 retains the unchanged mixed carrier with `RULE-0005.IntroducedIn=0.17.0` under protocol `0.18.0`.
- Positive P1 accepts `RULE-0005.IntroducedIn=0.18.0` without changing its Added transition.
- Positives P2/P3 accept compatible `RULE-0003.DeprecatedIn=0.17.0` and `0.18.0`, retaining `RULE-0003` in the exact profile.
- N1 future `IntroducedIn=0.19.0`, N2 future `DeprecatedIn=0.19.0`, and N3 current `RetiredIn=0.18.0` fail with exact `ArgumentException`, `ParamName=rules`, and `A complete catalog contains an invalid active-rule lifecycle.`
- N4 removal of deprecated-active `RULE-0003` from the compatible profile fails with exact `ArgumentException`, `ParamName=profiles`, and `A named profile must contain exactly its compatible rules.`
- N5 insertion of retired/absent `RULE-0004` into the profile fails with exact `ArgumentException`, `ParamName=profiles`, and `A named profile references a rule outside the catalog.`
- N6 mutates only canonical `deprecatedIn` from `0.18.0` to `0.19.0`; Reader must emit outer exact `FormatException` `A policy manifest value is not canonical.` with the exact N2 argument exception as inner evidence.

## Ownership, caps, and continuation

- Production, transition helper, public/friend/project/package/lock/workflow, and existing test files are locked. The only implementation allowlist entry is new `ContractSliceALifecycleManifestTests.cs`.
- Original-oracle must run at the exact FQN on unchanged production. If it is not green, stop and renew D/RT; do not manufacture a BehaviorRed.
- Target test size is at most `320` lines; hard test/combined cap is `420`; production cap is `0`. Any production need or `421+` additions reopens D/RT.
- After local green, focused/cumulative/Conformance/Domain validation and fresh reviews must close before state can become `ReviewedLocalGreen`; only then may progress become `18/20` (`90%`) and cumulative A `31/31`.
- `A-RESOURCE-01` and `A-CONVERGE-02` remain Candidate/inactive. B/C/D, final Scenario/status/owner/workflow/efficiency-contract activation, merge, release, publication, consumer mutation, and authority transfer remain held.
