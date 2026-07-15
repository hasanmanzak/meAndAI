# Quick Adoption

This guide installs the one-file seed for the meAndAI AI-capabilities
lifecycle. It covers both a clean existing GitHub repository and a local
directory that has no repository or `origin` yet.

The launcher configures credentials before publishing the seed, dispatches the lifecycle workflow, waits for that bounded run, and asks Codex Cloud to complete the generated draft through a scoped `@codex` comment. It never approves or merges the adoption pull request.

## Prerequisites

- PowerShell 5.1 or newer, `git`, and GitHub CLI (`gh`).
- `gh auth status` succeeds for an account allowed to create the target
  repository when needed and to set its Actions secrets.
- To leave only final review and merge to the maintainer, the consumer must be
  connected to [Codex Cloud for GitHub](https://learn.chatgpt.com/docs/third-party/github.md)
  with permission to work on pull-request branches. Without that setup, use
  `-SkipCodexDelegation` and hand the prompt below to Codex manually.
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
consumer repository exists may need that repository added to its grant after
the launcher's first attempt; update the grant and rerun the same command.

Do not commit either token file. The launcher adds both names to
`.git/info/exclude`, blocks tracked or historically committed copies, transfers
their values only to the two named repository secrets, and leaves the local
files in place.

## Quick command

Open PowerShell in the target directory and paste this single line. It
downloads the launcher from the exact `v0.6.0` tag into the OS temp directory
and runs it; it does not execute a moving `main` file.

```powershell
$p=Join-Path ([IO.Path]::GetTempPath()) 'Invoke-MeAndAIQuickAdoption-v0.6.0.ps1'; gh api -H 'Accept: application/vnd.github.raw+json' 'repos/hasanmanzak/meAndAI/contents/scripts/Invoke-MeAndAIQuickAdoption.ps1?ref=v0.6.0' | Set-Content -LiteralPath $p -Encoding UTF8; & $p -TargetPath .
```

The same command in a more readable form is:

```powershell
$launcher = Join-Path $env:TEMP 'Invoke-MeAndAIQuickAdoption-v0.6.0.ps1'
gh api -H 'Accept: application/vnd.github.raw+json' 'repos/hasanmanzak/meAndAI/contents/scripts/Invoke-MeAndAIQuickAdoption.ps1?ref=v0.6.0' | Set-Content -LiteralPath $launcher -Encoding UTF8
& $launcher -TargetPath .
```

For an existing connected repository, no owner or name is needed. The launcher
validates the GitHub `origin`, preserves existing application content, commits
only `.github/workflows/meandai-protocol-update.yml`, and pushes the default
branch.

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

If remote creation succeeds but a later credential, commit, or push gate
blocks, do not delete or reset anything. Resolve the reported condition and
rerun. An exact installed seed is idempotent: secrets are reconciled without a
duplicate commit, and the fixed delegation marker prevents a duplicate Codex
Cloud task.

## What the default command does next

Only after both secrets are stored and the seed commit is pushed, the launcher:

1. Dispatches **meAndAI AI capabilities lifecycle** on the default branch.
2. Waits up to 15 minutes for that exact commit's run and fails if its
   conclusion is not successful.
3. Resolves the single deterministic adoption draft.
4. Posts the scoped `@codex` adoption prompt once. Codex Cloud then works on
   that draft branch, runs the protocol gates, pushes its changes, and is asked
   to mark the pull request ready without merging it.

An empty consumer receives a deterministic bootstrap proposal. A populated
consumer with path collisions receives an
`.ai/adoption/meandai-capabilities.json` review manifest instead of overwritten
files. In both cases, semantic adoption remains a maintainer-and-agent review
operation.

GitHub does not expose a stable shell completion signal for the subsequent
Codex Cloud task. The launcher therefore stops after the durable delegation
comment. The maintainer waits for Codex's result, reviews its evidence and
applicable checks, and performs the final merge. If Codex cannot mark the draft
ready with its configured permissions, the maintainer must also perform that
single readiness transition.

For troubleshooting or a deliberately manual handoff, skip either later phase:

```powershell
& $launcher -TargetPath . -SkipLifecycleDispatch
& $launcher -TargetPath . -SkipCodexDelegation
```

`-SkipLifecycleDispatch` also skips Codex delegation because no adoption draft
is expected yet. The default workflow wait is bounded by
`-WorkflowTimeoutMinutes 15` (allowed range: 1 through 60).

## Codex prompt

The launcher sends the compact equivalent of this prompt through the generated
draft's `@codex` comment. Use this copy-ready version when delegation is manual:

```text
Complete this consumer repository's meAndAI AI-capabilities adoption.

Read AGENTS.md, the pinned .ai/protocol/PROTOCOL.md, and
.ai/adoption/meandai-capabilities.json before changing anything. Treat the
manifest as a transient handoff: preserve existing project semantics, resolve
each listed collision deliberately, create or reconcile the protocol-required
project-local memory, feature/decision documentation, tests, issue/PR links,
and Agile labels, then remove the manifest when every item is resolved.

Do not invent project facts. Do not overwrite consumer-owned files merely to
match a template. Decompose material work, satisfy DoR before implementation,
self-review each completed slice, run the relevant tests, and perform the
protocol's bounded final scan without entering an unbounded validation loop.

Secret provisioning is already a separate precondition. Do not print or commit
credentials. If launcher-level secret reconciliation is explicitly required,
the user authorizes reading only FG_PAT.txt and MEANDAI_RO_FG_PAT.txt and
transmitting their contents only to this repository as, respectively,
MEANDAI_UPDATER_TOKEN and MEANDAI_PROTOCOL_TOKEN.

Keep the pull request draft until documentation, tests, links, memory, and all
applicable review gates are complete. Report remaining blockers; do not bypass
branch protection or merge requirements.
```

For lifecycle states, collision semantics, and the manual alternative, see the
[complete adoption guide](adoption.md).
