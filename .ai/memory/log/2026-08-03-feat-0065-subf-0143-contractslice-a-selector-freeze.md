# ContractSlice A expected-selector reviewed-local-green handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-03 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-SELECTOR-01` is `ReviewedLocalGreen` with synchronized commit/push and exact-head hosted delivery complete |
| Finding/design parent | [`2430a67e0140a6c8ce0f26eaebae8aed35259134`](https://github.com/hasanmanzak/meAndAI/commit/2430a67e0140a6c8ce0f26eaebae8aed35259134), git tree identity `893e6f6dc1a6f0a246dc209be650f906e5f5c702`, passed Ubuntu in `18m29s` and Windows in `15m56s` in [run 30767103072](https://github.com/hasanmanzak/meAndAI/actions/runs/30767103072); publication verification was correctly skipped |
| Exact predecessor | [`c97c317fb0d5e734597f43f605fe4f1718aa6d1c`](https://github.com/hasanmanzak/meAndAI/commit/c97c317fb0d5e734597f43f605fe4f1718aa6d1c), git tree identity `7fa1748c59902f027f1bd8ca4cdd66b72194f98e`, passed Ubuntu in `17m33s` and Windows in `15m23s` in [run 30769530904](https://github.com/hasanmanzak/meAndAI/actions/runs/30769530904); publication verification was correctly skipped |
| Exact delivery | [`2bbd36f5dd9ee975778063719fe8f879873e00d5`](https://github.com/hasanmanzak/meAndAI/commit/2bbd36f5dd9ee975778063719fe8f879873e00d5), git tree identity `fe543889cc68fad6a61139f0125a41ca4050ce40`, passed Ubuntu in `17m11s` and Windows in `14m43s` in [run 30772197693](https://github.com/hasanmanzak/meAndAI/actions/runs/30772197693); publication verification was correctly skipped |
| Progress | Eleven of twenty packets are `ReviewedLocalGreen` (`55%`); cumulative A is `24/24`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen defect and correction

- Schema 1 permits only `ContextProof`, `Root`, and `Derived` in `ExpectedSelectorDeclaration.AllowedParentKinds`; selector-on-selector nesting is invalid. At the exact frozen predecessor, `ExpectedSelectorDeclaration.Create` instead canonicalized and accepted `QualifiedEvidenceReferenceKind.ExpectedSelector` as a parent.
- The bounded correction canonicalizes `allowedParentKinds` once inside `ExpectedSelectorDeclaration.Create`, then rejects any `ExpectedSelector` member with `ArgumentException`, `ParamName=allowedParentKinds`, and base message literal `Expected selector parent kinds must be ContextProof, Root, or Derived.` Observable `Message` equality means equality to `new ArgumentException(FrozenMessage, nameof(allowedParentKinds)).Message`, so framework-appended parameter text is compared without assuming one platform rendering.
- The sole production allowlist entry is `src/MeAndAI.Protocol.Conformance.Abstractions/Rules/ExpectedSelectorDeclaration.cs`. Production target is `8-18` gross changed lines; hard cap is `20`.
- Shared `CanonicalReferenceKinds` and `ReferenceKindRank` are outside the allowlist. `FindingDeclaration` legitimately needs the shared canonicalizer to accept `ExpectedSelector` finding-reference roles.

## Frozen test and expected-red oracle

- Reserved FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure`; one Fact; only `ContractSlice=A`; no `Scenario`.
- Marker/TRX stem: `TEST-0210-A-BEHAVIOR-RED-0008`.
- The sole test allowlist entry is new `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceASelectorManifestTests.cs`. Test target is `340-430` gross lines with hard cap `500`; combined C# hard cap is `520`. Counts are measured against the exact predecessor.
- Before any sibling assertion or writer call, the canonical-R first test action was:

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

There was no catch around the factory call. Pre-correction code reached the marker; any unexpected exception would have been marker-free and invalid R.
- Canonical R requires exactly one discovered/executed/failed exact-FQN result in a fresh external directory. Its failure message must be exactly the marker; only the standard same-result marker-free assertion stack and one byte-identical summary echo are permitted under the established 0003+ oracle. Paths, framework frames, indentation, line numbers, and duplicated presentation are non-oracles.
- Retained green replaces only the marker branch with `actual.ParamName == nameof(allowedParentKinds)` and `actual.Message == new ArgumentException(FrozenMessage, nameof(allowedParentKinds)).Message`. Any broader production change or changed exception contract returns the packet to D/RT.

## Required retained-test matrix

- Snapshot and canonicalize allowed-parent kinds and allowed-finding codes; accept exactly `ContextProof`, `Root`, and `Derived`; reject `ExpectedSelector` alone and mixed with an allowed kind.
- Reject null, empty, null-element, and duplicate collection inputs at the correct factory boundary. The exact two-selector fixture is: alpha = `protocol.test.selector.alpha`, slot `protocol.slot.repository-tree`, schema `protocol.test.selector-schema.alpha`, resolver `protocol.selector.test-alpha/1`, parents `ContextProof`/`Root`/`Derived`, findings `protocol.test.finding.alpha`/`protocol.test.finding.zeta`; zeta = `protocol.test.selector.zeta`, slot `protocol.slot.repository-governed-text`, schema `protocol.test.selector-schema.zeta`, resolver `protocol.selector.test-zeta/1`, parent `Derived`, finding `protocol.test.finding.zeta`. Input order is zeta then alpha; canonical output is alpha then zeta.
- The exact resolver component rows are `protocol.selector.test-alpha/1` -> assembly `MeAndAI.Protocol.Conformance.Tests`, type `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestAlphaSelectorResolver`, artifact `ContractSliceA.Proof.dll`; and the corresponding `protocol.selector.test-zeta/1` -> type `MeAndAI.Protocol.Conformance.Tests.ContractSliceATestZetaSelectorResolver` in the same assembly/artifact. Every selector references a declared slot and finding code and its resolver closes over these rows.
- Removing the entire `expectedSelectors` collection and both resolver component rows must reproduce the predecessor graph. Keeping selectors while removing either resolver row, or keeping either resolver row while removing the entire selector collection, must fail closure.
- Assert exact expected-selector wire-property order: `selectorKey`, `slotKey`, `selectorSchemaKey`, `resolver`, `allowedParentKinds`, `allowedFindingCodes`; prove Writer -> bytes -> Reader -> Writer byte identity and manifest-digest identity.
- Malformed-wire ownership is limited to the six outer selector fields, their exact order, both selector list fields, and selector-array ordering/null/duplicate boundaries. Nested resolver grammar receives only positive `componentKey`, `componentVersion` order and the orphan-closure negatives above; existing component-reference tests retain exhaustive nested grammar ownership.

## Canonical R, local green, and validation evidence

- The frozen-design record itself passed full `StructureOnly` with `elapsedMs=430703`; its publication-evidence suite passed [TEST-0083](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0083), [TEST-0176](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178), [TEST-0180](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180), [TEST-0181](../../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181), [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182), and [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189) in `272.7` seconds without claiming published-state evidence. Independent semantic/cap review and independent 13-record/link/grammar review each closed `0 Blocking / 0 Important / 0 Minor`.
- Canonical R ran exactly once at the reserved FQN and failed only with marker `TEST-0210-A-BEHAVIOR-RED-0008`: `D:\Temp\meandai-selector-red-1a30d640d8ab4a349cc8c851c1aeba15\TEST-0210-A-BEHAVIOR-RED-0008.trx`, SHA-256 `7A85D0CC4B1AAF45038E818B3687C10D5F3339EC2ECC53D9D5646C97D5F6D30A`. Transient red source SHA-256 was `FC04D1916D14D5A750FC8A884E353E2A2B3662D052F2EAF9A39E0549E64B8F55`; the production prehash was `5CFA7E3C37F730FA0ED3259A1688BF03C95D8E4B8D6061D9A21737656ABC1146`.
- Retained test source `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceASelectorManifestTests.cs` is `370` lines at SHA-256 `56B9B30AE4432D06644F58331569148EF7729DBE282FB8119634B11397862B69`. Final production SHA-256 is `F4AA63038FCCA7B6DFBCF087E0F97CDC851C980B099840871C66722FADC4AAAF`; production gross delta is `12/20`, and combined C# delta is `382/520`.
- Focused green is `1/1`, SHA-256 `98B2EADB4E111FEFCAB18C46FD3293FD88E88C028E562DE6CEC9B0C7DE33DDB2`; cumulative `ContractSlice=A` is `24/24`, SHA-256 `527DCB9E2799AAEDAA1D6A1083014F005705E66C6E620F174A736926D1418D35`.
- Full Conformance is `24/24`, SHA-256 `7356CC3AD6BD329D84B7694DB5919E7D751C00712216840FE0F562A3F5555532`; full Domain is `98/98`, SHA-256 `8DEBDBBE253F5DB7D2A72C0AD80690123AA6E904AAA50C8DAA8B123E35E7F478`.
- Release build is `0 warnings / 0 errors`; default-severity format, diff, and all six package locks are green. Full `StructureOnly` passed every discovered contract with `elapsedMs=376188`.
- The bounded publication-evidence suite passed the same exact seven IDs above in `244.7` seconds without claiming published-state evidence.

## Review and holds

- Independent D/RT closed `0 Blocking / 0 Important / 0 Minor`. The defect, local correction point, marker/FQN, first-red ordering, allowlists, caps, retained matrix, and downstream ownership remain exact.
- Independent final code/test review and independent evidence audit each closed `0 Blocking / 0 Important / 0 Minor` against the retained two-file C# delta and exact R/G/V evidence.
- Real five-rule Policy selector counts, selector/finding pairs, and complete Catalog inventory remain owned by `A-CONVERGE-01`. Runtime resolver behavior, admission, projector/DAG, convergence, complete profile, predecessor, transition, lifecycle, and resource behavior remain later-packet scope.
- `A-ADMISSION-01` is now packet-local `ReviewedLocalGreen` at its [handoff](2026-08-03-feat-0065-subf-0143-contractslice-a-admission-freeze.md). Historical frozen-design predecessor [`f298e87f98cb0896904a21078e2e3f391b2b8dcd`](https://github.com/hasanmanzak/meAndAI/commit/f298e87f98cb0896904a21078e2e3f391b2b8dcd), git tree identity `6debfc2f3648ec7972d3e1f21d1f1cc224b35a4a`, and [run 30774470978](https://github.com/hasanmanzak/meAndAI/actions/runs/30774470978) remain immutable predecessor evidence. Exact implementation delivery [`c1653d45c99eb01291bc571e93d74db80d94d9e8`](https://github.com/hasanmanzak/meAndAI/commit/c1653d45c99eb01291bc571e93d74db80d94d9e8), git tree identity `7f547daa92ca22d4f4f288e5ac8a97f890185bd7`, passed Ubuntu in `18m12s` and Windows in `17m28s` in [run 30778711538](https://github.com/hasanmanzak/meAndAI/actions/runs/30778711538); publication verification was correctly skipped. The record-evidence sync commit/push and exact-head hosted validation remain pending; every later packet remains Candidate/inactive until that gate is green.
- Final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, publication, WIP extraction, consumer mutation, authority transfer, and PowerShell retirement remain held.
