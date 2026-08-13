# Agentic SDLC Workflow Successor Delivery Plan

| Field | Value |
| --- | --- |
| Status | Proposed planning; no implementation authority |
| Parent | [Issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
| Records review | Draft [PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) |
| Architecture | [Agentic SDLC Workflow Architecture](README.md) |
| Lifecycle owner | [FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md) |
| Execution owner | [FEAT-0070](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md) |
| Current records base | Exact main [`6ca42f56a48976093692dc4764c464ca185aa964`](https://github.com/hasanmanzak/meAndAI/commit/6ca42f56a48976093692dc4764c464ca185aa964) |

## 1. Program boundary

[FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
owns the explicit SDLC, work-item states, GitHub-native tracking state, and
consumer transition semantics.
[FEAT-0070](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
owns workflow contracts, alias resolution, canonical practice selection,
execution roles, context/handoff, and optional bounded orchestration.

Neither feature reopens the accepted executable protocol architecture in
[DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md).
Provider, release, and authority-transfer effects remain behind its exact
application plans and grants.

## Related-work reconciliation

The delivery history that produced the explicit SDLC/backlog proposal also
contained three independently owned remediation lines. This table preserves
their current canonical disposition so archiving the originating planning
conversation cannot hide unfinished work or make completed work appear
pending. It is a traceability boundary, not a new dependency graph or an
implementation grant.

| Work identity | Canonical state and evidence | Relationship to this program |
| --- | --- | --- |
| [FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md) / [issue #150](https://github.com/hasanmanzak/meAndAI/issues/150) | Open current-main re-intake in this records packet; obsolete [draft PR #151](https://github.com/hasanmanzak/meAndAI/pull/151) remains closed and unmerged prior art | The only earlier work line resumed here; future delivery is owned by [SUBF-0157](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0157), [SUBF-0158](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0158), and [SUBF-0159](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0159) after their entry gates close |
| [BUG-0045](https://github.com/hasanmanzak/meAndAI/issues/149) / [FEAT-0058](../../features/FEAT-0058-v0156-completed-historical-adoption-issues/README.md) | Complete in closed [issue #149](https://github.com/hasanmanzak/meAndAI/issues/149), merged [PR #152](https://github.com/hasanmanzak/meAndAI/pull/152), and immutable [v0.15.6](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.6) at [`5321f1f1aa5966114c69b46bf6ed9191df109e6b`](https://github.com/hasanmanzak/meAndAI/commit/5321f1f1aa5966114c69b46bf6ed9191df109e6b) | Historical adjacent delivery evidence only; no reimplementation, reopened scope, or remaining action in [issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
| [FIND-0120 / issue #44](https://github.com/hasanmanzak/meAndAI/issues/44) | Complete and closed after the required `main` repository controls were established | Historical external-control evidence only; it is not reopened or owned by [FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md) or [FEAT-0070](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md) |
| [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139) | Open planned handoff for live GitHub reference validation before merge; its issue remains the live tracker/state store for that separate work identity | Separate backlog item. This records packet does not implement, close, reprioritize, or absorb it; any implementation requires its own refreshed intake and explicit directive |

Only [FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
is resumed by this proposal. If later design work demonstrates a real
dependency on [BUG-0036 / issue #139](https://github.com/hasanmanzak/meAndAI/issues/139),
that relationship must be added explicitly from then-current evidence; it
cannot be inferred from their shared protocol or GitHub-governance subject
matter.

## 2. Dependency order

```mermaid
flowchart LR
    Records["Records-only architecture and proposed decisions"]
    Lifecycle["Explicit SDLC"]
    Schema["Workflow and alias schema"]
    Assess["Read-only gate and practice resolver"]
    Handoff["Context/handoff plus single-agent executor"]
    Multi["Bounded multi-agent topology"]
    Delivery["Provider and delivery integration"]
    Adoption["Immutable release and consumer adoption"]

    Records --> Lifecycle --> Schema --> Assess --> Handoff --> Multi
    Multi --> Delivery --> Adoption
```

The dependency direction is conservative. A later accepted design may permit a
read-only schema prototype before every [FEAT-0057](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md)
projection is executable, but no mutating workflow may infer lifecycle
authority from an incomplete state model.

## 3. Reviewable slices

| Order | Owning slice | Outcome | Planned evidence | Entry authority |
| --- | --- | --- | --- | --- |
| 0 | Current records packet | Promote the idea; propose architecture, decisions, risks, scenarios, and DoR gaps | Static records/link review only | Current documentation directive |
| 1 | [SUBF-0157](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0157) | Map discovery through retirement onto existing gates and separate state axes | [TEST-0224](../../features/FEAT-0057-explicit-sdlc-backlog-governance/test-cases.md#test-0224) | Future explicit implementation directive |
| 2 | [SUBF-0158](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0158) | Define work-item transitions, blocking, catalog, and backlog semantics | [TEST-0225](../../features/FEAT-0057-explicit-sdlc-backlog-governance/test-cases.md#test-0225) | Separate reviewed activation |
| 3 | [SUBF-0159](../../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md#subf-0159) | Define GitHub and consumer projection/transition boundaries | [TEST-0226](../../features/FEAT-0057-explicit-sdlc-backlog-governance/test-cases.md#test-0226) | Separate reviewed activation |
| 4 | [SUBF-0160](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md#subf-0160) | Add declarative Workflow Contract and alias-binding schema | [TEST-0227](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0227) | Accepted current-main design plus explicit directive |
| 5 | [SUBF-0161](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md#subf-0161) | Resolve lifecycle admission and applicable canonical directives read-only | [TEST-0228](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0228) and [TEST-0229](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0229) | Prior slice exact evidence |
| 6 | [SUBF-0162](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md#subf-0162) | Compile exact context/handoff and execute one read-only or low-risk single-agent pilot | [TEST-0230](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0230) and [TEST-0231](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0231) | Accepted pilot and exact authority boundary |
| 7 | [SUBF-0163](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md#subf-0163) | Add bounded team selection, read-only parallelism, one writer, and recursive-delegation denial | [TEST-0232](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0232) | Single-agent pilot closure |
| 8 | [SUBF-0164](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md#subf-0164) | Integrate delivery/protocol lifecycle only through exact grants and pinned distribution | [TEST-0233](../../features/FEAT-0070-agentic-sdlc-workflow-capabilities/test-cases.md#test-0233) | Required [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163) predecessors and new explicit directive |

Each implementation slice must be independently test-first, reviewed, and
integrated before its successor. This planning sequence is not standing
implementation authority.

## 4. Definition of Ready gaps

Before the first executable slice:

- accept, revise, or reject proposed
  [DEC-0037](../../decisions/DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md)
  and proposed
  [DEC-0038](../../decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md);
- inventory current lifecycle/status/label/form/template and consumer
  projection surfaces;
- select workflow identifiers, schema format, immutable release binding, and
  runtime state owner;
- choose the first read-only or records pilot;
- accept a concurrency ceiling and independent-review threshold;
- freeze exact applicability predicates, ambiguity behavior, context redaction,
  lease/expiry, retry, and recovery contracts;
- resolve required [EPIC-0002 / issue #163](https://github.com/hasanmanzak/meAndAI/issues/163)
  technical predecessors;
- select target versions and executable test owners;
- capture exact baseline and expected-red designs; and
- issue a separate directive naming one dependency-closed slice.

## 5. Verification budget

The current operation is records-only. Its local budget is:

1. exact changed-file inventory and scope audit;
2. Markdown/stable-link/static structural checks that do not start the full
   suite;
3. one fresh-diff independent review.

No production build, executable feature test, full protocol suite, release,
consumer simulation, or publication claim was part of the original packet.
ContractSlice C has since merged and this branch is reconciled with current
`main`; fresh exact-head hosted validation is now the remaining integration
gate. A dirty-worktree result cannot prove the new committed instruction graph.

## 6. Active-work isolation and merge order

This records branch remains isolated from active implementation checkouts.
It does not independently modify
[FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md),
its implementation, tests, architecture ledger, or current continuation.

The integration order and current disposition are:

1. ContractSlice C finished and merged first;
2. this branch reconciled with current `main`;
3. shared feature and memory indexes preserve ContractSlice C truth;
4. bounded static checks and fresh exact-head hosted validation must pass; and
5. this records proposal receives a separate readiness review before merge.

Shared index or memory conflicts are reconciliation work for this branch and
must not be solved by reverting, editing, or pausing the active checkout.

## 7. Future directive contract

A future implementation directive must identify:

- one linked owning subfeature;
- exact accepted predecessor commit;
- included and excluded files/effects;
- canonical test and expected-red route;
- real repository/provider authority;
- single-writer and delegation topology;
- recurrence safe responses and unsafe retry boundaries;
- validation budget and stop conditions; and
- merge, release, and consumer-adoption exclusions.

Generic instructions such as “implement the architecture” or a slash command
alone are insufficient authority.

## 8. Continuation and worktree closure

Until draft [PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) is
merged or explicitly closed, its isolated worktree and branch remain live
delivery state and must not be removed merely because the originating
conversation is archived. A future agent starts from this delivery plan,
refreshes the PR and issue state, and checks the current branch/worktree
registration rather than relying on a remembered local directory.

The current operator-local continuation is recorded in the
[project-memory handoff](../../../.ai/memory/log/2026-08-12-agentic-sdlc-workflow-architecture.md#continuation-and-cleanup-handoff).
It is a convenience pointer, not a portable path requirement.

Cleanup is a separate post-delivery operation and is admitted only when all of
the following are true:

1. [PR #181](https://github.com/hasanmanzak/meAndAI/pull/181) is merged or
   explicitly closed, and its disposition is reflected in the owning issues
   and durable records;
2. the registered worktree is clean, has no untracked files, and its exact head
   is reachable from the remote branch, merge commit, or another intentional
   durable ref;
3. no active task, process, shell, editor, or agent uses the worktree;
4. the primary checkout and every unrelated worktree are identified and
   excluded from the removal target; and
5. any required post-merge reconciliation, exact-head validation, and evidence
   synchronization is complete.

These guards are necessary but not sufficient authority. This records-only
handoff grants no cleanup permission; after every guard passes, a separate
explicit maintainer directive naming the cleanup target is still required.
Under that directive, inspect the exact registered and prunable candidates
first, remove only the exact registered records worktree through Git worktree
management, prune only confirmed stale worktree metadata, and then delete the
local records branch if it is no longer checked out. Delete the remote branch
only when the explicit directive includes it and the pull-request disposition
and repository policy make that cleanup appropriate. Never use recursive
filesystem deletion as a substitute for worktree removal, never force-remove a
dirty worktree, and never touch any active implementation checkout or its user-owned
files.
