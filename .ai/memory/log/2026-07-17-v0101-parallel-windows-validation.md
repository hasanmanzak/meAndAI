# 2026-07-17 - v0.10.1 Parallel Windows Validation

## Canonical records

- Feature: [FEAT-0024](../../../docs/features/FEAT-0024-v0101-parallel-windows-validation/README.md)
- Tests: [TEST-0115 and TEST-0116](../../../docs/features/FEAT-0024-v0101-parallel-windows-validation/test-cases.md)
- Tracking and post-publication authority: [issue #65](https://github.com/hasanmanzak/meAndAI/issues/65)

## Durable facts

- The Linux full suite remains the canonical executable scenario-evidence run.
- Windows PowerShell 5.1 compatibility is one base job plus four quick-adoption
  shards behind the aggregate `Validate on windows-latest` check.
- Partial shards emit compatibility-only results and never claim the canonical
  `TEST-*` set.
- Quick-adoption tests build one protocol repository and exact release archive
  per process. Resets reuse that fingerprinted immutable fixture and create
  fresh mutable mock state; consumer worktrees and remotes are never shared.
- Hosted run 29568159757 is the pre-change baseline: the test step took 558
  seconds on Windows and 117 seconds on Linux. Timing is observational, not a
  pass/fail gate.
- Focused Windows PowerShell 5.1 shards passed in 11.5, 57.8, 246.8, and 39.7
  seconds. `FIND-0157` corrected the release-archive helper's script-scope
  dependency before completion; the fixture now exposes an explicit immutable
  archive path to every reset without sharing consumer state.
- The Windows base profile passed in 162.3 seconds, and the single final local
  full suite passed every canonical scenario through `TEST-0116` in 507.6
  seconds. Hosted runner durations remain external evidence owned by issue #65.

## Continuation

If delivery is still open, continue from issue #65 and the FEAT-0024 DoD. Do
not broaden this work into a general test scheduler, cross-runner Git cache, or
narrowing of Windows PowerShell 5.1 coverage.
