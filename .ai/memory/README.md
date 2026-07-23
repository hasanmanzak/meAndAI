# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.13.3** (candidate)<br>
Latest immutable release: **0.13.2**

The immutable [v0.13.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.2)
release targets commit `0c67c8a26192921840bbd12559d83f0ad450e880`;
[PR #103](https://github.com/hasanmanzak/meAndAI/pull/103) and
[issue #102](https://github.com/hasanmanzak/meAndAI/issues/102) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0042](../../docs/features/FEAT-0042-v0133-historical-capability-review-recovery/README.md)
/ `BUG-0024` and [issue #104](https://github.com/hasanmanzak/meAndAI/issues/104)
own the bounded v0.13.3 historical capability-review recovery on
`codex/bug-0024-historical-review-recovery`. It accepts only one fully proven
merged strict-predecessor review, preserves the complete current ledger, uses
expected-OID branch deletion, closes the issue last, and performs one fresh
current-catalog inventory. TEST-0165 and TEST-0166 belong to the existing
capability-adoption owner. Follow the
[v0.13.3 handoff](log/2026-07-23-v0133-historical-capability-review-recovery.md).

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
