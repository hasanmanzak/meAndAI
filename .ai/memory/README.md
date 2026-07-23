# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.13.5** (candidate)<br>
Latest immutable release: **0.13.4**

The immutable [v0.13.4](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.4)
release targets commit `089c63d2aeca2d8188bdaeeced5e33be8d01c256`;
[PR #107](https://github.com/hasanmanzak/meAndAI/pull/107) and
[issue #106](https://github.com/hasanmanzak/meAndAI/issues/106) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0044](../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md)
/ `BUG-0026`, [issue #108](https://github.com/hasanmanzak/meAndAI/issues/108),
`SUBF-0083`, and `SUBF-0084` own the bounded v0.13.5 slash-safe ref and
single-owner consumer-lifecycle correction. TEST-0169 and TEST-0170 remain in
their existing capability owners. Follow the
[v0.13.5 handoff](log/2026-07-23-v0135-slash-safe-ref-single-owner-lifecycle.md).

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
