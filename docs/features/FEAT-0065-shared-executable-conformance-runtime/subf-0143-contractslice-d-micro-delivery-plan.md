# [SUBF-0143](README.md#subf-0143) - ContractSlice D Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Gate 2 micro-delivery plan and design freeze |
| State | Design exact-head hosted green and maintainer accepted; Policy activation, producer infrastructure, and the first-rules cohort are `ExactHeadHostedGreen`; `D-RULE-0003-01` is `ReviewedLocalGreen`; D is `7/11` and A+B+C+D/full Conformance is `61/61`; specialized-rules cohort is local `1/3` with push held and `D-RULE-0004-01` next/inactive |
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

### `D-RULE-0001-01` pre-red freeze

The producer-infrastructure predecessor is exact commit
[`9d596d984f9921ba48e466d3e41984a9f34fb1c3`](https://github.com/hasanmanzak/meAndAI/commit/9d596d984f9921ba48e466d3e41984a9f34fb1c3).
[Run 31735781705](https://github.com/hasanmanzak/meAndAI/actions/runs/31735781705)
passed Ubuntu in `21m32s` and Windows in `15m08s`; publication was skipped.
This closes Cohort 2 as `ExactHeadHostedGreen` and activates only the frozen
RULE-0001 package.

The sole Fact/FQN/marker are
`ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0001_against_fresh_qualified_fixture`
and `TEST-0210-D-BEHAVIOR-RED-0003`, with only `ContractSlice=D` and no
Scenario, Theory, overload, class trait, or second Fact. The fully prepared
call is
`ContractSliceDPolicyEvaluatorFixture.EvaluateRule0001(InitialRuleQualificationPolicy.Export)`;
its semantic return is `ContractSliceDPolicyEvaluatorEvidence?`. The transient
predecessor runs the real repository-tree writer, codec, index, selector and
registered evaluator over one canonical feature directory containing a File
`test-cases.md` and no `README.md`; only the resulting empty evaluation intent
returns null and reaches the exact marker. Construction, qualification,
cancellation, wrong findings/references/order, negative/boundary fixtures, and
all exceptions remain marker-free.

Green requires exactly one `protocol.feature.readme-missing` finding whose
primary handle is the exact `protocol.selector.feature-readme` ExpectedSelector
for the feature-directory Derived proof and whose only related handle is that
proof. The same Fact proves: complete README/test-cases yields no finding;
README-only yields exactly `protocol.feature.test-cases-missing`; neither child
yields README then test-cases findings; non-File child terminals count as
missing; noncanonical/case-drifted/unrelated directories are ignored; findings
are ordinal while the canonical codec retains its strict input-order contract;
caller collections are copied; and cancellation closes before evaluation. No B/C handle, cache, result,
assertion, or TRX is consumed.

The exact production allowlist modifies only:

```text
src/MeAndAI.Protocol.Policy/Indexes/PolicyIndexes.cs
src/MeAndAI.Protocol.Policy/Registration/InitialPolicyRegistrationGraph.cs
src/MeAndAI.Protocol.Policy/Rules/PolicyRuleEvaluators.cs
```

The test allowlist adds
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceDPolicyEvaluatorTests.cs`.
It may also modify
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceDProducerInfrastructureTests.cs`
only to retire RULE-0001's predecessor empty-intent staging assertion while
retaining registration and cancellation ownership.
No other production/test path, declaration, public API, project, package, lock,
workflow, or record node may change. The cap is three production paths, one
new plus one retained test path, and `950` normalized changed C# lines. Canonical red uses one fresh
external result root, the exact full-FQN filter and marker-named TRX, one child,
Release `--no-restore --no-build`, exact native exit `1`, the common sixteen-
counter/marker-only/no-diagnostic oracle, and no rerun after invocation commit.
Focused green is `1/1`, D is `5/5`, and full Conformance is `59/59`.

Diagnostic `R=0003` executed once and is immutable no-success/no-retry. Its
sole Failed result never reached the marker: the real tree index rejected the
qualified tree model with `Sequence contains no elements` because codec and
index registrations held semantically equal but non-object-identical model
contracts. The bounded correction reuses the exact codec-owned tree model token
when constructing the tree index registration. Corrected canonical red keeps
the same packet/FQN/marker/null seam/oracle, but uses one distinct fresh result
root and is authorized exactly once; it cannot reuse diagnostic artifacts.
The first cumulative green then proved that the immutable infrastructure Fact
still required every evaluator's predecessor empty intent. Its bounded test-only
correction skips that obsolete normal-call assertion for RULE-0001 while keeping
its registration/applicability/cancellation checks; semantic outcomes remain
owned solely by the new RULE-0001 Fact.

### `D-RULE-0002-01` pre-red freeze

The predecessor is the separate local `ReviewedLocalGreen` RULE-0001 commit
[`d5348e822f071898926c7d2834641ac3a5a92e5c`](https://github.com/hasanmanzak/meAndAI/commit/d5348e822f071898926c7d2834641ac3a5a92e5c); the first-common-rules cohort is
not pushed until this packet also closes. The sole new Fact/FQN/marker are
`ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0002_against_fresh_qualified_fixture`
and `TEST-0210-D-BEHAVIOR-RED-0004`, with only `ContractSlice=D` and no
Scenario, Theory, overload, class trait, or second new test class.

The fully prepared call is
`ContractSliceDPolicyEvaluatorFixture.EvaluateRule0002(InitialRuleQualificationPolicy.Export)`;
its nullable semantic return is the retained
`ContractSliceDPolicyEvaluatorEvidence?`. It writes and qualifies fresh
repository-tree and governed-text payloads, parses each text once through the
frozen Markdig pipeline, indexes the resulting object-identical Markdown
models through the real protocol-record registration, then binds the tree and
record capabilities plus both exact context proofs and selector lookup to the
object-identical RULE-0002 evaluator. Only the predecessor evaluator's empty
intent after that complete valid call returns null and reaches the marker.
Construction, parsing, indexing, cancellation, wrong result/reference/order,
negative/boundary fixtures, and every exception remain marker-free.

For this packet the protocol-record index emits ordinal immutable rows with
record kinds `protocol.record.decision` and
`protocol.record.decision-reference`. A decision row is recognized by its
exact H1 `DEC-NNNN - <nonempty title>` identity; malformed title/shape still
retains the exact `DEC-NNNN` identity so RULE-0002, rather than absence, owns
the structure finding. Its member sequence is exactly `heading`, the six
ordered nonempty metadata keys `Classification`, `Status`, `Date`,
`Decision owners`, `Related features`, `Related decisions`, and the five
ordered exactly-once nonempty H2 keys `Context`, `Decision`, `Consequences`,
`Alternatives considered`, `Review condition`. A distinct governed occurrence
of exact ASCII `DEC-[0-9]{4}` creates one decision-reference row whose Derived
handle is the selector parent; the owning H1 identity itself is not a
reference. Inputs, records and members are copied and ordinal; duplicate
decision identities are structurally invalid, never an arbitrary winner.

For each ordinal reference, zero matching decisions emits exactly
`protocol.decision.record-missing`: primary is the exact
`protocol.selector.decision-record` ExpectedSelector for the reference handle;
related evidence is repository-tree ContextProof, governed-text Root proof,
then the reference Derived proof. One exact valid decision emits no finding.
One malformed or duplicate matching decision emits exactly
`protocol.decision.structure-invalid`: primary is its record Derived proof and
the same ordered related proof kinds are retained. Missing precedes structure;
distinct references remain independently reportable. The fixture proves
missing, exact valid, missing/reordered/duplicate metadata, missing/reordered/
duplicate/empty sections, malformed H1, duplicate record identity, ordinal
multi-reference results, caller-copy immutability, exact handle identity, and
cancellation before capability access.

The exact production allowlist modifies only:

```text
src/MeAndAI.Protocol.Policy/Models/PolicyModels.cs
src/MeAndAI.Protocol.Policy/Parsers/PolicyParsers.cs
src/MeAndAI.Protocol.Policy/Indexes/PolicyIndexes.cs
src/MeAndAI.Protocol.Policy/Registration/InitialPolicyRegistrationGraph.cs
src/MeAndAI.Protocol.Policy/Rules/PolicyRuleEvaluators.cs
```

The test allowlist modifies only
`tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceDPolicyEvaluatorTests.cs`
and `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceDProducerInfrastructureTests.cs`;
the latter may retire only RULE-0002's predecessor empty-intent assertion while
retaining registration/applicability/cancellation ownership. No declaration,
public API, project, package, lock, workflow, other producer/rule, Abstractions,
Conformance, Domain, Application, or record node may change. The cap is five
production paths, two retained test paths, and `1,500` normalized changed C#
lines. A crossing requires a reviewed pre-red redraw and cannot silently raise
the cap.

Canonical red uses one fresh external result root, exact full-FQN filter and
marker-named TRX, one Release `--no-restore --no-build` child, native exit `1`,
the common sixteen-counter/marker-only/no-diagnostic oracle, and no rerun after
invocation commitment. Focused green is `1/1`, D is `6/6`, full Conformance is
`60/60`; the cohort then runs the complete local boundary and only its two
separate commits are pushed together for exact-head hosted validation.

### `D-RULE-0003-01` pre-red freeze

The predecessor is exact-head hosted-green commit
[`4b9e8af8083da824b09706674a725ef93b59f467`](https://github.com/hasanmanzak/meAndAI/commit/4b9e8af8083da824b09706674a725ef93b59f467)
and run [31746252371](https://github.com/hasanmanzak/meAndAI/actions/runs/31746252371):
Ubuntu passed in `22m36s`, Windows in `20m05s`, and publication verification
was skipped. This packet adds exactly one direct non-skipped Fact,
`ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0003_with_exact_target_specialization_and_co_report`,
with only `ContractSlice=D`, no Scenario/Theory/overload/class trait, and marker
`TEST-0210-D-BEHAVIOR-RED-0005`.

The fresh fixture parses governed repository/provider Markdown through the
real fixed Markdig pipeline, builds the real governed-reference index, projects
repository-target demand, binds real target-resolution evidence, and invokes
the object-identical registered RULE-0003 evaluator. It covers CrossRecord,
EmbeddedRecord, and Commit references; clickable, non-clickable, and unsupported
syntax; local exact/missing/wrong/unresolved targets; qualified historical,
current, tag, and captured paths; and the RULE-0003 side of specialized
co-reporting. Unsupported authoring precedes not-clickable; not-clickable or
incomplete visible target coverage precedes resolution; qualified unresolved
precedes wrong-target. Embedded missing/wrong fragment is held for RULE-0004;
Commit wrong repository/object is held for RULE-0005; both remain eligible for
RULE-0003 common findings when the containing target itself is wrong. Exact
qualified references emit no finding. Findings use the governed Derived
reference as primary and retain ordered governed Root/Derived plus qualified
target evidence as related references.

The nullable semantic seam is
`ContractSliceDPolicyEvaluatorFixture.EvaluateRule0003(InitialRuleQualificationPolicy.Export)`.
Only the complete valid first common-finding call returning the predecessor
empty intent reaches the marker; setup/index/projection/qualification defects,
wrong codes/order/references, negative fixtures, cancellation, and exceptions
remain marker-free. The production allowlist modifies only
`PolicyIndexes.cs`, `RepositoryTargetResolutionDemandProjector.cs`,
`PolicyRuleEvaluators.cs`, and `InitialPolicyRegistrationGraph.cs`; the test
allowlist modifies only `ContractSliceDPolicyEvaluatorTests.cs` and may update
`ContractSliceDProducerInfrastructureTests.cs` solely to retire RULE-0003's
obsolete empty-intent staging assertion. No public API/declaration, codec/parser,
project/package/lock/workflow, other rule, Domain, Application, or record node
may change. The normalized changed-C# cap is `1,800` lines; crossing it requires
a reviewed pre-red redraw.

Canonical red uses one fresh external result root, exact FQN filter and
marker-named TRX, one Release `--no-restore --no-build` child, native exit `1`,
the common sixteen-counter/marker-only/no-diagnostic oracle, and irrevocable
no-rerun after invocation commitment. Focused green is `1/1`, cumulative D is
`7/7`, and full Conformance is `61/61`. RULE-0004 remains held until a separate
`ReviewedLocalGreen` RULE-0003 commit exists.

## Cohort measurement ledger

| Cohort | Local work/validation | Hosted CI | Hosted defects | Owner identification | Correction/revalidation | Estimated saving vs package-hosted | Consistency/traceability loss |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Policy activation | About `45m` local work; exact-tree StructureOnly `546.622s` and publication evidence `7/7` in `369.5s`, run concurrently | [Run 31719641316](https://github.com/hasanmanzak/meAndAI/actions/runs/31719641316): Ubuntu `18m53s`, Windows `18m40s`, publication skipped | `0` | Not applicable | `0` | Baseline: one avoided intermediate hosted wait | None observed |
| Real producer infrastructure | About `2h` active implementation/validation; StructureOnly `527.148s`, publication evidence `7/7` in `337.4s` | Pending one cohort push | `0` locally | Not applicable locally | `0` locally | No avoided package push; singleton cohort preserves semantic isolation | None observed locally |
| First common rules | RULE-0001 about `1h`; RULE-0002 about `1h` active implementation/validation; focused `1/1`, D `6/6`, full `60/60`, Domain `98/98`, API/ownership `15/15`, Release `0/0`, locks/format/diff clean; synchronized StructureOnly `528.328s`, publication evidence `7/7` in `334.7s`; evidence-line recurrence StructureOnly `501.510s`, publication `7/7` in `329.4s` | Run 31746252371: Ubuntu `22m36s`, Windows `20m05s`, publication skipped | `0` | RULE-0001 isolated one registration token-identity defect plus one staging expectation; RULE-0002 isolated one predecessor staging expectation immediately | About `20m` total including rebuild/revalidation | One intermediate hosted wait avoided | None observed |
| Specialized common rules | RULE-0003 about `1h` active implementation/validation; focused `1/1`, D `7/7`, full `61/61`, Domain `98/98`, Release `0/0`, format/diff clean; `1,155/1,800` changed C# lines | Not pushed; cohort local `1/3` | `0` locally | One infrastructure staging expectation identified immediately by D cumulative test | Under `10m` including rebuild/revalidation | Baseline: two avoided intermediate hosted waits | None observed locally |
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
