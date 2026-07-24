# DEC-0006 - Use a Seed Workflow with Collision-Aware Adoption Handoff

- Classification: Decision
- Status: Accepted
- Date: 2026-07-15
- Decision owners: meAndAI maintainers and consumer maintainers
- Related features: [FEAT-0005](../features/FEAT-0005-ai-capabilities-lifecycle/README.md), [FEAT-0004](../features/FEAT-0004-self-updating-consumer-updater/README.md)
- Related decisions: [DEC-0001](DEC-0001-portable-protocol-reference.md), [DEC-0002](DEC-0002-project-local-memory.md), [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md)
- Supersedes: the manual-only bootstrap assumption in [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md) and [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md); update supersession, credential scope, and project-local ownership remain unchanged

## Context

The consumer-resident, protocol-owned managed updater is deliberately safe
after adoption: it executes reviewed local code, verifies the existing protocol
gitlink, and changes only managed update paths. Those same preconditions make it incapable of installing
itself. A consumer that copies only the workflow has neither local scripts nor
a protocol submodule, while a populated consumer may already own files that
need semantic rather than mechanical merging.

GitHub Actions cannot start a local Codex session merely because a protocol was
downloaded. Treating the protocol as executable AI would obscure the authority
boundary. The workflow can, however, create a durable, review-only proposal
that an explicitly invoked agent or maintainer completes under the protocol.

## Decision

The canonical update workflow also acts as the only consumer seed. It checks
out `meAndAI` at an exact bootstrap release embedded in that workflow. When both
local updater files exist, the workflow executes the local updater exactly as
before. When either is absent, it executes a small source-only bootstrap
adapter from the pinned checkout. A partial installation is therefore adoption
input, never trusted updater code.

Bootstrap classification is based only on the declared adoption target set:

- `BootstrapReady`: every target is absent except an exact canonical seed
  workflow. The draft proposal adds the protocol gitlink, deterministic core
  assets, and a transient handoff manifest.
- `AdoptionReviewRequired`: at least one consumer-owned target exists. The
  draft proposal adds only the manifest and records the exact collisions.
- `PendingAdoption`: the deterministic branch and its proposal already exist;
  automation does not replace or duplicate them.
- `BlockedManualReview`: manifest ownership, branch/PR state, tag, source,
  credential, or seed identity is ambiguous. No mutation or cleanup occurs.
- `Update`: the complete local updater installation owns subsequent compatible
  update discovery and supersession.

The transient manifest is
`.ai/adoption/meandai-capabilities.json`. It identifies schema, state, consumer,
target tag, collision paths, proposed paths, and required completion tasks. It
instructs an agent/maintainer to create or verify labels, create project-owned
feature and decision records, tailor root instructions and memory, perform
semantic merges, run project tests, update links, and remove the manifest. A
proposal containing the manifest cannot be ready or merged.

The adoption branch is deterministic and created only with an expected-absent
Git lease. An existing branch is never reset. Automation does not close or
delete adoption work and does not supersede an adoption proposal; those more
complex controls remain exclusive to the post-adoption updater.

The bootstrap workflow does not create labels or issues. Doing so would expand
the consumer mutation token beyond the [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md) boundary and would still not
provide semantic project integration. GitHub Actions never calls an AI service
in this feature.

## Consequences

- A new consumer can begin with one workflow plus its existing two credential
  secrets.
- Arbitrary application content is compatible with deterministic bootstrap
  when adoption targets are absent.
- Populated repositories retain all consumer-owned content and receive a
  durable agent handoff rather than a guessed merge.
- Bootstrap executes protocol code not yet resident in the consumer, so the
  workflow pin and source/tag verification are supply-chain requirements.
- An AI agent must still be invoked explicitly to finish project-specific
  adoption; the operation installs and describes capabilities, not an AI
  runtime.
- Labels and project-specific records are not fully zero-touch, but token scope
  remains narrow and the bootstrap adapter stays small.
- Existing v0.4 consumers remain compatible because complete local updater
  installations continue down the existing code path.

## Alternatives considered

- Keep manual adoption: rejected because it contradicts the intended
  workflow-only entry point and duplicates deterministic setup work.
- Execute the newest script from moving `main`: rejected because unreviewed
  remote code would gain consumer write authority.
- Automatically merge existing consumer files: rejected because filenames do
  not prove semantic compatibility and overwrite risk is unacceptable.
- Start Codex from GitHub Actions: rejected because no configured runtime,
  identity, authority, or review contract exists and it would turn a small
  protocol into a hosted automation platform.
- Give the PAT Issues write permission and create labels automatically:
  rejected because labels are an agent completion task and the extra authority
  is not required for lifecycle correctness.
- Put full bootstrap logic inline in the workflow: rejected because it would
  make the seed difficult to review and self-update; the workflow remains a
  small pinned launcher.
- Rename the existing updater workflow and scripts: rejected because v0.4
  consumers can self-update only the already managed paths.

## Review condition

Revisit when GitHub provides a trustworthy native AI-agent handoff primitive,
consumer demand justifies a GitHub App, repository-reference providers gain a
portable mutation contract, or project labels must become zero-touch under a
separately approved credential boundary.
