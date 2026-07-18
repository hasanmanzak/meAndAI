# FEAT-0030 - v0.11.0 Optional Stability Cycle Agent Prompt

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.11.0 |
| Issue and post-publication authority | [#77](https://github.com/hasanmanzak/meAndAI/issues/77) |
| Pull request | [#78](https://github.com/hasanmanzak/meAndAI/pull/78) |
| Decisions | [DEC-0015](../../decisions/DEC-0015-event-triggered-stability-cycles.md); [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md) |
| Tests | [TEST-0131 and TEST-0132](test-cases.md) |

## Problem and intended outcome

The common protocol and DEC-0015 already define the normative event-triggered
stability and consistency cycle. Maintainers do not yet have one copy-ready,
bounded prompt for asking an AI agent to execute that cycle through a tool's
optional recurring-task or goal mechanism. Calling the artifact a goal or
installing it automatically would incorrectly imply self-scheduling,
background execution, or authority the protocol does not grant.

Publish one canonical optional agent prompt. A maintainer may copy or reference
it when configuring their own task or goal. The artifact never creates,
schedules, or activates one. It remains subordinate to the immutable protocol
pin and repository-local instructions, defaults to report-only, and requires
separate explicit authority for a converged review-branch push. Report-only may
prove local convergence, but it cannot claim full cycle completion or
`Waiting`; it reports the push-eligible state as `Blocked` on missing
final-push authority.

## Scope

- Add a small `docs/agent-prompts` index and one canonical stability-cycle
  prompt.
- Preserve DEC-0015 lifecycle, disposition, dependency, review, boundedness,
  waiting, blocked, and publication semantics in the prompt.
- Make the artifact reachable from this repository, submodule consumers, and
  repository-reference consumers through the immutable protocol source.
- Link it from the mandate and adoption documentation as optional,
  non-normative guidance.
- Add compact structural tests for fidelity, reachability, and non-activation.

## Non-goals

- Creating a Codex goal, automation, heartbeat, schedule, background loop,
  workflow, daemon, or recurring task.
- Copying or installing the prompt into consumer-owned files.
- Adding a second normative stability contract, a second project scan, or a
  validator-for-validator chain.
- Granting commit, push, PR, merge, tag, GitHub Release, issue-closing, or
  branch-deletion authority.
- Changing the quick-adoption Codex prompt, consumer `AGENTS.md` templates,
  updater managed paths, or migration catalog.

## Contracts and compatibility

- Normative authority remains the consumer's pinned `PROTOCOL.md`, DEC-0015,
  and applicable repository-local instructions. The prompt summarizes an
  invocation contract and cannot override them.
- Invocation is event-triggered. With no material development and no new
  failed evidence, an unchanged `Waiting` tree stops without a scan.
- Every observation receives one Gate 5 disposition; only unresolved
  `Blocking` findings enter the dependency-first remediation queue.
- Each correction receives focused evidence, relevant tests, and fresh-diff
  self-review before the next independent item. A correction-caused or exposed
  blocker remains in the same queue.
- An initially clean scan is convergence evidence. Remediation permits one
  confirmation scan; unchanged confirmation loops are prohibited.
- The prompt declares a finite validation budget and reports `Blocked` when
  authority, dependency, or required input is unavailable.
- `Publication mode` is `report-only` by default. Only explicit
  `push-review-branch` authority permits the ordinary converged final push.
  Local convergence in report-only remains an incomplete cycle blocked on
  final-push authority; neither mode creates a tag or GitHub Release.
- meAndAI maintainers use `docs/agent-prompts/...`; submodule consumers use the
  same file below `.ai/protocol`; repository-reference consumers resolve the
  same path at their configured immutable ref. No consumer-owned copy exists.

## Risks

| ID | Classification | Risk | Response and required evidence |
| --- | --- | --- | --- |
| `RISK-0135` | Autonomous-loop ambiguity | A reusable prompt is mistaken for a self-running goal | Explicit opt-in/non-scheduling contract and `TEST-0132` |
| `RISK-0136` | Authority expansion | The prompt assumes push or release authority | Report-only default, explicit publication mode, no-tag/release wording, and `TEST-0131` |
| `RISK-0137` | Normative drift | Prompt wording diverges from DEC-0015 | Section-bound structural assertions and direct authority links in `TEST-0131` |

## Readiness evidence

| Field | Declaration |
| --- | --- |
| Baseline | FEAT-0015 and DEC-0015 are complete and normative in protocol 0.10.4 |
| Entry points | Maintainer copy/reference; immutable submodule path; immutable repository-reference path |
| Consumers | meAndAI maintainers and consumer-repository maintainers using any agent/task product |
| Compatibility | Documentation-only opt-in surface; no consumer-owned or managed automation path changes |
| Validation budget | Structural tests first, one documentation slice, fresh-diff review, then shared full-project convergence scan |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0131 and TEST-0132](test-cases.md) |
| Test code | Passed | Repository structural suite owns and passes `TEST-0131` and `TEST-0132` |
| Baseline run | Green inherited baseline | Existing TEST-0096 through TEST-0099 prove the normative cycle |

## Decomposition and review gate

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0055` | Optional prompt, index, consumer reachability, and structural contract | [Issue #77](https://github.com/hasanmanzak/meAndAI/issues/77) | `TEST-0131`, `TEST-0132`; passed | Fidelity, authority, reachability, and no-activation diff; no open `Blocking` finding | Complete |

## Relationships

- Normative mandate: [FEAT-0015](../FEAT-0015-stability-consistency-mandate/README.md)
- Event-triggered cycle decision: [DEC-0015](../../decisions/DEC-0015-event-triggered-stability-cycles.md)
- Bounded convergence decision: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Tracking and post-publication authority: [Issue #77](https://github.com/hasanmanzak/meAndAI/issues/77)

## Definition of Ready

- [x] Stable feature, subfeature, risk, test, and issue identities exist.
- [x] Existing normative decisions are linked; no new decision is required
      because scheduling, installation, ownership, and authority do not change.
- [x] Problem, outcome, scope, non-goals, consumers, entry points,
      compatibility, authority, and error boundaries are explicit.
- [x] Two numbered structural scenarios and the verification approach are
      defined before implementation.
- [x] The artifact is one bounded documentation slice and has a finite review
      budget.

## Acceptance criteria

1. One copy-ready prompt faithfully covers the material-change trigger, scan,
   dispositions, dependency-first queue, sequential correction, tests,
   self-review, change-caused blockers, finite confirmation, convergence,
   waiting, and blocked outcomes.
2. The prompt explicitly creates no task, goal, schedule, workflow, or
   background execution and cannot start its next invocation.
3. Report-only is the default and may prove local convergence, but it must
   report the cycle incomplete and `Blocked` on missing final-push authority.
   Only an explicitly authorized review-branch push completes the cycle and
   enters `Waiting`; no mode authorizes a tag or GitHub Release.
4. The common protocol remains normative and the prompt cannot override
   repository-local instructions.
5. Both consumer integration models can resolve the artifact through their
   immutable protocol source without a consumer-owned copy or updater change.
6. Structural tests and documentation-link checks pass with no unresolved
   `Blocking` finding.

## Self-review and mandate evidence

The canonical prompt, its index, protocol/adoption links, immutable consumer
routes, and negative no-installation boundary pass structural validation and
fresh-diff review. The artifact remains report-only by default and does not
create or activate a goal, recurring task, automation, workflow, schedule,
background loop, or next invocation. Its local-convergence and full-completion
states now match the normative final-push boundary. Shared
FEAT-0029/FEAT-0030 convergence reports no unresolved `Blocking` finding.

## Definition of Done

- [x] Acceptance criteria met in the focused structural scope.
- [x] TEST-0131 and TEST-0132 have executable ownership and pass structure-only validation.
- [x] Fresh-diff review and bounded full-project convergence complete.
- [x] Documentation, links, changelog, version, and memory agree.
- [ ] Pull request, hosted checks, review, merge, branch cleanup, immutable
      v0.11.0 release, and post-publication evidence complete.

## Post-merge publication evidence

[Issue #77](https://github.com/hasanmanzak/meAndAI/issues/77) is the stable
external authority and [PR #78](https://github.com/hasanmanzak/meAndAI/pull/78)
is the current draft delivery. Checks, review, merge, branch cleanup, release,
tag, commit, asset, and post-publication verification remain `Pending` until
they exist.
