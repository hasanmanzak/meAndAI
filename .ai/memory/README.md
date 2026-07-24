# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-24**<br>
Protocol version: **0.14.2** (candidate)<br>
Latest immutable release: **0.14.1**

The immutable [v0.14.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.1)
release targets commit [`f153e21a3098945a1b669563046f875ef6fb8b60`](https://github.com/hasanmanzak/meAndAI/commit/f153e21a3098945a1b669563046f875ef6fb8b60);
[PR #113](https://github.com/hasanmanzak/meAndAI/pull/113) and
[issue #112](https://github.com/hasanmanzak/meAndAI/issues/112) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0047](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md)
/ [BUG-0029](https://github.com/hasanmanzak/meAndAI/issues/114) and
[BUG-0030](https://github.com/hasanmanzak/meAndAI/issues/116),
[SUBF-0089](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md#subf-0089),
[SUBF-0090](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md#subf-0090),
[SUBF-0091](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/README.md#subf-0091),
[TEST-0175](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0175),
[TEST-0176](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176),
[TEST-0177](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0177),
[TEST-0178](../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178),
[issue #114](https://github.com/hasanmanzak/meAndAI/issues/114), and
[issue #116](https://github.com/hasanmanzak/meAndAI/issues/116) own the bounded
v0.14.2 clickable exact-record and commit-reference correction. Follow the
[v0.14.2 handoff](log/2026-07-24-v0142-clickable-cross-record-references.md).

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
