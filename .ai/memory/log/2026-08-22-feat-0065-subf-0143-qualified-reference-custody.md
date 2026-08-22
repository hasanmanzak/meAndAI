# 2026-08-22 - ContractSlice C qualified-reference custody correction redraw

## Current state

[PR #190](https://github.com/hasanmanzak/meAndAI/pull/190) merged
`REPORT-SEALING-01` at exact main
[`997e2658b615212c5a34bc44ec1419282cf86446`](https://github.com/hasanmanzak/meAndAI/commit/997e2658b615212c5a34bc44ec1419282cf86446).
Exact-main [run 32553183954](https://github.com/hasanmanzak/meAndAI/actions/runs/32553183954)
passed Ubuntu and Windows; publication verification was correctly skipped.
The branch/worktree was removed after exact-main green. [TEST-0222](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0222)
remains Planned while its packet-local report route is green and its canonical
R remains immutable without rerun.

The subsequent direct [TEST-0209](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0209)
fixture review exposed [FIND-0466](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0466).
The merged public ContractSlice C path admits only ContextProof projections,
does not retain observed roots/models/capabilities/demand/selector authority,
and cannot issue the required second evaluation round. Separately, the three
real Policy selector resolvers copy the parent canonical value instead of
appending the two required feature children. Report code preserves references
but owns no producer authority. Synthetic protected/report input is not
accepted product evidence. [TEST-0209](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0209)
therefore remains Planned and `COMPOSED-QUALIFICATION-01` remains inactive.

## Accepted correction design

`C-QUALIFIED-REFERENCE-CUSTODY-01` is an `AcceptedFrozenDesign` Gate-2 contract
owned by [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
and the already-active [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210).
It adds no public API. One internal session-bound sealed graph owns exact
ContextProof/Root/Derived/ExpectedSelector handles, models, capabilities and
demand bindings. The applicability context owns graph0. Round0 acquires non-
projected inputs and returns immutable graph1: empty projection closes with
graph1, while nonempty projection issues a session-registered graph1-bound
round1 target plan. Round1 produces the final graph2-owned closure. Graph0 is
never mutated and no partial graph1/graph2 survives. It preserves structural
same-or-narrower locations and never invents selector targets.

The exact behavior FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCQualifiedReferenceCustodyTests.Preserves_exact_root_derived_and_expected_selector_graph_through_public_evaluation`.
It carries direct [`Scenario=TEST-0210`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) and `ContractSlice=C` traits. P/R are
`Applicable`/`BehaviorRed`; marker [`TEST-0210-C-BEHAVIOR-RED-0010`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210); one-shot
execution ordinal R0019. The red source first proves the exact current
one-round closure XOR activated two-round successor/graph2 closure. Exact
projector/index phase counts are predecessor `1/0 -> 1/1` and activated
`0/0 -> 1/0 -> 1/1`; partial or mixed states are marker-free. Only the exact predecessor whole state plus
`InvalidOperationException` / `The requested capability is unavailable.` at
the evaluator's first repository-tree capability request may emit the marker.
Green removes the predecessor branch and accepts only the activated two-round
state. The candidate [typed design](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md#c-qualified-reference-custody-01)
and [C plan](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-c-micro-delivery-plan.md#c-qualified-reference-custody-01-correction-control)
own the exact thirteen production paths, eleven test paths, plan-bound production
writer/qualification/cache session, graph lifecycle, three Derived kinds
adopted from closed codec states with manifest binding, measured usage and
live-session Produced/Retained cache association without graph-stage codec/
meter re-execution, retained instruction/demand collision frames,
root-relative graph ledgers, admission-owned codec acquisition failure versus
parser/index/projector declaration failure projection and its exact eligible
failure-cache boundary,
zero-missing-input paths, atomic successor custody, caps, and gate sequence.
This corrected design is `AcceptedFrozenDesign`; no R or source/test mutation
is authorized before the design merges and exact-main hosted validation is green.

[FIND-0467](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0467)
separately freezes `D-SELECTOR-SEMANTICS-CORRECTION-01`. Its only paths are the
Policy selector resolver and existing D infrastructure test. Existing FQN and
topology are unchanged; marker [`TEST-0210-D-BEHAVIOR-RED-0010`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), R0020. Exact
parents [`docs/features/FEAT-0001`](../../../docs/features/FEAT-0001-common-development-protocol/README.md) and [`DEC-0035`](../../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) must resolve to the two feature
child paths and unchanged decision identity. Its pre-red transform makes the
historical `...RED-0002` null branch marker-free and keys all three results by
selector key, leaving exactly one `...RED-0010` marker.

No source, test, workflow, owner, project, package, lock, canonical R, release,
publication or consumer mutation exists in this design checkpoint. Before the
focused commit, the accepted design tree passed filesystem/link/diff/capacity and
fresh design/security/evidence/traceability review without claiming a
committed graph identity. The exact focused commit and its committed-HEAD
schema-2 graph, PS7/PS5.1 StructureOnly and publication-evidence gates are now
green; it awaits one push and exact-head Ubuntu/Windows green. The design PR must then merge and its
exact-main head pass Ubuntu/Windows before C#/Policy work begins. D is the
first final lane and must consume R0020, synchronize shared records, merge and
pass exact-main hosted green. C may prepare scaffold/static preflight in
parallel, but reconciles onto that D exact main before consuming R0019; it then
owns the only active shared-record writer. Pre-reconcile hosted evidence is not
merge evidence. After both implementation merges and exact-main hosted
green, report sealing must be reconciled and revalidated before
[TEST-0209](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0209) can start.
