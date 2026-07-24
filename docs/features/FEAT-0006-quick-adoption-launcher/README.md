# FEAT-0006 - One-Command Quick Adoption Launcher

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.6.0 |
| Issue | [#19](https://github.com/hasanmanzak/meAndAI/issues/19) |
| Pull request | [#20](https://github.com/hasanmanzak/meAndAI/pull/20) |
| Decision | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The v0.5 lifecycle reduces first adoption to one consumer workflow, but the
maintainer must still copy that file, create or connect the Git repository,
configure two Actions secrets, commit, and push in the correct order. Repeating
those mechanical steps invites path, version, credential-name, and accidental
staging mistakes.

## Outcome

A maintainer opens a shell in a consumer directory and runs one source-only
PowerShell launcher. The launcher downloads the exact tagged workflow,
configures the two repository secrets from local token files without exposing
their values, commits only the workflow, and pushes it. If the directory has no
local Git repository or `origin`, it initializes `main` and creates a private
GitHub repository by default. It then dispatches and waits for the lifecycle
and places one scoped `@codex` task on the resulting draft, leaving final review
and merge to the maintainer.

## Scope

- Add `scripts/Invoke-MeAndAIQuickAdoption.ps1` as a source-only maintainer
  launcher pinned by default to `v0.6.0`.
- Support an existing clean GitHub repository on its default branch without
  modifying or staging application content.
- Support a directory without its own Git repository or `origin` by deriving
  the repository name from the directory, deriving the owner from authenticated
  `gh`, initializing `main`, and creating a private remote by default.
- Read `FG_PAT.txt` and `MEANDAI_RO_FG_PAT.txt`, store their trimmed values as
  `MEANDAI_UPDATER_TOKEN` and `MEANDAI_PROTOCOL_TOKEN`, and never print, delete,
  commit, or pass those values as command-line arguments.
- Add both token filenames to the local Git exclude file and block if either is
  tracked or present in repository history.
- Download the seed from the exact tag through the GitHub contents API and
  verify the returned Git blob before writing.
- Remain idempotent when the exact seed is already committed; block rather than
  overwrite a different workflow or ambiguous repository state.
- Dispatch and wait for the exact published commit's lifecycle under a finite
  timeout, then resolve the single deterministic adoption draft.
- Place one marker-protected Codex Cloud task on that draft and never approve
  or merge it.
- Add a concise remote-download quick command and a copy-ready consumer Codex
  prompt.

## Non-goals

- Creating, editing, or broadening fine-grained PAT grants.
- Embedding an OpenAI API key, adding another consumer workflow, or directly
  running a local Codex executable.
- Approving or merging the generated adoption pull request.
- Publishing unrelated untracked files when a local directory is initialized.
- Reconciling a customized seed workflow.
- Replacing the v0.5 lifecycle bootstrap or post-adoption updater.
- Supporting non-GitHub remotes or opaque repository references.

## Readiness evidence

- Domain and boundaries: consumer directory, Git root, default branch, GitHub
  repository identity, canonical seed blob, local token file, Actions secret,
  local exclude, commit, push, and lifecycle dispatch are separate concepts.
- Ordering: source and local-state validation precede remote mutation; both
  secrets are stored before the workflow commit is pushed; dispatch and Codex
  handoff occur only after publication.
- Compatibility: existing v0.5 consumers are unchanged. New consumers may use
  the launcher or continue with the documented manual workflow-only path.
- Recovery: remote creation or secret storage may succeed before a later Git
  failure; rerunning is safe when the seed remains exact and repository
  ownership is unambiguous.
- Verification: PowerShell AST and structural assertions plus real-Git fixtures
  with mocked GitHub API/CLI boundaries on Windows and Ubuntu CI.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0029` <a name="risk-0029"></a> | Credential confidentiality | Token values leak through arguments, logs, Git, or memory | Mitigated; launcher maintainer | stdin-only `gh secret set`, redacted errors, local exclude, tracked/history block, structural tests |
| `RISK-0030` <a name="risk-0030"></a> | Repository integrity | Existing or unrelated files are committed during adoption | Mitigated; launcher | Clean existing-repo gate and exact workflow-only staging validation; new untracked files remain local |
| `RISK-0031` <a name="risk-0031"></a> | Identity | The launcher targets the wrong owner, repository, remote, or branch | Mitigated; launcher | authenticated owner/default-branch resolution, GitHub-origin validation, and explicit parameter consistency checks |
| `RISK-0032` <a name="risk-0032"></a> | Authorization | A selected-repository fgPAT does not include a newly created consumer | Managed; consumer admin | Target-access preflight and actionable fail-closed rerun guidance; the launcher cannot edit PAT grants |
| `RISK-0033` <a name="risk-0033"></a> | Supply chain | A moving or corrupted workflow is installed | Mitigated; protocol maintainers | exact canonical tag, contents API, response blob verification, and existing-file byte comparison |
| `RISK-0034` <a name="risk-0034"></a> | Partial operation | Repository or secrets exist but commit/push fails | Managed; consumer maintainer | idempotent exact-seed rerun, no rollback of ambiguous remote state, and explicit continuation output |
| `RISK-0035` <a name="risk-0035"></a> | External agent handoff | Codex Cloud is unavailable, lacks write permission, or receives a duplicate task | Managed; consumer maintainer | documented Codex Cloud prerequisite, one marker-protected comment, explicit skip path, no automatic merge |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0033](test-cases.md#test-0033), [TEST-0034](test-cases.md#test-0034), [TEST-0035](test-cases.md#test-0035), [TEST-0036](test-cases.md#test-0036), and [TEST-0037](test-cases.md#test-0037); [TEST-0037](test-cases.md#test-0037) is historical and superseded by [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md) local scenarios |
| Test code | Automated and green | `tests/quick-adoption.tests.ps1`; red state first confirmed the launcher and guide were absent |
| Baseline run | Passed | Windows PowerShell 5.1 [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), and [TEST-0027](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032) on 2026-07-15 before FEAT-0006 changes |
| Feature and regression run | Passed | Windows PowerShell 5.1 [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), [TEST-0027](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032), and [TEST-0033](test-cases.md#test-0033), [TEST-0034](test-cases.md#test-0034), [TEST-0035](test-cases.md#test-0035), [TEST-0036](test-cases.md#test-0036), and [TEST-0037](test-cases.md#test-0037) on 2026-07-15 |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0011` <a name="subf-0011"></a> | Credential-safe seed installation in an existing consumer | [Issue #19](https://github.com/hasanmanzak/meAndAI/issues/19) | [TEST-0033](test-cases.md#test-0033), [TEST-0034](test-cases.md#test-0034), [TEST-0036](test-cases.md#test-0036); pass | `FIND-0053`, `FIND-0054`; resolved | Implemented |
| `SUBF-0012` <a name="subf-0012"></a> | New-repository creation, quick guide, and historical Cloud handoff | [Issue #19](https://github.com/hasanmanzak/meAndAI/issues/19) | [TEST-0035](test-cases.md#test-0035); [TEST-0037](test-cases.md#test-0037) historical pass, now superseded by [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md) | `FIND-0055`; resolved for v0.6.0 | Implemented; handoff superseded |

## Decisions and relationships

- Decision: [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md)
- Predecessor: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md)
- Credential boundary: [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Seed handoff: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Quick guide: [Quick adoption](../../quick-adoption.md)
- Tracking: [issue #19](https://github.com/hasanmanzak/meAndAI/issues/19)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Repository, source, token, secret, ordering, and error contracts.
- [x] Numbered risks and [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md).
- [x] Two bounded, reviewable slices.
- [x] Numbered test scenarios and verification approach.
- [x] Planned red state and successful baseline recorded.

## Acceptance criteria

1. One invocation in a clean connected consumer downloads the exact v0.6.0
   seed, configures both required Actions secrets, commits only the workflow,
   pushes the default branch, dispatches its lifecycle, and waits for the exact
   commit's successful bounded run.
2. One invocation in a directory without its own repository initializes
   `main`, creates `<authenticated-owner>/<directory-name>` as private by
   default, configures `origin` and both secrets, and pushes only the seed.
3. Token values never appear in arguments, output, committed content, project
   memory, or tracked history; tracked or historically committed token files
   block with rotation guidance.
4. Existing application content is preserved. Dirty connected repositories,
   non-default branches, non-GitHub origins, seed drift, source mismatch, and
   repository identity ambiguity block before workflow publication.
5. An exact committed seed is idempotent: rerun reconciles secrets without a
   duplicate commit or destructive reset.
6. The single adoption draft receives no more than one scoped `@codex` task;
   missing or unavailable Codex Cloud leaves an explicit manual handoff and no
   merge mutation.
7. The guide provides an exact-tag remote quick command, prerequisites,
   recovery and skip behavior, and a copy-ready Codex prompt that includes the
   user's scoped token-transmission authorization.
8. Existing lifecycle and updater tests remain green.

## Self-review

The bounded fresh-diff review and one full tracked-project convergence run are
complete. No additional bootstrap or validator layer was added.

| ID | Classification / priority / confidence | Finding and resolution | Status |
| --- | --- | --- | --- |
| `FIND-0053` <a name="find-0053"></a> | Recovery / High / High | A newly created remote left empty by an updater-token grant failure could not be resumed. Empty-remote identity, history, tree, branch, and exact-seed gates now permit only the launcher-owned recovery path; [TEST-0036](test-cases.md#test-0036) reproduces the grant-and-rerun sequence. | Resolved |
| `FIND-0054` <a name="find-0054"></a> | Portability / High / High | Case-insensitive regex matching under the Turkish locale rejected the ASCII capital `I` in `meAndAI`. Identifier and version validation now uses culture-independent case-sensitive matching; the Windows Turkish-locale run passes. | Resolved |
| `FIND-0055` <a name="find-0055"></a> | Idempotency / High / High | At v0.6.0, an exact rerun could request a second Codex Cloud task on the same draft. A fixed HTML ownership marker was checked before commenting; historical [TEST-0037](test-cases.md#test-0037) confirmed one task across two runs. [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md) later removed the Cloud path and owns active local behavior under distinct TEST IDs. | Resolved for v0.6.0; superseded behavior |

The final local command passed all [TEST-0001](../FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), [TEST-0027](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032), and [TEST-0033](test-cases.md#test-0033), [TEST-0034](test-cases.md#test-0034), [TEST-0035](test-cases.md#test-0035), [TEST-0036](test-cases.md#test-0036), and [TEST-0037](test-cases.md#test-0037); no
unresolved actionable in-scope finding remained.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded convergence scan complete.
- [x] No unresolved blocking finding; residual risks are explicit and owned.
- [x] Documentation, links, version, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [x] Applicable CI and review gates pass.

## Post-merge release gate

After the delivery pull request merges, tag the merged `main` commit as
`v0.6.0`, push the tag, and verify the remote reference.
