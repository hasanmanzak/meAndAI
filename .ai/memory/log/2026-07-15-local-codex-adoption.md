# 2026-07-15 - Local Codex Adoption Completion

## Context

- Work item: [FEAT-0007](../../../docs/features/FEAT-0007-local-codex-adoption/README.md)
- Decision: [DEC-0008](../../../docs/decisions/DEC-0008-local-codex-execution.md)
- Tracking: [issue #21](https://github.com/hasanmanzak/meAndAI/issues/21)
- Delivery: [pull request #22](https://github.com/hasanmanzak/meAndAI/pull/22)
- Target release: `v0.6.1`

## Durable outcome

- Quick adoption no longer requires or invokes a hosted GitHub-agent
  connection and creates no `@codex` comment.
- Repository creation, two fixed Actions secrets, seed publication, lifecycle
  dispatch, and exact-run waiting remain deterministic launcher operations.
- Local Codex runs only when the lifecycle leaves a transient adoption
  manifest. It uses the installed CLI or pinned temporary npm fallback in a
  clone of the draft's exact `headRefOid`, under a finite process timeout.
- The launcher reconciles the common Agile labels and one canonically marked
  adoption issue. Codex receives the issue URL but its spawned commands have
  network disabled and cannot own GitHub publication.
- The clone excludes both credential files. The prompt names their mappings
  only to state that provisioning is complete and credential access is out of
  scope.
- The launcher requires an unchanged agent head, manifest removal, a valid
  non-empty diff, protected-path preservation, an unchanged remote ref, and an
  expected-head lease before it commits and pushes. It marks the PR ready but
  never approves or merges it.
- If the manifest is already absent in a draft, the launcher leaves readiness
  unchanged because it has no provenance for the prior completion.

## Verification and continuation

- `TEST-0038` through `TEST-0041` cover the local runner contract, timeout and
  network boundary, label/issue reconciliation, isolated success,
  authentication/manifest/commit/race failures, unverified-draft handling,
  idempotency, and v0.6.1 regression metadata.
- The full Windows PowerShell 5.1 suite passed `TEST-0001` through `TEST-0041`
  in 94.4 seconds on 2026-07-15. PR #22 commit `9191cb0` then passed the
  [Ubuntu, Windows, and GitGuardian checks](https://github.com/hasanmanzak/meAndAI/actions/runs/29418825486).
- FEAT-0007 is complete. Merge PR #22, tag the resulting `main` commit as
  `v0.6.1`, and verify the remote tag before ending the release operation.
