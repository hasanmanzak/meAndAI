# 2026-07-15 - AI Capabilities Lifecycle

## Context

- Work item: [FEAT-0005](../../../docs/features/FEAT-0005-ai-capabilities-lifecycle/README.md)
- Decision: [DEC-0006](../../../docs/decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Tracking: [issue #17](https://github.com/hasanmanzak/meAndAI/issues/17)
- Delivery: [pull request #18](https://github.com/hasanmanzak/meAndAI/pull/18)
- Target release: `v0.5.0`

## Durable outcome

- The canonical consumer update workflow is also the only adoption seed.
- A consumer with no target collisions receives a deterministic full adoption
  draft; a consumer with collisions receives only
  `.ai/adoption/meandai-capabilities.json` and no overwrite.
- The source-only bootstrap code runs from the immutable tag embedded in the
  seed workflow and is not installed in the consumer.
- A pending deterministic adoption draft is retained. Seed drift, an existing
  manifest, or inconsistent branch/PR ownership blocks without cleanup.
- GitHub Actions does not run an AI agent. An explicitly invoked agent or
  maintainer completes project labels, records, memory, semantic merges, tests,
  links, and manifest removal before readiness or merge.
- After adoption, the existing consumer-owned updater retains compatible
  update and supersession responsibility under the v0.4 credential boundary.

## Verification and continuation

- `TEST-0027` through `TEST-0032` cover routing, bootstrap, populated consumer
  preservation, collision handoff, ownership recovery, and updater regression.
- Complete the bounded FEAT-0005 review, merge its delivery pull request, then
  tag the merged `main` commit as `v0.5.0`.
