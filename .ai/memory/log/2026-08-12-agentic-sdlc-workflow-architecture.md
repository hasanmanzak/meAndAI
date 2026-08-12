# 2026-08-12 - Agentic SDLC Workflow Architecture Planning

## Status

Records-only proposed architecture at exact base
[`6ca42f56a48976093692dc4764c464ca185aa964`](https://github.com/hasanmanzak/meAndAI/commit/6ca42f56a48976093692dc4764c464ca185aa964).
No implementation, protocol behavior, executable test, workflow, consumer,
merge, release, or authority-transfer permission is granted.

## Canonical records

- [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179)
  owns the proposed program.
- [FEAT-0057](../../../docs/features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
  refreshes the distinct SDLC/backlog scope retained by
  [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150). The obsolete
  [closed draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151) is
  prior art only.
- [FEAT-0070](../../../docs/features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
  owns Workflow Contracts, alias resolution, directive applicability,
  execution roles, context/handoff, and bounded multi-agent execution.
- Proposed [DEC-0037](../../../docs/decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md)
  keeps lifecycle state, readiness, authorization, review, merge, publication,
  and operation separate.
- Proposed [DEC-0038](../../../docs/decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md)
  makes commands thin aliases, roles non-granting responsibility boundaries,
  and single-agent execution the default.
- The complete [architecture](../../../docs/architecture/agentic-sdlc-workflows/README.md)
  and [delivery plan](../../../docs/architecture/agentic-sdlc-workflows/delivery-plan.md)
  record DRN prior art, accepted constraints, open choices, dependencies,
  future slices, tests, and the authority freeze.

## Retained decisions

- The existing Gate 0 through Gate 7 lifecycle remains canonical; workflow-run
  state and protocol application state are separate.
- Commands such as `/develop`, `/review`, and `/document` are examples rather
  than a closed vocabulary and own no rules.
- DDD, Rich Entity Model, TDD, SOLID, and documentation-graph requirements are
  canonical references selected by applicability, not copied command text.
- Actor identity, role, writer lease, and real grant remain separate.
- One agent handles ordinary work. The proposed first team ceiling is one
  orchestrator plus two workers, no parallel writers, and no recursive
  delegation.
- Exact context/handoff includes base, scope, authority, recurrence, acceptance,
  tests, budget, expiry, result, findings, and stale-state evidence; it cannot
  bypass mandatory instruction or recurrence reads.

## Open entry gates

Maintainer acceptance is still required for both proposed decisions, lifecycle
vocabulary, workflow schema/identity and release binding, first pilot, runtime
state owner, directive applicability, ambiguity handling, context redaction,
team ceiling, independent-review threshold, target versions, executable owners,
expected-red designs, validation budgets, and required
[EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
predecessors. A later directive must name one dependency-closed subfeature and
exact effect boundary.

## Records-packet verification

- `git diff --cached --check` passed before the first records commit, and
  `git diff --check HEAD^ HEAD` passed on exact commit
  [`3c8fd95c8bfdf2746006699073544659775a72e6`](https://github.com/hasanmanzak/meAndAI/commit/3c8fd95c8bfdf2746006699073544659775a72e6).
- Independent fresh-diff review closed at
  `0 Blocking / 0 Important / 0 Minor`, with no accepted residual,
  external/legacy follow-up, or optional improvement. This was a records-scope
  review, not Gate 5 implementation review.
- `pwsh -NoProfile -File tests/protocol.tests.ps1 -StructureOnly` was attempted
  on the committed tree and produced no result before the bounded 184-second
  local timeout. The observation is inconclusive, not red or green evidence;
  the unchanged broad route was not retried. Full tests, builds, hosted fan-out,
  and feature execution were not run by this records operation.

## Active-work isolation

The proposal was prepared in a separate worktree and does not edit
[FEAT-0065](../../../docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md)
or the active ContractSlice C checkout. ContractSlice C should merge first.
This branch must then reconcile shared indexes/memory with current `main`,
preserve C truth, rerun bounded static validation, and require fresh exact-head
hosted evidence before the records proposal can leave draft state.
