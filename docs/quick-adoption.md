# Quick Adoption

This guide installs the meAndAI AI-capabilities lifecycle through one
maintainer-downloaded thin PowerShell launcher. It supports both a clean
existing GitHub repository and a local directory that has no repository or
`origin` yet.

The immutable runtime release contains exactly two release assets: the small
`Invoke-MeAndAIQuickAdoption.ps1` launcher that the maintainer downloads and one
internal `MeAndAI.QuickAdoption.Bundle.zip` that the launcher retrieves. The
bundle is built deterministically from an exact commit's tracked Git blobs; it
is release output and is not committed. The launcher verifies its own immutable
runtime release, bundle, manifest, and every module payload before importing
code outside the consumer repository. It then creates the repository when
needed, provisions credentials, publishes the exact seed, dispatches the
lifecycle workflow, and waits for its bounded result. If that run creates a
semantic adoption draft, the launcher uses local Codex CLI synchronously in a
temporary clone, validates and pushes
the result, and marks the pull request ready. The launcher, not Codex,
reconciles the common labels and adoption issue. It never approves or merges;
the maintainer performs the final review and merge.

The launcher carries its canonical `RuntimeReleaseTag` and queries that exact
`releases/tags/<tag>` endpoint with
`X-GitHub-Api-Version: 2026-03-10` and accepts only a published immutable
GitHub Release whose tag, commit, asset digest, and publication metadata match
the runtime. `-ProtocolTag` is independent: it selects the compatible protocol
release to install in the consumer and does not redirect runtime download to a
different release. These supply-chain checks remain inside the reviewed thin
launcher rather than in a copy-pasted command stack.

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
| `MEANDAI_RO_FG_PAT.txt` | Read-only meAndAI fine-grained PAT | Required for a new repository or when `MEANDAI_PROTOCOL_TOKEN` is absent; optional when that secret exists; also used transiently for exact runtime and protocol source retrieval when present | `MEANDAI_PROTOCOL_TOKEN` |

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

Each present token input must be the exact canonical root filename and one
regular non-link, non-reparse file; that identity is checked again immediately
before and after every read. For the duration of the launcher, every Git
process receives an invocation-scoped empty `core.hooksPath` through process
configuration and the prior environment is restored in `finally`. Consumer or
global Git hooks therefore cannot run while the launcher may still have access
to plaintext token inputs.

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

When `MEANDAI_RO_FG_PAT.txt` is present, the thin launcher revalidates it and
temporarily exposes its value only as process `GH_TOKEN` while verifying and
downloading the exact immutable runtime bundle. It restores the caller's prior
GitHub environment and clears the in-memory token before imported module code
runs. The value is not put in argv, output, bundle content, or consumer files.
The verified module separately revalidates and reads the same canonical file
for exact target-policy and protocol-source retrieval and, when that repository
Actions secret is missing, for creation of `MEANDAI_PROTOCOL_TOKEN`.

When `MEANDAI_PROTOCOL_TOKEN` exists but its local source file is absent, the
launcher does not and cannot recover the stored value. Both the thin runtime
bootstrap and the verified module instead use the authenticated local `gh`
identity for their respective exact runtime-release, tagged-workflow, and
protocol-commit reads. If that identity cannot read a private meAndAI
repository, the launcher stops with a source-access error. The local Actions
secret remains untouched and is not a credential source for the local process.

## Quick command

