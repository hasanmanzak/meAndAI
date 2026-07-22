# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-22**<br>
Protocol version: **0.12.7**

The immutable v0.12.6 release is published at commit
`6de31e0c318666bfa1fb884f2f5a791ecaf0fd3e`. `0.12.7` identifies the local
FEAT-0038 development tree on
`codex/feat-0038-api-safe-merge-finalization`; it is not a published release.
Exact v0.12.7 publication state will be authoritative only in
[GitHub Releases](https://github.com/hasanmanzak/meAndAI/releases),
[issue #96](https://github.com/hasanmanzak/meAndAI/issues/96) after publication;
it is not predicted or projected into this pre-merge memory file.

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
