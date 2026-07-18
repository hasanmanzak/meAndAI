# FEAT-0029 - v0.11.0 Protocol-Aware Initial Adoption

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.11.0 |
| Issue and post-publication authority | [#76](https://github.com/hasanmanzak/meAndAI/issues/76) |
| Pull request | Pending |
| Decision | [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md) |
| Tests | [TEST-0127 through TEST-0130](test-cases.md) |

## Problem and intended outcome

Initial adoption currently classifies repositories only by collisions with the
canonical meAndAI target paths. A repository with a different governance or AI
protocol can therefore look identical to a populated repository with no prior
protocol. The launcher cannot ask whether the maintainer wants semantic full
migration, explicit hybrid reconciliation, or a clean governance start, and an
agent can silently choose a policy that belongs to the maintainer.

Add a bounded strategy gate before initial-adoption mutation. A verified
protocol-free repository uses `FreshAdoption`; a repository with detected
protocol surfaces requires `FullMigration`, `HybridReconciliation`,
`CleanStart`, or `Abort`. The launcher may receive the choice as a parameter or
ask interactively. Non-interactive ambiguity fails closed. The chosen strategy
is an immutable adoption input and the semantic actor applies it without
changing application behavior or inventing project facts.

## Scope

- Add `Auto`, `FreshAdoption`, `FullMigration`, `HybridReconciliation`,
  `CleanStart`, and `Abort` initial-adoption strategy semantics.
- Inventory a small declared set of likely protocol and governance surfaces;
  report exact detected paths without building a universal protocol parser.
- Add interactive selection and explicit non-interactive behavior to the
  single-file quick launcher.
- Require a separate loss acknowledgement for `CleanStart`.
- Bind the resolved strategy and detected surfaces through workflow dispatch,
  the transient manifest, proposal ownership marker, project adoption issue,
  and local Codex prompt.
- Prevent default-branch push or schedule events from starting an unselected
  initial migration while preserving completed-consumer update/finalization
  routes.
- Define semantic preservation, precedence, deletion, project-directive,
  application-content, rerun, and compatibility boundaries.
- Update adoption guidance, structural evidence, version, changelog, and
  project memory.

## Non-goals

- A universal governance scanner, semantic validator, compatibility registry,
  background service, or recursive bootstrap layer.
- Letting an AI agent select or change the maintainer's strategy.
- Automatically resolving semantic conflicts, fabricating historical records,
  or creating retroactive GitHub issues and pull requests.
- Deleting application source, assets, product documentation, tests, runtime
  configuration, or product behavior under any strategy.
- Preserving legacy filenames, identifiers, or topology during
  `FullMigration` when their semantics have been rehomed.
- Leaving two ambiguous common-protocol authorities after
  `HybridReconciliation`.
- Applying initial-adoption strategy selection to an already completed
  meAndAI consumer update.

## Contracts and compatibility

### Strategy resolution

- `Auto` resolves to `FreshAdoption` only when the bounded inventory contains
  no existing protocol surface. Generic target collisions still require a
  manifest-only semantic review, but do not count as migration evidence. With
  evidence present, an interactive run presents the inventory and asks; a
  non-interactive run stops before repository, secret, seed, branch, issue,
  pull-request, or Codex mutation.
- Explicit `FreshAdoption` is an assertion and fails when protocol evidence is
  present. Conversely, full migration, hybrid reconciliation, and clean start
  require detected protocol evidence and fail on an evidence-free repository,
  even when a generic target collision needs semantic review. `Abort` exits
  without adoption mutation.
- `FullMigration` preserves valid project semantics, directives, decisions,
  scope, dependencies, risks, test intent, and approvals while retiring the
  legacy protocol as live authority. Git history remains the historical
  source; a permanent compatibility ledger is not created.
- `HybridReconciliation` preserves selected existing structures only after a
  consumer decision records ownership and precedence. The pinned meAndAI
  protocol remains the common authority, while project-specific directives
  remain consumer-owned.
- `CleanStart` imports no legacy governance semantics and may remove only the
  detected and reviewed protocol/governance record surfaces. It requires
  `AcknowledgeProtocolRecordLoss`; application and product content remain out
  of deletion scope.

### Inventory and handoff

- The inventory is a bounded path classifier over the exact proposal-parent
  tree. It recognizes declared root instruction files and declared protocol,
  agent-rule, governance, feature, decision, finding, and memory roots. It does
  not interpret arbitrary project content or infer semantic equivalence.
  Reserved protocol state at `.ai/protocol`, below `.ai/protocol/`, and at
  `.ai/meandai-update-state.json` is always migration evidence; `Auto` cannot
  classify an incomplete or legacy reserved footprint as fresh. Active
  path-specific GitHub Copilot instructions below `.github/instructions/` are
  also declared protocol evidence.
- The exact immutable capabilities contract module is the single pure-policy
  authority for relevant-path classification, canonical policy casing,
  surface inventory, strategy resolution, and migration/CleanStart authority
  predicates. The standalone launcher loads that module read-only before any
  adoption mutation; the workflow adapter imports the same pinned module.
  Each actor retains only its own Git/GitHub evidence, containment, TOCTOU,
  tree/mode continuity, and mutation-boundary checks. No actor re-validates a
  second classifier implementation.
- Classification as evidence does not by itself grant write or deletion
  authority. Unambiguous instruction, rule, memory, known legacy `ai/`
  governance, `docs/governance/`, `docs/agent-prompts/`, and reserved
  `.ai/protocol/` records can be reconciled under the selected migration
  strategy. Ambiguous records such as root product/release documents or
  existing `docs/features/`, `docs/decisions/`, `docs/findings/`, and
  `docs/ideas/` content remain read-only evidence. `FullMigration` and
  `HybridReconciliation` may preserve and reference them; `CleanStart` stops
  before mutation when discarding them cannot be proven governance-only.
- Every canonical managed target and ancestor uses exact casing. A case
  variant is rejected before proposal mutation rather than treated as an
  independent consumer path.
- The selected strategy and exact sorted surface paths are carried in a new
  manifest schema and proposal marker. Existing immutable releases retain
  their original schemas. New code reads legacy proposals only for the bounded
  recovery meaning already encoded in those records; a legacy collision
  proposal that needs a new migration-policy choice must be closed and
  reassessed rather than retroactively relabeled. New proposals use only the
  strategy-bound representation.
- A rerun may reuse a proposal only when its strategy, surfaces, base head,
  target, protocol commit, branch, actor, and head remain exact. A different
  strategy requires an explicit new assessment; it is not retargeted silently.
- The local Codex prompt receives the resolved strategy as a command, not a
  suggestion. Discovering an additional governance surface or a required
  deletion outside the approved inventory blocks and reports the needed
  re-plan.
- A repository without a committed `HEAD` may contain only the two fixed local
  credential files and the exact canonical seed workflow. Application or
  governance files must be committed first so the isolated assessment cannot
  omit them.

### Event and ownership boundaries

- Initial adoption is launcher/manual-dispatch owned. A seed `push` or
  scheduled run without a resolved strategy does not create an initial
  migration proposal. Completed consumers continue through the existing
  updater and merge-finalization routes.
- Launcher, workflow, and recovery publication validate the committed tree
  after every created commit, require a clean index/worktree, rebind the live
  repository and default-branch identity, and publish only after those checks.
- `.ai/protocol` and its `VERSION` remain the common live authority.
  Repository-specific directives belong in root or scoped `AGENTS.md`, local
  memory, consumer decisions/features/findings/tests, or other explicitly
  consumer-owned surfaces.
- The transient manifest and migration assessment disappear when adoption is
  complete. The consumer's adoption feature and decision records retain the
  durable strategy outcome and semantic mapping rationale.

## Risks

| ID | Classification | Risk | Response and required evidence |
| --- | --- | --- | --- |
| `RISK-0129` | Destructive loss | `CleanStart` removes product or application content | Separate loss acknowledgement, governance-only allowlist, change-set validation, and `TEST-0129` |
| `RISK-0130` | Authorization drift | The agent or a rerun changes the selected strategy | Strategy-bound manifest/marker/issue/prompt identity and mismatch rejection in `TEST-0128` / `TEST-0130` |
| `RISK-0131` | Event race | The seed push creates a proposal before interactive selection | Initial push/schedule no-proposal gate and explicit dispatch evidence in `TEST-0128` |
| `RISK-0132` | Dual authority | Hybrid mode leaves contradictory protocols active | Mandatory precedence decision and semantic conflict evidence in `TEST-0129` |
| `RISK-0133` | Semantic loss | Full migration deletes legacy records before preserving valid meaning | Mapping-first prompt contract, review boundary, and full-migration fixture in `TEST-0129` |
| `RISK-0134` | False freshness | A known legacy protocol surface is missed and `Auto` chooses fresh adoption | Shared bounded classifier contract, positive/negative fixtures, and fail-closed unknown discovery in `TEST-0127` / `TEST-0130` |
| `RISK-0138` | Credential exposure | A linked token input or consumer Git hook observes plaintext credential material | Exact root regular-file validation, read-time revalidation, invocation-scoped hook suppression, and `TEST-0130` |

## Readiness evidence

| Field | Declaration |
| --- | --- |
| Baseline | Clean synchronized `main` at `e226293`, protocol `0.10.4`; the merged v0.10.4 complete suite is green |
| Entry points | Single-file launcher, consumer lifecycle workflow, pure capabilities resolver, bootstrap adapter, local Codex prompt |
| Consumers | New/protocol-free repositories, repositories with legacy governance, completed meAndAI consumers, submodule consumers, and repository-reference consumers |
| Semantic types | Strategy enum, bounded canonical path inventory, Boolean loss acknowledgement, exact proposal-parent/head identities, and manifest/marker schema identities |
| Error model | Unknown, contradictory, missing, drifted, non-interactive, unacknowledged-loss, or changed-head state stops before the next mutation boundary |
| Compatibility | Existing completed consumers and releases through v0.10.4 retain their updater route and immutable schemas; new proposals use v0.11.0 strategy binding |
| Validation budget | Tests first; two implementation slices; fresh-diff review after each; one complete suite; one bounded post-development scan and at most one confirmation after remediation |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0127 through TEST-0130](test-cases.md) |
| Test code | Passed | Pure policy, adapter, launcher, and structural suites own and pass `TEST-0127` through `TEST-0130` |
| Baseline run | Green inherited baseline | v0.10.4 complete suite recorded by FEAT-0028; branch baseline is clean |