After GitHub marks `v0.13.5` as an immutable release, download only the thin
[`Invoke-MeAndAIQuickAdoption.ps1` release asset](https://github.com/hasanmanzak/meAndAI/releases/download/v0.13.5/Invoke-MeAndAIQuickAdoption.ps1)
from that exact release with an authenticated browser. Until that condition is
true, use the latest release that GitHub already marks immutable rather than a
candidate tag or a moving branch.
Do not separately download or unpack the module bundle; the launcher retrieves
and verifies the release's one internal bundle asset itself. Save the reusable
launcher outside the consumer repository, such as in `$HOME\Downloads`. This
keeps an existing target clean and makes the reviewed runtime reusable across
consumers that select any compatible `-ProtocolTag`.

Open PowerShell in the target directory and run exactly one script invocation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath .
```

If the browser saved the asset elsewhere, change only the `-File` path. The
launcher itself verifies that its runtime `v0.13.5` is an exact published
immutable release, downloads the unique bundle, validates its archive manifest
and every payload digest, and imports it only from an owned temporary directory
outside the consumer. It never executes a moving `main` file. Omitting
`-ProtocolTag` selects the runtime-compatible default `v0.13.5`; explicitly
choosing another compatible target does not change the runtime bundle source.

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
manually. Empty means that the remote advertises no branch, tag, or other ref;
a tag-only repository is not empty. The launcher repeats that all-ref check
before secret reconciliation, seed writing, and seed push. A first-push race
must leave only the exact published default ref or the launcher removes its own
ref with an exact lease and stops. Unrelated local files remain untracked and
are not published. To
override the inferred identity or visibility:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -Owner 'my-owner' -RepositoryName 'my-repo' -Visibility private
```

Running the command is explicit authorization to read the applicable fixed
token files and transmit a value only when its mapped repository secret is
missing. Existing mapped secret names are preserved without overwrite. The
values are not command-line arguments and are not printed.

### Initial-adoption strategy

Before repository initialization, remote creation, secret writes, or seed
publication, the launcher verifies the authenticated `gh` identity and loads
the pure strategy/classification policy from its verified immutable runtime
release's capabilities contract module. The standalone launcher and workflow adapter do
not maintain competing policy copies; each keeps only its own Git/GitHub
evidence and mutation-boundary checks. The launcher then performs one bounded
path assessment of the exact committed consumer tree. `-AdoptionStrategy Auto`
is the default. It resolves to `FreshAdoption` only when no declared
protocol/governance surface exists. A collision with a generic target such as a
pull-request template is still routed to semantic review, but does not falsely
assert that the consumer already has another protocol.

Reserved state at `.ai/protocol`, anywhere below `.ai/protocol/`, or in
`.ai/meandai-update-state.json` is protocol evidence even when incomplete.
Path-specific GitHub Copilot instructions below `.github/instructions/` are
also active protocol evidence alongside the declared Cursor and Windsurf rule
roots.
Exact casing is mandatory for every managed path and ancestor. Existing broad
feature, decision, finding, idea, release, or product-documentation paths may
trigger the strategy gate without becoming writable: they remain evidence-only
unless they are in the declared safe legacy-governance allowlist.

When evidence exists, an interactive `Auto` run displays the exact detected
paths and asks the maintainer to choose one policy. A redirected or
`-NonInteractive` run fails closed instead; automation must pass an explicit
choice:

```powershell
# Preserve valid repository semantics, then retire the old protocol authority.
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -AdoptionStrategy FullMigration -NonInteractive

# Reconcile selected structures under an explicit ownership/precedence decision.
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -AdoptionStrategy HybridReconciliation -NonInteractive
```

`CleanStart` imports no legacy governance semantics. It is intentionally
separate from full migration and requires a second acknowledgement. In an
interactive run, type the exact confirmation requested by the launcher. In
automation, pass both controls:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -AdoptionStrategy CleanStart -AcknowledgeProtocolRecordLoss -NonInteractive
```

`CleanStart` can delete only exact detected governance-record paths. Every
completion mode is mechanically restricted to required protocol targets,
declared governance/memory records, and `tests/meandai-adoption/`; it cannot
add, modify, type-change, or delete application source, assets, runtime
configuration, product tests, or product documentation. It may discard exact
legacy records below the reserved `.ai/protocol/` root, but stops before
mutation when a detected ambiguous document cannot be proven governance-only.
`FreshAdoption` contradicts detected evidence and is rejected. `Abort` exits
before local Git or GitHub adoption mutation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke-MeAndAIQuickAdoption.ps1" -TargetPath . -AdoptionStrategy Abort
```

The inverse mismatch also fails closed: `FullMigration`,
`HybridReconciliation`, and `CleanStart` require at least one detected protocol
surface. A protocol-free repository uses `FreshAdoption`; a generic target
collision may still require semantic review but does not justify a fictional
migration or record-loss choice.

A proposal created by a legacy manifest/marker schema can recover only the
policy-free meaning already encoded in that immutable record. If such a
proposal has collisions that now require an explicit migration strategy,
close the legacy draft and rerun the assessment; the launcher does not
retroactively label it with a maintainer choice it never recorded.

Detected governance files must already belong to committed repository history;
otherwise they cannot appear in the isolated proposal clone and the launcher
asks the maintainer to commit/reconcile the repository first. The launcher
builds one bounded graph from generic instruction roots, their local references,
and the versioned compatibility seed. The chosen strategy and graph-derived
surface projection are carried through workflow dispatch, transient manifest,
proposal marker, adoption issue, local Codex prompt, reruns, and completion.
The AI actor cannot change the choice. A newly discovered authority or required
deletion outside the existing mutation envelope blocks for a new maintainer
assessment.

The graph is tied to the exact committed base by its digest, counts, limits,
and required projections. Every mutation boundary independently rebuilds that
source evidence; completion also builds the candidate final graph. Missing,
ambiguous, escaping, unsupported, over-budget, or drifted references block
before proposal mutation or readiness. A graph node is evidence, not write
authority: product/application files, source evidence, binaries, special Git
modes, and unknown formats remain protected. Successful completion removes the
transient manifest and leaves no graph ledger or legacy compatibility router.

A target with no committed `HEAD` may contain only `FG_PAT.txt`,
`MEANDAI_RO_FG_PAT.txt`, and the exact canonical seed workflow. Commit
application and governance files before adoption so the isolated clone cannot
silently omit them. A recognizable but byte-modified current seed is rejected
before repository creation or remote attachment; an already connected exact
older managed seed remains eligible for its bounded same-major update route.

These choices govern only initial adoption. A completed meAndAI consumer keeps
the existing current/update route and rejects explicit initial-strategy
arguments. Catalog-driven transition migrations remain a different mechanism
for already adopted consumers.

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
9. Requires an unchanged Git head, live repository/default-branch identity,
   manifest removal, a valid non-empty diff, absent credential files, and an
   unchanged live remote branch; it repeats the base check before publication
   and readiness. Every created commit is re-read from Git and the index and
   worktree must be clean before any push.
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
  installed seed, reconciles only missing secrets, and runs the explicitly
  requested immutable target updater against an isolated clone of the captured
  default-branch head. Before current-update planning, that exact target updater
  finalizes only unambiguous retained merged branches left by an older updater;
  malformed or reused ownership still fails closed. It then creates one atomic
  managed draft with the target pin, changed updater assets, required catalog
  migrations, and ledger. The maintainer checkout and default branch are
  unchanged, and no installed workflow or Codex adoption flow is started.
- A partial or drifted footprint, a newer installed tag, or a major-version
  boundary fails before secret or repository mutation. The launcher never
  downgrades and never overwrites an installed updater seed.

Target-bound recovery retries only explicitly declared idempotent GitHub API
GET reads, at most three total attempts, for transient transport failures,
HTTP 408/429, and 5xx responses. Permanent/semantic failures and all writes
remain single-attempt. Managed issue, comment, patch, and pull-request bodies
cross the Windows PowerShell 5.1 native boundary through owner-scoped UTF-8
without-BOM files rather than native argv. The updater may repair the one exact
historical quote-stripped schema-2 issue only after its complete generated
identity, trusted actor, and absence of duplicate issue, branch, pull request,
or backlink are proved; malformed or changed near matches still fail closed.

### Transition migrations

Do not choose or run a migration mode based on the consumer's installed tag.
Migration applicability comes from the target release's immutable, append-only
catalog, the consumer ledger, and exact repository bytes.

For a consumer whose installed updater already supports that contract, the
ordinary managed update draft contains the target gitlink, target-different
updater assets, exact catalog-derived consumer changes, and resulting ledger.
Only one maintainer merge is required.

For a consumer whose immutable updater predates the engine, rerun the latest
quick launcher with the requested target tag. It verifies that immutable
release, clones the exact consumer base and target source into a temporary
workspace, and invokes the target updater locally. The resulting single
schema-2 draft crosses the capability boundary atomically; no knowingly red
core-only merge or second reconciliation merge is required. Review and merge
that draft normally. Its installed workflow handles later compatible updates
through the ordinary scheduled or manual one-draft path. Do not hand-edit the
ledger or replace managed updater files in the maintainer checkout.

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
installed workflow does not subscribe to `push`, because a normal merge already
emits both PR and default-push events and self-created branches can displace the
pending exact PR run. The schedule and ordinary manual dispatch run bounded
recovery instead. They repair only an exact legacy installing update, then use
the normal finalizer. For a missed or failed recovery, run the same route
explicitly after confirming the PR is merged:

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

After adoption or update finalization, the installed workflow independently
discovers release-declared semantic capabilities. An already-current launcher
run dispatches that workflow instead of treating the current pin as proof that
semantic capability assessment is complete. The first capability is
`test-architecture`: tests remain feature-traceable but canonical suites and
fixtures are reviewed into capability ownership with deterministic recursive
discovery and separate suite processes. Exact terminal ledger state is a
no-op; an unresolved batch reuses one canonical issue, branch, transient
manifest, and draft review. The workflow may create that handoff, but only the
consumer's reviewed proposal may change semantic files or record terminal
evidence.

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
