# 2026-07-15 - Protocol Stability Invariants

## Scope

- Feature: [FEAT-0010](../../../docs/features/FEAT-0010-protocol-stability-invariants/README.md)
- Decision: [DEC-0010](../../../docs/decisions/DEC-0010-stable-automation-invariants.md)
- Tracking: [issue #34](https://github.com/hasanmanzak/meAndAI/issues/34)
- Branch: `codex/protocol-stability-invariants`
- Target: `0.8.0`

## Durable decisions and implementation state

- Executable bootstrap sources and updater targets require an exact published
  immutable GitHub Release. A tag alone is only a version label. Repository
  release immutability was enabled and re-read as `enabled: true` through the
  GitHub API on 2026-07-15.
- Adoption proposals use explicit proposed/completed marker phases, exact live
  PR/ref validation, complete managed-tree evidence, and idempotent recovery.
- Workflow dispatch binds one unseen run ID; protected paths and `.gitmodules`
  are ordinal and case-sensitive; credential checks cover the index plus local
  refs/reflogs and reject shallow repositories without claiming unseen remote
  history.
- Supersession validates the replacement and old proposal around close/delete,
  uses an exact-head lease, verifies the result, and compensates when continuity
  is lost.
- Repository validation derives record and child-suite coverage from canonical
  indexes and root Git inventory. CI is explicitly bounded to 20 minutes.
- Derivative-drift controls keep the bootstrap validator behind cohesive
  evidence seams, compare active template/test pins with the canonical version,
  and store exact release-target evidence outside the self-referential commit.

## Evidence and continuation

- Launcher integration passed through `TEST-0056` in 115 seconds on Windows
  PowerShell 5.1 after bounded test-fixture corrections.
- Bootstrap and updater adapter suites passed `TEST-0057` and `TEST-0058`.
- The structure-only repository gate passed `TEST-0059`.
- The bounded fresh-diff scan resolved `FIND-0089` through `FIND-0091` without
  adding another bootstrap layer.
- The complete parent command passed all child suites, then exposed an
  over-broad active-pin predicate and the hidden bootstrap adapter's stale
  default. The minimal correction passed `git diff --check` and the final
  structure-only `TEST-0059` confirmation.
- Remaining gates: hosted matrix CI, pull-request review/merge, and an
  immutable `v0.8.0` release targeting the exact merge commit. Release
  identifier and commit evidence must stay pending until those events occur.
