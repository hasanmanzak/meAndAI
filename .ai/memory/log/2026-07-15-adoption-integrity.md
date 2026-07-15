# Adoption and Updater Integrity

- Date: 2026-07-15
- Target release: `v0.7.2`
- Work item: [FEAT-0009](../../../docs/features/FEAT-0009-adoption-integrity/README.md)
- Tracking: [issue #30](https://github.com/hasanmanzak/meAndAI/issues/30)
- Delivery: [pull request #31](https://github.com/hasanmanzak/meAndAI/pull/31)
- CI: [Protocol validation run 29433627977](https://github.com/hasanmanzak/meAndAI/actions/runs/29433627977)
- Tests: [TEST-0046 through TEST-0050](../../../docs/features/FEAT-0009-adoption-integrity/test-cases.md)

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

The confirmation suite passed `TEST-0001` through `TEST-0050` in 142.5 seconds.
The one allowed post-change scan found no new actionable issue across the diff,
PowerShell syntax, active version surfaces, credential patterns, launcher seam,
and already-passing link gates. Record the reviewed pull request and annotated
`v0.7.2` tag without rewriting historical release evidence or expanding the
single-file quick-command boundary.
