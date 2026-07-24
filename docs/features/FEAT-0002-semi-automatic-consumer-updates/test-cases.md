# FEAT-0002 Test Scenarios

Implementations:

- [Resolver and structural tests](../../../tests/capabilities/consumer-update/protocol-update.tests.ps1)
- [Adapter and race fixtures](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1)
- [Full repository validator](../../../tests/protocol.tests.ps1)
- [Cross-platform CI workflow](../../../.github/workflows/protocol-tests.yml)

| ID | Related slice | Scenario | Expected result | Status | Automation |
| --- | --- | --- | --- | --- | --- |
| `TEST-0009` | [SUBF-0004](README.md) | Compare canonical tags numerically, including `v0.10.0`, uppercase, leading-zero, malformed, and prerelease-like values. | Highest compatible canonical stable tag is selected; all noncanonical values are reported as ignored. | Passed | Resolver test |
| `TEST-0010` | [SUBF-0004](README.md) | Latest compatible tag already has one valid managed PR. | No operation is produced. | Passed | Resolver test |
| `TEST-0011` | [SUBF-0005](README.md) | `v0.2.0` is pending when `v0.3.0` appears. | A verified replacement precedes old cleanup; an existing valid replacement is not duplicated. | Passed | Resolver and adapter tests |
| `TEST-0012` | [SUBF-0005](README.md) | Default branch already contains the target of an open managed PR. | Stale PR cleanup is planned without a replacement. | Passed | Resolver test |
| `TEST-0013` | [SUBF-0004](README.md) | Current version, tag aliases, or release inventory is malformed or ambiguous. | Plan blocks with zero mutations. | Passed | Resolver and adapter tests |
| `TEST-0014` | [SUBF-0004](README.md) | Multiple managed PRs claim the same active target. | Ambiguous state blocks without heuristic cleanup. | Passed | Resolver test |
| `TEST-0015` | [SUBF-0005](README.md) | Ownership, marker count, case, API/remote head, tree, path, draft/base state, or branch lease changes before mutation. | Ambiguous or human work is preserved; paired cleanup failure attempts to reopen the PR. | Passed | Shared-validator and adapter race fixtures |
| `TEST-0016` | [SUBF-0006](README.md) | A higher incompatible major exists without a newer same-major release. | Workflow reports manual migration and opens no automatic PR. | Passed | Resolver test |
| `TEST-0017` | [SUBF-0006](README.md) | Inspect workflow/adoption controls, immutable actions, permissions, triggers, pagination, origin validation, and repository CI. | Required review-only controls exist; auto-merge, mutable actions, and `pull_request_target` do not. | Passed locally and in PR CI | Structural and invalid-origin tests |
| `TEST-0021` | [SUBF-0005](README.md) | Inspect the audit comment emitted before managed PR and branch cleanup, including the branch-deletion compensation path. | The comment describes cleanup as an attempt, explains reopen/preserve compensation, and does not promise branch removal before deletion succeeds. | Passed | Adapter body fixture and structural assertion |

## Evidence

| Phase | Date | Commit | Environment | Command or check | Result |
| --- | --- | --- | --- | --- | --- |
| Red | 2026-07-14 | Working tree before resolver implementation | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update.tests.ps1` | Exit `1`: `TEST-0009 missing pure update resolver module.` |
| Green | 2026-07-14 | Final pre-publication working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Exit `0`; [complete protocol suite](../../../tests/protocol.tests.ps1) passed |
| Parse | 2026-07-14 | Final pre-publication working tree | Windows PowerShell 5.1 AST parser | Parse resolver, adapter, and both updater test files | No parser errors |
| Git leases | 2026-07-14 | Final pre-publication working tree | Local temporary bare and working Git repositories | Expected-absent creation and expected-head deletion smoke test | Passed |
| PR CI | 2026-07-14 | [PR #4](https://github.com/hasanmanzak/meAndAI/pull/4) | GitHub-hosted Ubuntu and Windows PowerShell 7 | [Actions run 29348128999](https://github.com/hasanmanzak/meAndAI/actions/runs/29348128999) | Passed |
| Red - `TEST-0021` | 2026-07-14 | Working tree after adding the comment contract test | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol-update-adapter.tests.ps1` | Exit `1`; the existing guaranteed-removal wording failed all five new assertions |
| Green - `TEST-0021` | 2026-07-14 | `v0.3.2` pre-publication working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Exit `0`; [complete protocol suite](../../../tests/protocol.tests.ps1) passed |

The adapter fixture returns only the first 100 pull requests unless the caller
uses `--paginate`, asserts exact expected-absent and expected-head lease
arguments, and exercises replacement, rollback, missing-ref, duplicate-marker,
case, origin, pagination, and concurrent-change paths. This keeps the tests from
passing merely because a scenario flag simulates the desired result.
