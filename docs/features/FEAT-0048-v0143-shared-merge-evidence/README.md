# FEAT-0048 - Shared API-2026 Merge Evidence

| Field | Value |
| --- | --- |
| Classification | Backward-compatible propagation correction / [BUG-0031](https://github.com/hasanmanzak/meAndAI/issues/117) |
| Status | Complete; publication evidence reopened |
| Target version | 0.14.3 |
| Issue | [#117](https://github.com/hasanmanzak/meAndAI/issues/117) |
| Pull request | [#118](https://github.com/hasanmanzak/meAndAI/pull/118) |
| Decisions | Reuses [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md); revises the release-declared capacity evidence in [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) without adding a new architecture |
| Tests | [TEST-0179](test-cases.md#test-0179) and [TEST-0180](test-cases.md#test-0180) |

## Problem and outcome

[FEAT-0038](../FEAT-0038-v0127-api-safe-merge-finalization/README.md)
replaced the removed API `2026-03-10` pull-request `merge_commit_sha` field with
one canonical merged issue-event `commit_id`, but the same contract did not
propagate to the post-publication verifier. The immutable `v0.14.2` identities
are correct while its dedicated publication gate fails deterministically in
[run 30104971376](https://github.com/hasanmanzak/meAndAI/actions/runs/30104971376).

The outcome is one pure merge-event resolver owned by the existing managed
updater module. The consumer updater and publication verifier retain their own
transport, pagination, containment, and mutation boundaries while sharing the
exact event-selection rule.

## Prior-art and current-main classification

- Classification: `PropagationGap`, not a new algorithm or design.
- Canonical prior work: [FEAT-0038](../FEAT-0038-v0127-api-safe-merge-finalization/README.md),
  [TEST-0155](../FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md#test-0155),
  and [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96).
- Current API-2026 updater: paginates pull-request issue events and validates
  one canonical `merged.commit_id`.
- Current API-2026 publication verifier: still reads the removed PR field.
- API-2022 capability-review and hosted-routing callers remain compatible and
  are explicitly outside this correction.

## Scope

- Move the pure exact merged-event selection rule into the existing
  protocol-managed resolver module.
- Keep a thin updater transport adapter and make the publication verifier use
  its existing paged transport before calling the same resolver.
- Add pure positive/negative resolver tests, paginated publication regression,
  and a version-qualified API-2026 call-site guard.
- Run the current workflow verifier authority against a detached clean worktree
  of the requested immutable release commit, so historical evidence never
  reloads the defect it is meant to recheck.
- Raise the bounded release-declared graph edge ceiling from 2,048 to 4,096
  after exact self-consumer evidence proves legitimate 2,061-edge growth.
- Publish immutable `v0.14.3`, then rerun the failed `v0.14.2` publication gate
  with the corrected verifier before closing [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114).

## Non-goals

- No consumer-repository mutation or named-consumer fixture.
- No API-version migration for API-2022 callers.
- No change to merge authorization, containment, pagination, release identity,
  or mutation ordering.
- No broad test-harness refactor in this revision correction.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0219` <a name="risk-0219"></a> | Another API-2026 caller reintroduces the removed field | Protocol maintainers / inventory every API-2026 production script, module, verifier, and managed workflow reader and enforce a version-qualified structural guard in [TEST-0180](test-cases.md#test-0180) |
| `RISK-0220` <a name="risk-0220"></a> | Sharing the rule weakens caller-specific pagination, containment, or failure behavior | Protocol maintainers / keep transport and containment in each caller and prove pure plus integration negatives in [TEST-0179](test-cases.md#test-0179) and [TEST-0180](test-cases.md#test-0180) |
| `RISK-0221` <a name="risk-0221"></a> | The correction accidentally rejects unaffected API-2022 response contracts | Protocol maintainers / scope the guard to code paths that explicitly request API `2026-03-10` and retain existing API-2022 tests |
| `RISK-0222` <a name="risk-0222"></a> | A historical rerun reloads the immutable target's obsolete verifier instead of the current correction | Protocol maintainers / checkout exact current workflow authority, execute it from a detached exact target worktree, and clean that worktree in `finally` under [TEST-0180](test-cases.md#test-0180) |
| `RISK-0223` <a name="risk-0223"></a> | Required traceability exhausts a nearly full graph ceiling and tempts maintainers to delete valid links | Protocol maintainers / record exact 2,039-to-2,061 self-consumer growth, raise only the edge ceiling to 4,096, and preserve exact N/N+1 evidence |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0092` <a name="subf-0092"></a> | Single-owner merged-event resolver and propagation to both API-2026 callers | [Issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) | [TEST-0179](test-cases.md#test-0179), [TEST-0180](test-cases.md#test-0180), and existing [TEST-0155](../FEAT-0038-v0127-api-safe-merge-finalization/test-cases.md#test-0155) | Pure contract, both adapters, API-version inventory, and publication evidence agree without duplication | Complete |

## Definition of Ready

- [x] Stable IDs, [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117),
      problem, outcome, scope, and non-goals are defined.
- [x] Prior art and the current-main call-site inventory classify this as a
      propagation gap owned upstream.
- [x] The pure input is an event collection; the output is one lowercase
      40-character merge commit SHA; zero, duplicate, malformed, or wrong-case
      evidence throws before caller mutation.
- [x] Caller ownership is explicit: transports paginate; the resolver selects;
      callers compare containment or exact release identity.
- [x] Risks, compatibility boundaries, one reviewable slice, numbered tests,
      baseline failure, and verification commands are recorded.
- [x] No new architectural decision is required because the correction applies
      the already accepted [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md)
      evidence contract through the [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md)
      upstream boundary.

## Acceptance criteria

1. One pure resolver accepts exactly one exact `merged` issue event whose
   `commit_id` is a lowercase 40-character SHA and rejects every ambiguous or
   malformed collection.
2. Both API-2026 callers use that resolver after complete pagination and contain
   no direct dependency on the removed PR response field.
3. Publication evidence resolves a merge event beyond the first page and
   compares the result with the exact released commit while current verifier
   code runs from a clean detached worktree of that immutable target.
4. A version-qualified guard inventories every API-2026 production reader
   without rejecting unaffected API-2022 contracts.
5. Existing managed-finalization, publication, structure, and hosted gates pass.
6. Immutable `v0.14.3`, corrected `v0.14.2` publication verification, issue
   closure, and exact owned-branch cleanup complete.

## Hosted findings

| ID | Finding | Resolution |
| --- | --- | --- |
| `FIND-0240` <a name="find-0240"></a> | [PR run 30111807614](https://github.com/hasanmanzak/meAndAI/actions/runs/30111807614) proved that the correct traceability graph grew from 2,039 to 2,061 edges and exceeded the published 2,048 ceiling on both hosted runtimes | Revise [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md), the release contract, and exact boundary test to 4,096; do not remove valid links |
| `FIND-0241` <a name="find-0241"></a> | The post-publication workflow checked verifier code out at `expected_commit`, so a historical `v0.14.2` rerun would execute the same obsolete field reader | Separate exact current verifier authority from the detached immutable evidence worktree and enforce the lifecycle in [TEST-0180](test-cases.md#test-0180) |
| `FIND-0242` <a name="find-0242"></a> | Dedicated [v0.14.3 post-publication run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612) proved that real `Invoke-RestMethod` top-level JSON arrays arrive as one unenumerated `System.Object[]`, while the verifier pagination helper and its mock assumed enumerated page items | Reopen publication closure and correct the distinct runtime-shape gap under [FEAT-0049](../FEAT-0049-v0144-paged-array-response-normalization/README.md) / [BUG-0032](https://github.com/hasanmanzak/meAndAI/issues/119) without mutating immutable `v0.14.3` |

## Self-review

The bounded implementation review found no unresolved blocking item:

- the pure resolver has one owner and contains no transport or mutation logic;
- both API-2026 callers fully paginate before delegating to that resolver;
- the updater retains containment and mutation ordering, while the publication
  verifier retains exact released-commit comparison;
- the structural guard is API-version-qualified and covers production scripts,
  modules, the verifier, and managed workflow YAML, so pinned API-2022
  contracts are not accidentally changed;
- focused resolver, updater, managed-finalization, and publication regressions
  pass on the supported PowerShell runtimes;
- the independent fresh-diff review found one omitted managed-workflow YAML
  inventory boundary; [TEST-0180](test-cases.md#test-0180) now covers it and
  the focused publication suite passes after the correction;
- the first hosted aggregate exposed [FIND-0240](#find-0240) and bounded review
  exposed [FIND-0241](#find-0241); both root contracts are corrected without
  pruning traceability or mutating a historical release;
- the final independent blocker-fix review found no unresolved action across
  edge-limit propagation, immutable-release compatibility, detached-worktree
  cleanup, PowerShell compatibility, or hosted-runner topology;
- no consumer file, named-consumer fixture, new workflow, or new release asset
  was introduced.

## Definition of Done

- [x] Implementation acceptance criteria and declared focused tests pass.
- [x] Fresh-diff self-review has no unresolved `Blocking` finding.
- [x] One post-development convergence scan and its independent review finding
      are resolved without opening a new hardening loop.
- [x] Documentation, version, changelog, project memory, and delivery issue are
      current and cross-linked before publication.
- [x] The change is bounded to the common owner and adds no consumer mutation,
      workflow job, release asset, or parallel hosted load.

## Post-merge publication closure

- Run the dedicated publication verifier for immutable `v0.14.3` after its
  release and record the external evidence under
  [issue #117](https://github.com/hasanmanzak/meAndAI/issues/117).
- Rerun the failed immutable `v0.14.2` publication gate with the corrected
  verifier, then close [issue #114](https://github.com/hasanmanzak/meAndAI/issues/114)
  only if it passes.
- Delete only the exact owned delivery branch after merge and verification.

## Post-merge release evidence

Immutable [v0.14.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.3)
targets exact merged [PR #118](https://github.com/hasanmanzak/meAndAI/pull/118)
commit [`2d6cfc27418209c26cf9c27225c37938bac14dd9`](https://github.com/hasanmanzak/meAndAI/commit/2d6cfc27418209c26cf9c27225c37938bac14dd9),
and its exact owned branch is absent. Dedicated
[run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612)
then exposed [FIND-0242](#find-0242), so
[issue #117](https://github.com/hasanmanzak/meAndAI/issues/117) is reopened
until [FEAT-0049](../FEAT-0049-v0144-paged-array-response-normalization/README.md)
publishes and the same immutable release passes current verifier authority.
