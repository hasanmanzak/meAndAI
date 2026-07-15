# FEAT-0007 - Complete Quick Adoption with Local Codex CLI

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | In review |
| Target version | 0.6.1 |
| Issue | [#21](https://github.com/hasanmanzak/meAndAI/issues/21) |
| Pull request | Pending |
| Decision | [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The v0.6.0 launcher completes its deterministic local work but delegates the
semantic adoption draft through a Codex Cloud `@codex` comment. A consumer
maintainer may use Codex CLI locally without connecting the private consumer
repository to Codex Cloud. Secret provisioning also does not require an AI
agent, so coupling that operation to Cloud is unnecessary.

## Outcome

The launcher provisions both Actions secrets, publishes the exact seed, runs
and awaits the lifecycle workflow, and invokes local Codex only when that run
produces a draft that still contains the adoption manifest. Codex works
synchronously in a temporary clone of the draft's immutable head. The launcher
then validates the result, commits it, and publishes it with an exact-head
lease. The maintainer retains the final pull-request review and merge gate.

## Scope

- Remove Codex Cloud comments, markers, prerequisites, and user guidance.
- Prefer an authenticated installed `codex` command and otherwise use a pinned
  temporary `@openai/codex` package through `npx`, without a global install.
- Clone only the deterministic adoption branch at the pull request's exact head
  into an operating-system temporary directory.
- Keep both credential source files and token values outside the clone and
  prompt; mention only the filenames, secret names, and completed provisioning.
- Run `codex exec` synchronously with an ephemeral session, `workspace-write`,
  a finite timeout, disabled spawned-command network access, bounded
  permissions, and captured final output.
- Reconcile the common Agile labels and one project-owned adoption issue in the
  launcher before local Codex starts; pass only the issue reference to Codex.
- Require unchanged Git head, manifest removal, a non-empty valid diff, no
  credential files, and an unchanged remote branch before a lease-protected
  commit and push.
- Preserve `-SkipCodexDelegation` as an alias for `-SkipLocalCodex`.
- Update the quick guide, adoption contract, version, changelog, and project
  memory for v0.6.1.

## Non-goals

- Connecting a consumer to Codex Cloud or posting an `@codex` comment.
- Passing token values, credential files, or an OpenAI API key to Codex.
- Automatically approving or merging the adoption pull request.
- Replacing the lifecycle workflow or consumer updater.
- Building a general-purpose agent orchestrator, validator chain, container, or
  hosted service.
- Claiming that local CLI inference is offline; it uses the maintainer's saved
  Codex authentication and configured model service.

## Readiness evidence

- Domain and contracts: seed publication, Actions-secret reconciliation,
  lifecycle run, draft identity, draft head, local CLI process, temporary clone,
  Codex result, Git commit, remote lease, and maintainer merge are separate
  boundaries. Token values remain local deterministic inputs and are never AI
  inputs.
- Ordering: secrets and seed precede workflow dispatch; the exact workflow run
  precedes draft resolution; draft resolution precedes CLI discovery; local
  validation and remote-head revalidation precede commit and push.
- Compatibility: v0.6.0 callers may continue using the old skip switch alias;
  the manual workflow-only path and existing pinned consumers remain valid.
- Verification: PowerShell AST and structural checks, real-Git fixtures with a
  mocked local Codex boundary, remote-head race coverage, and the complete
  protocol regression suite.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0036` | Credential confidentiality | Codex reads or emits consumer PAT values | Mitigated by launcher | Token values are absent from prompt/clone/environment; fixed filenames are rejected in the clone; output is never used as secret input |
| `RISK-0037` | Repository integrity | Codex commits, pushes, or changes an unexpected head | Mitigated by launcher | Detached execution contract, unchanged-head check, launcher-owned commit, exact remote-head lease, no merge |
| `RISK-0038` | Concurrency | The adoption branch changes during the local run | Mitigated by launcher | PR `headRefOid`, live ref recheck, and `--force-with-lease` expected head |
| `RISK-0039` | Tool availability | Codex is absent, unauthenticated, or a temporary download fails | Managed by maintainer | Installed CLI preference, pinned `npx` fallback, login-status gate, actionable failure, explicit skip path |
| `RISK-0040` | Semantic completion | Codex reports success but leaves the manifest or no reviewable change | Mitigated by launcher | Require zero Codex-created commits, manifest removal, non-empty diff, `git diff --check`, and explicit result capture before publication |
| `RISK-0041` | Unbounded execution | Local authentication or semantic work stalls indefinitely | Mitigated by launcher | Both calls use the finite `CodexTimeoutMinutes` process boundary and terminate the process tree on expiry |
| `RISK-0042` | Publication authority | Codex uses inherited GitHub credentials to mutate or merge remote state | Mitigated by launcher | Launcher owns labels, issue, commit, push, and readiness; Codex spawned commands have network disabled and receive no GitHub task |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0038 through TEST-0041](test-cases.md) |
| Test code | Automated and green | `tests/quick-adoption.tests.ps1`; the v0.6.0 implementation first failed 19 targeted FEAT-0007 assertions |
| Baseline run | Passed | v0.6.0 Windows PowerShell 5.1 suite passed TEST-0001 through TEST-0037 before this correction |
| Feature and regression run | Passed | Windows PowerShell 5.1 passed TEST-0001 through TEST-0041 in 94.4 seconds on 2026-07-15 |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0013` | Local CLI resolution and isolated semantic completion | [Issue #21](https://github.com/hasanmanzak/meAndAI/issues/21) | `TEST-0038`, `TEST-0039`, `TEST-0040`; pass | `FIND-0056` through `FIND-0058`; resolved | Implemented |
| `SUBF-0014` | v0.6.1 contract, guidance, and regression closure | [Issue #21](https://github.com/hasanmanzak/meAndAI/issues/21) | `TEST-0041` and full suite; pass | `FIND-0059`; resolved | Implemented |

## Decisions and relationships

- Decision: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Corrects: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Lifecycle dependency: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md)
- Credential boundary: [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Seed handoff: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking: [issue #21](https://github.com/hasanmanzak/meAndAI/issues/21)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Process, credential, Git, CLI, lifecycle, and error contracts.
- [x] Numbered risks and DEC-0008.
- [x] Two bounded, reviewable slices.
- [x] Numbered test scenarios and verification approach.
- [x] Baseline and planned red-test state recorded.

## Acceptance criteria

1. The launcher provisions both existing secret mappings and publishes the
   exact v0.6.1 seed before dispatching and awaiting the exact lifecycle run.
2. No local Codex command is required when the lifecycle produces no pending
   adoption draft.
3. A pending adoption draft is resolved with its exact `headRefOid`, cloned to
   an isolated temporary directory, and processed synchronously by local
   `codex exec` using saved local authentication under a finite timeout.
4. An installed Codex CLI is preferred. If absent and `npx` is available, the
   launcher uses only the pinned temporary `@openai/codex` version and performs
   no global installation.
5. Neither token value nor credential source file enters the Codex prompt,
   clone, command arguments, output, tracked content, or memory. The prompt may
   name the established file-to-secret mappings only to state that provisioning
   is complete and out of scope.
6. Missing authentication, a remaining manifest, a Codex-created commit, an
   empty or invalid diff, a credential file, or a moved remote head blocks
   publication with no automatic cleanup of remote state.
7. A successful local result is committed by the launcher and pushed only to
   the deterministic draft branch under an exact expected-head lease. The
   launcher never approves or merges the pull request.
8. Required common labels and one marked adoption issue are reconciled by the
   launcher, while Codex-spawned commands have no network access. A draft that
   already lacks the manifest is never promoted without launcher-owned proof.
9. v0.6.0 skip-switch callers remain compatible, documentation contains no
   active Cloud instruction, and all existing lifecycle/updater tests pass.

## Self-review

The one fresh-diff review found and the implementation resolved these blocking
items without opening a second review loop:

| ID | Priority | Finding | Resolution |
| --- | --- | --- | --- |
| `FIND-0056` | P0 | Local Codex had no execution deadline. | Added a finite process boundary, captured output, and process-tree termination. |
| `FIND-0057` | P1 | A manifest-free draft could be marked ready without launcher-owned evidence. | Such a draft is now left unchanged for explicit maintainer review. |
| `FIND-0058` | P1 | Prompt-only instructions did not enforce the remote publication boundary. | Launcher owns deterministic labels and issue; Codex-spawned commands have network disabled. |
| `FIND-0059` | P2 | The new unverified-draft test tried to capture `Write-Host` through the success stream on Windows PowerShell 5.1. | The executable gate now asserts zero readiness calls and unchanged Codex-call count; the user-facing message is checked structurally. |

The final full protocol verification passed `TEST-0001` through `TEST-0041` in
94.4 seconds. No unresolved actionable in-scope finding remains, so the bounded
scan stops here.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Both slice reviews and bounded scan stop condition complete.
- [x] No unresolved blocking finding; residual risks explicit and owned.
- [x] Documentation, links, version, and project memory current.
- [ ] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates pass.
