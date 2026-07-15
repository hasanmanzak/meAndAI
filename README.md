# meAndAI

`meAndAI` is a compact, versioned development protocol for human-AI software
delivery. A project can pin this repository as a Git submodule or repository
reference while keeping its own context and AI memory inside that project.

Current protocol version: **0.6.2**

## Start here

- Read the [common protocol](PROTOCOL.md).
- Follow the [adoption guide](docs/adoption.md) in a consuming repository.
- Use [quick adoption](docs/quick-adoption.md) for the one-command local seed.
- Browse the [feature index](docs/features/README.md) and
  [decision index](docs/decisions/README.md).
- Read this repository's isolated [project memory](.ai/memory/README.md).
- See the [changelog](CHANGELOG.md) for version history.

## Design boundary

The common protocol owns delivery rules, quality gates, identifiers, and
templates. Each consuming project owns its domain decisions, feature records,
test evidence, and AI memory. Those project-specific records must not be stored
inside the protocol submodule.

The initial implementation is tracked by
[FEAT-0001](docs/features/FEAT-0001-common-development-protocol/README.md) and
[GitHub issue #1](https://github.com/hasanmanzak/meAndAI/issues/1).

Semi-automatic, review-only consumer updates are tracked by
[FEAT-0002](docs/features/FEAT-0002-semi-automatic-consumer-updates/README.md)
and [GitHub issue #3](https://github.com/hasanmanzak/meAndAI/issues/3).

Fine-grained-PAT authentication and updater self-reconciliation are tracked by
[FEAT-0004](docs/features/FEAT-0004-self-updating-consumer-updater/README.md)
and [GitHub issue #15](https://github.com/hasanmanzak/meAndAI/issues/15).

Workflow-only adoption, collision-aware agent handoff, and the unified
AI-capabilities lifecycle are tracked by
[FEAT-0005](docs/features/FEAT-0005-ai-capabilities-lifecycle/README.md) and
[GitHub issue #17](https://github.com/hasanmanzak/meAndAI/issues/17).

One-command local repository creation, secret provisioning, and seed
publication are tracked by
[FEAT-0006](docs/features/FEAT-0006-quick-adoption-launcher/README.md) and
[GitHub issue #19](https://github.com/hasanmanzak/meAndAI/issues/19).

Local Codex completion without a hosted GitHub-agent connection is tracked by
[FEAT-0007](docs/features/FEAT-0007-local-codex-adoption/README.md) and
[GitHub issue #21](https://github.com/hasanmanzak/meAndAI/issues/21).

The v0.6.2 existing-secret preservation correction is tracked by
[BUG-0001](docs/features/FEAT-0007-local-codex-adoption/README.md#bug-0001-correction-for-v062)
and [GitHub issue #24](https://github.com/hasanmanzak/meAndAI/issues/24).

This repository is private. A consuming environment must have GitHub access to
clone or update the reference.
