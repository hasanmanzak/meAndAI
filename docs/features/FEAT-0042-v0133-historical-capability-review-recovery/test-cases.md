# FEAT-0042 Test Scenarios

Test implementation: [capability-review.tests.ps1](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0165` <a name="test-0165"></a> | [SUBF-0081](README.md#subf-0081) | Create a project-neutral consumer whose merged historical capability proposal and open trusted issue bind a strict-predecessor catalog resolved through the base-head `.ai/protocol` gitlink to an exact immutable tag. Supply current exact-head independent approval or owner attestation, retain a current ledger with the historical merged ledger as its exact prefix plus later entries, and vary automatic and explicit historical finalization, branch-already-absent partial recovery, completed rerun, and a subsequent current-catalog proposal. | The finalizer proves the immutable historical release, catalog, definitions, binding, merge, authority, and ledger without editing consumer content; deletes only the exact branch through expected-OID force-with-lease when present, records closure and closes the issue last, preserves all later ledger entries, performs exactly one fresh current inventory, and becomes an exact no-op after completion. | Integration / historical recovery / ordering / idempotency | Passed | Capability-review production fixture |
| `TEST-0166` <a name="test-0166"></a> | [SUBF-0081](README.md#subf-0081) | Vary active/open or closed-unmerged proposals; equal, non-prefix, reordered, rewritten, removed, unrelated, untagged, moved-tag, or digest-drifted catalogs; wrong or ambiguous issue/PR/base/head/branch/release bindings; absent or invalid current review authority; incomplete, divergent, truncated, or extended-invalid ledgers; branch movement at deletion; duplicate issue or pull-request candidates; and a second cleanup request in one invocation. | Every unproven state fails before branch, comment, issue, ledger, or proposal mutation. No active work is retired, no later ledger entry is lost, a moved branch defeats the lease, and the invocation never performs more than one historical cleanup or one fresh current inventory. | Negative / provenance / authorization / race / boundedness | Passed | Capability-review production fixture |

## Required coverage

- Canonical base-head `.ai/protocol` gitlink acquisition from Git objects, not
  a smudged worktree or issue prose.
- Exact immutable tagged historical release, canonical catalog digest, and
  definition-blob verification.
- Strict byte-identical ordered predecessor relationship; equal or incompatible
  catalogs remain fail-closed.
- Unique trusted issue/PR/base/reviewed-head/branch binding and merged-state
  proof.
- Current exact-head independent approval and empty-review personal-owner
  attestation paths, with unchanged rejection semantics.
- Exact historical merged ledger and current-ledger prefix preservation,
  including later terminal entries that recovery must not rewrite or truncate.
- No mutation before complete proof, expected-OID force-with-lease deletion,
  branch-first/issue-last closure, completed-rerun idempotency, and deletion-race
  rejection.
- At most one historical cleanup followed by one fresh current inventory per
  invocation; no consumer-specific fixture, loop, workflow, or hosted fan-out.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | v0.13.2 baseline [`0c67c8a`](https://github.com/hasanmanzak/meAndAI/commit/0c67c8a26192921840bbd12559d83f0ad450e880) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Existing [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0139), [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0140), [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163), and [TEST-0164](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0164) baseline is green before TEST-0165/0166 registration; historical stale-catalog recovery is not yet represented |
| 2026-07-23 | FEAT-0042 test-first tree | Windows PowerShell 5.1 | Focused capability-review test command above | Expected red: the unchanged runner rejected the trusted merged predecessor with `An open capability-review issue has stale catalog identity.` |
| 2026-07-23 | Corrected, version-pinned, and bounded-reviewed working tree | Windows PowerShell 5.1 | Focused capability-review test command above | Passed in 12.9 seconds; [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0139), [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0140), [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163), [TEST-0164](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0164), TEST-0165, and TEST-0166 emitted exact owner-bound evidence |
| 2026-07-23 | Pre-publication working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed all discovered structural contracts in 5.0 seconds |
| 2026-07-23 | Pre-publication working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1` | Passed [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147) in 21.3 seconds for the v0.13.3 two-asset release contract |
| 2026-07-23 | Pre-publication working tree | Windows PowerShell 5.1 outside the restricted sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/consumer-update/protocol-update.tests.ps1` | Passed all 28 declared updater scenarios in 60.5 seconds after the restricted run reproduced Git for Windows `Win32 error 5` signal-pipe failures |
| 2026-07-23 | Pre-publication working tree | Windows PowerShell 5.1 outside the restricted sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Local aggregate run reached the existing 15-minute process limit without a test failure or completion; hosted PR validation remains the required whole-repository gate and must pass before merge |
