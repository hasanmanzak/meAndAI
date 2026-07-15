# 2026-07-15 - Quick Adoption Launcher

## Context

- Work item: [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md)
- Decision: [DEC-0007](../../../docs/decisions/DEC-0007-local-quick-adoption-boundary.md)
- Tracking: [issue #19](https://github.com/hasanmanzak/meAndAI/issues/19)
- Delivery: pull request pending
- Target release: `v0.6.0`

## Durable outcome

- One source-only PowerShell launcher owns deterministic local seed setup; it
  is not copied into consumers and does not replace the lifecycle workflow.
- A clean connected consumer is validated against its GitHub default branch.
  A directory without a repository or origin is initialized on `main` and gets
  a private GitHub repository by default.
- `FG_PAT.txt` and `MEANDAI_RO_FG_PAT.txt` map only to
  `MEANDAI_UPDATER_TOKEN` and `MEANDAI_PROTOCOL_TOKEN`. Values use stdin, stay
  out of Git and output, and tracked/history exposure blocks with rotation.
- The launcher verifies the exact tagged source blob, reconciles both secrets
  before publication, and commits and pushes only the seed workflow.
- After publication, the launcher dispatches and waits for the exact lifecycle
  run, then posts one marker-protected `@codex` task to the deterministic draft.
  Codex Cloud owns semantic adoption; final evidence review and merge remain
  maintainer operations.

## Verification and continuation

- `TEST-0033` through `TEST-0037` cover source and credential contracts,
  existing and new repositories, exact rerun, collision failure, and handoff.
- The 2026-07-15 Windows PowerShell 5.1 full run passed `TEST-0001` through
  `TEST-0037`; bounded review findings `FIND-0053` through `FIND-0055` were
  resolved with no remaining actionable in-scope finding.
- The predecessor lifecycle was delivered by merged
  [pull request #18](https://github.com/hasanmanzak/meAndAI/pull/18) and tag
  [`v0.5.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.5.0) before FEAT-0006.
- Complete the bounded FEAT-0006 review, merge its delivery pull request, then
  tag the merged `main` commit as `v0.6.0`.
