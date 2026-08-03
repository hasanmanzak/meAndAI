# ContractSlice A projector-DAG frozen-design handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-03 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-PROJECTOR-DAG-01` `FrozenDesign`; D/RT accepted and maintainer-activated under the standing A-through-`A-CONVERGE-02` directive; LR/P/R/C# remain pending |
| Exact predecessor | [`b735853a2153338fd97c366bcd8c212f78bc1bce`](https://github.com/hasanmanzak/meAndAI/commit/b735853a2153338fd97c366bcd8c212f78bc1bce), git tree identity `fc5ae301331f55f1435b4262c300489e3cbcff2f`, passed Windows in `17m10s` and Ubuntu in `19m02s` in [run 30781516326](https://github.com/hasanmanzak/meAndAI/actions/runs/30781516326); publication verification was correctly skipped |
| Admission parent | [Reviewed-local-green admission handoff](2026-08-03-feat-0065-subf-0143-contractslice-a-admission-freeze.md) |
| Progress | Twelve of twenty live packets are `ReviewedLocalGreen` (`60%`); cumulative A remains `25/25`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Accepted architecture correction and ownership

- A owns canonical projector declaration wire/projection, exact slot/capability/component/artifact binding, document-local producer-DAG acceptance/rejection, and no executable export. C remains the first owner of typed registration lists, implementation objects, activation, runtime call order, and `CatalogSliceKernel`. `A-CONVERGE-01` later audits the unchanged projector row inside the real six-artifact, thirty-five-component union; it does not own a projector behavior fix.
- Producer-DAG nodes are exactly `PayloadSchemaDeclaration`, `SemanticModelParserDeclaration`, `ContextIndexDeclaration`, and `AcquisitionDemandProjectorDeclaration`. Slots, model/capability identities, selectors, evaluators, proof declarations, component/artifact mappings, and demand-schema tokens are not nodes.
- Owners are separate and exact: one schema-or-parser producer per model key/version, one index producer per capability key/version, at most one projector per output slot, and one artifact mapping per functional component identity. A functional component identity may occupy only one declaration role across activation proof, admission proof, payload codec, model type, parser, index, capability type, projector, selector resolver, and evaluator. These are separate invariants, not one overloaded single-owner rule.
- Edges always point prerequisite producer to dependent: model/capability producer to consuming parser/index, input-capability producer to projector, and projector to the output slot requirement's payload-schema producer. The exact ten-node successor graph has three schemas, two parsers, four indexes, and one projector. Roots are computed, never hard-coded, as nodes with indegree zero. Exact successor roots are governed-text and repository-tree schemas; the projected repository-target schema is not a successor root. Jointly removing the projector declaration and component removes its edge, so the valid nine-node predecessor roots are governed-text, repository-target-resolution, and repository-tree schemas.
- Slot-rooted closure is evaluated over the structurally unique union of every rule's applicability and evaluation slots: seed each slot's requirement-schema and capability producers, follow DAG dependencies in reverse, and require the union to equal all producer nodes. Every projector input slot must exist in that union and declare the projector input capability; output must be one existing evaluation-only slot. Unresolved inputs, duplicate producers/output owners, self edges, cycles, applicability output, and closed-but-unreachable declarations fail document-local parsing.
- Kahn validation uses the total ordinal comparator component key, component version, declaration key, declaration version, then family rank Schema/Parser/Index/Projector. A exposes no topological-order API and claims no runtime order; C owns the first executable call-trace proof.
- `DemandSchemaKey/Version` is the exact opaque emitted-demand discriminator `protocol.repository-target-resolution-demand` / `1`. It is not payload schema `protocol.repository-target-resolution` / `1`, not a fourth `PayloadSchemaDeclaration`, and not a producer-DAG node.

## Frozen behavior and expected-red contract

- Exact projector is `protocol.projector.repository-target-resolution-demand` / `1`, component `MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector` in `MeAndAI.Protocol.Policy`, input capability `protocol.capability.governed-reference-index` / `1`, input slots provider-governed-text then repository-governed-text, output slot repository-target-resolution, budget `(33554432,64,100000,5000000)`, and sole failure `protocol.budget.exhausted`.
- Reserved Fact/FQN is `MeAndAI.Protocol.Conformance.Tests.ContractSliceAProjectorDagManifestTests.Enforces_exact_projector_bindings_and_global_producer_graph`; the only trait is `ContractSlice=A`, with no `Scenario`. Marker/TRX stem is frozen as [`TEST-0210-A-BEHAVIOR-RED-0010`](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210).
- P is `NotApplicable`. Before transient source, exact admission focused `1/1` and cumulative A `25/25` must pass against unchanged source after one locked restore.
- R constructs the fully valid typed one-projector/twenty-six-component/three-artifact successor and verifies authority/count preconditions outside the catch. The first guarded missing-behavior observation is only `CanonicalManifestWriter.Write`. Only exact runtime `InvalidOperationException` plus exact message `This writer increment supports only the minimal qualification slice.` calls `Assert.Fail` with marker 0010. Reader is not invoked in R; setup, Catalog, precondition, type/message mismatch, and every other exception propagate marker-free. R is one fresh external exact-FQN TRX invocation and is never rerun.
- Green removes the legacy catch/marker and proves Writer -> Reader -> Writer byte identity, digest, typed projection, component/artifact closure, DAG acceptance/rejection, and predecessor reproduction. The positive tuple is exactly `(3,2,4,1,4,2,2,3,26,3)`. Removing the projector declaration and its component together must byte-reproduce the valid current admission `25 components / 3 artifacts / 0 projectors` predecessor. Focused and cumulative expected green are `1/1` and `26/26`; progress does not advance until G/V/review completes.

## Frozen matrix, allowlist, and caps

- Exact projector wire order is `projectorKey`, `projectorVersion`, `projector`, `inputCapability`, `inputSlotKeys`, `outputSlotKey`, `demandSchemaKey`, `demandSchemaVersion`, `budget`, `failureCodes`; existing nested component/capability/budget field owners remain authoritative.
- The retained Fact owns 103 unique one-at-a-time canonical-byte negatives: 50 outer wire-shape cases, four array-envelope cases, twenty-seven identity/collection/budget cases, and the following exact twenty-two component/DAG topology cases. Every mutation differs from positive bytes, remains valid JSON at the intended layer, is uniqueness-counted, and fails only through `FinalizedPolicyManifest.ParseCanonical` with `FormatException`.

| # | Exact base-fixture mutation | Sole owned invariant |
| ---: | --- | --- |
| 1 | Remove only the new projector component binding | Projector component must resolve |
| 2 | Duplicate the exact projector component binding | Component mapping key/version is unique |
| 3 | Add one mapped `protocol.projector.repository-target-resolution-demand.extra/1` component with no declaration | Functional component mappings cannot be declaration-free extras |
| 4 | Change only the projector binding artifact to undeclared `Missing.Projector.dll` | Every component maps to one declared artifact |
| 5 | Remove only the projector declaration while retaining its exact component binding | Projector component cannot be orphaned |
| 6 | Reuse `protocol.activation-proof.test/1` as the projector component | Projector and activation-proof roles are disjoint |
| 7 | Reuse `protocol.admission-proof.test-observed/1` as the projector component | Projector and admission-proof roles are disjoint |
| 8 | Reuse `protocol.codec.governed-text/1` as the projector component | Projector and payload-codec roles are disjoint |
| 9 | Reuse `protocol.type.model.source-text/1` as the projector component | Projector and model-type roles are disjoint |
| 10 | Reuse `protocol.parser.markdown/1` as the projector component | Projector and parser roles are disjoint |
| 11 | Reuse `protocol.index.governed-reference/1` as the projector component | Projector and index roles are disjoint |
| 12 | Reuse `protocol.type.capability.governed-reference-index/1` as the projector component | Projector and capability-type roles are disjoint |
| 13 | Remove governed-reference capability only from provider-governed-text slot | Every projector input slot declares its input capability |
| 14 | Remove governed-reference capability only from repository-governed-text slot | Every projector input slot declares its input capability |
| 15 | Remove governed-reference index declaration and only its implementation binding while retaining the governed-reference capability-type binding and all consumers | Every consumed capability has exactly one producer |
| 16 | Add a fully mapped second index declaration with a distinct index component but the same governed-reference output capability | Capability producer ownership is unique |
| 17 | Add a fully mapped second projector with a distinct component but the same repository-target-resolution output slot | Output-slot projector ownership is unique |
| 18 | Move repository-target-resolution slot from evaluation to applicability while retaining the projector | Projected outputs are evaluation-only |
| 19 | Add repository-target-resolution capability as an input to governed-reference index | Reject the exact target-index -> governed-index -> projector -> target-schema -> target-parser -> target-index cycle |
| 20 | Add a fully mapped unused schema/model producer pair referenced by no applicability or evaluation slot dependency | Closed but slot-unreachable producers are rejected |
| 21 | Remove provider-governed-text slot from the rule while retaining it in projector input keys | Every projector input slot resolves |
| 22 | Remove repository-governed-text slot from the rule while retaining it in projector input keys | Every projector input slot resolves |

The seven role-collision rows are the exact projector-delta representatives;
prior packets retain their own selector/evaluator/proof and producer-family
collision coverage. The positive successor asserts the two computed roots and
the byte-reproduced predecessor asserts its three computed roots.
- Production allowlist is only `CanonicalManifestReader.cs`, `CanonicalManifestWriter.cs`, and `CatalogSliceDeclaration.cs`; one new test file is allowed. Public API, project/package/lock/workflow files and every other source/test are held.
- The dependency rationale approves a bounded exception to the normal 450-line target: Reader planning ceiling `145`, Writer `70`, Catalog `110`, aggregate production gross hard cap `300`, retained new-test hard cap `390` physical lines, combined hard cap `690`; `700+` forces redraw. Assertions or semantic vectors may not be removed merely to fit.
- The records-only freeze cohort is the finite thirteen-record synchronization exception: five memory records (memory README, admission handoff, this projector handoff, log README, and project memory), three architecture records, and five feature/design/test/index records. Older handoffs remain immutable. No C#, executable test, project, lock, package, or workflow enters this freeze commit.

## Red-team disposition and holds

- Independent node/edge/reachability review originally found three Blocking, three Important, and one Minor design ambiguity; the exact node universe, projected-schema root rule, reverse slot closure, separated owner tables, total Kahn comparator, A-vs-C observability boundary, demand-schema disposition, and exact cycle/unreachable matrix above resolve them.
- Independent ownership/record review found one hosted-predecessor Blocking and four Important items; the [exact hosted-green predecessor](https://github.com/hasanmanzak/meAndAI/commit/b735853a2153338fd97c366bcd8c212f78bc1bce), explicit projector-vs-convergence/A-vs-C ownership, Writer-first validation-free R, demand token disposition, and finite record-cap/history exception resolve them.
- Independent evidence/budget review found two Blocking, six Important, and one Minor items; exact predecessor, 0010/FQN, 26/3 successor, joint declaration+component reproduction, Reader exclusion from R, 103-vector matrix, and corrected 690 hard cap resolve them. Current D/RT verdict is `0 Blocking / 0 Important / 0 Minor`; Protocol Gate 5 has no additional observation.
- B/C/D, all later A packets, Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), merge, release, publication, consumer mutation, WIP extraction, and PowerShell retirement remain held. No DoD, full [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) green, hosted projector evidence, or publication claim is made.
