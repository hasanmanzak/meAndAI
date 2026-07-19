# FEAT-0034 - CI Evidence Hygiene and Exact-Tree Reuse

| Field | Value |
| --- | --- |
| Classification | Backward-compatible CI and test-isolation correction / `BUG-0015`, `BUG-0016` |
| Status | Complete |
| Target version | 0.12.2 |
| Issue | [#85](https://github.com/hasanmanzak/meAndAI/issues/85) |
| Pull request | Recorded in [issue #85](https://github.com/hasanmanzak/meAndAI/issues/85) after creation; no evidence-only candidate commit |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) |
| Tests | [TEST-0142 and TEST-0143](test-cases.md) |

## Problem

The managed-merge finalization fixture inherits `GITHUB_STEP_SUMMARY` from its
canonical child process. Successful synthetic scenarios therefore append
fixture values such as a repeated hexadecimal placeholder, pull request `#42`,
and issue `#9` to the real hosted job summary.

The delivery lifecycle also creates avoidable complete workflow runs. Live
facts that exist only after a candidate push, pull-request creation, hosted
validation, merge, or publication have been copied back into the candidate
branch. Each evidence-only commit retriggers the complete pull-request suite.
After merge, the unprotected `main` push then repeats both complete suites even
when the pushed merge tree is byte-for-byte identical to the exact tree that
already passed both stable jobs.

## Outcome

Every managed-merge scenario owns and verifies an isolated summary file while
leaving an inherited outer summary unchanged. Live delivery evidence is
recorded in the linked issue or pull request without a repository commit made
solely to copy those facts. A `main` push reuses prior validation only when
local Git and GitHub evidence prove the exact pushed tree already passed both
stable jobs; all missing, ambiguous, failed, or mismatched evidence runs the
complete fail-safe route.

## Scope

- Isolate finalization summary output per scenario and verify exact success,
  no-op, failure, cleanup, and inherited-sentinel behavior.
- Add one project-neutral, read-only main-push evidence resolver returning only
  `ReuseExactValidatedTree` or `Full`.
- Keep the `push: main` trigger and the two stable Linux/Windows job names.
- Run `StructureOnly` in those jobs only for exact validated-tree reuse; retain
  current full behavior for direct, squash, rebase, forced, mismatched, failed,
  canceled, duplicate, unavailable, or malformed evidence.
- Refine the common protocol and feature-link graph so post-push live facts use
  their stable external authority and never require an evidence-only commit.
- Publish the correction as immutable `v0.12.2` after merge.

## Non-goals

- Removing `main` push validation or treating an unprotected branch as safe.
- Trusting a commit message, author, broad merge shape, or partial check set.
- Reusing a prior result for a different commit or a non-identical tree.
- Adding a workflow matrix, fan-in job, cache, service, or self-hosted runner.
- Changing updater behavior, consumer repositories, or consumer pull requests.
- Creating a generalized CI framework beyond this exact evidence boundary.

## Readiness evidence

- Domain and contracts: `GITHUB_STEP_SUMMARY` is caller-owned environment
  state; each fixture invocation temporarily replaces and finally restores it.
  The resolver is read-only and emits one exact enum value. `Full` is the
  default and every exception or ambiguity fails closed to it.
- Exact-tree authority: reuse requires an exact successful merge-queue commit,
  or exactly one merged pull request whose merge commit equals the pushed SHA,
  first parent equals the push `before` SHA, second parent equals the exact PR
  head, merge tree equals PR-head tree, and that exact head has one successful
  current-workflow run containing both stable successful jobs.
- Consumers and dependencies: the affected surfaces are the canonical
  consumer-update finalization fixture, `protocol-tests.yml`, the new
  workflow-efficiency capability owner, common protocol evidence rules, and
  DEC-0019. GitHub REST evidence and local Git are read-only dependencies.
- Compatibility: pull-request, merge-queue, ordinary manual, direct-push, and
  post-publication routes retain their existing authority. The stable job names
  and PR-only cancellation contract remain unchanged.
- Verification approach: declare the two scenarios, record expected-red
  results, implement the two bounded slices, run their capability owners,
  structural discovery, one full local validation, one fresh-diff review, and
  one bounded post-development scan.

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0154` | Evidence isolation | Fixture identities leak into a caller-owned GitHub summary or cleanup loses the prior environment value | Test maintainer / per-invocation temp file, `finally` restoration, exact success/no-output assertions, and inherited sentinel in `TEST-0142` |
| `RISK-0155` | Validation integrity | A direct, synthetic, stale, wrong-head, or partially green push is incorrectly classified as reusable | Workflow maintainer / joint Git and paginated GitHub proof, exact tree and parent identity, exact stable jobs, and fail-closed negatives in `TEST-0143` |
| `RISK-0156` | Runner efficiency | Conservative routing or external-evidence commits continue to repeat complete suites | Workflow maintainer / exact-tree positive cases plus a protocol prohibition on commits made solely to copy live external facts, verified by `TEST-0143` |
| `RISK-0157` | Required-check continuity | Optimization removes a trigger/job identity or lets publication and cancellation routes interfere | Workflow maintainer / retain `push: main`, both stable jobs, PR-only cancellation, and isolated publication structure in `TEST-0143` and `TEST-0124` |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0142 and TEST-0143](test-cases.md) |
| Test code | Implemented and focused green | `TEST-0142` is owned by the consumer-update finalization suite; `TEST-0143` is owned by the recursively discovered workflow-efficiency capability suite |
| Baseline run | Green | Immutable `v0.12.1`; [main run 29688880377](https://github.com/hasanmanzak/meAndAI/actions/runs/29688880377) passed before this correction |

## Decomposition and review gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0062` | Managed-merge job-summary isolation | [Issue #85](https://github.com/hasanmanzak/meAndAI/issues/85) | `TEST-0142`; expected red then focused owner green | Exact output, no-output, restoration, and cleanup paths reviewed | Complete |
| `SUBF-0063` | Exact-tree main routing and external-evidence discipline | [Issue #85](https://github.com/hasanmanzak/meAndAI/issues/85) | `TEST-0143`, retained `TEST-0124`; expected red then focused owner green | Git/GitHub identity, pagination, failure, permissions, and workflow routes reviewed | Complete |

## Decisions and relationships

- Runner efficiency: [FEAT-0027](../FEAT-0027-v0104-runner-minute-efficiency/README.md) / [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md)
- Capability test architecture: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Unavailable private-main protection: [issue #44](https://github.com/hasanmanzak/meAndAI/issues/44)
- Tracking and post-publication authority: [issue #85](https://github.com/hasanmanzak/meAndAI/issues/85)

## Definition of Ready

- [x] Stable `FEAT-0034`, `BUG-0015`, `BUG-0016`, `TEST-0142`,
      `TEST-0143`, and linked issue #85 exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable.
- [x] Summary ownership, route enum, Git/GitHub identity, compatibility,
      lifecycle, and fail-closed error contracts are explicit.
- [x] Consumers, dependencies, and governing decisions are identified.
- [x] `RISK-0154` through `RISK-0157` have owners and required evidence.
- [x] Two independently testable slices and review gates are defined.
- [x] Numbered regression scenarios and verification approach are defined.
- [x] Test-code and baseline states are recorded before implementation.

## Acceptance criteria

1. Every finalization invocation captures its own summary output, restores the
   caller's exact environment value in `finally`, and cannot change an
   inherited outer summary on success, no-op, or error paths.
2. The workflow retains `pull_request`, `merge_group`, `push: main`, ordinary
   manual, and isolated post-publication routes plus the two stable validation
   job names and PR-only cancellation behavior.
3. An exact validated merge tree or exact successful merge-queue commit takes
   the short `StructureOnly` route in both stable jobs.
4. Direct, squash, rebase, forced, mismatched, duplicated, failed, canceled,
   missing, malformed, or unavailable evidence always selects `Full` without
   leaking credentials or mutable authority.
5. PR number, pushed SHA, hosted result, merge SHA, release, and cleanup facts
   are written to the linked issue or pull request and do not require a commit
   whose sole purpose is copying external evidence.
6. `TEST-0142`, `TEST-0143`, retained workflow contracts, full validation, and
   the bounded review/scan pass with no unresolved `Blocking` finding.

## Self-review

The review was bounded to the two declared slices, their workflow, test,
protocol, version, and memory call sites, one fresh diff, and one final scan.
It did not expand into consumer updater behavior or unrelated issue #44.

- `SUBF-0062`: every invocation replaces `GITHUB_STEP_SUMMARY` with a unique
  file, captures only that file, restores the exact prior environment value,
  and removes the temporary file from a nested `finally`. Success, no-op, and
  rejection paths leave the inherited sentinel unchanged.
- `SUBF-0063`: the route has only `Full` and
  `ReuseExactValidatedTree`; all exceptions and ambiguous evidence fail closed.
  Exact commit, graph, tree, repository, branch, workflow, run, and stable-job
  identities are checked. Provider lookups are paginated, permissions are
  read-only, stable job names and triggers remain intact, and the publication
  route remains isolated.
- Fresh-diff review found `FIND-0174` (`Blocking`): the initial default GitHub
  provider retained the outer array produced by `gh api --slurp`, so live
  paginated response properties were not reached and every eligible push fell
  back to `Full`. The provider now flattens exactly one page-envelope level;
  a multi-page fake-CLI regression and a read-only lookup against historical
  PR #84 both prove the exact-tree route. `FIND-0174` is resolved.
- The first hosted PR run found `FIND-0175` (`Blocking`): GitHub does not expose
  `event.before` for a `pull_request`, and PowerShell rejected the resulting
  empty string at parameter binding before the resolver could select `Full`.
  Externally supplied route strings now accept empty values and validate them
  inside the fail-closed boundary; `TEST-0143` reproduces the exact hosted
  empty-before call. `FIND-0175` is resolved.
- The post-development inventory covered architecture, correctness, negative
  paths, test discovery, documentation links, least-privilege permissions, and
  runner consumption. No unresolved `Blocking` finding remains.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded in [test-cases.md](test-cases.md).
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Delivery pull request is cross-linked through issue #85 without an
      evidence-only candidate commit.
- [x] Applicable hosted CI remains a mandatory pre-merge external gate whose
      exact result is recorded in issue #85 or its linked pull request.

## Post-merge release evidence

[Issue #85](https://github.com/hasanmanzak/meAndAI/issues/85) is the stable
external publication authority. Exact pull request, merge commit, immutable
release, branch cleanup, and post-publication verification remain `Pending`
until those facts exist and will be recorded there rather than copied into a
follow-up repository commit.
