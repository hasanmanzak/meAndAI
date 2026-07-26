# FEAT-0055 Test Scenarios and Evidence

No new numbered scenario is introduced. The correction adds a transport
variant to the canonical instruction-graph lifecycle scenario.

| Existing ID | Slice | Action | Expected result | Relationship | State |
| --- | --- | --- | --- | --- | --- |
| [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) | [SUBF-0106](README.md#subf-0106) | Dispatch graph-aware and graph-unaware lifecycle inputs through the real production dispatch contract, including a compact graph identity with non-ASCII content; independently exercise the native stdin encoder under PS5.1 and PS7. | Arguments contain `--json` and no field flags; outer JSON has the exact required string properties; only graph-aware dispatch has the exact nested graph string; raw stdin is UTF-8 without BOM and round-trips exactly. | `ParameterizedVariant`; same lifecycle identity and compatibility contract | Planned expected-red then focused green |

## Test-first and delivery evidence

| Date | Commit / tree | Runtime | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-26 | [v0.15.3 baseline](https://github.com/hasanmanzak/meAndAI/commit/164543d939ef97ec02d96499d3e5b796eed64470) plus TEST-0153 regression only | Windows PowerShell 5.1 | Focused `source-graph-dispatch.case.ps1` owner | Pending expected red |
| 2026-07-26 | Candidate | Windows PowerShell 5.1 / PowerShell 7 | Focused TEST-0153 owner | Pending |
| 2026-07-26 | Candidate | Canonical local validation | One final relevant owner and one full suite | Pending |
| 2026-07-26 | Merged release tree | GitHub Actions / immutable release verifier | Ordinary PR validation and post-publication evidence | Pending |
