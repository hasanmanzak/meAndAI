# Changelog

This project uses the `M.m.rev` version format defined in the
[common protocol](PROTOCOL.md#8-versioning).

## 0.9.5 - 2026-07-17

### Fixed

- Replace the host-managed PowerShell progress overlay with compact normal
  console lines for actual launcher phases and elapsed local-Codex activity.
- Consume semantic `codex exec --json` output incrementally and present only
  bounded caller-facing messages and safe activity metadata; raw reasoning,
  command output, and streamed false-readiness remain non-authoritative.
- Establish kill-on-close Windows process-tree containment before semantic
  model work and terminate the owned tree before timeout or cancellation
  cleanup, while retaining exact interrupted-publication recovery.

Related work: [FEAT-0020 / BUG-0008](docs/features/FEAT-0020-v095-streamed-codex-cancellation/README.md),
[TEST-0105 and TEST-0106](docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md), and
[issue #57](https://github.com/hasanmanzak/meAndAI/issues/57).

## 0.9.4 - 2026-07-16

### Fixed

- Validate native Windows Codex workspace writes with a token-free sandbox
  probe before semantic execution, and carry only the verified `elevated` or
  `unelevated` mode across the isolated `--ignore-user-config` boundary.
- Fall back from an unavailable elevated sandbox to the still-sandboxed
  unelevated implementation, while blocking before a model call when neither
  mode succeeds or a probe leaves residue.
- Treat absent product facts in an empty consumer as `Not yet established`
  instead of fabricating them or blocking structural protocol adoption.
- Display truthful phase progress, indeterminate elapsed local-Codex work, and
  deterministic cleanup, with `-NoProgress` available for noninteractive use.

Related work: [FEAT-0019 / BUG-0007](docs/features/FEAT-0019-v094-sandbox-progress-correction/README.md),
[TEST-0103 and TEST-0104](docs/features/FEAT-0019-v094-sandbox-progress-correction/test-cases.md), and
[issue #55](https://github.com/hasanmanzak/meAndAI/issues/55).

## 0.9.3 - 2026-07-16

### Fixed

- Validate adoption pull-request origin through the real GitHub CLI fields
  `headRepository.name`, `headRepositoryOwner.login`, and Boolean
  `isCrossRepository` instead of the unavailable
  `headRepository.nameWithOwner` projection.
- Model the observed pull-request JSON shape in the quick-adoption integration
  fixture and reject repository-name, owner, cross-repository, and type drift
  before local Codex or Git mutation.
- Preserve the deterministic draft and resumable lifecycle boundary so an
  affected `v0.9.2` adoption can continue with the corrected launcher.

Related work: [FEAT-0018 / BUG-0006](docs/features/FEAT-0018-v093-live-pr-metadata-correction/README.md),
[TEST-0102](docs/features/FEAT-0018-v093-live-pr-metadata-correction/test-cases.md), and
[issue #53](https://github.com/hasanmanzak/meAndAI/issues/53).

## 0.9.2 - 2026-07-16

### Changed

- Distribute the existing quick-adoption launcher as one named asset of the
  immutable protocol release instead of presenting its acquisition as an
  inline PowerShell command stack.
- Reduce normal consumer-side execution to one local `-File` invocation while
  keeping the reusable launcher outside the consumer repository.
- Preserve exact immutable-release validation, canonical-source retrieval,
  credential handling, lifecycle orchestration, and maintainer-owned merge.

Related work: [FEAT-0017](docs/features/FEAT-0017-v092-single-file-quick-adoption/README.md),
[TEST-0101](docs/features/FEAT-0017-v092-single-file-quick-adoption/test-cases.md), and
[issue #51](https://github.com/hasanmanzak/meAndAI/issues/51).

## 0.9.1 - 2026-07-16

### Fixed

- Resolve an accessible derived GitHub repository before treating a no-remote,
  no-head target as a new repository.
- Connect only an existing empty repository, preserve its mapped repository
  Actions secrets, and require a local token file only when its mapped secret
  is absent.
- Keep credential-history validation ahead of repository classification and
  reject an existing non-empty derived repository before adding a local remote
  or mutating secrets.

Related work: [FEAT-0016 / BUG-0005](docs/features/FEAT-0016-v091-quick-adoption-correction/README.md),
[TEST-0100](docs/features/FEAT-0016-v091-quick-adoption-correction/test-cases.md), and
[issue #49](https://github.com/hasanmanzak/meAndAI/issues/49).

## 0.9.0 - 2026-07-16

### Added

- Add one event-triggered stability and consistency mandate for this repository
  and exact-pin consumers: scan after material development, preserve finding
  dispositions, and enter a waiting state after zero-`Blocking` convergence.
- Order remediation by explicit dependencies before priority, require focused
  evidence and fresh-diff self-review for each finding or smallest inseparable
  dependency group, and keep change-caused blockers in the active queue.
- Define the mandate's terminal publication action as a converged final Git
  push, explicitly separate from protocol tags and GitHub Releases, while
  retaining bounded confirmation and blocked stop conditions.
- Extend consumer adoption guidance, evidence templates, and structural
  scenarios without adding a scanner, scheduler, recursive bootstrapper, or
  consumer-owned file rewrite.

Related work: [FEAT-0015](docs/features/FEAT-0015-stability-consistency-mandate/README.md),
[DEC-0015](docs/decisions/DEC-0015-event-triggered-stability-cycles.md), and
[issue #47](https://github.com/hasanmanzak/meAndAI/issues/47).

## 0.8.6 - 2026-07-16

### Fixed

- Keep post-publication work outside the pre-merge Definition of Done and
  require every feature targeting the current release to be `Complete` before
  publication.
- Extend `TEST-0092` so the complete local gate rejects the exact projection
  mismatch that made immutable v0.8.5 ineligible for `TEST-0065` evidence.
- Advance current adoption pins to the corrective release without changing the
  v0.8.5 runtime behavior or weakening the post-publication verifier.

The v0.8.5 Release remains an immutable historical record. Its first
post-publication preflight exposed `FIND-0132`; v0.8.6 closes that verified
finding rather than rewriting or overstating the earlier release.

Related work: [FEAT-0014](docs/features/FEAT-0014-v085-convergence/README.md),
[DEC-0012](docs/decisions/DEC-0012-bounded-correction-and-external-release-evidence.md),
and [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43).

## 0.8.5 - 2026-07-16

### Fixed

- Reject linked, reparse, or escaping managed-path ancestors before launcher
  credential mutation or bootstrap filesystem writes, and apply one exact
  completed-publication contract before proposal retention or readiness.
- Use the protocol's unbounded ASCII/no-leading-zero version grammar at runtime,
  execute every declared boundary variant, and require independently derived
  workflow dispatch and run identity.
- Make scenario ownership depend on observable per-scenario results rather than
  suite exit alone, and reconcile finding counts, version wording, canonical
  GitHub links, and the durable external follow-up projection.

The unavailable private-repository `main` protection remains open as
`RISK-0076` / `FIND-0120`; this correction tracks it separately and does not
change repository visibility.

Related work: [FEAT-0014](docs/features/FEAT-0014-v085-convergence/README.md),
[DEC-0014](docs/decisions/DEC-0014-contained-adoption-and-observable-evidence.md),
and [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43).

## 0.8.4 - 2026-07-16

### Fixed

- Validate consumer-local updater assets through trusted exact-release code
  before credentials reach them, and reject seed drift before any secret
  mutation.
- Make interrupted adoption completion exactly rerunnable and reuse one
  canonical manifest contract across bootstrap and launcher boundaries.
- Align marker/serialization evidence with executed fixtures, traverse
  post-publication comment pagination, separate finding classification from the
  four protocol dispositions, and exercise canonical version boundaries.
- Replace stale delivery and planned-implementation wording with stable merged
  PR and implemented-evidence links while retaining exact publication facts in
  the external authority.

The unavailable private-repository `main` protection remains maintainer-owned
`RISK-0076`, with review required when public visibility or a supporting GitHub
plan makes the control available. This release does not change visibility.

Related work: [FEAT-0013](docs/features/FEAT-0013-v084-correction/README.md),
[DEC-0013](docs/decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md),
and [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41).

## 0.8.3 - 2026-07-16

### Fixed

- Removed the invalid trailing slash from the post-publication verifier's
  repository-metadata endpoint and made the focused mock reject that URL shape.
- Retained the immutable v0.8.2 failure as external evidence in
  [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38); v0.8.3 carries
  only this bounded correction and the required active release pins.

Related work: [FEAT-0012](docs/features/FEAT-0012-v082-correction/README.md),
[DEC-0012](docs/decisions/DEC-0012-bounded-correction-and-external-release-evidence.md),
and [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38).

## 0.8.2 - 2026-07-16

### Fixed

- Tighten exact adoption-issue ownership, serialize secret reconciliation, and
  align completed-proposal retention and reserved-branch orphan recovery.
- Replace identifier-substring and contract-dropping test evidence with
  scenario-owned assertions, credential-boundary checks, and a recurring
  actionlint gate.
- Make the completion scan mandatory in the feature template, preserve the
  distinct evidence contract for every finding disposition, and keep release
  facts pending in-repository until their external post-publication authority
  records them.
- Correct the v0.8.1 audit ledger and explicitly retain the historical fact
  that publication claims were written before publication evidence existed.

Exact release/tag/commit and hosted verification facts are intentionally
retained after publication by [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38)
and the GitHub Release rather than predicted in this changelog commit.

Related work: [FEAT-0012](docs/features/FEAT-0012-v082-correction/README.md),
[DEC-0012](docs/decisions/DEC-0012-bounded-correction-and-external-release-evidence.md),
and [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38).

## 0.8.1 - 2026-07-15

### Fixed

- Kept GitHub.com host identity on launcher metadata and secret operations and
  correlated each lifecycle dispatch to its exact workflow run.
- Used the read-only protocol credential to bind immutable releases to exact
  lightweight or annotated tag commits before any updater mutation.
- Exposed both sides of bootstrap renames, converged raced adoption issues, and
  limited fixture cleanup to paths owned by the current run.
- Unified bounded finding dispositions, reconciled v0.8.0 publication records,
  and replaced false-green line/range proxies with executable scenario, asset,
  timeout, YAML, PowerShell, and least-privilege CI evidence.

Related work: [FEAT-0011](docs/features/FEAT-0011-stability-closure/README.md),
[DEC-0011](docs/decisions/DEC-0011-qualified-evidence-and-closure.md), and
[issue #36](https://github.com/hasanmanzak/meAndAI/issues/36).

## 0.8.0 - 2026-07-15

### Added

- Made exact published immutable GitHub Releases the external authority for
  executable bootstrap sources and automatic update targets.
- Added explicit proposed/completed adoption markers, exact live PR
  revalidation, dispatch-specific workflow-run identity, and reachable
  ref/reflog credential-history boundaries.

### Fixed

- Made protected-path and `.gitmodules` checks case-sensitive and rename-safe.
- Replaced metadata-only adoption retention with one exact draft, marker,
  manifest, ancestry, tree, and live-ref validator.
- Made supersession cleanup replacement-first, revalidated, lease-safe, and
  compensated when close/delete continuity cannot be proven.
- Derived repository evidence coverage from canonical indexes, excluded nested
  repositories from root Markdown validation, bounded CI, and reconciled
  release/finding records through one reusable evidence schema.

Related work: [FEAT-0010](docs/features/FEAT-0010-protocol-stability-invariants/README.md),
[DEC-0010](docs/decisions/DEC-0010-stable-automation-invariants.md), and
[issue #34](https://github.com/hasanmanzak/meAndAI/issues/34), delivered through
[pull request #35](https://github.com/hasanmanzak/meAndAI/pull/35).

## 0.7.3 - 2026-07-15

### Changed

- Clarified that the displayed Codex prompt is not the quick-adoption entry
  point; the parent PowerShell launcher has already created or validated the
  repository, reconciled secrets, published the seed, completed the lifecycle,
  and prepared an isolated draft clone before Codex starts.
- Explained that applicable credential source files live only in the original
  target, are never committed, pushed, copied into the temporary clone, or
  deleted by the launcher, and are intentionally absent only from the Codex
  workspace.
- Distinguished the network-enabled parent launcher's GitHub and remote Git
  work before and after Codex from network-disabled commands spawned inside the
  Codex step, while retaining configured model-service access and
  maintainer-owned merge.

This release changes documentation and structural coverage only; launcher,
credential, workflow, publication, and consumer behavior are unchanged.

Related work: [BUG-0003](docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0003-documentation-clarification-for-v073)
and [issue #32](https://github.com/hasanmanzak/meAndAI/issues/32).

## 0.7.2 - 2026-07-15

### Fixed

- Bound adoption proposal retention and local completion to one canonical
  ownership marker, the target repository and base, authenticated actor,
  same-repository head, live head SHA, protocol tag, and exact protocol commit.
- Made final protocol gitlink and `.gitmodules` validation unconditional while
  preserving collision-mode completion without Codex network access or a
  populated protocol worktree.
- Rejected GitHub rename and previous-filename metadata in both updater
  inventory and cleanup revalidation so unmanaged rename sources cannot evade
  the managed-path contract.
- Kept adoption issues in progress during fallible work and moved them to
  `status:needs-review` only after the completion commit is pushed, verified,
  and the pull request is ready.
- Reconciled v0.7.0/v0.7.1 release records, clarified optional credential-file
  and authenticated-`gh` source transport rules, and exposed DEC-0007's partial
  supersession.

Related work: [FEAT-0009](docs/features/FEAT-0009-adoption-integrity/README.md)
and [issue #30](https://github.com/hasanmanzak/meAndAI/issues/30).

## 0.7.1 - 2026-07-15

### Fixed

- Existing connected repositories now require each local credential file only
  when its mapped repository Actions secret is missing. A configured target can
  rerun quick adoption after both local files have been removed.
- When `MEANDAI_PROTOCOL_TOKEN` exists but `MEANDAI_RO_FG_PAT.txt` is absent,
  the launcher uses the authenticated local GitHub CLI to retrieve the exact
  tagged workflow and clone the exact semantic-adoption source snapshot. Git
  blob and manifest-commit verification remain enforced.
- New repositories still require both local files before remote creation, and
  a missing target secret still requires its mapped file for provisioning.
  Stored GitHub secret values are never read or exposed.

Related work: [BUG-0002](docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0002-correction-for-v071)
and [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27).

## 0.7.0 - 2026-07-15

### Added

- Added repository-native `IDEA-NNNN` incubation for durable possibilities
  that are not yet authorized delivery work.
- Added bounded `Exploring`, `Parked`, `Promoted`, and `Rejected` states, a
  canonical idea index and template, and explicit promotion links into the
  existing work and decision graph.
- Added the parked role-based multi-agent protocol idea without implementing
  that feature.
- Added a pinned consumer idea template and absent-only idea-index installation
  during collision-free initial submodule adoption.
- Added executable `TEST-0043` and `TEST-0044` lifecycle, ownership, and
  bootstrap regression coverage.

### Changed

- Existing consumers may opt into `docs/ideas` from their immutable protocol
  pin without migration. Compatible updater managed paths remain unchanged and
  never rewrite consumer idea content.

Related work: [FEAT-0008](docs/features/FEAT-0008-idea-incubation/README.md),
[DEC-0009](docs/decisions/DEC-0009-repository-native-idea-incubation.md), and
[issue #26](https://github.com/hasanmanzak/meAndAI/issues/26).

## 0.6.2 - 2026-07-15

### Fixed

- The quick-adoption launcher now lists repository-level Actions secret names
  and preserves an existing `MEANDAI_UPDATER_TOKEN` or
  `MEANDAI_PROTOCOL_TOKEN` without calling `gh secret set` for that name.
- Only missing mapped secrets are created. `FG_PAT.txt` is neither required nor
  read when the updater secret already exists; the private protocol source file
  remains required for exact tagged-source retrieval.
- Existing credential-file tracking and history gates remain active even when
  an optional source file is absent, and a present secret name is explicitly
  not treated as validation of its hidden value, scope, expiry, or usability.

Related work: [BUG-0001](docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0001-correction-for-v062)
and [issue #24](https://github.com/hasanmanzak/meAndAI/issues/24).

## 0.6.1 - 2026-07-15

### Changed

- Replaced the hosted GitHub-agent handoff with synchronous local Codex CLI
  execution in an isolated temporary clone of the exact adoption PR head.
- Added installed-CLI discovery and a pinned, non-global
  `@openai/codex@0.144.4` fallback through `npx`.
- Added immutable `headRefOid`, unchanged-agent-head, manifest-removal,
  credential-file, protected-path, remote-head, exact-lease, and post-push
  verification gates before the adoption pull request becomes ready.
- Added a finite local Codex process limit and disabled network access for
  commands spawned by the agent. The launcher now owns deterministic Agile
  label and adoption-issue reconciliation.
- A manifest-free draft with no launcher-owned completion evidence is left for
  manual readiness review instead of being promoted automatically.
- Kept secret provisioning entirely in deterministic PowerShell/`gh` work;
  Codex receives only the fixed filename-to-secret-name mapping and never the
  token values or source files.
- Preserved `-SkipCodexDelegation` as a compatibility alias for the clearer
  `-SkipLocalCodex` switch.

### Removed

- Removed the Codex Cloud prerequisite, `@codex` pull-request comments, and
  marker-based delegation state from active quick-adoption behavior.

Related work: [FEAT-0007](docs/features/FEAT-0007-local-codex-adoption/README.md),
[DEC-0008](docs/decisions/DEC-0008-local-codex-execution.md), and
[issue #21](https://github.com/hasanmanzak/meAndAI/issues/21).

## 0.6.0 - 2026-07-15

### Added

- Added one source-only PowerShell launcher that installs the exact tagged
  lifecycle workflow into a clean connected consumer or creates a private
  GitHub repository for a new local directory.
- Added credential-safe provisioning from `FG_PAT.txt` and
  `MEANDAI_RO_FG_PAT.txt` to the fixed repository Actions secrets without
  printing, committing, deleting, or passing token values as arguments.
- Added fail-closed repository, branch, source-blob, workflow-collision,
  token-history, exact-staging, and updater-token-access gates.
- Added a concise quick adoption guide, consumer Codex handoff prompt, and
  executable `TEST-0033` through `TEST-0037` coverage.
- Added bounded post-publication lifecycle dispatch and a marker-protected
  Codex Cloud task on the deterministic adoption draft.

### Changed

- First adoption may now begin with one local launcher invocation through the
  successful lifecycle run and durable Codex Cloud handoff; final review and
  merge remain explicit maintainer gates.
- New-directory adoption publishes only the canonical seed workflow and leaves
  unrelated local content untracked.

Related work: [FEAT-0006](docs/features/FEAT-0006-quick-adoption-launcher/README.md),
[DEC-0007](docs/decisions/DEC-0007-local-quick-adoption-boundary.md), and
[issue #19](https://github.com/hasanmanzak/meAndAI/issues/19), delivered by
[pull request #20](https://github.com/hasanmanzak/meAndAI/pull/20).

## 0.5.0 - 2026-07-15

### Added

- Added one workflow-seeded AI-capabilities lifecycle for first adoption,
  collision-free bootstrap, semantic handoff, and later protocol updates.
- Added source-pinned lifecycle planning and bootstrap adapters with
  deterministic draft branches, expected-absent leases, and exact staged-path
  validation.
- Added a transient adoption manifest for project-specific labels, records,
  memory, semantic merge, tests, links, and explicit completion by an invoked
  agent or maintainer.
- Added executable `TEST-0027` through `TEST-0032` coverage for workflow
  routing, empty and populated consumers, collisions, idempotency, orphan
  recovery boundaries, credentials, and updater regression.

### Changed

- The consumer update workflow is now also the sole adoption seed. Complete
  existing installations continue to delegate to the v0.4 local updater.
- Collision-free consumers receive deterministic core assets in a draft;
  colliding consumers receive a manifest-only draft and no existing target is
  overwritten.
- GitHub Actions explicitly remains a deterministic repository actor and does
  not claim to start or impersonate an AI agent.

Related work: [FEAT-0005](docs/features/FEAT-0005-ai-capabilities-lifecycle/README.md),
[DEC-0006](docs/decisions/DEC-0006-seed-workflow-adoption-handoff.md), and
[issue #17](https://github.com/hasanmanzak/meAndAI/issues/17), delivered by
[pull request #18](https://github.com/hasanmanzak/meAndAI/pull/18).

## 0.4.0 - 2026-07-15

### Added

- Added a self-reconciling consumer updater that proposes the protocol gitlink
  and the exact target-different updater workflow/script subset in one draft PR.
- Added current-template drift detection and target path/mode/blob validation
  before proposal creation or supersession cleanup.
- Added executable `TEST-0022` through `TEST-0026` coverage for authentication,
  actor rotation, deterministic asset staging, drift, and multi-path proposals.

### Changed

- Consumer mutations now use the repository-scoped fine-grained PAT secret
  `MEANDAI_UPDATER_TOKEN`; the workflow `GITHUB_TOKEN` is read-only and private
  protocol reads remain separated through `MEANDAI_PROTOCOL_TOKEN`.
- Existing pre-v0.4 consumers require one reviewed updater migration; later
  compatible proposals update their own managed assets after merge.

Related work: [FEAT-0004](docs/features/FEAT-0004-self-updating-consumer-updater/README.md),
[DEC-0005](docs/decisions/DEC-0005-consumer-scoped-fine-grained-pat.md), and
[issue #15](https://github.com/hasanmanzak/meAndAI/issues/15) delivered by
[pull request #16](https://github.com/hasanmanzak/meAndAI/pull/16).

## 0.3.2 - 2026-07-14

### Changed

- Reworded updater cleanup comments to describe close/delete as an attempt and
  to explain the reopen/preserve compensation path when branch deletion fails.
- Preserved the existing replacement-first ordering, live safety gates, branch
  leases, and cleanup failure behavior.
- Added executable `TEST-0021` coverage for the emitted audit message contract.

Related work: [issue #11](https://github.com/hasanmanzak/meAndAI/issues/11) and
[pull request #12](https://github.com/hasanmanzak/meAndAI/pull/12).

## 0.3.1 - 2026-07-14

### Changed

- Clarified that urgent work may compress elapsed time but cannot reorder gates
  or authorize implementation before Definition of Ready.
- Required concise evidence to exist before its gate and routed real deviations
  through the existing numbered-decision process instead of retrospective
  evidence.
- Added executable `TEST-0020` coverage for the urgent-work contract.

Related work: [issue #9](https://github.com/hasanmanzak/meAndAI/issues/9) and
[pull request #10](https://github.com/hasanmanzak/meAndAI/pull/10).

## 0.3.0 - 2026-07-14

### Added

- Added a bounded post-development full-project convergence scan that records
  findings, resolves them from highest to lowest priority, and requires zero
  unresolved actionable in-scope findings for completion.
- Added explicit scope, validation-budget, progress, and blocked-state controls
  so repeated scans cannot become an unchanged review loop.
- Added [FEAT-0003](docs/features/FEAT-0003-convergent-completion-scan/README.md),
  [DEC-0004](docs/decisions/DEC-0004-bounded-completion-convergence.md), and
  executable `TEST-0019` contract coverage.

Related work: [issue #7](https://github.com/hasanmanzak/meAndAI/issues/7) and
[pull request #8](https://github.com/hasanmanzak/meAndAI/pull/8).

## 0.2.1 - 2026-07-14

### Changed

- Bounded normal self-validation to one fresh-diff review and one final
  verification command; only blocking findings reopen delivery scope.
- Prohibited recursive validator/bootstrap chains without a concrete risk and
  numbered decision, while retaining explicit full-scan triggers.
- Separated common consumer assets from submodule-only updater assets.
- Tightened the documented orphan-branch recovery checks for default branch,
  gitlink mode, and target tag without adding automation.
- Removed unused `issues: write` permission and corrected small contract and
  historical test-description drift.

Related work: [issue #5](https://github.com/hasanmanzak/meAndAI/issues/5).
## 0.2.0 - 2026-07-14

### Added

- A consumer-owned scheduled and manually dispatched workflow that proposes
  same-major protocol updates as draft pull requests.
- A fail-closed update resolver and thin GitHub adapter with replacement-first
  supersession of older managed update pull requests and branches.
- Collision-safe adoption mapping for the workflow and its scripts.
  Candidate ownership uses one canonical marker and live planned-head binding,
  with expected-state leases and compensation around non-atomic GitHub cleanup.
- Cross-platform repository validation on GitHub-hosted Ubuntu and Windows
  PowerShell, plus race, pagination, origin, marker, and local Git lease
  fixtures.

### Migration

- Consumers already pinned to exact `v0.1.0` need one manual upgrade to
  `v0.2.0` and one-time updater installation. New `v0.2.0` adopters receive the
  updater assets during initial adoption.
- Repository-reference consumers require a provider-specific deterministic
  adapter or manual reviewed upgrades; the generic workflow updates only the
  recommended `.ai/protocol` Git submodule.

Related work: [FEAT-0002](docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md),
[DEC-0003](docs/decisions/DEC-0003-reviewed-consumer-update-supersession.md),
[issue #3](https://github.com/hasanmanzak/meAndAI/issues/3), and
[pull request #4](https://github.com/hasanmanzak/meAndAI/pull/4).

## 0.1.0 - 2026-07-14

### Added

- Portable common development protocol and project adoption model.
- Project-local AI memory convention.
- Feature, decision, test, issue, and pull request templates.
- Structural protocol validation and its documented test scenarios.

Related work: [FEAT-0001](docs/features/FEAT-0001-common-development-protocol/README.md),
[issue #1](https://github.com/hasanmanzak/meAndAI/issues/1), and
[pull request #2](https://github.com/hasanmanzak/meAndAI/pull/2).
