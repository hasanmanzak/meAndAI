# FEAT-0066 Test Scenarios

Test implementation: not started. [SUBF-0145](README.md#subf-0145) activates
only after its [AcceptedFrozenDesign gate](subf-0145-micro-delivery-plan.md#acceptedfrozendesign-gate)
is exact-head hosted green; [SUBF-0146](README.md#subf-0146) remains inactive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0212` <a name="test-0212"></a> | [SUBF-0145](README.md#subf-0145) | Under the exact [design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze), [public API](subf-0145-public-api-contract.md), [values/errors](subf-0145-value-error-contract.md), and [micro plan](subf-0145-micro-delivery-plan.md#package-matrix), vary authority-set revision/revocation, actor roles, explicit solo exceptions, subject/target/operation/generation/binding, capability, approval, not-before/expiry, replay, sealed publication identity, protected activation record, and two-contender CAS. | Only one fresh, separated, exact, non-transitive, atomically consumed grant can authorize the matching unchanged effect; stale, replayed, broadened, conflicting, drifted, wrong-binding, or losing-CAS attempts fail before mutation. | Unit / contract / concurrency / security | Nearest same-contract sibling: [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); `Distinct` shared typed authority/grant/CAS foundation rather than one workflow lease. | Planned | Future .NET tests in `MeAndAI.Operations.Architecture.Tests` |
| `TEST-0213` <a name="test-0213"></a> | [SUBF-0146](README.md#subf-0146) | Interrupt every journal phase; vary lease expiry, fencing, duplicate delivery, receipt replay, partial persistence, corruption, retention boundary, reconstruction, recovery grant, and competing engine. | Reconstruction returns one deterministic terminal or recovery-required state, stale actors cannot commit, duplicate delivery is idempotent, corruption fails closed, and only the explicitly granted engine can resume. | Component / persistence / recovery / concurrency | Nearest same-contract sibling: [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125); Distinct reusable cross-application journal and recovery contract. | Planned | Future .NET persistence and crash-fixture tests |

## Required coverage

- Grant construction, consumption, expiry, revocation, and replay.
- Separation of duties and non-transitive capability composition.
- CAS, lease, fence, journal, receipt, retention, corruption, interruption, and
  deterministic reconstruction.
- Single-engine recovery across local and provider-backed application adapters.

## Evidence

No implementation, baseline, or run evidence exists. The four exact expected-red
markers/FQNs are frozen by the [selected design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze),
but no red is claimed before the design gate activates implementation. A
historical engine-state enum or workflow lease is not evidence for this
foundation.
