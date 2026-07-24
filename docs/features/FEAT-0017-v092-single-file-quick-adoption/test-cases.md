# FEAT-0017 Test Scenarios

Implementation: [`tests/protocol.tests.ps1`](../../../tests/protocol.tests.ps1).

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0101` | `FEAT-0017` | Inspect the current quick-command section, canonical launcher inventory, version pin, feature record, and release-asset contract. | The guide links the exact current-version `Invoke-MeAndAIQuickAdoption.ps1` release asset outside the consumer target and shows exactly one local `-File` invocation without inline API/download/persistence commands, `Invoke-Expression`, pipe-to-shell execution, or a second wrapper; the launcher retains the exact immutable-release gate. | Structural / distribution boundary | Passed locally | Repository structure validator |

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | Test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Expected red in 3.2 seconds: six TEST-0101 failures identified the inline API, parsing, persistence, variable, and command-stack remnants |
| 2026-07-16 | Focused green working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | TEST-0101 passed after [FIND-0147](README.md); the runner exited only on the intentionally incomplete current-feature status gate before this record was completed |
| 2026-07-16 | First complete-suite working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Failed in 173 seconds after the unaffected suites passed: [TEST-0041](../FEAT-0007-local-codex-adoption/test-cases.md) found three supply-chain facts removed with the old inline command ([FIND-0149](README.md)) |
| 2026-07-16 | Confirmation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 460 seconds: all discovered suites; quick-adoption evidence includes [TEST-0100](../FEAT-0016-v091-quick-adoption-correction/test-cases.md), and root scenario evidence includes `TEST-0101` |

Hosted and post-publication asset facts remain external in [issue #51](https://github.com/hasanmanzak/meAndAI/issues/51).
