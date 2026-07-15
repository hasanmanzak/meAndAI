# meAndAI

`meAndAI` is a compact, versioned development protocol for human-AI software
delivery. A project can pin this repository as a Git submodule or repository
reference while keeping its own context and AI memory inside that project.

Current protocol version: **0.8.3**

For v0.8.3, publication authority is the repository's
[GitHub Releases](https://github.com/hasanmanzak/meAndAI/releases) surface and
[issue #38](https://github.com/hasanmanzak/meAndAI/issues/38); this file does
not assert a pre-merge release state.

## Start here

- Read the [common protocol](PROTOCOL.md).
- Follow the [adoption guide](docs/adoption.md) in a consuming repository.
- Use [quick adoption](docs/quick-adoption.md) for the one-command local seed.
- Browse the [feature index](docs/features/README.md) and
  [decision index](docs/decisions/README.md).
- Browse incubating possibilities in the [idea index](docs/ideas/README.md).
- Read this repository's isolated [project memory](.ai/memory/README.md).
- See the [changelog](CHANGELOG.md) for version history.

## Design boundary

The common protocol owns delivery rules, quality gates, identifiers, and
templates. Each consuming project owns its domain decisions, feature records,
test evidence, and AI memory. Those project-specific records must not be stored
inside the protocol submodule.

The canonical [feature index](docs/features/README.md),
[decision index](docs/decisions/README.md), and [changelog](CHANGELOG.md) own
the detailed work and release history. The overview deliberately does not
duplicate that changing inventory.

This repository is private. A consuming environment must have GitHub access to
clone or update the reference.
