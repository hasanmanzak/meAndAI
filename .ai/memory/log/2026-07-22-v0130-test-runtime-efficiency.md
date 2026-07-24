# 2026-07-22 - v0.13.0 Test Runtime Efficiency

## Scope and authority

- Feature: [FEAT-0039](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/README.md)
- Tracking authority: [issue #95](https://github.com/hasanmanzak/meAndAI/issues/95)
- Task: [TASK-0001](https://github.com/hasanmanzak/meAndAI/issues/95)
- Test authority: [TEST-0157](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md), [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md), [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md), and [TEST-0160](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md)
- Measurement base: immutable v0.12.7 commit
  `6b01299cfe484c900944b7435d4fef43b11fc38d`

## Implemented candidate

- The append-only `test-runtime-efficiency` semantic capability makes
  reuse-first expensive setup and reviewed operation budgets common protocol
  requirements without changing the immutable `test-architecture` definition.
- The shared test runtime owns only budget import, route/runtime resolution,
  deterministic observation formatting, and parent-authoritative parsing.
  Fixture construction remains with its actual capability owner.
- Quick-adoption builds three repeated immutable seed families once per suite
  process and gives every request an isolated copied repository and remote.
  Shape-defining security, history, link/reparse, hook, race, and no-head cases
  remain fresh.
- Capabilities-bootstrap builds its consumer, protocol, and empty-remote
  baselines once and retains per-case isolated publication. Two pure graph
  identity drifts no longer reprovision process and acquisition boundaries.
- Parent validation requires exactly one applicable sorted observation before
  canonical scenario evidence; missing, malformed, duplicate, unknown-route,
  bypassed, or over-budget evidence fails closed.

## Current evidence and continuation

- [TEST-0157](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md), [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md), and [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md) pass; the local/structural portion of
  [TEST-0160](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md) is green. Candidate hosted execution remains external delivery
  evidence.
- The Windows PowerShell 5.1 Full route passes in 1,340.2 seconds. Quick-
  adoption `All` takes 776.2 seconds with init 11 versus exact-base 47;
  bootstrap `All` takes 267.6 seconds with init 3, clone 2, bundle 2, push 36,
  child process 4, and graph acquisition 3; instruction graph takes 135.9
  seconds.
- The final `WindowsNative` rerun passes in 341.0 seconds, including a 329.2-
  second quick-adoption native route.
- PowerShell AST parsing, `StructureOnly`, catalog/review, runtime-contract,
  and diff-whitespace checks pass at the focused gates recorded by [FEAT-0039](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/README.md).
- The first review found incomplete bypass inventory, cleanup leakage, mode-
  blind fingerprints, and an under-bound input digest. Test-first remediation
  now ratchets all owner-source operation and cleanup call sites, verifies no
  cleanup survivor, and binds owner source plus canonical committed bytes and
  modes. A final independent review then exposed a recovery-root survivor
  bypass, known-owner/unknown-route bypass, and dynamically assembled direct
  Git operation missed by inventory. All three have expected-red coverage,
  fail-closed remediation, and a no-blocker confirmation review.
- Initial hosted run 29919072917 failed before expensive suites under
  PowerShell 7: `Write-Output -NoEnumerate` wrapped a scalar data-file property
  in `List<object>`. Official portable PowerShell 7.6.4 reproduced the expected
  red locally. The property accessor now returns scalars directly and preserves
  only arrays with unary comma; focused runtime and `StructureOnly` pass under
  PowerShell 7.6.4 and Windows PowerShell 5.1. Corrected hosted execution, pull-
  request/release delivery, and post-publication evidence remain pending.
- Corrected hosted run 29919821489 reached every expensive Ubuntu owner:
  quick-adoption 188.0 seconds, bootstrap 62.2 seconds, and instruction graph
  70.7 seconds. It then exposed [TEST-0138](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) because inline operation enforcement
  grew the stable root runner beyond 180 lines. The limit was not raised;
  enforcement moved into one shared-runtime assertion and the root returned to
  167 lines. Focused [TEST-0138](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) and runtime contracts pass under PS5 and PS7.
- The same run's Windows step reached quick-adoption 821.5 seconds, bootstrap
  236.0 seconds, and instruction graph 129.8 seconds before the identical final
  [TEST-0138](../../../docs/features/FEAT-0032-general-capability-test-architecture/test-cases.md) failure. Approximate test-step totals were Windows 22:08 and Ubuntu
  6:51. Bootstrap improved, but total Windows, quick-adoption, and graph time did
  not; v0.13.0 therefore makes no wall-clock improvement claim and [TASK-0002](https://github.com/hasanmanzak/meAndAI/issues/98)
  owns the measured residual regression.
- The 2/3-minute soft goals were missed without violating a correctness gate.
  Residual wall-clock work is owned by
  [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).
