# meAndAI

`meAndAI` is a compact, versioned development protocol for human-AI software
delivery. A project can pin this repository as a Git submodule or repository
reference while keeping its own context and AI memory inside that project.

Current protocol version: **0.4.0**

## Start here

- Read the [common protocol](PROTOCOL.md).
- Follow the [adoption guide](docs/adoption.md) in a consuming repository.
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

This repository is private. A consuming environment must have GitHub access to
clone or update the reference.
