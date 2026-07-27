# FEAT-0058 Test Scenarios and Evidence

No new numbered scenario is introduced. The correction adds completed-
historical lifecycle variants to the canonical adoption-issue ownership
scenario.

| Existing ID | Slice | Action | Expected result | Relationship | State |
| --- | --- | --- | --- | --- | --- |
| [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) | [SUBF-0118](README.md#subf-0118) | Reconcile a current adoption while the anonymous project-neutral repository contains one exact completed historical issue, its same-repository merged terminal-marker pull request, and no historical reserved branch; rerun and exercise every partial, competing, malformed, unsupported, provider-failure, ambiguity, and bound variant. | Complete proof classifies only the old record as `CompletedHistorical`, never mutates it, reconciles one current issue, reaches Codex, and converges on rerun. Every negative fails before any local or provider mutation. | `ParameterizedVariant`; nearest same-contract sibling is [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) itself, with the same ownership contract, fail-closed risk, integration evidence level, and launcher boundary; historical lifecycle state is the varied parameter. | Passed on PowerShell 7 and Windows PowerShell 5.1 |
| [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176) | [SUBF-0118](README.md#subf-0118) | Retain current canonical and current-target legacy exact generated-body/link variants while historical bodies are classified. | Current issue migration and visible references remain exact; historical issue bytes remain unchanged. | Related retained evidence; not a new scenario | Passed as retained regression |

## Required variant matrix

- Positive: exact completed historical legacy issue, immutable older target,
  same-repository merged terminal-marker pull request, absent exact branch,
  current deterministic draft, exact-once current issue, Codex reachable, and
  idempotent rerun.
- Issue negatives: open, non-completed disposition, wrong title/body/URL/PR,
  duplicate marker, marker-only, quoted, displaced, leading-space, case
  variant, malformed version, unsupported or unreconstructable family, and
  candidate bound exhaustion.
- Pull-request negatives: missing, open, unmerged, cross-repository, wrong
  base/head/target/protocol commit/repository/actor, malformed or nonterminal
  marker, duplicate identity, provider failure, and malformed open-PR list
  roots or rows (`null`, object root, null row, and missing properties).
- Authority negatives: retained exact reserved branch, ambiguous issue or PR
  evidence, cross-major target, immutable-release failure, and evidence drift
  at pre-mutation revalidation.
- Classification-only matrix cases assert expected acceptance or rejection, permitted
  read-call sequence and arguments, and zero unexpected calls; those support
  routes do not load any mutation owner. Four representative full-launcher
  negatives span local grammar rejection, provider failure, live historical
  authority, and late frozen-inventory drift. Each snapshots issue and label
  inventory, historical and current pull-request state, branch refs, consumer
  HEAD/status, workflow state, mutation-call counters, and Codex calls and
  proves byte-identical zero mutation.

## Evidence

| Date | Commit / tree | Environment | Command | Result |
| --- | --- | --- | --- | --- |
| 2026-07-27 | [Exact v0.15.5 baseline](https://github.com/hasanmanzak/meAndAI/commit/11c56aac369767202835c4e9d6cc83aa321f4070) plus [TEST-0069](../FEAT-0012-v082-correction/test-cases.md#test-0069) variant only | PowerShell 7 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityManifestIssue` | Expected red in 175.6 seconds: the only reported failure was the historical fixture receiving the exact v0.15.5 malformed-marker rejection. |
| 2026-07-27 | Final frozen implementation worktree | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityManifestIssue`; `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityManifestIssue` | Passed in 141.9 / 147.7 seconds with the full completed-historical matrix, private protocol-read authority, frozen-state and zero-mutation oracles, exact manifest object-root rejection, fail-closed open-PR list root/row/property shapes, retained [TEST-0176](../FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176), and idempotent convergence. |
| 2026-07-27 | Final frozen implementation worktree | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard AdoptionLifecycle`; `powershell.exe -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard AdoptionLifecycle` | Passed in 194.9 / 202.4 seconds with current canonical/legacy retention, state-safe unmarked rows, exact drift diagnostics, idempotent recovery, and the final ready-state base-race revalidation. |
| 2026-07-27 | Corrected candidate worktree | PowerShell 7 / Windows PowerShell 5.1 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityMetadataCredential`; `powershell.exe -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityMetadataCredential`; `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityCodexFailure`; `powershell.exe -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard IntegrityCodexFailure` | Metadata/credential/FullMigration passed in 220.3 / 231.9 seconds; Codex-failure and independent workflow-run fixtures passed serially in 176.0 / 179.2 seconds. These runs prove that fresh attempts remove PR/branch and issue authority together while true recovery paths retain their exact issue. |
| 2026-07-27 | Corrected candidate worktree | PowerShell 7 | `pwsh -NoProfile -File tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard All` | Passed all declared quick-adoption scenarios in 847.1 seconds with the completed-historical matrix, exact JSON object-root rejection, independent fixture authority, FullMigration, Codex-failure, and managed-consumer routes in one process. |
| 2026-07-27 | Final frozen implementation worktree | PowerShell 7 / Windows PowerShell 5.1 | Relevant bundle, runtime-efficiency, source-graph dispatch, role-boundary, architecture, recurrence-prevention, governance, and publication-evidence owners | All applicable owners passed. Bundle: 27.3 / 28.9 seconds; runtime: 7.7 / 8.9 seconds; source graph: 4.9 / 5.7 seconds; publication evidence: 106.6 / 194.1 seconds. PowerShell 7 role, architecture, recurrence, and governance passed in 19.6, 2.9, 1.1, and 124.0 seconds. |
| 2026-07-27 | [`7856697dc8733449bf907dfb47af77486dd8dee6`](https://github.com/hasanmanzak/meAndAI/commit/7856697dc8733449bf907dfb47af77486dd8dee6) | PowerShell 7 canonical full profile | `pwsh -NoProfile -File tests/protocol.tests.ps1` | Passed every discovered suite in 1732.8 seconds. Exact owner evidence included quick adoption 844.371 seconds, instruction graph 129.840 seconds with 2/2 process starts and 4/4 blob requests, governance 121.801 seconds, publication evidence 100.484 seconds, and runtime efficiency 7.038 seconds. |
