# FEAT-0065 Test Scenarios

[SUBF-0152](README.md#subf-0152)/[TEST-0220](#test-0220) is complete through
[PR #170](https://github.com/hasanmanzak/meAndAI/pull/170), exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).
The architecture prerequisite remains [PR #169](https://github.com/hasanmanzak/meAndAI/pull/169)
and [run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).

The 2026-07-30
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
authorizes only Gate 1/2 design and expected-red planning for
[SUBF-0153](README.md#subf-0153)/[TEST-0221](#test-0221). It does not authorize
test source, expected-red execution, product code, workflow or scenario-owner
mutation, or any other later scenario.
Gate 3 additionally requires maintainer acceptance, merge of the accepted
[SUBF-0153](README.md#subf-0153) design, validation of its exact-main commit, then maintainer
acceptance, merge, and exact-main validation of the separate [SUBF-0143](README.md#subf-0143)
typed-handoff Gate 2 design, and finally a separate implementation directive.

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0209` <a name="test-0209"></a> | [FEAT-0065](README.md) composed qualification across [SUBF-0152](README.md#subf-0152), [SUBF-0153](README.md#subf-0153), [SUBF-0143](README.md#subf-0143), [SUBF-0144](README.md#subf-0144), and [SUBF-0154](README.md#subf-0154) | Vary rule, evidence, typed location, profile axes, acquisition state, evaluation state, debt, waiver, enforcement, and report values, including missing, duplicate, stale, unknown, malformed, and redacted data. | Invalid combinations fail construction. Valid reports preserve acquisition, per-rule evaluation, conformance verdict, and enforcement decision as four separate dimensions: incomplete/failed required acquisition creates `NotEvaluated` and aggregate `Indeterminate`, known violations remain visible, and enforcement follows the accepted phase/waiver/debt precedence. Canonical serialization, ordering, and digest are identical across supported runtimes and operating systems. | Component / contract / serialization | Nearest same-contract sibling: the [preserved WIP model scenario](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` because it directly exercises the composed production model with typed multi-surface locations and separated result dimensions, rather than aggregating child-test results or reusing the bounded repository report. | Planned | Future composed .NET qualification tests |
| `TEST-0210` <a name="test-0210"></a> | [SUBF-0143](README.md#subf-0143) | Build the first catalog from [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001) through [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005); vary normative provenance, release-bound canonical codec/model/index bindings, observed/failure/absence admission receipts, two-tier parse/index caching, qualified context-proof/root/derived references, two-phase applicability/evaluation requirements, deterministic resource exhaustion versus host cancellation, evaluation readiness/failures, ordering, duplicate/missing/unmapped rules, and repository/provider material variants. | The same compiled evaluator owns each semantic rule on every applicable surface; only receipt-qualified observed/failed or kernel-synthesized absent inputs enter the sealed typed context; zero-binding absence/coverage findings retain qualified context provenance; false applicability requires no evaluation-only evidence and yields a referenced zero-finding/zero-failure NotApplicable, while unresolved applicability yields NotEvaluated; semantic budgets are deterministic and host cancellation stays operational; document and provider bodies share provider-neutral capabilities; cache keys remain release/context safe; inventory or integrity defects fail closed; and kernel-minted evaluations/findings contain exact sealed provenance. | Unit / component / qualification | Nearest same-contract siblings: [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), and [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175); Distinct shared C# catalog/typed-model/evaluator contract rather than a duplicate scenario owner. | Planned | Future .NET qualification tests; its typed-handoff Gate 2 design is a prerequisite for [SUBF-0153](README.md#subf-0153) implementation |
| `TEST-0211` <a name="test-0211"></a> | [SUBF-0144](README.md#subf-0144) | Evaluate protected baseline plus valid/invalid extensions, waivers, historical debt, policy activation snapshots, previous-trusted runtime, candidate runtime, differential results, and attempted candidate self-certification. | Extensions are additive and namespaced, baseline enforcement cannot be lowered, waiver/debt effects follow the deterministic truth table, stale activation fails closed, and authority transfer remains impossible from candidate-only evidence. | Component / security / differential | Nearest same-contract sibling: [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163); Distinct protocol-runtime bootstrap and protected-policy contract. | Planned | Future .NET qualification and differential tests |
| `TEST-0220` <a name="test-0220"></a> | [SUBF-0152](README.md#subf-0152) | Vary exact rule identity/revision and SHA-256 values, every closed profile/outcome token, SurfaceSet order/duplicates/mutability, ExecutionProfile axes, and the new project graph. | Invalid lexical, range, null, duplicate, and cross-dimension values fail closed; valid values are immutable and ordinal-exact; SurfaceSet and profile equality are input-order independent; the Domain assembly is BCL-only and no outcome dimension implies another. | Unit / architecture / contract | Nearest siblings: [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191), [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192), and preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` scalar invalid-state and independent-axis contract in the new protocol Domain assembly. | Passing | `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj`; completed slice evidence is recorded below |
| `TEST-0221` <a name="test-0221"></a> | [SUBF-0153](README.md#subf-0153) | Vary the exact inventory-derived [evidence-acquisition design](subf-0153-evidence-contract-design.md): requirement schemas, request target, observed boundary/scope, asserted-canonical payload, typed locations, bindings/root references, requirement acquisition, pagination, context, and observed/absent/failed result variants. | Schema-identified content is immutable and content-addressed but remains an untrusted assertion until exact [FEAT-0067](../FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md) qualification; source/snapshot scope is structural; absent is `Incomplete`; failed has no valid context and remains `Failed`; requirement/context status is derived; invalid API, pagination, reference, schema, redaction, failure, collision, and union combinations fail construction. | Unit / architecture / contract | Same-contract classifications are fixed in the [design inventory](subf-0153-evidence-contract-design.md#distinct-test-intent-and-sibling-inventory). `Distinct` acquisition/evidence substrate rather than [SUBF-0143](README.md#subf-0143) codec/typed-model/derived-reference/finding/evaluation behavior, composed reports, or repository-only WIP. | Planned | Bounded Gate 2 red-team clean; existing Domain test project only after the [SUBF-0153](README.md#subf-0153) design is accepted, merged, and exact-main validated; the [SUBF-0143](README.md#subf-0143) typed-handoff Gate 2 design is separately accepted, merged, and exact-main validated; and a separate implementation directive is issued; no executable test currently authorized |
| `TEST-0222` <a name="test-0222"></a> | [SUBF-0154](README.md#subf-0154) | Seal the complete typed report after catalog evaluation and debt/waiver disposition; vary input order, culture, operating system, line endings, redaction, missing dimensions, and digest tampering. | The report is complete or fails closed; canonical bytes, collection order, and digest are schema-exact across supported runtimes and systems; raw content and credentials are absent. | Component / serialization / cross-runtime | `Distinct` from [TEST-0209](#test-0209) by canonical-byte/digest nondeterminism risk and report-sealing boundary rather than composed semantic evaluation. | Planned | Future .NET report qualification tests; implementation not authorized |

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
| Hosted ownership plan | After focused/combined green only, Status/Automation/traits/owner/both filters/[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146) change atomically; each stable job retains exactly one locked restore and one combined test process. |

The planned red may fail only for deliberately absent declared production
contracts. No test source, owner transfer, command change, or red execution is
authorized by this matrix.

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

[TEST-0221](#test-0221) has no executable evidence. Its current authority and evidence are
only the [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
and [Gate 2 design candidate](subf-0153-evidence-contract-design.md). Preserved
WIP runs remain historical oracles and do not satisfy either successor
scenario.
