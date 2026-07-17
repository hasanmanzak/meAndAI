# DEC-0007 - Use a Local Quick-Adoption Launcher with Explicit Credential Files

- Classification: Decision
- Status: Superseded in part by [DEC-0008](DEC-0008-local-codex-execution.md)
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer administrators
- Related features: [FEAT-0006](../features/FEAT-0006-quick-adoption-launcher/README.md), [FEAT-0005](../features/FEAT-0005-ai-capabilities-lifecycle/README.md), [FEAT-0016](../features/FEAT-0016-v091-quick-adoption-correction/README.md), [FEAT-0021](../features/FEAT-0021-v096-github-cli-prerequisite/README.md)
- Related decisions: [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md)

## Context

The lifecycle workflow is intentionally unable to provision its own
credentials. A maintainer must establish repository identity, copy the exact
seed, store two Actions secrets, and publish the seed before the workflow can
run. Those steps are deterministic but security-sensitive: shell history,
process arguments, broad staging, moving source refs, or a wrong remote can
turn convenience into credential or repository exposure.

Some consumer directories already contain a clean connected project; others
have no local Git repository or remote. One launcher can support both without
becoming a general project publisher if it owns only the seed workflow and
leaves unrelated local files untouched.

## Decision

Provide one source-only PowerShell launcher at
`scripts/Invoke-MeAndAIQuickAdoption.ps1`. It runs locally under explicit
maintainer authority and never becomes a consumer-managed updater asset.
Distribute that same reviewed file as the named asset
`Invoke-MeAndAIQuickAdoption.ps1` in the exact immutable protocol release.
Maintainers keep the reusable launcher outside consumer repositories and run
it with an explicit target path. The quick path does not add a second wrapper,
execute a moving source ref, or pipe downloaded text into a shell.

The launcher uses these fixed local inputs and GitHub secret targets:

| Local file | Repository Actions secret |
| --- | --- |
| `FG_PAT.txt` | `MEANDAI_UPDATER_TOKEN` |
| `MEANDAI_RO_FG_PAT.txt` | `MEANDAI_PROTOCOL_TOKEN` |

Token values are read only in process memory, transferred to `gh secret set`
through standard input, and never printed, persisted elsewhere, passed as
arguments, or deleted. Both filenames are added to `.git/info/exclude`. If
either file is tracked, staged, or appears in Git history, the launcher blocks
and requires credential rotation before reuse.

The protocol-read token downloads the workflow through the GitHub contents API
at an exact canonical release tag. The launcher verifies the response Git blob
before an atomic write. An existing exact workflow is accepted; any differing
target blocks without overwrite.

For an existing repository, the root must equal the selected directory, the
working tree must be clean apart from an exact seed candidate, `origin` must
resolve to GitHub, the current branch must be the GitHub default branch, and
the local head must equal the observed remote head before the seed commit. For
a directory with no own repository, the launcher initializes `main`. If
`origin` is absent, it resolves the exact requested
`<owner>/<repository-name>` through the authenticated GitHub CLI. An accessible
existing repository is connected automatically only when it has no branch
history; a non-empty repository blocks for manual clone or reconciliation. If
the repository does not exist, the launcher creates it as private by default.
It stages and commits only the workflow, so unrelated local files remain
unpublished.

The launcher configures both secrets before pushing the workflow. After that
publication succeeds, its default continuation dispatches the lifecycle,
waits under a finite timeout for the exact seed commit, resolves the single
deterministic draft, and places one idempotently marked `@codex` task on it.
This delegation uses the maintainer's configured Codex Cloud GitHub connection;
it does not embed an OpenAI API key or install another consumer workflow.

Fine-grained PAT repository grants cannot be modified through this launcher; a
token that cannot see a newly created selected repository blocks with
instructions to update its grant and rerun. The empty created remote is a
recognized resumable state. Workflow dispatch and Codex delegation may be
explicitly skipped for troubleshooting, but the launcher never approves or
merges the adoption pull request.

## Consequences

- Normal first adoption becomes one local command through workflow completion
  and a durable Codex Cloud handoff; final evidence review and merge remain a
  maintainer gate.
- Secret values do not enter shell arguments, Git content, logs, or project
  memory, but the two source files remain the maintainer's local responsibility.
- A newly created empty GitHub repository may remain after a later failure.
  Exact-state reruns reconcile it; the launcher does not guess at rollback or
  delete remote repositories.
- Existing dirty, ahead, behind, non-default, customized, or non-GitHub states
  require normal maintainer reconciliation instead of automation.
- The launcher deliberately does not publish unrelated local project files.
- The v0.5 lifecycle remains the authority for adoption PR content and all
  post-adoption updates.

## Alternatives considered

- Keep the copy/secret/commit steps manual: rejected because the exact same
  security-sensitive sequence would be repeated for every consumer.
- Put credential provisioning in GitHub Actions: rejected because a workflow
  cannot safely create the credential it needs and would cross the established
  credential boundary.
- Pass token values through `--body` or environment variables: rejected because
  arguments and inherited process state increase accidental disclosure risk;
  GitHub CLI supports stdin and encrypts values locally.
- Commit all files when initializing a new directory: rejected because adoption
  authority does not imply permission to publish unrelated project content.
- Automatically merge adoption: rejected because deterministic seeding and
  Codex execution do not replace the maintainer's final evidence and merge
  gate.
- Add a second consumer workflow around `openai/codex-action`: rejected for
  this release because it would require a third persistent API-key secret and
  broaden the bootstrap. The configured Codex Cloud `@codex` task is the
  smaller supported handoff.
- Delete a newly created remote after a later failure: rejected because remote
  deletion is destructive and partial ownership cannot be assumed.

## Review condition

Revisit if GitHub offers a first-party installation flow that atomically creates
the consumer repository, installs scoped credentials, and opens the adoption
handoff without persistent PAT files, or when meAndAI becomes public and the
read-only source-token input is no longer required.
