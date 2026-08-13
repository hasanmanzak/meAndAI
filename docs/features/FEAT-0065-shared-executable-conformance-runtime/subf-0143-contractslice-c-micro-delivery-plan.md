# [SUBF-0143](README.md#subf-0143) - ContractSlice C Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | Initial design, Activation, Applicability, and Evaluation cohorts `ExactHeadHostedGreen`; C `11/11`, current A+B+C/full Conformance `54/54`; R=0006/R=0008/R=0009/R=0010/R=0012/R=0013/R=0016 diagnostic/no-success, R=0007/R=0011/R=0014/R=0015/R=0017/R=0018 accepted/immutable; `C-INTENT-RESULT-01` and `C-AGGREGATION-01` are separate unpushed `ReviewedLocalGreen` commits, with `C-CONVERGE-01` next/pure audit; parent scenario held |
| Parent | Owning feature and current subfeature |
| Scenario | [TEST-0210](test-cases.md#test-0210), retained `Planned` |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Ordered-C authority | [Maintainer continuation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5264403013) |
| Accepted predecessor | Merged [PR #177](https://github.com/hasanmanzak/meAndAI/pull/177), exact-main commit [`6ca42f56a48976093692dc4764c464ca185aa964`](https://github.com/hasanmanzak/meAndAI/commit/6ca42f56a48976093692dc4764c464ca185aa964), and [run 31579758253](https://github.com/hasanmanzak/meAndAI/actions/runs/31579758253): Ubuntu `6m22s`, Windows `11m11s`, publication verification skipped |
| Normative owner | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Implementation language | C# only; D, Scenario/workflow activation, release, and publication remain held |

## Authority and non-goals

This plan decomposes only the already accepted ContractSlice C architecture.
Packet labels are operational delivery labels; they allocate no new stable work
or test ID and grant no executable authority merely by appearing here.

ContractSlice C owns the first executable export/kernel activation over a
Tests-owned synthetic complete catalog, the final six registration families,
provider-neutral producer execution, two-phase applicability/evaluation plans,
kernel-minted outputs, and deterministic aggregation. It introduces the exact
eight Abstractions and fifteen Conformance supported types already frozen by
the typed design, taking the supported public total from `72` through B to
`95` through C. Domain gains no export.

ContractSlice C does not own the real Policy export or rule implementations,
Application routing/I/O, live provider integration, Scenario/status/owner or
workflow activation, runtime-efficiency changes, feature DoD, D, merge,
release, or publication. ContractSlice D must freshly repeat the relevant B/C
vectors against the real Policy registrations; no C result is product evidence
for D.

## Frozen dependency graph

```text
merged exact-main B
  -> C-SURFACE-ACTIVATION-01
  -> C-REGISTRATION-MISMATCH-01
  -> C-PRODUCER-PIPELINE-01
  -> C-APPLICABILITY-PLAN-01
  -> C-APPLICABILITY-CLOSURE-01
  -> C-EVALUATION-PLAN-01
  -> C-EVALUATION-ADVANCE-01
  -> C-INTENT-RESULT-01
  -> C-AGGREGATION-01
  -> C-CONVERGE-01
```

Only one mutating packet may be active. A successor red or implementation is
held until its predecessor is locally green, independently reviewed, record-
synchronized, and captured in its own focused local commit. Within one cohort,
that boundary is named `ReviewedLocalGreen`; intermediate package commits are
not pushed and carry no hosted-green claim. A packet-specific freeze may refine
fixtures and exact path allowlists but may not change this topology, Fact
identity, ownership, or downstream holds without renewed design review.

## Frozen delivery cohorts

| Cohort | Ordered packets | Entry gate | Exit state |
| --- | --- | --- | --- |
| Activation | `C-SURFACE-ACTIVATION-01` -> `C-REGISTRATION-MISMATCH-01` -> `C-PRODUCER-PIPELINE-01` | Exact hosted-green design cohort | `ExactHeadHostedGreen` after one cohort push |
| Applicability | `C-APPLICABILITY-PLAN-01` -> `C-APPLICABILITY-CLOSURE-01` | Activation `ExactHeadHostedGreen` | `ExactHeadHostedGreen` after one cohort push |
| Evaluation | `C-EVALUATION-PLAN-01` -> `C-EVALUATION-ADVANCE-01` | Applicability `ExactHeadHostedGreen` | `ExactHeadHostedGreen` after one cohort push |
| Results/closure | `C-INTENT-RESULT-01` -> `C-AGGREGATION-01` -> `C-CONVERGE-01` | Evaluation `ExactHeadHostedGreen` | Slice completion only after final exact-head hosted green |

Each package still owns its canonical expected-red, focused local test, C-
cumulative test through that package, relevant Release build, diff/format and
required structural checks, package-local independent review, record sync, and
one separate focused local commit. The next package in the same cohort may
start only after those gates close as `ReviewedLocalGreen`. No intermediate
package commit is pushed.

At a cohort boundary, run the full C cumulative set, combined ContractSlice A
through the current cohort, full Conformance and Domain tests, relevant Release
builds, format, locks, API/ownership checks, canonical graph/StructureOnly, the
applicable publication-evidence suite, and a full cohort diff review. Only a
green and review-closed cohort pushes its ordered local commit sequence once to
the current PR branch. Its exact head must pass Ubuntu and Windows, with the
publication job taking its designed state, before the next cohort activates.

A hosted failure reopens only that cohort. Use its separate package commits to
identify the owning package, record the identification time, correct that owner,
repeat the entire local cohort validation, and push a new exact head. Work never
continues over a failed cohort. `ReviewedLocalGreen` names an intermediate
package; `ExactHeadHostedGreen` names a pushed cohort; neither name completes C.

## Exact test topology

Every retained C test is one direct non-skipped xUnit `[Fact]` with exactly one
`ContractSlice=C` trait and no `Scenario` trait. Theory, class-level traits,
generic/overloaded methods, inherited facts, and a second slice/Scenario value
are forbidden. The final ordinal LF-terminated inventory contains exactly
eleven FQNs, `1,262` UTF-8 bytes, and SHA-256
`5EA65760A6C0E1B7442686EF9306F0075608A0935E48C484432C5106A444C7E5`:

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceCActivationTests.Activates_exact_synthetic_registration_graph
MeAndAI.Protocol.Conformance.Tests.ContractSliceCAggregationTests.Aggregates_exact_catalog_evaluation_and_verdict
MeAndAI.Protocol.Conformance.Tests.ContractSliceCApplicabilityClosureTests.Closes_applicability_with_exact_terminal_shapes
MeAndAI.Protocol.Conformance.Tests.ContractSliceCApplicabilityPlanTests.Plans_exact_static_applicability_instructions
MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationAdvanceTests.Advances_owner_sharded_evaluation_to_closure
MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round
MeAndAI.Protocol.Conformance.Tests.ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures
MeAndAI.Protocol.Conformance.Tests.ContractSliceCOwnershipTests.Enforces_exact_friend_factory_and_negative_surface
MeAndAI.Protocol.Conformance.Tests.ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph
MeAndAI.Protocol.Conformance.Tests.ContractSliceCRegistrationTests.Rejects_registration_mismatch_without_kernel_activation
MeAndAI.Protocol.Conformance.Tests.ContractSliceCStructuralTests.Matches_exact_cumulative_c_public_surface
```

The first packet owns the Structural, Ownership, and Activation facts. Each
later semantic packet owns one Fact and one immutable BehaviorRed ordinal.
`C-CONVERGE-01` is a pure audit and adds no Fact. The final C count is `11/11`;
cumulative A+B+C/full Conformance becomes `54/54`, while Domain remains `98/98`.

## Packet ledger

| Packet | Frozen contract | Red identity | Required green boundary |
| --- | --- | --- | --- |
| `C-SURFACE-ACTIVATION-01` | Exact 23-type C public surface, cumulative supported total `95`, friend/factory/negative surface, final six-list registration identities, Tests-owned synthetic complete export/proof, and non-null `ConformanceKernel` activation over the exact registration graph | Permanent compile SurfaceRed for `IRuleEvaluator`; canonical `TEST-0210-C-BEHAVIOR-RED-0001`; `ContractSliceCActivationTests.Activates_exact_synthetic_registration_graph` | C `3/3`; A+B+C/full `46/46`; Domain `98/98` |
| `C-REGISTRATION-MISMATCH-01` | Six-family registration/type-token/public-projection bijection; exact missing/extra/duplicate/foreign/wrong-generic/order/proof mismatch classification; failed activation exposes no kernel | `TEST-0210-C-BEHAVIOR-RED-0002`; `ContractSliceCRegistrationTests.Rejects_registration_mismatch_without_kernel_activation` | C `4/4`; full `47/47` |
| `C-PRODUCER-PIPELINE-01` | Exact codec/parser/index/projector/selector/evaluator activation, Kahn order, per-binding/per-context/per-plan invocation, coalescing, input cardinality, cache/ledger ownership, and zero-input producer shapes | `TEST-0210-C-BEHAVIOR-RED-0003`; `ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph` | C `5/5`; full `48/48` |
| `C-APPLICABILITY-PLAN-01` | Named/slice profile rule selection, target-selector resolution, exact static slot/instruction projection, canonical ordering/digests, no provider route data, and plan/session binding | `TEST-0210-C-BEHAVIOR-RED-0004`; `ContractSliceCApplicabilityPlanTests.Plans_exact_static_applicability_instructions` | C `6/6`; full `49/49` |
| `C-APPLICABILITY-CLOSURE-01` | Observed/Failed/NoInput admission into exact outcomes, Complete/Incomplete/Failed independence, context-proof sealing, applicability intents, NotApplicable/Unresolved terminal shapes, cancellation and retry atomicity | `TEST-0210-C-BEHAVIOR-RED-0005`; `ContractSliceCApplicabilityClosureTests.Closes_applicability_with_exact_terminal_shapes` | C `7/7`; full `50/50` |
| `C-EVALUATION-PLAN-01` | Ready Applicable rules, producer-dependent static/projected slots, zero-demand no-I/O path, owner-sharded demand instructions, exact round/order/digest and unresolved predecessor terminalization | `TEST-0210-C-BEHAVIOR-RED-0006`; `ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round` | C `8/8`; full `51/51` |
| `C-EVALUATION-ADVANCE-01` | Projected owner-shard admission, aggregate outcome/proof, index invocation, multi-round monotonic session state, terminal closure, replay/collision/cancellation/host-failure behavior | `TEST-0210-C-BEHAVIOR-RED-0007`; `ContractSliceCEvaluationAdvanceTests.Advances_owner_sharded_evaluation_to_closure` | C `9/9`; full `52/52` |
| `C-INTENT-RESULT-01` | Exact Applicability/Finding/Failure/Evaluation intent factories and validation; kernel-only RuleId/revision/severity/remediation/reference/status minting; Satisfied/Violated/NotApplicable/NotEvaluated closed shapes | `TEST-0210-C-BEHAVIOR-RED-0008`; `ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures` | C `10/10`; full `53/53` |
| `C-AGGREGATION-01` | Canonical acquisition/evaluation ordering, violation/unresolved flags, slice result without verdict, complete-catalog verdict truth table, exact predecessor/catalog profile projection, no report/enforcement authority | `TEST-0210-C-BEHAVIOR-RED-0009`; `ContractSliceCAggregationTests.Aggregates_exact_catalog_evaluation_and_verdict` | C `11/11`; A+B+C/full `54/54`; Domain `98/98` |
| `C-CONVERGE-01` | Pure cumulative source/test/export/friend/trait/project/lock/graph audit; P/R/G `NotApplicable`; no executable change | None; all canonical reds remain immutable and are never rerun | C `11/11`; full `54/54`; Domain `98/98`; build/format/diff/StructureOnly/publication evidence/reviews green |

## Cohort measurement ledger

Measurements are filled from retained local and hosted evidence; estimates are
never promoted to observed facts. The comparison baseline is the same package
sequence with a push and Ubuntu/Windows wait after every package.

| Cohort | Local work and validation | Hosted CI | Hosted defects | Owner identification | Correction and revalidation | Estimated saving vs package-hosted | Consistency/traceability loss |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Activation | `3h10m` measured from the first package commit through the final synchronized exact-tree gate | Ubuntu `22m23s`; Windows `18m57s`; publication skipped | `0` | `NotApplicable` | `NotApplicable` | About `44m46s` of hosted critical-path wait from the two avoided intermediate pushes, using this cohort's `22m23s` longest job as the comparison basis | None observed; the local commit-reference recurrence caught the only record defect before push |
| Applicability | About `63m` active package/validation time | `20m37s` critical hosted duration (`13m46s` Windows) | `0` | `NotApplicable` | `NotApplicable` | About `14-21m` by avoiding a second hosted round | `No`; separate package commits and exact FQN/runner evidence remained intact |
| Evaluation | `1h14m46s` observed Plan-to-Advance commit interval, including package-local validation and final cohort gates | `21m26s` critical hosted duration (`17m52s` Windows) | `0` | `NotApplicable` | `NotApplicable` | About `18-22m` by avoiding a second hosted round | `No`; separate package commits, exact red identities, and traceability remained intact |
| Results/closure | About `44m` from the Intent commit through Aggregation record preparation; final converge validation pending | `NotMeasured` until the single cohort push | `0` locally | `NotApplicable` | One fixture-only zero-demand setup correction was isolated in under `2m` and revalidated in about `3m` | Two intermediate hosted rounds avoided; exact saving finalized after cohort hosted closure | `No`; separate commits, immutable red evidence, and ownership remained traceable |

C closure reports elapsed time, isolation cost, estimated saved time, and any
consistency or traceability loss for these four cohorts separately from D.

The Activation pre-push publication recurrence found two unlinked commit
references in the producer packet's owning ledger. The exact owner was isolated
in `4m01s`; the wording-only correction and package-commit amendment took less
than three additional minutes. This was a local validation defect, not a hosted
defect, and the full cohort validation recurs on the amended exact tree.
The amended tree passed StructureOnly in `449.389s`, publication evidence
`7/7` in `294.077s` without a publication claim, and the canonical graph at
`359/4162/321/4553078` under schema-2 ceilings.
The single cohort push then passed exact-head Ubuntu in `22m23s` and Windows in
`18m57s`; publication verification was skipped and hosted defects were `0`.

## Frozen first-packet allowlist and fixture

`C-SURFACE-ACTIVATION-01` introduces the complete C public surface and all
internal declarations needed for the already-frozen signatures, but exercises
only exact synthetic complete-export activation. The temporary red seam is the
fully prepared valid `ConformanceKernel.Activate(...)` path returning `null!`;
only that semantic null may call direct
`Assert.Fail("TEST-0210-C-BEHAVIOR-RED-0001")`. Construction, structural,
ownership, wrong-result, exception, and mismatch assertions are marker-free.
The next packet, not this red, owns the full mismatch matrix.

The executable allowlist is exact. It modifies the two existing export carrier
files; adds eight C public Abstractions files, six internal registration/seam
files, fifteen C public Conformance files, and one Conformance activation-core
file; adds exactly `ContractSliceCStructuralTests.cs`,
`ContractSliceCOwnershipTests.cs`, and `ContractSliceCActivationTests.cs`; and
modifies `ContractSliceAPublicApiTests.cs` plus
`ContractSliceBStructuralTests.cs` only to remove predecessor-only C-absence
assertions while retaining A export internals and B negative ownership. The B
structural adaptation also turns its exact A+B export equality into a
successor-safe A+B subset proof, while the new C structural Fact owns exact
A+B+C equality. The exact path
inventory is frozen in the typed design. The already-frozen
compile-only `ContractSliceC.SurfaceRed.cs` exists transiently only for its one
CS0246 observation and must be absent from the retained tree; it is not a
fourth C Fact or C ownership surface. No other source or test path may change. Domain,
Policy, Application, workflow, project, package, lock,
Scenario/status/owner, and runtime-efficiency files are immutable. The packet
cap remains at most `52` production paths, exactly `3` new C test paths plus two
bounded predecessor-test adaptations, and `7,000`
normalized changed C# lines; the first value over any threshold redraws before
red. Later packets retain their `10`/`1`/`3,500` defaults.

The synthetic-complete fixture starts from the retained five-rule declaration
data but creates a complete genesis catalog and canonical manifest whose
artifacts are exactly Domain, Conformance.Abstractions, Conformance, Markdig,
and Conformance.Tests. Its twenty-three Policy implementation rows are replaced
by exact Tests-owned component types; the four capability interfaces retain
their Abstractions identities. Five Tests-owned model types and eighteen
object-identical codec/parser/index/projector/selector/evaluator registration
objects form the exact twenty-seven-row partition. The test asserts the public
`Components` ordinal union, all six internal list identities/order, proof call
count, non-null kernel, and catalog projection. It does not test mismatch
variants or invoke producer behavior; those remain the next two packets.

The pre-red runner is a fresh ignored external PowerShell file with
`ValidateOnly` and one `Execute` mode, canonical LF plus terminal LF, frozen
length/SHA/AST, a fresh external result root and atomic JSON report. It binds
the exact hosted design HEAD, branch/upstream/status allowlist, all allowed
source lengths/SHA values, six lock hashes, warning-free Release build, DLL/PDB
identity, and the literal packet-specific command below. Exact Git/status,
source, runner, locks, and binaries are rechecked at start, pre-build, pre-test,
and post-test. Complete stdout/stderr logs are CreateNew regular non-reparse
files capped at `1,048,576` bytes each; overflow or truncation rejects the
oracle. TRX parsing prohibits DTD and external resolution. `ValidateOnly`
creates no root/report/log/build/test artifact. Immediately before the sole
child, `InvocationCommitted` consumes the current packet's frozen canonical R
ordinal; every later process,
timeout, interruption, exit, custody, TRX, or oracle failure is immutable
no-success/no-retry. Only pre-commit preflight/build failure may be corrected
and revalidated under renewed review.

## Canonical expected-red contract

Every BehaviorRed uses one fresh external runner and one fresh external result
root, a warning/error-free Release `--no-restore` build, exact source/runner/
lock/DLL/PDB custody, and exactly one child invocation:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=<marker>.trx" --filter "ContractSlice=C&FullyQualifiedName=<exact-FQN>"
```

No discovery prepass, second logger, fallback, or retry is allowed. The child
receives process-scoped `VSTEST_CONNECTION_TIMEOUT=300` and one `420000` ms
outer monotonic bound. Once `InvocationCommitted` is persisted immediately
before process creation, that ordinal is consumed even by process-create,
timeout, interruption, unexpected-exit, TRX, custody, or oracle failure.

Canonical red requires native exit `1`, runner exit `0`, one exact regular TRX,
one Failed result/definition/entry at the exact FQN, referential ID bijection,
exact marker-only Message, marker count exactly two with only the permitted
same-result standard-output echo, at most one permitted marker-free same-FQN
`[FAIL]` RunInfo, exact sixteen counters with total/executed/failed `1/1/1`
and every other counter `0`, secure XML parsing, no attachment/collector/
independent diagnostic, and unchanged source/Git/binary identities. A valid
red is immutable; green replaces only the predeclared semantic null/absent
behavior in the same uncommitted red-to-green operation.

## Design and graph cohort

The initial design cohort is exactly these twelve Markdown paths:

```text
.ai/memory/README.md
.ai/memory/log/2026-08-12-feat-0065-subf-0143-contractslice-c-design-freeze.md
.ai/memory/log/README.md
.ai/memory/project.md
docs/architecture/protocol-governance-and-execution/README.md
docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md
docs/architecture/protocol-governance-and-execution/transition-register.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-contractslice-c-micro-delivery-plan.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md
docs/features/README.md
```

It adds exactly two tracked record nodes: this plan and the one C design
ledger. The ledger remains the sole detailed C routing/evidence handoff and is
bounded to `400` lines, at most `16` Markdown links, and at most `4` repository-
relative links. These C-only ceilings accommodate immutable per-package and
per-cohort evidence without changing any general protocol limit. All other
status edits are edge-neutral where possible. The
schema-2 hard ceilings remain `512` nodes, `8,192` relations, `1,048,576` bytes
per parsed blob, and `8,388,608` aggregate parsed bytes; the exact design tree
must pass the canonical builder/validator and retain at least `2 KiB` per-blob
and aggregate headroom before commit.

## Design-delivery gates

Before any C# mutation or canonical red:

- the exact twelve-path design cohort passes diff/stable-ID/link/table/fence
  checks, publication evidence including the fresh commit-reference recurrence,
  StructureOnly, graph limits, and independent design/content reviews with
  `0 Blocking / 0 Important / 0 Minor`;
- the cohort is committed and pushed from the clean C branch, with the NCrunch
  user file excluded;
- that exact design commit passes Ubuntu and Windows hosted validation while
  publication verification is skipped; and
- the first packet receives a packet-specific exact path/fixture/runner freeze
  and renewed clean review before its one canonical red.

For `C-REGISTRATION-MISMATCH-01`, the exact predecessor is unpushed local commit
[`8812b22c7cc8a1785d24376f3e91a20fb0fe6cc0`](https://github.com/hasanmanzak/meAndAI/commit/8812b22c7cc8a1785d24376f3e91a20fb0fe6cc0).
Its four-path executable allowlist
is `KernelActivationCore.cs`, `CatalogSliceKernel.cs`, the fixture-only
adaptation in `ContractSliceCActivationTests.cs`, and the new owning
`ContractSliceCRegistrationTests.cs`; the cap is two production paths, two test
paths, and `1,800` normalized changed C# lines. The typed design owns the exact
six-family declaration/order/multiplicity/generic/projection matrix, proof
precedence, null-only red seam, and no-kernel failure boundary. No other path or
later semantic behavior is admitted.

No design-only success changed C from `0/11`; only the reviewed-local-green
surface packet moves C to `3/11`. It does not activate [TEST-0210](test-cases.md#test-0210),
or lifts D/Scenario/workflow/DoD/merge/release/publication holds.

`C-REGISTRATION-MISMATCH-01` accepted immutable canonical R=0004 and then
closed the exact six-family registration/type-token/component projection matrix
locally. Focused `1/1`, C `4/4`, full Conformance `47/47`, Domain `98/98`,
warning-free Release build, format/diff, and StructureOnly `429.279s` are green;
three independent review dimensions closed `0/0/0`. The packet is
`ReviewedLocalGreen`, has no push/hosted claim, and consumed about `28` minutes
from first C# mutation through final structural validation. No consistency or
traceability loss was observed. Producer-pipeline is next only after the
registration packet's separate local commit.

### Frozen `C-PRODUCER-PIPELINE-01` packet boundary

Retained negative registration fixtures outside this packet's two-test-path
allowlist compile only through the final operation interfaces' fail-closed
`NotSupportedException` defaults. The exact eighteen canonical fixture objects
override those operations on the same registered identities; this packet's Fact
proves those concrete operations are callable and no default is executable.

At that packet checkpoint the predecessor was the separate local registration
commit; it was unpushed and carried no hosted claim. The sole Fact is
`ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph`,
with only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0003`. Canonical R=0005 replaces only the fully
prepared valid kernel producer graph with `null!`; only that null reaches the
marker. Unexpected construction, activation, component, invocation, resource,
or assertion failures remain marker-free.

The packet adds the final callable members and already accepted carrier shapes
to the existing codec/parser/index/projector/selector identities; it creates no
adapter, direction-specific registration, second scheduler, Policy component,
provider route, or I/O seam. Activation owns all `3/2/4/1/3/5` registration
rows and the exact ten-node Schema/Parser/Index/Projector producer DAG; selectors
and evaluators are validated activation rows, not DAG nodes. The graph owns
declaration/binder/type closure, deterministic Kahn order,
per-binding/per-context/per-plan expansion, alias coalescing, declared
cardinality, the zero-binding/zero-input cases, and Conformance-owned resource
allowance/ledger handles. Later applicability/evaluation packets own live plan
state, provider admission, retries, evaluation rounds, and result minting.

The exact executable allowlist is:

```text
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/CodecRegistration.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/ProducerRegistrationContracts.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/SemanticResourceContracts.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/ProducerHandleContracts.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/CanonicalPayloadWriteContracts.cs
src/MeAndAI.Protocol.Conformance.Abstractions/Registration/ProducerIntentContracts.cs
src/MeAndAI.Protocol.Conformance/Activation/CatalogSliceProducerGraph.cs
src/MeAndAI.Protocol.Conformance/Activation/KernelActivationCore.cs
src/MeAndAI.Protocol.Conformance/Activation/CatalogSliceKernel.cs
src/MeAndAI.Protocol.Conformance/Activation/ConformanceKernel.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCActivationTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCProducerPipelineTests.cs
```

The first two, activation core/both kernels, and retained activation test are
modified rather than replaced; the five new contract/runtime files group only
the accepted final internal declarations. Exactly `10` production/Abstractions
paths, exactly the retained activation test plus one new C test, and at most
`3,500` normalized changed C# lines are permitted. The first extra path or line
redraws before red. Domain, Policy, Application, projects, packages, locks,
workflows, Scenario/status/owner, runtime efficiency, D, merge, release, and
publication are immutable.

The packet-specific child command specializes the generic canonical-red
template exactly as follows:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0003.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph"
```

One new fresh external runner specializes the common custody contract to the
exact twelve-path source allowlist, current HEAD/upstream/branch/status, six
locks, warning-free build, fresh DLL/PDB, one fresh result root, one child, and
canonical R=0005. The fully prepared valid seam is the synthetic complete
`ConformanceKernel` producer graph; the slice kernel receives the same graph
state in green. `InvocationCommitted` irrevocably consumes R=0005 for process-
create, timeout, interruption, unexpected exit, missing/malformed/extra TRX,
custody, or oracle failure; no changed or unchanged retry is permitted.

Green requires focused `1/1`, C `5/5`, full Conformance `48/48`, Domain
`98/98`, warning/error-free Release build, format/diff/locks, required
structure, package-local code/evidence/traceability reviews, record sync, and a
third separate unpushed local commit. The Activation cohort then runs its full
cohort boundary and is pushed once; applicability cannot activate before that
exact head is Ubuntu/Windows hosted green.

Canonical producer R=0005 is accepted/immutable and never rerun. Its fresh
runner is `41,565` bytes/SHA-256 `CD92BAD1...D82169B`; the report is `18,126`
bytes/SHA-256 `5563029B...E4E992`, and the sole `4,908`-byte TRX is SHA-256
`2E55C738...34AF2`. Native/runner exits are `1/0`; the one Failed
result/definition/entry has marker count `2`, exact failed counters, all other
thirteen counters zero, and no attachment/collector evidence. Green is focused
`1/1`, C `5/5`, full Conformance `48/48`, Domain `98/98`, build `0/0`, clean
format/diff, StructureOnly green in `434.832s`, and
code/evidence/traceability reviews `0/0/0`. At that packet checkpoint it was
`ReviewedLocalGreen`; the later cohort closure below owns its hosted claim.

## Frozen `C-APPLICABILITY-PLAN-01` packet boundary

The exact predecessor is the Activation cohort's hosted-green head owned by the
C evidence ledger. This packet does not alter the accepted rule catalog,
profile declarations, packet order, FQN, marker, or ownership. Its one direct
Fact is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCApplicabilityPlanTests.Plans_exact_static_applicability_instructions`,
with only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0004`. Canonical R=0006 changes only the fully
prepared valid complete-kernel `ApplicabilityPlan` result to `null!`; only that
null reaches the marker. Setup, target/profile validation, instruction/digest
checks, and every negative remain marker-free.

The production manifest's five accepted rules intentionally declare no
applicability-phase slots. The complete named Provider profile therefore
selects RULE-0003, RULE-0004, and RULE-0005 but exposes exact empty `Slots` and
`Instructions`; the slice Repository profile selects RULE-0001 through
RULE-0005 and exposes the same exact empty projection. This is the accepted
catalog-universal applicability shape, not a missing implementation. The
packet also implements the already frozen internal applicability-instruction
factory for future valid non-empty catalogs, using phase rank `0`, round `0`,
the canonical none-demand frame, and the exact instruction frame; no caller
supplies either digest.

The complete fixture resolves the release-declared named profile
`protocol.profile.consumer-provider-exact-commit-conformance-audit`. Its axes
are Consumer/Conformance/ExactCommit/Provider/Audit and its RuleIds are the
object-identical catalog RULE-0003..0005 rows. Its target input is deliberately
reversed and canonicalizes to one Repository support target followed by one
Provider target under schema surface order. Both share subject identity `repo`
and ExactCommit. Their target identity is the separator-free ordinal
concatenation of `0123456789abcdef`, `0123456789abcdef`, and `01234567`;
Repository has
source `repo`, Provider has source `github`. The slice fixture uses
Consumer/Conformance/ExactCommit/Repository/Audit and exactly the Repository
target. Plans retain the exact profile axes, selected catalog rule objects,
canonical targets, authority kind, manifest digest, and one opaque kernel/
session stamp. They contain no route, adapter, provider DTO, I/O, clock, or
Application authority.

Target input is enumerated once, copied, and must be structurally unique. All
targets share exact SubjectIdentity, SnapshotKind, and TargetIdentity. The
required target set is derived across every profile-active applicability and
evaluation slot of the selected rules, including repository support for a
Provider profile; unknown selector keys, missing/extra/duplicate/null targets,
zero/multiple selector matches, inconsistent identity, wrong surface or
snapshot, and noncanonical profile/rule/session use are
`CatalogIntegrityException(PlanStateInvalid)`. Input order never breaks a tie.
An equal-looking caller-created `NamedExecutionProfile`, a profile from another
kernel, or repeated/stale cross-kernel substitution is rejected. Argument nulls
retain their argument exceptions.

The exact executable allowlist is:

```text
src/MeAndAI.Protocol.Conformance/Activation/CatalogSliceKernel.cs
src/MeAndAI.Protocol.Conformance/Activation/ConformanceKernel.cs
src/MeAndAI.Protocol.Conformance/Catalog/NamedExecutionProfile.cs
src/MeAndAI.Protocol.Conformance/Planning/AcquisitionInstruction.cs
src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityPlan.cs
src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityPlanningCore.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCActivationTests.cs
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceCApplicabilityPlanTests.cs
```

These are at most six production paths and two C test paths, with at most
`2,400` normalized changed C# lines. `ApplicabilityPlanningCore.cs` is the sole
new production file and the owning Fact is the sole new test file. No export,
registration, producer graph, Domain, Policy, Application, project, package,
lock, workflow, Scenario/status/owner, runtime-efficiency, D, release, or
publication file may change. The first extra path or line redraws before red.

The packet-specific child command is the generic C canonical-red command with
the exact marker/FQN above, Release, `--no-restore --no-build --nologo`, minimal
verbosity, one fresh result root, and one TRX logger. A fresh external runner
must bind exact HEAD/upstream/branch/status, this eight-path source allowlist,
six locks, warning-free build, fresh DLL/PDB, one child, exit `1`, secure exact
one-result TRX, marker-only error message, sixteen counters, and no attachment/
collector evidence. `InvocationCommitted` irrevocably consumes R=0006; no
changed or unchanged retry is permitted after process creation, timeout,
interruption, unexpected exit, custody, TRX, or oracle failure.

Green requires focused `1/1`, C `6/6`, full Conformance `49/49`, Domain
`98/98`, warning/error-free Release build, format/diff/locks, package-local
structure and code/evidence/traceability reviews, record sync, and one separate
unpushed local commit named `ReviewedLocalGreen`. Applicability closure cannot
start before that commit. The two-package Applicability cohort receives no push
until its complete cohort boundary is green.

Fresh packet-design, evidence/scope, and traceability reviews close `0/0/0`.
The first frozen runner attempt R=0006 produced the exact behavior-red TRX but
was correctly rejected because one stale predecessor method-name oracle caused
`TRX identity/bijection mismatch.` R=0006 is immutable diagnostic/no-success
and never reruns. Corrected R=0007 changes only that predicate and freezes at
`42,368` bytes / SHA-256
`9EA4B00ADCF91B8CE2CB49F6FA9BD24005B5521E15411F996262C72AE67DD19F`,
AST `6,038` tokens / `0` errors. Corrected head `d251b377...c044` passed exact
hosted validation and the sole R=0007 was accepted with report SHA-256
`6DA8C76C...2384` and TRX SHA-256 `DC1A4426...8250`; native/runner exits were
`1/0`. Green is focused `1/1`, C `6/6`, full Conformance `49/49`, Domain
`98/98`, Release build `0/0`, format/diff/locks/StructureOnly and reviews
green. The packet is `ReviewedLocalGreen` in its separate local commit. At that
packet checkpoint closure was next/`FrozenDesign`, and the Applicability cohort
had not been pushed or claimed hosted green.

### `C-APPLICABILITY-CLOSURE-01` reviewed-local-green boundary

The packet changes exactly the two kernel delegations, the existing planning
session, one new closure core, one bounded activation-fixture adaptation, and
one owning closure Fact. It admits Observed/Failed/NoInput outcomes, independent
Complete/Incomplete/Failed acquisition status, sealed ContextProof references,
NotApplicable/Unresolved terminals, cancellation retry, and single-success
atomicity without activating evaluation rounds, real Policy, provider I/O, or
any held Scenario/workflow surface. Its normalized cap is `1,400` changed lines
with the owning test capped at `600`.

R=0008 stopped marker-free at fixture component registration mismatch; R=0009
stopped marker-free when the provider-profile fixture omitted repository-tree;
R=0010 stopped marker-free at admission-proof component reference closure.
Each is immutable diagnostic/no-success/no-retry. Corrected R=0011 is the sole
accepted expected-red: runner `42,757` bytes / SHA-256
`251A98B8C9BC86C812C0B30F4B5CC27DB0282BE5A2C2C63BBFEB70B45B2A297B`,
AST `6,131/46/0`, native/runner `1/0`, report SHA-256
`B6C4F18B345C60C13C0B5A45B5147A240F6FAC8B3BCBEC9FA2D9746564F1E9D2`,
and TRX SHA-256
`1711DFC8F13036B38696EBCF1FF61CD748CF4AE458E93A6699D3E1CACBA8133D`.
Green is Release build `0/0`, focused `1/1`, C `7/7`, full Conformance `50/50`,
Domain `98/98`, format/diff/locks green, StructureOnly `452.313s`, publication
evidence `7/7` in `305.7s` with no publication claim, and `1,052/1,400` plus `422/600`.
Code/evidence/traceability reviews close `0/0/0`; the three diagnostic owners
were isolated in under four minutes each, corrected/revalidated in about
`7m/5m/4m`, and caused no consistency or traceability loss. This packet is
`ReviewedLocalGreen` in its own local commit. The Applicability cohort then
passed its full local boundary and exact-head hosted run `31635734392` at the
exact identity owned by the canonical C ledger: Ubuntu `20m37s`, Windows
`13m46s`, publication skipped, and zero hosted defects.

## Frozen `C-EVALUATION-PLAN-01` packet boundary

The sole Fact/FQN remains
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round`,
with only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0006`. The fixture owns one ready Applicable rule
whose evaluation slots cover: one already admitted shared repository-tree slot,
one static repository-governed-text instruction, and one projected repository-
target slot. The Tests-owned projector deterministically returns three canonical
items over owners `alpha`, `alpha`, `omega`; planning emits no instruction for
the admitted slot, one none-demand static instruction, and two owner-sharded
projected instructions ordered by SlotKey, target, owner, then first ItemId.
A Tests-owned candidate visitor fixes the three selector tuples before red:
ItemId `0` is owner `alpha`, CommitObject
identity of forty `1` digits, path `docs/a.md`, no fragment;
ItemId `1` is owner `alpha`, TagRoot `v1.0.0`; ItemId `2` is owner `omega`,
CapturedSnapshotPath capture `capture-1`, path `docs/b.md`, fragment `L1-L2`,
expected content identity of sixty-four `2` digits. Candidate input permutations
must reproduce the identical public item order, demand frames, and digests.
A second empty-projector fixture proves zero projected instruction and no
external proof/I/O while preserving the ready static instruction. A predecessor
with unresolved applicability terminalizes that rule and emits no evaluation
instruction.

R changes only the fully prepared valid `PlanEvaluation(closure)` return to
`null!`; only that null reaches the marker. Foreign/stale/reused closure,
cancellation, wrong ordering/digest/round, zero-demand, and unresolved paths are
marker-free. Canonical R=0012 executed once but was rejected marker-free because
the fixture terminalized the rule and returned `EvaluationClosure`; it is an
immutable diagnostic/no-success/no-retry. R=0013 reached the marker and passed
its TRX oracle, but immediate green exposed the fixture's positional
applicability/evaluation-slot substitution; it is also immutable diagnostic/no-
success/no-retry. Corrected R=0014 retained the same semantic seam, executed
once after its exact correction head became hosted green, and is now accepted/
immutable. Green restored only the semantic result and passed focused `1/1`, C
`8/8`, full Conformance `51/51`, Domain `98/98`, Release build `0/0`, format/
diff, locks, StructureOnly, publication evidence, reviews, and record sync. The
packet is `ReviewedLocalGreen` only in its separate unpushed local commit;
Evaluation Advance is separately `ReviewedLocalGreen` in the same unpushed
cohort. R=0015 is accepted/immutable; its bounded green is focused `1/1`, C
`9/9`, full Conformance `52/52`, and Domain `98/98`. Results/closure remains
held until the full Evaluation cohort gate, single push, and exact-head hosted
green.

The executable allowlist is exact: modify
`Activation/ConformanceKernel.cs`, `Activation/CatalogSliceKernel.cs`,
`Planning/ApplicabilityPlanningCore.cs`, `Planning/AcquisitionInstruction.cs`,
and `ContractSliceCApplicabilityClosureTests.cs`; add
`Planning/EvaluationPlanningCore.cs` and
`ContractSliceCEvaluationPlanTests.cs`; modify
`ContractSliceCProducerPipelineTests.cs` only to make its existing Tests-owned
projector instance deterministic/configurable. No Abstractions/Domain/Policy/project/
package/lock/workflow file changes. The normalized cap is `1,900` changed lines,
with the owning test capped at `650`; `1,901` or `651` requires redraw. The
packet uses the common fresh external ValidateOnly/Execute runner contract,
one Release `--no-restore` build, one exact `--no-build` child filtered to the
FQN, TRX `TEST-0210-C-BEHAVIOR-RED-0006.trx`, `VSTEST_CONNECTION_TIMEOUT=300`,
a `420s` outer bound, exact native exit `1`, and immutable no-retry authority
after `InvocationCommitted`.

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0006.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round"
```

This packet-specific argv supersedes the generic red template for diagnostic
R=0012/R=0013 and corrected R=0014; each ordinal owns a distinct fresh runner/
report/root identity, and no prior ordinal is rerun.
The design cohort changes exactly the existing twelve C live-route records, no
new record node, and no product/test/project/lock/workflow path. Fresh design,
evidence/scope, and traceability reviews plus schema-2 graph validation must be
`0/0/0` before its focused records commit and single hosted design-gate push.

## Frozen `C-EVALUATION-ADVANCE-01` packet boundary

The sole Fact/FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationAdvanceTests.Advances_owner_sharded_evaluation_to_closure`,
with only `ContractSlice=C`, no Scenario, and marker
`TEST-0210-C-BEHAVIOR-RED-0007`. It consumes exactly the kernel-issued round-0
plan once, admits one complete proof per instruction by exact instruction
digest, retains one static outcome, aggregates the two owner-sharded projected
attempts into one repository-target outcome, invokes the registered target
index once after aggregate completion, and returns a round-1 closure whose
context contains the three canonical C evaluation slots. Empty projected
demand still produces one zero-attempt Complete projected outcome and one
index invocation; it never manufactures an external acquisition instruction.

Replay, foreign plan, missing/extra/colliding proof, and successful no-progress
routes fail at their owning integrity boundary. Cancellation before entry and
a Tests-owned index host exception commit no state and leave the exact
predecessor retryable; a successful retry consumes it once. The schema-1 graph
closes after this advance and emits no empty or second plan. Later intent/result
and aggregation packets retain all rule-evaluation/result ownership.

R changes only the fully prepared valid `AdvanceEvaluation(plan, proofs)`
result to `null!`; only that semantic null reaches the marker. All negative,
retry, zero-demand, index, construction, and assertion paths are marker-free.
The packet-specific command is:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0007.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCEvaluationAdvanceTests.Advances_owner_sharded_evaluation_to_closure"
```

It uses a fresh external ValidateOnly/Execute runner, one warning-free Release
`--no-restore` build, one exact `--no-build` child, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, a `420s` monotonic outer bound, exact native
exit `1`, secure single-TRX marker oracle, source/binary/lock/status custody,
and irreversible no-retry authority after `InvocationCommitted`.

The exact executable allowlist modifies
`Activation/CatalogSliceKernel.cs`, `Activation/ConformanceKernel.cs`,
`Planning/ApplicabilityClosureCore.cs`, `Planning/ApplicabilityPlanningCore.cs`,
`Planning/EvaluationPlanningCore.cs`, `ContractSliceCActivationTests.cs`,
`ContractSliceCEvaluationPlanTests.cs`, and
`ContractSliceCProducerPipelineTests.cs`; it adds
`Planning/EvaluationAdvanceCore.cs` and
`ContractSliceCEvaluationAdvanceTests.cs`. No Abstractions, Domain, Policy,
project/package/lock/workflow file changes are allowed. The normalized cap is
`1,200` changed lines and the owning test cap is `260`; `1,201` or `261`
requires redraw. Package green is focused `1/1`, C `9/9`, full Conformance
`52/52`, Domain `98/98`, Release/format/diff/locks/structure/reviews/record sync
green, followed by one separate unpushed `ReviewedLocalGreen` commit. Only then
does the Evaluation cohort run its full boundary and perform its single push.

The two Evaluation commits remained separate and the cohort is immutable
`ExactHeadHostedGreen` at
[`18a8e3fa28160ec2e622752005b964e0ca98b838`](https://github.com/hasanmanzak/meAndAI/commit/18a8e3fa28160ec2e622752005b964e0ca98b838).
[Run 31660382684](https://github.com/hasanmanzak/meAndAI/actions/runs/31660382684)
passed Ubuntu in `21m26s` and Windows in `17m52s`; publication was skipped and
no hosted defect occurred. The Plan-to-Advance commit interval was `1h14m46s`,
an estimated `18-22m` package-hosted round was avoided, and no consistency or
traceability loss was observed.

## Frozen `C-INTENT-RESULT-01` packet boundary

This Results/closure predecessor became `ReviewedLocalGreen` in its separate
unpushed commit after the corrected twelve-record design cohort became
exact-head hosted green. At that packet checkpoint, `C-AGGREGATION-01` was the
sole next frozen packet and could not start before the focused intent commit.
The intent packet's one direct Fact/FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures`,
with only `ContractSlice=C`, no Scenario/Theory/class trait, and marker
`TEST-0210-C-BEHAVIOR-RED-0008`.

The internal, pure, idempotent seam is exactly
`EvaluationIntentCore.Mint(EvaluationClosure closure, CancellationToken
cancellationToken)`. It validates the closure's plan-bound session, catalog,
manifest, terminal/ready partition, exact evaluation-slot outcome set, and
registered evaluator identity; it creates one opaque handle for each retained
complete context proof. A rule with any Incomplete/Failed evaluation outcome is
minted `NotEvaluated` with the ordinal unresolved slot keys and is not invoked;
otherwise the core invokes its evaluator once in RuleId/revision order,
validates its intent, and alone mints `RuleFinding`,
`RuleEvaluationFailure`, and `RuleEvaluation`. It does not consume the planning
session: `C-AGGREGATION-01` owns the later atomic public-kernel consumption.
Cancellation before return and any evaluator host exception produce no result
or committed state.

All `ApplicabilityIntent` factories snapshot a unique handle sequence;
`.NotApplicable` and `.Unresolved` additionally retain the existing non-empty
rule. `FindingIntent.Create` and
`EvaluationFailureIntent.Create` snapshot the caller sequence,
reject a null/duplicate handle, and reject the primary handle repeated as
related. `EvaluationIntent.Create` snapshots both lists and rejects duplicate
semantic finding or failure tuples. The core maps a foreign/stale closure,
missing/duplicate outcome, terminal/ready partition mismatch, or Complete
outcome without proof to `CatalogIntegrityCode.PlanStateInvalid`. It maps null
intents, foreign/unknown handles, unknown codes, disallowed finding primary/
related kinds, duplicate intent tuples, or evaluator-registration mismatch to
`CatalogIntegrityCode.IntentInvalid`.
Reference and result ordering is ordinal by code and then the full qualified-
reference tuple; output evaluations are RuleId/revision ordered.

The exact Tests-owned fixture starts from `evaluationReady: true`. Its cloned
synthetic profile has the exact `Repository+Provider` surface union so all five
fixture rules remain compatible with their accepted declarations; real Policy
profiles remain unchanged. RULE-0001
returns no intent items and becomes `Satisfied`; RULE-0002 returns exact
finding `protocol.decision.record-missing` over the admitted repository-tree
context proof and becomes `Violated`;
RULE-0003 remains terminal `NotApplicable`; RULE-0004 remains terminal
applicability-unresolved `NotEvaluated`; RULE-0005 returns exact declared
failure `protocol.evaluator.reference-ambiguity` over that proof and becomes
`NotEvaluated` while retaining no unresolved slot. The cloned synthetic
RULE-0002 declaration preserves that finding's severity/remediation and permits
`ContextProof` as its primary kind solely
for this project-neutral fixture; no production or real Policy declaration is
changed. A second acquisition-incomplete variant proves evaluator suppression
and ordinal unresolved-slot ownership. The Fact proves all four status shapes,
exact rule identity,
severity/remediation/reference projection, defensive snapshots, deterministic
repeat output, cancellation, host exception, and the complete invalid matrix.
Expected-selector resolution, real capabilities, real Policy evaluators,
aggregation/verdict, and session consumption remain held for their owning
packets/D.

The Tests-owned callback seam is exact: `RuleEvaluatorMirror` stores optional
applicability and evaluation delegates, checks the passed token in both methods,
and defaults evaluation to `EvaluationIntent.Create([], [])`; each five derived
mirror constructors forwards those two optional delegates. Activation
`CreateFixture` and applicability-closure `CreateFixture` accept an optional
ordinal RuleId-value-to-evaluation-delegate dictionary, reject unknown keys,
and bind each callback only to its object-identical registration. No production
factory or delegate seam is added.

The sole R=0016 invocation is immutable diagnostic/no-success. Its exact test
failed before the prepared `Mint` seam because the synthetic named profile was
Provider-only while RULE-0001/RULE-0002 were Repository-scoped. The sole TRX
therefore contained zero marker occurrences and the exact setup exception
`A named profile must contain exactly its compatible rules. (Parameter
'profiles')`; R=0016 is never rerun or reused as product evidence.

Corrected canonical R=0017 changes only the fully prepared valid `Mint` result
to `null!`; only that semantic null reaches the marker. Setup, invalid-intent,
cancellation, exception, repeat, order, and assertion paths are marker-free.
The packet-specific child argv is:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0008.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures"
```

It uses the common fresh external ValidateOnly/Execute runner: exact source,
runner, HEAD/upstream/status, six locks, warning-free Release build, rebuilt
DLL/PDB, fresh root, secure one-TRX result/definition/entry and 16-counter
oracle, process-scoped `VSTEST_CONNECTION_TIMEOUT=300`, `420s` monotonic outer
bound, and exact native exit `1`. `InvocationCommitted` irrevocably consumes
R=0017 for process-create failure, timeout, unexpected exit, interruption,
missing/malformed/extra TRX, or oracle rejection; no retry or replacement is
authorized. Only pre-commit validation/build failure may be corrected under a
newly reviewed runner state.

The exact executable allowlist modifies
`Evaluation/ApplicabilityIntent.cs`, `Evaluation/FindingIntent.cs`,
`Evaluation/EvaluationFailureIntent.cs`, and `Evaluation/EvaluationIntent.cs`
in Conformance.Abstractions; adds
`Evaluation/EvaluationIntentCore.cs` in Conformance; modifies
`ContractSliceCActivationTests.cs` and
`ContractSliceCApplicabilityClosureTests.cs`; and adds
`ContractSliceCIntentTests.cs`. No other source/test path and no Domain,
Policy, public API, project/package/lock/workflow file may change. The normalized
packet cap is `2,400` changed lines and the owning test cap is `900`; `2,401`
or `901` requires redraw. Package green is focused `1/1`, C `10/10`, full
Conformance `53/53`, Domain `98/98`, Release/format/diff/locks/structure/reviews
and record sync green, then one separate unpushed `ReviewedLocalGreen` commit.
That focused commit activated `C-AGGREGATION-01` inside the same Results/closure
cohort.

The design cohort allowlist is exactly
[memory index](../../../.ai/memory/README.md),
[project memory](../../../.ai/memory/project.md),
[memory log index](../../../.ai/memory/log/README.md),
[C evidence ledger](../../../.ai/memory/log/2026-08-12-feat-0065-subf-0143-contractslice-c-design-freeze.md),
[architecture record](../../architecture/protocol-governance-and-execution/README.md),
[successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md),
[transition register](../../architecture/protocol-governance-and-execution/transition-register.md),
[feature record](README.md), this micro-plan,
[typed design](subf-0143-typed-evaluation-kernel-design.md),
[test cases](test-cases.md), and the [feature index](../README.md). It adds no
node, executable source, project, package, lock, or workflow surface. Fresh
design, evidence/scope, traceability, schema-2 graph, StructureOnly, and
publication-evidence gates must pass before its focused commit, single push,
and exact-head hosted design gate.

Corrected design head [`01ac59bf72226493e0d929ce7c681b7160073abd`](https://github.com/hasanmanzak/meAndAI/commit/01ac59bf72226493e0d929ce7c681b7160073abd)
passed exact-head Ubuntu/Windows validation with publication verification
skipped. Canonical R=0017 is accepted and immutable: its sole child exited `1`,
the runner exited `0`, and the exact one-result TRX passed the frozen marker,
identity, counter, diagnostic, attachment, source, binary, lock, and custody
oracles. The bounded green source is `896/2,400` changed lines and its owning
test is `299/900`; focused `1/1`, C `10/10`, full Conformance `53/53`, Domain
`98/98`, warning/error-free Release build, format, locks, and diff are green.
Exact artifact hashes and final package-local structural/review evidence are
owned by the C evidence ledger. R=0017 is never rerun, and no package-hosted
claim is made.

## `C-AGGREGATION-01` reviewed-local-green evidence

The focused Intent commit exists at exact local head
[`414a7d00f7fb8d5ae3ee81ee327c5b75be7f3216`](https://github.com/hasanmanzak/meAndAI/commit/414a7d00f7fb8d5ae3ee81ee327c5b75be7f3216).
Aggregation then adds only the internal `EvaluationAggregationCore`, threads
the exact issued closure/profile through the existing kernel session, and makes
the public slice and complete `Evaluate` methods delegate to that one core. A
successful call consumes the closure once; cancellation, validation failure,
or host failure before commit leaves it retryable. Result collections remain
defensive snapshots in canonical acquisition/evaluation order. Slice output has
no verdict. Complete output is `Indeterminate` when any required evaluation is
unresolved, otherwise `NonConforming` when any rule is violated, otherwise
`Conforming`; neither path mints a report or enforcement decision.

The packet owns one direct Fact/FQN,
`MeAndAI.Protocol.Conformance.Tests.ContractSliceCAggregationTests.Aggregates_exact_catalog_evaluation_and_verdict`,
with only `ContractSlice=C`, no Scenario/Theory/class trait, and marker
`TEST-0210-C-BEHAVIOR-RED-0009`. R=0018 changed only the fully prepared valid
complete evaluation return to `null!`; only that semantic null reached the
marker. The exact child argv was:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj --configuration Release --no-restore --no-build --nologo --verbosity minimal --results-directory "<fresh-root>" --logger "trx;LogFileName=TEST-0210-C-BEHAVIOR-RED-0009.trx" --filter "ContractSlice=C&FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.ContractSliceCAggregationTests.Aggregates_exact_catalog_evaluation_and_verdict"
```

The exact executable allowlist modifies the two kernels, two evaluation result
carriers, applicability planning core, evaluation advance core, applicability-
closure and intent fixtures; it adds `EvaluationAggregationCore.cs` and the
aggregation Fact. No Abstractions, Domain, Policy, public API, project/package/
lock/workflow file changes. The captured pre-red budget was `579/2,400`
normalized changed lines and `268/900` owning-test lines.

Fresh runner `43,245` bytes / SHA-256
`BBDF57B940B3ACA2A7537ECA3D64B2E68EC9E65D18325FEC36E3DF90870F9C19`
passed ValidateOnly and its sole Execute. Report SHA-256 is
`02479BEA8AD9F6DA8E7341AC3CEF392ABF2D1C0C4FF9C98490EAC43BAA6E24B3`;
sole TRX is `4,838` bytes / SHA-256
`D164AC28CA286D96A6D2AB4CE598B596DF7366F736B416CFE5DE04858567920E`.
Native/runner exits were `1/0` in `2,304ms`; exact result/definition/entry,
marker, optional stack/stdout/RunInfo, sixteen counters, source/binary/lock/root,
and zero-attachment/collector oracles passed. R=0018 is immutable and never
reruns.

Green is focused `1/1`, C `11/11`, full Conformance `54/54`, Domain `98/98`,
warning/error-free Release build, format, six locks, and diff-check. A first
focused green exposed only a zero-demand fixture with no applicability scope;
ownership was isolated in under `2m`, the canonical non-empty candidate set was
restored, and revalidation cost about `3m`. Preliminary StructureOnly passed in
`487.011s`; publication evidence passed `7/7` in `321s` with no publication
claim. Exact-tree recurrences and final reviews remain the focused commit gate.
No package push or hosted claim exists. `C-CONVERGE-01` is next and may change
only the twelve records, with P/R/G `NotApplicable` and no executable delta.

## Deferred ContractSlice D cohort plan

D is not activated and no final D package/cohort membership is frozen here.
Only after C completes its final convergence, record synchronization, merge,
and exact-main hosted predecessor may a separate D micro-delivery plan use the
observed C cohort measurements. Its pre-D D/RT and micro-plan review must freeze
the accepted dependency graph into approximately two-to-four-package cohorts
while keeping these semantic boundaries separate: real Policy export and
registration activation; real codec/parser/index/projector infrastructure;
RULE-0001 plus RULE-0002; RULE-0003 through RULE-0005 with specialization and
co-report behavior; repository/provider equivalence plus D-CONVERGE. Distinct
expected-red or ownership boundaries may not be merged for speed.

D must use fresh fixtures and tests against real Policy registrations to repeat
the accepted B/C behaviors. C results inform delivery estimates only and are
not D product evidence. D uses the same package-local commit, cohort-local full
validation, single-push, exact-hosted, failure-reopen, status, and measurement
rules. Its closure reports cohort timing, isolation, savings, and consistency
separately, without activating Scenario/workflow/consumer/release scope.
