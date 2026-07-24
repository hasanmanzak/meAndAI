# FEAT-0033 Test Scenarios

Test implementation: capability-owned consumer-update coverage under
[`tests/capabilities/consumer-update`](../../../tests/capabilities/consumer-update).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0141` <a name="test-0141"></a> | `FEAT-0033` | In isolated project-neutral repositories, commit LF migration input and ledger blobs, create a fresh clean checkout with `core.autocrlf=true` and no consumer `.gitattributes`, and execute explicit cases for filtered worktree bytes, true worktree/input/ledger drift, exact plan application, and a second planning run. | Planning uses the captured base Git blobs and produces the exact plan without false drift; binary bytes and ledger identity remain exact; genuine clean-filtered worktree and committed-drift cases fail closed; the applied rerun is an exact no-op; no remote mutation or source-version/consumer-name branch is introduced. | Integration / regression / Windows compatibility / negative / idempotency | Passed locally and in hosted PR validation | `tests/capabilities/consumer-update/protocol-update.tests.ps1` with a capability-local isolated fixture |

## Required coverage

- Exact captured base commit and regular Git-blob identity.
- Binary-safe blob reads with no text decoding or shell redirection.
- `core.autocrlf=true`, no consumer `.gitattributes`, committed LF bytes, and a
  fresh clean checkout whose worktree may contain CRLF.
- Present migration ledger and migration input paths.
- No false drift for filtered worktree bytes.
- Rejection of genuine semantic worktree drift after Git clean filters.
- Distinct committed migration-input and ledger drift rejection.
- Exact plan application and idempotent second planning run.
- Unchanged staged/result and remote/default-head semantics.
- Project-neutral names and capability-local mutable fixture cleanup.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-19 | working tree before production correction | Windows PowerShell 5.1, unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1` | Expected red: clean CRLF checkout supplied worktree ledger bytes and failed with `Consumer migration ledger must use LF line endings.` |
| 2026-07-19 | working tree after production correction | Windows PowerShell 5.1, unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1` | Passed all declared adapter scenarios, including `TEST-0141`, in 52.2 seconds |
| 2026-07-19 | working tree after bounded self-review | Windows PowerShell 5.1, unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/protocol-update.tests.ps1` | Passed all 27 owner scenarios, including the [FIND-0173](README.md#find-0173) clean-filtered worktree drift guard, in 56.2 seconds |
| 2026-07-19 | working tree after final bounded scan | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly`; parse every tracked PowerShell script; `git diff --check`; canonical coupling, live-pin, and planner-boundary searches | Structure and discovery passed; every script parsed; the diff was clean; no named-consumer coupling or stale live `v0.12.0` pin remained; local planning uses the two canonical-base helpers while the remote planner remains on repository blob bytes |
| 2026-07-19 | [`3eff1b0048bbc3371c4a028a198717598d1bff66`](https://github.com/hasanmanzak/meAndAI/commit/3eff1b0048bbc3371c4a028a198717598d1bff66) | GitHub-hosted Ubuntu and Windows runners | [PR run 29686946514](https://github.com/hasanmanzak/meAndAI/actions/runs/29686946514) | Ubuntu validation passed in 7m41s; Windows PowerShell 5.1 validation passed in 29m37s; GitGuardian passed in 2s; pre-release publication verification was correctly skipped |
