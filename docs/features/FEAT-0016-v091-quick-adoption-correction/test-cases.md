# FEAT-0016 Test Scenarios

Implementation: [`tests/capabilities/initial-adoption/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1).

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0100` | [BUG-0005](https://github.com/hasanmanzak/meAndAI/issues/49) | Run from a no-head local repository without `origin` when the exact derived GitHub repository already exists empty and owns both mapped repository Actions secrets; remove one mapped secret while its file remains absent, probe the same repository after it contains history, and retain the absent-repository fixture. | The empty repository is connected and its present secrets are preserved without local token files or secret writes. A missing secret plus missing file fails before secret mutation; a non-empty derived repository fails before local-remote mutation; an absent repository still requires both files before creation. | Regression / repository identity and credential boundary | Passed | Mock GitHub CLI plus real-Git fixtures |

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | [BUG-0005](https://github.com/hasanmanzak/meAndAI/issues/49) test-first working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red in 366.5 seconds: the no-remote existing repository required `FG_PAT.txt` before secret inventory; fixture-state corrections were completed before green evidence |
| 2026-07-16 | [BUG-0005](https://github.com/hasanmanzak/meAndAI/issues/49) focused green working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass in 351.3 seconds: all declared quick-adoption scenarios including `TEST-0100`; scenario source/ownership binding then passed |
| 2026-07-16 | [BUG-0005](https://github.com/hasanmanzak/meAndAI/issues/49) first complete-suite working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Failed after unaffected child suites passed: three regex-escaped v0.9.0 mock matchers caused quick-adoption REST calls to escape to the real API ([FIND-0146](README.md)) |
| 2026-07-16 | [BUG-0005](https://github.com/hasanmanzak/meAndAI/issues/49) complete-suite confirmation | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass in 473.8 seconds: all discovered suites; quick-adoption machine-readable evidence includes `TEST-0100` |

Hosted and post-publication facts remain external in [issue #49](https://github.com/hasanmanzak/meAndAI/issues/49).
