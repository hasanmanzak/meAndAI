# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-22**<br>
Protocol version: **0.13.1**<br>
Latest immutable release: **0.13.0**

The immutable v0.13.0 release is published at commit
`299b8982cd57961e2b3a6136b07af3bfb49a16d1`; [issue #95](https://github.com/hasanmanzak/meAndAI/issues/95)
and [PR #99](https://github.com/hasanmanzak/meAndAI/pull/99) retain its delivery,
asset, cleanup, and post-publication evidence. [FEAT-0040](../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
and [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
now own the bounded v0.13.1 residual runtime correction on
`codex/task-0002-batched-instruction-graph-transport`. Production and
independent expected-reader implementation is complete through commits
`78c8706e9d4d4f4c020d983b22114165687b475e` and
`55764442820c884e8c3115726bb010a0a9004d77`; follow the
[implementation handoff](log/2026-07-22-v0131-batched-instruction-graph-implementation.md).
`WindowsNative`, the one budgeted Full suite, and bounded local convergence are
complete. Hosted, pull-request, merge, and release evidence remain pending
external delivery facts; elapsed results establish no wall-clock improvement.

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
