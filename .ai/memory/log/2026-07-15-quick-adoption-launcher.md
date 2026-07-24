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

- [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0033), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0034), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0035), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0036), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0037) cover source and credential contracts,
  existing and new repositories, exact rerun, collision failure, and handoff.
- The 2026-07-15 Windows PowerShell 5.1 full run passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../../../docs/features/FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), [TEST-0027](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032), and [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0033), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0034), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0035), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0036), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0037); bounded review findings [FIND-0053](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md#find-0053), [FIND-0054](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md#find-0054), and [FIND-0055](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md#find-0055) were
  resolved with no remaining actionable in-scope finding.
- The predecessor lifecycle was delivered by merged
  [pull request #18](https://github.com/hasanmanzak/meAndAI/pull/18) and tag
  [`v0.5.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.5.0) before [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md).
- Complete the bounded [FEAT-0006](../../../docs/features/FEAT-0006-quick-adoption-launcher/README.md) review, merge its delivery pull request, then
  tag the merged `main` commit as `v0.6.0`.
