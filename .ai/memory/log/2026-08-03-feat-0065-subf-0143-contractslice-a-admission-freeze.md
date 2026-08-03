# ContractSlice A admission-proof FrozenDesign handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-03 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-ADMISSION-01` is `FrozenDesign`; D/RT is complete, while locked restore, canonical R, C# mutation, green verification, synchronized freeze commit/push, and exact-head hosted validation remain pending |
| Exact predecessor | [`2bbd36f5dd9ee975778063719fe8f879873e00d5`](https://github.com/hasanmanzak/meAndAI/commit/2bbd36f5dd9ee975778063719fe8f879873e00d5), git tree identity `fe543889cc68fad6a61139f0125a41ca4050ce40`, passed Ubuntu in `17m11s` and Windows in `14m43s` in [run 30772197693](https://github.com/hasanmanzak/meAndAI/actions/runs/30772197693); publication verification was correctly skipped |
| Progress | Eleven of twenty live packets are `ReviewedLocalGreen` (`55%`); cumulative A is `24/24`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen ownership and absent behavior

- `ReleaseSchemaRegistry` and `AdmissionProofContractDeclaration` already own typed declaration snapshotting, canonicalization, composite `(contractKey, contractVersion, kind)` identity, kind rank, lookup, surfaces, and material-role values. They are regression-only in this packet.
- The exact predecessor still stages admission declarations off at three boundaries: `CanonicalManifestWriter` rejects a non-empty collection and emits an empty array, `CanonicalManifestReader` accepts/reconstructs only an empty collection and omits proof components from declaration closure, and `CatalogSliceDeclaration.ValidateSchemaSlotClosure` rejects every non-empty admission collection.
- The smallest correction therefore belongs only to `src/MeAndAI.Protocol.Conformance.Abstractions/Manifest/CanonicalManifestReader.cs`, `src/MeAndAI.Protocol.Conformance.Abstractions/Manifest/CanonicalManifestWriter.cs`, and `src/MeAndAI.Protocol.Conformance.Abstractions/Catalog/CatalogSliceDeclaration.cs`.
- Empty admission remains valid for the exact selector predecessor. Once admission rows exist, Catalog requires exactly one `Observed`, one `Failed`, and one `NoInput` row, a distinct proof component for every row, and every row's surfaces/material roles to equal the complete slot surface/material-role union. Reader resolves every proof component and keeps admission, activation-proof, runtime-anchor, and other functional declaration partitions disjoint.
- No generic non-empty rule is added to `AdmissionProofContractDeclaration.Create`; the exact non-empty closure belongs to the nonzero manifest topology, not the reusable token collection factory.

## Frozen expected-red contract

- R is `Applicable / BehaviorRed`; P is `NotApplicable`. The unchanged exact predecessor already passed selector focused `1/1` and cumulative `ContractSlice=A` `24/24` and needs no preparatory production seam.
- Reserved FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceAAdmissionProofManifestTests.Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure`; one Fact; only `ContractSlice=A`; no `Scenario`.
- Exact marker/TRX stem: `TEST-0210-A-BEHAVIOR-RED-0009`.
- The fully valid typed fixture is constructed outside the oracle. The first cross-graph observation invokes Writer. Only exact runtime type `InvalidOperationException` with exact message `This writer increment supports only the minimal qualification slice.` may directly call `Assert.Fail("TEST-0210-A-BEHAVIOR-RED-0009")`; setup, Catalog, type/message filter mismatch, or any other exception propagates marker-free.
- Canonical R is one fresh external-directory, exact-FQN, `--no-restore --no-build` invocation with process-scoped `VSTEST_CONNECTION_TIMEOUT=300`, a 420-second outer bound, one selected/executed/failed result, exact marker message, all sixteen counters, only accepted same-result adapter presentation, no attachment, and recorded TRX/source SHA-256. It is immutable and may not be rerun.
- Retained green removes the legacy catch/marker and feeds that same Writer result through canonical bytes, Reader, byte-identical Writer, digest, topology, wire, and negative assertions.

## Frozen synthetic topology

- The selector predecessor remains exact: three schemas, two parsers, four indexes, zero demand projectors, four evaluation slots, two selectors, two findings, twenty-two components, and three artifacts.
- Admission adds three declarations sharing synthetic key/version `protocol.test.admission-proof` / `1`. Reversed typed input is `NoInput`, `Failed`, `Observed`; canonical output is `Observed`, `Failed`, `NoInput`, directly proving the accepted proof-kind rank within the composite identity.
- The three distinct component keys are `protocol.admission-proof.test-observed`, `protocol.admission-proof.test-failed`, and `protocol.admission-proof.test-no-input`, with distinct Tests-owned proof types in assembly `MeAndAI.Protocol.Conformance.Tests`; all map to the existing `ContractSliceA.Proof.dll` artifact.
- Each row receives reversed Provider/Repository surfaces and the reversed complete role set. Canonical surfaces are Repository, Provider; canonical material roles are `protocol.material.governed-text`, `protocol.material.repository-target-resolution`, `protocol.material.repository-tree`.
- The successor topology is exactly twenty-five components and three artifacts. Removing all three declarations and all three proof-component mappings must reproduce the valid twenty-two-component/three-artifact selector predecessor. Partial declarations/components, shared proof components, activation/admission overlap, missing proof components, declaration-free orphan proof components, missing or undeclared component/artifact mappings, and extra proof rows fail closed. A valid parsed mapping that differs from the actual loaded artifact set remains the later `ArtifactMismatch` boundary and is not claimed here.
- Real `protocol.admission.*` keys, Application proof types, the six-artifact/thirty-five-component production inventory, and exact real five-rule rows remain owned by `A-CONVERGE-01`.

## Frozen retained-test matrix and caps

- Prove registry snapshot/mutation independence, composite lookup, exact three-kind order, unique proof components, exact surfaces/material roles, component/artifact closure, Writer -> Reader -> Writer byte identity, and manifest digest identity.
- Prove exact admission wire-field order `contractKey`, `contractVersion`, `kind`, `proofComponent`, `surfaces`, `materialRoles`, plus positive nested `componentKey`, `componentVersion` order.
- Own exactly forty-two malformed-wire vectors: each of six outer fields missing/duplicate/null/wrong type; one extra field; five adjacent swaps; unknown kind; surface unknown/duplicate/reversed/empty; material-role undeclared/duplicate/reversed/empty; and admission-array null-entry/reversed/duplicate. Exhaustive nested component-reference grammar remains with its earlier owner.
- Production gross targets/hard caps are Reader `105-135/145`, Writer `20-45/55`, Catalog `75-100/110`, aggregate production `220-280/310`. The sole new test target/hard cap is `330-360/370`; combined target/hard cap is `550-640/680`. Forecasting or exceeding any hard cap returns to D/RT before implementation; assertions may not be compressed or removed to fit.
- D/RT and the reconciled independent review each closed `0 Blocking / 0 Important / 0 Minor` on the shared-key rank fixture, Writer-first exact legacy predicate, three-file production allowlist, 680-line combined hard cap, matrix, and holds.

## Held scope and next gate

- The synchronized thirteen-record freeze cohort passed full `StructureOnly` with `elapsedMs=367302`. The bounded publication-evidence suite passed [TEST-0083](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0083), [TEST-0176](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178), [TEST-0180](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180), [TEST-0181](../../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181), [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182), and [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189) in `236.5` seconds without claiming published-state evidence.
- Independent architecture/semantic review, evidence/traceability review, and exact thirteen-record cohort review each closed `0 Blocking / 0 Important / 0 Minor` after the stale selector-delivery sentence, missing reciprocal handoff link, and over-broad artifact-mapping wording were corrected. Final `git diff --check` was clean; no C# or test source entered the cohort.
- Demand projector/DAG, real Policy/Application inventory, activation/export, runtime proof admission, candidate/receipt/request/instruction semantics, cache/replay/causality, `A-CONVERGE-01` and every later A packet remain inactive.
- ContractSlice B/C/D, final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), merge, release, publication, consumer mutation, authority transfer, WIP extraction, and PowerShell retirement remain held.
- This freeze changes no C# or test source and does not increase `11/20`, `55%`, or `24/24`. Canonical R and implementation may begin only after this thirteen-record freeze cohort is reviewed, committed, pushed, and exact-head hosted green.
