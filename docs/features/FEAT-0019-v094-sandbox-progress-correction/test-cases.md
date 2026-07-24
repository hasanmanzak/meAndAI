# FEAT-0019 Test Scenarios

Implementation: [`tests/capabilities/initial-adoption/quick-adoption.tests.ps1`](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1)
and the complete repository suite.

| ID | Related work | Scenario | Expected result | Level | Status | Automation |
| --- | --- | --- | --- | --- | --- | --- |
| `TEST-0103` <a name="test-0103"></a> | `FEAT-0019` / [BUG-0007](https://github.com/hasanmanzak/meAndAI/issues/55) | Exercise native Windows Codex configuration with `unelevated`, an unavailable preferred `elevated` implementation, successful unelevated fallback, probe write/read/delete failure, and probe residue. | Only `elevated` or `unelevated` crosses `--ignore-user-config`; the exact selected mode is used by the model-free probe and semantic run; successful fallback remains sandboxed; every probe failure blocks before a model call and leaves no accepted residue. | Contract / mocked-process regression | Passing | Quick-adoption launcher fixture plus structural assertions |
| `TEST-0104` <a name="test-0104"></a> | `FEAT-0019` | Inspect and exercise interactive phase progress, `-NoProgress`, error cleanup, indeterminate elapsed local-Codex status, and the empty-consumer prompt contract. | Progress names only real phases, never converts timeout into work completion, and is completed on every exit; suppression is deterministic; an empty consumer records unknown product facts without fabrication and may complete structural protocol adoption. | UX and semantic-boundary regression | Passing | PowerShell AST/source assertions and host-function fixture |

## Required coverage

- Exact parsing and allowlisting of the native Windows sandbox implementation.
- Retention of `--ignore-user-config`, `workspace-write`, approval denial, and
  spawned-command network denial.
- Token-free probe ordering before semantic Codex execution.
- Elevated failure, unelevated fallback, no-full-access invariant, and probe
  cleanup on success and failure.
- Truthful phase progress, elapsed indeterminate long-process status,
  `-NoProgress`, and final cleanup.
- Empty-repository adoption with explicit unknown application facts and no
  fabricated build or product-test evidence.
- Existing affected-consumer `v0.9.2` draft recovery and all prior quick-adoption gates.

## Evidence

| Date | Commit | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-16 | `v0.9.3` release asset | Windows PowerShell 5.1 / Codex CLI 0.144.4 | Affected-consumer quick-adoption run recorded in [issue #55](https://github.com/hasanmanzak/meAndAI/issues/55) | External red: model entered a read-only workspace and treated absent product facts as adoption blockers |
| 2026-07-16 | Pre-implementation host probe | Windows PowerShell 5.1 / Codex CLI 0.144.4 | `codex sandbox -P :workspace ...` with explicit Windows implementations | External red/green isolation: `unelevated` wrote/read/deleted the probe; `elevated` failed to launch the setup helper with Access Denied |
| 2026-07-16 | Test-first working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Expected red in 2.6 seconds: 24 focused failures identified the absent sandbox carry-forward, token-free probe, progress lifecycle, empty-consumer prompt, guide, and fixture contracts before integration execution |
| 2026-07-16 | Reviewed v0.9.4 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/quick-adoption.tests.ps1` | Passed in 359.1 seconds; all 34 owned scenarios passed, including `TEST-0103` and `TEST-0104` |
| 2026-07-16 | Reviewed v0.9.4 working tree | Windows PowerShell 5.1 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` | Passed in 526.4 seconds; every discovered suite and all declared scenario-ownership gates passed |
| 2026-07-16 | [PR #56](https://github.com/hasanmanzak/meAndAI/pull/56) initial hosted matrix | Ubuntu / Windows GitHub-hosted runners | `Protocol validation` run `29534127731` | Windows passed; Ubuntu exposed that the new Windows-only runtime fixture assertions were unconditional. The fixture was platform-gated and the non-Windows no-probe contract was added before merge. |

Pull-request and hosted publication evidence remains pending; [issue #55](https://github.com/hasanmanzak/meAndAI/issues/55) owns
the external facts.
