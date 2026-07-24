# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-24**<br>
Protocol version: **0.14.4** (candidate)<br>
Latest immutable release: **0.14.3**

The immutable [v0.14.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.3)
release targets commit [`2d6cfc27418209c26cf9c27225c37938bac14dd9`](https://github.com/hasanmanzak/meAndAI/commit/2d6cfc27418209c26cf9c27225c37938bac14dd9);
[PR #118](https://github.com/hasanmanzak/meAndAI/pull/118) retains delivery
evidence. [Issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) is
reopened because [run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612)
exposed the real PowerShell paged-array shape. The earlier
[issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) remains open for
the retained `v0.14.2` rerun. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0048](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md)
/ [BUG-0031](https://github.com/hasanmanzak/meAndAI/issues/117),
[SUBF-0092](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/README.md#subf-0092),
[TEST-0179](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0179),
[TEST-0180](../../docs/features/FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180),
and [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) own the
bounded v0.14.3 API-2026 merge-evidence propagation correction. Follow the
[v0.14.3 handoff](log/2026-07-24-v0143-shared-merge-evidence.md).

[FEAT-0049](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/README.md)
/ [BUG-0032](https://github.com/hasanmanzak/meAndAI/issues/119),
[SUBF-0093](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/README.md#subf-0093),
[TEST-0181](../../docs/features/FEAT-0049-v0144-paged-array-response-normalization/test-cases.md#test-0181),
and [issue #119](https://github.com/hasanmanzak/meAndAI/issues/119) own the
bounded `v0.14.4` runtime-shape correction. Follow the
[v0.14.4 handoff](log/2026-07-24-v0144-paged-array-normalization.md).

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
