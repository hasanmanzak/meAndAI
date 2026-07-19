# FEAT-0022 Test Scenarios

Test implementation: [managed merge finalization fixture](../../../tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0108` | `SUBF-0038` | Finalize an exact completed adoption merge, then repeat through recovery after its branch is absent and issue is closed. | The exact branch is deleted once with its expected-head lease; the canonical issue receives one evidence marker, loses transient status labels, closes as completed, and the rerun is mutation-idempotent. | Integration / state transition | Pass | Mock GitHub CLI and Git fixture |
| `TEST-0109` | `SUBF-0038` | Finalize an exact managed protocol update with one same-repository tracking issue and inspect workflow event/manual routing. | The tracking-linked issue and exact update branch converge; scheduled/ordinary dispatch still runs update discovery, merged events and explicit recovery run only finalization, and supersession behavior is unchanged. | Integration / structural | Pass | Mock GitHub CLI, Git fixture, and workflow assertions |
| `TEST-0110` | `SUBF-0038` | Present a normal PR and vary merge state, repository/base/head identity, branch/target, marker count/schema/order, changed paths, adoption/update issue ownership, and live-ref movement. | A normal PR is a no-op; every managed ambiguity or race blocks before branch deletion or issue mutation. | Negative / race / ownership | Pass | Parameterized mock GitHub CLI and Git fixture |

## Required coverage

- Successful adoption and update finalization.
- First-line canonical marker and same-repository identity.
- Exact issue ownership or canonical tracking-link identity.
- Exact-head branch deletion lease and post-delete absence.
- Idempotent absent-branch and already-closed-issue recovery.
- Normal, unmerged, cross-repository, wrong-base, no-longer-contained,
  malformed/duplicate marker or tracking line, preclosed-without-evidence,
  unexpected-path, missing/multiple issue, reused-branch, and moved-ref rejection.
- Workflow trigger, permission, routing, timeout, and existing updater regression.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | Expected-red working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/managed-merge-finalization.tests.ps1` | Expected failure: adapter parameter and workflow route absent; 15 focused assertions failed before production implementation. |
| 2026-07-17 | Final working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/managed-merge-finalization.tests.ps1` | Pass: `TEST-0108`, `TEST-0109`, and `TEST-0110`. |
| 2026-07-17 | Final working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass in 543.1 seconds: all discovered suites and scenario evidence, including quick adoption and `TEST-0108` through `TEST-0110`. |
