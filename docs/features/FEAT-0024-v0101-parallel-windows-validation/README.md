# FEAT-0024 - v0.10.1 Parallel Windows Validation and Immutable Test Fixtures

| Field | Value |
| --- | --- |
| Classification | Performance / test infrastructure feature |
| Status | Complete |
| Target version | 0.10.1 |
| Issue | [#65](https://github.com/hasanmanzak/meAndAI/issues/65) |
| Pull request | [#66](https://github.com/hasanmanzak/meAndAI/pull/66) |
| Related decisions | [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md), [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md) |
| Tests | [TEST-0115 and TEST-0116](test-cases.md) |

## Problem and intended outcome

The Windows PowerShell 5.1 validation job executes the large quick-adoption
integration suite serially and repeatedly rebuilds the same synthetic protocol
Git repository. Hosted evidence from run
[29568159757](https://github.com/hasanmanzak/meAndAI/actions/runs/29568159757)
recorded 558 seconds for the Windows test step versus 117 seconds on Linux.
The quick-adoption work accounted for most of that difference.

Retain the full Linux run as canonical executable scenario evidence while
running Windows compatibility coverage as one base job plus four parallel
quick-adoption shards. Within each quick-adoption process, build the protocol
repository and release archive once, reuse only that immutable fixture, and
reset all mutable scenario state independently.

## Scope

- Add four explicit Windows quick-adoption compatibility shards and one
  aggregate Windows result that preserves the existing check name.
- Add a constrained Windows base execution profile to the root suite; it may
  delegate only the canonical quick-adoption suite to the matrix jobs.
- Keep the default full suite and canonical scenario-result contract unchanged.
- Build, fingerprint, and reuse one protocol Git fixture and one release archive
  per quick-adoption process.
- Keep every consumer repository, remote, Codex home/log, issue, secret, and
  pull-request mock mutable and case-local.

## Non-goals

- Removing or narrowing Windows PowerShell 5.1 compatibility coverage.
- Splitting canonical `TEST-*` ownership across partial shards.
- Sharing mutable worktrees, Git refs, or caches between scenarios or runners.
- Adding a general test scheduler, persistent fixture service, or timing-based
  pass/fail threshold.
- Refactoring launcher production behavior.

## Contracts and risks

- `Shard=All` is the only quick-adoption mode allowed to emit
  `MEANDAI_SCENARIO_RESULTS`.
- A partial shard emits one compatibility-only result containing its exact
  validated shard name and no scenario identifiers.
- `ExecutionProfile=Full` retains current root-suite semantics.
  `ExecutionProfile=WindowsBase` delegates only
  `tests/quick-adoption.tests.ps1` and cannot be combined with structure-only
  validation.
- Fixture reuse is process-local. The fixture identity is its repository path,
  exact ref inventory, clean worktree state, and archive SHA-256 digest.
- Reset creates fresh mutable collections and temporary paths without changing
  the fixture identity.

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0106` | Evidence integrity | A partial shard falsely claims the full scenario set passed | Mitigating / test maintainer | Compatibility-only result schema, Linux full authority, workflow/runner assertions, `TEST-0115` |
| `RISK-0107` | Test isolation | Shared mutable Git or mock state makes cases order-dependent | Mitigating / test maintainer | Share only the fingerprinted protocol fixture and archive; create fresh mutable state; `TEST-0116` |
| `RISK-0108` | CI continuity | Renamed checks or incomplete aggregation weaken branch protection | Mitigating / repository maintainer | Preserve `Validate on windows-latest` as an aggregate that requires the base job and all four shards; `TEST-0115` |

## Definition of Ready

- [x] Stable feature/subfeature/test/risk identifiers and linked issue exist.
- [x] Problem, intended outcome, scope, and explicit non-goals are recorded.
- [x] Execution-profile, shard-result, fixture-identity, ownership, lifecycle,
      failure, and compatibility contracts are explicit.
- [x] Related launcher and stable-evidence decisions were reviewed.
- [x] Work is split into two independently reviewable slices.
- [x] Numbered success, failure, isolation, and boundary scenarios are defined.
- [x] Expected-red, focused-green, full-suite, hosted, review, and scan evidence
      are planned without a timing-sensitive gate.

## Acceptance criteria

1. Windows validation runs a base job plus exactly four parallel quick-adoption
   shards: `ContractsPreflight`, `AdoptionLifecycle`, `IntegrityFailures`, and
   `RepositoryRoutes`.
2. The aggregate `Validate on windows-latest` job fails unless the base job and
   all four matrix children succeed; Linux still runs the full suite.
3. Partial quick-adoption shards cannot emit canonical scenario evidence, while
   `Shard=All` and `ExecutionProfile=Full` retain current behavior.
4. Repeated reset calls reuse one protocol repository and release archive but
   receive fresh mutable collections and case-local temporary state.
5. Fixture refs, worktree state, and archive digest remain unchanged through a
   shard, and one archive output cannot mutate a later output.
6. Existing protocol scenarios remain green under PowerShell 7 and Windows
   PowerShell 5.1; hosted durations are recorded as observations only.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Self-review / findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0042` | Four-shard Windows compatibility orchestration with canonical evidence separation | [Issue #65](https://github.com/hasanmanzak/meAndAI/issues/65) | `TEST-0115`; expected-red then structure and four focused shard passes | Workflow routing, aggregate check identity, partial-result boundary, and PowerShell 5.1 syntax reviewed; no open finding | Complete |
| `SUBF-0043` | Process-local immutable protocol fixture and archive reuse | [Issue #65](https://github.com/hasanmanzak/meAndAI/issues/65) | `TEST-0116`; expected-red then focused integration pass | Immutable refs/archive fingerprint, fresh mutable state, and independent archive outputs reviewed; `FIND-0157` resolved | Complete |

## Verification approach

Add the two executable scenario contracts first and record their expected-red
failure. Implement each slice with focused parsing/structure or shard runs.
After both slice reviews, run one complete local Windows suite, inspect the
fresh diff, perform the protocol's single bounded completion scan, and use the
pull-request checks to verify Linux full evidence and Windows shard aggregation.
Compare hosted durations with run 29568159757 without making duration a gate.

## Relationships

- Launcher capability: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Single-file distribution: [FEAT-0017](../FEAT-0017-v092-single-file-quick-adoption/README.md)
- Tracking and post-publication authority: [issue #65](https://github.com/hasanmanzak/meAndAI/issues/65)
- Delivery: [pull request #66](https://github.com/hasanmanzak/meAndAI/pull/66)

## Self-review

The 2026-07-17 review was bounded to the changed workflow routing, canonical
evidence boundary, Windows PowerShell 5.1 syntax, fixture identity, mutable
scenario isolation, archive-copy behavior, active version pins, and closure
records. It did not introduce a general scheduler, cross-runner cache, or
production-launcher refactor.

| ID | Classification | Priority / impact | Finding | Disposition |
| --- | --- | --- | --- | --- |
| `FIND-0157` | Test-fixture scope defect / `Blocking` | `p1` / mocked release downloads could resolve the immutable archive variable in the launcher script scope and fail before exercising the requested shard | The first fixture-copy helper read script-local fixture state. The web-request mock executes from the launcher script scope, so the helper now copies from an explicit process-global immutable archive path rebound by every reset. | Resolved before completion; all four focused Windows PowerShell 5.1 shards passed and the bounded code review found no open blocker |

No unresolved in-scope `Blocking` finding remains. The documentation review
also confirmed that relative links and active version/memory projections are
consistent; planned statuses were reconciled to the completed focused
evidence before final validation.

## Definition of Done

- [x] Acceptance criteria and `TEST-0115` / `TEST-0116` pass.
- [x] Existing complete local suite passes.
- [x] Hosted Linux and Windows compatibility checks pass.
- [x] Both subfeature reviews and the bounded completion scan have no unresolved
      `Blocking` finding.
- [x] Documentation, links, changelog, version, and project memory agree.
- [x] Issue and pull request link the canonical records and evidence.

## Post-merge publication gate

Issue #65 is the external authority for the exact merged commit, immutable
`v0.10.1` release, launcher asset digest, hosted checks, observed Windows
critical path, branch deletion, and post-publication verification.
