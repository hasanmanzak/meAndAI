# Project-local AI Memory

Scope: **this `meAndAI` repository only**<br>
Last reviewed: **2026-07-28**<br>
Protocol version: **0.16.0**<br>
Latest immutable release: **0.16.0**

The immutable [v0.16.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.16.0)
release is complete at
[`2329f944694d24523f85b3a60352743918f0e5cd`](https://github.com/hasanmanzak/meAndAI/commit/2329f944694d24523f85b3a60352743918f0e5cd).
[PR #159](https://github.com/hasanmanzak/meAndAI/pull/159),
[issue #154](https://github.com/hasanmanzak/meAndAI/issues/154), exact-head
[run `30337115744`](https://github.com/hasanmanzak/meAndAI/actions/runs/30337115744),
exact-main [run `30339245671`](https://github.com/hasanmanzak/meAndAI/actions/runs/30339245671),
and post-publication [run `30340370375`](https://github.com/hasanmanzak/meAndAI/actions/runs/30340370375)
retain the merge, review, test, immutable publication, and verification
evidence for
[FEAT-0059](../../docs/features/FEAT-0059-csharp-operational-foundation/README.md).

[FEAT-0060](../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md)
/ [issue #155](https://github.com/hasanmanzak/meAndAI/issues/155) /
[draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) has locally
completed [SUBF-0138](../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#subf-0138),
the first clean-room `CSharpShadow` vertical slice. Follow the
[clean-room pivot handoff](log/2026-07-28-feat-0060-clean-room-pivot.md) and
[DEC-0033](../../docs/decisions/DEC-0033-specification-first-csharp-governance.md).
Canonical protocol, decision, feature, and numbered-scenario contracts design
C# behavior; project memory supplies context only, and PowerShell is a later
legacy black-box oracle rather than a translation source. The first slice
reuses canonical
[TEST-0004](../../docs/features/FEAT-0001-common-development-protocol/test-cases.md#test-0004)
for `protocol-authority`, repository-read-only, provider-free,
non-authoritative validation. Its Definition of Ready is 10/10 (100%);
implementation is 1/8 (12.5%), with exact-commit/hosted evidence and the other
seven subfeatures pending. The focused test first failed to compile in 7.9
seconds before production types existed; fresh review expanded the focused
suite to 28/28 in 5.5 seconds. The final full-solution rerun passed governance
28/28, architecture 31/31, and packaging 17/17 in 6.4 seconds. Locked restore, format,
portable publish, and the published-DLL real-repository run also passed; the
report retained `csharp-shadow` and `powershell-authority`.

The historical
[ledger inventory](../../docs/features/FEAT-0060-any-consumer-governance-cli/differential-ledger-analysis.md)
accounts for 188/188 active base identities, all seven explicit declaration
packets, and a separate proven lower bound of 116 TEST/case mappings. The
[rule/profile matrix](../../docs/features/FEAT-0060-any-consumer-governance-cli/rule-profile-matrix-analysis.md)
classifies the base universe into 43 C# candidates, 16 mixed boundaries, 94
retained PowerShell operations, 29 infrastructure contracts, three provider
identities, and three existing C# identities. The
[v1 decision packet](../../docs/features/FEAT-0060-any-consumer-governance-cli/contract-decision-packet.md)
was accepted by the maintainer on 2026-07-28 with an exact-pair shadow/release
boundary and independent severity/enforcement metadata. Exhaustive ledger and
matrix completion is deferred from bounded implementation/package sequencing,
not waived; it remains mandatory before equivalence, required-check
enforcement, authority transfer, or PowerShell retirement.

The earlier bounded canonical test harness and inert fixture changed under
[FIND-0365](../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0365);
that correction did not change workflow behavior. Replacement exact-head
[run `30366875189`](https://github.com/hasanmanzak/meAndAI/actions/runs/30366875189)
then exposed
[FIND-0366](../../docs/features/FEAT-0060-any-consumer-governance-cli/README.md#find-0366),
a stale Windows serial `Full` whole-job ceiling under
[TEST-0124](../../docs/features/FEAT-0027-v0104-runner-minute-efficiency/test-cases.md#test-0124).
Both findings are closed by exact final head
[`a573ad8b00f2939258ab59a3b06c13520733c186`](https://github.com/hasanmanzak/meAndAI/commit/a573ad8b00f2939258ab59a3b06c13520733c186)
and [run `30380421016`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016):
Ubuntu [job `90346608851`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346608851)
passed in 12 min 58 s and Windows
[job `90346609315`](https://github.com/hasanmanzak/meAndAI/actions/runs/30380421016/job/90346609315)
passed in 32 min 12 s, including a 30 min 46 s PowerShell 5.1 step. Linux
remains 20 minutes, post-publication remains 5, and consumer repositories,
production authority, and PowerShell production routes remain unchanged.

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
