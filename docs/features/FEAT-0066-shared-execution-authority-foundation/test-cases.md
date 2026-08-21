# FEAT-0066 Test Scenarios

[SUBF-0145](README.md#subf-0145) remains scenario-inactive, but its authority
snapshot, execution grant, publication envelope, and extension activation
packages are each `ReviewedLocalGreen` in separate local commits. Their
immutable [EA-CONVERGE-01 checkpoint](subf-0145-package-evidence.md#ea-converge-01)
is exact-head hosted green. The final review-link cohort is merged and
exact-main hosted green through [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187)
and [run 32521885155](https://github.com/hasanmanzak/meAndAI/actions/runs/32521885155).
The records-only
[TEST-0212 final activation freeze](subf-0145-test-0212-final-activation-freeze.md)
is local `AcceptedFrozenDesign`; it changes no trait, owner, workflow, or test.
[SUBF-0146](README.md#subf-0146) remains inactive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0212` <a name="test-0212"></a> | [SUBF-0145](README.md#subf-0145) | Under the exact [design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze), [public API](subf-0145-public-api-contract.md), [values/errors](subf-0145-value-error-contract.md), [micro plan](subf-0145-micro-delivery-plan.md#package-matrix), and [final activation freeze](subf-0145-test-0212-final-activation-freeze.md), vary authority-set revision/revocation, actor roles, explicit solo exceptions, subject/target/operation/generation/binding, independent expected lease/fence, approved grant store/head, capability, approval, not-before/expiry, replay, sealed publication identity, protected activation record, and two-contender CAS. | Only one fresh, separated, exact, non-transitive, atomically consumed grant can authorize the matching unchanged effect; stale, replayed, broadened, conflicting, drifted, wrong-binding, lease/fence-mismatched, unapproved/missing-store, or losing-CAS attempts fail before mutation. | Unit / contract / concurrency / security | Nearest same-contract sibling: [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); `Distinct` shared typed authority/grant/CAS foundation rather than one workflow lease. | Planned | Exact `20` [Subfeature=SUBF-0145](README.md#subf-0145) .NET Facts in six files; neutral topology, executable scenario owner/status, and both workflow filters are frozen but held |
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
[Subfeature=SUBF-0145](README.md#subf-0145) are locally green; no fact carries
[Scenario=TEST-0212](#test-0212). The scenario trait, executable owner, and
`Passing` status activate only in a separate final atom. A historical
engine-state enum or workflow lease remains non-evidence.

The [final activation freeze](subf-0145-test-0212-final-activation-freeze.md)
binds the exact `20` FQNs, six source paths, neutral topology-test FQN, one
natural-red marker/invocation identity, owner move, two stable workflow
filters, TEST-0146 oracle, fourteen-path allowlist, caps, and closure gates.
It is design evidence only; TEST-0212 remains `Planned`.
