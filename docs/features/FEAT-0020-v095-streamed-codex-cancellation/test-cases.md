# FEAT-0020 Test Scenarios

Implementation: [`tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1),
[`tests/capabilities/initial-adoption/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1),
[`tests/capabilities/initial-adoption/fixtures/Invoke-MockCodexEventProcess.ps1`](../../../tests/capabilities/initial-adoption/fixtures/Invoke-MockCodexEventProcess.ps1),
[`tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.ps1`](../../../tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.ps1),
and the complete repository suite.

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0105` <a name="test-0105"></a> | `FEAT-0020` / [BUG-0008](https://github.com/hasanmanzak/meAndAI/issues/57) | Exercise line-oriented phase presentation, `-NoProgress`, semantic `codex exec --json`, incremental JSONL agent/command/file/plan/lifecycle/error events, malformed/unknown presentation events, and a ready-looking stream with an invalid final result. | No native progress overlay is used; allowed observable activity appears while Codex runs, unsafe/raw fields are not rendered, presentation is bounded and suppressible, and only the final result plus repository validation can authorize publication. | UX / mocked-process integration | Passing | Quick-adoption fixture, captured information stream, and AST/source assertions |
| `TEST-0106` <a name="test-0106"></a> | `FEAT-0020` / [BUG-0008](https://github.com/hasanmanzak/meAndAI/issues/57) | Exercise timeout and Ctrl+C-equivalent pipeline cancellation while a mock process tree is active, then inspect child/descendant state, owned temporary roots, the remote proposal head, and existing push/marker recovery fixtures. | The active process tree is terminated before disposal and temporary cleanup; no pre-publication consumer result reaches the remote proposal; a later exact rerun remains safe; existing post-push recovery stays green. | Process lifecycle / cancellation / recovery | Passing | Extracted launcher-process seam, mock process tree, real-Git proposal fixture, and existing [TEST-0079](../FEAT-0013-v084-correction/test-cases.md#test-0079) recovery |

## Required coverage

- No active `Write-Progress` invocation or host-managed overlay.
- Normal line-oriented phase output, deduplication, bounded field length, and
  `-NoProgress` suppression.
- `--json` only for semantic execution and incremental JSONL stdout reads while
  the process is active.
- One parent-generated lowercase run identity returned by the first fixture
  event together with a bounded PID that remains live at consumption time; no
  bidirectional file handshake or cross-process timestamp-equality oracle.
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
| 2026-07-17 | v0.9.4 release asset | Windows PowerShell 5.1 / Codex CLI 0.144.4 | Affected-consumer quick-adoption run recorded in [issue #57](https://github.com/hasanmanzak/meAndAI/issues/57) | External red: native blue progress overlay collides with console history; semantic Codex activity is buffered; Ctrl+C child cleanup is not guaranteed by the process finalizer |
| 2026-07-17 | Working tree before implementation | Windows PowerShell 5.1 | `powershell -NoProfile -File tests/quick-adoption-streaming.tests.ps1` | Expected red: eight contract failures proved the absent line renderer, JSONL consumer, incremental reads, and exceptional process-tree cleanup |
| 2026-07-17 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -File tests/quick-adoption-streaming.tests.ps1` | Passed `TEST-0105` and `TEST-0106`; observable scenario result manifest emitted |
| 2026-07-17 | Reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Every executable suite and scenario owner passed; the repository gate correctly blocked only because FEAT-0020 was still marked `In Progress` during that pre-completion run |
| 2026-07-17 | Completed reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 517.2 seconds; all discovered suites, 34 existing quick-adoption scenarios, `TEST-0105`, `TEST-0106`, and scenario-ownership gates passed |
| 2026-07-27 | [Run `30244639416`](https://github.com/hasanmanzak/meAndAI/actions/runs/30244639416) and [run `30274245841`](https://github.com/hasanmanzak/meAndAI/actions/runs/30274245841) | GitHub Actions / Windows PowerShell 5.1 | Full protected Windows profile on two unrelated candidate heads | Recurrence red: both runs rendered the first JSONL event, but the child did not observe the test-only file acknowledgment within five seconds and emitted no later events. Ubuntu passed both heads, isolating a nondeterministic cross-process fixture handshake rather than a production streaming regression. |
| 2026-07-27 | [`120b04f6d724a1c01971d59332f3c54b2ada789c`](https://github.com/hasanmanzak/meAndAI/commit/120b04f6d724a1c01971d59332f3c54b2ada789c) | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`; `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1` | First correction passed in 9.7 / 11.3 seconds. It removed the acknowledgment file and used exact fixture PID plus process-start ticks during the existing five-second observation window. All later presentation and [TEST-0106](#test-0106) cancellation assertions remained unchanged. |
| 2026-07-27 | [`aa8c9f479fe902972fcd4b103e0e2353dc6ba5e0`](https://github.com/hasanmanzak/meAndAI/commit/aa8c9f479fe902972fcd4b103e0e2353dc6ba5e0) / [run `30278228996`](https://github.com/hasanmanzak/meAndAI/actions/runs/30278228996) | GitHub Actions / Ubuntu | Full protected Ubuntu profile | Recurrence red: only the aggregate `TEST-0105` live-consumption assertion reported a failure; no separate required-event or safe-presentation assertion reported a failure. The hosted log did not expose the failed aggregate operand. Code-path diagnosis identified exact process-start-tick equality as the remaining platform-sensitive correlation discriminator. |
| 2026-07-27 | [`345647fbd2affaba787b3b1db3a8c295a9eae49d`](https://github.com/hasanmanzak/meAndAI/commit/345647fbd2affaba787b3b1db3a8c295a9eae49d) | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`; `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1` | Passed in 10.1 / 12.8 seconds; an independent review run repeated the pass in 9.5 / 11.8 seconds with the same canonical TEST-0105/TEST-0106 manifest. The parent supplies one exact lowercase 32-hex run identity; the first fixture event must return it together with a bounded live PID. Exit zero, every expected event, safe presentation, final-result authority, and `TEST-0106` cancellation checks remain mandatory. |
| 2026-07-28 | [Run `30307649690`](https://github.com/hasanmanzak/meAndAI/actions/runs/30307649690) / exact head [`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976) | GitHub Actions / Windows PowerShell 5.1 | Full protected Windows profile | Expected red for [FIND-0362](../FEAT-0059-csharp-operational-foundation/README.md#find-0362): all JSONL events and separate presentation assertions passed, but the callback's independent PID reopen did not prove liveness and only the aggregate live-consumption assertion failed. The unrelated C# step passed 31 of 31; rerunning the unchanged head is not accepted as correction. |
| 2026-07-28 | [FIND-0362](../FEAT-0059-csharp-operational-foundation/README.md#find-0362) reviewed working tree | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1`; `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-streaming.tests.ps1` | Tests-first red failed only TEST-0105 when the callback required the absent owned-process observation. The bounded implementation then passed TEST-0105 and TEST-0106 in 9.7 / 11.7 seconds by supplying a `{ ProcessId, IsRunning }` value snapshot from the already-owned process for each consumed line; post-exit drain reports `IsRunning=false`. Exact committed-tree and hosted confirmation remain pending. |
