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

- PowerShell 5.1 or newer, `git`, and GitHub CLI (`gh`) version `2.82.1` or
  newer. The launcher validates this minimum immediately after command
  discovery and blocks before authentication or any local or remote mutation
  when the version is older or cannot be parsed unambiguously.
- `gh auth status` succeeds for an account allowed to create the target
  repository when needed, set its Actions secrets, and maintain its adoption
  labels and issue. When the existing protocol secret is reused without its
  local source file, that account must also be able to read
  `hasanmanzak/meAndAI`.
- [Local Codex CLI](https://github.com/openai/codex#readme) is installed and
  authenticated (`codex login status`). If
  `codex` is absent but `npx` is available, the launcher uses the pinned
  temporary package `@openai/codex@0.144.4` without a global install.
- On Windows, Codex must have a usable native Windows sandbox. The launcher
  reads only the active `[windows].sandbox` selection that its isolated
  `--ignore-user-config` execution would otherwise omit, then runs a token-free
  workspace-write probe before any model call. It prefers `elevated`, falls
  back to `unelevated` only when the former fails the probe, and blocks before
  semantic execution if neither mode can create, verify, and remove the probe
  file. It never uses `danger-full-access`.
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
[`Invoke-MeAndAIQuickAdoption.ps1` release asset](https://github.com/hasanmanzak/meAndAI/releases/download/v0.10.4/Invoke-MeAndAIQuickAdoption.ps1)
from the exact immutable `v0.10.4` GitHub Release with an authenticated browser.
Save the reusable file outside the consumer repository, such as in
`$HOME\Downloads`. This keeps an existing target clean and makes the reviewed
launcher reusable across consumers pinned to the same release.

Open PowerShell in the target directory and run exactly one script invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath .
```

If the browser saved the asset elsewhere, change only the `-File` path. The
launcher itself verifies that `v0.10.4` is an exact published immutable release
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

If `v0.9.2` already created the deterministic draft but stopped with
`BUG-0006`, download the corrected `v0.9.7` launcher asset and retain the
proposal's original protocol target while resuming:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -ProtocolTag v0.9.2
```

Do not retarget the retained draft to `v0.9.7`. Complete and merge its original
adoption first; the installed consumer updater can then propose the ordinary
reviewed `v0.9.7` upgrade.

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
7. On Windows, validates the selected native sandbox with a token-free
   workspace-write probe and passes only the verified mode to the isolated
   semantic run.
8. Runs [`codex exec`](https://learn.chatgpt.com/docs/non-interactive-mode)
   synchronously with an ephemeral `workspace-write` session, a 30-minute
   default process limit, spawned-command network access disabled, and its
   JSONL activity stream mapped to safe `Codex | ...` console lines.
9. Requires an unchanged Git head, manifest removal, a valid non-empty diff,
   absent credential files, and an unchanged live remote branch.
10. Creates the adoption completion commit, pushes it with an exact
   `--force-with-lease`, binds the canonical issue through exactly one
   non-closing `Tracking issue: #N` body line, and marks the pull request ready
   without merging it.

An empty consumer receives a deterministic bootstrap proposal. A populated
consumer with target collisions receives
`.ai/adoption/meandai-capabilities.json` instead of overwritten files. Local
Codex uses the exact protocol source snapshot for semantic reconciliation.
For a genuinely empty consumer, missing product purpose, runtime/stack,
architecture, build command, and product test command are recorded as
`Not yet established`. Their absence is not a blocker to protocol adoption,
and Codex must not invent values; adoption validation remains structural until
the project establishes those facts.

The resulting consumer records and structural tests treat the `.ai/protocol`
gitlink plus the `VERSION` inside that exact checkout as the sole current pin
authority. They link to or read those sources dynamically and do not copy the
adoption tag or commit as a live memory, decision, documentation, or test
constant. A dated adoption entry may retain the exact initial values as
historical evidence. Initial adoption also writes
`.ai/meandai-update-state.json` with the target release's complete migration
catalog recorded as satisfied, so a new consumer does not replay historical
transitions.

### Re-running the launcher

The latest launcher classifies a connected non-empty repository before secret
or repository mutation. A repository with no adoption footprint follows the
initial-adoption flow. A complete installation must prove the exact gitlink,
canonical `.gitmodules`, absence of the transient manifest, one installed
bootstrap tag whose immutable release maps to that gitlink, and workflow/module/
adapter blobs identical to that installed release.

- If the installed and requested tags are equal, the launcher preserves both
  existing secret names, creates only missing secrets, and exits successfully
  without workflow dispatch, Git publication, pull-request resolution, or
  Codex.
- If the installed tag is older in the same major, the launcher preserves the
  installed seed, reconciles only missing secrets, dispatches that installed
  updater with correlation evidence, waits for its result, and never enters
  adoption/Codex handling. An engine-era updater includes required catalog
  migrations in the managed update draft. A pre-engine updater first installs
  the newer lifecycle; after that merge, the new workflow automatically opens
  one same-target reconciliation draft if its catalog remains unsatisfied.
- A partial or drifted footprint, a newer installed tag, or a major-version
  boundary fails before secret or repository mutation. The launcher never
  downgrades and never overwrites an installed updater seed.

### Transition migrations

Do not choose or run a migration mode based on the consumer's installed tag.
Migration applicability comes from the target release's immutable, append-only
catalog, the consumer ledger, and exact repository bytes.

For a consumer whose installed updater already supports that contract, the
ordinary managed update draft contains the target gitlink, target-different
updater assets, exact catalog-derived consumer changes, and resulting ledger.
Only one maintainer merge is required.

For a consumer whose immutable updater predates the engine, the first managed
draft can contain only the core update that old code knows how to prove. Merge
it normally. The newly installed workflow then automatically creates one
same-target reconciliation draft and tracking issue. Review and merge that
draft; finalization deletes its exact owned branch and closes its issue. Later
compatible transitions use the one-draft path. If the follow-up event was
suppressed, run the installed workflow manually; do not add a launcher flag or
hand-edit the ledger.

Exact already-satisfied state is idempotent. Customized, partial, mixed,
drifted, linked, or otherwise ambiguous state fails closed before remote
mutation and requires explicit maintainer review.

An in-flight seed-only adoption is still initial adoption and can resume only
with its original protocol tag; a different requested seed remains a collision.

The CLI process reuses the maintainer's saved local Codex authentication. No
consumer repository connection to hosted GitHub-agent execution is required.
Local orchestration is not offline inference: the CLI sends its prompt and
relevant repository context to its configured model service.

## After maintainer merge

The consumer workflow, not the launcher or Codex, owns managed post-merge
cleanup. A qualifying same-repository `pull_request.closed` event invokes the
installed finalizer. It proves that the merge is still contained in the current
default branch, the marker and tracking issue are exact, no open pull request
reuses the branch, and the live head still matches. It then lease-deletes only
that deterministic branch, records one issue evidence marker, removes transient
meAndAI status labels, and closes the issue as completed.

GitHub does not replay an event that occurred while a route was absent, and a
merge performed with `GITHUB_TOKEN` may not create another workflow event. The
installed workflow therefore also runs bounded recovery on an installing
default-branch push, the schedule, and ordinary manual dispatch. It repairs only
an exact legacy installing update, then uses the normal finalizer. For a missed
or failed recovery, run the same route explicitly after confirming the PR is
merged:

```powershell
gh workflow run meandai-protocol-update.yml --repo <owner>/<repo> -f finalize_pull_request=<merged-pr-number>
```

The recovery routes are idempotent when the exact branch is already absent and
the issue already contains the matching finalization evidence. It fails closed
for a moved/reused branch, a merge no longer on the default branch, a malformed
ambiguous tracking line, or an issue closed without that evidence. Do not use
`Closes`, `Fixes`, or `Resolves` in a managed adoption/update PR; those keywords
would close the issue before branch convergence. Older consumer pins gain the
behavior when their reviewed update installs the current workflow and adapter.
If that immutable installing updater predates transition migrations, the new
workflow performs the generic same-target reconciliation handoff described
above; no source-version-specific bridge is selected.

## Stopping and resuming safely

Pressing `Ctrl+C` during local Codex work stops the launcher. The launcher owns
the Codex process tree, terminates it before process disposal, and then removes
only its unpredictable `meandai-local-adoption-*` temporary root. Because the
validated completion commit has not yet been pushed, the consumer checkout and
live proposal head remain unchanged. The deterministic seed, repository
secrets, lifecycle draft, labels, and adoption issue may already exist; they
are intentional, idempotent state. Resolve any reported prerequisite and run
the same command again.

If interruption occurs after the exact completion push but before the adoption
marker is finalized, the persisted `Publishing` intent binds the previous and
planned heads. A rerun either restores the still-live previous proposal or
validates and finalizes the planned head; any unrelated head blocks.

Closing the terminal forcibly, terminating PowerShell, or losing host power can
prevent the launcher's `finally` cleanup. On Windows, kill-on-close containment
still terminates the contained Codex process tree when the launcher handle
closes, but an unused directory under `%TEMP%\meandai-local-adoption-*` may
remain. First confirm no launcher or Codex process is using it, then remove only
that verified stale directory manually. Do not delete an ambiguous temporary
root. This residue does not corrupt the target repository.

For troubleshooting or a deliberately manual handoff:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -SkipLifecycleDispatch
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -SkipLocalCodex
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -NoProgress
```

`-SkipLifecycleDispatch` also skips local Codex because no draft is expected.
`-SkipCodexDelegation` remains an alias for `-SkipLocalCodex` for v0.6.0 caller
compatibility. The workflow wait is bounded by `-WorkflowTimeoutMinutes 15`
(allowed range: 1 through 60). Local authentication and execution are bounded
by `-CodexTimeoutMinutes 30` (allowed range: 1 through 120).
`-CodexTimeoutSeconds` is an optional finer-grained override; zero preserves
the minute setting. By default, compact normal console lines report actual
launcher phases, safe live Codex activity, and a bounded elapsed heartbeat when
the CLI emits no new event. No host-managed progress overlay or invented Codex
completion percentage is used. `-NoProgress` suppresses those lines without
changing behavior. If a draft already
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
Treat the .ai/protocol gitlink and its VERSION as the sole current protocol-pin
authority. Consumer-owned instructions, memory, decisions, features, indexes,
and tests must resolve that identity dynamically; do not embed the adoption tag
or commit as a live current-pin fact. Exact values may appear only in a dated
historical adoption record that does not claim current authority.
For an empty consumer, record unavailable product purpose, runtime/stack,
architecture, build command, and product test command as Not yet established;
their absence is not a blocker to protocol adoption. Use structural checks and
do not invent product behavior.
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
Keep review bounded and report the exact blocker if required non-product facts
or evidence are unavailable.
```

For lifecycle states, collision semantics, and the manual alternative, see the
[complete adoption guide](adoption.md).
