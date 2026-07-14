# FEAT-0002 - Semi-Automatic Consumer Protocol Updates

| Field | Value |
| --- | --- |
| Classification | Feature |
| Status | Complete |
| Target version | 0.2.0 |
| Issue | [#3](https://github.com/hasanmanzak/meAndAI/issues/3) |
| Pull request | [#4](https://github.com/hasanmanzak/meAndAI/pull/4) |
| Tests | [Scenarios and evidence](test-cases.md) |

## Problem

Pinned consumers are reproducible but do not learn about later protocol
releases. A moving `main` reference would detect changes by sacrificing review,
repeatability, and compatibility. A pending older update can also become stale
when a later compatible release appears.

## Outcome

Submodule consumers install a small, consumer-owned workflow during adoption.
It proposes the latest compatible release through a draft pull request, keeps
repeated runs idempotent, and uses replacement-first, compensated cleanup to
supersede an untouched older proposal. It never approves or merges the update.

## Scope

- Collision-safe workflow, resolver, and adapter installation during adoption.
- Canonical lowercase `vM.m.rev` discovery with no leading-zero aliases,
  numeric ordering, and same-major automation only.
- Paginated PR inventory and exactly one case-sensitive ownership marker.
- Binding to the consumer repository, default branch, draft state, actor,
  remote branch SHA, protocol commit, `160000` gitlink mode, and changed path.
- Targeted Git-tree traversal and `.gitmodules` protocol-origin validation.
- Replacement creation and full verification before old-proposal cleanup.
- Fresh validation of both proposals, expected-state Git leases, and PR reopen
  compensation when paired branch cleanup fails.
- State-aware cleanup comments that describe attempted mutation and the
  reopen/preserve compensation path without promising success.
- A shared pure candidate validator used by planning and live mutation gates.
- Private-repository credential and GitHub Actions permission guidance.
- A one-time manual migration for consumers pinned to immutable `v0.1.0`.
- Windows and Ubuntu `pwsh` repository CI.

## Non-goals

- Automatic merge, approval, or incompatible-major migration.
- A central scanner with access to every consumer repository.
- Generic mutation of opaque provider-specific repository references.
- Modification of consumer memory, domain records, or copied templates.
- A universal project bootstrapper or semantic AI-memory validator.

## Implementation map

- [Adoption and recovery guide](../../adoption.md)
- [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- [Consumer workflow](../../../templates/project/.github/workflows/meandai-protocol-update.yml)
- [Pure resolver and shared validator](../../../templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1)
- [Live GitHub adapter](../../../templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1)
- [Resolver and structural tests](../../../tests/protocol-update.tests.ps1)
- [Adapter race fixture](../../../tests/protocol-update-adapter.tests.ps1)
- [Repository validation workflow](../../../.github/workflows/protocol-tests.yml)

## Risks

| ID | Classification | Risk | Owner | Status | Evidence or response |
| --- | --- | --- | --- | --- | --- |
| `RISK-0004` | Concurrency | Overlapping runs create duplicate proposals | Maintainers | Mitigated | Workflow concurrency, deterministic branches, and `TEST-0011`/`TEST-0015` |
| `RISK-0005` | Data loss | Supersession deletes human work | Maintainers | Verified | Shared invariant gate, fresh revalidation, expected-head deletion lease, and [test evidence](test-cases.md#evidence) |
| `RISK-0006` | Availability | Cleanup removes the old proposal before a valid replacement exists | Maintainers | Mitigated | Replacement-first verification and reopen compensation |
| `RISK-0007` | Authentication | Consumer token cannot read private `meAndAI` | Consumer admin | Documented prerequisite | Separate read-only `MEANDAI_PROTOCOL_TOKEN`; consumer `GITHUB_TOKEN` performs local mutations |
| `RISK-0008` | Compatibility | Automation applies an incompatible major | Maintainers | Mitigated | Same-major resolver and `TEST-0016` |
| `RISK-0009` | Bootstrap | Immutable `v0.1.0` lacks the updater | Maintainers | Accepted transition | One-time reviewed `v0.2.0` migration in the [adoption guide](../../adoption.md) |
| `RISK-0010` | Portability | Repository-reference providers have no common writable contract | Maintainers | Accepted boundary | Provider decision or manual reviewed update |
| `RISK-0011` | Maintainability | Planning and live gates drift apart | Maintainers | Mitigated | One pure candidate validator shared by the resolver and adapter |
| `RISK-0012` | Identity | Another write workflow can act as `github-actions[bot]` | Consumer admin | Documented | Review all write workflows or use a dedicated GitHub App identity |
| `RISK-0013` | Interruption | Cancellation after branch push leaves an orphan reserved branch | Maintainers | Managed manually | Lease-safe inspection and recovery procedure in the [adoption guide](../../adoption.md#interrupted-run-recovery) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests and latest run | Self-review and findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0004` | Canonical version resolver and shared candidate validator | [Issue #3](https://github.com/hasanmanzak/meAndAI/issues/3) | `TEST-0009`, `TEST-0010`, `TEST-0013`, `TEST-0014`; passed 2026-07-14 | `FIND-0024`, `FIND-0025`, `FIND-0030`, `FIND-0036`, `FIND-0037`, `FIND-0039` resolved | Complete |
| `SUBF-0005` | Consumer adapter and compensated supersession | [Issue #3](https://github.com/hasanmanzak/meAndAI/issues/3) | `TEST-0011`, `TEST-0012`, `TEST-0015`, `TEST-0021`; adapter and real-Git lease fixtures passed 2026-07-14 | `FIND-0020` through `FIND-0029`, `FIND-0035`, `FIND-0038`, and `FIND-0049` resolved | Complete |
| `SUBF-0006` | Adoption, security boundary, and workflow templates | [Issue #3](https://github.com/hasanmanzak/meAndAI/issues/3) | `TEST-0016`, `TEST-0017`; local and PR CI passed 2026-07-14 | `FIND-0032` through `FIND-0034` and `FIND-0040` resolved | Complete |

## Definition of Ready

- [x] Stable feature ID and [linked issue](https://github.com/hasanmanzak/meAndAI/issues/3).
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Consumer, authentication, compatibility, and portability boundaries are identified.
- [x] Work is split into independently reviewable subfeatures.
- [x] Risks and [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md) are recorded.
- [x] Numbered [test scenarios](test-cases.md) preceded implementation.
- [x] The red baseline is recorded: the initial updater test exited `1` with `TEST-0009 missing pure update resolver module.`

## Acceptance criteria

1. Initial `v0.2.0+` submodule adoption installs the updater only when every
   consumer-owned target is absent; collisions require manual review.
2. Only canonical same-major stable tags are eligible, and the current gitlink
   must resolve to exactly one such tag from the configured protocol origin.
3. At most one valid draft proposal targets the latest compatible release.
4. A newer compatible release is created and fully revalidated before an
   untouched older proposal is closed and lease-deleted.
5. Failed creation, ambiguous ownership, case-only drift, missing refs, or human
   changes stop or compensate without deleting ambiguous work; pre-cleanup
   comments describe the attempted action and compensation without promising
   successful branch removal.
6. Automation never merges, applies a new major, or rewrites consumer memory,
   feature records, decisions, or copied templates.
7. Existing `v0.1.0` consumers have an explicit one-time reviewed migration.
8. The full repository suite passes locally and on Ubuntu and Windows PR CI.

## Self-review findings

| ID | Classification | Severity | Disposition | Evidence |
| --- | --- | --- | --- | --- |
| `FIND-0020` | Race safety | High | Resolved | Fresh live validation plus expected-head leases |
| `FIND-0021` | Ownership | High | Resolved | Expected-absent creation lease and ownership-safe rollback |
| `FIND-0022` | Recovery | High | Resolved | Immediate PR identity verification and reopen compensation |
| `FIND-0023` | Integrity | High | Resolved | Marker binds protocol SHA; API head, remote head, base, draft, tree mode, and path are verified |
| `FIND-0024` | Pagination | Medium | Resolved | All PR and file inventories use paged API reads |
| `FIND-0025` | Version ambiguity | High | Resolved | Exactly one canonical current tag is required |
| `FIND-0026` | Remote errors | Medium | Resolved | Only `ls-remote --exit-code` result `2` means absence; other errors stop |
| `FIND-0027` | Supply chain | High | Resolved | `.gitmodules` origin gate and invalid-origin fixture |
| `FIND-0028` | Supply chain | Medium | Resolved | `actions/checkout` is pinned to an immutable commit |
| `FIND-0029` | Test gap | High | Resolved | Adapter, rollback, pagination, identity, and race fixtures added |
| `FIND-0030` | Version policy | Medium | Resolved | Prospective mandatory controls may be minor; forced migration is major |
| `FIND-0031` | Evidence | Medium | Resolved | Red/green, AST, lease, and limitation evidence recorded |
| `FIND-0032` | Adoption | Medium | Resolved | Canonical-tag and origin prerequisites documented |
| `FIND-0033` | Traceability | Medium | Resolved | Risk owners, statuses, evidence, and link map added |
| `FIND-0034` | Decision semantics | Low | Resolved | Supersession wording distinguishes replacement from related context |
| `FIND-0035` | Test harness | High | Resolved | Repository CI path restored inside the required-files array |
| `FIND-0036` | Marker ambiguity | Medium | Resolved | Zero or multiple ownership markers block planning |
| `FIND-0037` | Exactness | Medium | Resolved | Canonical tag grammar and ref, marker, SHA, and path checks are case-sensitive |
| `FIND-0038` | False-green risk | Medium | Resolved | Mocks assert exact leases and hide later pages without `--paginate` |
| `FIND-0039` | Logic duplication | Medium | Resolved | Planning and live gates share one pure candidate validator |
| `FIND-0040` | Delivery evidence | High | Resolved | [PR #4](https://github.com/hasanmanzak/meAndAI/pull/4) passed Ubuntu and Windows CI |
| `FIND-0049` | Audit clarity | Low | Resolved | Conditional cleanup wording and `TEST-0021`; tracked by [issue #11](https://github.com/hasanmanzak/meAndAI/issues/11) |

## Scan limitations

- The local run used Windows PowerShell 5.1 and deterministic fake Git/GitHub
  adapters. Ubuntu and PowerShell 7 evidence is delegated to PR CI.
- The real-Git smoke test exercised creation and deletion leases against local
  temporary repositories; it did not mutate a live consumer repository.
- Repository settings, secret availability, and GitHub-hosted approval behavior
  remain consumer-administrator prerequisites and cannot be proven locally.

## Definition of Done

- [x] Acceptance criteria 1 through 7 are verified by local resolver, adapter, structural, and real-Git lease tests.
- [x] Mandatory test code passes with red/green evidence.
- [x] Every subfeature completed self-review.
- [x] Full repository scan findings and limitations are recorded.
- [x] Documentation, version metadata, links, and project memory are current.
- [x] [Pull request #4](https://github.com/hasanmanzak/meAndAI/pull/4) and issue #3 cross-link the canonical records.
- [x] Ubuntu and Windows GitHub CI checks pass on the published pull request.
- [x] Review gate is satisfied.

## Post-merge release gate

- [ ] The delivery PR is merged and `v0.2.0` is pushed and remotely verified.
