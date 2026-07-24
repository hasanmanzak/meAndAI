# FEAT-0005 Test Scenarios

Implementations:
`tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1`,
`tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1`, and the existing
repository/updater suites.

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0027` | [SUBF-0009](README.md) | Run the seed workflow with both local updater files present, both absent, or only one present. | Complete local installation delegates to the local updater; absence or partial installation uses the exact source-pinned bootstrap adapter. | Structural / boundary | Passed | Workflow and routing assertions |
| `TEST-0028` | [SUBF-0009](README.md) | Bootstrap a consumer whose only adoption target is the exact seed workflow. | One draft proposal stages the exact v0.5.0 gitlink, core adoption assets, and manifest with an expected-absent branch lease. | Integration | Passed | Bootstrap adapter fixture |
| `TEST-0029` | [SUBF-0009](README.md) | Bootstrap a populated consumer with arbitrary application files but no adoption-target collisions. | The same deterministic bootstrap proposal is created and every unrelated path remains unchanged. | Integration / regression | Passed | Real-Git adapter fixture |
| `TEST-0030` | [SUBF-0010](README.md) | Present one or more existing consumer-owned adoption targets, including case-sensitive and partial-adoption boundaries. | A manifest-only draft proposal records the exact collisions; no colliding target or unrelated path is staged. | Negative / boundary | Passed | Pure planner and adapter fixtures |
| `TEST-0031` | [SUBF-0010](README.md) | Re-run with a pending adoption PR, an orphan deterministic branch, an existing manifest, or an unexpected seed workflow blob. | No duplicate, reset, cleanup, or overwrite occurs; pending work is retained and ambiguous state blocks manual review. | Recovery / concurrency | Passed | Planner and adapter fixtures |
| `TEST-0032` | [SUBF-0010](README.md) | Complete adoption, inspect the manifest tasks and credential contract, then run the existing updater suite. | The manifest requires agent completion/removal, labels remain outside workflow authority, and adopted consumers preserve v0.4 updater behavior. | Regression / structural | Passed | Repository and updater suites |

## Required coverage

- Success: workflow-only seed produces a deterministic collision-free adoption
  proposal from an exact source release.
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
| 2026-07-15 | `main` at `v0.4.0` before FEAT-0005 changes | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: existing [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0006](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0007](../FEAT-0001-common-development-protocol/test-cases.md), and [TEST-0008](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0018](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0019](../FEAT-0003-convergent-completion-scan/test-cases.md), [TEST-0020](../FEAT-0001-common-development-protocol/test-cases.md), [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md) baseline |
| 2026-07-15 | FEAT-0005 test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities-bootstrap.tests.ps1` | Expected red: lifecycle module/adapter, seed routing, adoption contract, and protocol contract are absent |
| 2026-07-15 | FEAT-0005 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities-bootstrap.tests.ps1` | Pass: `TEST-0027` through `TEST-0032` |
| 2026-07-15 | FEAT-0005 implementation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update.tests.ps1` | Pass: existing updater [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md) and [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md) and [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md) |
| 2026-07-15 | FEAT-0005 bounded convergence working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Initial full run found [FIND-0052](README.md): stale current version in the repository-reference adapter |
| 2026-07-15 | FEAT-0005 confirmation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: [complete protocol suite](../../../tests/protocol.tests.ps1) after [FIND-0052](README.md) remediation |
