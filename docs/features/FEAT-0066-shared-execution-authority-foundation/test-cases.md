# FEAT-0066 Test Scenarios

Test implementation is paused at a design-correction boundary. [SUBF-0145](README.md#subf-0145)
has a `ReviewedLocalGreen` snapshot package and one accepted grant red; grant
production resumes only after the corrected [AcceptedFrozenDesign gate](subf-0145-micro-delivery-plan.md#acceptedfrozendesign-gate)
is exact-head hosted green. [SUBF-0146](README.md#subf-0146) remains inactive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0212` <a name="test-0212"></a> | [SUBF-0145](README.md#subf-0145) | Under the exact [design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze), [public API](subf-0145-public-api-contract.md), [values/errors](subf-0145-value-error-contract.md), and [micro plan](subf-0145-micro-delivery-plan.md#package-matrix), vary authority-set revision/revocation, actor roles, explicit solo exceptions, subject/target/operation/generation/binding, independent expected lease/fence, approved grant store/head, capability, approval, not-before/expiry, replay, sealed publication identity, protected activation record, and two-contender CAS. | Only one fresh, separated, exact, non-transitive, atomically consumed grant can authorize the matching unchanged effect; stale, replayed, broadened, conflicting, drifted, wrong-binding, lease/fence-mismatched, unapproved/missing-store, or losing-CAS attempts fail before mutation. | Unit / contract / concurrency / security | Nearest same-contract sibling: [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); `Distinct` shared typed authority/grant/CAS foundation rather than one workflow lease. | Planned | [Subfeature=SUBF-0145](README.md#subf-0145) .NET contract tests; executable scenario-owner/status activation held |
| `TEST-0213` <a name="test-0213"></a> | [SUBF-0146](README.md#subf-0146) | Interrupt every journal phase; vary lease expiry, fencing, duplicate delivery, receipt replay, partial persistence, corruption, retention boundary, reconstruction, recovery grant, and competing engine. | Reconstruction returns one deterministic terminal or recovery-required state, stale actors cannot commit, duplicate delivery is idempotent, corruption fails closed, and only the explicitly granted engine can resume. | Component / persistence / recovery / concurrency | Nearest same-contract sibling: [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125); Distinct reusable cross-application journal and recovery contract. | Planned | Future .NET persistence and crash-fixture tests |

## Required coverage

- Grant construction, consumption, expiry, revocation, and replay.
- Separation of duties and non-transitive capability composition.
- CAS, lease, fence, journal, receipt, retention, corruption, interruption, and
  deterministic reconstruction.
- Single-engine recovery across local and provider-backed application adapters.

## Evidence

The snapshot package is `ReviewedLocalGreen`. The grant package's one canonical
[`TEST-0212-GRANT-RED-0002`](#test-0212) invocation failed only on the frozen
authorizer absence; source SHA-256 is
`BBECC0F165FFAD9DC59B62A742B9B26F53C3DC6624A90DD9004D52A9155C52B7` and TRX
SHA-256 is `87D21A285E5BDDEC8D1B555583963A073DCF0C9E954EF901568C61806238C7A3`.
The correction creates no replacement R and that invocation is never rerun.
During green transformation, intermediate facts replace the governance-invalid
[Scenario=TEST-0212](#test-0212) trait with exact [Subfeature=SUBF-0145](README.md#subf-0145); their FQNs and
this canonical documentation trace remain unchanged. The scenario trait,
executable owner, and `Passing` status activate only in a separate final atom.
A historical engine-state enum or workflow lease remains non-evidence.
