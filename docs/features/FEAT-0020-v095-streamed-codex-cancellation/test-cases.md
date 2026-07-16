# FEAT-0020 Test Scenarios

Implementation: [`tests/quick-adoption-streaming.tests.ps1`](../../../tests/quick-adoption-streaming.tests.ps1),
[`tests/quick-adoption.tests.ps1`](../../../tests/quick-adoption.tests.ps1),
[`tests/fixtures/Invoke-MockCodex.ps1`](../../../tests/fixtures/Invoke-MockCodex.ps1),
and the complete repository suite.

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0105` | `FEAT-0020` / `BUG-0008` | Exercise line-oriented phase presentation, `-NoProgress`, semantic `codex exec --json`, incremental JSONL agent/command/file/plan/lifecycle/error events, malformed/unknown presentation events, and a ready-looking stream with an invalid final result. | No native progress overlay is used; allowed observable activity appears while Codex runs, unsafe/raw fields are not rendered, presentation is bounded and suppressible, and only the final result plus repository validation can authorize publication. | UX / mocked-process integration | Passing | Quick-adoption fixture, captured information stream, and AST/source assertions |
| `TEST-0106` | `FEAT-0020` / `BUG-0008` | Exercise timeout and Ctrl+C-equivalent pipeline cancellation while a mock process tree is active, then inspect child/descendant state, owned temporary roots, the remote proposal head, and existing push/marker recovery fixtures. | The active process tree is terminated before disposal and temporary cleanup; no pre-publication consumer result reaches the remote proposal; a later exact rerun remains safe; existing post-push recovery stays green. | Process lifecycle / cancellation / recovery | Passing | Extracted launcher-process seam, mock process tree, real-Git proposal fixture, and existing TEST-0079 recovery |

## Required coverage

- No active `Write-Progress` invocation or host-managed overlay.
- Normal line-oriented phase output, deduplication, bounded field length, and
  `-NoProgress` suppression.
- `--json` only for semantic execution and incremental JSONL stdout reads while
  the process is active.
- User-facing agent messages plus generic command, file, plan, tool, reasoning,
  lifecycle, error, and bounded heartbeat activity.
- No raw reasoning, raw command output, credential value, or persistent event
  transcript.
- Final-result-file authority under ready-looking, malformed, and unknown
  streamed events.
- Timeout and exceptional-finalizer child-tree termination before process
  disposal and owned temporary-root cleanup.
- Remote proposal immutability before validated publication and existing exact
  recovery after an interrupted push/marker transition.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | v0.9.4 release asset | Windows PowerShell 5.1 / Codex CLI 0.144.4 | Derdini quick-adoption run linked by [issue #57](https://github.com/hasanmanzak/meAndAI/issues/57) | External red: native blue progress overlay collides with console history; semantic Codex activity is buffered; Ctrl+C child cleanup is not guaranteed by the process finalizer |
| 2026-07-17 | Working tree before implementation | Windows PowerShell 5.1 | `powershell -NoProfile -File tests/quick-adoption-streaming.tests.ps1` | Expected red: eight contract failures proved the absent line renderer, JSONL consumer, incremental reads, and exceptional process-tree cleanup |
| 2026-07-17 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -File tests/quick-adoption-streaming.tests.ps1` | Passed `TEST-0105` and `TEST-0106`; observable scenario result manifest emitted |
| 2026-07-17 | Reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Every executable suite and scenario owner passed; the repository gate correctly blocked only because FEAT-0020 was still marked `In Progress` during that pre-completion run |
| 2026-07-17 | Completed reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 517.2 seconds; all discovered suites, 34 existing quick-adoption scenarios, `TEST-0105`, `TEST-0106`, and scenario-ownership gates passed |
