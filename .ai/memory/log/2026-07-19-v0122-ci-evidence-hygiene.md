# 2026-07-19 - v0.12.2 CI Evidence Hygiene and Exact-Tree Reuse

- Feature: [FEAT-0034](../../../docs/features/FEAT-0034-ci-evidence-hygiene/README.md)
- Decisions: [DEC-0019](../../../docs/decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../../docs/decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Tracking and external publication authority: [issue #85](https://github.com/hasanmanzak/meAndAI/issues/85)
- Delivery pull request: recorded through issue #85 after creation; no evidence-only candidate commit
- Target version: `0.12.2`

## Durable continuation

- `GITHUB_STEP_SUMMARY` is caller-owned state. The managed-merge fixture gives
  every invocation a unique temporary summary, captures its lines, restores
  the prior environment value in `finally`, and removes the temporary file.
  Synthetic PR, issue, and SHA values never reach an outer hosted summary.
- Private `main` remains unprotected, so `push: main` and both stable validation
  job identities remain. Exact-tree reuse is allowed only for an exact green
  merge-queue commit or one exact merged PR with verified before/after parents,
  base/head identity, merge-tree/head-tree equality, current workflow, and both
  stable jobs successful.
- The resolver is read-only, exhausts GitHub pagination, and returns only
  `ReuseExactValidatedTree` or `Full`. Every direct, squash, rebase, forced,
  mismatched, duplicated, failed, canceled, malformed, missing, or API-error
  case returns `Full`.
- A reusable tree runs `StructureOnly` inside the same Linux and Windows jobs.
  It does not remove a trigger, rename a required check, add fan-out, or treat
  a similar diff as prior evidence.
- PR numbers, exact push/check/merge/release facts, and cleanup evidence belong
  in issue #85 or the delivery pull request. A converged candidate does not get
  a commit whose only purpose is copying those later external facts.
- `TEST-0142` stays with the consumer-update finalization owner. `TEST-0143`
  uses the workflow-efficiency capability with real isolated Git graphs and an
  injected project-neutral GitHub evidence provider.

## Current evidence

- Before correction, `TEST-0142` reproduced eight synthetic finalization lines
  in its inherited outer summary and had no per-invocation capture.
- Before correction, `TEST-0143` reported the missing resolver, short route,
  and external-evidence rule.
- After correction, both focused capability owners, recursive discovery,
  test-architecture isolation, protocol governance, and the Windows profile
  selector pass locally. The final full Windows PowerShell validation passed
  all discovered suites in 1609.5 seconds outside the restricted workspace
  sandbox; the sandboxed attempt was invalid because Git for Windows could not
  create local clone signal pipes (`Win32 error 5`). Hosted, merge,
  immutable-release, cleanup, and post-publication evidence is recorded later
  through issue #85.
