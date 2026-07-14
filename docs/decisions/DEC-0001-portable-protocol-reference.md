# DEC-0001 - Use a Pinned Protocol Reference with a Project Adapter

- Classification: Decision
- Status: Accepted
- Date: 2026-07-14
- Decision owners: Repository maintainers
- Related feature:
  [FEAT-0001](../features/FEAT-0001-common-development-protocol/README.md)
- Related decision:
  [DEC-0002](DEC-0002-project-local-memory.md)

## Context

Multiple projects need the same delivery rules, but copied protocol files drift
and a moving remote branch makes builds and agent behavior non-reproducible.
Instructions inside a submodule also do not automatically govern files in the
parent repository, so consumption needs an explicit project-root entry point.

## Decision

The canonical protocol remains in this repository. Consumers use a Git
submodule at `.ai/protocol` or a tool-native repository reference pinned to a
tag or commit. Each consumer keeps or merges the matching root `AGENTS.md`
adapter: the submodule adapter loads `.ai/protocol/PROTOCOL.md`; the
repository-reference adapter resolves the configured repository, immutable ref,
and `PROTOCOL.md` entry point without assuming a local checkout.

The submodule is the recommended default because it works offline after clone,
preserves the exact commit, and exposes templates locally. The
[adoption guide](../adoption.md) is the operational source.

## Consequences

- Protocol upgrades are intentional, reviewable dependency changes.
- Existing project instructions remain visible at the root.
- Private repository access is required on every machine or CI identity.
- Consumers must initialize submodules, or configure their repository-reference
  resolver and matching adapter.
- A protocol change does not silently change a pinned consumer.

## Alternatives considered

- Copy files into every repository: rejected because fixes and rules drift.
- Always read `main` remotely: rejected because it is not reproducible or
  reliably available.
- Build a universal bootstrapper/package: rejected as unnecessary complexity for
  a small document-and-template protocol.
