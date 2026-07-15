# Changelog

This project uses the `M.m.rev` version format defined in the
[common protocol](PROTOCOL.md#8-versioning).

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
[issue #19](https://github.com/hasanmanzak/meAndAI/issues/19).

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

- Consumers already pinned to immutable `v0.1.0` need one manual upgrade to
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
