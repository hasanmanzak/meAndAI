# 2026-07-27 - v0.15.6 Completed Historical Adoption Issues

## Scope

[FEAT-0058](../../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md),
[SUBF-0118](../../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md#subf-0118),
[BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149), and
[issue #149](https://github.com/hasanmanzak/meAndAI/issues/149), with delivery
through [PR #152](https://github.com/hasanmanzak/meAndAI/pull/152), own the common,
project-neutral v0.15.6 correction. A named consumer exposed the defect but is
evidence only; no consumer-local workaround, fixture, or regression belongs in
this release.

## Immutable baseline

- Release: [v0.15.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.5)
- Commit: [`11c56aac369767202835c4e9d6cc83aa321f4070`](https://github.com/hasanmanzak/meAndAI/commit/11c56aac369767202835c4e9d6cc83aa321f4070)
- Delivery: [PR #148](https://github.com/hasanmanzak/meAndAI/pull/148)
- Expected red: the exact baseline plus only the new
  [TEST-0069](../../../docs/features/FEAT-0012-v082-correction/test-cases.md#test-0069)
  parameter rejected a valid completed historical issue as malformed in 175.6
  seconds.

## Owned correction

- The canonical issue inventory classifies `CurrentCanonical`,
  `CurrentLegacy`, `CompletedHistorical`, `Competing`, `Malformed`, and
  `Unmarked` records without creating a second lifecycle owner.
- Strict local grammar and an eight-candidate ceiling precede provider access.
  Supported historical proof is limited to the inventoried v0.8.0-v0.10.4
  legacy profile-A issue body and schema-3 terminal pull-request family.
- Complete proof binds exact issue metadata, immutable release commit,
  same-repository merged pull request, target, actor, terminal marker, absent
  open pull request, and absent reserved branch. Unsupported, partial,
  ambiguous, drifting, or provider-failing evidence remains fail closed.
- One pre-mutation snapshot freezes historical metadata. Later inventory reads
  must match its fingerprint before the next mutation and never repeat remote
  historical proof as a retry.
- Completed historical issues remain byte- and metadata-identical; only the
  existing current issue path may converge.

## Compatibility and version boundary

- The v0.15.5 immutable workflow and schema-2 policy remain separate retained
  evidence. v0.15.6 is the current runtime/target and v0.15.7 is the synthetic
  future-negative fixture.
- The reviewed instruction-graph schema-2 profile spans exact v0.15.5-v0.15.6
  without changing its 524,288-byte blob, 512-node, 4,096-edge, or 32,768-byte
  path limits.
- Current opaque and current-target legacy issue behavior, proposal creation,
  merge authority, secret handling, instruction-graph semantics, and managed
  update behavior are unchanged.

## Current evidence

- The focused `IntegrityManifestIssue` shard passes on PowerShell 7 / Windows
  PowerShell 5.1 in 156.1 / 162.6 seconds. It covers the six classes, all 20
  supported tag-to-commit identities, exact 8/9 candidate bounds, 999/1000
  inventory behavior, provider and marker negatives, frozen drift, full-
  launcher zero-mutation boundaries, and positive idempotence.
- [TEST-0147](../../../docs/features/FEAT-0036-modular-quick-adoption-reliability/test-cases.md#test-0147)
  bundle verification passes on PowerShell 7 / Windows PowerShell 5.1 in 27.3
  / 28.9 seconds. Runtime-efficiency passes in 7.7 / 8.9 seconds and retained/
  current source-graph dispatch passes in 4.9 / 5.7 seconds. PowerShell 7 role-
  boundary, architecture, recurrence-prevention, and governance owners pass in
  19.6, 2.9, 1.1, and 124.0 seconds; publication evidence passes without a
  published-state claim on both runtimes in 106.6 / 194.1 seconds.
- Production and test reviews found and corrected the initial late-proof
  mutation-order defect, issue-response shape gaps, ambient target identity,
  per-issue malformed-state leakage, case-sensitive repository comparison,
  weak zero-mutation oracles, missing frozen-flow proof, and incomplete
  candidate/provider matrices. Final review also corrected the test-owned drift
  mutation and forwarded the private-protocol read token through the complete
  historical release-proof chain without persisting credential material.
- Canonical quick-adoption convergence then exposed and closed detached parser-
  helper extraction, a stale current-version oracle, state access on unmarked
  rows, cumulative race-fixture timing, partial PR/issue fixture resets, and a
  root-array type-conversion leak. Fresh attempts now reset PR/branch and issue
  authority together, recovery attempts retain both, and non-object manifest
  roots reach the exact canonical contract error.
- The full PowerShell 7 quick-adoption owner passed every declared scenario in
  one process in 847.1 seconds. The affected metadata/FullMigration and Codex-
  failure shards also pass on PowerShell 7 / Windows PowerShell 5.1 in 220.3 /
  231.9 and 176.0 / 179.2 seconds. The retained `AdoptionLifecycle` shard
  passes on the final candidate in 194.9 / 202.4 seconds.
- Exact candidate commit
  [`7856697dc8733449bf907dfb47af77486dd8dee6`](https://github.com/hasanmanzak/meAndAI/commit/7856697dc8733449bf907dfb47af77486dd8dee6)
  passes every discovered canonical local suite in 1732.8 seconds. The run
  records quick adoption at 844.371 seconds, instruction graph at 129.840
  seconds with 2/2 process starts and 4/4 blob requests, governance at 121.801
  seconds, publication evidence at 100.484 seconds, and runtime efficiency at
  7.038 seconds.
- Final fresh-diff review, structural convergence, exact committed-HEAD graph
  validation of the evidence-only finalization, hosted checks, immutable
  publication, post-publication verification, issue closure, and owned-branch
  cleanup remain delivery gates.

## Safe continuation

Keep [BUG-0036](https://github.com/hasanmanzak/meAndAI/issues/139) sequenced
after this overlapping ownership correction. Do not begin consumer recovery as
part of this release. Before publication, commit every new governance record so
the PowerShell 7 and Windows PowerShell 5.1 instruction-graph owners inspect the
exact candidate HEAD rather than an untracked worktree projection.
