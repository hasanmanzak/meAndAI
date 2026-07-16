# Quick Adoption

This guide installs the one-file seed for the meAndAI AI-capabilities
lifecycle. It supports both a clean existing GitHub repository and a local
directory that has no repository or `origin` yet.

The launcher is distributed as one asset of the requested immutable GitHub
Release. It verifies that release again before accepting executable source,
creates the repository when needed, provisions credentials, publishes the exact
seed, dispatches the lifecycle workflow, and waits for its bounded result. If
that run creates a semantic adoption draft, the launcher
uses local Codex CLI synchronously in a temporary clone, validates and pushes
the result, and marks the pull request ready. The launcher, not Codex,
reconciles the common labels and adoption issue. It never approves or merges;
the maintainer performs the final review and merge.

The launcher queries the exact `releases/tags/<tag>` endpoint with
`X-GitHub-Api-Version: 2026-03-10` and accepts only a published immutable
GitHub Release whose tag and publication metadata match the requested version.
This supply-chain check remains inside the reviewed launcher rather than in a
copy-pasted command stack.

## Prerequisites

- PowerShell 5.1 or newer, `git`, and GitHub CLI (`gh`).
- `gh auth status` succeeds for an account allowed to create the target
  repository when needed, set its Actions secrets, and maintain its adoption
  labels and issue. When the existing protocol secret is reused without its
  local source file, that account must also be able to read
  `hasanmanzak/meAndAI`.
