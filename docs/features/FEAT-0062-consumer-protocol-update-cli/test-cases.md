# FEAT-0062 Update Application Test Scenarios

Test implementation: not started; development is not authorized.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0202` <a name="test-0202"></a> | [SUBF-0129](README.md#subf-0129) | Resolve current, descendant, pre-engine, missing-link, incompatible, malformed, and future installed states against exact release catalogs; vary target-runtime handoff and legacy-handoff-pending evidence. | Exactly one complete compatible transition chain, side-by-side target handoff, or current no-op is returned; the old runtime never interprets target-only semantics; ambiguity and unsupported history fail closed. | Unit / release integration | Nearest sibling: [TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106); `Distinct` target-runtime installed-state and handoff contract. | Planned | Future .NET tests |
| `TEST-0203` <a name="test-0203"></a> | [SUBF-0130](README.md#subf-0130) | Seal and apply managed assets, gitlink, migrations, and ledger under an exact grant while injecting HEAD drift, target-runtime drift, lease loss, links, partial writes, cancellation, and target mismatch. | Exact target-bound plan applies through one engine and shared journal; drift, unsafe evidence, or interruption enters explicit recovery without automatic fallback. | Git / filesystem / authority / recovery | Nearest sibling: [TEST-0121](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md#test-0121); `Distinct` compiled update application apply/recovery boundary. | Planned | Future integration tests |
| `TEST-0204` <a name="test-0204"></a> | [SUBF-0131](README.md#subf-0131) | Create, resume, close, finalize, and recover managed proposals across direct, merge-queue, squash, rebase, duplicate, failed, and legacy-handoff-pending events and compare applicable PowerShell outcomes. | Only qualified exact evidence finalizes one owner and reconciles the handoff; divergence or unmapped behavior blocks later authority migration without transferring or retiring authority here. | GitHub / differential / concurrency / recovery | Nearest sibling: [TEST-0179](../FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0179); `Distinct` update application closure/finalization and compatibility-evidence contract. | Planned | Future integration/differential tests |

## Evidence

No implementation or run evidence exists; all scenarios are planning records.
