# FEAT-0038 - API-Version-Safe Managed Merge Finalization

| Field | Value |
| --- | --- |
| Classification | Backward-compatible updater correctness correction / [BUG-0022](https://github.com/hasanmanzak/meAndAI/issues/96) |
| Status | Complete |
| Target version | 0.12.7 |
| Issue | [#96](https://github.com/hasanmanzak/meAndAI/issues/96) |
| Pull request | [#97](https://github.com/hasanmanzak/meAndAI/pull/97) |
| Decisions | [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md), [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md) |
| Tests | [TEST-0155](test-cases.md#test-0155) and [TEST-0156](test-cases.md#test-0156) |

## Problem and intended outcome

The consumer updater reads GitHub REST API version `2026-03-10`, which no
longer includes `merge_commit_sha` in pull-request response payloads. Both the
ordinary/schema-2 finalizer and the bounded legacy installing-update repair
still require that removed property. Strict mode therefore stops an otherwise
valid post-merge recovery before exact branch deletion and issue closure.

Resolve the merge commit from the exact pull request's complete issue-event
stream instead. One canonical `merged` event and its lowercase 40-character
`commit_id` become the containment input; every existing ownership, immutable
release, changed-path, schema-2, branch-head, and issue gate remains intact.

## Scope

- Add one shared updater helper that reads the exact pull request's paginated
  issue events and returns one canonical merged commit identity.
- Use that helper in ordinary/schema-2 managed finalization and legacy
  installing-update tracking repair.
- Reject absent, duplicate, malformed, or uncontained merge evidence before
  any branch, issue, comment, label, or pull-request mutation.
- Preserve idempotent recovery and the existing exact-head branch deletion and
  issue-last finalization order.
- Before target-bound current-update planning, let the exact requested updater
  recover any unambiguous retained merged branch that an older finalizer left
  behind; use only the authenticated local `gh` identity in the isolated clone.
- Publish immutable v0.12.7 and use its updater assets to recover the already-
  merged consumer finalization tracked by [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96).

## Non-goals

- Changing merge authorization, auto-merging consumer pull requests, or
  relaxing any existing finalization identity gate.
- Mutating consumer application content or introducing consumer-specific
  production paths, names, or fixtures.
- Migrating capability-review or hosted-CI routing paths pinned to API
  `2022-11-28`; that API version still exposes their current response contract.
- Adding a second finalizer, GraphQL dependency, workflow, runner, or retry
  loop.

## Contracts and affected boundaries

- The pull request must still be closed and merged into the current default
  branch from the exact same repository, marker-bound branch, and marker-bound
  head commit.
- The exact `repos/{repository}/issues/{number}/events` collection is read with
  pagination. Exactly one case-sensitive `merged` event must exist and its
  `commit_id` must be canonical lowercase SHA-1 text.
- The resolved event commit must be identical to or an ancestor of the current
  default head through the existing compare contract.
- Event lookup is read-only and uses the existing bounded GitHub-read retry
  policy. No mutation gains retry behavior.
- Ordinary unmanaged pull requests remain no-ops and do not incur the new
  event lookup.

## Risks

| ID | Classification | Risk | Owner / response and evidence |
| --- | --- | --- | --- |
| `RISK-0179` <a name="risk-0179"></a> | API compatibility | A removed pull-request field blocks every post-merge recovery | Updater maintainer / one event-based helper and a structural no-dependency assertion in [TEST-0155](test-cases.md#test-0155) |
| `RISK-0180` <a name="risk-0180"></a> | Evidence completeness | A first-page-only or ambiguous event read selects incomplete merge evidence | Updater maintainer / paginated project-neutral fixture plus zero, duplicate, and malformed event negatives in [TEST-0155](test-cases.md#test-0155) |
| `RISK-0181` <a name="risk-0181"></a> | Lifecycle safety | Replacing the merge source weakens containment or permits mutation on unrelated evidence | Updater maintainer / unchanged identity gates, compare containment, and no-mutation negatives in [TEST-0155](test-cases.md#test-0155) |
| `RISK-0182` <a name="risk-0182"></a> | Runner efficiency | The correction adds unbounded network calls or new hosted jobs | Updater maintainer / one event read is retained across the existing four-state pre/post-mutation checks, legacy repair keeps one mutation-bound read, unmanaged no-op proof, and no workflow fan-out |
| `RISK-0183` <a name="risk-0183"></a> | Recovery ordering | A retained merged branch blocks current-launcher namespace inventory before the corrected updater can be installed | Quick-adoption maintainer / the exact target adapter runs bounded merged-branch recovery before current planning in one isolated clone; [TEST-0156](test-cases.md#test-0156) proves ordering, GitHub host/token restoration, adapter/location failure cleanup, and maintainer-checkout identity/status preservation |

## Definition of Ready

- [x] Stable IDs and linked [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96) exist.
- [x] Problem, outcome, scope, non-goals, contracts, consumers, and risks are
      explicit.
- [x] Existing decisions remain applicable; no new architectural decision is
      required.
- [x] [TEST-0155](test-cases.md#test-0155) and [TEST-0156](test-cases.md#test-0156) define success, pagination,
      legacy recovery, local launcher ordering, idempotency,
      malformed/ambiguous evidence, containment, and no-mutation coverage.
- [x] Test-first expected-red evidence is recorded before production changes.

## Acceptance criteria

1. The API-2026 consumer updater contains no production dependency on the
   removed pull-request `merge_commit_sha` response field.
2. A valid managed merge with one exact `merged` issue event finalizes through
   the event `commit_id`, including schema-2 and legacy installing-update
   recovery paths.
3. The merged event may occur beyond the first 100 event records without being
   omitted.
4. Zero, multiple, noncanonical, or uncontained merged-event evidence fails
   before any finalization or legacy-tracking mutation.
5. An already-finalized rerun remains an exact no-op, while an ordinary pull
   request remains unmanaged and performs no event lookup.
6. A compatible current-launcher run recovers exact retained merged branches
   before update planning, restores every process token/environment binding,
   preserves the maintainer checkout, and rejects ambiguous recovery evidence.
7. Focused capability evidence, structure validation, diff checks, one bounded
   self-review, hosted gates, immutable release verification, exact owned-
   branch cleanup, and the consumer recovery all complete.

## Relationships

- Managed merge contract: [FEAT-0022](../FEAT-0022-v097-managed-merge-finalization/README.md)
- Idempotent lifecycle: [FEAT-0023](../FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md)
- Atomic legacy recovery: [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md)
- Target-bound launcher recovery: [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md)
- Capability test architecture: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md)
- External evidence: [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96)

## Definition of Done

- [x] Acceptance criteria pass with canonical [TEST-0155](test-cases.md#test-0155) and [TEST-0156](test-cases.md#test-0156)
      evidence.
- [x] Focused and structural validation pass on the exact candidate tree.
- [x] Bounded self-review and one convergence scan have no unresolved
      `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory are current.
- [ ] Hosted checks pass, the owned pull request is merged, immutable v0.12.7
      is verified, and the owned work branch is deleted.
- [ ] The consumer's exact historical finalization converges without weakening
      its existing repository-owned evidence.
