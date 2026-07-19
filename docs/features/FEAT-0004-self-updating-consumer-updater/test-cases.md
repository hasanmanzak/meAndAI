# FEAT-0004 Test Scenarios

Test implementation:
[workflow and resolver tests](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1),
[adapter fixtures](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1), and
[repository structural tests](../../../tests/protocol.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0022` | `SUBF-0007` | Inspect updater credential wiring and run without a write token. | `MEANDAI_UPDATER_TOKEN` exclusively authenticates consumer checkout, push, and GitHub API mutation; missing credentials stop before mutation and the job token is read-only. | Structural / integration | Passed | Workflow assertions and adapter fixture |
| `TEST-0023` | `SUBF-0007` | Resolve the authenticated PAT owner and inspect an existing proposal from another actor. | The token owner's exact login is trusted; missing or different ownership blocks reconciliation without cleanup. | Integration | Passed | Adapter fixture |
| `TEST-0024` | `SUBF-0008` | Compare canonical current assets and stage an upgrade with a mixed changed/unchanged target asset set. | All current blobs match the pinned templates; the gitlink and only target-different assets are staged with exact target modes/blobs. | Integration | Passed | Adapter fixture |
| `TEST-0025` | `SUBF-0008` | Remove, customize, case-drift, or substitute a current/target updater asset. | Reconciliation fails before push or pull-request mutation and preserves existing work. | Negative / boundary | Passed | Resolver and adapter fixtures |
| `TEST-0026` | `SUBF-0008` | Validate and supersede multi-path managed proposals, then inspect adoption/version contracts. | Exact expected paths and blobs are required; extra, missing, or wrong assets block cleanup; one-time migration and later self-update are documented. | Regression / structural | Passed | Resolver, adapter, and repository assertions |

## Required coverage

- Success: a target release updates the pointer and exact changed updater asset
  subset in one draft proposal.
- Credential boundary: source reads and consumer writes use different secrets;
  missing or expired write access produces no mutation.
- Identity boundary: authenticated actor rotation never silently adopts an old
  proposal.
- Integrity: current drift and target path/blob/mode mismatch fail closed.
- Supersession: replacement verification still precedes old proposal cleanup,
  with existing leases and reopen compensation unchanged.
- Migration: pre-v0.4 consumers receive one reviewed bootstrap and later
  releases need no separate updater workflow.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` before FEAT-0004 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing `TEST-0001` through `TEST-0021` baseline |
| 2026-07-15 | `main` before FEAT-0004 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update.tests.ps1` | Pass: existing updater resolver/structure baseline |
| 2026-07-15 | `main` before FEAT-0004 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Pass: existing adapter/race baseline |
| 2026-07-15 | FEAT-0004 working tree with new assertions | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update.tests.ps1` | Expected red: `TEST-0026` rejects valid managed updater paths and accepts a missing expected path under the old protocol-only validator |
| 2026-07-15 | FEAT-0004 working tree with PAT-actor fixtures | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Expected red: old adapter trusts `github-actions[bot]`, does not resolve the PAT owner, and therefore rejects the new actor fixtures |
| 2026-07-15 | FEAT-0004 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Pass: adapter mutation, identity, exact-asset, race, lease, and compensation fixtures |
| 2026-07-15 | FEAT-0004 working tree | Windows PowerShell 5.1 | PowerShell AST parse plus `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: all PowerShell files parse and repository validation passes `TEST-0001` through `TEST-0026` |
