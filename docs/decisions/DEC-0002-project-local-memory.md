# DEC-0002 - Keep AI Memory Local to Each Consuming Project

- Classification: Decision
- Status: Accepted
- Date: 2026-07-14
- Decision owners: Repository maintainers
- Related feature:
  [FEAT-0001](../features/FEAT-0001-common-development-protocol/README.md)
- Related decision:
  [DEC-0001](DEC-0001-portable-protocol-reference.md)

## Context

Agent memory must be portable across machines, but domain facts and
collaboration history from unrelated projects must not leak into a shared
protocol. Tool-local chat memory is not a reliable repository artifact and may
not exist in another environment.

## Decision

Each consuming repository owns `.ai/memory` beside the protocol reference.
The directory contains a concise project snapshot and dated, append-only
handoffs. Canonical decisions remain under `docs/decisions`; memory links to
them instead of duplicating their full content.

The protocol repository applies the same rule recursively and stores only its
own facts in its root [project memory](../../.ai/memory/README.md). Shared rules
remain in [PROTOCOL.md](../../PROTOCOL.md).

Memory records distinguish verified facts, assumptions, preferences, and open
questions; include freshness information where needed; and contain no secrets or
raw chat transcripts.

## Consequences

- Another authorized machine can resume work from repository evidence.
- Project context remains isolated even when many projects share one protocol.
- Memory updates are reviewed with the feature that changes the remembered fact.
- Incorrect or stale memory is corrected explicitly and linked to evidence.
- Maintainers must keep memory concise to prevent it from becoming a second,
  conflicting documentation system.

## Alternatives considered

- Store all project memory in this repository: rejected for coupling, privacy,
  and stale-context risk.
- Rely only on tool-local memory: rejected because it is not portable or
  repository-versioned.
- Store raw conversations: rejected because they are noisy, sensitive, and not a
  curated source of truth.
