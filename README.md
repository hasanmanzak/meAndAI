# meAndAI

`meAndAI` is a compact, versioned development protocol for human-AI software
delivery. A project can pin this repository as a Git submodule or repository
reference while keeping its own context and AI memory inside that project.

Current protocol version: **0.10.1**

For v0.10.1, publication authority is the repository's
[GitHub Releases](https://github.com/hasanmanzak/meAndAI/releases) surface and
[issue #65](https://github.com/hasanmanzak/meAndAI/issues/65); this file does
not assert a pre-merge release state.

## Start here

- Read the [common protocol](PROTOCOL.md).
- Follow the [adoption guide](docs/adoption.md) in a consuming repository.
- Use [quick adoption](docs/quick-adoption.md) for the single-file local seed.
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

The protocol's stability and consistency mandate starts one bounded project
scan after material development, resolves dependency-ready blocking findings
with per-finding self-review, pushes only after local convergence, and then
waits for the next development event. That converged push is distinct from a
protocol-version tag or GitHub Release.

The canonical [feature index](docs/features/README.md),
[decision index](docs/decisions/README.md), and [changelog](CHANGELOG.md) own
the detailed work and release history. The overview deliberately does not
duplicate that changing inventory.

This repository is private. A consuming environment must have GitHub access to
clone or update the reference.
