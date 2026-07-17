# FEAT-0026 Test Scenarios

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0119` | `SUBF-0046`, `SUBF-0047` | Run the explicit migration against a real v0.9.2-shaped consumer with mixed LF/CRLF fixtures and historical sentinels, rerun it, then take the ordinary compatible-update route. | Exactly eight current-authority fragments become version-neutral; encoding/newlines, unrelated content, and historical evidence remain unchanged; the second migration is a no-op; the later ordinary run dispatches only the installed updater; the executable adoption prompt carries the same prospective rule. | Integration / compatibility | Passed | Black-box launcher fixture, independent exact-byte oracle, idempotent rerun, ordinary-update continuation, and structure contract |
| `TEST-0120` | `SUBF-0046` | Exercise a non-repository, wrong gitlink, drifted installed updater, missing/duplicated/drifted/mixed fragment, unrelated dirty path, and a second-file write failure. | Every unsupported identity or content state fails before durable mutation; the write failure restores all original byte arrays; no secret, workflow, Git publication, issue, or pull-request operation begins. | Integration / negative / atomicity | Passed | Black-box launcher fixture with mutation counters, byte snapshots, and rollback injection |

## Required coverage

- Exact immutable v0.9.2 tag, gitlink, and updater-asset identity before
  migration classification.
- Exact eight-path all-legacy/all-neutral state machine.
- UTF-8 with and without BOM, LF/CRLF preservation, and unrelated byte
  preservation.
- Dated memory, completed adoption feature, and historical evidence unchanged.
- No secrets, workflow dispatch, commit, push, issue, pull request, or merge in
  migration mode.
- Version-neutral local-Codex prompt and corrected TEST-0114 description.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-17 | v0.10.2 baseline | Hosted Ubuntu/Windows and local Windows PowerShell 5.1 | FEAT-0025 publication gates | Green immutable baseline |
| 2026-07-17 | v0.10.3 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/v092-live-pin-migration.tests.ps1` | Green in 55.8 seconds; TEST-0119 and TEST-0120 passed |
| 2026-07-17 | v0.10.3 working tree | Windows PowerShell 5.1 host context | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Green in 561.4 seconds; all discovered suites and scenario evidence passed |
