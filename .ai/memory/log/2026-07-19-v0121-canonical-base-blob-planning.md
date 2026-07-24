# 2026-07-19 - v0.12.1 Canonical Base-Blob Migration Planning

- Feature: [FEAT-0033](../../../docs/features/FEAT-0033-canonical-base-blob-migration-planning/README.md)
- Decisions: [DEC-0018](../../../docs/decisions/DEC-0018-release-declared-consumer-migrations.md), [DEC-0020](../../../docs/decisions/DEC-0020-target-bound-current-launcher-recovery.md)
- Tracking: [issue #83](https://github.com/hasanmanzak/meAndAI/issues/83)
- Pull request: [#84](https://github.com/hasanmanzak/meAndAI/pull/84)
- Target version: `0.12.1`

## Durable continuation

- The exact captured consumer base commit remains the sole local migration-
  planning authority. Each required input and the optional ledger are read as
  binary bytes from its validated regular Git blob, never from checkout-
  filtered worktree bytes.
- The worktree remains required as a contained regular-file write destination.
  Its Git clean-filtered blob must still equal the captured base blob, so CRLF
  smudging is accepted without hiding semantic worktree drift. Staged-result,
  committed-result, proposal-tree, default-head, and remote-head gates remain
  fail closed.
- The remote finalizer already reads canonical GitHub blob bytes and is not
  routed through the local worktree reader.
- [TEST-0141](../../../docs/features/FEAT-0033-canonical-base-blob-migration-planning/test-cases.md) lives in the consumer-update capability, uses project-neutral
  isolated real Git repositories, and covers `core.autocrlf=true`, absent
  `.gitattributes`, LF committed blobs, CRLF worktree files, present-ledger
  planning, genuine committed input and ledger drift, exact staged blobs, and
  an applied-state no-op rerun.
- The immutable migration and capability catalogs are unchanged. This is a
  generic adapter-boundary correction, not a named-consumer or source-version
  migration.

## Current evidence

- The executable regression first failed on the previous worktree reader with
  `Consumer migration ledger must use LF line endings.` in a clean filtered
  checkout.
- After the binary base-blob correction, the complete focused adapter fixture,
  including all existing scenarios and [TEST-0141](../../../docs/features/FEAT-0033-canonical-base-blob-migration-planning/test-cases.md), passed in 52.2 seconds on
  Windows PowerShell 5.1.
- The complete consumer-update owner suite passed all 27 scenarios in 56.2
  seconds after the bounded self-review correction.
- Candidate `3eff1b0048bbc3371c4a028a198717598d1bff66` passed [hosted run
  29686946514](https://github.com/hasanmanzak/meAndAI/actions/runs/29686946514):
  Ubuntu in 7m41s, Windows PowerShell 5.1 in 29m37s, and GitGuardian in 2s.
- Merge, immutable-release, cleanup, and post-publication evidence remains
  pending until those facts exist.
