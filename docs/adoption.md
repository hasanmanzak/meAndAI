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

## Recommended: pinned Git submodule

From the consuming repository root:

```powershell
git submodule add https://github.com/hasanmanzak/meAndAI.git .ai/protocol
git -C .ai/protocol checkout v0.3.0
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
| `.github/ISSUE_TEMPLATE/{bug,epic,feature,finding,subfeature,task}.yml` | `.github/ISSUE_TEMPLATE/` |
| `.github/PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` |
| `templates/feature/` | A new `docs/features/FEAT-NNNN-*/` record |
| `templates/decision.md` | A new `docs/decisions/DEC-NNNN-*.md` record |

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

The copy above is the updater's one-time bootstrap. A workflow cannot install
itself into a consumer that does not already contain it. Therefore consumers
pinned to immutable `v0.1.0` must manually move the submodule to `v0.2.0`, run
this collision-safe copy, review the resulting files, and merge them once. New
consumers adopting `v0.2.0` or later receive the same assets during initial
adoption.

### Update workflow prerequisites and behavior

The supplied workflow is consumer-owned and supports the recommended
`.ai/protocol` Git submodule only when its gitlink resolves to exactly one
canonical lowercase `vM.m.rev` release tag with no leading zeros, and
`.gitmodules` points to the configured protocol repository. A commit pin
remains valid protocol usage, but it uses the manual reviewed update process
because the generic updater cannot infer its current major unambiguously.
Before enabling the updater:

1. Add a repository Actions secret named `MEANDAI_PROTOCOL_TOKEN`. It must be a
   read-only credential that can clone this private `meAndAI` repository. The
   consumer's `GITHUB_TOKEN` remains responsible for consumer contents and
   pull request mutations.
2. In **Settings > Actions > General > Workflow permissions**, allow GitHub
   Actions to create and approve pull requests. The workflow declares only the
   consumer permissions it uses: `contents: write` and `pull-requests: write`.
3. Keep credentials out of repository files, project memory, workflow output,
   issue bodies, and pull request bodies. Adoption cannot create the secret or
   enable the repository setting on the maintainer's behalf.

Any workflow with consumer `contents: write` can interfere with automation
branches under the shared `github-actions[bot]` identity. Limit write-capable
workflows to reviewed code; consumers needing stronger identity separation may
replace `GITHUB_TOKEN` with a dedicated GitHub App through a project decision.

The schedule and manual dispatch provide eventual detection, not an immediate
release notification. A pull request created with `GITHUB_TOKEN` may require a
maintainer to approve its workflow runs under the consumer repository's Actions
policy. See GitHub's documentation for
[`GITHUB_TOKEN`](https://docs.github.com/en/actions/concepts/security/github_token)
and [repository Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository).

The updater selects the highest numeric canonical tag in the current major and
uses a draft pull request as the review gate. It never approves or merges a pull
request.
Its state rules are:

| Observed state | Result |
| --- | --- |
| Consumer already pins the latest compatible tag | No change |
| One valid managed pull request already targets the latest tag | Keep it; no duplicate pull request |
| An older valid managed pull request is open and a newer compatible tag exists | Create and fully verify the newer replacement first; revalidate both proposals before each cleanup, then close the old PR and delete only its expected branch head; try to reopen the old PR if paired cleanup fails |
| Ownership, canonical marker, planned head, protocol commit, gitlink mode, changed path, base, draft state, author, repository, API head, or remote ref is ambiguous | Stop or compensate without deleting ambiguous work |
| A higher major exists | Report that explicit migration is required; do not propose it automatically |

Managed update pull requests change only the `.ai/protocol` gitlink. Consumer
memory, root instructions, feature records, decisions, and copied templates are
not rewritten. Maintainers still apply the project's normal DoR, DoD, CI, and
review gates. The complete contract is recorded in
[FEAT-0002](features/FEAT-0002-semi-automatic-consumer-updates/README.md) and
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
- ref: `v0.3.0`
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

For a submodule without the updater, or for the one-time `v0.1.0` migration:

```powershell
git -C .ai/protocol fetch --tags
git -C .ai/protocol checkout v0.3.0
git add .ai/protocol
```

### Semi-automatic submodule updates

After the workflow and scripts are committed on the consumer's default branch,
the daily schedule or `workflow_dispatch` checks for a newer compatible
canonical tag. If one exists, the workflow opens a deterministic draft branch
and pull request for the exact target. The maintainer reviews and merges it
through the consuming project's ordinary gates.

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
3. fetch that SHA and verify that its only change from the consumer default
   branch is `.ai/protocol`, with gitlink mode `160000` before and after;
4. verify that the new gitlink SHA resolves to the intended canonical protocol
   tag; and
5. delete only that exact branch SHA with an expected-head lease.

After substituting the real branch, tag, and verified SHA, inspect these
commands as one checklist:

```powershell
$branch = 'automation/meandai-protocol-v0.3.0'
$targetTag = 'v0.3.0'
$expectedSha = '<verified-40-character-orphan-head-sha>'
$defaultBranch = (gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name').Trim()
git ls-remote --heads origin "refs/heads/$branch"
gh pr list --state all --head $branch --json number,state,headRefName,headRefOid
git fetch origin "refs/heads/$defaultBranch:refs/remotes/origin/$defaultBranch"
git fetch origin "refs/heads/$branch"
git diff --name-only "origin/$defaultBranch...FETCH_HEAD"
git diff --raw --no-abbrev "origin/$defaultBranch...FETCH_HEAD" -- .ai/protocol
git ls-tree FETCH_HEAD -- .ai/protocol
git -C .ai/protocol fetch --tags
git -C .ai/protocol rev-parse "$targetTag^{commit}"
git push --force-with-lease="refs/heads/${branch}:$expectedSha" origin ":refs/heads/$branch"
```

`--name-only` must return only `.ai/protocol`; `--raw` must return one
`160000 -> 160000` entry; and the `ls-tree` SHA must equal the tag's commit.
Do not delete the branch if any default-branch, SHA, ownership, pull-request,
path, mode, tag, or active-run check is uncertain.

## Portability and privacy

This is a private repository, so each machine or automation identity needs
GitHub access. Never place credentials in the submodule configuration or
project memory. If access cannot be guaranteed, use an approved private mirror
pinned to the same commit and record that choice in a project decision.
