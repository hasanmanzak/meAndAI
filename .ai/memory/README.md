# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-30**<br>
Protocol version: **0.16.0**<br>
Latest immutable release before this unmerged development: **0.16.0**

The maintainer accepted
[DEC-0035](../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
on 2026-07-29. Follow the accepted
[architecture](../../docs/architecture/protocol-governance-and-execution/README.md),
[successor plan](../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md),
[WIP extraction ledger](../../docs/architecture/protocol-governance-and-execution/wip-extraction-ledger.md),
the historical [architecture-acceptance handoff](log/2026-07-29-protocol-governance-execution-architecture-acceptance.md),
the historical [domain-vocabulary planning handoff](log/2026-07-29-feat-0065-subf-0152-domain-vocabulary.md),
the historical [domain-vocabulary implementation handoff](log/2026-07-29-feat-0065-subf-0152-domain-vocabulary-implementation.md),
the historical [evidence-acquisition design handoff](log/2026-07-30-feat-0065-subf-0153-evidence-contract-design.md),
and the current [typed-evaluation-kernel design handoff](log/2026-07-30-feat-0065-subf-0143-typed-handoff-design.md).
The product is one versioned executable protocol platform implemented in C#,
not a collection of CLI products. [SUBF-0152](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
and [TEST-0220](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
are complete through [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170),
exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).

The historical
[SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
[design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5126219253)
produced the accepted
[evidence-acquisition design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0153-evidence-contract-design.md).
[PR #171](https://github.com/hasanmanzak/meAndAI/pull/171) merged it at exact
main
[`cae8854f8afee4c31e362a02637b27b488aab90f`](https://github.com/hasanmanzak/meAndAI/commit/cae8854f8afee4c31e362a02637b27b488aab90f),
with bounded [closure evidence](https://github.com/hasanmanzak/meAndAI/pull/171#issuecomment-5128021520).
That design has no executable evidence or implementation authority.

The current [design-only directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5128172584)
authorizes only Gate 1/2 design and expected-red planning for
[SUBF-0143](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0143)
and [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210).
Follow the exact
[typed-evaluation-kernel design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md).
Bounded red-team, maintainer acceptance, accepted-design merge/exact-main
validation, and a separate implementation directive remain required. No C#
source/test, Gate 3, project/package/lock/solution, workflow/scenario-owner/
[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
WIP extraction, consumer, release, publication, authority-transfer,
or PowerShell-retirement change is authorized.

Immutable [v0.16.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.16.0)
is published at
[2329f944694d24523f85b3a60352743918f0e5cd](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
[PR #159](https://github.com/hasanmanzak/meAndAI/pull/159) and
[issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) retain the
merge, test, and immutable publication evidence for
[FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md).

The immutable [v0.15.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.6)
release is complete at
[`5321f1f1aa5966114c69b46bf6ed9191df109e6b`](https://github.com/hasanmanzak/meAndAI/commit/5321f1f1aa5966114c69b46bf6ed9191df109e6b).
[PR #152](https://github.com/hasanmanzak/meAndAI/pull/152) and
[issue #149](https://github.com/hasanmanzak/meAndAI/issues/149) retain the
delivery, review, test, and publication evidence for
[FEAT-0058](../../docs/features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md).

[FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
is the completed shared technical prerequisite. Follow the historical
[portable-package completion handoff](log/2026-07-28-feat-0059-subf-0121-portable-packaging.md)
for its slice evidence. Its release does not authorize any successor feature,
consumer change, or authority migration.

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
