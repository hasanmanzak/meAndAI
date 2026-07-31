# FEAT-0065 Test Scenarios

[SUBF-0152](README.md#subf-0152)/[TEST-0220](#test-0220) is complete through
[PR #170](https://github.com/hasanmanzak/meAndAI/pull/170), exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).
The architecture prerequisite remains [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169)
and [run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).

The historical 2026-07-30
[SUBF-0153](README.md#subf-0153) [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
produced the accepted [SUBF-0153](README.md#subf-0153)/[TEST-0221](#test-0221)
design. [PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) merged it at
exact main
[`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f).
That closed Gate 2 design only.

The later
[SUBF-0143](README.md#subf-0143) [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584)
produced an accepted Gate 2 packet for
[SUBF-0143](README.md#subf-0143)/[TEST-0210](#test-0210). It was accepted,
merged, and bounded exact-main validated at
[`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7).
[TEST-0210](#test-0210) remains `Planned`, but the corrected
[ContractSlice A directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228)
now authorizes only the reviewed A topology correction, project/lock transition,
exact A expected reds, and bounded cumulative-A C# implementation.
The append-only
[BehaviorRed evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
changes only the TRX evidence wording. The earlier observation remains
diagnostic; the fresh same-FQN canonical rerun after packet synchronization is
now accepted and recorded below.
The later append-only
[RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
classifies only one exact marker-free same-FQN xUnit `[FAIL]` RunInfo as
same-result bookkeeping. The run that exposed it remains diagnostic; the later
post-synchronization run satisfied the complete corrected oracle.

The subsequent scoped
[activation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5135051435)
authorized [SUBF-0153](README.md#subf-0153)/[TEST-0221](#test-0221) Gate 3.
[PR #173](https://github.com/hasanmanzak/meAndAI/pull/173) completed that
activation at exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd),
and exact-main [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256)
passed both stable jobs.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0209` <a name="test-0209"></a> | [FEAT-0065](README.md) composed qualification across [SUBF-0152](README.md#subf-0152), [SUBF-0153](README.md#subf-0153), [SUBF-0143](README.md#subf-0143), [SUBF-0144](README.md#subf-0144), and [SUBF-0154](README.md#subf-0154) | Vary rule, evidence, typed location, profile axes, acquisition state, evaluation state, debt, waiver, enforcement, and report values, including missing, duplicate, stale, unknown, malformed, and redacted data. | Invalid combinations fail construction. Valid reports preserve acquisition, per-rule evaluation, conformance verdict, and enforcement decision as four separate dimensions: incomplete/failed required acquisition creates `NotEvaluated` and aggregate `Indeterminate`, known violations remain visible, and enforcement follows the accepted phase/waiver/debt precedence. Canonical serialization, ordering, and digest are identical across supported runtimes and operating systems. | Component / contract / serialization | Nearest same-contract sibling: the [preserved WIP model scenario](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` because it directly exercises the composed production model with typed multi-surface locations and separated result dimensions, rather than aggregating child-test results or reusing the bounded repository report. | Planned | Future composed .NET qualification tests |
| `TEST-0210` <a name="test-0210"></a> | [SUBF-0143](README.md#subf-0143) | Execute the exact [typed-evaluation-kernel design](subf-0143-typed-evaluation-kernel-design.md) through ContractSlice A-D: A canonical manifest/digest/typed-projection and declaration/artifact/component preflight without executable export; first qualification/complete export activation in C; persistent writer/qualifier pairs, plan-bound Conformance qualification/cache, proof-candidate admission, provider-neutral capability/reference contracts; staged zero-to-N evaluation rounds with typed owner-sharded repository-target demand; retained acquisition outcomes; then kernel outputs, aggregation, and fresh RULE-0001..0005 repository/provider qualification. | The real five-rule Policy export is qualification-only and cannot mint a complete-baseline verdict; Application owns route/I/O but no protocol encoder; only exact instruction-bound proof candidates or kernel-synthesized absence enter the sealed context; repository/provider material shares compiled semantics while retaining distinct qualified locations; false applicability avoids evaluation-only evidence, unresolved remains NotEvaluated, acquisition Complete/Incomplete/Failed remains independent from rule status, empty repository-target demand performs no external I/O while the registered target index still produces the empty capability, external owners remain item custody rather than subject scope, independently metered four-counter producer/cache behavior is deterministic, integrity defects abort, and only the kernel mints referenced findings/evaluations. | Unit / component / qualification | Nearest same-contract siblings are [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177), and [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178); all are `Distinct`, and [TEST-0210](#test-0210) executes fresh fixtures rather than consuming sibling results. | Planned | Gate 2 accepted/merged at [`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7); corrected ContractSlice A directive plus [message/echo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054) and [RunInfo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849) clarifications active; canonical first A BehaviorRed/limited ParseCanonical green and second A canonical-string exact-red/bounded-green accepted; cumulative A `13/13`, but remaining A is pending and no owner/workflow/hosted activation occurs until A-D and combined green |
| `TEST-0211` <a name="test-0211"></a> | [SUBF-0144](README.md#subf-0144) | Evaluate protected baseline plus valid/invalid extensions, waivers, historical debt, policy activation snapshots, previous-trusted runtime, candidate runtime, differential results, and attempted candidate self-certification. | Extensions are additive and namespaced, baseline enforcement cannot be lowered, waiver/debt effects follow the deterministic truth table, stale activation fails closed, and authority transfer remains impossible from candidate-only evidence. | Component / security / differential | Nearest same-contract sibling: [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163); Distinct protocol-runtime bootstrap and protected-policy contract. | Planned | Future .NET qualification and differential tests |
| `TEST-0220` <a name="test-0220"></a> | [SUBF-0152](README.md#subf-0152) | Vary exact rule identity/revision and SHA-256 values, every closed profile/outcome token, SurfaceSet order/duplicates/mutability, ExecutionProfile axes, and the new project graph. | Invalid lexical, range, null, duplicate, and cross-dimension values fail closed; valid values are immutable and ordinal-exact; SurfaceSet and profile equality are input-order independent; the Domain assembly is BCL-only and no outcome dimension implies another. | Unit / architecture / contract | Nearest siblings: [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191), [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192), and preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` scalar invalid-state and independent-axis contract in the new protocol Domain assembly. | Passing | `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`; completed slice evidence is recorded below |
| `TEST-0221` <a name="test-0221"></a> | [SUBF-0153](README.md#subf-0153) | Vary the exact inventory-derived [evidence-acquisition design](subf-0153-evidence-contract-design.md): requirement schemas, request target, observed boundary/scope, asserted-canonical payload, typed locations, bindings/root references, requirement acquisition, pagination, context, and observed/absent/failed result variants. | Schema-identified content is immutable and content-addressed but remains an untrusted assertion until exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification; source/snapshot scope is structural; absent is `Incomplete`; failed has no valid context and remains `Failed`; requirement/context status is derived; invalid API, pagination, reference, schema, redaction, failure, collision, and union combinations fail construction. | Unit / architecture / contract | Same-contract classifications are fixed in the [design inventory](subf-0153-evidence-contract-design.md#distinct-test-intent-and-sibling-inventory). `Distinct` acquisition/evidence substrate rather than [SUBF-0143](README.md#subf-0143) codec/typed-model/derived-reference/finding/evaluation behavior, composed reports, or repository-only WIP. | Passing | `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`; completed through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173), exact main [`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd), and [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256) |
| `TEST-0222` <a name="test-0222"></a> | [SUBF-0154](README.md#subf-0154) | Seal the complete typed report after catalog evaluation and debt/waiver disposition; vary input order, culture, operating system, line endings, redaction, missing dimensions, and digest tampering. | The report is complete or fails closed; canonical bytes, collection order, and digest are schema-exact across supported runtimes and systems; raw content and credentials are absent. | Component / serialization / cross-runtime | `Distinct` from [TEST-0209](#test-0209) by canonical-byte/digest nondeterminism risk and report-sealing boundary rather than composed semantic evaluation. | Planned | Future .NET report qualification tests; implementation not authorized |

## [TEST-0210](#test-0210) Gate 2 expected-red matrix

The normative detailed contract is the
[SUBF-0143](README.md#subf-0143) [typed-evaluation-kernel design](subf-0143-typed-evaluation-kernel-design.md#test-0210-expected-red-contract).
[TEST-0210](#test-0210) remains one canonical scenario and uses the additional
exact trait
`ContractSlice=A|B|C|D` for independently reviewed red/green increments.

| Contract group | Required boundary |
| --- | --- |
| A - Catalog and manifest preflight | Exact cumulative-A `48` exports and members; zero Domain delta; qualification slice versus complete snapshot; canonical manifest bytes/digest/typed projection with exact `16,777,216`-byte, depth-`64`, and `1,000,000`-token ceilings; acyclic declaration/artifact/component binding; only the four exact runtime anchors may be role-exempt; exact normative selectors/bytes/digests; predecessor transitions; schema/demand DAG; named profiles; negative public/friend surface; `27` manifest logical producer/type-contract and `35` full component rows; fail-closed missing/extra/duplicate/retired/unmapped/unreachable declarations and mappings. Under [FIND-0439](README.md#find-0439), every document-local closure defect is `ParseCanonical` `FormatException`; the parser seals `sourceCommit`/fragment grammar but trusted qualification/release evidence proves real commit/blob/content, and predecessor-trusted or loaded-export conflicts begin later in Conformance. The second reviewed A increment adds one writer-owned internal `CanonicalManifestQuotedUtf8Codec`, exact lowercase control escaping, raw/non-normalized printable Unicode including distinct `é`/`é` raw bytes, positive 1,226-byte manifest/digest, same-codec complete quoted-token equality, and malformed raw/escaped Unicode classification without changing the public surface. A constructs no executable export, validates no typed registration list, and declares no kernel. |
| B - Codec admission and typed roots | Exact cumulative-B `72` export shape and only the codec-registration/model-token subset; Tests-only private-stamp `Activate -> WriteCanonicalPayload -> Qualify -> Admit`; persistent writer/qualifier pairs for repository-tree, governed-text, and repository-target-resolution; CommitObject/TagRoot/CapturedSnapshotPath wire, content ordering/deduplication, codec ceilings, golden/malformed/round-trip vectors, codec-local four-counter ledger, codec decode/model cache, ContextProof/Root/codec-derived references, collision/single-flight/eviction/cancellation/host-failure lifecycle, and no writer/codec admission rerun. B claims no parser/index/projector/selector behavior, provider-neutral capability semantics, parser-model/index cache, shared-root ledger, zero-candidate planning, or real Policy code. |
| C - First executable activation, synthetic complete applicability, and kernel | Exact cumulative-C `95` exports; first executable export activation and `CatalogSliceKernel`; friend-only synthetic qualification export/proof branch for `CatalogSliceKernel` mismatch oracles plus a Tests-owned synthetic complete graph with all six typed registration families and no real Policy registration; exact registration/type-token/public-`Components` count/order/bijection plus missing/extra/duplicate/foreign/wrong-generic/projection-drift `RegistrationMismatch` oracles; both Markdown parsers; synthetic repository-tree/record/governed-reference/repository-target indexes, target projector, selectors, evaluators, provider-neutral capabilities, parser-model/index caches, and shared-root ledgers; mandatory PlanApplicability -> CloseApplicability -> PlanEvaluation -> zero-to-N AdvanceEvaluation -> EvaluationClosure -> proof-free Evaluate; true/false/unresolved applicability; CommitObject/TagRoot/CapturedSnapshotPath and historical Markdown/line paths; capture-manifest expected-content authority, global ItemId source-plus-authority map, owner sharding, successful-model pairing versus declared parser failure, input-only target-parser cache identity with zero-row/hit/cross-shard-plan isolation, target-parser 33,554,432-byte equality/one-over budget, plan-global equality/one-over limits of 64 unique content keys, 16,777,216 aggregate unique-content bytes, and 67,108,864 complete payload bytes with deterministic first-crossing tail, zero external instruction/I/O/codec with one zero-model synthetic target-index invocation, Complete/Incomplete/Failed outcomes, `projector-failed` and `projected-resource-failed`, OutcomeDigest/collision, integrity aborts, cumulative results, exact order/flags, and synthetic complete-catalog verdict truth table. |
| D - Real first common rules | Final cumulative `96` exports (`72` Abstractions, `23` Conformance, `1` Policy); direct real `InitialRuleQualificationPolicy.Export` graph; every real Policy writer/codec repeats B and every real parser/index/projector/selector/evaluator repeats C without a Policy Tests friend or consumed B/C result; every qualified input is freshly constructed from immutable fixture definitions/data rather than a prior runtime handle or assertion; fresh positive/negative/boundary/malformed RULE-0001..0005 repository/provider fixtures; tag roots, historical/current blobs, captured lines, Markdown anchors, same SHA under same/external owners, duplicate commits, empty demand, Missing/Present/wrong-owner/wrong-object joins; exact codes/provenance; RULE-0003/0004/0005 specialization/co-reporting; [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175), [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0177](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177), and [TEST-0178](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178) equivalence without consuming sibling results. |
| API/project ownership | [TEST-0220](#test-0220) and [TEST-0221](#test-0221) retain exact predecessor type/member behavior; [TEST-0210](#test-0210) owns exact Domain export equality to their ordinal union, cumulative public inventories `48/72/95/96`, final assembly totals `72/23/1`, and the eventual total solution/project/reference/package/lock/effective-restore graph. |
| Expected-red purity | One ContractSlice at a time after byte-identical locked restore: SurfaceRed is compile-only with exactly the design's one `CS0246` file/span/token/FQN tuple and no discovery claim. A's first BehaviorRed used the historical `ParseCanonical => null!` predicate. The second A red uses exact FQN `MeAndAI.Protocol.Conformance.Tests.ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding`, marker/TRX `TEST-0210-A-BEHAVIOR-RED-0002`, and only the exact legacy quoted-byte result frozen in the design may invoke `Assert.Fail`; B/C/D retain their exact warning-free activation/export `null!` sentinel. Every BehaviorRed uses one full-FQN-filtered invocation, one TRX logger, a fresh external TRX path, exactly one selected/executed/failed result, and the complete zero/nonzero counter inventory. The sole failed result has exactly one `Output/ErrorInfo/Message` whose normalized text equals the marker byte-for-byte; the marker occurs nowhere else except for at most one byte-identical `ResultSummary/Output/StdOut` or `StdErr` adapter echo. `ResultSummary/RunInfos` is absent or has one marker-free `RunInfo outcome="Error"` with exactly `computerName`/`outcome`/`timestamp` attributes and one Text matching the locked-adapter same-FQN `[FAIL]` grammar; it is same-result bookkeeping only with the exact Failed result/summary, 16 counters including `error=0`, and no other diagnostic or attachment. Reviewed source plus immutable xUnit `2.9.3` lock proves the direct `Assert.Fail` exception type because standard TRX does not serialize it. C first proves executable export activation; D first proves only the real export graph. RULE-0001 waits until the real D writer/codec/parser/index/projector/kernel vector path is green, then uses that D session to mint a fresh Conformance-registered input from immutable fixture data. Restore/lock/project/analyzer/predecessor/environment, any independent or contradictory extra diagnostic/result, relabeled unexpected exception, or console-only inference invalidates red. |
| Negative surface | No consumer registration/reflection/DI, public export/input/output construction, `object`/`dynamic`, raw DTO/JSON/snippet/message, Policy-side route/provider DTO/I/O/cache, Application-side codec/semantic cache, host/CLI, debt/waiver/enforcement, report serialization, publication, or authority API. |
| Hosted ownership plan | Only after all focused and combined green: atomically activate Status/Automation/owner/both filters/[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146); retain one locked-restore CLI invocation and one solution test CLI invocation per stable job, allow exactly Domain.Tests plus the deliberate new Conformance.Tests testhost, reconcile exact per-project counts, and keep the unchanged 35-minute Windows timeout. |

Transient red is never pushed or published and receives no root,
StructureOnly, combined, hosted, workflow, or scenario-owner validation. This
matrix grants no source, project, lock, workflow, owner, red-execution, or
implementation authority.

## [TEST-0221](#test-0221) Gate 2 expected-red matrix

The normative detailed matrix is in the
[detailed design matrix](subf-0153-evidence-contract-design.md#test-0221-expected-red-contract).
Fresh expected-red code must directly cover these groups:

| Contract group | Required boundary |
| --- | --- |
| Exact API ownership | [TEST-0220](#test-0220) retains the exact PredecessorInventory API; [TEST-0221](#test-0221) owns exact equality between product exports and CumulativeInventory plus exact SliceInventory API. Normative lists, not handwritten counts, determine size. |
| Project and restore graph | [TEST-0220](#test-0220) remains sole direct owner of solution/project/package/lock/effective-restore graph. [TEST-0221](#test-0221) proves only that SliceInventory is exported by the existing Domain assembly. |
| Vocabulary/semantic owners | Strict namespaced tokens and version text; catalog requirement tokens, [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) adapter/source/failure tokens, and release-bound payload schemas are distinct. |
| Target/boundary/scope | Exact subject/source mapping, SnapshotKind-specific target/boundary identities, UTC interval, EvidenceScope membership, and repository/provider/release/snapshot location constraints. |
| Payload/binding/reference | Canonical bytes are copied and ContentDigest is derived; schemas and requirement keys match; bindings are structural untrusted assertions; context alone projects exact root references; parser-derived references remain [SUBF-0143](README.md#subf-0143). |
| Requirement/context | Accepted consistency, scoped redaction/failure, zero-object negative inventory, paged/interrupted/non-paged counts and cursor chains, structural empty-context proof, derived status, order, equality, and defensive copying. |
| Result union | Observed carries a Complete/Incomplete context; absent has no attempt and is Incomplete; failed has no valid context and covers every requirement; no fourth status or failure envelope. |
| Expected-red purity | After byte-identical locked restore, only focused [TEST-0221](#test-0221) runs and fails solely for absent SliceInventory. StructureOnly/root/hosted validation is prohibited on transient red. |
| Negative surface | No provider DTO/object/dynamic/raw cursor/ETag/credential, I/O/adapter/parser/catalog/evaluator/finding/report/host/CLI/debt/waiver/publication/authority API. |
| Hosted ownership plan | After focused/combined green only, Status/Automation/traits/owner/both filters/[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) change atomically; each stable job retains exactly one locked-restore CLI invocation and one protocol test CLI invocation. A later Conformance.Tests project may add one distinct testhost only under the separately accepted [TEST-0210](#test-0210) budget contract. |

The scoped [activation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5135051435)
consumed this matrix. The valid reflection inventory red selected and executed
exactly `1/1` test and failed solely because all `23` declared SliceInventory
public types were absent. No restore, compile, predecessor, environment, or
workflow-discovery failure contaminated the red.

## Required coverage

- [SUBF-0152](README.md#subf-0152) exact scalar grammar, independent axes/outcomes, immutable sets,
  project graph, and invalid-state prevention.
- [SUBF-0153](README.md#subf-0153) governed evidence schemas, target/boundary
  scope, canonical payloads, typed locations, bindings, contexts, and
  acquisition-result union.
- [SUBF-0143](README.md#subf-0143) release-bound typed decoders/models,
  catalog transition, applicability, findings/evaluation records, evaluator
  qualification, and deterministic aggregation.
- [SUBF-0144](README.md#subf-0144) protected extension activation, debt/waiver semantics, and
  predecessor-trusted self-consumption.
- [SUBF-0154](README.md#subf-0154) report completeness, redaction, canonical bytes, digest, and
  cross-platform equality.
- [TEST-0209](#test-0209) direct composed production qualification across those boundaries;
  child-test results are not its product oracle.

## Evidence

[TEST-0220](#test-0220) began from expected-red checkpoint
[`9a48c02266d9690e14240de0fac3c57d54d12fa6`](https://github.com/hasanmanzak/meAndAI/commit/9a48c02266d9690e14240de0fac3c57d54d12fa6).
A fresh locked restore succeeded. The exact filtered Release command from the
[canonical execution route](subf-0152-domain-vocabulary-design.md#canonical-execution-route)
then failed only with `CS0246` for deliberately absent `SurfaceSet` and
`SurfaceKind` production contracts.

After the bounded production implementation, a recorded execution of that same
exact command passed 52 of 52 tests with zero failed and zero skipped in 116 ms.
The explicit protocol solution Release build completed in 1.45 seconds with
zero warnings and zero errors, and `dotnet format` verification at severity
`info` was clean. The existing
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
direct workflow-topology owner passed on PowerShell 7 and Windows PowerShell
5.1. [TEST-0220](#test-0220) now has the sole `DotNetTestProject` authority in
`tests/scenario-ownership.psd1`.

Final StructureOnly passed with exit zero and zero failures on PowerShell 7 in
approximately 160.5 seconds and on Windows PowerShell 5.1 in 275.9 seconds; the
Windows owner observation was 273,271 ms. Gate 5 code/test and infrastructure
fresh-diff reviews were clean after all findings were resolved, and the latest
correction review was clean.

[PR #170](https://github.com/hasanmanzak/meAndAI/pull/170) then merged the exact
validated implementation. Exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da)
passed [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506)
on [Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506/job/90771124477)
and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506/job/90771124470).
That closes [TEST-0220](#test-0220) and [SUBF-0152](README.md#subf-0152).

[TEST-0221](#test-0221) Gate 2 began with the historical
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253).
[PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) merged the accepted
[design](subf-0153-evidence-contract-design.md) at exact main
[`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f),
and the [closure comment](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520)
records bounded design validation. Its required typed-handoff predecessor was
then accepted, merged, and bounded exact-main validated at
[`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7).

The scoped
[activation directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5135051435)
then authorized [TEST-0221](#test-0221) Gate 3. The historical local candidate
evidence was:

- expected red: the reflection inventory test selected/executed `1/1` and
  failed solely because all `23` SliceInventory public types were absent;
- scoped lock-file fingerprints remained unchanged:
  `src/MeAndAI.Protocol.Domain/packages.lock.json` at `03EE...CB46` and
  `tests/dotnet/MeAndAI.Protocol.Domain.Tests/packages.lock.json` at
  `D206...00BC`;
- focused [TEST-0221](#test-0221): `46/46` passing;
- combined [TEST-0220](#test-0220)/[TEST-0221](#test-0221): `98/98` passing in
  the existing Domain.Tests testhost;
- Gate 5 retained only public-observable coverage and removed the private-
  reflection oracle from the final green suite; the valid historical expected
  red is unchanged;
- local [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  owner/topology verification: green;
- explicit Release build: `0` warnings and `0` errors;
- `dotnet format` verification at severity `info`: clean; and
- no solution, project, package, project-reference, dependency, effective-
  restore, or lock graph expansion.

[TEST-0221](#test-0221) is `Passing` with Automation owned by
`tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`
through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173), exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd),
and exact-main [run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256).
The local measurements above are retained as historical expected-red and
pre-publication green evidence, not as the current lifecycle state.

The [TEST-0210](#test-0210) Gate 3 working tree now contains the exact six-
project/reference/lock scaffold, predecessor ownership transition, canonical A
SurfaceRed, the cumulative-A 48-type structural surface, and the first
same-FQN BehaviorRed source. Locked restore remained byte-identical and the
focused ownership/public-API structural checkpoint passed `11/11`. Its Gate 2
design was accepted, merged, and bounded exact-main validated at
[`23d27478af09446363bcb299dee24957e3a206a7`](https://github.com/hasanmanzak/meAndAI/commit/23d27478af09446363bcb299dee24957e3a206a7),
and the corrected [SUBF-0143](README.md#subf-0143) ContractSlice A
[Gate 3 directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228)
plus append-only [message/echo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
and [RunInfo](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
clarifications now govern the work; [FIND-0440](README.md#find-0440) owns the
RunInfo evidence-contract correction. Each BehaviorRed observed before its
applicable clarification remains diagnostic only and does not satisfy the
successor scenario. Renewed review of the topology/parser and RunInfo
corrections passed `0 Blocking` / `0 Important` / `0 Minor`.

The fresh post-synchronization one-invocation run used a newly created,
initially empty external directory, the exact A FQN and marker, and one TRX
logger. It exited nonzero and produced exactly one TRX at
`D:\Temp\meandai-test-0210-a-canonical-54b33df16d7446be918f0a3cb75d3c28\TEST-0210-A-BEHAVIOR-RED-0001.trx`.
Its sole mapped result is Failed with one exact marker message and one permitted
`StdOut` marker echo. Its sole `RunInfo` is the exact marker-free same-FQN
`[FAIL]` bookkeeping shape with `outcome="Error"`; the summary is Failed and all
16 counters are exact, including `total=1`, `executed=1`, `failed=1`,
`passed=0`, and `error=0`, with every remaining counter zero. The standard
failed-result assertion stack is marker-free, and there is no independent
diagnostic or attachment. This is the canonical first A BehaviorRed.
It remains the predecessor evidence for the reviewed first limited green.

The sentinel was then replaced by the first limited ParseCanonical
implementation. Its Release `--no-restore` production build completed with zero
warnings and zero errors. With the original red oracle unchanged, the exact FQN
passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-91b9a19a6db741c6af2e5bac3a1a22b0\TEST-0210-A-GREEN-0001.trx`.
After the transient marker constant and null-only `Assert.Fail` branch were
removed, canonical equality was moved before digest/object construction. Format
verification and the final six-project Release build passed with zero warnings
and zero errors. The final-source exact FQN passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-62a34655387e4306b0bc26c9203fb97d\TEST-0210-A-GREEN-FINAL-0001.trx`,
and the cumulative `ContractSlice=A` filter passed `12/12`.

The green assertion set validates the exact 1,222-byte fixture, all typed
projections and ordering, manifest/artifact digests, null `CompleteCatalog`, and
caller-buffer mutation independence. Source review confirms the pre-copy 16 MiB
limit, private `ToArray` parse/hash boundary, canonical typed-reserialization
equality, and absence of retained raw bytes. The private input copy and writer-
returned reserialization byte array are zeroed in `finally`; the
`ArrayBufferWriter` internal buffer becomes unreachable and is not retained by
the manifest but is not explicitly zeroed.

The first-green support review closed with `0 Blocking`, one unnumbered
remaining-A coverage `Important`, and no unresolved `Minor`. The then-current
writer's `UnsafeRelaxedJsonEscaping` was exact for that ASCII fixture but was not
proof of raw printable-Unicode preservation, lowercase control escaping, or
malformed-Unicode boundaries. Those canonical-string cases therefore received
the separately reviewed exact FQN, marker, fixture matrix, and absent-behavior
predicate below. Their later bounded green closed that one coverage `Important`;
the ordering observation remains closed by equality-before-digest/object
construction and the zeroization wording remains corrected above.

[TEST-0210](#test-0210) remains `Planned`: neither the first limited A behavior
increment nor the later canonical-string green completes remaining A, and
preserved WIP or diagnostic runs do not satisfy any successor increment.

### Second A canonical-string exact-red and bounded-green closure

This increment remains [TEST-0210](#test-0210)/`ContractSlice=A`; it adds no
stable scenario identity. The exact `[Fact]` FQN is
`MeAndAI.Protocol.Conformance.Tests.ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding`,
and its exact marker/TRX filename is `TEST-0210-A-BEHAVIOR-RED-0002`.

The writer-owned internal seam is
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)`. Its behavior-
preserving pre-red extraction retains the legacy `UnsafeRelaxedJsonEscaping`
bytes and routes the returned quoted token through validated `WriteRawValue`.
Only the design's complete frozen legacy probe output may emit the marker; the
green output owns exact quote/backslash/raw-slash behavior, short named C0
escapes, lowercase remaining C0/DEL/C1 escapes, and raw non-normalized printable
Unicode.

`BoundedJsonReader.ReadString` slices the complete original quoted token by
`TokenStartIndex..BytesConsumed`, catches only `InvalidOperationException` from
its direct `GetString()` call as `FormatException`, re-encodes the decoded value
with that same codec, and ordinal-compares the complete quoted byte sequences.
A mismatch fails before typed factories. No second string grammar/parser exists;
only codec `ArgumentException` caused through this document re-encode is mapped
to `FormatException`, while direct malformed .NET UTF-16 remains internal
argument-boundary `ArgumentException`.

The positive integration fixture replaces only `assemblyName` with
`MeAndAI.Protocol.　Unicode.𠮟.Tests`. It is exactly 1,226 bytes including LF,
has SHA-256
`5195e1a4b36b8b57a96fbd774fb78c5d46878948f91ee597e66ef6f44821a928`,
and contains raw `E3 80 80` plus `F0 A0 AE 9F` exactly once each. Its escaped
`U+3000` and lower/uppercase valid surrogate-pair alternatives are
noncanonical. Lowercase canonical control lexemes reach the opaque factory and
its document-caused `ArgumentException` becomes public `FormatException`;
uppercase hex, long-form named controls, and raw C1 fail lexically before the
factory. Invalid raw UTF-8 covers isolated continuation, overlong, surrogate,
truncated, and above-maximum sequences. Escaped Unicode covers lone high/lone
low/reversed/high-plus-ASCII failures. Direct malformed .NET UTF-16 supplied to
the internal codec is instead an argument-boundary `ArgumentException`; every
malformed raw or escaped public document remains `FormatException`.

The exact non-normalization vector passes `é` (`U+00E9`) and `é`
(`U+0065 U+0301`) independently. Their raw strict-UTF-8 value bytes are
respectively `C3 A9` and `65 CC 81`; they remain ordinally distinct, and neither
input or output is normalized to the other.

The complete probe units, legacy/green quoted hex, transformations, and
exception taxonomy are normative in the
[second A design](subf-0143-typed-evaluation-kernel-design.md#second-a-increment---canonical-quoted-utf-8-strings).
The exact old-FQN seam predecessor passed `1/1` at
`D:\Temp\meandai-test-0210-a-seam-1d7c48a903be4f31a6e2c59b708d4fa1\TEST-0210-A-SEAM-NOOP-0002.trx`.
The valid red at
`D:\Temp\meandai-test-0210-a-8b7f24d6c19a4e03b5f1728a90c4d6e1\TEST-0210-A-BEHAVIOR-RED-0002.trx`
and bounded source review each closed `0 Blocking`/`0 Important`/`0 Minor`.
The original-oracle green with its marker still present passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-3c6d91a5e8f247b0a1c4d7e9f2b5a630\TEST-0210-A-GREEN-0002.trx`.
After marker/legacy-branch removal and an absent source search, final-source
passed `1/1` at
`D:\Temp\meandai-test-0210-a-green-final-5e2a7c91d4f84360b8e1a3c6f9072d54\TEST-0210-A-GREEN-FINAL-0002.trx`
and cumulative A passed `13/13` at
`D:\Temp\meandai-test-0210-a-cumulative-7a3e6d20f9514bc8a2d5e7f039c6b184\TEST-0210-A-GREEN-CUMULATIVE-0002.trx`.

Locked restore, unchanged six lock fingerprints, standard format verification,
`git diff --check`, and the zero-warning/zero-error six-project Release build
passed. The non-gating severity-info scan found pre-existing informational/flat-
namespace backlog and suggestions, so it is not claimed clean. This closes the
canonical-string coverage `Important`, not full A. `TEST-0210` remains `Planned`;
remaining A and workflow/scenario-owner/
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D,
root, combined, hosted, WIP, consumer, release, publication, authority-transfer,
and PowerShell-retirement scope remain held.
