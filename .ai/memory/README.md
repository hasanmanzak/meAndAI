# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.13.4** (candidate)<br>
Latest immutable release: **0.13.3**

The immutable [v0.13.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.3)
release targets commit `4285c7a6169d91a7b7cc75b72ce6c88230bf0039`;
[PR #105](https://github.com/hasanmanzak/meAndAI/pull/105) and
[issue #104](https://github.com/hasanmanzak/meAndAI/issues/104) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0043](../../docs/features/FEAT-0043-v0134-case-safe-review-authority/README.md)
/ `BUG-0025`, [issue #106](https://github.com/hasanmanzak/meAndAI/issues/106),
[PR #107](https://github.com/hasanmanzak/meAndAI/pull/107), and `SUBF-0082`
own the bounded v0.13.4 case-safe repository-identity
correction on `codex/bug-0025-case-safe-review-authority`. The correction may
fold only GitHub owner and repository-name components while every PR number,
head, authority, provenance, ledger, and cleanup gate remains strict.
TEST-0167 and TEST-0168 belong to the existing capability-review owner. Follow
the [v0.13.4 handoff](log/2026-07-23-v0134-case-safe-review-authority.md).

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
