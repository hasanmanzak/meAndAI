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

- [TEST-0038](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0038), [TEST-0039](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0039), [TEST-0040](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0040), and [TEST-0041](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0041) cover the local runner contract, timeout and
  network boundary, label/issue reconciliation, isolated success,
  authentication/manifest/commit/race failures, unverified-draft handling,
  idempotency, and v0.6.1 regression metadata.
- The full Windows PowerShell 5.1 suite passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0001), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0002), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0003), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0005), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0006), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0007), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0008), [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0009), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0010), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0011), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0012), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0013), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0014), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0015), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0016), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0017), [TEST-0018](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0018), [TEST-0019](../../../docs/features/FEAT-0003-convergent-completion-scan/test-cases.md#test-0019), [TEST-0020](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0020), [TEST-0021](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md#test-0021), [TEST-0022](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0022), [TEST-0023](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0023), [TEST-0024](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0024), [TEST-0025](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0025), and [TEST-0026](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md#test-0026), [TEST-0027](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0027), [TEST-0028](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0028), [TEST-0029](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0029), [TEST-0030](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0030), [TEST-0031](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0031), and [TEST-0032](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md#test-0032), [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0033), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0034), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0035), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0036), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md#test-0037), and [TEST-0038](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0038), [TEST-0039](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0039), [TEST-0040](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0040), and [TEST-0041](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md#test-0041)
  in 94.4 seconds on 2026-07-15. [PR #22](https://github.com/hasanmanzak/meAndAI/pull/22) commit [`9191cb0`](https://github.com/hasanmanzak/meAndAI/commit/9191cb07731e1286cf7735e0d37fa4fe75863b50) then passed the
  [Ubuntu, Windows, and GitGuardian checks](https://github.com/hasanmanzak/meAndAI/actions/runs/29418825486).
- [FEAT-0007](../../../docs/features/FEAT-0007-local-codex-adoption/README.md) is complete. Merge [PR #22](https://github.com/hasanmanzak/meAndAI/pull/22), tag the resulting `main` commit as
  `v0.6.1`, and verify the remote tag before ending the release operation.
- Release operation completed: [PR #22](https://github.com/hasanmanzak/meAndAI/pull/22)
  merged as [`a4ffefa698b079815edebda86204150b03707957`](https://github.com/hasanmanzak/meAndAI/commit/a4ffefa698b079815edebda86204150b03707957); the remote annotated
[`v0.6.1` tag](https://github.com/hasanmanzak/meAndAI/tree/v0.6.1) resolves to
  that exact commit, and the owned delivery branch was removed.