## Decomposition and review gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0053` | Pure strategy/inventory resolver, workflow event gate, manifest and proposal identity | [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76) | `TEST-0127`, `TEST-0128`; passed | Exact enum/path/schema/event diff and negative matrix; no open `Blocking` finding | Complete |
| `SUBF-0054` | Launcher selection, strategy-specific semantic prompt, deletion boundary, recovery, and guidance | [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76) | `TEST-0129`, `TEST-0130`; passed | Parameter/prompt/change-set/recovery diff and negative matrix; no open `Blocking` finding | Complete |

## Relationships

- Initial adoption lifecycle: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md) / [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Local semantic completion: [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md) / [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Adoption containment: [FEAT-0009](../FEAT-0009-adoption-integrity/README.md) / [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md)
- Consumer transition migrations: [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) / [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
- Strategy decision: [DEC-0021](../../decisions/DEC-0021-explicit-initial-adoption-strategy.md)
- Tracking and post-publication authority: [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76)

## Definition of Ready

- [x] Stable feature, subfeature, risk, test, decision, and issue identities exist.
- [x] Problem, outcome, scope, non-goals, entry points, consumers, dependencies,
      semantic types, ownership, compatibility, errors, and mutation boundaries
      are explicit.
- [x] Strategy resolution and every mode's preservation/deletion semantics are
      measurable.
- [x] The work is split into resolver/handoff and launcher/semantic slices.
- [x] Numbered success, failure, recovery, event-race, and destructive-boundary
      scenarios are defined before behavior implementation.
- [x] Baseline, test-first approach, finite validation budget, repeat rule, and
      stop condition are recorded.

## Acceptance criteria

1. `Auto` selects `FreshAdoption` only with no detected protocol evidence;
   otherwise interactive selection is required and non-interactive use fails
   before adoption mutation.
2. Explicit invalid, contradictory, or mismatched strategy input fails closed;
   `Abort` leaves repository/GitHub adoption state unchanged.
3. `CleanStart` cannot proceed without explicit record-loss acknowledgement,
   and no strategy authorizes adding, modifying, type-changing, or deleting
   application or product content.
4. Full migration preserves valid semantics while removing legacy common
   authority; hybrid reconciliation records one explicit precedence decision;
   clean start imports no legacy governance semantics.
5. The workflow creates no unselected initial proposal from seed push or
   schedule, while completed-consumer update and finalization routes remain
   unchanged.
6. The resolved strategy and exact surface inventory remain consistent through
   dispatch, manifest, marker, issue, Codex prompt, rerun, and completion.
7. Drift in strategy, inventory, base/head, marker, acknowledgement, or changed
   paths blocks without partial publication or silent retargeting.
8. New schemas remain exact. Legacy immutable proposal schemas retain only
   their encoded bounded recovery meaning; a collision proposal requiring a
   new policy choice blocks for close-and-reassessment.
9. Documentation explains every mode, command-line and interactive usage,
   non-interactive behavior, data-loss boundary, and consumer ownership rule.
10. Focused suites and the complete repository suite pass with no unresolved
    `Blocking` finding.
11. Linked/reparse credential inputs fail before authentication or upload, and
    launcher-owned Git operations cannot execute consumer or global hooks while
    local token inputs may be present.

## Self-review and mandate evidence

The implementation review identified and closed containment, live-base drift,
preflight, event-routing, collision-identity, credential-link, Git-hook,
empty-remote all-ref race, and duplicated-policy gaps. The exact immutable
capabilities module is now the single pure-policy authority; launcher and
workflow actors retain only their distinct evidence and mutation guards. One
status-aware completion envelope covers normal and recovery publication,
rechecks the canonical base before publication and readiness, and binds the
strategy and exact surface identity across every handoff.

The pure-policy assertions, full adapter suite, five focused launcher shards,
combined `-Shard All` launcher harness, complete repository suite, PowerShell
parsing, diff hygiene, and independent fresh-diff review pass. The bounded
convergence scan reports no unresolved `Blocking` finding.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario ownership complete.
- [x] Both subfeature review gates and declared local suites pass.
- [x] Bounded post-development scan converges with no unresolved `Blocking`
      finding.
- [x] Documentation, links, changelog, version, and project memory agree.
- [ ] Pull request, hosted checks, review, merge, branch cleanup, immutable
      v0.11.0 release, and post-publication evidence complete.

## Post-merge publication evidence

[Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76) is the stable
external authority. Exact pull request, checks, merge, branch cleanup, release,
tag, commit, asset, and post-publication verification remain `Pending` until
they exist.
