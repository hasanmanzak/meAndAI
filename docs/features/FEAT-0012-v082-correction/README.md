# FEAT-0012 - Deliver the Bounded v0.8.2 Correctness Correction

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.3 |
| Issue | [#38](https://github.com/hasanmanzak/meAndAI/issues/38) |
| Pull requests | [#39](https://github.com/hasanmanzak/meAndAI/pull/39) and [#40](https://github.com/hasanmanzak/meAndAI/pull/40) |
| Decision | [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The read-only scan after v0.8.1 found ten blocking observations that the prior
green suite and self-review did not expose. Exact issue ownership, concurrent
secret preservation, completed-proposal retention, reserved-branch recovery,
credential-boundary assertions, scenario ownership, workflow validation, scan
records, publication timing, and the consumer feature template each had a
specific correctness or evidence gap.

Several gaps were discoverable in earlier scans, and some should have been
caught by the review of the work that introduced them. This correction records
that failure directly. It repairs the owning contracts and their focused
evidence instead of adding another scanner or extending validation indefinitely.

## Outcome

The existing automation and governance surfaces enforce exact ownership,
serialize create-if-absent secret reconciliation, retain valid completed
proposals, inventory the full reserved branch namespace, preserve credential
contracts in tests, bind each scenario to executable evidence, validate both
workflows with actionlint, and separate pre-merge delivery facts from external
post-publication facts.

## Scope

- Resolve only `FIND-0102` through `FIND-0111`.
- Add focused executable scenarios [TEST-0069](test-cases.md), [TEST-0070](test-cases.md), [TEST-0071](test-cases.md), [TEST-0072](test-cases.md), [TEST-0073](test-cases.md), [TEST-0074](test-cases.md), [TEST-0075](test-cases.md), and [TEST-0076](test-cases.md) in the
  existing suites and CI workflow.
- Correct the v0.8.1 audit ledger and historical publication-timing statement.
- Correct the common protocol, feature template, canonical indexes, changelog,
  version, and project memory needed by this delivery.
- Keep exact v0.8.2 release/tag/commit/check facts outside the pre-merge commit
  and write them to [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38)
  and the GitHub Release only after publication.

## Non-goals

- New product behavior, consumer migration, automatic merge, or changes outside
  the ten recorded findings.
- A hosted coordinator, GitHub App, universal validator, recursive bootstrapper,
  semantic AI reviewer, or another full-project scan.
- Repairing external consumer repositories during this delivery.
- Predicting the v0.8.2 merge commit, release tag state, or hosted check result.

## Readiness evidence

- Domain and contracts: canonical ownership marker, repository-scoped secret
  mutation, adoption proposal phase, reserved automation branch, credential
  authority, test scenario identity, workflow semantics, finding disposition,
  and release evidence are distinct concepts.
- Consumers and dependencies: the quick-adoption launcher, bootstrap and updater
  adapters, their fixtures, repository validator, CI workflow, protocol,
  templates, feature/decision graph, changelog, and project memory.
- Compatibility: a backward-compatible `M.m.rev` correction; consumers remain
  governed by their immutable pin until a maintainer merges a reviewed update.
- Verification: eight focused scenarios, the existing complete suite, one
  fresh-diff review, and the single budgeted confirmation scan.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0068` | External concurrency | Two local launchers can observe the same missing secret before either writes it | Mitigated; launcher owner | Repository-scoped serialization and passed [TEST-0070](test-cases.md) |
| `RISK-0069` | Ownership ambiguity | Marker-like prose or old reserved branches can be mistaken for automation ownership | Mitigated; automation owners | Exact marker parsing, full namespace inventory, passed [TEST-0069](test-cases.md) and [TEST-0072](test-cases.md) |
| `RISK-0070` | Evidence integrity | Green tests can omit the credential or scenario contract they claim | Mitigated; test/CI owners | Contract-bearing mocks, explicit scenario map, actionlint, passed [TEST-0073](test-cases.md), [TEST-0074](test-cases.md), and [TEST-0075](test-cases.md) |
| `RISK-0071` | Publication integrity | Repository documents can claim a release before an external release exists | Mitigated; protocol owner | Two-stage evidence model and passed local [TEST-0076](test-cases.md); exact publication facts remain external |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0069](test-cases.md), [TEST-0070](test-cases.md), [TEST-0071](test-cases.md), [TEST-0072](test-cases.md), [TEST-0073](test-cases.md), [TEST-0074](test-cases.md), [TEST-0075](test-cases.md), and [TEST-0076](test-cases.md) |
| Test code | Automated and green | Existing suites plus the focused external-evidence verifier implement [TEST-0069](test-cases.md), [TEST-0070](test-cases.md), [TEST-0071](test-cases.md), [TEST-0072](test-cases.md), [TEST-0073](test-cases.md), [TEST-0074](test-cases.md), [TEST-0075](test-cases.md), and [TEST-0076](test-cases.md) |
| Baseline run | Passed but insufficient | v0.8.1 full suite passed in 232.8 seconds during the initial scan while the ten findings remained reproducible or evidenced |

## Declared scan boundary and finite budget

| Field | Declaration |
| --- | --- |
| Initial scan | Completed read-only on 2026-07-15 against v0.8.1 commit `9b4060a98af65d2ff3102495b8b29719c831c7de` |
| Tracked scope | All 102 tracked files: repository inventory, PowerShell entry points/adapters/modules, both workflows, tests and fixtures, protocol/templates, feature/decision/memory graph, version/changelog, and GitHub release/issue/branch projections |
| Exclusions | External consumer repositories; no tracked generated or binary files existed. PSScriptAnalyzer was unavailable. Local `bash -n` was blocked by the Windows ACL environment; hosted Ubuntu evidence covered the shell path. |
| Initial evidence | Complete PowerShell suite passed in 232.8 seconds; all 13 tracked PowerShell files parsed; both workflows passed actionlint 1.7.12; worktree, credential-history, remote branch, issue, PR, and immutable v0.8.1 release projections were inspected |
| Budget | One completed initial scan plus one confirmation scan after remediation; no unchanged or third scan is authorized |
| Stop condition | All declared tests and relevant gates pass, the confirmation scan has no unresolved `Blocking` finding, and unreviewed scope is retained here |

## Decomposition and gate ledger

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0027` | Exact automation ownership, secret serialization, proposal retention, and orphan recovery | [Issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) | [TEST-0069](test-cases.md), [TEST-0070](test-cases.md), [TEST-0071](test-cases.md), and [TEST-0072](test-cases.md); pass | `FIND-0102`, `FIND-0103`, `FIND-0109`, `FIND-0110`; resolved | Complete |
| `SUBF-0028` | Contract-bearing test evidence and workflow validation | [Issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) | [TEST-0073](test-cases.md), [TEST-0074](test-cases.md), and [TEST-0075](test-cases.md); local pass, recurring hosted gate enforced before merge | `FIND-0104` through `FIND-0106`; resolved | Complete |
| `SUBF-0029` | Auditable scan records, release evidence, and consumer template | [Issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) | [TEST-0076](test-cases.md); local contract pass, external publication gate retained separately | `FIND-0107`, `FIND-0108`, `FIND-0111`; resolved | Complete |

## Decisions and relationships

- Decision: [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md)
- Predecessor: [FEAT-0011](../FEAT-0011-stability-closure/README.md)
- Evidence boundary: [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md)
- Stable automation invariants: [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md)
- Bounded convergence: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Tracking and publication authority: [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, frozen scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Ownership, concurrency, lifecycle, recovery, credential, evidence, scan,
      and publication contracts and consumers identified.
- [x] Numbered risks and [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md).
- [x] Three independently reviewable slices.
- [x] Numbered test scenarios and finite verification approach.
- [x] Baseline limitation and test-code state recorded.

## Acceptance criteria

1. Adoption-issue ownership accepts exactly one canonical parsed marker and
   rejects marker-like prose, duplicates, or ambiguity without mutating the
   wrong issue.
2. Concurrent launchers cannot overwrite a canonical repository secret that
   another launcher created after the first observation.
3. A verified `Completed` adoption proposal remains valid until maintainer
   disposition and does not make a later lifecycle run fail or create a
   duplicate proposal.
4. Recovery inventories every remote branch in the reserved meAndAI namespace
   and blocks before mutation when an older orphan is unowned or ambiguous.
5. Credential-boundary fixtures retain and assert exact authorization,
   API-version, repository identity, secret-name, token-authority, and standard
   input mapping.
6. Every active documented scenario has one canonical declaration, one owning
   suite/evidence kind, and a successful owner-suite result; focused fixtures
   cover declared variants, while superseded TEST IDs remain historical and are
   never reused for new behavior.
7. Recurring CI validates both workflow files with pinned, integrity-checked
   actionlint in addition to the PowerShell repository suite.
8. [FEAT-0011](../FEAT-0011-stability-closure/README.md) records its historical scan, in-slice blockers, findings, and
   publication-timing defect without rewriting the later valid v0.8.1 release.
9. The consumer feature template mandates the bounded post-development scan
   and preserves each disposition's distinct evidence requirement.
10. FEAT-0012 retains `Pending` publication fields before merge and designates
    [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) as the stable external authority for later exact evidence.
11. The external verifier calls the exact repository metadata resource without
    a trailing slash, and its focused mock rejects the invalid URL shape.

## Initial findings register

All findings below came from the declared initial scan, affected the authorized
correction, and remained `Blocking` until their focused implementation and
evidence passed. File links identify canonical local evidence;
[issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) owns the delivery
and later publication evidence.

| ID | Classification | Severity / confidence | Evidence | Affected scope | Impact | Required action | Disposition / status | Links |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FIND-0102` | Verified defect - ownership | High / High | The launcher selected an issue when its body merely contained the marker substring | Adoption issue reconciliation in [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) | An unrelated issue can be mutated and the canonical issue closed | Parse exactly one canonical marker and reject quoted, duplicate, or incidental text | `Resolved` / Complete | Passed [TEST-0069](test-cases.md), [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md) |
| `FIND-0103` | Verified defect - concurrency | High / High | Secret names were inventoried once and the stale snapshot was reused for later writes | Secret reconciliation in [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) | Concurrent launchers can overwrite a newly created secret | Serialize per repository and re-read the live name inventory inside the mutation boundary | `Resolved` / Complete | Passed [TEST-0070](test-cases.md), `RISK-0068` |
| `FIND-0104` | Verified evidence defect | High / High | The validator accepted a TEST ID when its raw text occurred anywhere; [TEST-0037](../FEAT-0006-quick-adoption-launcher/test-cases.md) had been reused for different behavior | [Repository validator](../../../tests/protocol.tests.ps1), feature scenarios, and test suites | Green structure checks can claim behavior that was not executed | Require one canonical declaration, owning suite/evidence kind, successful owner run, focused variant fixtures, and permanent supersession | `Resolved` / Complete | Passed [TEST-0074](test-cases.md), [FEAT-0006 scenarios](../FEAT-0006-quick-adoption-launcher/test-cases.md) |
| `FIND-0105` | Verified evidence defect - credential boundary | High / High | GitHub mocks discarded authorization/API-version headers and assertions did not prove exact token-to-secret stdin mapping | [Quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) | Regressed token authority or missing headers can remain green | Retain and assert the complete credential contract in focused fixtures | `Resolved` / Complete | Passed [TEST-0073](test-cases.md), [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md) |
| `FIND-0106` | Verified evidence defect - workflow semantics | High / High | CI used generic YAML parsing and one string rejection but no workflow-semantic linter | [Protocol CI](../../../.github/workflows/protocol-tests.yml) and consumer workflow | Unsupported Actions expressions can pass local validation and fail before jobs start | Run a pinned, integrity-checked actionlint against both workflows on every validation run | `Resolved` / Complete | Local actionlint pass and recurring [TEST-0075](test-cases.md) gate |
| `FIND-0107` | Verified governance defect | High / High | [FEAT-0011](../FEAT-0011-stability-closure/README.md) omitted declared scan boundaries and reduced findings and five in-slice blockers to unauditable summaries | [FEAT-0011](../FEAT-0011-stability-closure/README.md) | Completion evidence cannot be independently reconstructed | Restore scope, exclusions, budget, blocker ownership, and complete finding evidence | `Resolved` / Complete | Passed local [TEST-0076](test-cases.md), [protocol scan contract](../../../PROTOCOL.md#5-full-project-scans) |
| `FIND-0108` | Verified governance defect - publication timing | High / High | The v0.8.1 feature and memory claimed immutable publication in the pre-merge commit before the release existed | [FEAT-0011](../FEAT-0011-stability-closure/README.md), [project memory](../../../.ai/memory/project.md), [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36), and [release v0.8.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1) | Later valid evidence obscures that the original completion claim was premature | Record the historical defect and use a stable external authority with pending pre-merge fields for future releases | `Resolved` / Complete | Passed local [TEST-0076](test-cases.md); external post-publication gate remains separate |
| `FIND-0109` | Verified defect - lifecycle state | Medium / High | The launcher produced a ready `Completed` proposal that bootstrap retention accepted only as draft `Proposed` | [Launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) and [bootstrap adapter](../../../templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1) | A normal rerun can fail while a valid maintainer-review proposal is open | Recognize and retain the exact completed proposal without duplicate creation or mutation | `Resolved` / Complete | Passed [TEST-0071](test-cases.md) |
| `FIND-0110` | Verified recovery defect | Medium / High | Recovery checked only the current target branch rather than the complete reserved namespace | [Updater adapter](../../../templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1) | An older interrupted branch can coexist with a new proposal and hide ambiguous ownership | Inventory and validate every reserved remote branch before mutation | `Resolved` / Complete | Passed [TEST-0072](test-cases.md), [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md) |
| `FIND-0111` | Verified protocol/template drift | Medium / High | The feature template made the completion scan conditional and collapsed four evidence contracts into one statement | [Consumer feature template](../../../templates/feature/README.md) | Consumers can skip the required scan or close a disposition without its required evidence | Make the scan mandatory and state each disposition contract exactly | `Resolved` / Complete | Passed local [TEST-0076](test-cases.md), [protocol review gate](../../../PROTOCOL.md#gate-5---self-review) |

## BUG-0004 - Repository-root verifier URL correction

| Field | Evidence |
| --- | --- |
| Classification | Post-publication integration defect |
| Status | Resolved for v0.8.3; external verification pending publication |
| Owning finding | `FIND-0108` |
| Tracking | [Issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) |
| Failed evidence | [v0.8.2 post-publication run 29454981897](https://github.com/hasanmanzak/meAndAI/actions/runs/29454981897) |

The first real external run called the repository metadata endpoint with an
extra trailing slash. GitHub returned 404, while the focused mock had accepted
the same invalid URL and therefore produced a false green result. The v0.8.3
repair builds the empty-path request from the exact repository root and adds a
negative regression that rejects the trailing-slash form. No new verifier or
scan layer is introduced.

## Self-review

Each slice received one focused fresh-diff review against the fixed findings
register. The review caught the following derivative blockers before commit;
each remained owned by its root finding and was fixed in the same slice rather
than being deferred or turned into another scan cycle.

| Owning finding | Blocking observation caught by self-review | Resolution and evidence |
| --- | --- | --- |
| `FIND-0102` | First-line marker parsing alone could still accept a drifted owned record | Require the exact canonical title and body; [TEST-0069](test-cases.md) passes |
| `FIND-0103` | The initial lock implementation used an unavailable `gh label view` path and could not prove exact owner cleanup | Use the exact REST label resource, nonce revalidation, and owner-only delete; [TEST-0070](test-cases.md) passes |
| `FIND-0105` | Moving source verification before the lock initially bypassed a present read-only protocol token | Select the verified local read token before lock mutation and use authenticated `gh` only when the file is absent; focused quick-adoption and full suites pass |
| `FIND-0106` | The first actionlint package name did not match the official release asset | Pin the verified `linux_amd64` artifact and SHA-256; local actionlint reports zero errors |
| `FIND-0108` | The first post-publication verifier required permanent default-branch equality and mixed release evidence into the feature commit | Verify released-commit ancestry and keep exact publication facts in [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) and the GitHub Release; verifier fixtures pass |
| `FIND-0108` / `BUG-0004` | The real v0.8.2 external run exposed an invalid repository-root trailing slash that the mock also accepted | Remove the slash, make the focused mock reject it, retain the failed run, and publish the bounded v0.8.3 repair |
| `FIND-0108` / `BUG-0004` | The first v0.8.3 full run exposed two escaped legacy-version fixture matchers that a plain-version search had missed | Align the exact matchers, search both plain and escaped legacy pins, and rerun the complete suite successfully in 264.4 seconds |
| `FIND-0110` | A complete initial reserved-branch inventory could still change before the first mutation | Revalidate the exact namespace immediately before publication or cleanup; [TEST-0072](test-cases.md) passes |

The bounded confirmation reused the declared repository inventory, reviewed the
complete changed tree and surrounding ownership boundaries, parsed every
tracked PowerShell surface, validated both workflows with actionlint, and ran
the complete suite in 267.9 seconds. No unresolved `Blocking` observation
remained. The Windows sandbox-only Git signal-pipe denial was rerun once outside
the sandbox and did not reproduce there.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and explicit scenario mapping complete.
- [x] Focused and complete test commands and results recorded.
- [x] Three slice reviews complete.
- [x] One budgeted confirmation scan complete with no unresolved `Blocking`
      finding.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue and decision records cross-linked; pull-request, hosted-check, and
      release facts are delegated to external authority [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38).
- [x] Applicable local gates pass; hosted CI remains a required pre-merge gate
      and is recorded externally rather than predicted in this commit.

## Hosted publication authority

The delivery and verifier-repair pull requests are linked above. Exact release,
commit, and hosted-check facts are recorded in [issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) and the corresponding
GitHub Releases. The historical pre-publication fields below deliberately remain
`Pending`; copying mutable hosted state into this canonical commit is not their
authority and does not require another documentation-only pull request.

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #38](https://github.com/hasanmanzak/meAndAI/issues/38) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
