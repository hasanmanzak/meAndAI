# FEAT-0046 Test Scenarios

The executable owner remains the existing
[protocol-governance suite](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0174` <a name="test-0174"></a> | [SUBF-0088](README.md#subf-0088) | Inspect the common protocol, active updater contracts, [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md), and meAndAI repository instructions for the reusable-asset single-owner boundary | Protocol-provided code, tests, fixtures, validators, workflows, templates, prompts, scripts, and documentation cannot be copied, reimplemented, ported, shadowed, forked, or generically retested in a consumer; project-specific integration remains consumer-owned; exact consumer-resident, protocol-owned managed projections remain release-pinned; conflicting legacy updater ownership terminology is absent; and missing common behavior returns upstream | Protocol contract / ownership / regression | Passed | Existing protocol-governance suite |

## Evidence log

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | v0.14.0 baseline | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/protocol-governance/protocol-governance.tests.ps1` | Expected red: 11 required non-duplication contract clauses were absent |
| 2026-07-23 | v0.14.1 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/protocol-governance/protocol-governance.tests.ps1` | Passed TEST-0174 in 3.6 seconds before completion-record reconciliation |
| 2026-07-23 | v0.14.1 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1` | Passed [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) current/legacy dispatch and quick-wrapper callback |
| 2026-07-23 | v0.14.1 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1` | Passed [TEST-0083](../FEAT-0013-v084-correction/test-cases.md#test-0083) in 1.9 seconds |
| 2026-07-23 | v0.14.1 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed all discovered protocol contracts; protocol-governance owner completed in 2.843 seconds |
| 2026-07-23 | [PR #113](https://github.com/hasanmanzak/meAndAI/pull/113) head [`045dce6`](https://github.com/hasanmanzak/meAndAI/commit/045dce6e871cadb1ea4da3d2fb06256f9c524816) | GitHub-hosted Ubuntu and Windows | Protocol validation full profile | Expected red during review: the quick-adoption immutable fixture rejected an empty duplicate `v0.14.1` future-release commit on both platforms; [FIND-0212](README.md#find-0212) owns the correction |
| 2026-07-23 | corrected [PR #113](https://github.com/hasanmanzak/meAndAI/pull/113) working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard ContractsPreflight` | Passed the focused immutable-fixture and prerequisite shard after restoring distinct `v0.14.1` current and `v0.14.2` future release identities |
| 2026-07-23 | corrected [PR #113](https://github.com/hasanmanzak/meAndAI/pull/113) working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1` | Passed all 41 owned scenarios in 745.2 seconds; reusable fixture initialization closed at the exact 11/11 operation budget |
