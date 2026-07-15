# FEAT-0010 - Protocol Stability Invariants

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.0 |
| Issue | [#34](https://github.com/hasanmanzak/meAndAI/issues/34) |
| Pull request | [#35](https://github.com/hasanmanzak/meAndAI/pull/35) |
| Decision | [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The bounded v0.7.3 project scan found related defects in proposal-state
transitions, protected-path validation, executable release trust, concurrent
workflow discovery, supersession continuity, credential-history claims, and
repository evidence maintenance. Treating them as isolated patches would keep
the same missing invariants available under different symptoms.

## Outcome

meAndAI automation uses a small shared invariant model: executable source is
accepted only from a published immutable release, persisted proposal state is
validated against live GitHub and Git evidence before and after mutation, path
policy accounts for complete rename provenance, and repository validation is
derived from canonical indexes and current release facts. Equivalent defects
fail the same regression boundary instead of reappearing in later scans.

## Scope

- Resolve `FIND-0076` through `FIND-0092` in dependency order.
- Add an explicit completion transition for launcher-owned adoption proposals.
- Validate protected paths from source and destination rename records.
- Identify exactly one workflow run created by the current dispatch.
- Require exact draft, marker, manifest, and tree evidence for pending adoption.
- Make published immutable GitHub Releases the executable-source authority.
- Revalidate replacement continuity around compensated supersession cleanup.
- Align credential-history claims with locally observable Git history.
- Derive repository-document validation from canonical indexes and exclude
  nested worktrees from the root project scan.
- Reconcile release evidence, routing, timeout, template, and finding records.
- Keep exact-state validation cohesive, derive active version pins from the
  canonical release, and keep post-publication commit evidence external.

## Non-goals

- A hosted control plane, GitHub App, universal bootstrapper, validator chain,
  or semantic AI-memory engine.
- Automatic approval, merge, or destructive repair of ambiguous consumer work.
- Retrofitting behavior into consumers that remain pinned before `v0.8.0`.
- Claiming atomicity across Git refs and GitHub pull-request state.

## Readiness evidence

- Domain and contracts: immutable release, tag, proposal marker, proposal
  state, branch head, draft state, manifest, tree contract, workflow dispatch,
  workflow run, rename source/destination, replacement continuity, observable
  Git history, canonical index, validation responsibility seam, and external
  release evidence are separate concepts.
- Consumers and dependencies: the source-only launcher, seed workflow,
  bootstrap adapter, consumer updater, GitHub Releases/API, project validator,
  templates, and portable memory are affected. Existing pins remain valid.
- Compatibility: the `0.x` consumer contract changes prospectively at `0.8.0`.
  Manual workflow-only adoption remains available, but source execution blocks
  until the requested tag has a published immutable release.
- Verification: focused PowerShell fixtures per slice, real-Git rename and
  history fixtures, structural release checks, one complete repository suite,
  and the bounded convergence budget in DEC-0004.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0054` | State integrity | A persisted marker describes an earlier branch head after launcher publication | Mitigating; launcher owner | Explicit proposed/completed marker transition, live re-fetch, and rerun fixture |
| `RISK-0055` | Path integrity | Rename or case provenance removes a protected consumer control | Mitigating; launcher owner | Ordinal source-and-destination name-status validation |
| `RISK-0056` | Supply chain | A moved tag changes executable bootstrap code | Mitigating; release owner | Immutable-release prerequisite before source retrieval or execution |
| `RISK-0057` | Concurrency | Another run or proposal mutation is mistaken for launcher-owned progress | Mitigating; automation owners | Pre-dispatch inventory and exact unseen-run/live-proposal validation |
| `RISK-0058` | Cleanup continuity | A replacement changes during old-proposal cleanup | Mitigating; updater owner | Revalidation around cleanup plus best-effort PR compensation |
| `RISK-0059` | Security assurance | Local Git evidence is described as complete remote history | Mitigating; launcher owner | Capability-accurate wording and shallow/unobservable-history handling |
| `RISK-0060` | Governance drift | Duplicated inventories and pre-release prose outlive canonical state | Mitigating; maintainers | Index-derived checks, release-evidence schema, and current-state assertions |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0052 through TEST-0059](test-cases.md) |
| Test code | Green locally and hosted | `TEST-0052` through `TEST-0059` passed; hosted Ubuntu, Windows, and GitGuardian checks passed on PR #35 |
| Baseline run | Passed | `v0.7.3` passed `TEST-0001` through `TEST-0051` on Windows, Ubuntu, and GitGuardian before this work |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0021` | Launcher proposal, path, run, and history invariants | [Issue #34](https://github.com/hasanmanzak/meAndAI/issues/34) | `TEST-0052` through `TEST-0056`; local and hosted pass, 2026-07-15 | `FIND-0076`, `FIND-0077`, `FIND-0080`, `FIND-0082`, `FIND-0092`; resolved | Complete |
| `SUBF-0022` | Immutable release, bootstrap, and supersession invariants | [Issue #34](https://github.com/hasanmanzak/meAndAI/issues/34) | `TEST-0056` through `TEST-0058`; local and hosted pass | `FIND-0078`, `FIND-0079`, `FIND-0081`; resolved | Complete |
| `SUBF-0023` | Durable validation and release evidence | [Issue #34](https://github.com/hasanmanzak/meAndAI/issues/34) | `TEST-0059`; local and hosted pass | `FIND-0083` through `FIND-0091`; resolved | Complete |

## Decisions and relationships

- Decision: [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md)
- Bounded convergence: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Consumer supersession: [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Seed lifecycle: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Local completion: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Predecessor hardening: [FEAT-0009](../FEAT-0009-adoption-integrity/README.md)
- Tracking: [issue #34](https://github.com/hasanmanzak/meAndAI/issues/34)

## Definition of Ready

- [x] Stable feature ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] State, path, release, concurrency, history, and evidence contracts.
- [x] Numbered risks and DEC-0010.
- [x] Three bounded, independently reviewable slices.
- [x] Numbered test scenarios and verification approach.
- [x] Focused test code and expected red evidence recorded.

## Acceptance criteria

1. A successful local adoption completion persists a canonical completed
   proposal marker bound to the published head; exact reruns reconcile state
   without rerunning Codex or failing ownership checks.
2. PR base, actor, repository, body, draft state, and branch head are
   revalidated immediately before and after launcher publication.
3. Protected workflow and credential paths cannot be removed, renamed, copied
   through case drift, or hidden in rename provenance.
4. The launcher accepts exactly one workflow run created after its dispatch;
   multiple unseen matches block without selecting the newest.
5. Existing pending adoption is accepted only when one exact draft, marker,
   live head, manifest, and state-appropriate tree contract agree.
6. Bootstrap source and update targets are used only when the tag has a
   published immutable GitHub Release; a tag alone is not release authority.
7. Supersession revalidates replacement continuity around old cleanup and
   restores the old PR when the continuity check or paired deletion fails.
8. Credential-history checks and documentation distinguish reachable local
   history, reflog evidence, shallow state, and unavailable remote history.
9. Canonical indexes drive required-document coverage; active version pins,
   bounded validator seams, external release evidence, routing, CI bounds, and
   finding records agree without rewriting historical evidence.
10. Focused tests, the complete cross-platform suite, self-review, and one
    bounded post-change convergence scan pass without an unresolved actionable
    in-scope finding.

## Findings register

| ID | Classification / severity / confidence | Required resolution | Status |
| --- | --- | --- | --- |
| `FIND-0076` | State integrity / High / High | Persisted schema-3 completion marker plus exact pre/post PR revalidation and idempotent rerun | Resolved |
| `FIND-0077` | Path integrity / High / High | Direct ordinal index checks protect both rename sides; `.gitmodules` path matching is case-sensitive | Resolved |
| `FIND-0078` | Supply chain / High / High | Launcher, seed workflow, download guide, and updater require exact immutable-release evidence | Resolved |
| `FIND-0079` | Bootstrap ownership / Medium / High | One exact validator covers draft identity, marker, ancestry, manifest, paths, blobs, and post-create continuity | Resolved |
| `FIND-0080` | Workflow concurrency / Medium / High | Dispatch inventories prior run IDs and binds exactly one unseen run ID | Resolved |
| `FIND-0081` | Supersession continuity / Medium / High | Replacement and old proposal are revalidated around close/delete with verified compensation | Resolved |
| `FIND-0082` | Security assurance / Medium / High | Local ref/reflog checks reject shallow history and documentation states the unavailable-remote limit | Resolved |
| `FIND-0083` | Release traceability / Medium / High | BUG-0003 now records PR #33, exact commit, tag object, and historical authority boundary | Resolved |
| `FIND-0084` | Test reliability / Low / High | Record/test coverage derives from canonical indexes and root Git inventory excludes nested repositories | Resolved |
| `FIND-0085` | Bounded execution / Low / High | Repository CI has an explicit 20-minute job timeout | Resolved |
| `FIND-0086` | Documentation routing / Low / High | Documentation router links adoption, quick adoption, records, memory, overview, protocol, and changelog | Resolved |
| `FIND-0087` | Release evidence / Low / High | Feature template defines one post-merge evidence schema and legacy tags no longer overclaim immutability | Resolved |
| `FIND-0088` | Finding traceability / Low / High | FIND-0048 is recorded in FEAT-0001 with its bounded fix evidence | Resolved |
| `FIND-0089` | Validator cohesion / Medium / High | Split the oversized exact-adoption validator into cohesive evidence helpers and guard the production seam structurally | Resolved |
| `FIND-0090` | Active-version drift / Medium / High | Derive project-template version coverage dynamically and assert the behavior-bearing test fixture uses the current adoption branch | Resolved |
| `FIND-0091` | Release evidence / Medium / High | Store exact target evidence externally after publication instead of requiring a repository commit to identify itself | Resolved |
| `FIND-0092` | Test portability / Medium / High | Build local-clone file URIs through one `UriBuilder` boundary instead of platform-dependent path casting | Resolved |

## Self-review

The implementation uses four reusable boundaries rather than thirteen
independent patches: release authority, exact proposal state, complete path and
history provenance, and canonical repository evidence. The launcher suite
passed `TEST-0033` through `TEST-0056` on Windows PowerShell in 115 seconds.
Bootstrap and updater adapter suites passed `TEST-0057` and `TEST-0058`; the
repository structure-only gate passed `TEST-0059`. The immutable-release
repository setting was enabled and re-read as `enabled: true` through GitHub's
2026-03-10 API. The bounded fresh-diff scan found three derivative risks: a
monolithic bootstrap validator, active `v0.7.3` pins, and a self-referential
release-evidence field. They were resolved through one responsibility-seam
gate, canonical active-pin coverage, and external post-publication evidence.

The complete parent command then passed every lifecycle, updater, and launcher
child suite and exposed one structural blocker: the new active-pin check treated
absent versions and an action dependency release comment as protocol pins. The
same check also found the hidden bootstrap adapter's genuinely stale default.
The default and predicate were corrected; the final structure-only confirmation
passed `TEST-0059`.
The first hosted run then passed Windows but exposed a Linux-only empty file URI
in the shallow-history fixture. One cross-platform URI helper replaced the
platform-dependent cast; no production behavior changed. The corrected hosted
run passed Ubuntu, Windows, and GitGuardian on PR #35.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded convergence scan complete.
- [x] No unresolved blocking finding; residual limitations are explicit.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [x] Applicable CI and review gates pass.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| Release authority | Published immutable GitHub Release |
| Release identifier | [`v0.8.0`](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.0) |
| Target commit | [`a6a25b4e2a4dad5b0d09c0dddaf777f730c6a821`](https://github.com/hasanmanzak/meAndAI/commit/a6a25b4e2a4dad5b0d09c0dddaf777f730c6a821) |
| Verification evidence | Release and locked tag target verified after PR #35 merged on 2026-07-15 |
