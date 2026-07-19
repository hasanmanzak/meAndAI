# FEAT-0018 Test Scenarios

Implementation: [`tests/capabilities/initial-adoption/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1).

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0102` | `FEAT-0018` / `BUG-0006` | Resolve the deterministic adoption draft using the live GitHub CLI repository metadata shape, then vary repository name, repository owner, cross-repository state, and its Boolean type. | The matching same-repository draft passes; every identity or type mismatch fails before local Codex or Git mutation; the command requests the real fields and the fixture exposes no synthetic `headRepository.nameWithOwner`. | Contract / real-shape regression | Passed locally | Quick-adoption integration fixture |

## Required coverage

- Same-repository success with `headRepository.name`,
  `headRepositoryOwner.login`, and `isCrossRepository=false`.
- Repository-name and owner mismatch rejection.
- Cross-repository and invalid Boolean-type rejection.
- Exact `gh pr list --json` field-request verification.
- Existing branch, actor, marker, head, base, draft, lifecycle, and recovery
  regression coverage.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | `v0.9.2` release asset | Windows PowerShell 5.1 / GitHub CLI | Externally reproduced quick-adoption run recorded in [issue #53](https://github.com/hasanmanzak/meAndAI/issues/53) | External red: successful lifecycle and valid same-repository draft were followed by false repository-origin rejection |
| 2026-07-16 | Test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red in 25.4 seconds: production omitted live field `headRepositoryOwner` |
| 2026-07-16 | Focused green working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passed in 315.6 seconds: every declared quick-adoption scenario including `TEST-0102` |
| 2026-07-16 | Complete-suite working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 474.6 seconds: all discovered suites and machine-readable `TEST-0102` evidence |
