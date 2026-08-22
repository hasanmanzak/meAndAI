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

The common C/D design checkpoint subsequently merged through
[PR #191](https://github.com/hasanmanzak/meAndAI/pull/191) at exact main
[`5bd13520444643d022ef1b421f9cbee48e29b014`](https://github.com/hasanmanzak/meAndAI/commit/5bd13520444643d022ef1b421f9cbee48e29b014).
Exact-main [run 32566870206](https://github.com/hasanmanzak/meAndAI/actions/runs/32566870206)
passed Ubuntu and Windows; publication verification was correctly skipped.

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
This corrected C design remains `AcceptedFrozenDesign`; its R0019 and source/test
mutation wait for the D correction to merge and pass exact-main hosted validation.

[FIND-0467](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0467)
separately freezes `D-SELECTOR-SEMANTICS-CORRECTION-01`. Its only paths are the
Policy selector resolver and existing D infrastructure test. Existing FQN and
topology are unchanged; marker [`TEST-0210-D-BEHAVIOR-RED-0010`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210), R0020. Exact
parents [`docs/features/FEAT-0001`](../../../docs/features/FEAT-0001-common-development-protocol/README.md) and [`DEC-0035`](../../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md) must resolve to the two feature
child paths and unchanged decision identity. Its accepted pre-red transform made the
historical `...RED-0002` null branch marker-free and keyed all three results by
selector key, leaving exactly one `...RED-0010` marker before green removed it.

R0020 is accepted and immutable without rerun. The exact red source was
`26,001` bytes / SHA-256
`B44F6370E391340322F2C0610B877884CCA9B450DA967C9105A0E91385A0593E`;
the one-shot runner was `43,086` bytes / SHA-256
`90BDA5172C04D72DC5AB07DDABABB30398ED10757577B04C51E82D0BC6B19CD0`.
Its sole `5,298`-byte TRX has SHA-256
`AD5F3BA680897B7DD8A9BEE0FE6BB3C5FD04703698138C867D35271B6E806E61`;
native/runner exits were `1/0`, result/definition/entry were `1/1/1`, raw/
transcript marker counts were `2/1`, all sixteen counters were exact, and no
attachment or collector existed. The `12,933`-byte report SHA-256 is
`CC452127DB21C7D51B62CD63EB6D8AC716CD279F52386A95D948C65F479E5394`.

The marker-free implementation is `ReviewedLocalGreen`: focused `1/1`, D
`11/11`, Scenario and A-D union `65/65`, full Conformance `73/73`, Domain
`98/98`, API/ownership `15/15`, Release `0/0`, format, locks and diff are
green. Fresh code and evidence/scope reviews are `0/0/0`. Exact green source
identities are Policy `807` bytes / SHA-256
`6D74DD1D6887F73AFE35AE930A6C318B04060EC2572AFF4B6AFD73D81AB64AC7`
and test `25,669` bytes / SHA-256
`511DC11DC5D5DB68E3BD5918794DB58552F6F983122E8A6981C3B7AC50FE71F8`;
caps are production `16/120`, test `60/180`, combined `76/300`. The final
record-synchronized schema-2 instruction-graph suite passed `4/4` with exact
`2/2` process-start and `4/4` blob-request counters, PS7 and PS5.1
StructureOnly passed, and publication evidence passed `7/7` without claiming
published state. Commit, push, exact-head hosted, merge and exact-main gates
remain pending. C may prepare scaffold/static preflight in
parallel, but reconciles onto that D exact main before consuming R0019; it then
owns the only active shared-record writer. Pre-reconcile hosted evidence is not
merge evidence. After both implementation merges and exact-main hosted
green, report sealing must be reconciled and revalidated before
[TEST-0209](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0209) can start.
