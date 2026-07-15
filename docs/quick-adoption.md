# Quick Adoption

This guide installs the one-file seed for the meAndAI AI-capabilities
lifecycle. It supports both a clean existing GitHub repository and a local
directory that has no repository or `origin` yet.

The launcher creates the repository when needed, provisions credentials,
publishes the exact seed, dispatches the lifecycle workflow, and waits for its
bounded result. If that run creates a semantic adoption draft, the launcher
uses local Codex CLI synchronously in a temporary clone, validates and pushes
the result, and marks the pull request ready. The launcher, not Codex,
reconciles the common labels and adoption issue. It never approves or merges;
the maintainer performs the final review and merge.

## Prerequisites

- PowerShell 5.1 or newer, `git`, and GitHub CLI (`gh`).
- `gh auth status` succeeds for an account allowed to create the target
  repository when needed, set its Actions secrets, and maintain its adoption
  labels and issue.
- [Local Codex CLI](https://github.com/openai/codex#readme) is installed and
  authenticated (`codex login status`). If
  `codex` is absent but `npx` is available, the launcher uses the pinned
  temporary package `@openai/codex@0.144.4` without a global install.
- An existing connected consumer is clean, checked out on its GitHub default
  branch, and synchronized with `origin`.
- The target directory contains these two local-only files:

| Local file | Content | Actions secret created by the launcher |
| --- | --- | --- |
| `FG_PAT.txt` | Consumer updater fine-grained PAT | `MEANDAI_UPDATER_TOKEN` |
| `MEANDAI_RO_FG_PAT.txt` | Read-only meAndAI fine-grained PAT | `MEANDAI_PROTOCOL_TOKEN` |

The updater token needs repository access plus `Contents: Read and write`,
`Pull requests: Read and write`, and `Workflows: Read and write` for its
consumer. The read token needs read-only contents access to
`hasanmanzak/meAndAI`. If either token uses GitHub's selected-repository mode,
its grant must include the relevant repository. A token created before a new
consumer exists may need that repository added after the launcher's first
attempt; update the grant and rerun the same command.

Do not commit either token file. The launcher adds both names to
`.git/info/exclude`, blocks tracked or historically committed copies, transfers
their values only to the two named repository secrets, and leaves the local
files in place. Secret provisioning is deterministic PowerShell/`gh` work; it
does not require Codex and the values are never placed in the Codex prompt.

## Quick command

Open PowerShell in the target directory and paste this single line. It
downloads the launcher from the exact `v0.6.1` tag into the OS temp directory
and runs it; it does not execute a moving `main` file.

```powershell
$p=Join-Path ([IO.Path]::GetTempPath()) 'Invoke-MeAndAIQuickAdoption-v0.6.1.ps1'; gh api -H 'Accept: application/vnd.github.raw+json' 'repos/hasanmanzak/meAndAI/contents/scripts/Invoke-MeAndAIQuickAdoption.ps1?ref=v0.6.1' | Set-Content -LiteralPath $p -Encoding UTF8; & $p -TargetPath .
```

The same command in a more readable form is:

```powershell
$launcher = Join-Path $env:TEMP 'Invoke-MeAndAIQuickAdoption-v0.6.1.ps1'
gh api -H 'Accept: application/vnd.github.raw+json' 'repos/hasanmanzak/meAndAI/contents/scripts/Invoke-MeAndAIQuickAdoption.ps1?ref=v0.6.1' | Set-Content -LiteralPath $launcher -Encoding UTF8
& $launcher -TargetPath .
```

For an existing connected repository, no owner or name is needed. The launcher
validates the GitHub `origin`, preserves application content, commits only
`.github/workflows/meandai-protocol-update.yml`, and pushes the default branch.

For a directory without a local repository or `origin`, it initializes `main`,
uses the active `gh` owner and directory name, and creates a private repository
by default. Unrelated local files remain untracked and are not published. To
override the inferred identity or visibility:

```powershell
& $launcher -TargetPath . -Owner 'my-owner' -RepositoryName 'my-repo' -Visibility private
```

Running the command is explicit authorization to read the two fixed token
files and transmit their contents only to the selected `<owner>/<repository>`
as `MEANDAI_UPDATER_TOKEN` and `MEANDAI_PROTOCOL_TOKEN` Actions secrets. The
values are not command-line arguments and are not printed.

If remote creation succeeds but a later credential, commit, workflow, or local
Codex gate blocks, do not delete or reset anything. Resolve the reported
condition and rerun. Exact seed and completed-adoption states are idempotent.

## Default execution order

Only after both secrets are stored and the seed commit is pushed, the launcher:

1. Dispatches **meAndAI AI capabilities lifecycle** on the default branch.
2. Waits up to 15 minutes for that exact commit's run and fails if it is not
   successful.
3. Resolves the single deterministic adoption draft and its immutable
   `headRefOid`.
4. If the transient manifest is present, reconciles the common Agile labels and
   one canonically marked adoption issue through the launcher's authenticated
   `gh` process.
5. Resolves the installed local Codex CLI or pinned temporary fallback.
6. Clones only the adoption branch into an OS temporary directory. The original
   checkout and its credential files are not the Codex workspace.
7. Runs [`codex exec`](https://learn.chatgpt.com/docs/non-interactive-mode)
   synchronously with an ephemeral `workspace-write` session, a 30-minute
   default process limit, and spawned-command network access disabled.
8. Requires an unchanged Git head, manifest removal, a valid non-empty diff,
   absent credential files, and an unchanged live remote branch.
9. Creates the adoption completion commit, pushes it with an exact
   `--force-with-lease`, and marks the pull request ready without merging it.

An empty consumer receives a deterministic bootstrap proposal. A populated
consumer with target collisions receives
`.ai/adoption/meandai-capabilities.json` instead of overwritten files. Local
Codex uses the exact protocol source snapshot for semantic reconciliation.

The CLI process reuses the maintainer's saved local Codex authentication. No
consumer repository connection to hosted GitHub-agent execution is required.
Local orchestration is not offline inference: the CLI sends its prompt and
relevant repository context to its configured model service.

For troubleshooting or a deliberately manual handoff:

```powershell
& $launcher -TargetPath . -SkipLifecycleDispatch
& $launcher -TargetPath . -SkipLocalCodex
```

`-SkipLifecycleDispatch` also skips local Codex because no draft is expected.
`-SkipCodexDelegation` remains an alias for `-SkipLocalCodex` for v0.6.0 caller
compatibility. The workflow wait is bounded by `-WorkflowTimeoutMinutes 15`
(allowed range: 1 through 60). Local authentication and execution are bounded
by `-CodexTimeoutMinutes 30` (allowed range: 1 through 120). If a draft already
lacks the manifest when inspected, the launcher does not rerun Codex or mark
the draft ready; the maintainer must validate that prior change manually.

## Codex prompt

The launcher supplies a scoped prompt over standard input. Its essential
contract is:

```text
Complete this consumer repository's meAndAI AI-capabilities adoption in the
isolated clone of the deterministic draft head.

Read .ai/adoption/meandai-capabilities.json, the exact protocol source supplied
by the launcher, every applicable AGENTS.md, and existing project files. Resolve
collisions semantically; create or reconcile feature and decision records,
local memory, tests, evidence, and clickable links. Reference the project-owned
adoption issue already created by the launcher. Do not invent project facts.
Remove the manifest only when all adoption gates are satisfied.

Secret provisioning is complete: FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and
MEANDAI_RO_FG_PAT.txt maps to MEANDAI_PROTOCOL_TOKEN. The files are intentionally
absent. Do not search for, request, print, recreate, or modify credential values
or repository secrets.

Spawned-command network access is disabled. Do not invoke gh, GitHub APIs,
remote Git operations, or another external service. Do not change the pinned
protocol or lifecycle workflow. Do not commit, push, approve, mark ready,
merge, close, or delete; the launcher owns GitHub records and publication and
the maintainer owns merge. Keep review bounded and report the exact blocker if
project facts or required evidence are unavailable.
```

For lifecycle states, collision semantics, and the manual alternative, see the
[complete adoption guide](adoption.md).
