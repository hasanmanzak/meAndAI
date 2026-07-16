# FEAT-0015 - Add the Stability and Consistency Mandate

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.9.0 |
| Issue and post-publication authority | [#47](https://github.com/hasanmanzak/meAndAI/issues/47) |
| Pull request | [#48](https://github.com/hasanmanzak/meAndAI/pull/48) |
| Decisions | [DEC-0015](../../decisions/DEC-0015-event-triggered-stability-cycles.md); [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md) |
| Tests | [TEST-0096 through TEST-0099](test-cases.md) |

## Problem

The protocol contains the necessary review, finding-disposition, and bounded
full-project scan controls, but they are distributed across several gates. It
does not yet express the maintainer's persistent operating mandate as one clear
cycle for this repository and every consumer: scan after development, order
actionable findings by dependency and priority, resolve them sequentially with
self-review, publish only a converged tree, and then wait for the next material
development event.

Without an explicit contract, `release` can be confused with a GitHub Release,
priority can be applied before dependencies, a fix-created defect can escape
into later work, or persistence can be interpreted as an unchanged autonomous
scan loop.

## Outcome

`PROTOCOL.md` defines one event-triggered stability and consistency mandate.
The current repository inherits it recursively, consumers inherit it through
their reviewed protocol pin, feature and pull-request templates collect its
evidence, and structural scenarios reject lifecycle, ordering, review, or push
wording that weakens the contract.

## Scope

- Add the mandate to the existing bounded self-validation and full-project scan
  lifecycle without adding another scanner.
- Define development triggers, zero-`Blocking` convergence, waiting and re-entry
  states, dependency-first queue order, and blocked outcomes.
- Require focused evidence and fresh-diff self-review for each finding or
  smallest inseparable dependency group.
- Keep every change-caused or change-exposed `Blocking` defect in the active
  queue until resolved.
- Define the terminal mandate action as a converged final Git push, distinct
  from tags and GitHub Releases.
- Make the contract available prospectively to exact-pin consumers and update
  active version, templates, adoption guidance, changelog, and project memory.
- Add compact structural regression coverage to the existing repository test
  suite and scenario-ownership map.

## Non-goals

- A background agent, scheduler, scanner service, reusable scan engine,
  recursive bootstrapper, or validator-for-validator chain.
- Repeating an unchanged scan or continuing after the finite budget is
  exhausted.
- Requiring literally zero observations; non-blocking dispositions remain
  visible under their existing evidence contracts.
- Automatically rewriting consumer-owned `AGENTS.md`, memory, feature/decision
  records, or tests during a compatible update.
- Resolving [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) or
  changing its external/legacy disposition.
- Treating an ordinary mandate cycle as a protocol tag or GitHub Release.

## Contracts and compatibility

- A material repository-content change that reaches local development
  completion triggers exactly one bounded post-development cycle. A push with
  no new content and an unchanged waiting tree do not trigger another scan.
- Scan scope includes correctness and bugs, refactor and duplication
  opportunities, review quality, tests, documentation, governance,
  consistency, architecture, security, operations, and repository hygiene as
  applicable under Section 5.
- Every observation uses the existing disposition taxonomy. The successful
  local stop condition is zero unresolved `Blocking`, not zero observations.
- Queue readiness is dependency-first. Priority, severity, impact rank, and
  stable ID order rank only findings whose dependencies are satisfied. Every
  finding records dependency IDs or explicit `None`, `p0` through `p3`
  priority, and the protocol's five-level severity and impact ranks.
- One finding is the default correction unit. The smallest recorded
  dependency-coherent group may be atomic when isolation would be unsafe or
  impossible.
- Every correction has focused evidence and fresh-diff self-review. A new
  `Blocking` observation caused or exposed by that correction is fixed in the
  same correction when coherent or added to the active queue before
  convergence.
- An initial scan with zero unresolved `Blocking` is sufficient convergence
  evidence. After remediation changes the tree, the one confirmation scan
  proves the queue stayed empty. Changed evidence or a new blocker may reopen
  work within the declared finite budget; unchanged scans are prohibited.
- The converged final push is an ordinary branch push. Hosted evidence can
  reopen the cycle and require a later corrected push. Tag and GitHub Release
  publication are independent version-distribution events.
- Consumers pinned before v0.9.0 remain governed by their immutable pin. A
  submodule consumer receives the mandate when its reviewed update changes the
  protocol gitlink; repository-reference consumers update their exact ref
  manually or through their provider-specific adapter. Consumer-owned files
  remain untouched by the generic updater.

## Risks

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0081` | Unbounded execution | A persistent mandate is read as a continuous autonomous loop or unchanged re-scan | Mitigated by DEC-0015 / protocol owner | Material-change trigger, waiting state, finite budget, and unchanged-scan prohibition; `TEST-0096`, `TEST-0099` |
| `RISK-0082` | Disposition drift | "No findings" is read literally and hides or endlessly retries accepted residual, legacy, external, or optional observations | Mitigated by DEC-0015 / review owner | Convergence means no unresolved `Blocking`; every observation keeps one Gate 5 disposition; `TEST-0096` |
| `RISK-0083` | Publication and reachability | A converged push is confused with a GitHub Release, or maintainers assume an old consumer pin changed | Mitigated by DEC-0015 / release and consumer owners | Separate push and protocol-version publication contracts plus prospective exact-pin adoption; `TEST-0099` |
| `RISK-0084` | Remediation atomicity | Strict one-row execution breaks an inseparable dependency change, or broad batching defeats focused review | Mitigated by DEC-0015 / implementation owner | One finding by default with only the smallest recorded dependency-coherent group exception; `TEST-0097`, `TEST-0098` |

## Active finding register

The fresh-diff review uses one current-scope queue. Shared confidence is high;
all seven findings are `Blocking` and owned by SUBF-0037. None requires a
separate issue because each is resolved inside issue #47.

| ID | Classification | Severity | Dependencies | Priority / impact rank | Evidence and required action | Disposition / status |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0133` | Lifecycle contradiction | High | None | P1 / High | The zero-blocker path required a second unchanged confirmation while the bounded contract prohibited it. Make the initial clean scan sufficient and require confirmation only after remediation changes the tree. | `Blocking` / Resolved with `TEST-0096` red/green evidence and fresh-diff review |
| `FIND-0134` | State-transition ambiguity | Medium | None | P1 / Medium | Failed evidence was both a re-entry trigger and an unconditional blocked outcome. Distinguish correctable failed evidence from evidence that cannot be corrected within authority or budget. | `Blocking` / Resolved with explicit re-entry/blocked transition and `TEST-0096` red/green evidence |
| `FIND-0135` | Finding-schema gap | High | None | P1 / High | The queue requires explicit dependency, priority, severity, and impact-rank ordering, but canonical finding records did not require enough structured inputs. Extend the schema and structural contract. | `Blocking` / Resolved with canonical schema, finding form, and `TEST-0097` red/green evidence |
| `FIND-0136` | Version-publication wording conflict | Medium | None | P1 / Medium | DEC-0015 said v0.9.0 distribution may use a GitHub Release even though Gate 7 requires one for v0.8.0+. Make the separate immutable release requirement explicit without changing the mandate's final-push meaning. | `Blocking` / Resolved with mandatory Gate 7 distribution wording and `TEST-0099` red/green evidence |
| `FIND-0137` | Structural evidence false positive | High | `FIND-0135` | P1 / High | TEST-0096 through TEST-0099 could satisfy related fragments outside the mandate section, combine independent consumer pin surfaces, or omit declared transition and ownership relationships. Bind assertions to the mandate section and independently prove each surface and relation. | `Blocking` / Resolved with section-bounded clauses, independent adapter pins, exact updater set, and structural evidence |
| `FIND-0138` | Change-caused documentation drift | Low | None | P2 / Low | The active-register introduction still said "all three findings" after review expanded the register to five rows. Record this change-caused observation and make the count match the six-row register including this correction. | `Blocking` / Resolved in the same documentation correction; confirmation scan required |
| `FIND-0139` | Push-evidence self-reference | High | None | P1 / High | FEAT-0015 required its own final push while claiming pre-push completion, so the repository record could not carry exact proof without predicting its containing commit. Separate local push eligibility from externally written exact push evidence. | `Blocking` / Resolved with external issue/PR evidence boundary and `TEST-0099` red/green evidence |

## Readiness evidence

| Field | Declaration |
| --- | --- |
| Baseline commit | Immutable v0.8.6 commit `a3d58a9cee00b9914c40adcd8e93dff53bed235a` |
| Baseline suite | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` passed in 561.6 seconds for the v0.8.6 review tree; immutable publication was verified separately on 2026-07-16 |
| Scan and validation budget | One test-first contract pass, one implementation pass, one fresh-diff self-review, the existing initial full-project scan, one correction queue if needed, and one confirmation scan; repeat only for changed evidence or a new `Blocking` finding |
| Stop condition | Declared tests and acceptance criteria pass, no unresolved `Blocking` remains, and the review tree is locally eligible for the converged final push; exact push evidence is written externally after it exists |
| Compatibility | Prospective minor-version control; earlier exact pins remain valid and consumer-owned files are not rewritten |

## Decomposition and gate ledger

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0037` | Normative mandate, consumer reachability, evidence templates, and structural contract | [Issue #47](https://github.com/hasanmanzak/meAndAI/issues/47) | `TEST-0096` through `TEST-0099`; structure and complete suite passed | Fresh-diff review complete; `FIND-0133` through `FIND-0139` resolved | Complete and confirmed locally |

## Acceptance criteria

1. The common protocol defines a material-development-triggered cycle covering
   bug, refactor, review, test, documentation, governance, and consistency
   concerns and enters `Waiting` after a zero-`Blocking` convergence result.
2. The remediation queue is dependency-first and deterministically prioritizes
   only ready findings from recorded dependency, priority, severity, impact
   rank, and stable-ID fields; dependency cycles or missing authority stop as
   `Blocked`.
3. Each `Blocking` finding or smallest inseparable dependency group receives a
   solution, focused evidence, and fresh-diff self-review before the next
   independent item; change-caused or exposed blockers cannot leave the cycle.
4. An initial zero-`Blocking` scan converges without an unchanged repeat. A
   cycle that remediates findings runs the existing bounded confirmation scan
   and re-enters after material development or correctable new failed evidence;
   uncorrectable evidence stops `Blocked` only at the authority/budget boundary.
5. A locally converged review tree becomes eligible for a converged final Git
   push. The mandate does not create a tag or GitHub Release; exact push evidence
   is recorded externally after it exists, and hosted findings reopen the cycle
   and require a later converged corrective push.
6. The protocol repository inherits the mandate recursively, and consumer
   instructions continue to resolve the immutable common protocol without
   transferring ownership of consumer `AGENTS.md`, memory, records, or tests.
7. Active pins, changelog, adoption guidance, feature/decision graph, scenario
   ownership, version, and project memory describe v0.9.0 consistently.

## Definition of Ready

- [x] Stable ID, linked issue, problem, outcome, scope, and non-goals recorded.
- [x] Trigger, queue, disposition, correction, review, confirmation, push,
      waiting, re-entry, blocked, and consumer-ownership contracts defined.
- [x] DEC-0015 accepted and related bounded-convergence decisions linked.
- [x] `RISK-0081` through `RISK-0084` assigned owners and responses.
- [x] One coherent review slice and `TEST-0096` through `TEST-0099` defined.
- [x] Baseline, test-first approach, finite validation budget, compatibility,
      repeat rule, and stop condition recorded.
- [x] Test code is planned and absent; the structural suite will capture the
      intended red state before normative implementation.

## Self-review and mandate evidence

The initial 2026-07-16 scan covered all 119 tracked baseline files plus the new
FEAT-0015 decision, feature, test, and memory records. It reviewed protocol and
template semantics, PowerShell and workflow boundaries, test ownership,
consumer pins and managed paths, documentation links, versions, identifiers,
memory, and Git hygiene. `.git` internals, disposable test directories, and
post-publication GitHub evidence that does not yet exist were excluded. The
declared budget is this initial pass and one confirmation pass after
remediation.

The initial queue was resolved as `FIND-0133`, `FIND-0135`, `FIND-0137`,
`FIND-0134`, then `FIND-0136`: dependencies first, then P1 severity/impact rank
and stable ID. `FIND-0138` was caused by the growing review register, entered
the active queue immediately after the complete suite, and was resolved in the
same documentation correction. `FIND-0139` then separated local convergence
eligibility from the exact external push fact before publication. Each
correction received a focused structural check and fresh-diff review.

The checks rejected the zero-blocker confirmation contradiction, missing
finding schema, ambiguous failed-evidence transition, and optional-release
wording before their fixes. The test-quality correction bound assertions to
the mandate section, independently checked both consumer adapters, and proved
the exact updater managed set. No correction introduced a new `Blocking`
finding. `FIND-0120` remains the pre-existing `ExternalOrLegacyFollowUp` in
issue #44 and is not part of this queue.

Focused evidence: all PowerShell files parse, `git diff --check` passes, the
quick-adoption suite passed in 372.3 seconds, the structural suite passed, and
the complete suite passed in 560.1 seconds with exact observed results for
TEST-0096 through TEST-0099. The bounded confirmation covered structure, links,
IDs, PowerShell parsing, active pins, finding-register state, and Git hygiene;
it found no repository blocker. Two diagnostic matches were narrowed after they
correctly proved to be historical v0.8.6 and FIND-0138 evidence rather than
active drift. The final evidence-only structural verification passed in 3.7
seconds.

## Converged final push evidence

The repository record proves local eligibility. Exact commit and ref facts are
written to the external authority only after the push exists, so this file does
not predict the commit that contains itself.

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #47](https://github.com/hasanmanzak/meAndAI/issues/47), its [push-evidence comment](https://github.com/hasanmanzak/meAndAI/issues/47#issuecomment-4993144105), and [pull request #48](https://github.com/hasanmanzak/meAndAI/pull/48) |
| Local convergence eligibility | Passed on 2026-07-16: complete suite, bounded confirmation, and final relevant structural verification are clean |
| Intended review branch | `agent/stability-consistency-mandate` |
| Exact pushed commit and ref | Maintained in the external evidence authority after each converged push; not mirrored into its own containing commit |

## Definition of Done

- [x] Acceptance criteria met and structural scenarios pass.
- [x] Mandatory test code and scenario ownership are complete.
- [x] Focused and complete verification results are recorded.
- [x] SUBF-0037 and the complete diff received fresh-diff self-review.
- [x] The bounded full-project scan and confirmation have no unresolved
      `Blocking` finding; other dispositions retain their required evidence.
- [x] Documentation, links, version, changelog, and project memory are current
      for local convergence.
- [x] Issue, pull request, decision, and feature records are cross-linked.
- [ ] Applicable hosted CI and review gates pass before merge.

## Post-merge protocol-version publication evidence

This separate gate distributes v0.9.0 to exact-pin consumers. It is not the
mandate's converged final push and remains outside pre-merge Definition of Done.

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #47](https://github.com/hasanmanzak/meAndAI/issues/47) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
