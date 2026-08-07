# ContractSlice A resource-boundary FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-07 |
| State | `A-RESOURCE-01` is `FrozenDesign` and inactive |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceAResourceManifestTests.Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings`; one Fact; only `ContractSlice=A`; no Scenario |
| Route | P=`NotApplicable`; R=`0016` / `TEST-0210-A-BEHAVIOR-RED-0016`; G is one bounded test plus one constant replacement |

The records-head gate that permits this design freeze is exact-hosted-green:

```text
predecessorCommitSha=b7b31bada52b639e5bcdd4dc7a286821c7e0cc4a
predecessorTreeSha=92cc21e2d407fcf3d4d98b1cc2c8d628275cf335
workflowRunId=31196555916
workflowConclusion=success
ubuntuJobId=92926052870
ubuntuJobConclusion=success
windowsJobId=92926052804
windowsJobConclusion=success
publicationJobId=92926053924
publicationJobConclusion=skipped
```

Canonical rules remain in the [design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md#canonical-manifest-contract).

No expected-red or implementation evidence exists. `A-CONVERGE-02`, B/C/D,
final activation, merge, release, publication, consumer mutation, and authority
transfer remain held.
