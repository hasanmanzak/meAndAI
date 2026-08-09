# Instruction-Graph Capacity Handoff

| Field | Value |
| --- | --- |
| Authority | [FEAT-0069](../../../docs/features/FEAT-0069-instruction-graph-capacity/README.md), [DEC-0036](../../../docs/decisions/DEC-0036-prospective-instruction-graph-capacity.md), and [issue #175](https://github.com/hasanmanzak/meAndAI/issues/175) |
| Baseline | Exact [`854bc97056d9e3250ab4c6caa7558825904466e8`](https://github.com/hasanmanzak/meAndAI/commit/854bc97056d9e3250ab4c6caa7558825904466e8): `356` nodes, `4096` edges, `311` parsed blobs, `4192113` parsed bytes |
| Decision | Prospective `v0.17.0` remains schema `2`; edges become `8192` and aggregate parsed bytes become `8388608`; all unrelated limits and every target through `v0.16.0` remain exact |
| State | Local verification complete; exact-head hosted delivery pending |

## Test-first evidence

- [TEST-0223](../../../docs/features/FEAT-0069-instruction-graph-capacity/test-cases.md#test-0223)
  expected-red exited `1` in `191.9s` with the sole prospective-capacity
  mismatch.
- The bounded implementation changed only the canonical current-policy edge and
  aggregate constants, exact target-profile composition, deterministic identity
  oracles, and their tests. Intermediate missing-owner and old-hash diagnostics
  are not green evidence.
- The canonical graph owner passed in `234.5s`, with the three predecessor
  graph scenarios and the new capacity scenario all reported green. Quick-adoption
  `ContractsPreflight` passed in `28.5s` with exact `v0.16.0`, `v0.17.0`, and
  unsupported-target behavior.
- Exact-tree StructureOnly passed in `446.6s` with suite observation `444638ms`.
  Publication evidence passed `7/7` in `277.1s` without a published-state
  claim. Fresh code/test and content/scope reviews closed `0/0/0`.
- The first hosted delivery exposed only the runtime-efficiency operation
  oracle at expected `91` versus actual `93`; the two new profile checks explain
  the exact delta. The bounded `93` oracle passed its owner in `7.6s`, and
  replacement hosted validation remains pending.

## Boundary

- This is a protocol-owned prospective capacity revision, not a repository
  exception or a consumer patch.
- The version remains `0.16.0` until a separately authorized immutable release;
  merge, release, publication, consumer mutation, ContractSlice activation,
  workflow filters, and B/C/D remain outside this delivery.
- Complete delivery only after final exact-tree recurrence, commit/push,
  draft-PR synchronization, and exact-head hosted stable jobs are green.
