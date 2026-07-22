# FEAT-0038 Test Scenarios

| ID | Scenario | Expected result | Level | Status | Canonical owner |
| --- | --- | --- | --- | --- | --- |
| `TEST-0155` | Exercise project-neutral ordinary, schema-2, and legacy installing-update finalization with API `2026-03-10` pull-request payloads that omit `merge_commit_sha`. Supply one exact `merged` issue event after 100 unrelated records, rerun an already-finalized result, and vary the event set to zero, duplicate, uppercase/malformed commit identity, and a valid commit not contained in the current default head. | The shared helper reads the complete paginated event collection, selects exactly one canonical merged-event `commit_id`, and preserves exact branch-first/issue-last convergence and idempotency. Every absent, ambiguous, malformed, or uncontained case fails before mutation. Ordinary pull requests perform no event lookup, and the API-2026 updater has no raw dependency on the removed PR field. | Capability integration / API compatibility / pagination / recovery / negative / idempotency / structural regression | Locally complete | `tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` |
| `TEST-0156` | Run the target-bound local launcher against isolated exact-base and exact-release clones while a corrected target adapter exposes merged-branch recovery and current-planning modes. Exercise success and adapter/location-stack interruption after recovery but before current planning. | The launcher obtains the authenticated local `gh` token, binds it with `GH_HOST=github.com` only for the isolated operation, invokes exact retained-merge recovery before current planning, restores all prior environment values even when location restoration fails, removes its temporary roots, and preserves the maintainer checkout's HEAD, branch, and exact porcelain status. | Capability orchestration / recovery ordering / credential lifetime / interruption / checkout preservation | Complete | `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` |

## Required coverage

- API-2026 pull-request payload with the removed property absent.
- Complete paginated issue-event collection with the merged event beyond the
  first 100 records.
- Ordinary/schema-2 finalization and bounded legacy tracking repair.
- Exact event commit containment in the current default head.
- Zero, duplicate, wrong-case, malformed, and uncontained evidence negatives.
- No branch, issue, label, comment, or pull-request mutation after rejection.
- Exact idempotent rerun and unmanaged pull-request no-op behavior.
- Structural guard against reintroducing the removed field into the API-2026
  updater.
- Exact target-adapter merged-branch recovery before current-update planning.
- Process-scoped local `gh` token/host binding with exact environment restoration.
- Maintainer-checkout identity/status and temporary-root preservation after success or an
  interrupted current-planning call.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-22 | Immutable baseline `6de31e0` / v0.12.6 | GitHub REST API `2026-03-10` and local Windows PowerShell 5.1 | Live PR response plus exact issue-event inspection | Live response omits `merge_commit_sha`; its exact pull-request event stream contains one `merged` event with a canonical `commit_id`. |
| 2026-07-22 | FEAT-0038 test-first working tree before production correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Expected red: both managed finalizer paths terminate on the absent PR property, and the structural guard reports the remaining API-2026 dependency. |
| 2026-07-22 | Corrected local working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Final candidate run passed in 24.3 seconds with canonical `TEST-0155` evidence, including the unmanaged no-event-read assertion. |
| 2026-07-22 | TEST-0156 test-first working tree before launcher correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard CurrentLauncherRecovery` | Expected red: six recovery-order/token contracts were absent before production correction. |
| 2026-07-22 | Corrected local working tree before final cleanup hardening | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard CurrentLauncherRecovery` | Passed in 5.9 seconds with ordered recovery/current calls, process-token restoration, adapter interruption cleanup, and maintainer-checkout identity/status preservation. |
| 2026-07-22 | Final corrected candidate tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard All` | Passed in 1030.7 seconds and emitted canonical `MEANDAI_SCENARIO_RESULTS` containing `TEST-0156`, including GitHub host binding and location-stack failure restoration. |
