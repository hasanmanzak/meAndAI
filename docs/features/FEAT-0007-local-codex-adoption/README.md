# FEAT-0007 - Complete Quick Adoption with Local Codex CLI

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.6.1 |
| Issue | [#21](https://github.com/hasanmanzak/meAndAI/issues/21) |
| Pull request | [#22](https://github.com/hasanmanzak/meAndAI/pull/22) |
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
- Delivery: [pull request #22](https://github.com/hasanmanzak/meAndAI/pull/22)

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
- [x] Issue, pull request, decisions, and related work cross-linked.
- [x] Applicable CI and review gates pass.

## Release evidence

[Pull request #22](https://github.com/hasanmanzak/meAndAI/pull/22) merged as
`a4ffefa698b079815edebda86204150b03707957`. The remote annotated
[`v0.6.1` tag](https://github.com/hasanmanzak/meAndAI/tree/v0.6.1) resolves to
that exact merge commit. The owned delivery branch was deleted locally and
remotely after merge verification.

## BUG-0001 correction for v0.6.2

| Field | Value |
| --- | --- |
| Classification | Bug correction |
| Status | Complete |
| Target version | 0.6.2 |
| Issue | [#24](https://github.com/hasanmanzak/meAndAI/issues/24) |
| Pull request | [#25](https://github.com/hasanmanzak/meAndAI/pull/25) |
| Test | [`TEST-0042`](test-cases.md) |

### Problem and outcome

The v0.6.1 launcher unconditionally calls `gh secret set` for both mapped
repository Actions secrets. On an existing repository, that can replace a
maintainer-managed secret even though the launcher only needs to create a
missing mapping.

The correction lists repository Actions secret names, preserves every existing
mapped name without attempting a write, and creates only missing mapped
secrets. GitHub does not expose stored secret values, so presence is not treated
as value validation.

### Scope and contracts

- Compare the two canonical secret names case-insensitively against the
  repository-level Actions-secret name list.
- Do not read `FG_PAT.txt`, preflight its token, or call `gh secret set` for
  `MEANDAI_UPDATER_TOKEN` when that secret already exists.
- Continue requiring `MEANDAI_RO_FG_PAT.txt` as the private protocol source
  credential, but do not write `MEANDAI_PROTOCOL_TOKEN` when that secret exists.
- Retain tracked-file and Git-history safety checks for both credential paths,
  including when an optional source file is absent because its mapped secret
  already exists.
- Preserve the v0.6.1 new-repository behavior: both missing secrets are created
  before seed publication.
- Fail closed if the existing secret-name list cannot be obtained or a required
  missing secret has no valid local credential file.

No secret value comparison, rotation, deletion, organization/environment secret
management, or general credential manager is in scope. This correction refines
the deterministic reconciliation boundary in
[DEC-0008](../../decisions/DEC-0008-local-codex-execution.md); it does not require
a new architectural decision.

### Readiness and acceptance

- [x] Stable ID and linked issue exist.
- [x] Problem, outcome, scope, non-goals, credential ownership, ordering, and
      failure behavior are explicit.
- [x] `RISK-0043`: a present secret may contain an invalid or stale value.
      Owner: consumer maintainer. Response: preserve it by name, make no claim
      about its value, and let the bounded lifecycle expose an unusable secret.
- [x] `TEST-0042` covers existing-secret preservation, missing-secret creation,
      omitted updater source input, and new-repository regression behavior.
- [x] Verification is bounded to one focused red/green run, one fresh-diff
      review, and one complete protocol run.

Acceptance requires zero `gh secret set` calls for already-present mapped
names, exactly one call for each missing mapped name, unchanged credential
redaction and history gates, and a green `TEST-0001` through `TEST-0042` suite.

### Verification and self-review

| ID | Priority | Finding | Resolution |
| --- | --- | --- | --- |
| `FIND-0060` | P2 | The first documentation assertion treated Markdown line wrapping as semantic content and failed twice on one correctly worded sentence. | Normalized guide whitespace before checking the complete sentence; the next full run passed. |
| `FIND-0061` | P1 | Making `FG_PAT.txt` optional initially skipped its Git-history check when the file was absent. | Moved required-file presence evaluation after unconditional tracked-path and history checks; added an absent-but-historical regression fixture. |

The focused pre-implementation run failed because the launcher had no
`gh secret list` contract. The first focused green run passed in 43.3 seconds.
After `FIND-0060` was resolved, the complete Windows PowerShell 5.1 suite passed
`TEST-0001` through `TEST-0042` in 91.7 seconds. The post-review focused
confirmation for `FIND-0061` passed `TEST-0033` through `TEST-0042` in 44.9
seconds. `git diff --check` reported no whitespace error.

### Definition of Done

- [x] Existing mapped repository secrets are preserved without a set attempt.
- [x] Only missing mappings read their required mutation input and are created.
- [x] Credential redaction, tracked-path, and history gates remain intact.
- [x] New-repository provisioning remains backward compatible.
- [x] `TEST-0042`, the complete regression suite, and bounded self-review pass.
- [x] Protocol, guides, changelog, version metadata, feature record, and project
      memory are synchronized.
- [x] No unresolved blocking or actionable in-scope finding remains.

## BUG-0002 correction for v0.6.3

| Field | Value |
| --- | --- |
| Classification | Bug correction |
| Status | Implemented and verified; delivery pending |
| Target version | 0.6.3 |
| Issue | [#27](https://github.com/hasanmanzak/meAndAI/issues/27) |
| Pull request | [#29](https://github.com/hasanmanzak/meAndAI/pull/29) |
| Test | [`TEST-0043`](test-cases.md) |

### Problem and outcome

The v0.6.2 launcher makes `FG_PAT.txt` optional when its mapped updater secret
exists, but still requires `MEANDAI_RO_FG_PAT.txt` before it can inspect and
preserve an existing `MEANDAI_PROTOCOL_TOKEN`. Consequently, a fully configured
existing target cannot rerun quick adoption without retaining the two local
credential files.

For an existing connected target, each local token file becomes required only
when its mapped repository Actions secret is missing. If
`MEANDAI_PROTOCOL_TOKEN` exists and its source file is absent, the launcher uses
the already-required authenticated local `gh` session to fetch the exact tagged
private protocol source and applies the same Git-blob verification. It never
reads the stored repository secret value.

### Scope and contracts

- Inspect repository secret names before deciding which local files are
  required on an existing connected target.
- Preserve an existing mapped secret without a set operation, whether or not
  its local source file exists.
- Use `MEANDAI_RO_FG_PAT.txt` for source retrieval when present. When it is
  absent and `MEANDAI_PROTOCOL_TOKEN` exists, use authenticated `gh api` for
  the exact workflow and `gh repo clone` for the exact semantic-adoption
  snapshot. Verify the workflow blob and snapshot commit as before.
- Require a mapped local file when its repository secret is missing; do not use
  `gh` authentication as a substitute for provisioning that missing secret.
- Keep both files mandatory for a new repository, before remote creation.
- Preserve exact-tag validation, Git-blob verification, tracked-path/history
  gates, standard-input secret writes, redaction, and new-repository behavior.

Reading repository secret values, importing organization/environment secrets,
rotating credentials, or adding a credential manager is out of scope. This is a
transport fallback inside the authenticated launcher boundary already accepted
by [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md), not a new
architectural boundary.

### Readiness and acceptance

- [x] Stable `BUG-0002` ID and linked issue #27 exist.
- [x] Problem, outcome, scope, non-goals, ownership, ordering, and failure
      behavior are explicit.
- [x] `RISK-0044`: the authenticated `gh` identity may lack private meAndAI
      source access even though the target secret name exists. Owner: consumer
      maintainer. Response: fail with an actionable source-access error; never
      request or recover the stored secret value.
- [x] `TEST-0043` covers both files absent with both secrets present, a missing
      secret with its file absent, recovery with the required file, and the
      unchanged new-repository requirement.
- [x] Verification is bounded to one focused red/green line, one fresh-diff
      review, and one complete protocol run.

Acceptance requires a configured existing target to proceed with both local
files absent, while every missing target secret still requires its own file and
all `TEST-0001` through `TEST-0043` scenarios pass.

### Definition of Done

- [x] Existing-target file requirements derive from repository secret names.
- [x] File-free workflow and semantic-source retrieval preserve exact source
      verification without reading stored secret values.
- [x] Missing-secret and new-repository credential gates remain fail-closed.
- [x] `TEST-0043` passes its focused real-Git regression suite.
- [x] The complete protocol suite and bounded fresh-diff review pass.
- [ ] Documentation, project memory, pull-request evidence, merge, and the
      separate `v0.6.3` tag gate are complete.
