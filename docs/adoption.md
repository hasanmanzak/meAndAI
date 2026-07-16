# Adopting the Common Protocol

The recommended layout keeps the shared protocol immutable and the consuming
project's memory and documentation under that project's ownership.

```text
consumer-project/
|-- AGENTS.md
|-- .ai/
|   |-- memory/
|   `-- protocol/       # Git submodule pinned to a meAndAI tag
|-- docs/
|   |-- decisions/
|   `-- features/
`-- ...
```

This boundary is defined by
[DEC-0001](decisions/DEC-0001-portable-protocol-reference.md) and
[DEC-0002](decisions/DEC-0002-project-local-memory.md).

For the shortest supported setup, follow the
[quick adoption guide](quick-adoption.md). It creates or validates the GitHub
repository, provisions the required secrets, publishes only the lifecycle
seed, dispatches its bounded run, and completes any resulting semantic draft
through local Codex CLI without merging it. In an existing repository it
preserves canonical repository Actions secret names already present and creates
only missing mappings; GitHub does not expose their values for validation. If
the protocol secret exists but its local source file does not, the launcher
uses the authenticated local `gh` identity for exact tagged-source retrieval.
Secret inventory and writes are serialized by the temporary repository label
`meandai:secret-reconciliation-lock`, owned by a unique launcher nonce. An
existing, stale, changed, or contended lock blocks. After confirming that no
launcher session is active, a maintainer may inspect and remove only that label
through GitHub or `gh label delete ... --yes`, then rerun. The lock uses the
local `gh` label authority already required by quick adoption and adds no PAT
permission.

## Workflow-only AI capabilities lifecycle

For a new submodule consumer on `v0.8.5`, the only repository file required
before the lifecycle runs is the exact canonical
[AI capabilities lifecycle workflow](https://github.com/hasanmanzak/meAndAI/blob/v0.8.5/templates/project/.github/workflows/meandai-protocol-update.yml)
at `.github/workflows/meandai-protocol-update.yml`. Configure the two
[credentials](#update-workflow-prerequisites-and-behavior), then use quick
adoption or run the workflow manually. Before checkout, the workflow requires
the exact tag embedded in its reviewed content to have a published immutable
GitHub Release, then checks out that locked tag; it never executes a moving
`main`.

The same operation covers an empty repository, a populated repository, and an
already adopted repository. Classification depends only on collisions with
declared adoption targets; unrelated application files do not prevent the
deterministic path.

| State | Proposal and next owner |
| --- | --- |
| `BootstrapReady` | No target collides. One deterministic draft adds `.gitmodules`, the `.ai/protocol` gitlink, `AGENTS.md`, the memory skeleton, issue/PR templates, local updater scripts, and `.ai/adoption/meandai-capabilities.json`. |
| `AdoptionReviewRequired` | At least one target collides. The draft adds only `.ai/adoption/meandai-capabilities.json`, listing the exact paths that need semantic review. No consumer target is overwritten. |
| `PendingAdoption` | The deterministic branch and one draft already exist. Later runs retain them and create nothing else. |
| `Update` | Adoption is complete, so the reviewed consumer-owned updater performs same-major update discovery and supersession. |
| `BlockedManualReview` | Seed identity, manifest ownership, branch/PR ownership, source, or another prerequisite is ambiguous. The run stops without cleanup or overwrite. |

The workflow does not start an AI agent. It opens a durable, review-only
handoff. In the quick-adoption path, the launcher reconciles the common Agile
labels and one marked adoption issue before invoking local Codex with spawned
network access disabled. In a manual path, the maintainer must create or verify
those GitHub records. The semantic actor must reconcile collisions, create
project-owned feature and decision records, tailor local memory, add and run
project tests, repair links, and remove the manifest before marking the pull
request ready or merging it. A full `BootstrapReady` proposal still contains the manifest
because deterministic file installation is not evidence that the
project-specific work is complete.

`MeAndAI.CapabilitiesBootstrap.psm1` and
`Invoke-MeAndAICapabilitiesBootstrap.ps1` are source-only launch assets. They
run from the pinned protocol checkout and are not copied to the consumer. Once
the reviewed adoption draft merges, future compatible releases update the
protocol gitlink and the three consumer-owned updater assets through the same
workflow.

## Recommended: pinned Git submodule

From the consuming repository root:

```powershell
$tag = 'v0.8.5'
$release = gh api -H 'Accept: application/vnd.github+json' `
  -H 'X-GitHub-Api-Version: 2026-03-10' `
  "repos/hasanmanzak/meAndAI/releases/tags/$tag" | ConvertFrom-Json
