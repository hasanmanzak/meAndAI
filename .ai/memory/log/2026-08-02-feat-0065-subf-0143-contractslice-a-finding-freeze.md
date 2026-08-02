# ContractSlice A finding declaration design freeze

| Field | Value |
| --- | --- |
| Date | 2026-08-02 |
| Branch | `codex/subf-0143-contract-slice-a-implementation` |
| Pull request | Draft [PR #174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Parent | [SUBF-0143](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143) / [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) |
| State | `A-FINDING-01` is `FrozenDesign`; `R=NotApplicable`; the authorized route is `TestOnlyGreen`; implementation and V remain pending |
| Exact predecessor | [`bdd252bb74a2d8ee87664cb0d34b5c893d34a7b9`](https://github.com/hasanmanzak/meAndAI/commit/bdd252bb74a2d8ee87664cb0d34b5c893d34a7b9), git tree identity `b95ac0da13e26c168d03525a0d2f7c63127e9885`, passed Ubuntu and Windows in [run 30762028026](https://github.com/hasanmanzak/meAndAI/actions/runs/30762028026); publication verification was correctly skipped |
| Progress | Nine of twenty packets are `ReviewedLocalGreen` (`45%`); cumulative A is `22/22`; [TEST-0210](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210) remains `Planned` |

## Frozen scope

- Reserved FQN: `MeAndAI.Protocol.Conformance.Tests.ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles`; one Fact; only `ContractSlice=A`; no `Scenario`, expected-red marker, ordinal, or TRX.
- Existing C# already implements the owned behavior: typed finding declaration, non-empty canonical-unique primary roles, canonical-unique optionally empty related roles, rule-level finding-code canonicalization/duplicate rejection, canonical Reader/Writer projection, and `FinalizedPolicyManifest.ParseCanonical` rejection when reserialized bytes differ from the input. Therefore production mutation is forbidden unless the retained test exposes a real defect and D/RT is redrawn first.
- The sole C# allowlist entry is new `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ContractSliceAFindingManifestTests.cs`; production delta/cap is exactly `0`; retained test target is `260-340` lines with a hard cap of `420` and combined C# hard cap `420`.
- Fixtures use only synthetic identities such as `test.finding.alpha`, `test.finding.beta`, `test.severity.error`, and `test.remediation.alpha`/`test.remediation.beta`. The real five-rule Policy finding inventory, exact Catalog counts/pairs, selectors, evaluator outputs, and qualified runtime references belong to later packets, especially `A-CONVERGE-01` and `A-SELECTOR-01`.

## Required retained-test matrix

- Construct two synthetic declarations in reverse code order and reference-kind inputs in reverse order. Prove input snapshotting; distinct primary/related role sets; primary non-empty; related empty accepted; canonical kind ordering; and rule-level finding-code ordering.
- Prove exact Writer -> bytes -> Reader -> Writer byte identity and manifest-digest identity. Assert parsed code, severity, remediation, primary kinds, related kinds, and exact finding wire-property order: `code`, `severity`, `remediation`, `allowedPrimaryReferenceKinds`, `allowedRelatedReferenceKinds`.
- Reject null code/severity/remediation, null primary/related collections, empty primary, duplicate primary kind, duplicate related kind, and duplicate finding code. Reversed valid input is normalized rather than rejected.
- For each exact wire field (`code`, `severity`, `remediation`, `allowedPrimaryReferenceKinds`, `allowedRelatedReferenceKinds`), reject missing, duplicate, null, wrong-type, extra-field, and reordered forms. Reject empty primary; unknown tokens independently in primary and related; duplicate tokens independently in primary and related; noncanonical kind order; null finding entries; and noncanonical/duplicate finding-code order. Typed factories deliberately normalize valid reverse-order inputs; raw noncanonical wire order is rejected later because `FinalizedPolicyManifest.ParseCanonical` reserializes with `CanonicalManifestWriter` and throws public `FormatException` on byte inequality. No malformed form may escape that public parse boundary.
- Keep expected selectors empty. Preserve the exact predecessor topology and every retained 0007 fixture. Do not add Catalog exact-inventory validation, selector closure, evaluator failure behavior, emitted-reference validation, or full-A graph assertions.

## D/RT verdict and holds

- Independent adjudication withdrew the earlier Catalog exact-pair/BehaviorRed proposal because it would steal `A-CONVERGE-01` ownership. The corrected freeze closed `0 Blocking / 0 Important / 0 Minor`: `R=NotApplicable`, `TestOnlyGreen`, production `0`, synthetic fixtures, and no real inventory or selector closure.
- `A-SELECTOR-01` and every later packet remain Candidate/inactive. No downstream implementation may activate before this packet is green, reviewed, synchronized, committed, pushed, and exact-head hosted green.
- Final Scenario/status/owner/workflow/[TEST-0146](../../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146), B/C/D, merge, release, publication, WIP extraction, consumer mutation, authority transfer, and PowerShell retirement remain held.
