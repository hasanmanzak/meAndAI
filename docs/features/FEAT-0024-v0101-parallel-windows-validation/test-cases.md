# FEAT-0024 Test Scenarios

| ID | Owner | Scenario | Expected result | Type | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0115` | `SUBF-0042` | Inspect and execute the Linux full profile, Windows base profile, four exact quick-adoption shard names, partial result boundary, and aggregate job dependencies; vary an unknown shard/profile and an incomplete or failed aggregate dependency. | Linux remains the canonical full run; Windows base delegates only quick adoption; four matrix children run on PowerShell 5.1; partial shards expose no canonical scenario IDs; invalid or incomplete routing fails closed. | Structure / orchestration / negative | Passed | `tests/protocol.tests.ps1`, workflow, focused shard invocations |
| `TEST-0116` | `SUBF-0043` | Reset mock state repeatedly, request independent archive outputs, mutate one output, and inspect the process-local protocol fixture before teardown. | The fixture is built once and retains the same path, refs, clean state, and archive digest; mutable collections and temp paths are fresh; archive outputs are byte-identical before caller mutation and independent afterward. | Integration / isolation / lifecycle | Passed | `tests/quick-adoption.tests.ps1`, real local Git fixture |

## Baseline

| Date | Environment | Command or evidence | Result |
| --- | --- | --- | --- |
| 2026-07-17 | GitHub-hosted Ubuntu and Windows | [Protocol validation run 29568159757](https://github.com/hasanmanzak/meAndAI/actions/runs/29568159757) | Passed; protocol-test step was 117 seconds on Ubuntu and 558 seconds on Windows. |
| 2026-07-17 | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed before FEAT-0024 in 615.1 seconds. |

## Implementation evidence

| Date | State | Environment | Command or evidence | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | Expected-red working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly` and focused immutable-fixture assertions | Failed only the planned `TEST-0115` / `TEST-0116` contracts before implementation. |
| 2026-07-17 | Focused green working tree | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1 -Shard ContractsPreflight` | Passed in 11.5 seconds. |
| 2026-07-17 | Focused green working tree | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1 -Shard AdoptionLifecycle` | Passed in 57.8 seconds. |
| 2026-07-17 | Focused green working tree | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1 -Shard IntegrityFailures` | Passed in 246.8 seconds after resolving `FIND-0157`. |
| 2026-07-17 | Focused green working tree | Windows PowerShell 5.1 | `tests/quick-adoption.tests.ps1 -Shard RepositoryRoutes` | Passed in 39.7 seconds. |
| 2026-07-17 | Final working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -ExecutionProfile WindowsBase` | Passed in 162.3 seconds; every non-delegated Windows suite emitted valid evidence. |
| 2026-07-17 | Final working tree | Windows PowerShell 5.1 | `tests/protocol.tests.ps1` | Passed in 507.6 seconds; all discovered suites and canonical scenarios through `TEST-0116` passed. |
| 2026-07-17 | Pull request #66 at `82ccaaa` | GitHub-hosted Ubuntu and Windows | [Protocol validation run 29573099890](https://github.com/hasanmanzak/meAndAI/actions/runs/29573099890) | Passed: Linux full 158 seconds; Windows base 151 seconds; shard jobs 23, 75, 326, and 47 seconds; aggregate check passed. The Windows critical path was 326 seconds versus the 558-second baseline. |

Post-publication evidence is recorded after each fact exists through issue #65.
Durations are observations and never pass/fail thresholds.
