# FEAT-0066 Test Scenarios

[SUBF-0145](README.md#subf-0145) remained scenario-inactive through its four
`ReviewedLocalGreen` authority/grant/publication/activation packages and the
immutable [EA-CONVERGE-01 checkpoint](subf-0145-package-evidence.md#ea-converge-01)
is exact-head hosted green. The final review-link cohort is merged and
exact-main hosted green through [PR #187](https://github.com/hasanmanzak/meAndAI/pull/187)
and [run 32521885155](https://github.com/hasanmanzak/meAndAI/actions/runs/32521885155).
The [TEST-0212](#test-0212) [final activation](subf-0145-test-0212-final-activation-freeze.md)
is `Passing`, merged through [PR #189](https://github.com/hasanmanzak/meAndAI/pull/189),
and exact-main hosted green through
[run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165).
[FIND-0465](README.md#find-0465) is resolved. [SUBF-0146](README.md#subf-0146)
has a records-only Gate 1/2 freeze candidate; it has no red or test code and
[TEST-0213](#test-0213) remains inactive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0212` <a name="test-0212"></a> | [SUBF-0145](README.md#subf-0145) | Under the exact [design](subf-0145-authority-grant-activation-design.md#test-0212-qualification-freeze), [public API](subf-0145-public-api-contract.md), [values/errors](subf-0145-value-error-contract.md), [micro plan](subf-0145-micro-delivery-plan.md#package-matrix), and [final activation freeze](subf-0145-test-0212-final-activation-freeze.md), vary authority-set revision/revocation, actor roles, explicit solo exceptions, subject/target/operation/generation/binding, independent expected lease/fence, approved grant store/head, capability, approval, not-before/expiry, replay, sealed publication identity, protected activation record, and two-contender CAS. | Only one fresh, separated, exact, non-transitive, atomically consumed grant can authorize the matching unchanged effect; stale, replayed, broadened, conflicting, drifted, wrong-binding, lease/fence-mismatched, unapproved/missing-store, or losing-CAS attempts fail before mutation. | Unit / contract / concurrency / security | Nearest same-contract sibling: [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105); `Distinct` shared typed authority/grant/CAS foundation rather than one workflow lease. | Passing | Exact `20/20` [Subfeature=SUBF-0145](README.md#subf-0145) and `20/20` Scenario Facts, neutral topology `1/1`, Architecture `52/52`, Packaging `17/17`, combined route `69/69`; exact-main Ubuntu/Windows green in [run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165) |
| `TEST-0213` <a name="test-0213"></a> | [SUBF-0146](README.md#subf-0146) | Under the records-only [design](subf-0146-journal-recovery-design.md), [public API](subf-0146-public-api-contract.md), [values/errors](subf-0146-value-error-contract.md), and [micro plan](subf-0146-micro-delivery-plan.md#package-matrix), interrupt every intent/effect/receipt phase; vary lease expiry/release/renewal, fencing, duplicate delivery, lost result, partial persistence, chain truncation/fork/corruption, live-effect divergence, retention boundary, reconstruction, recovery action/grant, and competing engine. | Intent failure forbids the effect; receipt ambiguity becomes `RecoveryRequired`; reconstruction deterministically returns `RecoveryRequired`, `Diverged`, `UnrecoverableJournal`, or `Complete`; stale actors cannot append; identical delivery is idempotent; corruption fails closed; only a fresh exact newer-fenced recovery grant may retry `NotStarted` or record `AppliedUnrecorded`; retention needs an independent grant/ledger. | Component / persistence / recovery / concurrency / security | Nearest same-contract sibling: [TEST-0125](../FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125); `Distinct` reusable cross-application journal, reconstruction, recovery, and retention contract. | Planned | Four future compile-safe FQNs/markers are frozen in the [package matrix](subf-0146-micro-delivery-plan.md#package-matrix); no red or test code exists |

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
[Scenario=TEST-0212](#test-0212) are green on the same exact `20` Facts.
The neutral topology, executable owner, and both stable filters are active;
exact-main hosted validation is green through
[run 32542273165](https://github.com/hasanmanzak/meAndAI/actions/runs/32542273165).
A historical
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

For [SUBF-0146](README.md#subf-0146), the [design](subf-0146-journal-recovery-design.md) freezes
intent-before-effect, ambiguous-receipt, lease/fence, reconstruction, recovery,
and independent retention semantics. The [public API](subf-0146-public-api-contract.md)
and [value/error contract](subf-0146-value-error-contract.md) freeze the exact
surface, digests, rejections, precedence, and cancellation behavior. The
[micro plan](subf-0146-micro-delivery-plan.md) freezes four future package
markers/FQNs, one-time red custody, paths, caps, review gates, and the held
Scenario-activation boundary. These records are test intent only: no
[Subfeature=SUBF-0146](README.md#subf-0146) or
[Scenario=TEST-0213](#test-0213) Fact currently exists.
