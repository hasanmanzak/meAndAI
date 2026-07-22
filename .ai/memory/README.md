# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-22**<br>
Protocol version: **0.13.0**

The immutable v0.12.7 release is published at commit
`6b01299cfe484c900944b7435d4fef43b11fc38d`; [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96)
and [PR #97](https://github.com/hasanmanzak/meAndAI/pull/97) retain its delivery
evidence. `0.13.0` identifies the local FEAT-0039 development tree on
`codex/task-0001-reusable-fixture-guardrails`; it is not a published release.
[Issue #95](https://github.com/hasanmanzak/meAndAI/issues/95) is the external
tracking authority for this candidate.

This directory is the portable, curated handoff between the maintainer and AI
collaborators. It is not the common memory of consuming projects. Each consumer
creates its own `.ai/memory` outside the protocol submodule.

Read in this order:

1. [Project snapshot](project.md)
2. The current continuation identified in the [log index](log/README.md)
3. Canonical feature and decision documents linked by those records

Memory ownership and boundaries are defined by
[DEC-0002](../../docs/decisions/DEC-0002-project-local-memory.md).

## Recording rules

- Store durable project facts and collaboration constraints, not raw chat.
- Mark assumptions and open questions explicitly.
- Link to issues, pull requests, features, decisions, tests, or commits.
- Date facts that may become stale.
- Correct obsolete entries with a new record; do not silently rewrite history.
- Never store credentials or unrelated project details here.
