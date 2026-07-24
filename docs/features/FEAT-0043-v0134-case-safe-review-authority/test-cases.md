# FEAT-0043 Test Scenarios

Test implementation: [capability-review.tests.ps1](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0167` <a name="test-0167"></a> | [SUBF-0082](README.md#subf-0082) | Create a project-neutral proven merged strict-predecessor capability review whose trusted marker and exact-head personal-owner attestation use canonical lowercase repository identity while its exact ledger pull-request URL uses equivalent owner-only, repository-only, and combined mixed casing. Finalize each case, then rerun the completed state. | The structured GitHub repository identity comparison accepts casing-only equivalence; every [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)/[DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) proof still passes, exact branch-first/issue-last cleanup completes, one fresh inventory occurs, the ledger remains byte-identical, and the completed rerun performs no mutation. | Integration / authorization / historical recovery / idempotency | Automated; passed | Capability-review production fixture |
| `TEST-0168` <a name="test-0168"></a> | [SUBF-0082](README.md#subf-0082) | Vary the historical pull-request binding across another owner or repository, deceptive prefix/suffix, wrong host, wrong path shape, wrong pull-request number, query/fragment or malformed/ambiguous URL, and non-case differences while retaining otherwise valid review evidence. | Only owner and repository-name casing may differ. Every other mismatch fails before branch, comment, issue, ledger, or proposal mutation and cannot borrow authority from a case-folded or partially matched string. | Negative / identity boundary / fail-closed mutation safety | Automated; passed | Capability-review production fixture |

## Required coverage

- Structured canonical GitHub pull-request URL parsing.
- Case-insensitive comparison limited to owner and repository-name components.
- Exact host, pull-request path shape and number, reviewed head, actor,
  permission, release, catalog, ledger, and cleanup contracts.
- Mixed owner casing, mixed repository casing, and both varied together.
- Different owner/repository and deceptive textual near-matches.
- Wrong host/path/number plus malformed or ambiguous URL rejection.
- No mutation before complete proof, expected-OID branch deletion, issue-last
  closure, byte-identical ledger preservation, one fresh inventory, and
  completed-rerun idempotency.
- Project-neutral fixtures and no new workflow or hosted fan-out.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | Immutable v0.13.3 consumer runtime | GitHub Actions / Derdini | [Run 30004752646](https://github.com/hasanmanzak/Derdini/actions/runs/30004752646) | Failed at the mixed-case repository-binding comparison after the exact-head owner attestation reached historical recovery |
| 2026-07-23 | v0.13.3 baseline [`4285c7a`](https://github.com/hasanmanzak/meAndAI/commit/4285c7a6169d91a7b7cc75b72ce6c88230bf0039) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Existing capability-review owner passed before TEST-0167/0168 were added |
| 2026-07-23 | FEAT-0043 test-first tree | Windows PowerShell 5.1 | Focused capability-review test command above | Failed as intended in 10.3 seconds: equivalent display-case authority was rejected as not linked to the exact pull request |
| 2026-07-23 | FEAT-0043 corrected and reviewed working tree | Windows PowerShell 5.1 | Focused capability-review test command above | Passed in 14.5 seconds; scenario evidence lists [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0139), [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0140), [TEST-0163](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0163), [TEST-0164](../FEAT-0041-v0132-exact-head-owner-attestation/test-cases.md#test-0164), [TEST-0165](../FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md#test-0165), [TEST-0166](../FEAT-0042-v0133-historical-capability-review-recovery/test-cases.md#test-0166), [TEST-0167](#test-0167), and [TEST-0168](#test-0168) |
| 2026-07-23 | Pre-publication working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed in 13.6 seconds for every discovered structural contract |
