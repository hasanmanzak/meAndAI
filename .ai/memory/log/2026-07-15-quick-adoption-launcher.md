# 2026-07-15 - Quick Adoption Launcher

## Context

- Work item: [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md)
- Decision: [DEC-0007](../../../docs/decisions/DEC-0007-local-quick-adoption-boundary.md)
- Tracking: [issue #19](https://github.com/hasanmanzak/meAndAI/issues/19)
- Delivery: [pull request #20](https://github.com/hasanmanzak/meAndAI/pull/20)
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

- [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md) cover source and credential contracts,
  existing and new repositories, exact rerun, collision failure, and handoff.
- The 2026-07-15 Windows PowerShell 5.1 full run passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0018](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0019](../../../docs/features/FEAT-0003-convergent-completion-scan/test-cases.md), [TEST-0020](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0021](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0022](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0023](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0024](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0025](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), and [TEST-0026](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0027](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0028](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0029](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0030](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0031](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), and [TEST-0032](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), and [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md); bounded review findings [FIND-0053](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md), [FIND-0054](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md), and [FIND-0055](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md) were
  resolved with no remaining actionable in-scope finding.
- The predecessor lifecycle was delivered by merged
  [pull request #18](https://github.com/hasanmanzak/meAndAI/pull/18) and tag
  [`v0.5.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.5.0) before [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md).
- Complete the bounded [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md) review, merge its delivery pull request, then
  tag the merged `main` commit as `v0.6.0`.
