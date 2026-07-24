# FEAT-0042 - Historical Capability-Review Recovery Across Compatible Protocol Updates

| Field | Value |
| --- | --- |
| Classification | Backward-compatible capability-lifecycle correction / [BUG-0024](https://github.com/hasanmanzak/meAndAI/issues/104) |
| Status | Complete |
| Target version | 0.13.3 |
| Issue | [#104](https://github.com/hasanmanzak/meAndAI/issues/104) |
| Pull request | [#105](https://github.com/hasanmanzak/meAndAI/pull/105) |
| Decision | [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) |
| Tests | [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166) |

## Problem

A capability-review issue can remain open after its exact proposal has merged
and before its branch-first/issue-last finalizer completes. If a later
compatible protocol update appends capabilities, the current catalog marker no
longer equals that retained issue's historical marker. Treating every such
record as active ambiguity prevents the updater from proving and retiring work
that was already merged, so current-catalog discovery cannot continue.

## Outcome

Recover one provably merged historical capability review without treating
catalog mismatch alone as corruption. The finalizer resolves the protocol
gitlink from the historical pull request's immutable base head, proves that
release and its catalog are the strict append-only predecessor of the current
catalog, applies current exact-head review authority, preserves all later
ledger entries, and performs exact leased branch-first/issue-last cleanup.
Active, unmerged, ambiguous, incompatible, or unverifiable records remain
fail-closed.

## Scope

- Resolve `.ai/protocol` from the historical pull request's captured base-head
  Git tree rather than from the current consumer worktree.
- Require that gitlink to identify an exact immutable, tagged meAndAI release
  and load its catalog and definition blobs from canonical Git objects.
- Accept only a strict predecessor catalog: every historical entry is
  byte-identical and in the same order at the beginning of the current catalog,
  and the current catalog contains at least one later entry.
- Bind exactly one trusted issue, pull request, branch, historical catalog
  marker, reviewed head, base head, and merged result before any mutation.
- Re-evaluate the historical pull request's exact head using the current
  independent-review or exact personal-owner-attestation authority contract.
- Require the merged historical ledger to be exact for that catalog and the
  current default-branch ledger to retain it as an exact prefix while
  preserving any valid later entries.
- Delete the exact branch with a true expected-OID force-with-lease operation,
  record one canonical closure marker, and close the issue last.
- Perform at most one historical cleanup and then one fresh current-catalog
  inventory per invocation.

## Non-goals

- Cleaning active, open, closed-unmerged, superseded, duplicate, or ambiguous
  capability work.
- Accepting an equal, reordered, rewritten, removed, untagged, moving, or
  unrelated catalog as historical compatibility.
- Reconstructing history from issue prose, the current worktree, cached API
  state, or consumer-specific names and layouts.
- Editing a consumer ledger, truncating later ledger entries, changing semantic
  assessments, or bypassing current review authority.
- Adding a polling loop, recurring job, hosted-runner fan-out, broad migration
  framework, or project-specific fixture.

## Readiness evidence

- Domain and contracts: [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md)
  defines historical identity, strict-predecessor compatibility, review
  authority, ledger preservation, mutation order, and invocation bounds.
- Consumers and dependencies: the existing source-only capability-review
  runner, canonical Git object reads, bounded GitHub issue/pull-request/review/
  comment/ref APIs, and the installed consumer workflow; no new credential or
  hosted-job requirement.
- Compatibility: the current fail-closed path remains authoritative unless one
  complete merged-history proof succeeds; normal same-catalog discovery and
  finalization are unchanged.
- Risks: `RISK-0197` through `RISK-0200` below.
- Verification: focused capability-review tests first, structural and release-
  pin checks, one bounded fresh-diff review, and the protocol's bounded final
  scan.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166) |
| Test code | Automated | [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166) run under the existing capability-adoption owner with a project-neutral historical-release fixture |
| Baseline run | Expected red recorded | The unchanged v0.13.2 runner rejected the trusted merged predecessor as a stale catalog before production correction |

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0197` <a name="risk-0197"></a> | Historical provenance | A stale marker or consumer-controlled tree redirects recovery to an unrelated or mutable protocol snapshot | Capability-review maintainer / resolve the base-head gitlink from canonical Git objects and require one exact immutable tagged release whose catalog digest and definition blobs match the retained marker |
| `RISK-0198` <a name="risk-0198"></a> | Work preservation and authority | Automation retires active or unauthorized semantic work because a PR or issue merely resembles a historical record | Consumer lifecycle maintainer / require a unique trusted issue/PR/branch binding, merged state, exact reviewed head, current review or owner-attestation authority, and fail closed for every active, unmerged, duplicate, or ambiguous state |
| `RISK-0199` <a name="risk-0199"></a> | Ledger integrity | Historical cleanup rewrites or truncates valid assessments added after the merged review | Capability catalog maintainer / require the historical merged ledger to be exact and the current ledger to preserve it as an exact prefix; cleanup is metadata-only and [TEST-0165](test-cases.md#test-0165) proves later entries remain byte-identical |
| `RISK-0200` <a name="risk-0200"></a> | Race and runner cost | Branch movement between proof and deletion destroys new work, or repeated reconciliation consumes unbounded runner minutes | Workflow maintainer / use true expected-OID force-with-lease deletion, revalidate mutable state before mutation, close the issue last, and permit one cleanup plus one fresh inventory per invocation |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0081` <a name="subf-0081"></a> | Strict-predecessor historical proof, exact leased cleanup, and bounded current rediscovery | [Issue #104](https://github.com/hasanmanzak/meAndAI/issues/104) | [TEST-0165](test-cases.md#test-0165), [TEST-0166](test-cases.md#test-0166); expected red and corrected focused green | `FIND-0208` and `FIND-0209` resolved; no Blocking finding remains | Complete |

## Decisions and relationships

- Governing decision: [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md)
- Semantic capability lifecycle: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Current exact-head authority: [FEAT-0041](../FEAT-0041-v0132-exact-head-owner-attestation/README.md) / [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md)
- Managed cleanup and reconciliation: [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) and [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)

## Definition of Ready

- [x] Stable IDs and linked [issue #104](https://github.com/hasanmanzak/meAndAI/issues/104) exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria and historical identity/error contracts are defined.
- [x] Consumers, dependencies, compatibility, and token boundaries are known.
- [x] `RISK-0197` through `RISK-0200` and [DEC-0026](../../decisions/DEC-0026-historical-capability-review-recovery.md) are recorded.
- [x] One independently reviewable slice has a gate ledger.
- [x] [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166) and the bounded verification approach are defined.
- [x] Test-code and current-baseline states are recorded before implementation.

## Acceptance criteria

1. A uniquely bound merged historical review is eligible only when its
   base-head `.ai/protocol` gitlink resolves to an exact immutable tagged
   release whose catalog is a strict byte-identical ordered predecessor of the
   current catalog.
2. Historical issue, marker, pull request, base, reviewed head, merge result,
   branch, release, catalog, definition blobs, and ledger evidence are complete
   and consistent before any mutation.
3. The historical exact reviewed head has either a current trusted independent
   approval or the exact bounded personal-owner attestation permitted by
   [DEC-0025](../../decisions/DEC-0025-exact-head-personal-owner-attestation.md); merge, Ready state, or historical cached authority is insufficient.
4. The current default-branch ledger preserves the exact historical merged
   ledger prefix and every valid later entry; recovery performs no consumer
   content edit.
5. Successful cleanup uses an expected-OID force-with-lease branch deletion,
   records one canonical closure marker, closes the issue last, and is an exact
   no-op after completion.
6. Active, unmerged, closed-unmerged, equal-catalog, incompatible, untagged,
   moved, duplicated, drifted, or ambiguous records fail before mutation.
7. One invocation cleans at most one historical record, then acquires exactly
   one fresh current inventory so normal current-catalog discovery can continue
   without a loop or hosted-job expansion.

## Verification approach

Register [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166) in the existing capability-adoption owner and first run
them against the unchanged v0.13.2 runner to capture the intended stale-catalog
failure. Implement the smallest historical proof and cleanup boundary, rerun
the focused owner, then run structural and release-pin checks. Perform one
bounded fresh-diff review and one final relevant protocol validation command;
only a proven `Blocking` finding reopens SUBF-0081.

## Self-review

The single bounded fresh-diff review found one Blocking request-routing defect:
the global explicit pull-request number was evaluated inside every catalog
inventory, so an exact historical request failed against the current catalog
and could be evaluated again after cleanup. `FIND-0208` moved that validation to
the selected current or historical candidate exactly once. A bounded test-
evidence audit then found that the first fixture shared historical and current
ledger bytes and asserted only a lower bound on fresh inventory calls.
`FIND-0209` separated the byte streams, proved preservation of the appended
entry and no consumer write, required exactly one fresh inventory, checked all
GitHub mutation verbs, and added duplicate-PR and partial-finalization paths.
The corrected focused owner passes all six mapped capability-review scenarios;
no unresolved Blocking finding remains.

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0208` <a name="find-0208"></a> | Blocking / explicit recovery routing | `FinalizePullRequestNumber` was applied to the current inventory before historical resolution and again after cleanup. | Resolved: validate the requested number once against the selected current or historical PR; fresh inventory does not reuse it. [TEST-0165](test-cases.md#test-0165) covers explicit historical finalization. |
| `FIND-0209` <a name="find-0209"></a> | High / test-evidence completeness | The initial fixture did not distinguish the historical merged ledger from the current ledger with later entries and allowed more than one fresh inventory. | Resolved: distinct exact byte streams, appended-entry preservation, no-write and mutation assertions, exact inventory count, duplicate-PR rejection, and branch-already-absent issue-last recovery are automated in [TEST-0165](test-cases.md#test-0165) and [TEST-0166](test-cases.md#test-0166). |

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful focused results recorded.
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current for
      the pre-publication tree.
- [x] Issue, decision, tests, and related work cross-linked; the pull request
      and immutable release are recorded below when GitHub creates them.

Hosted gates, immutable publication, and consumer-side recovery are post-merge
evidence. They do not weaken or reopen this completed upstream implementation
gate and remain fail-closed until recorded below.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #104](https://github.com/hasanmanzak/meAndAI/issues/104) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
