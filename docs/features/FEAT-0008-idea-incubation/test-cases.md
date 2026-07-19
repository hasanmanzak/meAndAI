# FEAT-0008 Test Scenarios

Implementations: `tests/capabilities/idea-incubation/idea-incubation.tests.ps1`, the existing
bootstrap adapter fixture, and the complete repository suite.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0043` | `SUBF-0015` | Inspect the protocol, idea index, reusable template, decision, and repository's first idea. | The lifecycle is non-authorizing, uses only the four bounded statuses, preserves terminal history, and requires linked promotion before delivery. | Structural / contract | Passed | PowerShell source and link assertions |
| `TEST-0044` | `SUBF-0016` | Bootstrap a consumer with an absent or existing `docs/ideas/README.md`, then run the existing updater and repository suites. | Collision-free adoption installs the exact index; an existing index produces manifest-only review without overwrite; existing consumers retain pinned-template access without updater managed-path expansion. | Real-Git integration / regression | Passed | Bootstrap adapter fixture and full suite |

## Required coverage

- Idea identity, statuses, minimum fields, and non-authorizing behavior.
- Promotion and rejection traceability.
- Repository index and first deferred multi-agent idea.
- Pinned consumer template and adoption-guide mapping.
- Absent-only initial adoption and collision preservation.
- Existing updater managed-path and full protocol regression behavior.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.6.2` before FEAT-0008 | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing `TEST-0001` through `TEST-0042` in 90.9 seconds |
| 2026-07-15 | FEAT-0008 test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/idea-incubation.tests.ps1` | Expected red: 36 missing lifecycle, index, template, and adoption-contract assertions |
| 2026-07-15 | FEAT-0008 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/idea-incubation.tests.ps1` | Pass: `TEST-0043` and structural `TEST-0044` in 2.5 seconds |
| 2026-07-15 | FEAT-0008 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities-bootstrap-adapter.tests.ps1` | Pass: absent index and collision preservation, including `TEST-0044`, in 49.1 seconds |
| 2026-07-15 | FEAT-0008 first full run | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Failed: `FIND-0062` stale escaped API-ref fixture; focused quick-adoption confirmation then passed in 47.9 seconds |
| 2026-07-15 | FEAT-0008 convergence working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: complete `TEST-0001` through `TEST-0044` in 114.4 seconds |
| 2026-07-15 | FEAT-0008 final working tree | Windows PowerShell 5.1 | `git diff --check`; `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: no whitespace errors; complete `TEST-0001` through `TEST-0044` in 101.1 seconds |
