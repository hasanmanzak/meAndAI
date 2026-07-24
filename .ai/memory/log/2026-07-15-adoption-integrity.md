# Adoption and Updater Integrity

- Date: 2026-07-15
- Target release: `v0.7.2`
- Work item: [FEAT-0009](../../../docs/features/FEAT-0009-adoption-integrity/README.md)
- Tracking: [issue #30](https://github.com/hasanmanzak/meAndAI/issues/30)
- Delivery: [pull request #31](https://github.com/hasanmanzak/meAndAI/pull/31)
- CI: [Protocol validation run 29433627977](https://github.com/hasanmanzak/meAndAI/actions/runs/29433627977)
- Tests: [TEST-0046](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0047](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0048](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0049](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), and [TEST-0050](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md)

## Durable behavior

Adoption completion trusts only one open deterministic pull request whose
canonical marker binds the target repository, default base, authenticated
maintainer actor, same-repository head, live head SHA, protocol tag, and exact
protocol commit. The source-only lifecycle workflow applies the same ownership
check before retaining an existing proposal. Full and collision-mode completion
both require the exact `160000` gitlink and canonical `.gitmodules` mapping.

The consumer updater rejects rename or previous-filename metadata during both
candidate inventory and cleanup revalidation. The local launcher keeps adoption
issues in progress while Codex or validation can still block, and assigns
`status:needs-review` only after the completion commit is published, verified,
and the pull request becomes ready.

## Continuation

The confirmation suite passed [TEST-0001](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0002](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0003](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0004](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0005](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0006](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0007](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), and [TEST-0008](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0009](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0010](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0011](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0012](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0013](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0014](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0015](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0016](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), and [TEST-0017](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0018](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0019](../../../docs/features/FEAT-0003-convergent-completion-scan/test-cases.md), [TEST-0020](../../../docs/features/FEAT-0001-common-development-protocol/test-cases.md), [TEST-0021](../../../docs/features/FEAT-0002-semi-automatic-consumer-updates/test-cases.md), [TEST-0022](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0023](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0024](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0025](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), and [TEST-0026](../../../docs/features/FEAT-0004-self-updating-consumer-updater/test-cases.md), [TEST-0027](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0028](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0029](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0030](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0031](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), and [TEST-0032](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/test-cases.md), [TEST-0033](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0034](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0035](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0036](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), and [TEST-0037](../../../docs/features/FEAT-0006-quick-adoption-launcher/test-cases.md), [TEST-0038](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0039](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0040](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0041](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), and [TEST-0042](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), [TEST-0043](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md) and [TEST-0044](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md), [TEST-0045](../../../docs/features/FEAT-0007-local-codex-adoption/test-cases.md), and [TEST-0046](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0047](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0048](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), [TEST-0049](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md), and [TEST-0050](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md) in 142.5 seconds.
The one allowed post-change scan found no new actionable issue across the diff,
PowerShell syntax, active version surfaces, credential patterns, launcher seam,
and already-passing link gates. Record the reviewed pull request and annotated
`v0.7.2` tag without rewriting historical release evidence or expanding the
single-file quick-command boundary.
