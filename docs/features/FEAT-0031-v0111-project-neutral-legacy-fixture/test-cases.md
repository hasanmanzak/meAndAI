# FEAT-0031 Test Scenarios

Implementation: [`tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1`](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1)
and [`tests/capabilities/consumer-update/consumer-migrations.tests.ps1`](../../../tests/capabilities/consumer-update/consumer-migrations.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0133` | [SUBF-0057](README.md) | Inspect the frozen fixture and its bounded adapter test surface for path, symbol, message, and URL identity. | Unique surface markers and exact neutral tokens bind the fixture path, function, variable, messages, commit text, and reserved `example.invalid` links; no live consumer GitHub URL is embedded. | Structural / coupling regression | Passed locally | Existing adapter suite |

The existing canonical [`TEST-0125`](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md)
declaration remains owned by [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md). FEAT-0031 strengthens its executable
evidence without redeclaring or renumbering that compatibility scenario.

## Required coverage

- Preserve the exact [MIG-0001](../../../migrations/MIG-0001.json) recognition fragment and legacy protocol SHA.
- Core-only unique [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md) failure and atomic exact 13-path success.
- Second planning pass over applied bytes and ledger is an exact no-op.
- Synthetic reserved issue and pull-request links match between fixture and
  consumer content.
- Project-neutral fixture path, function, variables, messages, and commit text.
- Immutable migration/catalog bytes and existing consumer-migration scenarios.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-18 | `v0.11.0` baseline | Windows PowerShell 5.1 | Read-only fixture/test audit | Named-consumer coupling present; [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) record claims a no-op rerun not directly executed by its test block |
| 2026-07-18 | Test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Expected red at the absent neutral fixture; the sandboxed run also reproduced the known Windows Git signal-pipe ACL limitation |
| 2026-07-18 | Reviewed working tree | Windows PowerShell 5.1, unrestricted local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Passed in 33.7 seconds; core-only unique [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md) red, exact 13-path atomic green, no-op second plan, and bounded `TEST-0133` surface guard passed |
| 2026-07-18 | Reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/consumer-migrations.tests.ps1` | Passed in 1.7 seconds with [TEST-0119](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md) and [TEST-0120](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md); immutable migration/catalog blobs remained unchanged |
| 2026-07-19 | Reviewed working tree | Windows PowerShell 5.1, unrestricted local Git fixtures | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 1593.1 seconds; all discovered suites passed, including [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) and `TEST-0133` |
