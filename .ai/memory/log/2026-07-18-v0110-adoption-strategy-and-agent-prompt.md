# 2026-07-18 - v0.11.0 Adoption Strategy and Optional Agent Prompt

## Scope

- [FEAT-0029](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md)
  adds a maintainer-owned strategy gate for initial adoption.
- [DEC-0021](../../../docs/decisions/DEC-0021-explicit-initial-adoption-strategy.md)
  defines fresh, full-migration, hybrid, clean-start, abort, inventory, and
  authority semantics.
- [FEAT-0030](../../../docs/features/FEAT-0030-v0110-stability-cycle-agent-prompt/README.md)
  publishes a non-normative prompt that maintainers may copy or reference for
  one bounded stability cycle without activating a task or goal.

## Durable implementation facts

- The quick launcher authenticates read-only, verifies the immutable v0.11.0
  capabilities contract module, and then assesses exact committed paths before
  any repository or GitHub adoption mutation. `Auto` selects only
  evidence-free `FreshAdoption`; evidence-bearing non-interactive runs require
  an explicit strategy.
- That exact module is the single pure-policy authority for the launcher and
  workflow adapter. Actor-specific Git/GitHub evidence and mutation-boundary
  checks remain independent, but copied classifiers and classifier-to-
  classifier validation are prohibited.
- The bounded classifier recognizes a declared protocol/governance surface and
  stops above 256 exact paths or 16 KiB of UTF-8 path inventory. It does not
  parse documents or infer migration semantics. Reserved `.ai/protocol`
  roots, exact active-rule roots, and `.ai/meandai-update-state.json` are
  migration evidence; ambiguous product/governance records remain read-only.
- GitHub path-specific Copilot instructions below `.github/instructions/` are
  included in the declared active-rule inventory and migration authority
  boundary; they cannot be left as an unnoticed parallel instruction source.
- New initial proposals bind strategy, exact sorted surfaces, and clean-start
  loss acknowledgement in manifest schema 2 and proposal marker schemas 5/6.
  Issue, prompt, rerun, and completion validation preserve the same tuple.
- Seed-push and scheduled events do not create an unselected initial migration
  proposal. Completed consumers retain their existing current/update route.
- Local semantic completion may delete only the transient manifest and exact
  assessed governance paths authorized by a migration strategy. One shared
  normal/recovery completion envelope rejects unauthorized application or
  product addition, modification, type change, and deletion.
- Seed, workflow proposal, local completion, and updater commits are validated
  again from committed Git trees before publication. Live repository/default
  branch identity, exact casing, reserved submodule ownership, clean
  index/worktree state, and lease-bounded race compensation fail closed.
- Empty-remote routing means zero advertised refs, including tags. The
  launcher rechecks that boundary before external mutation and seed
  publication; post-first-push drift permits compensation only for the exact
  launcher-owned default ref.
- Credential inputs are exact root regular non-link files and are revalidated
  at read time. The launcher appends one process-only empty `core.hooksPath`
  override and restores the previous Git configuration environment in its
  outer `finally`, so launcher-owned Git operations cannot execute consumer or
  global hooks while token files are present.
- The target updater adapter treats native stderr as output, not failure. Its
  native wrapper temporarily uses `ErrorActionPreference=Continue`, captures
  the process exit code, restores the caller preference in `finally`, and
  throws unless that code is explicitly accepted. Every adapter Git call uses
  the wrapper; ancestry false and missing-ref exits 1/2 remain typed control
  flow while every unexpected nonzero exit stops. The migration-catalog
  detached checkout is quiet; this resolves the Windows PowerShell 5.1 failure
  recorded as [FIND-0158](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0158) without changing immutable v0.10.4 assets.
- The capabilities classifier treats only a sole null/empty-collection
  sentinel as an empty inventory. This normalizes PowerShell 7/Linux parameter
  binding for empty schema-5/6 adoption markers while continuing to reject a
  null mixed with any real repository path. The hosted defect and correction
  are recorded as [FIND-0159](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0159) under existing [TEST-0127](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0127) and [TEST-0130](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0130).
