# ContractSlice A finding declaration reviewed-local-green handoff

| Field | Value |
| --- | --- |
| Date | 2026-08-02 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-FINDING-01` is packet-local `ReviewedLocalGreen`; `R=NotApplicable`; the authorized route was `TestOnlyGreen`; production delta is `0`; local V and reviews are complete; synchronized commit, push, and exact-head hosted validation remain pending |
| Exact predecessor | [`e0756ffd6ccf2080974db9d9d7dae1c2e728145a`](https://github.com/hasanmanzak/meAndAI/commit/e0756ffd6ccf2080974db9d9d7dae1c2e728145a), git tree identity `47ec9c4de659487b6c0163f93aea9d90513fc3c9`, passed Ubuntu and Windows in [run 30764065710](https://github.com/hasanmanzak/meAndAI/actions/runs/30764065710); publication verification was correctly skipped |
| Progress | Ten of twenty packets are `ReviewedLocalGreen` (`50%`); cumulative A is `23/23`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen scope

- Reserved FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles`; one Fact; only `ContractSlice=A`; no `Scenario`, expected-red marker, ordinal, or TRX.
- Existing C# already implements the owned behavior: typed finding declaration, non-empty canonical-unique primary roles, canonical-unique optionally empty related roles, rule-level finding-code canonicalization/duplicate rejection, canonical Reader/Writer projection, and `FinalizedPolicyManifest.ParseCanonical` rejection when reserialized bytes differ from the input. Therefore production mutation is forbidden unless the retained test exposes a real defect and D/RT is redrawn first.
- The sole C# allowlist entry is new `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAFindingManifestTests.cs`; production delta/cap is exactly `0`; retained test target is `260-340` lines with a hard cap of `420` and combined C# hard cap `420`.
- Fixtures use only the exact synthetic identities `protocol.test.finding.alpha`/`protocol.test.finding.zeta`, `protocol.test.severity.alpha`/`protocol.test.severity.zeta`, and `protocol.test.remediation.alpha`/`protocol.test.remediation.zeta`. The real five-rule Policy finding inventory, exact Catalog counts/pairs, selectors, evaluator outputs, and qualified runtime references belong to later packets, especially `A-CONVERGE-01` and `A-SELECTOR-01`.

## Required retained-test matrix

- Construct two synthetic declarations in reverse code order and reference-kind inputs in reverse order. Prove input snapshotting; distinct primary/related role sets; primary non-empty; related empty accepted; canonical kind ordering; and rule-level finding-code ordering.
- Prove exact Writer -> bytes -> Reader -> Writer byte identity and manifest-digest identity. Assert parsed code, severity, remediation, primary kinds, related kinds, and exact finding wire-property order: `code`, `severity`, `remediation`, `allowedPrimaryReferenceKinds`, `allowedRelatedReferenceKinds`.
- Reject null code/severity/remediation, null primary/related collections, empty primary, duplicate primary kind, duplicate related kind, and duplicate finding code. Reversed valid input is normalized rather than rejected.
- For each exact wire field (`code`, `severity`, `remediation`, `allowedPrimaryReferenceKinds`, `allowedRelatedReferenceKinds`), reject missing, duplicate, null, wrong-type, extra-field, and reordered forms. Reject empty primary; unknown tokens independently in primary and related; duplicate tokens independently in primary and related; noncanonical kind order; null finding entries; and noncanonical/duplicate finding-code order. Typed factories deliberately normalize valid reverse-order inputs; raw noncanonical wire order is rejected later because `FinalizedPolicyManifest.ParseCanonical` reserializes with `CanonicalManifestWriter` and throws public `FormatException` on byte inequality. No malformed form may escape that public parse boundary.
- Keep expected selectors empty. Preserve the exact predecessor topology and every retained 0007 fixture. Do not add Catalog exact-inventory validation, selector closure, evaluator failure behavior, emitted-reference validation, or full-A graph assertions.

## Local green and validation evidence

- No canonical expected-red exists for this packet: `R=NotApplicable`; no BehaviorRed ordinal, marker, or TRX was created.
- Retained source: `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAFindingManifestTests.cs`; `420` lines; SHA-256 `19DDFFA7131306C8BEF70D7E5B83E88B7ED564FE657045C5ACAF6CFAE49A1CAF`. Production delta is exactly `0`; test/combined size is `420/420`.
- Focused green is `1/1`: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-finding-green-e0756ff-0008\focused\TEST-0210-A-FINDING-FOCUSED-GREEN.trx`, SHA-256 `D7C069CCB0B96EE9ECAFCAF98B25294ED368412278839F39BF9079B181FCB25D`.
- Cumulative `ContractSlice=A` green is `23/23`: `C:\Users\hasan\AppData\Local\Temp\meandai-test-0210-a-finding-green-e0756ff-0008\cumulative\TEST-0210-A-FINDING-CUMULATIVE-GREEN.trx`, SHA-256 `8B7046AA517C7A8052AE67DB4088549DEF8AF1E5557C250F2A80E9D5589A2CD3`.
- Full Domain is `98/98`, SHA-256 `8B59FC8B1AE4A4C4634852F80948F99162CF2ACFB143367C2EAD01C4D6803CDB`; full Conformance is `23/23`, SHA-256 `B714DD314BCCD54E1E12117306822355DF5CD1D9A42BF554CD10D0BA7C56804F`.
- Release build is `0 warnings / 0 errors`; default-severity format, diff, the one-file test allowlist, production-zero assertion, and all six package locks are green.
- StructureOnly passed every discovered contract in `635` seconds (`elapsedMs=633046`). The publication-evidence suite passed [TEST-0083](../../../docs/features/FEAT-0013-v084-correction/test-cases.md#test-0083), [TEST-0176](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), [TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178), [TEST-0180](../../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180), [TEST-0181](../../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181), [TEST-0182](../../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182), and [TEST-0189](../../../docs/features/FEAT-0052-v0151-declarative-bundle-source-mapping/test-cases.md#test-0189) in `238.5` seconds without claiming published-state evidence.

## Review and holds

- Independent adjudication withdrew the earlier Catalog exact-pair/BehaviorRed proposal because it would steal `A-CONVERGE-01` ownership. The corrected freeze closed `0 Blocking / 0 Important / 0 Minor`: `R=NotApplicable`, `TestOnlyGreen`, production `0`, synthetic fixtures, and no real inventory or selector closure.
- Independent code/test red-team and independent evidence audit each closed `0 Blocking / 0 Important / 0 Minor` against the exact retained source and four TRX artifacts.
- `A-SELECTOR-01` and every later packet remain Candidate/inactive. No downstream implementation may activate before this packet is synchronized, committed, pushed, and exact-head hosted green.
- Final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, publication, WIP extraction, consumer mutation, authority transfer, and PowerShell retirement remain held.
