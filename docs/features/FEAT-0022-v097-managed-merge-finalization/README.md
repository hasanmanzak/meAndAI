# FEAT-0022 - v0.9.7 Managed Merge Finalization

| Field | Value |
| --- | --- |
| Classification | Feature correction / [BUG-0010](https://github.com/hasanmanzak/meAndAI/issues/61) |
| Status | Complete |
| Target version | 0.9.7 |
| Issue | [#61](https://github.com/hasanmanzak/meAndAI/issues/61) |
| Pull request | [#62](https://github.com/hasanmanzak/meAndAI/pull/62) |
| Decision | [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

A managed adoption or protocol-update pull request can merge while its tracking
issue retains a review status and its automation branch remains. Initial
adoption has no merge listener or machine-readable tracking reference. A merged update
branch is no longer owned by an open proposal, so the next updater run treats
the remaining reserved ref as ambiguous and blocks future update discovery.

## Outcome

The consumer-owned lifecycle finalizes an exact managed merge without expanding
merge authority. It records durable merge evidence, removes transient issue
status labels, closes the one owned or tracking-linked issue, and deletes only
the unchanged pull-request head through an expected-head Git lease. A bounded
manual dispatch reconciles an exact missed event idempotently.

## Scope

- Route merged `pull_request.closed` events to post-merge finalization while
  preserving scheduled and ordinary manual update discovery.
- Recognize canonical completed adoption and protocol-update ownership markers.
- Add the exact adoption issue as a tracking reference before the launcher marks
  the pull request ready.
- Require one same-repository tracking issue for a managed update proposal.
- Revalidate repository, default base and current merge containment,
  same-repository head, branch reuse, marker, pull-request head, changed paths,
  issue identity, and live ref before mutation.
- Delete a present branch only with its exact expected-head lease and verify
  remote absence afterward.
- Record one idempotency marker in the tracking issue, remove transient workflow
  labels, and close the issue as completed.
- Preserve existing replacement-first supersession and credentials.

## Non-goals

- Approving or merging any pull request.
- Enabling GitHub's repository-wide automatic branch deletion setting.
- Retrospectively cleaning any existing consumer.
- Deleting human-owned branches, closing unrelated issues, or guessing ownership.
- Adding a service, scheduler, bootstrapper, or generalized validator framework.

## Readiness evidence

- Domain and contracts: a managed merge is the qualified tuple of consumer
  repository, default base, merged pull request, canonical marker, target tag,
  protocol commit, exact head SHA, deterministic branch, changed-path class,
  and one tracking issue. Adoption issues are selected by their canonical first
  line; update issues use one exact same-repository
  `Tracking issue: [#N](https://github.com/<owner>/<repository>/issues/N)` line.
- Lifecycle and errors: ordinary pull requests are no-ops. A managed-looking
  but unmerged, cross-repository, wrong-base, malformed, duplicate, moved,
  unexpected-path, or ambiguously linked state fails before destructive
  mutation. Branch deletion precedes issue closure so a destructive failure
  cannot falsely close the work item.
- Consumers and compatibility: consumers adopting or upgrading to `v0.9.7`
  receive the event route and finalizer through the existing managed workflow
  and adapter paths. Earlier pins remain unchanged and past merge events are not
  replayed automatically.
- Credential boundary: proposal creation and self-update retain
  `MEANDAI_UPDATER_TOKEN`. The post-merge job uses a job-scoped consumer
  `GITHUB_TOKEN` only for same-repository contents, pull-request reads, and issue
  finalization.
- Verification approach: focused mocked GitHub/Git scenarios, workflow and
  PowerShell structural validation, the complete repository suite, and hosted
  Ubuntu/Windows checks.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0098` | Data loss / identity | A foreign, reused, or moved branch is deleted as managed work | Mitigating / consumer workflow | Exact first-line marker, repository/base/head/path checks, current merge containment, open-PR reuse rejection, live-ref equality, expected-head lease, and [TEST-0110](test-cases.md) |
| `RISK-0099` | Consistency | Branch deletion and issue closure cannot be atomic | Mitigating / consumer workflow | Validate all state first, delete and verify the branch before issue mutation, then use an idempotent evidence marker and recovery dispatch |
| `RISK-0100` | Availability | A missed event or restricted job token leaves cleanup incomplete | Mitigating / consumer maintainer | Explicit pull-request recovery input, idempotent absent-branch handling, and actionable failure evidence |
| `RISK-0101` | Traceability | An update merge has no authoritative issue to close | Mitigating / consumer maintainer | Exactly one same-repository tracking issue is a pre-merge requirement for managed updates; native closing keywords are forbidden so finalization ordering stays deterministic |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0108](test-cases.md), [TEST-0109](test-cases.md), and [TEST-0110](test-cases.md) |
| Test code | Implemented | The focused fixture failed first on the absent adapter/workflow route, then passed after production implementation |
| Baseline run | Green | `v0.9.6` complete local suite and hosted Ubuntu/Windows validation recorded in [issue #59](https://github.com/hasanmanzak/meAndAI/issues/59) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0038` | Event-routed, issue-aware, lease-safe managed merge finalization | [Issue #61](https://github.com/hasanmanzak/meAndAI/issues/61) | [TEST-0108](test-cases.md), [TEST-0109](test-cases.md), and [TEST-0110](test-cases.md); focused pass | `FIND-0153` through `FIND-0155` resolved; bounded confirmation clean | Complete |

## Decisions and relationships

- Decision: [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md)
- Update supersession: [FEAT-0002](../FEAT-0002-semi-automatic-consumer-updates/README.md) / [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Adoption lifecycle: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md) / [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Local completion boundary: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Qualified evidence and recovery: [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md) and [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md)
- Tracking: [issue #61](https://github.com/hasanmanzak/meAndAI/issues/61)
- Delivery: [pull request #62](https://github.com/hasanmanzak/meAndAI/pull/62)

## Definition of Ready

- [x] Stable `FEAT-0022`, [BUG-0010](https://github.com/hasanmanzak/meAndAI/issues/61), and linked [issue #61](https://github.com/hasanmanzak/meAndAI/issues/61).
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable.
- [x] Event, repository, marker, head, branch, path, issue, credential, error,
      recovery, and compatibility contracts are identified.
- [x] `RISK-0098` through `RISK-0101` and [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) are recorded.
- [x] The bounded correction is one independently reviewable slice.
- [x] [TEST-0108](test-cases.md), [TEST-0109](test-cases.md), and [TEST-0110](test-cases.md) and the verification approach are defined.
- [x] Test-code and baseline states are recorded.

## Acceptance criteria

1. An exact completed adoption merge closes its canonical adoption issue,
   removes transient status labels, records exact merge/branch evidence, and
   lease-deletes its unchanged deterministic branch.
2. An exact protocol-update merge performs the same finalization for exactly
   one same-repository tracking issue and unchanged reserved branch.
3. Normal pull requests are no-ops; every managed identity, issue, path, and
   branch ambiguity fails before destructive mutation.
4. A repeated merge event or explicit recovery dispatch is idempotent when the
   exact branch is absent and the issue is already closed.
5. Scheduled/manual update discovery, replacement-first supersession,
   credentials, and maintainer-owned review and merge remain unchanged.
6. Focused scenarios, structural checks, and the complete protocol suite pass
   with documentation, links, version, changelog, and memory aligned.

## Self-review

The fresh diff and complete call flow were reviewed for event separation,
credential scope, marker/issue identity, default-branch containment, changed
paths, branch reuse, lease ordering, idempotent recovery, interrupted mutation,
launcher readiness, update compatibility, duplication, and documentation and
version consistency. The change extends the existing consumer workflow,
launcher, and mutation adapter; it adds no service, scheduler, bootstrapper, or
generalized validator.

### Bounded project scan

- Scope: all 148 tracked or intended repository files, PowerShell entry points,
  workflow and consumer templates, scenario ownership, version pins,
  documentation, memory links, credential boundaries, and working-tree hygiene.
- Exclusions: `.git` internals and external hosted-CI, merge, tag, immutable
  release, and later empty-consumer adoption facts that do not yet exist.
- Budget: one initial scan and one confirmation after the listed remediations;
  no recursive hardening or additional feature scope.

| ID | Classification / disposition | Priority / impact | Evidence and action | Status |
| --- | --- | --- | --- | --- |
| `FIND-0153` | Lifecycle defect / `Blocking` | `p1` / issue could close before destructive convergence | Independent design review showed that native `Closes #N` semantics contradict branch-first finalization. Replaced them with one exact non-closing `Tracking issue: #N` line and reject every native closing keyword before readiness/finalization. | Resolved |
| `FIND-0154` | Identity and consistency gap / `Blocking` | `p1` / stale or reused branch could be finalized | Added fresh default-head containment, same-repository API head, open-PR branch-reuse, repeated live-state, exact-ref, and expected-head lease checks before issue mutation. | Resolved |
| `FIND-0155` | Regression-evidence defect / `Blocking` | `p1` / release-boundary tests entered an unrelated API failure | Three escaped `v0\.9\.6` fixture matchers survived the ordinary version search, repeating the class recorded by historical [FIND-0152](../FEAT-0021-v096-github-cli-prerequisite/README.md). Updated the fixtures and added a version-derived structural scan over escaped release references so the class now fails at the root protocol gate. | Resolved |

The bounded confirmation parsed every changed PowerShell file, found one exact
scenario owner for [TEST-0108](test-cases.md), [TEST-0109](test-cases.md), and [TEST-0110](test-cases.md), passed `git diff --check`,
found no stale ordinary or escaped active release pin, and completed the full
repository suite in 543.1 seconds with all discovered scenario evidence. No
unresolved `Blocking` finding remains.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding; every other disposition has its
      required evidence.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue, decision, tests, and related work cross-linked; the pull-request
      link is added when publication creates it.
- [x] Applicable local pre-merge gates passed; hosted PR validation remains in
      its explicit external gate below.

## Post-merge release evidence

[Issue #61](https://github.com/hasanmanzak/meAndAI/issues/61) is the external
authority for the exact merged commit, immutable `v0.9.7` release, launcher
asset digest, hosted checks, and owned branch cleanup after publication.
