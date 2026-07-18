# 2026-07-17 - v0.9.5 Streamed Codex Activity and Cancellation Cleanup

## Scope

- [FEAT-0020](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/README.md)
  and [issue #57](https://github.com/hasanmanzak/meAndAI/issues/57) own this
  bounded correction.
- Replace the Windows PowerShell progress overlay with compact normal lines,
  present safe `codex exec --json` activity while it runs, and stop the owned
  process tree before cancellation cleanup.
- Keep the final-result file, repository validation, exact lease, maintainer
  merge, and [DEC-0013](../../../docs/decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md)
  publication recovery unchanged.

## Current evidence

- `TEST-0105` and `TEST-0106` are owned by
  [`tests/quick-adoption-streaming.tests.ps1`](../../../tests/quick-adoption-streaming.tests.ps1).
- The expected-red run proved the v0.9.4 overlay, buffered stdout, and weak
  exceptional-finalizer boundary. The focused implementation run passed on
  Windows PowerShell 5.1.
- The completed reviewed working tree passed the complete repository suite in
  517.2 seconds, including all 34 existing quick-adoption scenarios,
  `TEST-0105`, `TEST-0106`, and scenario-ownership gates.
- [Pull request #58](https://github.com/hasanmanzak/meAndAI/pull/58) owns the
  review branch and links the canonical feature, tests, decisions, and issue.
  Merge, immutable-release, and hosted-check evidence remain pending and belong
  in issue #57 when those facts exist.

## Continuation

Run one focused regression and one complete repository suite after version and
documentation alignment. Fix only a verified blocker, perform one fresh-diff
self-review and bounded scan, then publish v0.9.5. The retained affected-consumer
proposal recorded in [issue #57](https://github.com/hasanmanzak/meAndAI/issues/57) must continue to
target v0.9.2 when resumed with the newer launcher.
