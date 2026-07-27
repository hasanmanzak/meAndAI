# FEAT-0063 Test Scenarios

Test implementation: not started; development and consumer mutation are not authorized.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0205` <a name="test-0205"></a> | [SUBF-0132](README.md#subf-0132) | Inventory supported consumer states and migrate representative fresh, current, legacy, recovery, protected-authority, and ambiguous cases through immutable releases. | Supported states reach exact C# authority with clean bounded changes; unsafe or unsupported states fail closed without workaround duplication. | Migration / integration | Nearest sibling: [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153); `Distinct` engine-authority migration contract. | Planned | Future immutable consumer simulations |
| `TEST-0206` <a name="test-0206"></a> | [SUBF-0132](README.md#subf-0132) | Interrupt and resume mixed PowerShell/C# migration at every durable boundary and vary runtime availability and artifact integrity. | Recovery is idempotent, exact, and credential-safe; missing runtime or invalid artifact fails before mutation with a bounded response. | Recovery / release / security | Nearest sibling: [TEST-0121](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md#test-0121); `Distinct` cross-engine migration recovery. | Planned | Future migration integration tests |
| `TEST-0207` <a name="test-0207"></a> | [SUBF-0133](README.md#subf-0133) | Remove proposed PowerShell authority and PS 5.1/7 routes in a candidate tree, then scan every supported normal/recovery/publication path and run post-retirement validation. | Retirement is permitted only when no supported dependency remains and all C# authority passes; any reference or behavioral gap blocks deletion. | Architecture / full integration / compatibility | Nearest sibling: [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146); `Distinct` executable authority-retirement gate. | Planned | Future dependency and full-suite tests |

## Evidence

No implementation or run evidence exists; all scenarios are planning records.
