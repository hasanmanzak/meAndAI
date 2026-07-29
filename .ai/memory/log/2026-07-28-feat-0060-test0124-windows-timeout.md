# 2026-07-28 - [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md) [FIND-0366](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0366) [TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) Windows Full job-ceiling correction

## Directive and boundary

The maintainer separately authorized this correction after the replacement
exact head for
[FIND-0365](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0365)
exposed a second blocking CI result. The canonical owner is
[FEAT-0027](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/README.md) /
[TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124),
not the quick-adoption scenarios interrupted by runner cancellation. This
authorization changes only the single Windows whole-job ceiling and does not
start [FEAT-0060](../../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
C# development or permit a production, consumer, profile,
coverage, authority, retry, operation-timeout, adoption, update, or
PowerShell-retirement change.

## Red evidence and cause

Exact head
[`39d6a0790e967293249dff2e32f5197a149added`](https://github.com/hasanmanzak/meAndAI/commit/39d6a0790e967293249dff2e32f5197a149added)
selected `Full` for the changed PowerShell test paths.
[Run `30366875189`](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189)
passed [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266387),
skipped the [release verifier](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300267382)
as expected, and canceled only the
[Windows job](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189/job/90300266379).
Its check annotation was `The job has exceeded the maximum execution time of
35m0s`; GitHub completed the five-minute cancellation grace at 40 min 01 s.
The displayed quick-adoption Git failures occurred while cancellation was
active and do not establish independent
[TEST-0066](../../../docs/features/FEAT-0011-stability-closure/test-cases.md#test-0066),
[TEST-0116](../../../docs/features/FEAT-0024-v0101-parallel-windows-validation/test-cases.md#test-0116),
or [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126)
defects.

The nearest successful Windows `Full` evidence is
[run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744):
the PowerShell 5.1 step used 30 min 17 s and the whole job used 31 min 48 s,
leaving about three minutes inside the 35-minute ceiling. A local PowerShell
5.1 `quick-adoption.tests.ps1 -Shard All` diagnostic reached only its external
20 min 04 s observation ceiling, returned no authoritative verdict, and left
no orphan. The current signature repeats historical
[FIND-0160](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160).

## Test-first correction and current evidence

[TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124)
first required an exact 60-minute Windows bound while the workflow remained at
35. Its PowerShell 7 StructureOnly structural verifier failed in 201 seconds
with exactly one problem: `Windows full validation timeout does not cover the
measured serial-suite budget.`

Only `.github/workflows/protocol-tests.yml` then changed from 35 to 60 minutes
for `Validate on windows-latest`. The same structural verifier passed in 176.9
seconds. Linux remains exactly 20 minutes and post-publication remains exactly 5;
[TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124)
continues to enforce both unchanged siblings and the single-job topology.

The checksummed official actionlint v1.7.12 Windows asset passed both workflow
definitions. The PowerShell 5.1
[TEST-0123](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0123)
owner passed in 17.9 seconds. The unchanged
[TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
Windows-native streaming owner passed on PowerShell 7 / Windows PowerShell 5.1
in 10 / 13 seconds. Candidate StructureOnly passed on PowerShell 7 / Windows
PowerShell 5.1 in 187.8 / 279 seconds, with protocol-governance observations
of 185685 / 276067 ms. Exact-commit and hosted evidence remain pending.

## Continuation

The selector/topology owners, actionlint, both-runtime candidate StructureOnly,
and bounded fresh-diff review are complete. Commit the evidence graph, then run
only the HEAD-dependent StructureOnly check on PowerShell 7 and Windows
PowerShell 5.1 because current governance reads `HEAD`. Push once and accept
closure only after that exact head passes both protected Ubuntu and Windows
jobs. Do not rerun the unchanged canceled head, change quick-adoption operation
timeouts, add retries or fan-out, or treat cancellation fallout as three
independent defects. After hosted closure, update
[issue #155](https://github.com/hasanmanzak/meAndAI/issues/155) and
[PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) with immutable record
links and the exact run evidence.