- [Local Codex CLI](https://github.com/openai/codex#readme) is installed and
  authenticated (`codex login status`). If
  `codex` is absent but `npx` is available, the launcher uses the pinned
  temporary package `@openai/codex@0.144.4` without a global install.
- An existing connected consumer is clean, checked out on its GitHub default
  branch, and synchronized with `origin`.
- The target directory contains the applicable local-only files:

| Local file | Content | Requirement | Actions secret mapping |
| --- | --- | --- | --- |
| `FG_PAT.txt` | Consumer updater fine-grained PAT | Required for a new repository or when `MEANDAI_UPDATER_TOKEN` is absent; not read when that secret exists | `MEANDAI_UPDATER_TOKEN` |
| `MEANDAI_RO_FG_PAT.txt` | Read-only meAndAI fine-grained PAT | Required for a new repository or when `MEANDAI_PROTOCOL_TOKEN` is absent; optional when that secret exists and used for source retrieval when present | `MEANDAI_PROTOCOL_TOKEN` |

The updater token needs repository access plus `Contents: Read and write`,
`Pull requests: Read and write`, and `Workflows: Read and write` for its
consumer. The read token needs read-only contents access to
`hasanmanzak/meAndAI`. If either token uses GitHub's selected-repository mode,
its grant must include the relevant repository. A token created before a new
consumer exists may need that repository added after the launcher's first
attempt; update the grant and rerun the same command.

Do not commit either token file. The launcher adds both names to
`.git/info/exclude`, rejects shallow repositories, and blocks copies found in
the index or in locally reachable Git refs and reflogs even when an optional
source file is currently absent. This local check cannot prove the absence of a
credential path in remote commits that were never fetched or that have already
been pruned or garbage-collected. Rotate the credential and inspect the remote
history whenever prior exposure is suspected. For an existing repository the
launcher lists repository-level Actions secret names, preserves either
canonical name that already exists, and sends a value through `gh secret set`
only for a missing name. GitHub does not reveal stored values, so this presence
check does not validate value, scope, expiry, or usability. Organization and
environment secrets do not replace these two repository secrets. Secret
provisioning is deterministic PowerShell/`gh` work; it does not require Codex
and values are never placed in the Codex prompt.

Secret-name inventory and missing-secret writes run inside one temporary,
repository-scoped lock represented by the label
`meandai:secret-reconciliation-lock`. The launcher creates that label with a
unique session nonce, verifies the same nonce before removing it, and fails
closed if the label already exists or its ownership changes. This uses the
local authenticated `gh` label authority already required for adoption; it does
not add updater-PAT permissions. If a process crash leaves a stale lock, first
confirm that no quick-adoption launcher is running for the repository, inspect
the label description, then delete only that label through the repository UI or
`gh label delete meandai:secret-reconciliation-lock --repo <owner>/<repo> --yes`
before rerunning. Never remove a lock owned by an active or uncertain session.

When `MEANDAI_PROTOCOL_TOKEN` exists but its local file is absent, the launcher
does not and cannot recover the stored value. It uses the authenticated local
`gh` identity only to retrieve the exact tagged workflow and clone the exact
protocol commit required by semantic adoption. If that identity cannot read the
private protocol repository, the launcher stops with a source-access error.

## Quick command

Download the single
[`Invoke-MeAndAIQuickAdoption.ps1` release asset](https://github.com/hasanmanzak/meAndAI/releases/download/v0.9.2/Invoke-MeAndAIQuickAdoption.ps1)
from the exact immutable `v0.9.2` GitHub Release with an authenticated browser.
Save the reusable file outside the consumer repository, such as in
`$HOME\Downloads`. This keeps an existing target clean and makes the reviewed
launcher reusable across consumers pinned to the same release.

Open PowerShell in the target directory and run exactly one script invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath .
```

If the browser saved the asset elsewhere, change only the `-File` path. The
launcher itself verifies that `v0.9.2` is an exact published immutable release
before it downloads canonical source; it never executes a moving `main` file.

## Target behavior and options

For an existing connected repository, no owner or name is needed. The launcher
validates the GitHub `origin`, preserves application content, commits only
`.github/workflows/meandai-protocol-update.yml`, and pushes the default branch.

For a directory without a local repository or `origin`, it initializes `main`,
uses the active `gh` owner and directory name, and first resolves that exact
GitHub identity. If the repository already exists and is empty, the launcher
connects it and applies the same repository-secret preservation rules as an
already connected target. If it does not exist, the launcher creates a private
repository by default and both local token files remain mandatory before that
creation. An existing non-empty repository must be cloned or reconciled
manually. Unrelated local files remain untracked and are not published. To
override the inferred identity or visibility:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -Owner 'my-owner' -RepositoryName 'my-repo' -Visibility private
```

Running the command is explicit authorization to read the applicable fixed
token files and transmit a value only when its mapped repository secret is
missing. Existing mapped secret names are preserved without overwrite. The
values are not command-line arguments and are not printed.

If remote creation succeeds but a later credential, commit, workflow, or local
Codex gate blocks, do not delete or reset anything. Resolve the reported
condition and rerun. Exact seed and completed-adoption states are idempotent.

## Default execution order

Only after both repository secret names are present—either preserved or
created—and the seed commit is pushed, the launcher:

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
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -SkipLifecycleDispatch
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -SkipLocalCodex
```

`-SkipLifecycleDispatch` also skips local Codex because no draft is expected.
`-SkipCodexDelegation` remains an alias for `-SkipLocalCodex` for v0.6.0 caller
compatibility. The workflow wait is bounded by `-WorkflowTimeoutMinutes 15`
(allowed range: 1 through 60). Local authentication and execution are bounded
by `-CodexTimeoutMinutes 30` (allowed range: 1 through 120).
`-CodexTimeoutSeconds` is an optional finer-grained override; zero preserves
the minute setting. If a draft already
lacks the manifest when inspected, the launcher does not rerun Codex or mark
the draft ready; the maintainer must validate that prior change manually.

## Codex prompt

The displayed prompt is not the adoption entry point. Run the
[quick command](#quick-command) from the original target directory; the parent
PowerShell launcher starts and owns the end-to-end operation. By the time it
supplies this prompt to Codex, the launcher has already:

1. created or validated the GitHub repository;
2. reconciled both repository Actions secret names, reading an applicable
   local credential file only when its mapped secret was missing;
3. published the seed, completed the lifecycle run, resolved its deterministic
   draft, and reconciled the adoption labels and issue; and
4. cloned the exact draft head into a separate OS temporary directory for the
   Codex workspace.

For a new repository, place both credential files in the original target
directory before running the quick command. For an existing repository, each
file is required only when its mapped secret is missing, as described under
[Prerequisites](#prerequisites). The launcher excludes these files from Git and
never commits, pushes, or deletes them. They are never copied into the isolated
clone. Therefore, "intentionally absent" below refers only to the temporary
Codex workspace; it does not say that the files were absent from, or never
required in, the original target.

The parent launcher retains network access and owns `gh`, GitHub API, and
remote Git operations before and after the Codex phase. Only commands spawned
inside the Codex session have network access disabled. The configured model
service remains reachable by Codex itself, so this is network-restricted local
orchestration rather than offline inference. After Codex returns, the launcher
validates the result, creates the completion commit, lease-pushes the draft,
and marks the pull request ready; the maintainer still owns merge.

The launcher supplies its scoped prompt over standard input. Its essential
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

Secret provisioning was reconciled by the parent launcher before this Codex
step. FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and MEANDAI_RO_FG_PAT.txt maps to
MEANDAI_PROTOCOL_TOKEN. When a mapped secret was missing, its source file was
read only from the maintainer's original target directory. Those files were
never committed or copied into the isolated clone, so they are intentionally
absent from this Codex workspace. Do not search for, request, print, recreate,
or modify credential values or repository secrets.

The parent launcher owns GitHub and remote Git operations before and after this
Codex step. Network access is disabled only for commands spawned during this
step. Within this clone, do not invoke gh, GitHub APIs, remote Git operations,
or another external service. Do not change the pinned protocol or lifecycle
workflow. Do not commit, push, approve, mark ready, merge, close, or delete;
the launcher owns GitHub records and publication and the maintainer owns merge.
Keep review bounded and report the exact blocker if project facts or required
evidence are unavailable.
```

For lifecycle states, collision semantics, and the manual alternative, see the
[complete adoption guide](adoption.md).
