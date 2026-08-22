# FEAT-0066 Test Scenarios

[SUBF-0145](README.md#subf-0145) remained scenario-inactive through its four
`ReviewedLocalGreen` authority/grant/publication/activation packages and the
immutable [EA-CONVERGE-01 checkpoint](subf-0145-package-evidence.md#ea-converge-01)
is exact-head hosted green. The final review-link cohort is merged and
exact-main hosted green through [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187)
and [run 32521885155](https://github.com/hasanmanzak/meAndAI/actions/runs/32521885155).
The [TEST-0212](#test-0212) [final activation](subf-0145-test-0212-final-activation-freeze.md)
is now locally active with semantic gates `Passing`. The first [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189)
exact-head run exposed only the finite Windows timeout owned by
[FIND-0465](README.md#find-0465); corrected local structural evidence is green,
while replacement exact-head hosted validation remains pending.
[SUBF-0146](README.md#subf-0146) remains inactive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0212` <a name="test-0212"></a> | [SUBF-0145](README.md#subf-0145) | Under the exact [design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze), [public API](subf-0145-public-api-contract.md), [values/errors](subf-0145-value-error-contract.md), [micro plan](subf-0145-micro-delivery-plan.md#package-matrix), and [final activation freeze](subf-0145-test-0212-final-activation-freeze.md), vary authority-set revision/revocation, actor roles, explicit solo exceptions, subject/target/operation/generation/binding, independent expected lease/fence, approved grant store/head, capability, approval, not-before/expiry, replay, sealed publication identity, protected activation record, and two-contender CAS. | Only one fresh, separated, exact, non-transitive, atomically consumed grant can authorize the matching unchanged effect; stale, replayed, broadened, conflicting, drifted, wrong-binding, lease/fence-mismatched, unapproved/missing-store, or losing-CAS attempts fail before mutation. | Unit / contract / concurrency / security | Nearest same-contract sibling: [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); `Distinct` shared typed authority/grant/CAS foundation rather than one workflow lease. | Passing | Exact `20/20` [Subfeature=SUBF-0145](README.md#subf-0145) and `20/20` Scenario Facts, neutral topology `1/1`, Architecture `52/52`, Packaging `17/17`, combined route `69/69`; exact-head hosted validation pending |
| `TEST-0213` <a name="test-0213"></a> | [SUBF-0146](README.md#subf-0146) | Interrupt every journal phase; vary lease expiry, fencing, duplicate delivery, receipt replay, partial persistence, corruption, retention boundary, reconstruction, recovery grant, and competing engine. | Reconstruction returns one deterministic terminal or recovery-required state, stale actors cannot commit, duplicate delivery is idempotent, corruption fails closed, and only the explicitly granted engine can resume. | Component / persistence / recovery / concurrency | Nearest same-contract sibling: [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125); Distinct reusable cross-application journal and recovery contract. | Planned | Future .NET persistence and crash-fixture tests |

## Required coverage

- Grant construction, consumption, expiry, revocation, and replay.
- Separation of duties and non-transitive capability composition.
- CAS, lease, fence, journal, receipt, retention, corruption, interruption, and
  deterministic reconstruction.
- Single-engine recovery across local and provider-backed application adapters.

## Evidence

All four package-local canonical reds are immutable and were consumed exactly
once. Their source/TRX identities, one-time original-oracle routes, bounded
greens, cumulative counts, reviews, and focused commits are retained by the
[package ledger](subf-0145-package-evidence.md). The four exact package FQNs and
[Subfeature=SUBF-0145](README.md#subf-0145) and
[Scenario=TEST-0212](#test-0212) are locally green on the same exact `20` Facts.
The neutral topology, executable owner, and both stable filters are active;
exact-head hosted validation remains pending. A historical
engine-state enum or workflow lease remains non-evidence.

The bounded [FIND-0465](README.md#find-0465) correction changes only the
[TEST-0124](../FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124)
Windows finite bound from `55` to `65`; Linux remains `30`, post-publication
remains `5`, and the activation topology, filters, owner, Scenario traits,
canonical red custody, and held successor scope are unchanged.

The [final activation freeze](subf-0145-test-0212-final-activation-freeze.md)
binds the exact `20` FQNs, six source paths, neutral topology-test FQN, one
natural-red marker/invocation identity, owner move, two stable workflow
filters, [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) oracle, fourteen-path activation allowlist, bounded finite-timeout correction allowlist, caps, and closure gates.
Its accepted natural-red and local-green evidence are retained in the
[package ledger](subf-0145-package-evidence.md#test-0212-final-activation).
