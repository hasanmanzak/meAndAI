# FEAT-0021 Test Scenarios

Implementation: [`tests/capabilities/initial-adoption/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1)
and the complete repository suite.

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0107` <a name="test-0107"></a> | `FEAT-0021` / [BUG-0009](https://github.com/hasanmanzak/meAndAI/issues/59) | Run the launcher prerequisite boundary with `gh` output for `2.82.0`, malformed, ambiguous, and leading-zero versions, exact `2.82.1`, a later version, and `2.100.0`; inspect calls and the untouched missing target. | Incompatible or unparseable clients fail with upgrade guidance after only one version query; compatible clients continue to target validation; no authentication, Git initialization, secret inspection, or remote mutation occurs in the fixture. | Prerequisite / compatibility regression | Passing | Quick-adoption mock CLI plus side-effect assertions |

## Required coverage

- Exact minimum `2.82.1` acceptance.
- Older `2.82.0` rejection.
- Malformed, ambiguous, and non-canonical leading-zero output rejection.
- Later and multi-digit component acceptance without lexical comparison.
- Exactly one `gh --version` call before the next prerequisite.
- No authentication, Git initialization, credential inspection, or remote
  mutation on rejected input.
- Existing quick-adoption behavior with the compatible mock default.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | `main` at `v0.9.5` behavior | GitHub CLI 2.42.1 / affected-consumer adoption | User-reported quick-adoption run recorded in [issue #59](https://github.com/hasanmanzak/meAndAI/issues/59) | External red: late `repository.pullRequest.projectCards` failure instead of an initial compatibility rejection |
| 2026-07-17 | Working tree before implementation | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red: the seven TEST-0107 cases failed at the missing version-query boundary |
| 2026-07-17 | Working tree after implementation | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passing in 362.5 seconds; the first sandboxed attempt reached a Git signal-pipe ACL error, and the required unrestricted retry passed |
| 2026-07-17 | Working tree after active-pin alignment | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Failed after 208.2 seconds; [FIND-0152](README.md#find-0152) identified three stale escaped release-fixture pins |
| 2026-07-17 | [`8f3e572`](https://github.com/hasanmanzak/meAndAI/commit/8f3e572c7bc6b8876520ea73c935207b804496df) after [FIND-0152](README.md#find-0152) resolution | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passing in 535.1 seconds; all discovered suites, 35 quick-adoption scenarios including `TEST-0107`, and [TEST-0105](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)/[TEST-0106](../FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106) passed |
