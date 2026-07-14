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
git -C .ai/protocol checkout v0.1.0
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

$collisions = @($copies.Target | Where-Object { Test-Path -LiteralPath $_ })
if ($collisions.Count -gt 0) {
    throw "Existing consumer files require a manual merge: $($collisions -join ', ')"
}

New-Item -ItemType Directory -Force .github/ISSUE_TEMPLATE | Out-Null
foreach ($copy in $copies) {
    Copy-Item -LiteralPath $copy.Source -Destination $copy.Target
}
```

A repository-reference consumer MUST request the same pinned source paths from
its provider and write them to the consumer-owned targets in the table. Apply
the same collision preflight before writing anything. If the provider exposes
only `PROTOCOL.md`, create equivalent project-owned assets through reviewed
changes or use submodule mode for template installation; a moving `main`
download is not an acceptable fallback.

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
- ref: `v0.1.0`
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

For a submodule:

```powershell
git -C .ai/protocol fetch --tags
git -C .ai/protocol checkout v0.1.0
git add .ai/protocol
```

## Portability and privacy

This is a private repository, so each machine or automation identity needs
GitHub access. Never place credentials in the submodule configuration or
project memory. If access cannot be guaranteed, use an approved private mirror
pinned to the same commit and record that choice in a project decision.
