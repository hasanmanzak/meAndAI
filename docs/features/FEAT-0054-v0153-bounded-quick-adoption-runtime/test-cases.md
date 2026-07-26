# FEAT-0054 Test Scenarios and Evidence

No new numbered scenario is introduced. This feature changes execution level
and deterministic operation maxima inside existing canonical families.

| Existing ID | Slice | Action | Expected result | Relationship | State |
| --- | --- | --- | --- | --- | --- |
| [TEST-0055](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0055) | [SUBF-0103](README.md#subf-0103) | Run the existing real-Git reflog-only, unborn-head, shallow, tracked/staged, nested/case, and pre-mutation credential boundaries after batching both canonical pathspecs. | Every security and ordering outcome remains equivalent; a successful scan uses exactly three Git processes. | `Distinct`; retained real security/history evidence | Focused PS5.1/7 passing |
| [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107) | [SUBF-0104](README.md#subf-0104) | Run all seven existing CLI version inputs through the exact production contract, then run `older` and `exact-floor` through the full launcher. | Parser outcomes and guidance remain unchanged; the two representatives retain public-boundary ordering; full launcher count is exactly two. | `ParameterizedVariant`; same canonical scenario family | Focused PS5.1/7 passing |
| [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) | [SUBF-0102](README.md#subf-0102), [SUBF-0103](README.md#subf-0103), [SUBF-0104](README.md#subf-0104) | Validate measurement provenance, support-role ownership, exact command/call observations, declared counters, and lower closure targets. | Missing, malformed, duplicate, undeclared, bypassed, or over-budget evidence fails; canonical observations prove 5-to-3 and 7-to-2. | `InfrastructureContract`; direct operation-budget authority | Focused passing |
| [TEST-0160](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0160) | [SUBF-0105](README.md#subf-0105) | Run focused Windows PowerShell 5.1/7 checks, one final canonical suite, and unchanged hosted Windows/Ubuntu jobs; record owner and job durations. | Every scenario remains exact-once and green; topology is unchanged; elapsed observations do not gate correctness. | `Distinct`; cross-runtime and hosted delivery evidence | Pending |

## Test-first evidence

| Date | Commit / tree | Runtime | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-26 | [`9bc12e3`](https://github.com/hasanmanzak/meAndAI/commit/9bc12e394725a86d29efb745cbdfa26407ffd3d2) | Hosted Ubuntu / Windows | [Protocol validation run 30186941435](https://github.com/hasanmanzak/meAndAI/actions/runs/30186941435) | Baseline: Ubuntu 10m55s, Windows 30m26s; quick-adoption 216.519s / 814.141s. |
| 2026-07-26 | Exact v0.15.2 production with measurement-only support adapter | Windows PowerShell 5.1 | `quick-adoption.tests.ps1 -Shard ContractsPreflight` | Expected red in 15.3s: the sole failure observed five credential Git processes rather than maximum three. |
| 2026-07-26 | Candidate after [SUBF-0103](README.md#subf-0103) and [SUBF-0104](README.md#subf-0104) | Windows PowerShell 5.1 | `quick-adoption.tests.ps1 -Shard ContractsPreflight` | Passing in 21.7s; security/history and all version variants green. |
| 2026-07-26 | Same candidate | PowerShell 7 on Windows | `quick-adoption.tests.ps1 -Shard ContractsPreflight` | Passing in 19.2s. |
| 2026-07-26 | Same candidate | Windows PowerShell 5.1 | `test-runtime-efficiency.tests.ps1` | Passing in 7.0s with declared measurement and closure targets. |

## Focused and delivery evidence

Pending implementation. Record only one focused run per slice, one final full
suite, one ordinary hosted PR validation, exact merge/release evidence, and the
post-publication verifier result.
