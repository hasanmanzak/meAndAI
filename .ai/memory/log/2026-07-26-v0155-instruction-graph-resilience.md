# 2026-07-26 - v0.15.5 Instruction-Graph Resilience

## Scope

[FEAT-0056](../../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md)
owns the v0.15.5 correction discovered through exact read-only simulations of
three current consumer trees. The consumer repositories are evidence only;
all production changes and regressions belong upstream.

## Immutable baseline

- Release: [v0.15.4](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.4)
- Commit: [`1883a2315529e7493343c07eebb4c74ed77a62b4`](https://github.com/hasanmanzak/meAndAI/commit/1883a2315529e7493343c07eebb4c74ed77a62b4)
- Delivery: [PR #138](https://github.com/hasanmanzak/meAndAI/pull/138)
- Closed baseline defect: [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137)

## Owned correction

- [Issues #140](https://github.com/hasanmanzak/meAndAI/issues/140) through
  [#147](https://github.com/hasanmanzak/meAndAI/issues/147)
  own hash/placeholder parsing, abort joining, schema-2 capacity, `.mqproj`
  protection, imperative reading, numeric ratio/path, qualified authority, and
  compatible target-policy selection.
- [DEC-0031](../../../docs/decisions/DEC-0031-instruction-graph-schema-2-bounded-compatibility.md)
  owns schema 2, the 524,288-byte per-blob ceiling, unchanged 4 MiB aggregate,
  prospective `.mqproj` protected classification, exact historical target
  profiles, marker-family preservation, and the finite graph-unaware fallback.
- Instruction-reference tokens pass strict decoding before raw shape filtering,
  external/file/drive classification, repository safety, exact-tree membership,
  and placeholder suppression. A local literal-hash/query target selects the
  longest canonical exact-tree prefix before literal membership; its remaining
  suffix is opaque and cannot redirect through dot-segment normalization. Once
  the first valid boundary establishes exact identity, a second literal or
  percent-decoded delimiter cannot reopen or re-normalize that suffix
  ([FIND-0339](../../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0339)). Encoded extensionless file/drive inputs remain unsafe and external
  schemes remain external.
- Batch cleanup keeps a sticky monotonic-clock integrity fault across primary
  and abort scopes, performs no later timed wait after that fault, and observes
  every faulted task exception. Negative-only qualified authority covers the
  bounded direct/reverse modal, contraction, `no longer`, and `never` grammar
  without splitting qualifier conjunctions
  ([FIND-0340](../../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0340)). Every negation binds to the same exact authority-designation
  complement as positive grammar, so ordinary extensionless-path negation
  cannot cross `when`, `because`, `although`, `if`, `after`, `before`, or
  `where` and erase a later positive designation
  ([FIND-0341](../../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0341)). Any retained positive declaration on a mixed line remains
  conservatively authoritative so protected evidence fails closed.
- Existing [TEST-0151](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151),
  [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152),
  [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153),
  and [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161)
  remain the canonical scenario owners; no duplicate numbered test is
  introduced.

## Compatibility boundary

- Every supported graph-aware target uses its exact release-owned schema and
  limit profile. Its target-semantic commands never come from the runtime.
- The three linked-path helpers form one atomic ancillary family: all three
  come from the target when present, or all three come from the runtime when an
  older target exports none. A partial family fails closed.
- Targets v0.12.6-v0.14.1 retain schema-7 Proposed/Completed and schema-8
  Publishing markers. Graph-aware targets from v0.14.2 onward retain schema-9
  Proposed/Completed and schema-10 Publishing markers.
- Runtime-policy fallback is allowed only for exact graph-unaware v0.12.4 and
  v0.12.5 workflows. Too-old, unsupported, and future graph-unaware tags fail
  closed; graph identity is never converted between schemas.

## Simulation classification

- Latest-byte pre/post remote HEADs stayed exact and every clone stayed clean.
- Derdini `e7b10ef` retained its existing older seed, which v0.15.5 does not
  recognize.
- TravelOS `6ee1191` returned assessment schema 3 for graph `0cd369f4...` with
  9 nodes / 74 edges. `Auto` required explicit strategy; hypothetical
  `FullMigration` was `Resolved`. Assessment/summary SHA-256 values were
  `cf5f3609931cda8ba51cfb5b9f2325d777c82a7278ffd9ef36251ac509536c16`
  / `b180143e125fdff13d24d3f717aeca4333fd0b6098be8c96cabb0a1ce2177d73`.
- HAnchor `0281b39` failed closed for maintainer review because protected
  `HAnchor.mq5` is declared live canonical authority.
- No consumer repository was modified and no GitHub simulation repository was
  created.

## Handoff state

Completed local evidence:

- The prior canonical instruction-graph owner passed
  [TEST-0151](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151),
  [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152),
  and [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161)
  on PowerShell 5.1/7 in 220.4/119.6 seconds with exact process/request
  budgets, repeated-hash safety, sticky-clock, fault-observation, capacity,
  authority, and cleanup oracles.
- After the final independent parser review added nested literal/decoded
  delimiter opacity, decoded extensionless scheme/drive inputs,
  punctuation/`however` mixed authority, qualifier conjunctions, bounded
  direct/reverse negation forms, and exact-complement containment across the
  reviewed ordinary-prose connectors, the PowerShell 7 owner passed in 126.5
  seconds.
- The final canonical instruction-graph owner then passed
  [TEST-0151](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151),
  [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152),
  and [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161)
  on Windows PowerShell 5.1 / PowerShell 7 in 248.3 / 143.5 seconds with exact
  2/2 process starts and 4/4 blob requests on both runtimes. The parser-focused
  bounded independent audit found no new `Blocking` or `Important` finding on
  the latest bytes; both runtime AST parses, diff-check, and the overall bounded
  diff/self-review were clean.
- Target-policy import and dispatch under
  [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  passed on both runtimes, including exact historical profiles, the atomic
  ancillary trio, schema-7/8 and schema-9/10 transitions, the exact v0.12.4-
  v0.12.5 fallback, and fail-closed unsupported tags. The PowerShell 7
  canonical initial-adoption integration passed all 19 declared scenarios in
  301.7 seconds.
- The quick-adoption bundle owner retained
  [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
  on PowerShell 5.1/7, and the affected PowerShell 7 lifecycle shard passed.
- Latest-byte read-only resimulation reverified all three consumer snapshots at
  clean exact pre/post remote HEAD; each result remained classified and no
  consumer or GitHub simulation repository was changed or created.
- The first frozen-tree canonical full suite ran for 1751.8 seconds and every
  preceding owner passed before [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
  correctly reported a stale reviewed AST inventory: the exact immutable-policy
  fixture helper contributed four launcher invocations and one helper-owned
  recursive cleanup identity not present in the prior call graph
  ([FIND-0342](../../../docs/features/FEAT-0056-v0155-instruction-graph-resilience/README.md#find-0342)). Exact identity reconciliation left runtime maxima unchanged; the
  focused runtime-efficiency owner then passed
  [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158),
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159),
  and [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162)
  on PowerShell 7 / Windows PowerShell 5.1 in 7.0 / 7.7 seconds with
  `contract.self-check` 1/1. The declared runtime-budget file remained byte-
  identical.
- The final frozen-tree `tests/protocol.tests.ps1` run passed every discovered
  suite in 1745.3 seconds. Capabilities bootstrap passed in 304.600 seconds,
  quick adoption in 861.817 seconds, instruction graph in 129.069 seconds with
  exact 2/2 process starts and 4/4 blob requests, protocol governance in 118.857
  seconds, publication evidence in 96.524 seconds, and runtime efficiency in
  6.586 seconds with [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158),
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159),
  [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162),
  and `contract.self-check` 1/1.

The overall bounded diff/self-review is complete with no unresolved `Blocking`
finding. Remaining gates are the owned pull request, hosted checks and review,
exact merged-commit `v0.15.5` publication and two-asset verification, post-
publication verification, closure of only
[issues #140](https://github.com/hasanmanzak/meAndAI/issues/140) through
[#147](https://github.com/hasanmanzak/meAndAI/issues/147), and exact OID-bound
branch cleanup.
