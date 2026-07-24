# FEAT-0045 Test Scenarios

Test implementations remain in existing capability suites:
[capability-catalog.tests.ps1](../../../tests/capabilities/capability-adoption/capability-catalog.tests.ps1),
[capability-review.tests.ps1](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1),
and
[protocol-governance.tests.ps1](../../../tests/capabilities/protocol-governance/protocol-governance.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0171` <a name="test-0171"></a> | [SUBF-0086](README.md#subf-0086) | In fresh anonymous real Git repositories, exercise clean `core.autocrlf=true` checkout bytes, staged-only, unstaged, untracked, staged-plus-unstaged, genuine CRLF, and exact reruns. | Clean state returns exact HEAD blob bytes; staged-only returns index bytes; unstaged/untracked returns raw worktree bytes; ambiguous or noncanonical state is not normalized; reruns do not mutate repository state. | Integration / Git / byte integrity / idempotency | Passed | Existing capability-catalog suite |
| `TEST-0172` <a name="test-0172"></a> | [SUBF-0087](README.md#subf-0087) | Import the three-entry catalog from a two-entry released predecessor ledger and from a complete terminal ledger. | Existing tuples remain exact and ordered; only `canonical-repository-evidence` is pending for the predecessor; a complete three-entry ledger is a no-op; rewrite/reorder/duplicate state fails closed. | Contract / capability lifecycle / compatibility | Passed | Existing capability-catalog and review suites |
| `TEST-0173` <a name="test-0173"></a> | [SUBF-0085](README.md#subf-0085) | Inspect the common/local ownership mandates and new canonical artifact set. | Reusable defects are assigned upstream; consumer recovery stays separate; new artifacts contain no named-consumer knowledge and grant no unrelated-repository authority. | Protocol contract / project neutrality | Passed | Existing protocol-governance suite |

## Required coverage

- Exact binary-safe HEAD and index blob acquisition through Git, not text
  pipelines or transformed worktree substitutes.
- `core.autocrlf=true`, no consumer `.gitattributes` rule, committed LF bytes,
  clean CRLF worktree bytes, real drift rejection, and idempotent reruns.
- Containment, ordinary-file and regular-blob gates; ambiguous state fails
  closed without normalization.
- Exact preservation of both released capability tuples and two-entry terminal
  ledger prefix behavior.
- Common/local upstream ownership, semantic consumer ownership, and anonymous
  canonical fixtures.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | v0.13.5 baseline | Source inspection | Production capability-review ledger acquisition | Expected red boundary identified: Git-clean ledger bytes come from the checkout-filtered worktree |
| 2026-07-23 | v0.14.0 candidate | Windows PowerShell 5.1 / anonymous local Git fixture | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\capabilities\capability-adoption\capability-catalog.tests.ps1` | Passed [TEST-0134](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0134), [TEST-0135](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0135), [TEST-0157](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0157), and TEST-0171 |
| 2026-07-23 | v0.14.0 candidate | Windows PowerShell 5.1 / injected lifecycle fixtures | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\capabilities\capability-adoption\capability-review.tests.ps1` | Passed [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0139), [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0140), [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163) and [TEST-0164](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0164), [TEST-0165](../FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md#test-0165) and [TEST-0166](../FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md#test-0166), [TEST-0167](../FEAT-0043-v0134-case-safe-review-authority/test-cases.md#test-0167) and [TEST-0168](../FEAT-0043-v0134-case-safe-review-authority/test-cases.md#test-0168), and [TEST-0169](../FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/test-cases.md#test-0169), and TEST-0172 in 14.1 seconds |
| 2026-07-23 | v0.14.0 candidate | Windows PowerShell 5.1 / exact candidate tree | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\protocol.tests.ps1 -StructureOnly` | Passed all discovered structural contracts in 5.3 seconds, including TEST-0173 |
| 2026-07-23 | [PR #111](https://github.com/hasanmanzak/meAndAI/pull/111) correction | Windows PowerShell 5.1 / real anonymous Git clone | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\capabilities\capability-adoption\capability-catalog.tests.ps1` | Passed TEST-0171 after removing unnecessary matched-process termination exposed by the first hosted Windows run |
