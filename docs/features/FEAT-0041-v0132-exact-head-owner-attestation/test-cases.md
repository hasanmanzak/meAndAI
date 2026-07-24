# FEAT-0041 Test Scenarios

Test implementation: [capability-review.tests.ps1](../../../tests/capabilities/capability-adoption/capability-review.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0163` | [SUBF-0080](README.md) | Finalize project-neutral merged capability reviews with a trusted independent exact-head approval; prove any nonempty stale, rejected, creator-authored, or insufficient review collection retains the existing rejection path; then use an empty review collection and vary canonical personal-owner attestations across exact, stale-head, wrong repository/PR, malformed, duplicate, untrusted-author, owner/creator mismatch, organization owner, non-admin, and permission-identity-drift states. | Existing review submissions never fall through to self-attestation and require no comment lookup. Only an empty review collection may use one exact single-line repository/PR/head-bound comment whose author, personal repository owner, PR creator, and exact admin permission actor are identical; every other state fails before mutation. | Authorization contract / exact string / pagination / negative | Passed | Capability-review production fixture |
| `TEST-0164` | [SUBF-0080](README.md) | Start from an already-merged review whose exact branch and issue were retained after the old approval gate failed; add the canonical owner attestation and invoke explicit pull-request-number recovery, then rerun the completed state. | Existing merged-tree, ledger, containment, branch-head, and issue gates remain authoritative; recovery deletes only the exact branch, records closure and closes the issue last, and the completed rerun performs no mutation or duplicate evidence. | Integration / historical recovery / ordering / idempotency | Passed | Capability-review production fixture |

## Required coverage

- Existing review-state regression with zero attestation reads; fallback only
  for a literally empty review collection.
- Personal repository owner + PR creator + comment author + exact admin identity.
- Canonical single-line ASCII comment bytes bound to repository, PR, and exact
  head.
- Stale/wrong repository, PR, and head bindings.
- Malformed, duplicate, conflicting, ordinary, and untrusted comments.
- Owner type, owner/creator identity, permission, and permission-actor negatives.
- Already-merged explicit recovery, no pre-proof mutation, branch-first cleanup,
  issue-last closure, and completed-rerun idempotency.
- No new workflow job, credential scope, or consumer-specific fixture.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-23 | v0.13.1 baseline `f8296cf` | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Passed [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md) and [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md) before TEST-0163/0164 registration; confirms the old independent-only baseline |
| 2026-07-23 | FEAT-0041 test-first tree before production correction | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Expected red: the independent and nonempty-review regression checks pass, then the exact empty-review personal-owner attestation is rejected by the unchanged `Merged capability review lacks an approval for the exact review head` gate |
| 2026-07-23 | FEAT-0041 corrected working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/capability-adoption/capability-review.tests.ps1` | Passed [TEST-0139](../FEAT-0032-general-capability-test-architecture/test-cases.md), [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md), TEST-0163, and TEST-0164, including page-two discovery, nonfallback beside reviews, negative actor/permission states, merged recovery ordering, and completed-rerun idempotency |
| 2026-07-23 | FEAT-0041 corrected working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1 -StructureOnly` | Passed all discovered structural contracts, version/feature metadata, scenario ownership, and current-release reference checks |
| 2026-07-23 | FEAT-0041 corrected working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption-bundle.tests.ps1` | Passed [TEST-0147](../FEAT-0036-modular-quick-adoption-reliability/test-cases.md) for the v0.13.2 thin-launcher/module-bundle release contract |
