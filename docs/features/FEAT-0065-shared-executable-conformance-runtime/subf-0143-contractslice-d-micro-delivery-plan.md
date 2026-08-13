# [SUBF-0143](README.md#subf-0143) - ContractSlice D Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | Design exact-head hosted green and maintainer accepted; `D-POLICY-SURFACE-ACTIVATION-01` is `ExactHeadHostedGreen`; `D-REAL-PRODUCER-INFRASTRUCTURE-01` is `ReviewedLocalGreen`; D is `4/11` and A+B+C+D/full Conformance is `58/58`; the Cohort 2 exact-head hosted gate is pending and RULE-0001 remains inactive |
| Parent | [SUBF-0143](README.md#subf-0143) |
| Scenario | [TEST-0210](test-cases.md#test-0210), retained `Planned` |
| Tracking | [Issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) |
| Accepted predecessor | C merged at exact main [`e9bc3c6f4cc54cc25bfccaa5b4364f2c970e612b`](https://github.com/hasanmanzak/meAndAI/commit/e9bc3c6f4cc54cc25bfccaa5b4364f2c970e612b); exact-main Ubuntu/Windows green and publication verification skipped; immutable linked evidence is owned by the D design handoff |
| Normative owner | [Typed evaluation kernel design](subf-0143-typed-evaluation-kernel-design.md) |
| Implementation language | C# only; final Scenario/status/owner/workflow activation, consumer, merge, release, publication, and other subfeatures remain held |

## Authority and non-goals

This record decomposes only the accepted ContractSlice D architecture. It does
not create or change a general protocol rule. Operational packet labels allocate
no new stable work or test ID. Their exact order, Facts, expected-red identities,
and ownership boundaries are frozen for D only.

D owns the real qualification-only `InitialRuleQualificationPolicy.Export`, the
real Policy codec/parser/index/projector/selector/evaluator graph, fresh
RULE-0001 through RULE-0005 implementations, repository/provider equivalence,
and the final planned-phase ContractSlice inventory verifier. D repeats the
required B/C behavior against real Policy registrations with fresh fixtures;
no B/C runtime handle, cache entry, result, assertion, or TRX is product evidence
for D. C measurements inform only delivery estimates.

D does not own Application routing or I/O, live provider integration, complete-
catalog authority, final Scenario/status/owner/workflow activation, [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
activation, consumer recovery, WIP extraction, feature DoD, merge, release, or
publication. The real five-rule export remains qualification-only and cannot
mint a complete-baseline verdict.

## Frozen dependency graph

```text
exact-main C completion
  -> D-POLICY-SURFACE-ACTIVATION-01
  -> D-REAL-PRODUCER-INFRASTRUCTURE-01
  -> D-RULE-0001-01
  -> D-RULE-0002-01
  -> D-RULE-0003-01
  -> D-RULE-0004-01
  -> D-RULE-0005-01
  -> D-REPOSITORY-PROVIDER-EQUIVALENCE-01
  -> D-ACTIVATION-TOPOLOGY-01
  -> D-CONVERGE-01
```

Only one mutating packet may be active. A successor may start only after its
predecessor has canonical expected-red custody, focused and D-cumulative green,
the relevant Release build, diff/format/structural gates, package-local
independent review, synchronized records, and one separate focused local commit.
That intermediate state is `ReviewedLocalGreen`; it has no push or hosted claim.

## Frozen delivery cohorts

| Cohort | Ordered packets | Entry gate | Exit state |
| --- | --- | --- | --- |
| Policy activation | `D-POLICY-SURFACE-ACTIVATION-01` | Exact-head hosted-green and maintainer-accepted D design | `ExactHeadHostedGreen` after one cohort push |
| Real producer infrastructure | `D-REAL-PRODUCER-INFRASTRUCTURE-01` | Policy activation `ExactHeadHostedGreen` | `ExactHeadHostedGreen` after one cohort push |
| First common rules | `D-RULE-0001-01` -> `D-RULE-0002-01` | Infrastructure `ExactHeadHostedGreen` | `ExactHeadHostedGreen` after one cohort push |
| Specialized common rules | `D-RULE-0003-01` -> `D-RULE-0004-01` -> `D-RULE-0005-01` | First common rules `ExactHeadHostedGreen` | `ExactHeadHostedGreen` after one cohort push |
| Equivalence/closure | `D-REPOSITORY-PROVIDER-EQUIVALENCE-01` -> `D-ACTIVATION-TOPOLOGY-01` -> `D-CONVERGE-01` | Specialized rules `ExactHeadHostedGreen` | Slice completion only after final exact-head hosted green |

The Policy activation and infrastructure cohorts deliberately contain one
packet each. The public Policy type/member SurfaceRed and first Export
BehaviorRed must close in one uncommitted red-to-green operation; separating
them would either commit the forbidden `null!` sentinel or make the later red
already green. The accepted infrastructure architecture likewise owns one
integrated real codec/parser/index/projector/selector/evaluator producer graph
and one expected-red boundary. Splitting either merely to reach a numeric cohort
size would invent an ownership/red boundary. All other cohorts contain two or
three ordered packets.

At each cohort boundary run full D cumulative validation; the ContractSlice
union from A through D; full Conformance and Domain; relevant warning-free
Release builds; format, locks, API/ownership, canonical graph/StructureOnly, and
applicable publication-evidence checks; then review the complete cohort diff.
Only a fully green, review-closed cohort pushes its ordered local commit sequence
once to the current draft PR branch. The next cohort remains inactive until
Ubuntu and Windows pass for that exact head and publication takes its designed
state.

A hosted failure reopens only its cohort. Separate local commits identify the
owning packet. Record owner-identification time, correction/revalidation cost,
and a new exact-head push; never continue over a failed cohort.

## Exact test topology

Every retained D test is one direct non-skipped xUnit `[Fact]` with exactly one
`ContractSlice=D` trait and no `Scenario` trait. The final planned-phase D
inventory is exactly these eleven FQNs in ordinal order. Its canonical LF plus
terminal-LF form is `1,415` UTF-8 bytes with SHA-256
`20B40E80801FAE93F5BC64282FC90695F94FE8FE6EC7E30083581E9B8C1A424E`:

```text
MeAndAI.Protocol.Conformance.Tests.ContractSliceActivationTopologyTests.Matches_exact_contract_slice_scenario_inventory
MeAndAI.Protocol.Conformance.Tests.ContractSliceDOwnershipTests.Enforces_exact_policy_friend_and_negative_surface
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0001_against_fresh_qualified_fixture
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0002_against_fresh_qualified_fixture
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0003_with_exact_target_specialization_and_co_report
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0004_with_exact_fragment_specialization_and_co_report
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0005_with_exact_commit_specialization_and_co_report
MeAndAI.Protocol.Conformance.Tests.ContractSliceDPolicyExportTests.Exports_exact_real_registration_graph
MeAndAI.Protocol.Conformance.Tests.ContractSliceDProducerInfrastructureTests.Activates_exact_real_codec_parser_index_projector_selector_evaluator_graph
MeAndAI.Protocol.Conformance.Tests.ContractSliceDRepositoryProviderEquivalenceTests.Produces_equivalent_results_from_fresh_repository_and_provider_fixtures
MeAndAI.Protocol.Conformance.Tests.ContractSliceDStructuralTests.Matches_exact_final_cumulative_public_surface
```

Theory, inherited/generic/overloaded Fact, class-level trait, duplicate FQN, a
second slice, and a premature Scenario trait are forbidden. Structural and
Ownership plus the export Fact make D `3/3`; infrastructure makes `4/4`; rules
0001..0005 make `9/9`; equivalence makes `10/10`; activation topology makes
`11/11`. Final A+B+C+D/full Conformance is `65/65`; Domain remains `98/98`.
`D-CONVERGE-01` is a code-free audit and adds no Fact.

## Packet ledger

| Packet | Frozen ownership | Canonical expected-red | Required package green |
| --- | --- | --- | --- |
| `D-POLICY-SURFACE-ACTIVATION-01` | Final cumulative `96` exports (`72/23/1`), one public Policy export, zero Domain delta, exact references/friends/negative surface, and real qualification export with exact public/internal 27-row component plus six-list registration graph; no rule evaluation | Permanent compile SurfaceRed for missing `InitialRuleQualificationPolicy`, then canonical `TEST-0210-D-BEHAVIOR-RED-0001` / `ContractSliceDPolicyExportTests.Exports_exact_real_registration_graph` in one uncommitted red-to-green operation | D `3/3`; full `57/57` |
| `D-REAL-PRODUCER-INFRASTRUCTURE-01` | Real three writers/codecs and all real parser/index/projector/selector/evaluator registrations repeat B/C golden, malformed, budget, ordering, cache, ledger, and lifecycle vectors without consuming B/C results | `TEST-0210-D-BEHAVIOR-RED-0002`; `ContractSliceDProducerInfrastructureTests.Activates_exact_real_codec_parser_index_projector_selector_evaluator_graph` | D `4/4`; full `58/58` |
| `D-RULE-0001-01` | Fresh feature-directory repository fixture; missing README/test-cases precedence and exact selector references | `TEST-0210-D-BEHAVIOR-RED-0003`; accepted planned FQN `ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0001_against_fresh_qualified_fixture` | D `5/5`; full `59/59` |
| `D-RULE-0002-01` | Fresh decision-reference/tree/text fixtures; missing record and exact required-structure outcomes | `TEST-0210-D-BEHAVIOR-RED-0004`; `ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0002_against_fresh_qualified_fixture` | D `6/6`; full `60/60` |
| `D-RULE-0003-01` | Repository/provider clickable-target grammar, resolution precedence, historical/current/tag/captured paths, and RULE-0003 side of co-report | `TEST-0210-D-BEHAVIOR-RED-0005`; exact FQN above | D `7/7`; full `61/61` |
| `D-RULE-0004-01` | Declaration anchor and EmbeddedRecord fragment specialization; suppress fabricated specialization when containing target is not exact | `TEST-0210-D-BEHAVIOR-RED-0006`; exact FQN above | D `8/8`; full `62/62` |
| `D-RULE-0005-01` | Human commit exact permalink, repository/object/OID resolution, duplicate/zero references, and RULE-0003/0005 co-report | `TEST-0210-D-BEHAVIOR-RED-0007`; exact FQN above | D `9/9`; full `63/63` |
| `D-REPOSITORY-PROVIDER-EQUIVALENCE-01` | Fresh repository and provider fixtures produce equal common semantics with distinct qualified locations; no sibling-result consumption | `TEST-0210-D-BEHAVIOR-RED-0008`; exact FQN above | D `10/10`; full `64/64` |
| `D-ACTIVATION-TOPOLOGY-01` | Exact planned-phase A-D FQN-to-slice inventory and zero Scenario cardinality; method/FQN/table later remain byte-identical during separately held activation | `TEST-0210-D-BEHAVIOR-RED-0009`; accepted topology FQN above | D `11/11`; full `65/65` |
| `D-CONVERGE-01` | Pure source/test/export/friend/trait/project/lock/graph/evidence audit; P/R/G `NotApplicable` | None; all canonical reds immutable and never rerun | D `11/11`; full `65/65`; Domain `98/98`; all closure gates green |

The canonical first D red remains the accepted warning-free
`InitialRuleQualificationPolicy.Export => null!` sentinel. Later reds use one
fully prepared valid call and direct `Assert.Fail(exactMarker)` only on that
packet's exact absent-behavior predicate. Each uses one fresh external result
root, one full-FQN-filtered invocation, one TRX logger, exactly one selected/
executed/failed result, exact sixteen counters, bounded marker echo/RunInfo, and
no independent diagnostics or attachments. No canonical red is rerun.

Before each later red, a packet-local pre-red freeze must name the exact fully
prepared valid call, semantic return type, transient `null!` assignment, and
the one null-only marker branch. That refinement may narrow the fixture,
allowlist, or line cap, but it may not change the packet label, FQN, marker,
ownership, order, cohort membership, or downstream holds. Construction,
negative/boundary cases, wrong result types, and all exceptions remain marker-
free. The pre-red freeze and renewed D/RT must close before source mutation.

## Exact implementation ownership and limits

Policy production is limited to the accepted namespaces and type identities:
the one export entrypoint; five models; three codecs; two parsers; four indexes;
one demand projector; three selector resolvers; five rule evaluators; and only
the internal registration/qualification helpers necessary to bind those exact
types. Conformance changes are limited to already accepted generic seams when a
fresh real-Policy path proves a defect owned there. Abstractions public API is
frozen at `72`; Domain and Application are immutable. No Policy Tests friend,
project/package/lock/workflow change, direction-specific adapter, alternate
codec/parser/index path, or second kernel is allowed.

Before every red, the packet-specific freeze must enumerate exact source/test
paths and line budgets. Default packet cap is ten production paths, one owning
test path, and `3,500` normalized changed lines; a smaller frozen cap wins. A
crossing requires a reviewed pre-red design amendment and cannot silently raise
the limit. Cohort record sync uses the exact D design cohort and adds no new
stable ID.

### `D-POLICY-SURFACE-ACTIVATION-01` pre-red freeze

The accepted design-delivery head is exact
[`fae0ff2ccb69f02c1eb11e6d310a2454a4297d63`](https://github.com/hasanmanzak/meAndAI/commit/fae0ff2ccb69f02c1eb11e6d310a2454a4297d63),
hosted green in [run 31706799393](https://github.com/hasanmanzak/meAndAI/actions/runs/31706799393): Ubuntu `23m39s`, Windows `14m07s`, publication skipped. The maintainer accepted this design on 2026-08-13 and explicitly authorized D implementation.

The permanent compile observation uses only transient
`ContractSliceD.SurfaceRed.cs` in the exact ten-line shape and must produce only
the frozen `CS0246` tuple for `InitialRuleQualificationPolicy`. The retained
BehaviorRed test reads the fully prepared
`PolicyQualificationSliceExport export = InitialRuleQualificationPolicy.Export`;
only `export is null` calls `Assert.Fail("TEST-0210-D-BEHAVIOR-RED-0001")`.
The transient red implementation is exactly the non-nullable property
`InitialRuleQualificationPolicy.Export => null!`; construction, structural and
ownership checks remain marker-free. Canonical red selects only the frozen
export Fact with Release `--no-restore --no-build`, one fresh root, one TRX and
the common no-retry oracle. No sentinel enters a commit.

The exact production allowlist is:

```text
src/MeAndAI.Protocol.Policy/InitialRuleQualificationPolicy.cs
src/MeAndAI.Protocol.Policy/Declarations/InitialPolicyDeclarations.cs
src/MeAndAI.Protocol.Policy/Registration/InitialPolicyRegistrationGraph.cs
src/MeAndAI.Protocol.Policy/Models/PolicyModels.cs
src/MeAndAI.Protocol.Policy/Codecs/PolicyCodecs.cs
src/MeAndAI.Protocol.Policy/Parsers/PolicyParsers.cs
src/MeAndAI.Protocol.Policy/Indexes/PolicyIndexes.cs
src/MeAndAI.Protocol.Policy/Demands/RepositoryTargetResolutionDemandProjector.cs
src/MeAndAI.Protocol.Policy/Selectors/PolicySelectorResolvers.cs
src/MeAndAI.Protocol.Policy/Rules/PolicyRuleEvaluators.cs
```

The exact retained test allowlist adds only
`ContractSliceDPolicyExportTests.cs` and modifies only the predecessor-safe
Policy-absence assertions in `ContractSliceAPublicApiTests.cs`,
`ContractSliceBStructuralTests.cs`, `ContractSliceCOwnershipTests.cs`, and
`ContractSliceCStructuralTests.cs`. Their existing Facts, FQNs, traits and A/B/C
surface assertions remain unchanged; the D Structural/Ownership Facts alone own
the new Policy export. The packet cap is ten production paths, five test paths,
and `3,500` normalized changed C# lines. No project, package, lock, workflow,
Abstractions, Conformance, Domain, Application or other source/test path may
change. At that Cohort 1 checkpoint, Cohort 2 behavior was absent: real producers could expose only their
object-identical registration identities and fail-closed staging behavior here.

### `D-REAL-PRODUCER-INFRASTRUCTURE-01` pre-red freeze

The predecessor implementation is exact
[`f59c927834cee7ddd5d685e5231536898016006d`](https://github.com/hasanmanzak/meAndAI/commit/f59c927834cee7ddd5d685e5231536898016006d).
[Run 31719641316](https://github.com/hasanmanzak/meAndAI/actions/runs/31719641316)
passed Ubuntu in `18m53s` and Windows in `18m40s`; publication was skipped.
That closes the Policy-activation cohort as `ExactHeadHostedGreen` and grants
no authority beyond this frozen infrastructure packet.

The sole owning Fact constructs fresh repository-tree, governed-text, and
repository-target payload sources plus fresh parser/index/projector/selector/
evaluator inputs, then calls
`ContractSliceDProducerInfrastructureFixture.Activate(InitialRuleQualificationPolicy.Export)`.
The semantic return is one Tests-owned
`ContractSliceDProducerInfrastructureEvidence`; only a null return after the
entire valid call reaches
`Assert.Fail("TEST-0210-D-BEHAVIOR-RED-0002")`. Invalid construction,
malformed payloads, budget boundaries, cancellation, wrong result kinds, and
all exceptions are marker-free. The red changes no production source and the
green introduces no sentinel.

The fresh fixture repeats, without consuming B/C results or handles: the three
canonical writers/codecs at golden, empty, malformed, location/identity,
ordering, equality, and first-one-over boundaries; source-model and target-
model parser success/failure; repository-tree, record, governed-reference, and
repository-target index order and empty/nonempty lifecycle; zero/nonzero target
demand projection; exact selector resolution; four-counter local metering,
cache/ledger identity and cancellation; and all five registered evaluators as
concrete callable staging objects. Rule-specific applicability/findings remain
owned by the later RULE packets, so the infrastructure evaluator staging result
is only `Applicable([])` plus an empty evaluation intent.

The exact production allowlist is:

```text
src/MeAndAI.Protocol.Policy/Models/PolicyModels.cs
src/MeAndAI.Protocol.Policy/Codecs/PolicyCodecs.cs
src/MeAndAI.Protocol.Policy/Parsers/PolicyParsers.cs
src/MeAndAI.Protocol.Policy/Indexes/PolicyIndexes.cs
src/MeAndAI.Protocol.Policy/Demands/RepositoryTargetResolutionDemandProjector.cs
src/MeAndAI.Protocol.Policy/Selectors/PolicySelectorResolvers.cs
src/MeAndAI.Protocol.Policy/Rules/PolicyRuleEvaluators.cs
src/MeAndAI.Protocol.Policy/Registration/InitialPolicyRegistrationGraph.cs
```

The exact executable test allowlist adds only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceDProducerInfrastructureTests.cs`.
No Abstractions, Conformance, Domain, Application, declaration, export,
predecessor test, project, package, lock, workflow, or other source/test path
may change. The packet cap is eight production paths, one test path, and
`3,500` normalized changed C# lines; crossing it requires a reviewed pre-red
amendment. The record cohort is exactly the twelve current D routing surfaces:
project memory README/project/log index plus the D handoff; architecture
README/successor/transition; feature index and FEAT record; this plan; typed
design; and the scenario record. It adds no record node or net unique link
relation.

Canonical R=0002 uses one fresh external runner/report/log identity, a fresh
absent result root, warning-free Release `--no-restore` build, exact DLL/PDB and
six-lock custody, one Release `--no-restore --no-build` child, process-scoped
`VSTEST_CONNECTION_TIMEOUT=300`, and a `420s` monotonic outer bound. The sole
TRX must contain exactly the frozen FQN, Failed outcome, marker-only message,
optional marker-free standard stack/echo/RunInfo, `1/1/1` result-definition-
entry bijection, all sixteen counters, and no attachment/collector/independent
diagnostic. Atomic `InvocationCommitted` consumes R=0002 for every process-
create, timeout, interruption, exit, TRX, or oracle failure; no rerun is
authorized. The exact freeze cohort must first be committed, pushed, and pass
same-head Ubuntu/Windows validation before the runner is materialized.

## Cohort measurement ledger

| Cohort | Local work/validation | Hosted CI | Hosted defects | Owner identification | Correction/revalidation | Estimated saving vs package-hosted | Consistency/traceability loss |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Policy activation | About `45m` local work; exact-tree StructureOnly `546.622s` and publication evidence `7/7` in `369.5s`, run concurrently | [Run 31719641316](https://github.com/hasanmanzak/meAndAI/actions/runs/31719641316): Ubuntu `18m53s`, Windows `18m40s`, publication skipped | `0` | Not applicable | `0` | Baseline: one avoided intermediate hosted wait | None observed |
| Real producer infrastructure | About `2h` active implementation/validation; StructureOnly `527.148s`, publication evidence `7/7` in `337.4s` | Pending one cohort push | `0` locally | Not applicable locally | `0` locally | No avoided package push; singleton cohort preserves semantic isolation | None observed locally |
| First common rules | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | Baseline: one avoided intermediate hosted wait | `NotMeasured` |
| Specialized common rules | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | Baseline: two avoided intermediate hosted waits | `NotMeasured` |
| Equivalence/closure | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | `NotMeasured` | Baseline: two avoided intermediate hosted waits | `NotMeasured` |

At D closure, observed duration, hosted duration, hosted defects, owning-package
isolation time, correction/revalidation cost, estimated saving, and any
consistency/traceability loss are reported per cohort separately from C.

## Design cohort and activation gate

The exact records-only allowlist is:

- [.ai/memory/README.md](../../../.ai/memory/README.md)
- [.ai/memory/project.md](../../../.ai/memory/project.md)
- [.ai/memory/log/README.md](../../../.ai/memory/log/README.md)
- [D design handoff](../../../.ai/memory/log/2026-08-13-feat-0065-subf-0143-contractslice-d-design-freeze.md)
- [architecture README](../../architecture/protocol-governance-and-execution/README.md)
- [successor plan](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md)
- [transition register](../../architecture/protocol-governance-and-execution/transition-register.md)
- [feature index](../README.md)
- [FEAT-0065 record](README.md)
- [C micro-delivery plan](subf-0143-contractslice-c-micro-delivery-plan.md)
- this D micro-delivery plan
- [typed design](subf-0143-typed-evaluation-kernel-design.md)
- [TEST-0210 record](test-cases.md#test-0210)

It changes no code, test, project, package, lock, workflow, or general
`PROTOCOL.md` rule. Fresh design, evidence, scope, traceability, link/stable-ID,
diff, format, graph/StructureOnly, and applicable publication-evidence reviews
must close before one focused design commit/push.

That exact design head passed Ubuntu and Windows with publication skipped, and
the maintainer accepted it. Those gates authorize only the ordered D cohort
implementation above. Scenario/workflow/consumer/release scope remains held;
the Policy-activation successor remains blocked until Cohort 1 is pushed once
and becomes `ExactHeadHostedGreen`.
