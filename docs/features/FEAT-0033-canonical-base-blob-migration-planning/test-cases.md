# FEAT-0033 Test Scenarios

Test implementation: capability-owned consumer-update coverage under
[`tests/capabilities/consumer-update`](../../../tests/capabilities/consumer-update).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0141` | `FEAT-0033` | In isolated project-neutral repositories, commit LF migration input and ledger blobs, create a fresh clean checkout with `core.autocrlf=true` and no consumer `.gitattributes`, and execute explicit cases for filtered worktree bytes, true worktree/input/ledger drift, exact plan application, and a second planning run. | Planning uses the captured base Git blobs and produces the exact plan without false drift; binary bytes and ledger identity remain exact; genuine clean-filtered worktree and committed-drift cases fail closed; the applied rerun is an exact no-op; no remote mutation or source-version/consumer-name branch is introduced. | Integration / regression / Windows compatibility / negative / idempotency | Passed locally; hosted PR gate pending | `tests/capabilities/consumer-update/protocol-update.tests.ps1` with a capability-local isolated fixture |

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
| 2026-07-19 | working tree after bounded self-review | Windows PowerShell 5.1, unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/protocol-update.tests.ps1` | Passed all 27 owner scenarios, including the `FIND-0173` clean-filtered worktree drift guard, in 56.2 seconds |
| 2026-07-19 | working tree after final bounded scan | Windows PowerShell 5.1 | `tests/protocol.tests.ps1 -StructureOnly`; parse every tracked PowerShell script; `git diff --check`; canonical coupling, live-pin, and planner-boundary searches | Structure and discovery passed; every script parsed; the diff was clean; no named-consumer coupling or stale live `v0.12.0` pin remained; local planning uses the two canonical-base helpers while the remote planner remains on repository blob bytes |
