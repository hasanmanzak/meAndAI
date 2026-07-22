# Changelog

This project uses the `M.m.rev` version format defined in the
[common protocol](PROTOCOL.md#8-versioning).

## 0.13.0 - 2026-07-22

### Added

- Declare the append-only `test-runtime-efficiency` semantic capability with
  reuse-first immutable setup, isolated mutable derivatives, machine-readable
  operation budgets, and reviewed budget-delta requirements.
- Add strict owner/route/runtime operation observations to the common test
  runtime and make the stable parent runner validate them before accepting a
  suite's canonical scenario or compatibility result.

### Changed

- Build the three repeated quick-adoption fixture families once per suite and
  provision 21 deep-copy mutable derivatives while retaining fresh fixtures
  for security, history, link, hook, race, and version-shape evidence.
- Build bootstrap consumer, protocol, and empty-remote seeds once, reducing its
  reviewed fixture operations from 38 to 3 `init` and 72 to 2 `clone` calls
  while preserving all 36 independently published integration cases.
- Move graph count and surface-projection drift to the production-owned pure
  identity contract, retaining isolated success, base-drift, and digest-drift
  evidence with four child processes and three acquisitions.
- Require applicable repositories to select the lowest faithful evidence
  boundary, reuse equivalent deterministic setup, and fail closed on missing,
  malformed, over-budget, or cleanup-incomplete resource evidence.
- Bind reusable fixture identity to its owner source and canonical committed
  bytes/modes, verify cleanup leaves no owned resource, and ratchet every
  owner-source Git, launcher, adapter, child-process, and recursive-cleanup call
  site so an alias, unclassified Git splat, unreviewed known-owner route, or new
  bypass cannot silently restore repeated setup or skip its budget.
- Exercise the focused runtime-efficiency contract under PowerShell 7 in the
  existing Windows job while retaining the existing Linux Full route and the
  unchanged one-Windows/one-Ubuntu topology.
- Preserve imported operation-contract scalar and array types without relying
  on PowerShell 7's scalar-wrapping `Write-Output -NoEnumerate` behavior.
- Keep the stable root runner a thin discovery/profile/process orchestrator by
  delegating required, non-observing, unknown-route, and unowned operation-
  evidence enforcement to the shared test runtime.

Related work: [FEAT-0039](docs/features/FEAT-0039-v0130-test-runtime-efficiency/README.md),
`TASK-0001`, [DEC-0019](docs/decisions/DEC-0019-hosted-runner-efficiency.md),
[DEC-0022](docs/decisions/DEC-0022-release-declared-semantic-capabilities.md),
and [issue #95](https://github.com/hasanmanzak/meAndAI/issues/95). Residual
wall-clock optimization is assigned to
[`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

## 0.12.7 - 2026-07-22

### Fixed

- Resolve managed pull-request merge containment from the exact paginated
  `merged` issue event and its canonical `commit_id`, because GitHub REST API
  `2026-03-10` no longer returns `merge_commit_sha` in pull-request payloads.
- Restore ordinary/schema-2 finalization and bounded legacy installing-update
  recovery without weakening marker, repository, immutable-release,
  changed-path, branch-head, containment, or issue-finalization gates.
- Let the exact target-bound quick launcher finalize unambiguous retained merged
  branches before namespace inventory and current-update planning, so older
  finalizer failures cannot prevent installation of the corrected updater.

### Changed

- Retain one verified merged-event commit across the finalizer's existing
  pre/post-mutation state checks, avoiding repeated event reads while ordinary
  unmanaged pull requests remain no-ops.

Related work: [FEAT-0038](docs/features/FEAT-0038-v0127-api-safe-merge-finalization/README.md),
`BUG-0022`, [DEC-0016](docs/decisions/DEC-0016-managed-post-merge-finalization.md),
and [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96).

## 0.12.6 - 2026-07-21

### Added

- Discover a consumer's committed instruction topology from generic instruction
  roots and repository-relative references without adding consumer-specific
  memory paths to the shared protocol.
- Persist one canonical, exact-base instruction graph identity through local
  proposal ownership and hosted completion, then independently rebuild and
  compare it before mutation or readiness publication.

### Changed

- Bind initial-adoption classification and completion closure to the same
  bounded graph evidence while preserving the existing adoption strategy and
  change-set authorization envelope.
- Require FullMigration completion to leave only the canonical live protocol
  authority reachable from the root instruction graph; ambiguous, missing,
  unsupported, drifted, or noncanonical authority remains review-blocking.

### Fixed

- Split instruction text into physical CRLF, LF, or CR lines with one
  cross-runtime .NET regex contract so Windows PowerShell 5.1 and PowerShell 7
  cannot merge conditional and required references into one authority line.

### Security

- Protect source, binary, special-mode, and unknown-format content from graph-
  derived mutation authority, and enforce repository containment, exact casing,
  Unicode normalization, symlink/reparse safety, and deterministic resource
  limits throughout discovery and closure.

Related work: [FEAT-0037](docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md),
[DEC-0024](docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md),
and [issue #93](https://github.com/hasanmanzak/meAndAI/issues/93).

## 0.12.5 - 2026-07-20

### Fixed

- Bind a newly created managed protocol-update issue to the exact POST response
  and a direct identity read before consulting the eventually consistent issue
  inventory. A temporarily lagging list no longer reports a false creation
  failure, while a visible duplicate or mismatched canonical identity still
  fails closed.

Related work: [FEAT-0036](docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md),
`BUG-0021`, `FIND-0197`, and
[issue #89](https://github.com/hasanmanzak/meAndAI/issues/89).

## 0.12.4 - 2026-07-20

### Added

- Split the tracked quick-adoption implementation into cohesive private and
  public PowerShell module sources while retaining one exported adoption entry
  point and the existing public parameter contract.
- Add an exact source-blob deterministic builder that requires one clean source
  commit, reads the ordered inventory and payloads from that commit, and emits
  byte-identical `MeAndAI.QuickAdoption.Bundle.zip` output for repeated builds.

### Changed

- Keep one maintainer-downloaded thin `Invoke-MeAndAIQuickAdoption.ps1`, while
  each immutable release contains exactly two release assets: that launcher and
  one internal verified module bundle. The generated archive is not committed.
- Bind the launcher to its own `RuntimeReleaseTag`, independently of the
  compatible consumer target selected by `-ProtocolTag`, and verify immutable
  release, commit, asset, archive, manifest, entry-point, length, and digest
  evidence outside the consumer before module import.
- Allow a present, revalidated `MEANDAI_RO_FG_PAT.txt` to authenticate only the
  exact runtime-release read through invocation-scoped `GH_TOKEN`; restore the
  caller environment and clear the value before imported code runs. An absent
  file uses the authenticated local `gh` identity.

### Fixed

- Retry only explicitly declared idempotent GitHub API GET reads, with three
  total attempts for bounded transient transport, HTTP 408/429, and 5xx
  failures; permanent/semantic errors and every mutation remain single-attempt.
- Preserve structured GitHub issue, comment, patch, and pull-request bodies
  across Windows PowerShell 5.1 through UTF-8-no-BOM body files, and repair only
  the exact historical quote-stripped schema-2 issue after complete ownership
  and absence proof.
- Resolve the bundle builder's omitted `SourceRoot` only after script parameter
  binding so its documented direct invocation works on Windows PowerShell 5.1.

Related work: [FEAT-0036](docs/features/FEAT-0036-modular-quick-adoption-reliability/README.md),
[DEC-0023](docs/decisions/DEC-0023-verified-quick-adoption-module-bundle.md),
[TEST-0147 through TEST-0149](docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md),
`BUG-0018`, `BUG-0019`, `BUG-0020`, and
[issue #89](https://github.com/hasanmanzak/meAndAI/issues/89).

## 0.12.3 - 2026-07-20

### Added

- Emit one non-authoritative, owner-bound elapsed-millisecond observation for
  every suite process without changing child result or exit-code authority.
- Add executable `TEST-0144` through `TEST-0146` ownership for runtime
  observations, evidence-preserving hotspot optimization, and hosted topology.

### Changed

- Move deterministic adoption marker, completed-change-set, and reserved
  protocol-submodule combinations into production-owned contracts while
  retaining representative real launcher, Git, security, recovery, TOCTOU,
  credential, Codex, and native-Windows vertical slices.
- Reuse fingerprinted immutable fixture baselines through fresh isolated case
  state. On the same Windows PowerShell 5.1 machine, quick-adoption real
  launcher invocations fell from 166 to 113 and its canonical run fell from
  1055.028 to 643.7 seconds, approximately 39.0 percent.
- Retain exactly one ordinary Ubuntu job, one ordinary Windows job, and the
  isolated publication job without a matrix, fan-in runner, or elapsed-time
  pass/fail gate.

### Fixed

- Preserve empty unrelated Git configuration and the complete adoption
  proposal, asset, strategy, legacy, marker, and shard-initialization contracts
  discovered during bounded review.

Related work: [FEAT-0035](docs/features/FEAT-0035-test-runtime-efficiency/README.md),
[DEC-0019](docs/decisions/DEC-0019-hosted-runner-efficiency.md),
[DEC-0022](docs/decisions/DEC-0022-release-declared-semantic-capabilities.md),
[TEST-0144 through TEST-0146](docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md),
and [issue #87](https://github.com/hasanmanzak/meAndAI/issues/87).

## 0.12.2 - 2026-07-19

### Fixed

- Isolate managed-merge test summaries per invocation so synthetic fixture
  identities cannot leak into a caller-owned GitHub job summary.
- Treat absent event payload fields as fail-closed full-validation evidence
  instead of failing during PowerShell parameter binding.
- Reuse exact already-green merge trees on `main` only after joint Git and
  paginated GitHub evidence; retain full fail-safe validation for every direct,
  ambiguous, mismatched, failed, or unavailable push.

### Changed

- Keep pull-request, merge-queue, `main`, manual, and publication validation
  gates while making proven exact-tree `main` pushes run focused structural
  verification in the two stable jobs instead of repeating both full suites.
- Record live PR, push, hosted-check, merge, release, and cleanup facts in the
  linked issue or pull request without evidence-only candidate commits and
  their redundant workflow runs.

### Added

- Add capability-owned `TEST-0142` summary-isolation coverage and `TEST-0143`
  exact-tree routing, fail-closed negative, workflow, and evidence-discipline
  coverage.

## 0.12.1 - 2026-07-19

### Fixed

- Read local consumer migration inputs and the optional ledger from the exact
  captured base-commit Git blobs instead of checkout-filtered worktree bytes.
- Prevent clean `core.autocrlf=true` Windows checkouts from reporting false
  consumer drift while retaining committed-state, staged-result, and
  idempotency rejection gates.

### Added

- Add capability-owned `TEST-0141` coverage for canonical LF blobs, CRLF
  worktrees, present-ledger planning, genuine committed input and ledger drift,
  exact staged blobs, and an applied-state no-op rerun.

## 0.12.0 - 2026-07-19

### Added

- Add a minimal release-declared capability framework with typed immutable
  definitions, append-only catalog validation, and a separate reviewed
  consumer capability ledger.
- Add `test-architecture` as the first semantic capability, covering
  capability-based physical ownership, feature-based scenario traceability,
  deterministic recursive discovery, common runtime infrastructure, separate
  suite processes, and capability-local fixture isolation.
- Add fresh-adoption, already-current, and post-update semantic capability
  discovery with one canonical review issue, branch, transient manifest, and
  draft proposal plus evidence-based branch-first, issue-last completion.

### Changed

- Reorganize this repository's canonical suites and fixtures below
  `tests/capabilities/<capability>` while retaining
  `tests/protocol.tests.ps1` as the stable CLI and CI entry point.
- Replace root-only suite enumeration and filename-derived partial execution
  with normalized recursive owner discovery, ordinal ordering, explicit
  execution profiles, and shared result/runtime modules.
- Make an already-current quick-adoption run dispatch the installed lifecycle
  so protocol currency and semantic capability adoption cannot be conflated.
- Keep semantic capability assessment outside deterministic updater managed
  paths and outside the initial-adoption content envelope; a pre-framework
  consumer first receives its ordinary update and is assessed by the newly
  installed same-target workflow.

## 0.11.1 - 2026-07-18

### Changed

- Replace the named pre-engine consumer fixture with a minimal project-neutral
  legacy-consumer fixture using reserved `example.invalid` evidence links.
- Keep immutable `MIG-0001` and updater runtime behavior unchanged while making
  `TEST-0125` execute its documented exact no-op second plan.
- Neutralize canonical documentation and project memory through state-based
  terminology and protocol-owned issue evidence instead of consumer identity.

### Added

- Add bounded `TEST-0133` coverage for the project-neutral fixture path,
  reserved-link contract, and absence of a live consumer GitHub URL.

## 0.11.0 - 2026-07-18

### Added

- Add a maintainer-owned initial-adoption strategy gate with `FreshAdoption`,
  `FullMigration`, `HybridReconciliation`, acknowledged `CleanStart`, and
  `Abort` semantics; `Auto` selects only evidence-free fresh adoption.
- Carry the selected strategy and bounded exact-path inventory through manual
  workflow dispatch, transient manifest, proposal marker, adoption issue,
  semantic-agent prompt, recovery, and completion.
- Publish one optional, copy/reference-only stability and consistency cycle
  prompt that maintainers may use when configuring their own task or goal.

### Changed

- Stop seed-push and scheduled events from creating an unselected initial
  migration proposal while retaining completed-consumer update and
  finalization routes.
- Bound protocol-surface assessment to a declared classifier, 256 paths, and
  16 KiB; non-interactive ambiguity and inventory overflow fail closed without
  growing a universal semantic bootstrapper. Reserved protocol roots, exact
  rule-root entries, and the consumer migration ledger cannot be mistaken for
  a fresh repository.
- Make the exact immutable capabilities contract module the single pure-policy
  authority used by both the standalone launcher and workflow adapter; remove
  their copied classifiers and the launcher-to-module validator chain while
  retaining actor-specific Git/GitHub evidence and mutation-boundary checks.
- Use one normal/recovery completion envelope: deletion is limited to the
  transient manifest and exact assessed governance paths authorized by a
  migration strategy, while unauthorized application or product additions,
  modifications, type changes, and deletions are rejected.
- Recheck live repository identity, default-branch name, and exact base before
  seed, proposal, completion, and readiness publication; a concurrent branch
  rename or advance blocks, and an invocation-owned seed race is compensated
  only through an exact lease. Treat a remote as empty only when it advertises
  no branch, tag, or other ref, and verify the exact first-ref set after push.
- Re-read every launcher/bootstrap/updater-created commit before publication,
  require its exact parent, paths, modes, and source-bound blobs, and stop on a
  dirty post-commit index or working tree. Canonical target casing and every
  `.gitmodules` subsection/path collision with `.ai/protocol` fail closed.
- Accept credential inputs only as exact root regular non-link files, recheck
  their identity at read time, and suppress Git hooks for the bounded launcher
  process so consumer hooks cannot observe plaintext token sources.
- Keep the stability-cycle prompt non-normative, single-invocation, and
  report-only by default. It neither creates nor activates a goal, recurring
  task, automation, scheduler, workflow, background loop, or next invocation;
  a review-branch push requires separate explicit authority. Report-only may
  establish local convergence, but remains `Blocked` and cannot claim full
  cycle completion or `Waiting` until that final-push authority is exercised.

### Fixed

- Treat successful native-command stderr as output under Windows PowerShell
  5.1 and decide target-updater failure from the captured process exit code;
  restore the caller error preference, retain failure for every unexpected
  nonzero exit, preserve ancestry/missing-ref exits 1/2 as typed control flow,
  route every adapter Git call through that boundary, and quiet the detached
  migration-catalog checkout that exposed the defect.
- Normalize PowerShell 7's singleton-null representation of an empty protocol
  inventory without weakening fail-closed validation: a null mixed with any
  real path remains invalid, and empty initial-adoption markers round-trip on
  both Windows PowerShell and PowerShell 7.
- Raise only the serial Windows `Full` validation job's bounded timeout from
  20 to 35 minutes after the expanded suite passed its capabilities and
  updater families but was canceled by the stale limit; keep the Linux and
  post-publication limits and the single-runner topology unchanged.

Related work: [FEAT-0029](docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md),
[FEAT-0030](docs/features/FEAT-0030-v0110-stability-cycle-agent-prompt/README.md),
[DEC-0021](docs/decisions/DEC-0021-explicit-initial-adoption-strategy.md),
[TEST-0127 through TEST-0132](tests/scenario-ownership.psd1),
[issue #76](https://github.com/hasanmanzak/meAndAI/issues/76), and
[issue #77](https://github.com/hasanmanzak/meAndAI/issues/77). The resolved
PowerShell and validation corrections are `FIND-0158` through `FIND-0160`,
with amended
[TEST-0126](docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md)
plus [TEST-0124](docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md)
and [TEST-0127 / TEST-0130](docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md)
in [PR #78](https://github.com/hasanmanzak/meAndAI/pull/78).

## 0.10.4 - 2026-07-18

### Fixed

- Let the latest quick launcher recover any compatible pre-engine consumer by
  running the exact requested immutable target updater in isolated consumer and
  protocol clones, without dispatching old workflow code or changing the
  maintainer checkout.
- Produce one atomic schema-2 proposal containing the target gitlink, changed
  updater assets, all required release-declared migrations, and the ledger, so
  no knowingly red core-only merge is required.
- Retire exact legacy schema-1 drafts only after the replacement validates;
  issue-less historical drafts are cleanup-only and never receive an invented
  tracking issue.

Related correction: [FEAT-0028](docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md),
[DEC-0020](docs/decisions/DEC-0020-target-bound-current-launcher-recovery.md),
[TEST-0125 and TEST-0126](docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md),
and [issue #74](https://github.com/hasanmanzak/meAndAI/issues/74).

### Changed

- Require recurring GitHub Actions workflows to minimize total hosted runner
  consumption without weakening declared platform, runtime, safety, or
  evidence coverage.
- Replace the Windows base job, seven-child matrix, and Ubuntu fan-in runner
  with one actual Windows PowerShell 5.1 job retaining the stable
  `Validate on windows-latest` identity.
- Select `WindowsNative` for complete platform-neutral diffs and fail safe to
  `Full` for PowerShell, command-wrapper, workflow, migration, rename,
  deletion, manual, merge-queue, empty, unavailable, or oversized evidence.
- Keep Linux as the canonical full-suite authority, make focused Windows runs
  compatibility-only, and cancel only superseded runs for the same pull
  request while isolating main, manual, merge-queue, and publication runs.
- Preserve the seven focused quick-adoption shard names as local diagnostic
  entry points without paying for hosted matrix fan-out.

Related work: [FEAT-0027](docs/features/FEAT-0027-v0104-runner-minute-efficiency/README.md),
[DEC-0019](docs/decisions/DEC-0019-hosted-runner-efficiency.md),
[TEST-0123 and TEST-0124](docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md),
and [issue #72](https://github.com/hasanmanzak/meAndAI/issues/72).

## 0.10.3 - 2026-07-17

### Fixed

- Replace the source-version-specific repair with an immutable, append-only
  migration catalog, a pure state-based planner, and an exact consumer ledger
  that binds satisfied migration IDs to definition blobs.
- Include required catalog-derived consumer changes and the resulting ledger in
  the ordinary managed update proposal when the installed updater supports the
  engine; reject partial, customized, drifted, or ambiguous state before remote
  mutation.
- Handle immutable pre-engine consumers through a capability-based handoff: the
  old updater first installs the target engine, then the new workflow
  automatically opens one same-target reconciliation proposal. Fresh adoption
  starts with the target catalog recorded as satisfied.
- Preserve the sole-live-pin adoption rule and represent the duplicated-live-pin legacy-consumer regression
  as `MIG-0001` data rather than a tag-named launcher switch.
- Validate every compatible intermediate release catalog cumulatively so a
  skipped migration cannot be removed or rewritten by a later target.
- Recompute schema-2 merge evidence from immutable target and pull-request base
  blobs before cleanup, and reject linked migration leaf destinations before
  the first write.

Related work: [FEAT-0026](docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md),
[DEC-0018](docs/decisions/DEC-0018-release-declared-consumer-migrations.md),
[TEST-0119 through TEST-0122](docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md),
and [issue #69](https://github.com/hasanmanzak/meAndAI/issues/69).

## 0.10.2 - 2026-07-17

### Changed

- Replace the overloaded Windows `IntegrityFailures` compatibility shard with
  four semantic shards that initialize independent mutable baselines while
  preserving canonical `Shard=All` order and evidence.
- Keep the existing aggregate Windows check identity and require its base job
  plus all seven compatibility matrix children.
- Make an explicit post-publication verification dispatch skip the ordinary
  Linux and Windows validation matrix and run only the read-only verifier.

Related work: [FEAT-0025](docs/features/FEAT-0025-v0102-balanced-windows-validation/README.md),
[TEST-0117 and TEST-0118](docs/features/FEAT-0025-v0102-balanced-windows-validation/test-cases.md),
and [issue #67](https://github.com/hasanmanzak/meAndAI/issues/67).

## 0.10.1 - 2026-07-17

### Changed

- Keep the full Linux protocol suite as canonical executable scenario evidence
  while running Windows PowerShell 5.1 compatibility as one base job and four
  parallel quick-adoption shards behind the existing aggregate check name.
- Build the synthetic four-tag protocol repository and exact release archive
  once per quick-adoption process, reuse only that fingerprinted immutable
  fixture, and keep consumer repositories and mutable mock state isolated.
- Make partial shards emit compatibility-only results so they cannot claim the
  full canonical `TEST-*` scenario set.

Related work: [FEAT-0024](docs/features/FEAT-0024-v0101-parallel-windows-validation/README.md),
[TEST-0115 and TEST-0116](docs/features/FEAT-0024-v0101-parallel-windows-validation/test-cases.md),
and [issue #65](https://github.com/hasanmanzak/meAndAI/issues/65).

## 0.10.0 - 2026-07-17

### Added

- Let scheduled and manual consumer update discovery create or reuse the exact
  target-owned issue, create only missing Agile labels, link the issue and
  draft pull request, and carry one real `Tracking issue: #N` line without
  maintainer preparation.
- Classify repeated quick-adoption runs before mutation: current installations
  are no-ops after missing-secret reconciliation, and complete older same-major
  installations dispatch their preserved installed updater.

### Changed

- Make the protocol gitlink and its checked-out `.ai/protocol/VERSION` the sole
  live consumer pin authority, so a routine compatible update does not require
  a separate consumer-owned version-copy reconciliation.
- Close superseded or merged update work only after the exact owned branch has
  converged, and add one bounded, immutable-release-verified bridge for a
  qualifying update that installs the v0.10.0 finalizer over a legacy workflow.
- Reject partial, drifted, newer, cross-major, foreign, moved, reused, or
  ambiguous adoption/update state before the corresponding mutation boundary.

Related work: [FEAT-0023 / BUG-0011](docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md),
[TEST-0111 through TEST-0114](docs/features/FEAT-0023-v0100-idempotent-consumer-lifecycle/test-cases.md),
[DEC-0017](docs/decisions/DEC-0017-idempotent-consumer-lifecycle.md), and
[issue #63](https://github.com/hasanmanzak/meAndAI/issues/63).

## 0.9.7 - 2026-07-17

### Fixed

- Finalize an exact merged adoption or protocol-update proposal in the consumer
  workflow without expanding merge authority: lease-delete only its unchanged
  deterministic branch, then record evidence, remove transient status labels,
  and close its canonical tracking issue.
- Bind managed proposals to one non-closing `Tracking issue: #N` line and reject
  missing, duplicate, malformed, native-closing, cross-repository, reused,
  moved, or no-longer-contained merge state before mutation.
- Add an idempotent pull-request-number recovery dispatch for installing merges,
  suppressed events, and partial post-merge issue reconciliation while keeping
  schedule/update discovery on the existing consumer-scoped updater PAT.

Related work: [FEAT-0022 / BUG-0010](docs/features/FEAT-0022-v097-managed-merge-finalization/README.md),
[TEST-0108 through TEST-0110](docs/features/FEAT-0022-v097-managed-merge-finalization/test-cases.md),
[DEC-0016](docs/decisions/DEC-0016-managed-post-merge-finalization.md), and
[issue #61](https://github.com/hasanmanzak/meAndAI/issues/61).

## 0.9.6 - 2026-07-17

### Fixed

- Require GitHub CLI `2.82.1` or newer at the quick-adoption launcher's first
  prerequisite boundary, before authentication or any local or remote mutation.
- Parse exactly one canonical ASCII version line and compare unbounded decimal
  components numerically, rejecting malformed, ambiguous, leading-zero, and
  incompatible output with official upgrade guidance.
- Cover the exact floor, older client, later client, multi-digit component, and
  fail-closed side-effect ordering in the existing quick-adoption suite.

Related work: [FEAT-0021 / BUG-0009](docs/features/FEAT-0021-v096-github-cli-prerequisite/README.md),
[TEST-0107](docs/features/FEAT-0021-v096-github-cli-prerequisite/test-cases.md), and
[issue #59](https://github.com/hasanmanzak/meAndAI/issues/59).

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
