# FEAT-0013 Test Scenarios

Implementations:

- [Quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1)
- [Bootstrap adapter fixtures](../../../tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1)
- [Repository and evidence fixtures](../../../tests/protocol.tests.ps1)
- [Post-publication evidence fixtures](../../../tests/capabilities/publication-evidence/post-publication-evidence.tests.ps1)

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0077` <a name="test-0077"></a> | [SUBF-0030](README.md#subf-0030) | Route a complete consumer whose local updater asset is exact, missing, or drifted. | Trusted exact-release code validates the complete managed asset set before either token reaches the local updater; missing or drifted state blocks. | Supply-chain / integration | Passed | Workflow and bootstrap-adapter fixtures |
| `TEST-0078` <a name="test-0078"></a> | [SUBF-0030](README.md#subf-0030) | Run the launcher against an exact, absent, or differing existing seed while mapped secrets are missing. | Differing seed state blocks before lock acquisition, secret inventory, or secret write; exact and absent states retain their documented paths. | Mutation ordering / integration | Passed | Quick-adoption fixture |
| `TEST-0079` <a name="test-0079"></a> | [SUBF-0030](README.md#subf-0030) | Interrupt completion after the leased push but before marker/readiness update, then rerun. | Persisted intent binds old and planned heads; rerun finalizes the exact pushed completion without invoking Codex or creating another commit. | Recovery / state transition | Passed | Quick-adoption interruption fixture |
| `TEST-0080` <a name="test-0080"></a> | [SUBF-0030](README.md#subf-0030) | Supply exact and malformed adoption manifests with property, identity, proposed-path, collision, and required-task variants. | Launcher and bootstrap apply one exact canonical contract and reject every malformed variant before an agent prompt. | Semantic contract / boundary | Passed | Shared-module, bootstrap, and launcher fixtures |
| `TEST-0081` <a name="test-0081"></a> | [SUBF-0031](README.md#subf-0031) | Exercise canonical, quoted, malformed, and duplicate ownership markers. | Every named marker variant has a focused fixture and ambiguous ownership blocks before issue mutation or Codex execution. | Evidence integrity | Passed | Quick-adoption fixtures |
| `TEST-0082` <a name="test-0082"></a> | [SUBF-0031](README.md#subf-0031) | Exercise the serialized secret state model documented by [TEST-0070](../FEAT-0012-v082-correction/test-cases.md#test-0070) through pre-seeded contention, ownership change, and a later deterministic rerun. | Evidence is described as serialization/recovery and proves no unexecuted simultaneous-process concurrency claim. | Evidence integrity / state transition | Passed | Quick-adoption lock and rerun fixtures plus scenario wording |
| `TEST-0083` <a name="test-0083"></a> | [SUBF-0031](README.md#subf-0031) | Place qualifying post-publication evidence only in a second page of issue comments while the issue body contains marker-like text. | The verifier follows bounded pagination, accepts the qualifying comment, and never substitutes issue-body text for comment evidence. | External integration / pagination | Passed | Post-publication evidence fixture |
| `TEST-0084` <a name="test-0084"></a> | [SUBF-0031](README.md#subf-0031) | Inspect the finding issue form's classification and disposition controls. | Classification is independent and disposition offers exactly `Blocking`, `AcceptedResidual`, `ExternalOrLegacyFollowUp`, and `OptionalImprovement`. | Governance / structural | Passed | Repository validator |
| `TEST-0085` <a name="test-0085"></a> | [SUBF-0031](README.md#subf-0031), [SUBF-0032](README.md#subf-0032) | Validate version strings, completed scenario wording, and stable delivery links. | Canonical `M.m.rev` boundary cases pass, malformed/leading-zero forms fail, completed records describe implementations without planned wording, and [FEAT-0012](../FEAT-0012-v082-correction/README.md) links merged PRs [#39](https://github.com/hasanmanzak/meAndAI/pull/39) and [#40](https://github.com/hasanmanzak/meAndAI/pull/40) while hosted facts remain external. | Versioning / documentation / traceability | Passed | Repository validator plus external link review |

## Required coverage

- Trusted-source ordering, complete managed asset identity, and token boundary.
- Seed preflight before mutation and exact interruption recovery.
- One exact manifest contract at bootstrap and launcher boundaries.
- Honest variant/concurrency evidence and bounded second-page comment evidence.
- Stable delivery links, exact finding taxonomy, version grammar boundaries,
  and completed-document wording.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | Immutable v0.8.3 commit [`7ec7f83c7190c3f064a3c572e7e30d29ea1e5454`](https://github.com/hasanmanzak/meAndAI/commit/7ec7f83c7190c3f064a3c572e7e30d29ea1e5454) | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Baseline passed in 273.3 seconds but did not prove TEST-0077 through TEST-0085; nine `Blocking` findings, one `OptionalImprovement`, and one `ExternalOrLegacyFollowUp` remained |
| 2026-07-16 | FEAT-0013 working tree before the shared-path self-review correction | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passed in 357.4 seconds; the later complete suite revalidated the shared-path correction |
| 2026-07-16 | FEAT-0013 final working tree | Windows PowerShell 5.1 outside the restricted Git signal-pipe sandbox | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | All discovered suites passed in 352 seconds; no unresolved `Blocking` finding remained |
| Pending | Merged v0.8.4 commit | GitHub Actions | Hosted CI and post-publication verifier | Pending; exact facts belong to [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) and the GitHub Release |
