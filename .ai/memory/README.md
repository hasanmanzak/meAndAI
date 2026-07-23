# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-23**<br>
Protocol version: **0.13.2** (candidate)<br>
Latest immutable release: **0.13.1**

The immutable [v0.13.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.1)
release targets commit `f8296cf8d4aba66519a24603c5c7a2a3727f973c`;
[PR #100](https://github.com/hasanmanzak/meAndAI/pull/100) and
[issue #101](https://github.com/hasanmanzak/meAndAI/issues/101) retain its
delivery and publication evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0041](../../docs/features/FEAT-0041-v0132-exact-head-owner-attestation/README.md)
/ `BUG-0023` and [issue #102](https://github.com/hasanmanzak/meAndAI/issues/102)
now own the bounded v0.13.2 capability-finalization correction on
`codex/bug-0023-owner-attestation`. It preserves every nonempty GitHub review
collection as authoritative and permits a fallback only for an empty review
collection plus one canonical exact-head comment from the personal repository
owner, pull-request creator, and exact `admin` actor. TEST-0163 and TEST-0164
were added to the existing capability-adoption owner; expected red, focused
green, structural, and release-bundle evidence are recorded. Hosted gates,
publication, and the retained external consumer recovery remain pending. Follow the
[v0.13.2 handoff](log/2026-07-23-v0132-exact-head-owner-attestation.md).

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
