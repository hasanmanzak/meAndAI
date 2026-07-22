# FEAT-0038 Test Scenarios

| ID | Scenario | Expected result | Level | Status | Canonical owner |
| --- | --- | --- | --- | --- | --- |
| `TEST-0155` | Exercise project-neutral ordinary, schema-2, and legacy installing-update finalization with API `2026-03-10` pull-request payloads that omit `merge_commit_sha`. Supply one exact `merged` issue event after 100 unrelated records, rerun an already-finalized result, and vary the event set to zero, duplicate, uppercase/malformed commit identity, and a valid commit not contained in the current default head. | The shared helper reads the complete paginated event collection, selects exactly one canonical merged-event `commit_id`, and preserves exact branch-first/issue-last convergence and idempotency. Every absent, ambiguous, malformed, or uncontained case fails before mutation. Ordinary pull requests perform no event lookup, and the API-2026 updater has no raw dependency on the removed PR field. | Capability integration / API compatibility / pagination / recovery / negative / idempotency / structural regression | Locally complete | `tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` |

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

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-22 | Immutable baseline `6de31e0` / v0.12.6 | GitHub REST API `2026-03-10` and local Windows PowerShell 5.1 | Live PR response plus exact issue-event inspection | Live response omits `merge_commit_sha`; its exact pull-request event stream contains one `merged` event with a canonical `commit_id`. |
| 2026-07-22 | FEAT-0038 test-first working tree before production correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Expected red: both managed finalizer paths terminate on the absent PR property, and the structural guard reports the remaining API-2026 dependency. |
| 2026-07-22 | Corrected local working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Final candidate run passed in 24.3 seconds with canonical `TEST-0155` evidence, including the unmanaged no-event-read assertion. |
