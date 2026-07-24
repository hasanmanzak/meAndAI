# FEAT-0047 Test Scenarios

Canonical executable ownership remains in the
[protocol-governance suite](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1).
The
[publication-evidence suite](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1)
owns the separate GitHub-surface scenario.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0175` | [SUBF-0089](README.md#decomposition-and-gate) | Inspect the direct common rule, templates, reusable text generators, and every repository Markdown document through positive and negative fixtures | Every repository-document cross-record reference is a clickable link to its exact target; valid balanced, escaped, angle-delimited, reference-style, and GFM-autolink forms pass, while free-text identifiers, numbers, known titles, referential paths, wrong targets, code-formatted pseudo-links, unresolved references, invalid bare-URL boundaries or domains, shorthand, and cross-document ranges fail; an artifact's own identity is not treated as a reference to another artifact | Protocol contract / traceability / regression | In progress | [Protocol-governance owner](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1) |
| `TEST-0176` | [SUBF-0089](README.md#decomposition-and-gate) | Exercise issue, pull-request, conversation-comment, submitted-review, inline-review, exact merge-commit comment, title, pagination, Markdown-destination, autolink, and publication-indirection references through positive and negative fixtures | Every GitHub-surface cross-record reference uses an absolute clickable exact target; valid balanced, escaped, angle-delimited, and GFM-autolink forms pass, while free text, invalid bare-URL boundaries or domains, relative or wrong targets, unresolved pseudo-links, and non-permalink or parent-mismatched comment links fail; stable issue indirection and each artifact's own identity remain valid | External integration / traceability / regression | Passed | [Publication-evidence owner](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1) |

## Evidence log

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-24 | Immutable `v0.14.1` commit `f153e21a3098945a1b669563046f875ef6fb8b60` | Repository comparison | `git diff f153e21a3098945a1b669563046f875ef6fb8b60 -- PROTOCOL.md .github templates scripts tests` | Expected red established before implementation: the direct rule, prompts, linked writers, and [TEST-0175](test-cases.md) did not exist |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 | `pwsh -NoProfile -File tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1` | Passed [TEST-0083](../FEAT-0013-v084-correction/test-cases.md) and [TEST-0176](test-cases.md), including balanced Markdown destinations and GFM autolink boundary/domain fixtures, in 31.0 seconds |
| 2026-07-24 | `v0.14.2` working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1` | Passed [TEST-0083](../FEAT-0013-v084-correction/test-cases.md) and [TEST-0176](test-cases.md), including balanced Markdown destinations and GFM autolink boundary/domain fixtures, in 45.5 seconds |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 / Windows PowerShell 5.1 | `tests/capabilities/capability-adoption/capability-review.tests.ps1` | Passed the capability-review lifecycle owner in 20.4 / 21.2 seconds |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 / Windows PowerShell 5.1 | `tests/capabilities/consumer-update/protocol-update-reliability.tests.ps1` | Passed [TEST-0148](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md) and [TEST-0149](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md) in 23.455 / 22.965 seconds |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 / Windows PowerShell 5.1 | `tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Passed the managed finalization owner in 10.599 / 18.993 seconds |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 / Windows PowerShell 5.1 | Initial-adoption `Contracts` and `ContractsPreflight` shards | Passed link/marker contracts in 3.450 / 3.464 seconds and preflight contracts in 19.040 / 21.575 seconds |
| 2026-07-24 | `v0.14.2` working tree | PowerShell 7 | `pwsh -NoProfile -File tests/capabilities/protocol-governance/protocol-governance.tests.ps1` | Parser, link, and [TEST-0175](test-cases.md) fixtures produced no failure; the owner remained intentionally red only because the current feature record stays `In progress` until its remaining completion gates pass |