- The single Windows validation job has a 35-minute bound after the expanded
  serial `Full` suite passed capabilities and updater compatibility but hit its
  stale 20-minute ceiling. Linux remains bounded at 20 minutes and
  post-publication at 5; no runner, matrix, setup, profile, or coverage route
  was added. This is [FIND-0160](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0160) under existing [TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124).
- The canonical stability-cycle prompt lives at
  [docs/agent-prompts/stability-and-consistency-cycle.md](../../../docs/agent-prompts/stability-and-consistency-cycle.md). It is single-run,
  report-only by default, and cannot create or schedule its next invocation.
  Report-only may establish local convergence but leaves the normative cycle
  incomplete and `Blocked` until authorized final-push authority exists.

## Evidence and continuation

- [TEST-0127](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0127) and [TEST-0128](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0128) pass their resolver and adapter owners, including
  the 466.6-second full adapter suite after the single-policy refactor.
- [TEST-0129](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0129) and [TEST-0130](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/test-cases.md#test-0130) pass five focused launcher shards and the combined
  `-Shard All` harness in 1107 seconds, including cross-shard fixture isolation.
- [TEST-0131](../../../docs/features/FEAT-0030-v0110-stability-cycle-agent-prompt/test-cases.md#test-0131) and [TEST-0132](../../../docs/features/FEAT-0030-v0110-stability-cycle-agent-prompt/test-cases.md#test-0132) pass the final 2.5-second structure-only protocol
  suite after local convergence was separated from authorized full completion.
- The amended [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126) real-Git fixture reproduced [FIND-0158](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0158) under Windows
  PowerShell 5.1 in 3.5 seconds and initially passed in 3.6 seconds. Self-review
  then exposed three direct Git bypasses with an expected 3.7-second red; the
  final unrestricted 5.0-second pass covers exact HEAD, error-preference
  restoration, real ancestry/remote exits 0/1/2, invalid ancestry/remote
  failure, unexpected-nonzero rejection, and no direct bypass.
- The complete `tests/protocol-update.tests.ps1` updater family passed outside
  the process sandbox in 34.8 seconds with every declared adapter scenario and
  canonical [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126) ownership green. Two preceding sandboxed attempts
  reached only the known Git-for-Windows `sh.exe` signal-pipe error 5 in the
  unchanged [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0125) clone fixture; the identical unrestricted run passed.
- Ubuntu run `29651797496` supplied the expected-red [FIND-0159](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md#find-0159) evidence at
  commit [`617d1b0`](https://github.com/hasanmanzak/meAndAI/commit/617d1b0a37ec1e2705abf8beea4c5ed775dc431f): capabilities and quick adoption both rejected the same
  empty inventory representation. After the correction, the complete
  capabilities/adapter family passed locally in 461.7 seconds and the focused
  `AdoptionLifecycle` quick shard passed in 160.3 seconds. Replacement Ubuntu
  run `29653339317` passed in 7 minutes 33 seconds.
- Windows run `29653339317` selected the required `Full` profile and passed the
  capabilities and protocol-update families, including the real PowerShell
  5.1 [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md#test-0126) regression, before GitHub canceled the still-running
  quick-adoption family at the old 20-minute bound without a test failure.
  The [TEST-0124](../../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124) structure gate then failed first against 20 and passed in
  2.6 seconds after the Windows-only 35-minute correction; replacement hosted
  Windows evidence remains required from the follow-up commit.
- The complete repository suite passes in 1576 seconds with every discovered
  suite and canonical scenario owner green before that documentation-and-
  assertion-only clarification. Fresh-diff review and bounded post-development
  confirmation report no unresolved `Blocking` finding.
- [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76) and
  [issue #77](https://github.com/hasanmanzak/meAndAI/issues/77) own delivery and
  post-publication facts; [PR #78](https://github.com/hasanmanzak/meAndAI/pull/78)
  is the current draft. Checks, review, merge, branch cleanup, immutable
  release, asset, and post-publication verification remain pending until they
  exist.
