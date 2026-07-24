# FEAT-0044 Test Scenarios

Test implementations:
[capability-review.tests.ps1](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1)
and
[managed-merge-finalization.tests.ps1](../../../tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0169` | [SUBF-0083](README.md) | Exercise a slash-bearing capability-review branch through inventory, exact branch-only interrupted recovery, manifest update, finalization, lease deletion, post-delete verification, drift rejection, and completed rerun. Reject any fixture call that encodes `/` as `%2F`. | Every Git ref request preserves literal path separators, branch-only recovery creates no second ref and resumes the remaining operations, exact ref/OID and lease gates remain strict, issue closure follows branch convergence, and rerun is a no-op. | Integration / GitHub API / recovery / idempotency | Automated; passed | Existing capability-review production fixture |
| `TEST-0170` | [SUBF-0084](README.md) | Inspect canonical consumer event routing for a merged managed PR, default-branch and reserved automation-branch pushes, schedule, and dispatch. | The PR merge alone enters post-merge finalization/discovery; no push event is admitted; schedule/manual recovery remains; shared concurrency cannot be churned by merge-caused or self-created pushes. | Workflow contract / runner efficiency / recovery | Automated; passed | Existing managed-finalization suite |

## Required coverage

- Literal slash-delimited Git ref routes with segment-wise escaping.
- Exact returned ref/OID validation and moved-ref rejection.
- Branch-only interrupted creation, no duplicate ref POST, and deterministic
  continuation.
- Expected-head branch deletion, verified absence, issue-last closure, and
  completed-rerun idempotency.
- Managed merged-PR lifecycle ownership, complete push exclusion,
  schedule/manual recovery preservation, and non-canceling concurrency.
- Project-neutral fixtures and no new hosted job, test suite, or credential.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | Immutable v0.13.4 consumer runtime | GitHub Actions / Derdini | [Run 30011058590](https://github.com/hasanmanzak/Derdini/actions/runs/30011058590) | Finalizer succeeded, then capability-review ref lookup used `%2F`, returned 404, and retained the review branch |
| 2026-07-23 | Immutable v0.13.4 consumer runtime | GitHub Actions / Derdini | [Runs 30011059451 and 30011271796](https://github.com/hasanmanzak/Derdini/actions) | Automation-branch push acquired workflow concurrency and displaced the pending exact pull-request event |
| 2026-07-23 | v0.13.4 test-first tree | Windows PowerShell 5.1 | Focused capability-review owner | Failed as intended: `%2F` branch-separator endpoint rejected |
| 2026-07-23 | v0.13.4 test-first tree | Windows PowerShell 5.1 | Focused managed-finalization owner | Failed as intended: reserved automation event filter absent and proposal still owned default push |
| 2026-07-23 | Corrected v0.13.5 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Passed in 14.5 seconds; TEST-0169 reported by the canonical owner |
| 2026-07-23 | First corrected v0.13.5 tree | Windows PowerShell 5.1 | Focused managed-finalization owner | Review-refined TEST-0170 failed as intended because recovery-only push still created a second hosted run |
| 2026-07-23 | Final corrected v0.13.5 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Passed in 18.3 seconds; TEST-0170 reported by the canonical owner after complete push exclusion |
| 2026-07-23 | Reviewed v0.13.5 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 10.0 seconds for every discovered structural contract |
