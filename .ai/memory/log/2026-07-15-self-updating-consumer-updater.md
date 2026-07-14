# 2026-07-15 - Self-Updating Consumer Updater

- Feature:
  [FEAT-0004](../../../docs/features/FEAT-0004-self-updating-consumer-updater/README.md)
- Decision:
  [DEC-0005](../../../docs/decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Tracking: [issue #15](https://github.com/hasanmanzak/meAndAI/issues/15)
- Delivery: [pull request #16](https://github.com/hasanmanzak/meAndAI/pull/16)
- Target protocol release: `v0.4.0`

## Durable outcomes

- Consumer mutations use a repository-scoped fine-grained PAT stored as
  `MEANDAI_UPDATER_TOKEN`; updater scripts remain credential-agnostic through
  `GH_TOKEN`.
- A private protocol source keeps a separate read-only
  `MEANDAI_PROTOCOL_TOKEN`; a public source can use the read-only workflow token.
- The updater resolves proposal ownership from the authenticated PAT identity.
  Rotating to another owner does not silently adopt an existing proposal.
- Current updater copies must equal the pinned templates before mutation.
- Compatible proposals include `.ai/protocol` and only target-different updater
  assets, with exact expected paths, modes, and blobs verified before push and
  before destructive supersession cleanup.
- The running job continues with already loaded code; after merge, the next run
  uses the updated workflow and scripts.
- Pre-v0.4 consumer updater copies require one reviewed migration. No GitHub App,
  hosted service, token broker, auto-approval, or auto-merge was added.

## Continuation

Use the feature test evidence and pull-request CI as the canonical delivery
state. Never store either PAT value in repository content or project memory.
