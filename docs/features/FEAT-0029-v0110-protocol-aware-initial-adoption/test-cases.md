# FEAT-0029 Test Scenarios

Test implementation: [capabilities resolver](../../../tests/capabilities-bootstrap.tests.ps1),
[bootstrap adapter](../../../tests/capabilities-bootstrap-adapter.tests.ps1),
[quick launcher](../../../tests/quick-adoption.tests.ps1), and
[repository structural suite](../../../tests/protocol.tests.ps1).

| ID | Related slice | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0127` | `SUBF-0053` | Classify an empty/protocol-free tree and trees containing each declared protocol surface; vary duplicates, case collisions, malformed paths, canonical target collisions, and unknown strategy values. | The inventory is unique, sorted, bounded, and exact; `Auto` resolves only a clean tree to `FreshAdoption`; explicit fresh adoption rejects evidence; malformed or ambiguous inputs stop without a proposal. | Unit / contract / boundary / negative | Passed | `tests/capabilities-bootstrap.tests.ps1` |
| `TEST-0128` | `SUBF-0053` | Exercise workflow dispatch, seed push, schedule, existing proposal, and completed-consumer routes with every strategy, loss-acknowledgement state, manifest/marker property variant, and changed base/head. | Only an explicit or safely auto-resolved strategy creates an initial proposal; push/schedule cannot race selection; strategy and surfaces are exact in manifest and marker; existing updater/finalizer routes remain unchanged. | Integration / event / identity / recovery | Passed | `tests/capabilities-bootstrap-adapter.tests.ps1`, workflow structural checks |
| `TEST-0129` | `SUBF-0054` | Run local semantic completion fixtures for full migration, hybrid reconciliation, and clean start, including legacy project directives, decisions/tests, application files, unacknowledged loss, and a requested out-of-inventory deletion. | Full mode preserves semantics then retires legacy authority; hybrid records precedence; clean start imports no legacy governance and requires acknowledgement; application/product content is unchanged; unapproved deletion blocks. | Integration / semantic contract / destructive negative | Passed | `tests/quick-adoption.tests.ps1` and mock Codex fixtures |
| `TEST-0130` | `SUBF-0054` | Invoke explicit, interactive, non-interactive, abort, rerun, interruption, strategy-mismatch, additional-surface, and completed-consumer launcher paths. | Inventory is shown before choice; non-interactive ambiguity and mismatch stop before mutation; abort is a no-op; the prompt cannot change strategy; exact reruns recover; completed consumers bypass initial strategy selection. | Launcher / UX / recovery / compatibility | Passed | `tests/quick-adoption.tests.ps1` |

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
