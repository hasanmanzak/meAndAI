# FEAT-0061 Test Scenarios

Test implementation: not started; development is not authorized.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0197` <a name="test-0197"></a> | [SUBF-0125](README.md#subf-0125) | Discover and assess fresh, current, historical, ambiguous, linked-path, and protected-authority repositories. | Assessment is deterministic and read-only; ambiguity and protected authority fail closed with exact evidence. | Contract / integration / security | Nearest sibling: [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153); `Distinct` compiled staged adoption assessment. | Planned | Future .NET tests |
| `TEST-0198` <a name="test-0198"></a> | [SUBF-0126](README.md#subf-0126) | Plan every supported explicit strategy and vary target release, graph, source HEAD, marker family, and unknown evidence. | One immutable target-bound plan is produced only for an allowed explicit strategy; invalid inputs fail before mutation. | Unit / contract | Nearest sibling: [TEST-0098](../FEAT-0015-stability-consistency-mandate/test-cases.md#test-0098); `Distinct` typed strategy-plan contract. | Planned | Future .NET tests |
| `TEST-0200` <a name="test-0200"></a> | [SUBF-0127](README.md#subf-0127) | Apply an exact plan, alter source state, inject partial failures, links, TOCTOU, and closure validation failures. | Exact plan succeeds atomically; drift or unsafe paths fail closed; recovery preserves qualified evidence. | Filesystem / Git / recovery | Nearest sibling: [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125); `Distinct` compiled transition apply boundary. | Planned | Future integration tests |
| `TEST-0201` <a name="test-0201"></a> | [SUBF-0128](README.md#subf-0128) | Publish/resume proposal lifecycle and compare applicable PowerShell outcomes, credentials, cancellation, and completed-history cases. | One exact lifecycle is reused; secrets remain redacted; recovery is idempotent; unmapped divergence blocks authority transfer. | GitHub / differential / security | Nearest sibling: [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069); `Distinct` C# publication and authority transfer. | Planned | Future integration/differential tests |

## Evidence

No implementation or run evidence exists; all scenarios are planning records.
