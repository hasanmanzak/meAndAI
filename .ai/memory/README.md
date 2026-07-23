# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.14.1** (candidate)<br>
Latest immutable release: **0.14.0**

The immutable [v0.14.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.0)
release targets commit `a2a987b322f5ea8d705ad6c5325cffc662a60978`;
[PR #111](https://github.com/hasanmanzak/meAndAI/pull/111) and
[issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0046](../../docs/features/FEAT-0046-v0141-consumer-nonduplication-mandate/README.md)
/ `BUG-0028`, [issue #112](https://github.com/hasanmanzak/meAndAI/issues/112),
and `SUBF-0088` own the bounded v0.14.1 consumer non-duplication mandate.
Follow the [v0.14.1 handoff](log/2026-07-23-v0141-consumer-nonduplication.md).

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
