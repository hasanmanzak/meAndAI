# FEAT-0065 Test Scenarios

Only [SUBF-0152](README.md#subf-0152) / [TEST-0220](#test-0220) has
test-first authority and is locally converged. Exact-head and hosted evidence
remain pending. Every later scenario remains planned and unauthorized. The
architecture merge and
exact-main prerequisite are satisfied by
[PR #169](https://github.com/hasanmanzak/meAndAI/pull/169) and
[run 30483054367](https://github.com/hasanmanzak/meAndAI/actions/runs/30483054367).

| ID | Related slice | Scenario | Expected result | Level | Intent review | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `TEST-0209` <a name="test-0209"></a> | [FEAT-0065](README.md) composed qualification across [SUBF-0152](README.md#subf-0152), [SUBF-0153](README.md#subf-0153), [SUBF-0143](README.md#subf-0143), [SUBF-0144](README.md#subf-0144), and [SUBF-0154](README.md#subf-0154) | Vary rule, evidence, typed location, profile axes, acquisition state, evaluation state, debt, waiver, enforcement, and report values, including missing, duplicate, stale, unknown, malformed, and redacted data. | Invalid combinations fail construction. Valid reports preserve acquisition, per-rule evaluation, conformance verdict, and enforcement decision as four separate dimensions: incomplete/failed required acquisition creates `NotEvaluated` and aggregate `Indeterminate`, known violations remain visible, and enforcement follows the accepted phase/waiver/debt precedence. Canonical serialization, ordering, and digest are identical across supported runtimes and operating systems. | Component / contract / serialization | Nearest same-contract sibling: the [preserved WIP model scenario](https://github.com/hasanmanzak/meAndAI/blob/1873c98638ba4960734aadb188eb8c8d70b4bc52/docs/features/FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` because it directly exercises the composed production model with typed multi-surface locations and separated result dimensions, rather than aggregating child-test results or reusing the bounded repository report. | Planned | Future composed .NET qualification tests |
| `TEST-0210` <a name="test-0210"></a> | [SUBF-0143](README.md#subf-0143) | Build the first catalog from [RULE-0001](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001) through [RULE-0005](../../architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005); vary normative provenance, evaluator binding, applicability, required evidence, ordering, duplicate/missing/unmapped rules, and repository/provider material variants. | The same compiled evaluator owns each semantic rule on every applicable surface; exact qualified inputs match canonical scenarios, inventory defects fail closed, and deterministic findings contain typed locations and provenance. | Unit / component / qualification | Nearest same-contract siblings: [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), and [TEST-0175](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175); Distinct shared C# catalog/evaluator contract rather than a duplicate scenario owner. | Planned | Future .NET qualification tests |
| `TEST-0211` <a name="test-0211"></a> | [SUBF-0144](README.md#subf-0144) | Evaluate protected baseline plus valid/invalid extensions, waivers, historical debt, policy activation snapshots, previous-trusted runtime, candidate runtime, differential results, and attempted candidate self-certification. | Extensions are additive and namespaced, baseline enforcement cannot be lowered, waiver/debt effects follow the deterministic truth table, stale activation fails closed, and authority transfer remains impossible from candidate-only evidence. | Component / security / differential | Nearest same-contract sibling: [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163); Distinct protocol-runtime bootstrap and protected-policy contract. | Planned | Future .NET qualification and differential tests |
| `TEST-0220` <a name="test-0220"></a> | [SUBF-0152](README.md#subf-0152) | Vary exact rule identity/revision and SHA-256 values, every closed profile/outcome token, SurfaceSet order/duplicates/mutability, ExecutionProfile axes, and the new project graph. | Invalid lexical, range, null, duplicate, and cross-dimension values fail closed; valid values are immutable and ordinal-exact; SurfaceSet and profile equality are input-order independent; the Domain assembly is BCL-only and no outcome dimension implies another. | Unit / architecture / contract | Nearest siblings: [TEST-0191](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191), [TEST-0192](../FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192), and preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195); `Distinct` scalar invalid-state and independent-axis contract in the new protocol Domain assembly. | Passing | `tests/dotnet/MeAndAI.Protocol.Domain.Tests/MeAndAI.Protocol.Domain.Tests.csproj` |
| `TEST-0221` <a name="test-0221"></a> | [SUBF-0153](README.md#subf-0153) | Vary requested/acquired evidence requirements, completeness and consistency, repository/provider/release/snapshot typed locations, findings, and rule-evaluation records. | A missing required envelope is retained as an absent-input fact and rolls up to `Incomplete`; it remains distinct from a present but invalid source that yields `Failed`. Ambiguous/untyped locations and invalid finding/evaluation combinations fail construction; immutable inputs are defensively retained. | Unit / contract | Nearest same-contract siblings are umbrella [TEST-0209](#test-0209) and preserved [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195). `Distinct` by evidence-ambiguity risk, multi-surface typed-location and composite-record scope, direct unit/contract evidence, and construction boundary rather than composed report qualification or the bounded repository-only WIP model. | Planned | Future .NET contract tests; implementation not authorized |
| `TEST-0222` <a name="test-0222"></a> | [SUBF-0154](README.md#subf-0154) | Seal the complete typed report after catalog evaluation and debt/waiver disposition; vary input order, culture, operating system, line endings, redaction, missing dimensions, and digest tampering. | The report is complete or fails closed; canonical bytes, collection order, and digest are schema-exact across supported runtimes and systems; raw content and credentials are absent. | Component / serialization / cross-runtime | `Distinct` from [TEST-0209](#test-0209) by canonical-byte/digest nondeterminism risk and report-sealing boundary rather than composed semantic evaluation. | Planned | Future .NET report qualification tests; implementation not authorized |

## Required coverage

- [SUBF-0152](README.md#subf-0152) exact scalar grammar, independent axes/outcomes, immutable sets,
  project graph, and invalid-state prevention.
- [SUBF-0153](README.md#subf-0153) governed evidence kinds, completeness, typed locations, findings,
  and evaluation records.
- [SUBF-0143](README.md#subf-0143) catalog transition, rule revision, evaluator qualification, and
  deterministic aggregation.
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

Exact-head and both hosted stable jobs remain pending. Pull-request and hosted
evidence are external to the candidate tree and governed by
[issue #165](https://github.com/hasanmanzak/meAndAI/issues/165). Preserved WIP
runs remain historical oracles only and do not satisfy this scenario.
