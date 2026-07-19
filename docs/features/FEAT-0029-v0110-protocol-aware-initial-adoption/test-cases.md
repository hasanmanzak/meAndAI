# FEAT-0029 Test Scenarios

Test implementation: [capabilities resolver](../../../tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1),
[bootstrap adapter](../../../tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1),
[quick launcher](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1), and
[repository structural suite](../../../tests/protocol.tests.ps1). The inherited
current-launcher compatibility contract is exercised by
[the target updater adapter](../../../tests/capabilities/consumer-update/protocol-update-adapter.fixture.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0127` | `SUBF-0053` | Classify an empty/protocol-free tree and trees containing each declared protocol surface; vary scalar null, empty array, PowerShell 7 singleton-null, mixed-null, duplicates, case collisions, malformed paths, canonical target collisions, and unknown strategy values. | Supported empty representations produce one exact empty inventory on every PowerShell host; null mixed with a real path remains invalid; nonempty inventory is unique, sorted, bounded, and exact; `Auto` resolves only a clean tree to `FreshAdoption`; explicit fresh adoption rejects evidence; malformed or ambiguous inputs stop without a proposal. | Unit / contract / boundary / negative / cross-platform | Passed locally and on replacement Ubuntu | `tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1` |
| `TEST-0128` | `SUBF-0053` | Exercise workflow dispatch, seed push, schedule, existing proposal, and completed-consumer routes with every strategy, loss-acknowledgement state, manifest/marker property variant, and changed base/head. | Only an explicit or safely auto-resolved strategy creates an initial proposal; push/schedule cannot race selection; strategy and surfaces are exact in manifest and marker; existing updater/finalizer routes remain unchanged. | Integration / event / identity / recovery | Passed | `tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.fixture.ps1`, workflow structural checks |
| `TEST-0129` | `SUBF-0054` | Run local semantic completion fixtures for full migration, hybrid reconciliation, and clean start, including legacy project directives, decisions/tests, application files, unacknowledged loss, and a requested out-of-inventory deletion. | Full mode preserves semantics then retires legacy authority; hybrid records precedence; clean start imports no legacy governance and requires acknowledgement; application/product content is unchanged; unapproved deletion blocks. | Integration / semantic contract / destructive negative | Passed | `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` and mock Codex fixtures |
| `TEST-0130` | `SUBF-0054` | Invoke explicit, interactive, non-interactive, abort, rerun, interruption, strategy-mismatch, additional-surface, empty schema-5/6 marker surface, and completed-consumer launcher paths. | Inventory is shown before choice; non-interactive ambiguity and mismatch stop before mutation; abort is a no-op; the prompt cannot change strategy; an empty marker round-trips on Windows PowerShell and PowerShell 7; exact reruns recover; completed consumers bypass initial strategy selection. | Launcher / UX / recovery / compatibility / cross-platform | Passed locally and on replacement Ubuntu | `tests/capabilities/initial-adoption/quick-adoption.tests.ps1` |

## Required coverage

- Every strategy and the `Auto`, interactive, non-interactive, and `Abort`
  boundaries.
- Bounded exact inventory and canonical collision interaction.
- Seed-push/schedule race prevention and completed-consumer compatibility.
- Manifest, marker, issue, prompt, base/head, and rerun strategy identity.
- Semantic preservation, explicit hybrid precedence, acknowledged clean-start
  loss, and application-content non-deletion.
- Invalid input, path ambiguity, drift, interruption, and recovery behavior.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-18 | `e226293` baseline | Windows / repository baseline | Prior v0.10.4 complete-suite evidence | Green inherited baseline; TEST-0127 through TEST-0130 not yet implemented |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\capabilities-bootstrap-adapter.tests.ps1` | Passed, exit 0 in 466.6 s; all declared adapter scenarios green after the single-policy refactor |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 | `tests\quick-adoption.tests.ps1` shards `ContractsPreflight`, `IntegrityMetadataCredential`, `RepositoryRoutes`, `AdoptionLifecycle`, and `IntegrityCodexFailure` | Passed sequentially, exit 0 in 14.5 s, 286.2 s, 239.0 s, 158.3 s, and 238.9 s |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\quick-adoption.tests.ps1 -Shard All` | Passed, exit 0 in 1107 s; every declared scenario and cross-shard fixture-isolation path is green |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\protocol.tests.ps1` | Passed, exit 0 in 1576 s; all discovered suites and canonical TEST-0127 through TEST-0130 ownership are green |
| 2026-07-18 | Working tree | Static review | PowerShell AST parsing, `git diff --check`, and independent fresh-diff review | Passed; no unresolved `Blocking` finding and no classifier-to-classifier validator chain remains |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 / real Git | `tests\protocol-update-adapter.tests.ps1 -NativeStderrOnly` | `FIND-0158` reproduced in 3.5 s; initial wrapper passed in 3.6 s; self-review exposed three direct Git bypasses with an expected 3.7-second red; final unrestricted run passed in 5.0 s with successful stderr, exact HEAD, preference restoration, real ancestry/remote exits 0/1/2, unexpected failures, and no bypass under `TEST-0126` |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 / unrestricted local Git | `tests\protocol-update.tests.ps1` | Final pass in 34.8 s after two sandbox-only Git-for-Windows signal-pipe failures; every updater adapter scenario and canonical `TEST-0126` ownership is green |
| 2026-07-18 | `617d1b0` | Ubuntu / PowerShell 7 hosted expected red | [Protocol validation run 29651797496](https://github.com/hasanmanzak/meAndAI/actions/runs/29651797496) | `FIND-0159` reproduced: scalar-null `TEST-0127` and empty-marker `TEST-0130` both reached the same invalid empty-path exception; `TEST-0074` messages were secondary suite-evidence fallout |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 / unrestricted local Git | `tests\capabilities-bootstrap.tests.ps1` | Expected red in 1.4 s for the explicit singleton-null sentinel, then all canonical capabilities and real adapter scenarios passed in 461.7 s after exact normalization |
| 2026-07-18 | Working tree | Windows PowerShell 5.1 / unrestricted local Git | `tests\quick-adoption.tests.ps1 -Shard AdoptionLifecycle` | Passed in 160.3 s; empty adoption-marker surfaces and the complete focused lifecycle matrix are green |
| 2026-07-18 | `cf818e5` | GitHub-hosted Ubuntu / PowerShell 7 | [Protocol validation run 29653339317](https://github.com/hasanmanzak/meAndAI/actions/runs/29653339317) | Passed in 7 minutes 33 seconds; the corrected empty-inventory cases and all canonical suites were green |
| 2026-07-18 | `cf818e5` | GitHub-hosted Windows PowerShell 5.1 expected red | [Protocol validation run 29653339317](https://github.com/hasanmanzak/meAndAI/actions/runs/29653339317) | `Full` selected correctly; capabilities and protocol-update passed, including the screenshot regression under `TEST-0126`; the still-running quick-adoption suite was canceled at the stale 20-minute bound without a test failure (`FIND-0160`) |
| 2026-07-18 | Test-first correction working tree | Windows PowerShell 5.1 | `tests\protocol.tests.ps1 -StructureOnly` | Expected red in 2.6 seconds against the 20-minute Windows bound, then passed in 2.6 seconds with the exact Windows-only 35-minute boundary under `TEST-0124` |
