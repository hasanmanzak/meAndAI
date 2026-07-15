# FEAT-0005 Test Scenarios

Planned test implementation:
`tests/capabilities-bootstrap.tests.ps1`,
`tests/capabilities-bootstrap-adapter.tests.ps1`, and the existing
repository/updater suites.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0027` | `SUBF-0009` | Run the seed workflow with both local updater files present, both absent, or only one present. | Complete local installation delegates to the local updater; absence or partial installation uses the exact source-pinned bootstrap adapter. | Structural / boundary | Passed | Workflow and routing assertions |
| `TEST-0028` | `SUBF-0009` | Bootstrap a consumer whose only adoption target is the exact seed workflow. | One draft proposal stages the exact v0.5.0 gitlink, core adoption assets, and manifest with an expected-absent branch lease. | Integration | Passed | Bootstrap adapter fixture |
| `TEST-0029` | `SUBF-0009` | Bootstrap a populated consumer with arbitrary application files but no adoption-target collisions. | The same deterministic bootstrap proposal is created and every unrelated path remains unchanged. | Integration / regression | Passed | Real-Git adapter fixture |
| `TEST-0030` | `SUBF-0010` | Present one or more existing consumer-owned adoption targets, including case-sensitive and partial-adoption boundaries. | A manifest-only draft proposal records the exact collisions; no colliding target or unrelated path is staged. | Negative / boundary | Passed | Pure planner and adapter fixtures |
| `TEST-0031` | `SUBF-0010` | Re-run with a pending adoption PR, an orphan deterministic branch, an existing manifest, or an unexpected seed workflow blob. | No duplicate, reset, cleanup, or overwrite occurs; pending work is retained and ambiguous state blocks manual review. | Recovery / concurrency | Passed | Planner and adapter fixtures |
| `TEST-0032` | `SUBF-0010` | Complete adoption, inspect the manifest tasks and credential contract, then run the existing updater suite. | The manifest requires agent completion/removal, labels remain outside workflow authority, and adopted consumers preserve v0.4 updater behavior. | Regression / structural | Passed | Repository and updater suites |

## Required coverage

- Success: workflow-only seed produces a deterministic collision-free adoption
  proposal from an immutable source tag.
- Populated repository: arbitrary app content does not imply collision, while
  exact consumer-owned target conflicts require semantic review.
- Supply chain: source bootstrap execution is pinned and target tag identity is
  verified.
- Integrity: collision and staged-path sets are exact and case-sensitive.
- Recovery: deterministic branch creation uses an expected-absent lease and
  existing branch/PR state is never overwritten.
- Handoff: no AI service is called; the manifest carries required agent tasks
  and prevents a completion claim until removed.
- Regression: existing local updater routing, supersession, authentication,
  and self-update tests remain green.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.4.0` before FEAT-0005 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing `TEST-0001` through `TEST-0026` baseline |
| 2026-07-15 | FEAT-0005 test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities-bootstrap.tests.ps1` | Expected red: lifecycle module/adapter, seed routing, adoption contract, and protocol contract are absent |
| 2026-07-15 | FEAT-0005 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities-bootstrap.tests.ps1` | Pass: `TEST-0027` through `TEST-0032` |
| 2026-07-15 | FEAT-0005 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update.tests.ps1` | Pass: existing updater `TEST-0009` through `TEST-0017` and `TEST-0021` through `TEST-0026` |
| 2026-07-15 | FEAT-0005 bounded convergence working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Initial full run found `FIND-0052`: stale current version in the repository-reference adapter |
| 2026-07-15 | FEAT-0005 confirmation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: complete `TEST-0001` through `TEST-0032` suite after `FIND-0052` remediation |
