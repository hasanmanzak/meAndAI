# FEAT-0052 Test Scenarios

Test implementation: [publication-evidence owner](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1)
with retained [bundle owner](../../../tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0189` <a name="test-0189"></a> | [SUBF-0099](README.md#subf-0099) | Build and verify an ordered schema-2 inventory containing a payload whose bundle path differs from its tracked repository path; exercise exact top-level types and source-array shape, exact source bytes and GitHub Contents metadata, missing/extra properties, unsafe paths, case-insensitive duplicates, ordering, digest mismatch, and a schema-1 `v0.15.0` compatibility release. | Builder and verifier consume the same declared mapping; the external source is requested exactly once at its real path; malformed mappings fail before byte acceptance; schema 1 is accepted only for the bounded historical range and schema 2 is mandatory afterward. | Integration / regression | Passing locally | Existing publication-evidence and bundle suites |

## Required coverage

- Valid schema-2 in-tree and relocated source mappings.
- Exact schema, kind, entry-point, and source-array types before normalization.
- Independent safe-path and uniqueness checks for both semantic path types.
- Exact manifest/archive ordering, GitHub Contents metadata, and Git-blob digest
  identity.
- Malformed, missing, duplicate, reordered, and mismatched mapping rejection.
- Exact schema-1 lower/upper compatibility at `v0.12.4` and `v0.15.0`, plus
  rejection immediately below and above that bounded range.
- No new workflow topology, release asset, or test-suite owner.
- [TEST-0189](#test-0189) evidence is confirmed from its own failure checkpoint
  and does not depend on retained
  [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
  negative-case results.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-25 | [Immutable v0.15.0 commit](https://github.com/hasanmanzak/meAndAI/commit/5c6efa43ce366933a388065b32c7c06db0c5de2e) | GitHub Actions / local PowerShell 7 | Post-publication verifier for `v0.15.0` | Failing baseline: inferred `scripts/quick-adoption/MeAndAI.ContentIdentity.psm1` returns `404`; [run 30176928208](https://github.com/hasanmanzak/meAndAI/actions/runs/30176928208) |
| 2026-07-26 | [FEAT-0052](README.md) reviewed candidate; exact commit pending pull request | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1` | Passed retained [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) in 28.6 seconds, including inventory-driven schema-2 exact Git-blob mapping, strict top-level types, and fail-closed path cases. |
| 2026-07-26 | [FEAT-0052](README.md) reviewed candidate; exact commit pending pull request | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1` | Passed [TEST-0189](#test-0189) and retained publication scenarios in 171.4 seconds; schema-2 relocation, exact Contents/blob evidence, exact schema-1 bounds at `v0.12.4` and `v0.15.0`, immediate out-of-range rejection, strict top-level types, malformed/unsafe/duplicate/mismatched mappings, and an independent TEST-0189 success checkpoint passed. |
| 2026-07-26 | [FEAT-0052](README.md) reviewed candidate; exact commit pending pull request | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/protocol-governance/protocol-governance.tests.ps1 -StructureOnly` | Passed in 165.1 seconds after aligning [FIND-0288](README.md#find-0288), registering [BUG-0034](https://github.com/hasanmanzak/meAndAI/issues/131), and validating visible cross-record links. |
| 2026-07-26 | [FEAT-0052](README.md) earlier candidate; exact commit pending pull request | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 2,070.1 seconds before the final review-derived schema-bound and documentation-alignment corrections; retained as historical candidate evidence and superseded for completion by the final row below. |
| 2026-07-26 | [FEAT-0052](README.md) final reviewed candidate; exact commit pending pull request | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed all discovered protocol suites in 2,081.2 seconds; [TEST-0189](#test-0189), retained [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147), protocol governance, test architecture, and exact runtime scenario evidence were green. |
