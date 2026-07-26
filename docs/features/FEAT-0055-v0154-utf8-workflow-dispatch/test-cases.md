# FEAT-0055 Test Scenarios and Evidence

No new numbered scenario is introduced. The correction adds a transport
variant to the canonical instruction-graph lifecycle scenario.

| Existing ID | Slice | Action | Expected result | Relationship | State |
| --- | --- | --- | --- | --- | --- |
| [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) | [SUBF-0106](README.md#subf-0106) | Dispatch graph-aware and graph-unaware lifecycle inputs through the real production dispatch contract, including a compact graph identity with non-ASCII content; independently exercise the native stdin encoder under PS5.1 and PS7. | Arguments contain `--json` and no field flags; outer JSON has the exact required string properties; only graph-aware dispatch has the exact nested graph string; raw stdin is UTF-8 without BOM and round-trips exactly. | `ParameterizedVariant`; same lifecycle identity and compatibility contract | Expected-red and focused PS5.1/7 green |

## Test-first and delivery evidence

| Date | Commit / tree | Runtime | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-26 | [v0.15.3 baseline](https://github.com/hasanmanzak/meAndAI/commit/164543d939ef97ec02d96499d3e5b796eed64470) plus the [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) regression only | Windows PowerShell 5.1 | `source-graph-dispatch.case.ps1` | Expected red in 1.3 seconds: current dispatch did not use one JSON stdin payload. |
| 2026-07-26 | Candidate | Windows PowerShell 5.1 / PowerShell 7 | `source-graph-dispatch.case.ps1` | Passed in 3.7 / 3.2 seconds with exact JSON property, nested-string, Unicode byte, no-BOM, restoration, and legacy-omission evidence. |
| 2026-07-26 | Candidate | Windows PowerShell 5.1 | `capabilities-bootstrap.tests.ps1 -Shard Contracts` | Passed in 4.5 seconds; canonical source handoff requires JSON stdin. |
| 2026-07-26 | Candidate | Windows PowerShell 5.1 | `quick-adoption.tests.ps1 -Shard AdoptionLifecycle` | Passed in 195 seconds; the full launcher and shared gh fixture preserve exact lifecycle dispatch. |
| 2026-07-26 | Candidate after [FIND-0306](README.md#find-0306) | Windows PowerShell 5.1 | `protocol.tests.ps1 -StructureOnly` | Passed in 165.8 seconds; version roles, current-feature state, canonical record links, and the BUG-to-issue registry are exact. |
| 2026-07-26 | Final reviewed candidate after [FIND-0307](README.md#find-0307) | Windows PowerShell 5.1 | `source-graph-dispatch.case.ps1` | Passed in 3.1 seconds; final relevant owner has no unresolved blocking review finding. |
| 2026-07-26 | Candidate before [FIND-0308](README.md#find-0308) | Windows PowerShell 5.1 | `tests/protocol.tests.ps1` | Failed after 2,016.9 seconds only at TEST-0159: the new JSON builder added one unreviewed dynamic-operation identity. |
| 2026-07-26 | Final candidate after [FIND-0308](README.md#find-0308) | Windows PowerShell 5.1 | `test-runtime-efficiency.tests.ps1` | Passed TEST-0158/0159/0162 in 6.8 seconds after replacing the scriptblock invocation with a direct modular helper. |
| 2026-07-26 | Final candidate after [FIND-0308](README.md#find-0308) | Canonical local validation | `tests/protocol.tests.ps1` | Passed all discovered suites in 1,957.8 seconds. |
| 2026-07-26 | Merged release tree | GitHub Actions / immutable release verifier | Ordinary PR validation and post-publication evidence | Pending |
