# FEAT-0033 - Canonical Base-Blob Consumer Migration Planning

| Field | Value |
| --- | --- |
| Classification | Backward-compatible updater correctness correction / `BUG-0014` |
| Status | Complete |
| Target version | 0.12.1 |
| Issue | [#83](https://github.com/hasanmanzak/meAndAI/issues/83) |
| Pull request | [#84](https://github.com/hasanmanzak/meAndAI/pull/84) |
| Decisions | [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md) |
| Tests | [TEST-0141](test-cases.md) |

## Problem

The local/current-launcher updater captures one exact consumer base commit, but
its migration planner reads required inputs and the migration ledger from the
checked-out worktree. Git checkout filters can change those bytes without
changing the commit. On Windows, a clean clone with `core.autocrlf=true` can
therefore present CRLF worktree bytes for canonical LF blobs. The planner then
computes worktree-derived identities and incorrectly reports that a clean
consumer differs from its committed base.

This is a generic committed-state authority defect, not a consumer-specific or
source-version-specific migration problem.

## Outcome

Consumer migration planning reads binary-safe canonical bytes directly from
the exact captured `BaseCommit` Git blobs, including the migration ledger.
Worktree filters cannot create false drift, while genuine committed drift,
ambiguous tree entries, staging mismatches, and remote-head movement continue
to fail closed.

## Scope

- Add one bounded binary-safe local Git-blob reader to the production updater.
- Resolve every migration input and the optional ledger through the validated
  regular-blob entry in the captured base commit.
- Preserve worktree containment and destination checks for later writes.
- Preserve exact staged, committed, proposal, default-head, and remote
  validation behavior.
- Add project-neutral, capability-owned regression coverage for Windows
  checkout filtering, true committed drift, ledger handling, and rerun
  idempotency.
- Publish the correction as immutable `v0.12.1` after merge.

## Non-goals

- Changing `MIG-0001`, the migration catalog or ledger schema, the capability
  catalog, or consumer path authority.
- Adding a named-consumer, source-tag, or one-off transition branch.
- Reading arbitrary untracked worktree files or normalizing consumer content.
- Changing remote proposal, supersession, finalization, or merge behavior.
- Mutating or merging a consumer repository or its existing pull requests.

## Readiness evidence

- Domain and contracts: the captured base commit and its regular Git blobs are
  the only planning-input authority; the worktree remains a write destination,
  not committed-state evidence. Blob bytes are opaque byte arrays and must not
  pass through text decoding, newline normalization, shell redirection, or
  culture-sensitive conversion.
- Consumers and dependencies: the affected entry point is
  `Get-ConsumerMigrationPlanForBase` in the managed updater template. The
  current-launcher path and ordinary engine-era updater share that production
  planner. DEC-0018 and DEC-0020 remain authoritative; no new decision is
  required.
- Compatibility: clean repositories behave identically across checkout
  filtering settings; genuine committed states and all existing fail-closed
  proposal guards retain their current meaning.
- Verification approach: declare `TEST-0141`, record its expected-red result,
  implement the smallest production correction, run the focused consumer
  update suite, structural discovery, relevant Windows-native evidence, one
  full validation, one bounded fresh-diff review, and the required bounded
  post-development scan.

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0151` | Committed-state integrity | Worktree filters continue to influence planning or ledger identity | Updater maintainer / read exact validated base blobs and prove LF-blob/CRLF-worktree equivalence in `TEST-0141` |
| `RISK-0152` | Binary and process safety | Native stdout decoding, quoting, or a failed Git process corrupts or truncates blob bytes | Updater maintainer / binary stream copy, exact blob identity verification, explicit exit handling, and negative cases in `TEST-0141` |
| `RISK-0153` | Fail-closed regression | Avoiding false drift also accepts genuine committed drift or weakens staged/result validation | Updater maintainer / distinct committed-drift case plus unchanged staging, commit, and remote lifecycle regressions |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0141](test-cases.md) |
| Test code | Implemented and automated | `TEST-0141` is owned by the consumer-update capability and uses isolated real Git repositories |
| Baseline run | Green | Immutable `v0.12.0`; issue #81 owns the hosted and publication evidence |

## Decomposition and review gate

This correction is one cohesive, independently testable slice; creating a
separate subfeature would add no independent review boundary.

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `FEAT-0033` | Canonical base-blob input acquisition and its focused regression | [Issue #83](https://github.com/hasanmanzak/meAndAI/issues/83) | `TEST-0141`; expected-red and focused green recorded | `FIND-0173` resolved; final convergence scan passed | Complete |

## Decisions and relationships

- Migration model: [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) / [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
- Current-launcher recovery: [FEAT-0028](../FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md) / [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md)
- Capability test architecture: [FEAT-0032](../FEAT-0032-general-capability-test-architecture/README.md) / [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md)
- Tracking and post-publication authority: [issue #83](https://github.com/hasanmanzak/meAndAI/issues/83)

## Definition of Ready

- [x] Stable `FEAT-0033`, `BUG-0014`, `TEST-0141`, and linked issue #83 exist.
- [x] Problem, outcome, scope, and non-goals are explicit.
- [x] Acceptance criteria are measurable.
- [x] Byte authority, process, path, compatibility, lifecycle, and error
      contracts are explicit.
- [x] Consumers, entry point, dependencies, and governing decisions are
      identified.
- [x] `RISK-0151` through `RISK-0153` have owners and required evidence.
- [x] The work is one bounded reviewable slice; no artificial subfeature is
      required.
- [x] The numbered regression scenario and verification approach are defined.
- [x] Test-code and baseline states are recorded before implementation.

## Acceptance criteria

1. Migration inputs and the optional ledger are read as binary-safe bytes from
   their validated regular-blob entries in the exact captured `BaseCommit`.
2. Planning never substitutes worktree bytes for committed-state evidence, but
   containment and destination validation still protect every later write.
3. A fresh clean Windows checkout with `core.autocrlf=true`, no consumer
   `.gitattributes`, and committed LF bytes produces the exact expected plan
   without false drift, including when the ledger is present.
4. A distinct true committed-byte drift remains rejected before proposal or
   remote mutation.
5. Applying the exact plan and planning again is an exact no-op; staged,
   committed, proposal, and remote/default-head verification remain unchanged.
6. `TEST-0141`, the focused consumer-update suite, structural discovery, full
   validation, and the bounded review/scan complete with no unresolved
   `Blocking` finding.

## Self-review

The bounded fresh-diff review challenged the byte-authority, native-process,
worktree, staged-result, and remote-planner boundaries.

- The binary reader accepts only a canonical SHA, resolves one Git application,
  runs `git cat-file blob` in the exact workspace, copies stdout through a
  binary stream, drains stderr concurrently, and fails on any nonzero exit.
- The planner still requires each path to be one contained regular worktree
  file, but the bytes supplied to the pure engine come only from the validated
  base tree entry. The remote finalizer remains on its existing GitHub blob API
  path.
- `FIND-0173` identified that reading only the base blob could hide a genuine
  dirty-worktree content change that the old raw-byte comparison rejected.
  The correction now compares the worktree's Git clean-filtered blob identity
  with the exact base blob before planning. This accepts CRLF smudging while
  rejecting semantic worktree drift; `TEST-0141` exercises both states.
- Exact staged and committed output-blob checks, proposal ownership, default-
  head revalidation, and remote-head leases were not weakened. The complete
  consumer-update owner suite passed after the review correction.

### Finding register

| ID / title | Classification / disposition | Dependency | Priority / severity / impact rank | Evidence and impact rationale | Action / status | Links |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0173` - Canonical planning initially omitted dirty-worktree equivalence | Committed-state integrity regression / `Blocking` | None | `p1` / high / high | The first correction read exact base blobs but did not separately prove that a present worktree file still represented that blob after Git clean filters; a semantic local edit could therefore be overwritten even though CRLF-only smudging must be accepted | Add the exact clean-filtered worktree/base-blob gate, a real uncommitted-drift negative, and retain canonical blob bytes as the only plan input / `Resolved` and verified in `TEST-0141` on 2026-07-19 | `RISK-0153`, `BUG-0014`, [issue #83](https://github.com/hasanmanzak/meAndAI/issues/83) |

### Local verification evidence

- Expected red: adapter fixture rejected a clean filtered ledger with
  `Consumer migration ledger must use LF line endings.` before the production
  correction.
- `tests/capabilities/consumer-update/protocol-update.tests.ps1`: passed all
  27 owned scenarios including `TEST-0141` in 56.2 seconds after `FIND-0173`.
- `tests/capabilities/initial-adoption/quick-adoption.tests.ps1 -Shard
  ContractsPreflight`: passed in 15.9 seconds.
- `tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1`:
  passed all 17 owned scenarios in 485.8 seconds.
- The final structure, parse, link, and stale-reference scan is recorded in
  [TEST-0141 evidence](test-cases.md); hosted PR checks remain the external
  pre-merge gate.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful local results recorded.
- [x] Bounded self-review and post-development scan complete.
- [x] No unresolved `Blocking` finding.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Pull request [#84](https://github.com/hasanmanzak/meAndAI/pull/84) is
      cross-linked.
- [ ] Final hosted-check evidence is cross-linked after the candidate passes.
- [ ] Applicable hosted CI gates pass before merge.

## Post-merge release evidence

[Issue #83](https://github.com/hasanmanzak/meAndAI/issues/83) is the stable
external publication authority, with implementation review in [PR
#84](https://github.com/hasanmanzak/meAndAI/pull/84). Exact merge commit,
immutable release, branch cleanup, and post-publication verification remain
`Pending` until those facts exist.
