# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-31**<br>
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
the historical [evidence-contract implementation handoff](log/2026-07-30-feat-0065-subf-0153-evidence-contract-implementation.md),
the accepted Gate 2 [typed-evaluation-kernel design handoff](log/2026-07-30-feat-0065-subf-0143-typed-handoff-design.md),
the historical [ContractSlice A topology-correction handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-topology-correction.md),
the current [ContractSlice A canonical-string bounded-green closure handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-canonical-string.md),
and the proposed
[SUBF-0143 micro-delivery control plan](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-micro-delivery-plan.md).
The product is one versioned executable protocol platform implemented in C#,
not a collection of CLI products. [SUBF-0152](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0152)
and [TEST-0220](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0220)
are complete through [PR #170](https://github.com/hasanmanzak/meAndAI/pull/170),
exact main commit
[`c31819487e77fc878fc40fae6445bfef582719da`](https://github.com/hasanmanzak/meAndAI/commit/c31819487e77fc878fc40fae6445bfef582719da),
and [run 30511073506](https://github.com/hasanmanzak/meAndAI/actions/runs/30511073506).

[SUBF-0153](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#subf-0153)
and [TEST-0221](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0221)
are complete through [PR #173](https://github.com/hasanmanzak/meAndAI/pull/173)
at exact main
[`ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd`](https://github.com/hasanmanzak/meAndAI/commit/ff0f4f17ea65a9774f42b4c9ce660eeaa213b7fd).
[Run 30603364256](https://github.com/hasanmanzak/meAndAI/actions/runs/30603364256)
passed both stable jobs. The prior local-candidate state and discarded
`NETSDK1064` attempt remain historical only.

The accepted Gate 2
[typed-evaluation-kernel design](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0143-typed-evaluation-kernel-design.md)
now includes the maintainer-approved ParseCanonical-only ContractSlice A
topology correction. Follow the current
[correction handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-topology-correction.md)
and corrected
[Gate 3 directive](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139269228).
[The append-only BehaviorRed evidence clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5139945054)
governs the exact TRX message/echo/type oracle.
[The append-only RunInfo clarification](https://github.com/hasanmanzak/meAndAI/issues/165#issuecomment-5140224849)
permits only one exact marker-free same-FQN xUnit `[FAIL]` bookkeeping node and
keeps every other diagnostic invalid.
[FIND-0439](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0439)
closes the parser resource, exception, component-reachability, and trusted-
provenance boundaries.
[FIND-0440](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md#find-0440)
records the RunInfo correction; its mandatory fresh rerun is now satisfied by
the accepted post-synchronization canonical A BehaviorRed.
[TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`; the A scaffold, exact SurfaceRed, 48-type structural surface,
and focused `11/11` checkpoint exist locally. Topology/parser and RunInfo
reviews passed `0 Blocking` / `0 Important` / `0 Minor`. Pre-applicable-
clarification BehaviorRed observations are diagnostic
only. The fresh exact-FQN run recorded in the historical
[correction handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-topology-correction.md)
passed the complete clarified oracle as canonical BehaviorRed. The first limited
ParseCanonical increment then passed the original-oracle and final-source exact-
FQN checks `1/1`, cumulative A `12/12`, format verification, a warning/error-
free final six-project Release build, and private-byte source review. That first-
green support review had `0 Blocking`, one unnumbered remaining-A coverage
`Important`, and no unresolved `Minor`. The current
[canonical-string handoff](log/2026-07-31-feat-0065-subf-0143-contractslice-a-canonical-string.md)
preserves the second A exact-red FQN/marker and records its bounded green. The
writer-owned
`CanonicalManifestQuotedUtf8Codec.EncodeQuotedUtf8(string)`, legacy/green byte
probe, 1,226-byte Unicode fixture and digest, exact `é` (`C3 A9`) versus `é`
(`65 CC 81`) non-normalization, and the lexical/malformed matrix. The reader
re-encodes with that same codec and ordinal-compares the complete original
quoted token without a second grammar; only `GetString()`'s
`InvalidOperationException` is caught at that call boundary. Direct malformed
UTF-16 remains codec-argument `ArgumentException`, while only document-caused
codec failure maps to public `FormatException`. Its seam predecessor passed
`1/1`, red and bounded source reviews closed `0 Blocking`/`0 Important`/
`0 Minor`, original-oracle and final-source greens passed `1/1`, and cumulative
A passed `13/13`. Locked restore, unchanged six lock fingerprints, standard
format, clean diff check, and the zero-warning/error six-project Release build
passed; the non-gating severity-info scan exposed pre-existing informational
backlog/suggestions and is not claimed clean. The canonical-string coverage
`Important` is closed, but remaining A is pending and [TEST-0210](../../docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md#test-0210)
remains `Planned`. Each reviewed A source, exact red, and smallest green proceeds
separately, one increment at a time; no later A increment is active. A constructs
no executable export and declares no kernel. B/C/D, workflow/scenario-owner/
[TEST-0146](../../docs/features/FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
WIP extraction, consumer, release, publication, authority-transfer, and
PowerShell-retirement changes remain unauthorized.

The proposed micro-delivery plan is non-normative and non-activating until
maintainer acceptance. If accepted, begin with its `BASE-SCOPE` through
`BASE-CHECKPOINT` sequence. The current source/test trees are now tracked by
local baseline commit `5fa7f7d` (`[skip ci]`); cumulative `13/13` is now a
content-addressed reviewed local predecessor, and `BASE-RECORDS` is synchronized.
Do not let a small-context agent select its own contract, evidence ordinal,
FQN, marker, oracle, allowlist, or held-scope exception.

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
