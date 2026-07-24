# FEAT-0034 Test Scenarios

Test implementation: capability-owned coverage under
[`tests/capabilities/consumer-update`](../../../tests/capabilities/consumer-update)
and
[`tests/capabilities/workflow-efficiency`](../../../tests/capabilities/workflow-efficiency).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0142` <a name="test-0142"></a> | [SUBF-0062](README.md#subf-0062) | Bind an inherited outer summary sentinel, execute successful, idempotent/no-op, and rejected managed-merge finalization scenarios, and inspect each invocation's isolated summary plus final environment state. | A successful finalization emits exactly its expected line only to its invocation file; no-op/error paths emit none; the inherited sentinel and environment value are unchanged; temp files are removed even on error. | Integration / regression / isolation / negative | Passed locally | `tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` |
| `TEST-0143` <a name="test-0143"></a> | [SUBF-0063](README.md#subf-0063) | Resolve main-push validation from isolated real Git graphs and mocked paginated GitHub evidence for exact PR merge, exact merge-group, pull-request events with an empty `before` field, direct/squash/rebase/forced pushes, parent/tree/PR/head mismatches, duplicate/missing/failed/canceled jobs/runs, and API/auth/malformed failures; inspect workflow and protocol contracts. | Only exact already-green tree evidence returns `ReuseExactValidatedTree`; every other case returns `Full` without a parameter-binding failure; the workflow retains its triggers, stable jobs, fail-safe short/full conditions, PR-only cancellation, and publication isolation; the protocol forbids evidence-only candidate commits while preserving external cross-links. | Integration / regression / workflow structure / negative / fail-closed | Passed locally | `tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1` |

## Required coverage

- Per-invocation summary ownership, exact success text, zero no-op/error text,
  environment restoration, inherited-sentinel integrity, and cleanup.
- Exact lowercase commit identities, push before/after parents, tree identity,
  one merged PR, exact PR head, current workflow identity, exact stable job
  names, successful conclusions, and pagination.
- Exact successful merge-group evidence for the pushed SHA.
- Direct, squash, rebase, forced, wrong-parent, wrong-tree, wrong-base,
  wrong-head, duplicate, missing, failed, canceled, and API-error negatives.
- Empty provider event fields must reach the fail-closed `Full` route instead of
  failing during PowerShell parameter binding.
- Retained `main` trigger, stable Linux/Windows jobs, PR-only cancellation,
  fail-safe `Full` default, and isolated post-publication job.
- Stable external issue/PR evidence authority without metadata-only commits.
- Project-neutral fixtures and deterministic recursive discovery.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-19 | [`c1e70901749d7c34a747b765134f668232b9d2ca`](https://github.com/hasanmanzak/meAndAI/commit/c1e70901749d7c34a747b765134f668232b9d2ca) | GitHub-hosted Ubuntu and Windows | [main run 29688880377](https://github.com/hasanmanzak/meAndAI/actions/runs/29688880377) | Green baseline; exact merge tree repeated the full Linux suite for 7m40s and full Windows suite for about 30m, establishing [BUG-0016](https://github.com/hasanmanzak/meAndAI/issues/85) |
| 2026-07-19 | working tree before correction | GitHub-hosted job-summary evidence | [PR run 29686946514](https://github.com/hasanmanzak/meAndAI/actions/runs/29686946514) | Synthetic finalization identities escaped the fixture into the real summary, establishing [BUG-0015](https://github.com/hasanmanzak/meAndAI/issues/85) |
| 2026-07-19 | working tree before [SUBF-0062](README.md#subf-0062) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Expected red: eight synthetic finalization lines reached the inherited outer summary and no invocation-owned output was captured |
| 2026-07-19 | working tree before [SUBF-0063](README.md#subf-0063) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1` | Expected red: the route module and exact-tree workflow/protocol contracts were absent |
| 2026-07-19 | working tree after correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1` | Green: [TEST-0108](../FEAT-0022-v097-managed-merge-finalization/test-cases.md#test-0108), [TEST-0109](../FEAT-0022-v097-managed-merge-finalization/test-cases.md#test-0109), [TEST-0110](../FEAT-0022-v097-managed-merge-finalization/test-cases.md#test-0110), [TEST-0112](../FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md#test-0112), and `TEST-0142` passed with isolated summary evidence |
| 2026-07-19 | working tree after correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1` | Green: `TEST-0143` passed exact reuse, fail-closed negatives, workflow structure, and multi-page fake-CLI evidence |
| 2026-07-19 | historical [PR #84](https://github.com/hasanmanzak/meAndAI/pull/84) / current resolver | Windows PowerShell 5.1, read-only live GitHub evidence | `Resolve-MeAndAIMainValidationRoute` for merge [`c1e70901749d7c34a747b765134f668232b9d2ca`](https://github.com/hasanmanzak/meAndAI/commit/c1e70901749d7c34a747b765134f668232b9d2ca) | Returned `ReuseExactValidatedTree`; exact base, head, merge tree, current workflow run, and both stable jobs matched |
| 2026-07-19 | final working tree | Windows PowerShell 5.1 outside the restricted workspace sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Green in 1609.5 seconds: all recursively discovered suites passed, including `TEST-0142` and `TEST-0143`; the restricted-sandbox attempt was invalid because Git for Windows could not create local clone signal pipes (`Win32 error 5`) |
| 2026-07-19 | candidate [`0e44135584c14145b50180f28874680e4309ba07`](https://github.com/hasanmanzak/meAndAI/commit/0e44135584c14145b50180f28874680e4309ba07) | GitHub-hosted Ubuntu and Windows | [PR #86](https://github.com/hasanmanzak/meAndAI/pull/86) [run 29692117634](https://github.com/hasanmanzak/meAndAI/actions/runs/29692117634) | Expected red for [FIND-0175](README.md#find-0175): a pull-request event supplied an empty `before` field and both jobs failed at PowerShell parameter binding before selecting `Full` |
