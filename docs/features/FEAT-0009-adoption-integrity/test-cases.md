# FEAT-0009 Test Scenarios

Test implementation:
[quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1),
[updater adapter fixtures](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1),
and [repository validation](../../../tests/protocol.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0046` | `SUBF-0017` | Complete a manifest-only collision draft while exact protocol source was retrieved through the token-backed archive path. | Codex can stage the canonical `.gitmodules` and exact gitlink without network or source Git metadata; the launcher validates and publishes it. | Real-Git integration | Passed | Mock Codex plus bare remotes |
| `TEST-0047` | `SUBF-0018` | Present wrong/missing marker fields, actor, base, head repository, head SHA, or a wrong unchanged protocol reference. | Bootstrap and launcher fail closed without Codex, readiness, branch cleanup, or unrelated mutation. | Negative / ownership / supply chain | Passed | Mock GitHub CLI and real-Git fixtures |
| `TEST-0048` | `SUBF-0019` | Return a GitHub PR-file record that renames an unmanaged source into an expected managed destination. | Candidate validation includes source/status metadata, blocks reconciliation, and preserves every PR and branch. | Negative / consumer ownership | Passed | Updater adapter fixture |
| `TEST-0049` | `SUBF-0020` | Fail local authentication/completion, then complete a verified adoption. | The adoption issue has no review-ready state while blocked and receives exactly one `status:needs-review` transition only after readiness. | State transition / integration | Passed | Mock GitHub CLI and Codex fixture |
| `TEST-0050` | `SUBF-0020` | Inspect v0.7.2 protocol, release records, decision status, launcher seams, links, and complete regressions. | Active metadata and normative behavior agree; historical releases are closed; all repository suites pass. | Structural / regression | Passed | PowerShell source, link, AST, and complete suite |

## Required coverage

- Collision and full-bootstrap success paths.
- Missing, duplicate, malformed, cross-repository, wrong-base, wrong-actor,
  non-draft, and moved-head ownership failures.
- Exact gitlink and canonical `.gitmodules` checks whether or not the reference
  appears in the local Codex diff.
- GitHub rename destination/source semantics.
- Blocked and successful issue-label transitions.
- Version, changelog, feature, decision, memory, links, and existing regression
  behavior.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-15 | `main` at `v0.7.1` before FEAT-0009 | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0045` in 119.2 seconds after one ACL-only environment retry |
| 2026-07-15 | `SUBF-0017` red state | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected fail: `TEST-0046` could not publish the exact gitlink from a token-backed manifest-only draft |
| 2026-07-15 | `SUBF-0017` reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1`; `git diff --check` | Pass: existing quick-adoption scenarios plus `TEST-0046` in 70.6 seconds; no whitespace errors |
| 2026-07-15 | `SUBF-0018` red state | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1`; `tests/capabilities-bootstrap.tests.ps1` | Expected failures: five invalid PR metadata variants and one wrong unchanged gitlink were promoted; an unverified existing proposal remained pending |
| 2026-07-15 | `SUBF-0018` reviewed working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1`; `tests/capabilities-bootstrap.tests.ps1` | Pass: ownership/exact-pin quick suite in 87.1 seconds and lifecycle suite in 44.9 seconds |
| 2026-07-15 | `SUBF-0019` red/green working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Expected fail on both rename phases, then pass with no cleanup mutation in 10.0 seconds |
| 2026-07-15 | `SUBF-0020` issue-state working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Pass: review status follows readiness exactly once and remains absent in four blocked modes; 87.1 seconds |
| 2026-07-15 | `SUBF-0020` first complete run | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | One test-only blocker after all integration suites passed: literal TEST-0050 metadata matching did not normalize a Markdown line break |
| 2026-07-15 | `SUBF-0020` confirmation working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Pass: `TEST-0001` through `TEST-0050` in 142.5 seconds after the single blocker-only confirmation fix |
| 2026-07-15 | PR #31 implementation head | GitHub Actions | [Protocol validation run 29433627977](https://github.com/hasanmanzak/meAndAI/actions/runs/29433627977) | Pass on Ubuntu and Windows; GitGuardian passed |
