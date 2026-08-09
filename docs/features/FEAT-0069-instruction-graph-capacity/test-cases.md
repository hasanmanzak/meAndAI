# FEAT-0069 Test Cases

| Test | Related slice | Scenario | Expected result | Level | Distinct intent | Status | Owner and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0223` <a name="test-0223"></a> | [SUBF-0155](README.md#subf-0155), [SUBF-0156](README.md#subf-0156) | Select current and immutable target graph profiles; vary edge, per-blob, and aggregate parsed-byte limits at exact N/N+1 and in canonical digest input while retaining every unrelated limit. | Current schema 2 accepts exactly `8,192` edges, `1,048,576` bytes per blob, and `8,388,608` aggregate parsed bytes and rejects one-over before mutation; every value changes graph identity; `v0.17.0` selects the new triple; exact targets through `v0.16.0` retain released limits; unsupported tags fail closed; the meAndAI self graph passes without a repository exception. | Pure policy / exact boundary / compatibility / integration / cross-runtime | Extends [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) and [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) only for a prospective capacity/profile transition; it does not duplicate their parser, path, closure, or lifecycle inventories. | Per-blob amendment ReviewedLocalGreen / delivery pending | Canonical owner `tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1`; `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` is sibling compatibility evidence and does not declare a second scenario owner. |

### Required evidence

1. Current-policy exact-value assertion fails against the predecessor `4,096` /
   `4,194,304` constants before production changes.
2. Exact edge `8,192` passes and `8,193` fails with the edge-budget error.
3. Exact per-blob `1,048,576` passes and `1,048,577` fails with the per-blob
   budget error.
4. Exact aggregate `8,388,608` passes and `8,388,609` fails with the
   aggregate parsed-blob budget error.
5. Canonical digest comparison changes for only-edge, only-blob, and only-
   aggregate limit drift.
6. Target-policy composition proves immutable old profiles and exact new
   `v0.17.0`; unreviewed tags remain rejected.
7. Focused owners pass on supported PowerShell, then StructureOnly and hosted
   stable jobs close the feature without activation or publication claims.

### Local evidence

- Expected-red: the canonical owner exited `1` in `191.9s` with the sole
  deliberate mismatch `prospective release-owned graph capacity differs from
  the accepted decision.`
- Bounded implementation diagnostics first exposed only the missing scenario
  registry entry and then the two deterministic graph-identity oracles changed
  by the canonical limit inputs; neither diagnostic is reused as green evidence.
- Focused green: the canonical owner passed in `234.5s`, reporting the three
  predecessor graph scenarios and [TEST-0223](#test-0223) green together.
- Sibling compatibility green: quick-adoption `ContractsPreflight` passed in
  `28.5s`, including immutable `v0.16.0`, prospective `v0.17.0`, and
  unsupported-target fail-closed cases.
- Exact-tree StructureOnly passed in `446.6s` with suite observation `444638ms`.
  Publication evidence passed `7/7` in `277.1s` and explicitly made no
  published-state claim.
- The first hosted delivery exposed only the sibling
  [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
  operation oracle at expected `91` versus actual `93`: the two deliberate
  profile checks account exactly for the delta. The bounded `93` oracle passed
  its owner locally in `7.6s`; replacement hosted validation remains pending.
- The per-blob amendment began with design authority only. Its fresh expected-
  red and focused green are now recorded; final local gates, reviews,
  commit/push, and exact-head hosted evidence must close the amendment.
- Amendment expected-red: the canonical owner exited `1` in `234.1s` with only
  the accepted-decision capacity mismatch. Production was unchanged.
- Amendment focused green: after the two bounded policy changes and the two
  deterministic identity-oracle updates, the canonical owner passed in
  `236.2s`; all four owned graph scenarios were green with exact actor counters
  `2/2` process starts and `4/4` blob requests.
- Amendment target-profile compatibility passed `ContractsPreflight` in `27.8s`:
  immutable `v0.16.0` retained `524,288`, prospective `v0.17.0` selected
  `1,048,576`, and unsupported targets remained fail closed.
- Direct source-graph dispatch compatibility passed in `5.1s`. The broader
  vertical shard's `304s` outer timeout produced no failure and remains an
  inconclusive infrastructure observation, not green evidence.
- The first StructureOnly exact-tree run exposed only nine evidence-link
  structure findings. Their edge-neutral wording correction was followed by a
  green StructureOnly in `427.2s` (`425411ms` owner observation).
- Publication evidence then passed `7/7` in `286.7s` and explicitly made no
  published-state claim. These evidence-only record additions require one final
  exact-tree recurrence before commit.
