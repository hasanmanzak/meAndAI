# DEC-0036 - Expand Instruction-Graph Capacity Prospectively

- Classification: Decision
- Status: Accepted
- Date: 2026-08-09
- Decision owners: meAndAI maintainers and initial-adoption maintainers
- Related feature: [FEAT-0069](../features/FEAT-0069-instruction-graph-capacity/README.md)
- Tracking: [Issue #175](https://github.com/hasanmanzak/meAndAI/issues/175)
- Revises: [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md) and [DEC-0031](DEC-0031-instruction-graph-schema-2-bounded-compatibility.md) only for the prospective current-release edge, per-blob, and aggregate parsed-byte ceilings

## Context

The exact meAndAI self-consumer graph at
[`854bc97056d9e3250ab4c6caa7558825904466e8`](https://github.com/hasanmanzak/meAndAI/commit/854bc97056d9e3250ab4c6caa7558825904466e8)
is valid at `356` nodes, `4,096` edges, `311` parsed blobs, and `4,192,113`
aggregate parsed bytes. The inclusive edge ceiling has no remaining relation and
the `4,194,304`-byte aggregate ceiling has only `2,191` bytes remaining.
ContractSlice delivery already removed duplicated current-state and evidence
recaps while preserving canonical owners. Another packet cannot add its required
records and immutable delivery links without deterministically exceeding one or
both ceilings.

The later ContractSlice B repository-tree freeze produced a second exact
capacity signal before executable failure: its canonical typed-design blob was
`525,145` bytes, `857` bytes above the retained `524,288` per-blob ceiling. Safe
historical compaction restored validity but left only `2,710` bytes of local
headroom at `521,578/524,288`. The same packet's first complete test-owned wire
draft required `996` normalized changed lines against a packet-local `700`-line
redraw threshold. Neither observation changes graph semantics or the bounded
wire contract; both show that the prospective delivery envelope is too narrow.

[DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md) previously
raised the edge ceiling from `2,048` to `4,096` when correct self-consumer
traceability grew from `2,039` to `2,061`; deleting valid links was rejected as
temporary relief. The same review condition now applies. The aggregate ceiling
is independently saturated, so raising only edges would remain fail closed but
unusable.

## Decision

1. The prospective `v0.17.0` schema-2 profile has inclusive limits of `8,192`
   edges, `1,048,576` bytes per parsed blob, and `8,388,608` aggregate parsed
   bytes.
2. Schema remains `2`. Limits are already canonical digest inputs, so the new
   exact target profile creates prospective identity without reinterpreting an
   older graph or changing graph grammar.
3. Immutable target profiles through `v0.16.0` retain their exact released
   schema, per-blob, node, edge, aggregate, and path limits. Unsupported gaps
   and future tags remain fail closed.
4. The current node (`512`), depth (`32`), tree-entry (`65,536`), tree-path
   (`4,194,304`), and graph-path (`32,768`) ceilings do not change. No evidence
   requires broader values for those dimensions.
5. The canonical bootstrap policy, target-profile validator, graph serializer,
   quick/hosted actors, and exact tests use the same selected profile. No actor
   may carry a private override.
6. Exact `N` boundaries pass and `N+1` boundaries fail before external or
   semantic mutation. The self-consumer graph must pass without a repository
   identity exception.

## Consequences

- The current repository begins the prospective profile near 50% of both
  revised dimensions instead of using packet-local compaction as capacity.
- Worst-case accepted graph traversal, single-blob parsing, and aggregate
  parsed-byte custody increase only for the new profile and remain finite. The
  aggregate envelope still caps a graph containing maximum-size blobs at eight.
- Historical consumers continue to import their exact target-owned policy.
- A new immutable release is required before a consumer can select the new
  profile; this decision does not authorize merge, release, or publication.

## Verification

[TEST-0223](../features/FEAT-0069-instruction-graph-capacity/test-cases.md#test-0223)
owns current-policy values, exact edge/per-blob/aggregate `N/N+1`, digest
sensitivity, legacy target-profile preservation, unsupported-tag rejection, and
self-consumer evidence. Existing [TEST-0152](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152)
and [TEST-0153](../features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
retain their broader graph and lifecycle contracts.

## Alternatives considered

- Continue per-packet compaction: rejected because duplicate recaps were already
  removed and the exact graph still reached both ceilings; valid traceability is
  not expendable capacity.
- Raise only edges: rejected because aggregate parsed bytes are independently at
  `99.948%`.
- Raise every graph limit: rejected because the observed graph requires only a
  wider prospective per-blob bound; nodes, depth, tree, and path remain
  comfortably bounded.
- Change schema: rejected because limit values already participate in identity
  and prior releases evolved exact limits within their immutable profiles.

## Review condition

Review this decision when a real exact graph approaches any prospective
ceiling after canonical-owner compaction, when supported-host time or memory
evidence shows unacceptable pressure, or when a later schema changes graph
serialization or parsing semantics.
