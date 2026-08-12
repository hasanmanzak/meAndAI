# Agentic SDLC Workflow Successor Delivery Plan

| Field | Value |
| --- | --- |
| Status | Proposed planning; no implementation authority |
| Parent | [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179) |
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

No production build, executable feature test, full protocol suite, hosted
fan-out, release verification, consumer simulation, or publication claim is
part of this packet. Exact-head hosted validation is a later draft-exit
prerequisite after ContractSlice C merges and this branch is reconciled with
then-current `main`; it is not authorized by the current records operation. A
dirty-worktree result cannot prove the new committed instruction graph.

## 6. Active-work isolation and merge order

This records branch is intentionally isolated from the active ContractSlice C
checkout. It does not modify
[FEAT-0065](../../features/FEAT-0065-shared-executable-conformance-runtime/README.md),
its implementation, tests, architecture ledger, or current continuation.

The safest integration order is:

1. keep this proposal as a draft;
2. allow the active ContractSlice C delivery to finish and merge first;
3. reconcile this branch with the then-current `main`;
4. preserve ContractSlice C truth in shared feature and memory indexes;
5. rerun the bounded static link/scope checks and require fresh exact-head
   hosted validation; and
6. review this records proposal for readiness separately.

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
