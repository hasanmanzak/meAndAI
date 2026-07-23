# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.14.0** (candidate)<br>
Latest immutable release: **0.13.5**

The immutable [v0.13.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.5)
release targets commit `014f9bbe30074a742c84e3915ebcf94b9fe9cc3e`;
[PR #109](https://github.com/hasanmanzak/meAndAI/pull/109) and
[issue #108](https://github.com/hasanmanzak/meAndAI/issues/108) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0045](../../docs/features/FEAT-0045-v0140-canonical-repository-evidence/README.md)
/ `BUG-0027`, [issue #110](https://github.com/hasanmanzak/meAndAI/issues/110),
and `SUBF-0085` through `SUBF-0087` own the bounded v0.14.0 canonical
repository-evidence and upstream-correction capability. Follow the
[v0.14.0 handoff](log/2026-07-23-v0140-canonical-repository-evidence.md).

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
