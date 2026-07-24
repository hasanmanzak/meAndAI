# Optional Credential-Source Files

- Date: 2026-07-15
- Target release: `v0.7.1`
- Work item: [BUG-0002](https://github.com/hasanmanzak/meAndAI/issues/27)
- Tracking: [issue #27](https://github.com/hasanmanzak/meAndAI/issues/27)
- Delivery: [pull request #29](https://github.com/hasanmanzak/meAndAI/pull/29)
- Test: [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md)

## Durable behavior

For an existing connected consumer, the launcher lists repository Actions
secret names before deciding which local credential files are required. A file
is optional only when its exact mapped repository secret already exists. GitHub
does not expose the stored value, and the launcher never attempts to read it.

If `MEANDAI_PROTOCOL_TOKEN` exists while `MEANDAI_RO_FG_PAT.txt` is absent, the
launcher uses the authenticated local `gh` identity to retrieve the exact
tagged workflow and clone the exact protocol commit needed by semantic
adoption. Existing Git-blob, manifest-commit, credential-history, redaction,
and no-overwrite gates remain active. Failure of that local identity to read
the private protocol repository is an actionable source-access blocker.

A missing target secret still requires its mapped file because local `gh`
authentication is a source-transport fallback, not secret provisioning. A new
repository still requires both files before remote creation.

## Evidence and continuation

The focused red test proved the old unconditional protocol-file requirement.
The focused pre-integration green run covered a file-free semantic-adoption
snapshot, missing-secret failure/recovery, and the new-repository gate. Its
provisional [TEST-0043](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md) ID became [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md) after merged v0.7.0 work claimed
[TEST-0043](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md), [TEST-0044](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md), and [RISK-0044](../../../docs/features/FEAT-0008-idea-incubation/README.md), [RISK-0045](../../../docs/features/FEAT-0008-idea-incubation/README.md), [RISK-0046](../../../docs/features/FEAT-0008-idea-incubation/README.md), and [RISK-0047](../../../docs/features/FEAT-0008-idea-incubation/README.md); [BUG-0002](https://github.com/hasanmanzak/meAndAI/issues/27) moved
to [RISK-0048](../../../docs/features/FEAT-0007-local-codex-adoption/README.md) and target `v0.7.1`. The implementation is published in pull
request [#29](https://github.com/hasanmanzak/meAndAI/pull/29). The integrated focused run passed [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md) and [TEST-0038](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0039](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0040](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0041](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), and [TEST-0042](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md)
and [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md) in 62.7 seconds; the complete suite passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0018](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0019](../../../docs/features/FEAT-0003-convergent-completion-scan/test-cases.md), [TEST-0020](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0021](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0022](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0023](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0024](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0025](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), and [TEST-0026](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0027](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0028](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0029](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0030](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0031](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), and [TEST-0032](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0038](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0039](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0040](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0041](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), and [TEST-0042](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0043](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md) and [TEST-0044](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md), and [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md) in 111.2 seconds with no unresolved fresh-diff blocker. [Pull request
#29](https://github.com/hasanmanzak/meAndAI/pull/29) then merged at `42e653e23ccb11034a735b8c3c420accf5f19964`, and annotated tag
[`v0.7.1`](https://github.com/hasanmanzak/meAndAI/tree/v0.7.1) resolves to that
exact release commit. [BUG-0002](https://github.com/hasanmanzak/meAndAI/issues/27) is complete.
