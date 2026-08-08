# ContractSlice A resource-boundary FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-07 |
| State | `A-RESOURCE-01` is local `ReviewedLocalGreen`; hosted checks are pending |
| Identity | Exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceAResourceManifestTests.Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings`; one Fact; only `ContractSlice=A`; no Scenario |
| Route | P=`NotApplicable`; accepted immutable R=`0024` / `TEST-0210-A-BEHAVIOR-RED-0024`; `0016` cadence-infrastructure diagnostic, `0017` PowerShell-host diagnostic, `0018` Job-identity diagnostic, `0019` xUnit-stderr diagnostic, `0020` stdout-shape diagnostic, `0021` TRX-validator diagnostic, `0022` ExitTime diagnostic, and `0023` exit-code diagnostic; G is the bounded test plus `MaximumDepth 64 -> 9`; local green/reviews are complete and hosted checks are pending |

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

The first `0016` invocation created no TRX/report and stopped at `302.5221ms`
cadence lateness; it is never retried/promoted and cannot authorize G. Native
Job-member capture post-build dry validation is `9.903ms`; renewed D/RT/review gates the
fresh corrected invocation. The first `0017` invocation used Windows PowerShell 5.1
and stopped in `Add-Type` before evidence-directory creation or `dotnet test`
because that host cannot compile the runner's C# 6+ get-only auto-properties.
It is never retried/promoted and cannot authorize G. The first `0018` invocation
produced exact BehaviorRed TRX (`1/1/0/1`, `3.841319s`, SHA-256
`89D881785929221FC28A718815286A863B6AA8940A8833337A8FE2F92BC7E6CF`) but no
sampler report because Job PID `80408` lost exact metrics between fences. It is
immutable Job-identity diagnostic and cannot authorize G. The corrected runner adds
PowerShell 7, bounded `32 x 1ms` fence stabilization, an OS-enforced `1.5 GiB`
Job memory cap/native peak evidence, a direct `<=50ms` canonical capture gate,
audit-union retention across incomplete rounds, and exit-churn dry validation. The first
`0019` invocation produced exact BehaviorRed TRX (`1/1/0/1`,
`3.8481559s`, SHA-256
`F50CD0C3D9CC36FEB177C21C0857FAC680825699FAD1027FF6FF843F27BB548F`) but no
sampler report because empty-stderr policy rejected xUnit's sole exact-FQN
`[FAIL]` line. List/pass/fail probes isolated the contract and the transient Fact
was removed before rebuilding. It is immutable xUnit-stderr diagnostic and
cannot authorize G. The first `0020` invocation produced exact BehaviorRed TRX at
`D:\Temp\meandai-test-0210-a-evidence-26d21f52b82049cb87ea220f9ba2b432\meandai-test-0210-a-c05f53e47b5c4086b1736d6b7ecabae9\TEST-0210-A-BEHAVIOR-RED-0020.trx`
(`1/1/0/1`, `4.0820838s`, SHA-256
`852A8156F0A9D0E61F7A04722DF91FADAB3EC1CF7863776FA59C47AFD20F26C4`) but no
sampler report because the stdout oracle required one raw marker occurrence while
canonical output contains one marker-only diagnostic line and one occurrence in
the exact TRX result-path line. The failing-console probe established that exact
shape and was removed before rebuilding. `0020` is immutable stdout-shape
diagnostic and cannot authorize G. The first `0021` invocation produced exact
BehaviorRed TRX at
`D:\Temp\meandai-test-0210-a-evidence-1a35f1f56e384d2e945ef692ced8f74a\meandai-test-0210-a-6f4993253147464695de8e46dd6e6b61\TEST-0210-A-BEHAVIOR-RED-0021.trx`
(`1/1/0/1`, `4.2296268s`, SHA-256
`F6DFDBC58600EF5268B70E1BC2469ECEB1BB35908CB024C482519CB35F23B3BE`) but no
sampler report. Offline replay isolated PowerShell expression precedence: the
eleven ResultSummary adapter regex expressions had collapsed into one pattern.
It is immutable TRX-validator diagnostic and cannot authorize G. The corrected
array/CR handling passes the complete `0021` TRX offline. The first `0022`
invocation then produced exact BehaviorRed TRX at
`D:\Temp\meandai-test-0210-a-evidence-6efc76444eab41ac8cb3c6f99465c725\meandai-test-0210-a-dacdc6c119a94a8fae330bdd9ffc6fca\TEST-0210-A-BEHAVIOR-RED-0022.trx`
(`1/1/0/1`, `4.5237249s`, SHA-256
`E925D18B325972902093B430CC2A4C3AA6ED16191535B71438426F055CBE63C7`) and that
TRX passes the corrected validator offline, but no sampler report exists because
the atomically created Job process exposes null PowerShell `Process.ExitTime`.
The same null was reproduced without dotnet test by the dry atomic child. `0022`
is immutable ExitTime diagnostic and cannot authorize G. The first `0023`
invocation then produced report
`D:\Temp\meandai-test-0210-a-evidence-3fb1566f965344fab4bf9d98098b9e46\meandai-test-0210-a-688587e00d474928b58d529f91c0fac7.sampler.json`
(SHA-256 `4009CDEA4542E35EA37D78EE9D3A97C4F389CC054CACF0898696573CA54E30B4`)
and exact BehaviorRed TRX
`D:\Temp\meandai-test-0210-a-evidence-3fb1566f965344fab4bf9d98098b9e46\meandai-test-0210-a-688587e00d474928b58d529f91c0fac7\TEST-0210-A-BEHAVIOR-RED-0023.trx`
(`1/1/0/1`, `4.6141616s`, SHA-256
`A13D6BA2D871250CB35C0C75CE63E19764949255CDB1176A34FE8A00205A3B91`).
Its console/TRX/custody/cadence/memory evidence is otherwise canonical: `80`
samples, `26.885ms` maximum lateness, `114.795ms` maximum interval,
`19.634ms` maximum exact capture, `460,746,752` aggregate peak bytes, and
`311,787,520` native Job peak bytes. However, the report serializes
`exitCode: null`; PowerShell `$null -ne 0` let the nonzero-exit gate fail open.
Both independent reviews therefore returned `1/0/0`. `0023` is immutable
exit-code diagnostic and cannot authorize G. Accepted immutable `0024` obtains the
typed exit code from the retained native process handle through
`GetExitCodeProcess`, fails closed on API failure or `STILL_ACTIVE`, and accepts
only a nonzero `System.Int32`. Its validation child proves exact native zero;
null, zero, `Int64`, and string probes are rejected. Fresh Release build passed
with `0` warnings/errors, and mutation-free validation passed `4,916`
exit-churn captures at maximum `20.206ms`, native Job peak evidence,
source/PDB SHA-256
`08A465CE2B6FEECB4C67A1A5BF6C48F987005E218394888B5D52F49A430B1A8B`, and
runner SHA-256
`8BCCD373B3553EA5D1C79EB989A7C0C85BB7614F71F3BBB7A271D5B233C71734`.
The single accepted canonical R produced report
`D:\Temp\meandai-test-0210-a-evidence-0dc776b3d0164cafa2f1ce15b35674c1\meandai-test-0210-a-a2ef3f1b356b4c06a29f718ca2c5c32d.sampler.json`
(SHA-256 `0A87EC24D540BAA434C6A0C51BDC17F642851D027B9838EDD88CFA659434FD8F`)
and exact BehaviorRed TRX
`D:\Temp\meandai-test-0210-a-evidence-0dc776b3d0164cafa2f1ce15b35674c1\meandai-test-0210-a-a2ef3f1b356b4c06a29f718ca2c5c32d\TEST-0210-A-BEHAVIOR-RED-0024.trx`
(`1/1/0/1`, `3.9275173s`, SHA-256
`221DE7EA48C6C548F40DC4B07F54CD1F7B8608CBA14A38AE4AC342A627E1D61B`).
It records typed native `exitCode=1`, `65` samples, `6,417.632ms` root/sampler
duration, `23.925ms` maximum lateness, `122.26ms` maximum interval, `16.71ms`
maximum capture, `450,334,720` aggregate peak bytes, `306,827,264` native Job
peak bytes, and exact conhost/dotnet/testhost descendants. Two independent
immutable-artifact reviews accepted it at `0/0/0`; it was not rerun.

G changes only private `CanonicalManifestReader.MaximumDepth` from `64` to `9`
(`+1/-1`) and removes the transient marker/legacy branch from the bounded test.
The first local green exposed an over-exact test assertion: runtime
`JsonReaderException` is a `JsonException` subtype. Replacing exact-type with
`IsAssignableFrom<JsonException>` matches the frozen wording and requires no
production broadening. Fresh focused green is `1/1`; cumulative A and full
Conformance are `32/32`; Domain is `98/98`; Release solution build is `0`
warnings/errors; format verification passes. Test SHA-256 is
`CCBA4CA72FBF1CCA9F6F9366F619CBED46E912ACF0EBE8BB27E67EF2F7171E15` and
production SHA-256 is
`59778EBB360B46833130FBCF7EC7995D17137A98F4857812331379681DBA8D86`.
Fresh post-green code/test and evidence/scope reviews both closed `0/0/0`.
Canonical R=`0024` and bounded local green are accepted; hosted checks are
pending. `A-CONVERGE-02`, B/C/D,
final activation, merge, release, publication, consumer mutation, and authority
transfer remain held.