$publishedAt = [DateTimeOffset]::MinValue
if ([string]$release.tag_name -cne $tag -or
    $release.draft -isnot [bool] -or $release.draft -or
    $release.prerelease -isnot [bool] -or $release.prerelease -or
    $release.immutable -isnot [bool] -or -not $release.immutable -or
    -not [DateTimeOffset]::TryParse(
      [string]$release.published_at, [ref]$publishedAt
    )) {
  throw "Protocol release $tag is not published and immutable."
}
git submodule add https://github.com/hasanmanzak/meAndAI.git .ai/protocol
git -C .ai/protocol checkout $tag
git add .gitmodules .ai/protocol
```

Copy or merge the
[submodule root adapter](../templates/project/AGENTS.submodule.md) into the
consuming repository's root `AGENTS.md`. If that file already exists, keep its
project-specific rules and add an explicit instruction to read
`.ai/protocol/PROTOCOL.md`.

Initialize project-local memory beside, never inside, the submodule. The
command below is intentionally fail-closed so an existing project memory is
never replaced:

```powershell
if (Test-Path -LiteralPath .ai/memory) {
    throw 'Project memory already exists; review and merge the templates manually.'
}
Copy-Item -Recurse .ai/protocol/templates/project/.ai/memory .ai/memory
```

Adapt the copied files to the project and commit them in the consuming
repository. Also create project-owned `docs/features` and `docs/decisions`
records as work is defined.

### Consumer tracking assets

Files under a protocol checkout or remote reference do not configure the
consumer repository. The consumer MUST own its memory, issue forms, pull
request template, feature records, and decision records. Materialize the
following source-to-target mapping from the pinned protocol ref:

| Pinned source | Consumer-owned target |
| --- | --- |
| `templates/project/.ai/memory/` | `.ai/memory/` |
| `templates/project/docs/ideas/README.md` | `docs/ideas/README.md` |
| `templates/idea.md` | A new `docs/ideas/IDEA-NNNN-*.md` record |
| `.github/ISSUE_TEMPLATE/{bug,epic,feature,finding,subfeature,task}.yml` | `.github/ISSUE_TEMPLATE/` |
| `.github/PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` |
| `templates/feature/` | A new `docs/features/FEAT-NNNN-*/` record |
| `templates/decision.md` | A new `docs/decisions/DEC-NNNN-*.md` record |

The idea index is an absent-only initial-adoption target. Automation never
creates individual idea records and the compatible updater never manages
consumer-owned `docs/ideas` content. An existing consumer may create the index
and later records from its pinned templates without migrating its updater.

The repository's `.github/ISSUE_TEMPLATE/config.yml` is deliberately excluded:
its contact link describes this protocol repository and follows its current
`main`. Create a consumer-owned configuration whose links point to the
consumer's documentation or to the exact pinned protocol tag.


Submodule consumers also materialize these submodule-only automation assets:

| Pinned source | Consumer-owned target |
| --- | --- |
| `templates/project/.github/workflows/meandai-protocol-update.yml` | `.github/workflows/meandai-protocol-update.yml` |
| `templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1` | `.github/scripts/MeAndAI.ProtocolUpdate.psm1` |
| `templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1` | `.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1` |

Opaque repository-reference consumers MUST NOT copy these three files unchanged.
They use a reviewed provider-specific adapter or the manual update process.
The two AI-capabilities bootstrap files beside these scripts are deliberately
source-only and MUST NOT be materialized in the consumer.
For a submodule consumer, the following command initializes only absent files.
It aborts on every collision instead of overwriting consumer rules:

```powershell
$forms = @('bug.yml', 'epic.yml', 'feature.yml', 'finding.yml', 'subfeature.yml', 'task.yml')
$copies = foreach ($form in $forms) {
    @{
        Source = ".ai/protocol/.github/ISSUE_TEMPLATE/$form"
        Target = ".github/ISSUE_TEMPLATE/$form"
    }
}
$copies += @{
    Source = '.ai/protocol/.github/PULL_REQUEST_TEMPLATE.md'
    Target = '.github/PULL_REQUEST_TEMPLATE.md'
}
$copies += @{
    Source = '.ai/protocol/templates/project/docs/ideas/README.md'
    Target = 'docs/ideas/README.md'
}
$copies += @(
    @{
        Source = '.ai/protocol/templates/project/.github/workflows/meandai-protocol-update.yml'
        Target = '.github/workflows/meandai-protocol-update.yml'
    },
    @{
        Source = '.ai/protocol/templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        Target = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    },
    @{
        Source = '.ai/protocol/templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        Target = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    }
)

$collisions = @($copies.Target | Where-Object { Test-Path -LiteralPath $_ })
if ($collisions.Count -gt 0) {
    throw "Existing consumer files require a manual merge: $($collisions -join ', ')"
}

foreach ($copy in $copies) {
    $parent = Split-Path -Parent $copy.Target
    if ($parent) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }
    Copy-Item -LiteralPath $copy.Source -Destination $copy.Target
}
```

The copy above remains the manual adoption alternative. Starting with `v0.5.0`,
the exact seed workflow can install the absent deterministic assets through the
review-only lifecycle described above. Consumers with copied updater assets
from `v0.2.x` or `v0.3.x` still require the reviewed one-time `v0.4.0`
migration below; their immutable old updater cannot retroactively add its own
self-update behavior.

#### One-time v0.4.0 updater migration

Before migration, merge or manually close every old managed update pull request
and verify that no reserved automation branch remains. Do not let the new PAT
identity adopt an old `github-actions[bot]` proposal.

1. Record the current protocol tag and verify all three consumer updater files
   exactly match that tag's templates. Stop and merge customizations manually if
   any file differs.
2. Create the repository-scoped fine-grained PAT described below and store it as
   `MEANDAI_UPDATER_TOKEN`.
3. Move `.ai/protocol` to `v0.4.0`, replace only the three updater targets with
   their `v0.4.0` templates, and review the pointer and asset diff together.
4. Run the consumer's tests and merge the migration through its normal pull
   request gates. Later compatible updates reconcile these assets themselves.

### Update workflow prerequisites and behavior

The supplied workflow is consumer-owned and supports the recommended
`.ai/protocol` Git submodule only when its gitlink resolves to exactly one
canonical lowercase `vM.m.rev` release tag with no leading zeros, and
`.gitmodules` points to the configured protocol repository. A commit pin
remains valid protocol usage, but it uses the manual reviewed update process
because the generic updater cannot infer its current major unambiguously.
Before enabling the updater:

1. Create a fine-grained PAT named `meAndAI Updater - <repo>`. Select only the
   consumer repository and grant `Contents: read and write`, `Pull requests:
   read and write`, and `Workflows: read and write`; `Metadata: read` is
   implicit. Store it as the repository Actions secret
   `MEANDAI_UPDATER_TOKEN`.
2. While `meAndAI` is private, add a separate Actions secret named
   `MEANDAI_PROTOCOL_TOKEN` with read-only access to this repository. Omit this
   source credential when the configured protocol repository is public; the
   workflow falls back to its read-only `GITHUB_TOKEN` for that checkout.
3. Keep both credentials out of repository files, project memory, workflow output,
   issue bodies, and pull request bodies. Adoption cannot create the secret or
   choose its expiry on the maintainer's behalf.

PAT activity is attributed to its human owner. Do not reuse the updater token
across unrelated repositories or expose it to other workflows. Before rotating
to a token owned by another user, merge or manually close the existing managed
proposal; actor rotation intentionally fails closed. Reconsider a GitHub App
when automation must be independent of a human identity or centrally governed
across multiple owners.

The schedule and manual dispatch provide eventual detection, not an immediate
release notification. The workflow keeps its own `GITHUB_TOKEN` read-only and
uses the fine-grained PAT only for consumer checkout, branch push, and pull
request operations. Consumer Actions policies still govern resulting workflow
runs. See GitHub's documentation for
[`GITHUB_TOKEN`](https://docs.github.com/en/actions/concepts/security/github_token)
and [fine-grained PATs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

Starting with `v0.8.1`, the updater adapter receives the read-only
`MEANDAI_PROTOCOL_TOKEN` separately and uses it for release and tag-commit API
evidence; `MEANDAI_UPDATER_TOKEN` remains limited to consumer reads and writes.
An installed v0.8.0 adapter can propose the normal v0.8.1 update PR. That PR
replaces the workflow and adapter together, so no separate manual workflow seed
is required before the reviewed update merges.

The updater identifies the highest numeric canonical tag in the current major,
requires its exact published immutable-release metadata before target checkout
or mutation, and uses a draft pull request as the review gate. It never
approves or merges a pull request.
Its state rules are:

| Observed state | Result |
| --- | --- |
| Consumer already pins the latest compatible tag | No change |
| One valid managed pull request already targets the latest tag | Keep it; no duplicate pull request |
| An older valid managed pull request is open and a newer compatible tag exists | Create and fully verify the newer replacement first; revalidate both proposals before each cleanup, then close the old PR and delete only its expected branch head; try to reopen the old PR if paired cleanup fails |
| Ownership, canonical marker, planned head, protocol commit, gitlink mode, expected managed path/blob set, base, draft state, author, repository, API head, or remote ref is ambiguous | Stop or compensate without deleting ambiguous work |
| A higher major exists | Report that explicit migration is required; do not propose it automatically |

Managed update pull requests change the `.ai/protocol` gitlink and only the
target-different subset of the three canonical updater assets. Before mutation,
all current copies must equal the pinned templates; customization stops for
manual review. The running job continues with its already loaded updater code,
and a merged proposal supplies the updater used by the next run. Consumer
memory, root instructions, feature records, decisions, tests, and other files
are not rewritten. Maintainers still apply the project's normal DoR, DoD, CI,
and review gates. The evolved contract is recorded in
[FEAT-0004](features/FEAT-0004-self-updating-consumer-updater/README.md) and
[DEC-0005](decisions/DEC-0005-consumer-scoped-fine-grained-pat.md), preserving
the supersession rules in
[DEC-0003](decisions/DEC-0003-reviewed-consumer-update-supersession.md).

A repository-reference consumer MUST request the common pinned source paths
from the first table and write them to those consumer-owned targets. It MUST NOT
copy the submodule-only updater assets unchanged. Apply the same collision
preflight before writing anything. If the provider exposes only `PROTOCOL.md`,
create equivalent project-owned tracking assets through reviewed changes or use
submodule mode for template installation; a moving `main` download is not an
acceptable fallback.


A repository-reference automation adapter MUST define and test the provider's
exact read, write, compare-and-swap, ownership, and rollback behavior in a
reviewed project decision. If those primitives cannot be proved, keep updates
manual rather than approximating the submodule workflow.
Create the labels referenced by the forms before use: `type:epic`,
`type:feature`, `type:subfeature`, `type:task`, `type:bug`, `type:finding`,
`priority:p0` through `priority:p3`, `status:blocked`, and
`status:needs-review`. Add project-specific area labels only when needed.

GitHub issue-form fields are guidance on private repositories because current
[`required` validation is public-repository only](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema).
Verify DoR and DoD in the project feature record and pull request.

For an existing consumer clone, initialize the pinned protocol with:

```powershell
git submodule update --init --recursive
```

New clones may use `git clone --recurse-submodules <consumer-repository>`.

## Pinned repository reference

A tool that natively supports repository references MAY use:

- repository: `https://github.com/hasanmanzak/meAndAI`
- ref: `v0.8.5`
- entry point: `PROTOCOL.md`

Copy or merge the
[repository-reference adapter](../templates/project/AGENTS.repository-reference.md)
into the consumer root. Configure it for the provider that resolves the three
fields above; it MUST NOT point to `.ai/protocol/PROTOCOL.md` when no submodule
exists.

The reference MUST resolve to a tag or commit and MUST be readable in every
development environment. Follow the [consumer tracking asset](#consumer-tracking-assets)
mapping to initialize local memory, templates, and tracking assets from that
same immutable ref. Never point project memory into the remote protocol
reference. Do not rely on a moving `main` reference.

Do not install the supplied submodule workflow unchanged for an opaque
repository reference: it cannot know how to update that provider's pointer.
Record a provider-specific deterministic adapter in a project decision, or use
the manual reviewed update process below.

## Rule precedence

1. Legal, security, and platform constraints.
2. Explicit current user instructions.
3. Consuming repository instructions and accepted decisions.
4. The pinned [common protocol](../PROTOCOL.md).
5. Tool defaults.

A project instruction can strengthen the common protocol. A relaxation requires
a numbered project decision with its rationale, risk, scope, and review
condition.

## Updating

1. Read releases between the current and target versions in the
   [changelog](../CHANGELOG.md).
2. Create a tracked project issue for the upgrade.
3. Review incompatible or newly mandatory rules.
4. Update the submodule or reference to a specific tag.
5. Run the consuming project's tests and documentation-link checks.
6. Update the pinned version in project memory and merge through a pull request.

For a submodule without the updater, use the target release selected by the
reviewed migration. Verify its immutable-release metadata with the same check
shown under [Recommended: pinned Git submodule](#recommended-pinned-git-submodule)
before checkout; the current example then installs `v0.8.5`:

```powershell
git -C .ai/protocol fetch --tags
git -C .ai/protocol checkout v0.8.5
git add .ai/protocol
```

### Semi-automatic submodule updates

After the workflow and scripts are committed on the consumer's default branch,
the daily schedule or `workflow_dispatch` checks for a newer compatible
canonical tag. If one exists, the workflow opens a deterministic draft branch
and pull request for the exact target. The same proposal contains the protocol
gitlink plus only those canonical updater assets whose target-release blobs
differ. The maintainer reviews and merges it through the consuming project's
ordinary gates.

If another release appears before merge, the newer proposal supersedes the
older one. Supersession is replacement-first and compensated, not a distributed
transaction: the workflow creates and fully verifies the new branch and draft
pull request, then revalidates both proposals immediately before each old
cleanup. It closes the old pull request and deletes only the exact expected
branch head with a Git lease. If paired branch cleanup fails or the ref
disappears, it tries to reopen the old pull request and reports manual recovery
when compensation cannot restore the prior review state. The workflow never
intentionally deletes a changed or ambiguously owned branch.

### Interrupted-run recovery

Cancellation or infrastructure failure after the branch push but before pull
request creation can leave a reserved automation branch without a managed pull
request. The expected-absent creation lease makes the next run stop instead of
overwriting it. Disable or wait for update runs before recovery, then:

1. read the actual consumer default branch and capture the exact remote branch
   SHA;
2. verify that no open or closed pull request owns the branch;
3. fetch that SHA and verify its changes are exactly `.ai/protocol` plus the
   target-different subset of the three canonical updater assets;
4. verify the gitlink resolves to the intended canonical protocol tag and every
   changed updater blob/mode equals that tag's template; and
5. delete only that exact branch SHA with an expected-head lease.

After substituting the real branch, tag, and verified SHA, inspect these
commands as one checklist:

```powershell
$branch = 'automation/meandai-protocol-v0.4.0'
$targetTag = 'v0.4.0'
$expectedSha = '<verified-40-character-orphan-head-sha>'
$defaultBranch = (gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name').Trim()
git ls-remote --heads origin "refs/heads/$branch"
gh pr list --state all --head $branch --json number,state,headRefName,headRefOid
git fetch origin "refs/heads/$defaultBranch:refs/remotes/origin/$defaultBranch"
git fetch origin "refs/heads/$branch"
git diff --name-only "origin/$defaultBranch...FETCH_HEAD"
git diff --raw --no-abbrev "origin/$defaultBranch...FETCH_HEAD" -- .ai/protocol .github/workflows/meandai-protocol-update.yml .github/scripts/MeAndAI.ProtocolUpdate.psm1 .github/scripts/Invoke-MeAndAIProtocolUpdate.ps1
git ls-tree FETCH_HEAD -- .ai/protocol .github/workflows/meandai-protocol-update.yml .github/scripts/MeAndAI.ProtocolUpdate.psm1 .github/scripts/Invoke-MeAndAIProtocolUpdate.ps1
git -C .ai/protocol fetch --tags
git -C .ai/protocol rev-parse "$targetTag^{commit}"
git -C .ai/protocol ls-tree "$targetTag" -- templates/project/.github/workflows/meandai-protocol-update.yml templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1 templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1
git push --force-with-lease="refs/heads/${branch}:$expectedSha" origin ":refs/heads/$branch"
```

`--name-only` must return `.ai/protocol` plus exactly the target-different
managed asset subset. The raw gitlink entry must be `160000 -> 160000`, every
changed asset must remain `100644`, the gitlink SHA must equal the tag commit,
and each changed asset blob must equal its listed target template. Do not delete
the branch if any default-branch, SHA, ownership, pull-request, path, blob, mode,
tag, or active-run check is uncertain.

## Portability and privacy

This is a private repository, so each machine or automation identity needs
GitHub access. Never place credentials in the submodule configuration or
project memory. If access cannot be guaranteed, use an approved private mirror
pinned to the same commit and record that choice in a project decision.
