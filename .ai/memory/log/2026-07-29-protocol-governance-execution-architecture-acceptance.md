# 2026-07-29 - Protocol Governance and Execution Architecture Acceptance

## Outcome

The maintainer accepted
[DEC-0035](../../../docs/decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md)
and the complete
[Protocol Governance and Execution Architecture](../../../docs/architecture/protocol-governance-and-execution/README.md).
The accepted product boundary is one versioned executable protocol platform
implemented in C#. CLI processes, workflows, and provider runners are
least-authority hosts or adapters; they do not own rule semantics, application
lifecycles, or release identity.

Acceptance is architecture and planning authority only. No implementation,
test implementation, WIP extraction, workflow or ruleset change, consumer or
provider mutation, release publication, trust-anchor transfer, compatibility
retirement, or PowerShell deletion is authorized.

## Stable successor allocation

- [FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md)
  / [issue #165](https://github.com/hasanmanzak/meAndAI/issues/165) owns shared
  conformance, catalog, evaluator, typed evidence/report, extensions,
  qualification, and self-consumption.
- [FEAT-0066](../../../docs/features/FEAT-0066-shared-execution-authority-foundation/README.md)
  / [issue #166](https://github.com/hasanmanzak/meAndAI/issues/166) owns shared
  authority snapshots, grants, activation CAS, leases/fences, journal,
  receipts, reconstruction, and recovery.
- [FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md)
  / [issue #167](https://github.com/hasanmanzak/meAndAI/issues/167) owns exact
  Git/GitHub evidence, Trust Bootstrap, immutable resolution, managed hook,
  evaluator hosting, and separated result publication.
- Rescoped [FEAT-0061](../../../docs/features/FEAT-0061-consumer-adoption-cli/README.md)
  / [issue #156](https://github.com/hasanmanzak/meAndAI/issues/156) owns the
  adoption application.
- Rescoped [FEAT-0062](../../../docs/features/FEAT-0062-consumer-protocol-update-cli/README.md)
  / [issue #157](https://github.com/hasanmanzak/meAndAI/issues/157) owns the
  update application.
- [FEAT-0068](../../../docs/features/FEAT-0068-protocol-release-finalizer-authority-transfer/README.md)
  / [issue #168](https://github.com/hasanmanzak/meAndAI/issues/168) owns
  predecessor-trusted release finalization, fresh verification, and distinct
  authority transfer.
- Parked [FEAT-0063](../../../docs/features/FEAT-0063-consumer-migration-powershell-retirement/README.md)
  / [issue #158](https://github.com/hasanmanzak/meAndAI/issues/158) owns
  compatibility qualification, supported-consumer authority migration, and
  eventual dependency-proven PowerShell retirement.

The canonical dependency, surface, first-rule, test, and gate mapping is the
[successor delivery plan](../../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md).

## Shared-rule model

The first stable identities,
[RULE-0001](../../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0001)
through
[RULE-0005](../../../docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md#rule-0005),
cover feature/decision document structure, exact cross-record links, embedded
record anchors, and exact commit permalinks. They deliberately exercise
repository and provider evidence without making links the complete governance
scope. Later catalog work must inventory files, documents, GitHub records,
workflows, releases, migrations, authority evidence, and other normative
contracts under stable rule identities.

Rule semantics are owned by
[FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md).
Repository and provider enumeration, pagination, freshness, and completeness
are owned by
[FEAT-0067](../../../docs/features/FEAT-0067-evidence-acquisition-managed-consumer-integration/README.md).
For example,
[TEST-0176](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0176)
remains qualification evidence for one common semantic rule; it is not
duplicated as a consumer or GitHub-only validator.

## Preserved WIP

[Draft PR #160](https://github.com/hasanmanzak/meAndAI/pull/160) remains open,
draft, and frozen at exact commit
[1873c98638ba4960734aadb188eb8c8d70b4bc52](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52).
The [extraction ledger](../../../docs/architecture/protocol-governance-and-execution/wip-extraction-ledger.md)
classifies every path in its 158-file diff. Useful identity, evaluator,
parser/index, exact-Git, process-runner, report, and packaging behavior may be
reintroduced only as the smallest dependency-closed item under a successor
feature with fresh expected-red/green evidence. CLI product boundaries,
two-profile policy, hard-coded two-rule catalog, permanent legacy engine
states, repository-only locations, workflow wiring, project graph, lock files,
and package-CLI grammar are not carried forward.

Four of seven WIP subfeatures retain historical exact-branch evidence. The
parent was not completed, merged, released, or granted authority, and no
successor inherits a passing state.

## Validation and continuation

The architecture packet uses no workflow change and must be committed with
[skip ci]. After the complete documentation graph is committed, run only the
canonical StructureOnly entry point in PowerShell 7 and Windows PowerShell 5.1
on the same clean exact head. Record exact commands, environments, full SHA,
clean-tree checks, and results externally on
[TASK-0003 / issue #164](https://github.com/hasanmanzak/meAndAI/issues/164);
do not create an evidence-only follow-up commit.

Do not start C#. A later maintainer directive must name one dependency-closed
feature or subfeature whose Definition of Ready includes expected-red evidence
and Gate 2 review. [FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md)
and [FEAT-0066](../../../docs/features/FEAT-0066-shared-execution-authority-foundation/README.md)
are the two shared foundations; neither is implicitly authorized by this
handoff.
