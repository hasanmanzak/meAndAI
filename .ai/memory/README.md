# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-25**<br>
Protocol version: **0.15.0**<br>
Latest immutable release: **0.14.5**

The immutable [v0.14.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.5)
release is complete. [PR #122](https://github.com/hasanmanzak/meAndAI/pull/122)
and closed [issue #121](https://github.com/hasanmanzak/meAndAI/issues/121)
retain its delivery and publication evidence. Current verifier authority also
closed the retained `v0.14.4`, `v0.14.3`, and `v0.14.2` publication gates;
[issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) and
[issue #114](https://github.com/hasanmanzak/meAndAI/issues/114) are closed.
Follow the [v0.14.5 publication-closure handoff](log/2026-07-25-v0145-publication-closure.md)
for exact dated evidence. [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
remains the separate runtime residual owner.

[FEAT-0051](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
is implemented and locally reviewed for target `0.15.0` under
[issue #124](https://github.com/hasanmanzak/meAndAI/issues/124), with
[SUBF-0095](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0095) / [issue #128](https://github.com/hasanmanzak/meAndAI/issues/128),
[SUBF-0096](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096) / [issue #125](https://github.com/hasanmanzak/meAndAI/issues/125),
[SUBF-0097](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0097) / [issue #126](https://github.com/hasanmanzak/meAndAI/issues/126),
and [SUBF-0098](../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0098) / [issue #127](https://github.com/hasanmanzak/meAndAI/issues/127).
The maintainer authorized implementation on 2026-07-25. Follow the current
[release-candidate handoff](log/2026-07-25-v0150-recurrence-prevention-modular-test-harness.md);
the completed [runtime-role handoff](log/2026-07-25-v0150-subf-0097-runtime-evidence-roles.md),
the completed [canonical-utility handoff](log/2026-07-25-v0150-subf-0096-canonical-utility-ownership.md),
the completed [first-slice handoff](log/2026-07-25-v0150-subf-0095-recurrence-gate.md),
and the earlier
[planning handoff](log/2026-07-25-v0150-recurrence-prevention-planning.md)
remain historical evidence. The final full suite, reviewed pull request, and
immutable `v0.15.0` release remain pending under
[issue #124](https://github.com/hasanmanzak/meAndAI/issues/124).

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
