# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-26**<br>
Protocol version: **0.15.3**<br>
Latest immutable release: **0.15.2**

The immutable [v0.15.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.2)
release is complete at
[`9bc12e394725a86d29efb745cbdfa26407ffd3d2`](https://github.com/hasanmanzak/meAndAI/commit/9bc12e394725a86d29efb745cbdfa26407ffd3d2).
[PR #134](https://github.com/hasanmanzak/meAndAI/pull/134) and closed
[issue #133](https://github.com/hasanmanzak/meAndAI/issues/133) retain the
delivery, review, test, and publication evidence for
[FEAT-0053](../../docs/features/FEAT-0053-v0152-distinct-test-intent/README.md).

[FEAT-0054](../../docs/features/FEAT-0054-v0153-bounded-quick-adoption-runtime/README.md)
/ [issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) is the current
`0.15.3` bounded runtime refinement. It batches credential containment from
five to three Git processes per successful checkpoint and reduces the
[TEST-0107](../../docs/features/FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
family from seven to two full-launcher executions while retaining all seven
production-contract variants. Follow the
[current handoff](log/2026-07-26-v0153-bounded-quick-adoption-runtime.md).
[`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
is the parent runtime authority.

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

[FEAT-0050](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md)
/ [BUG-0033](https://github.com/hasanmanzak/meAndAI/issues/121),
[SUBF-0094](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/README.md#subf-0094),
[TEST-0182](../../docs/features/FEAT-0050-v0145-bare-document-basename-links/test-cases.md#test-0182),
and [issue #121](https://github.com/hasanmanzak/meAndAI/issues/121) own the
bounded `v0.14.5` basename-label correction. Follow the
[v0.14.5 handoff](log/2026-07-25-v0145-bare-document-basename-links.md).

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
- Keep current tool, environment, integration, and implementation routes in the
  [Active recurrence knowledge](project.md#active-recurrence-knowledge) section
  of the project snapshot. These entries are routing evidence, never executable
  regression evidence. Retain a concise `Stale` or `Superseded` routing
  tombstone in the active index and move only its detailed history to dated
  logs.
- Date facts that may become stale.
- Correct obsolete entries with a new record; do not silently rewrite history.
- Never store credentials or unrelated project details here.
