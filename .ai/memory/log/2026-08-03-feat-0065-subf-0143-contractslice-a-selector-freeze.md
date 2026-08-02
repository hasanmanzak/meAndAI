# ContractSlice A expected-selector frozen-design handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-03 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-SELECTOR-01` is `FrozenDesign`; D/RT, freeze-record local V, and record reviews are complete; expected-red and production mutation are not yet activated; synchronized freeze commit/push/exact-head hosted validation remain pending |
| Exact predecessor | [`2430a67e0140a6c8ce0f26eaebae8aed35259134`](https://github.com/hasanmanzak/meAndAI/commit/2430a67e0140a6c8ce0f26eaebae8aed35259134), git tree identity `893e6f6dc1a6f0a246dc209be650f906e5f5c702`, passed Ubuntu in `18m29s` and Windows in `15m56s` in [run 30767103072](https://github.com/hasanmanzak/meAndAI/actions/runs/30767103072); publication verification was correctly skipped |
| Progress | Ten of twenty packets are `ReviewedLocalGreen` (`50%`); cumulative A is `23/23`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen defect and correction

- Schema 1 permits only `ContextProof`, `Root`, and `Derived` in `ExpectedSelectorDeclaration.AllowedParentKinds`; selector-on-selector nesting is invalid. Current `ExpectedSelectorDeclaration.Create` instead canonicalizes and accepts `QualifiedEvidenceReferenceKind.ExpectedSelector` as a parent.
- The bounded correction canonicalizes `allowedParentKinds` once inside `ExpectedSelectorDeclaration.Create`, then rejects any `ExpectedSelector` member with `ArgumentException`, `ParamName=allowedParentKinds`, and base message literal `Expected selector parent kinds must be ContextProof, Root, or Derived.` Observable `Message` equality means equality to `new ArgumentException(FrozenMessage, nameof(allowedParentKinds)).Message`, so framework-appended parameter text is compared without assuming one platform rendering.
- The sole production allowlist entry is `src/MeAndAI.Protocol.Conformance.Abstractions/Rules/ExpectedSelectorDeclaration.cs`. Production target is `8-18` gross changed lines; hard cap is `20`.
- Shared `CanonicalReferenceKinds` and `ReferenceKindRank` are outside the allowlist. `FindingDeclaration` legitimately needs the shared canonicalizer to accept `ExpectedSelector` finding-reference roles.

## Frozen test and expected-red oracle

- Reserved FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure`; one Fact; only `ContractSlice=A`; no `Scenario`.
- Marker/TRX stem: `TEST-0210-A-BEHAVIOR-RED-0008`.
- The sole test allowlist entry is new `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceASelectorManifestTests.cs`. Test target is `340-430` gross lines with hard cap `500`; combined C# hard cap is `520`. Counts are measured against the exact predecessor.
- Before any sibling assertion or writer call, the first test action is exactly:

```csharp
_ = ExpectedSelectorDeclaration.Create(
    "protocol.test.selector.alpha",
    "protocol.slot.repository-tree",
    "protocol.test.selector-schema.alpha",
    Resolve("protocol.selector.test-alpha"),
    [QualifiedEvidenceReferenceKind.ExpectedSelector],
    [FindingCode.Parse("protocol.test.finding.alpha")]);

Assert.Fail("TEST-0210-A-BEHAVIOR-RED-0008");
```

There is no catch around the factory call. Current code reaches the marker; any unexpected exception is marker-free and invalid R.
- Canonical R requires exactly one discovered/executed/failed exact-FQN result in a fresh external directory. Its failure message must be exactly the marker; only the standard same-result marker-free assertion stack and one byte-identical summary echo are permitted under the established 0003+ oracle. Paths, framework frames, indentation, line numbers, and duplicated presentation are non-oracles.
- Green replaces only the marker branch with `actual.ParamName == nameof(allowedParentKinds)` and `actual.Message == new ArgumentException(FrozenMessage, nameof(allowedParentKinds)).Message`. Any broader production change or changed exception contract returns the packet to D/RT.

## Required retained-test matrix

- Snapshot and canonicalize allowed-parent kinds and allowed-finding codes; accept exactly `ContextProof`, `Root`, and `Derived`; reject `ExpectedSelector` alone and mixed with an allowed kind.
- Reject null, empty, null-element, and duplicate collection inputs at the correct factory boundary. The exact two-selector fixture is: alpha = `protocol.test.selector.alpha`, slot `protocol.slot.repository-tree`, schema `protocol.test.selector-schema.alpha`, resolver `protocol.selector.test-alpha/1`, parents `ContextProof`/`Root`/`Derived`, findings `protocol.test.finding.alpha`/`protocol.test.finding.zeta`; zeta = `protocol.test.selector.zeta`, slot `protocol.slot.repository-governed-text`, schema `protocol.test.selector-schema.zeta`, resolver `protocol.selector.test-zeta/1`, parent `Derived`, finding `protocol.test.finding.zeta`. Input order is zeta then alpha; canonical output is alpha then zeta.
- The exact resolver component rows are `protocol.selector.test-alpha/1` -> assembly `MeAndAI.Protocol.Conformance.Tests`, type `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver`, artifact `ContractSliceA.Proof.dll`; and the corresponding `protocol.selector.test-zeta/1` -> type `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver` in the same assembly/artifact. Every selector references a declared slot and finding code and its resolver closes over these rows.
- Removing the entire `expectedSelectors` collection and both resolver component rows must reproduce the predecessor graph. Keeping selectors while removing either resolver row, or keeping either resolver row while removing the entire selector collection, must fail closure.
- Assert exact expected-selector wire-property order: `selectorKey`, `slotKey`, `selectorSchemaKey`, `resolver`, `allowedParentKinds`, `allowedFindingCodes`; prove Writer -> bytes -> Reader -> Writer byte identity and manifest-digest identity.
- Malformed-wire ownership is limited to the six outer selector fields, their exact order, both selector list fields, and selector-array ordering/null/duplicate boundaries. Nested resolver grammar receives only positive `componentKey`, `componentVersion` order and the orphan-closure negatives above; existing component-reference tests retain exhaustive nested grammar ownership.

## Freeze-record validation evidence

- Full `StructureOnly` passed every discovered contract with `elapsedMs=430703`.
- The publication-evidence suite passed [TEST-0083](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0083), [TEST-0176](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178), [TEST-0180](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180), [TEST-0181](../../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181), [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182), and [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189) in `272.7` seconds without claiming published-state evidence.
- Independent semantic/cap review and independent 13-record/link/grammar review each closed `0 Blocking / 0 Important / 0 Minor` after correcting the exact first-red call, portable exception-message oracle, two-selector/two-resolver topology, malformed-wire ownership, production target, and memory freshness.

## Review and holds

- Independent D/RT closed `0 Blocking / 0 Important / 0 Minor`. The defect, local correction point, marker/FQN, first-red ordering, allowlists, caps, retained matrix, and downstream ownership are exact.
- Real five-rule Policy selector counts, selector/finding pairs, and complete Catalog inventory remain owned by `A-CONVERGE-01`. Runtime resolver behavior, admission, projector/DAG, convergence, complete profile, predecessor, transition, lifecycle, and resource behavior remain later-packet scope.
- Every later packet remains Candidate/inactive. No downstream implementation may activate before this freeze is synchronized, committed, pushed, and exact-head hosted green.
- Final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, publication, WIP extraction, consumer mutation, authority transfer, and PowerShell retirement remain held.
