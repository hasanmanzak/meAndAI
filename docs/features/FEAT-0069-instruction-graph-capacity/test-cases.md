# FEAT-0069 Test Cases

| Test | Related slice | Scenario | Expected result | Level | Distinct intent | Status | Owner and evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0223` <a name="test-0223"></a> | [SUBF-0155](README.md#subf-0155) | Select current and immutable target graph profiles; vary edge and aggregate parsed-byte limits at exact N/N+1 and in canonical digest input while retaining every unrelated limit. | Current schema 2 accepts exactly `8,192` edges and `8,388,608` aggregate parsed bytes and rejects one-over before mutation; either value changes graph identity; `v0.17.0` selects the new pair; exact targets through `v0.16.0` retain released limits; unsupported tags fail closed; the meAndAI self graph passes without a repository exception. | Pure policy / exact boundary / compatibility / integration / cross-runtime | Extends [TEST-0152](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) and [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) only for a new prospective capacity/profile transition; it does not duplicate their parser, path, closure, or lifecycle inventories. | Local passing / exact-head hosted gate pending | Canonical owner `tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1`; `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` is sibling compatibility evidence and does not declare a second scenario owner. |

### Required evidence

1. Current-policy exact-value assertion fails against the predecessor `4,096` /
   `4,194,304` constants before production changes.
2. Exact edge `8,192` passes and `8,193` fails with the edge-budget error.
3. Exact aggregate `8,388,608` passes and `8,388,609` fails with the
   aggregate parsed-blob budget error.
4. Canonical digest comparison changes for only-edge and only-aggregate limit drift.
5. Target-policy composition proves immutable old profiles and exact new
   `v0.17.0`; unreviewed tags remain rejected.
6. Focused owners pass on supported PowerShell, then StructureOnly and hosted
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
