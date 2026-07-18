# FEAT-0028 - v0.10.4 Atomic Legacy Updater Recovery

| Field | Value |
| --- | --- |
| Classification | Consumer updater recovery feature and confirmed bug correction |
| Status | Complete |
| Target version | 0.10.4 |
| Bug | `BUG-0013` |
| Issue | [#74](https://github.com/hasanmanzak/meAndAI/issues/74) |
| Pull request | Pending |
| Decision | [DEC-0020](../../decisions/DEC-0020-target-bound-current-launcher-recovery.md) |
| Tests | [TEST-0125 and TEST-0126](test-cases.md) |

## Problem and intended outcome

An immutable updater installed before the consumer-migration engine can only
dispatch its own old workflow. The v0.10.3 handoff therefore creates a
core-only proposal first and migration output only after that proposal merges.
A correct consumer pre-merge validator can reject the intermediate tree, so
the handoff cannot complete without weakening a required gate. Older updater
drafts may also lack the later canonical tracking-issue contract.

The latest verified quick launcher must recover this capability gap without a
source-version switch. It runs the explicitly requested immutable target
updater in an isolated local clone of the exact consumer default-branch head.
That updater creates one schema-2 draft containing
the target gitlink, changed updater assets, every required declarative
migration output, and the ledger. A strictly qualified legacy unbound draft is
cleanup-only and is retired only after the replacement is fully validated.

## Scope

- Add a target-bound current-launcher route for completed compatible adopters
  whose installed updater cannot plan the target catalog atomically.
- Clone the consumer and target protocol release into a contained temporary
  workspace; never modify the maintainer's checkout or consumer default branch.
- Reuse the target release's production resolver, migration engine, proposal
  builder, validation, and replacement-first cleanup.
- Accept catalogless pre-engine releases only before the first catalog and
  only when the committed consumer ledger is absent.
- Use the authenticated local GitHub CLI and Git credential configuration for
  bounded publication; never read or copy stored Actions secret values.
- Bind planning to the requested immutable target even if a newer release is
  published while the run is active.
- Qualify an issue-less or `#REQUIRED` schema-1 legacy draft only as
  `SupersedeOnly` under exact ownership, byte, path, and branch evidence.

## Non-goals

- A tag-named repair, repository-specific branch, or `v0.9.2` special case.
- Changing `MIG-0001` or introducing another migration format.
- Arbitrary target script execution, an AI migration agent, or a hosted
  bootstrap service.
- Guessing customized, partial, mixed, linked, or unsupported consumer state.
- Reading stored Actions secret values or automatically merging a proposal.
- Replacing normal scheduled engine-era updates after recovery is complete.

## Contracts and risks

### Current-launcher identity and containment

- The route is enabled only by the latest quick launcher after it verifies the
  target as a published immutable release and verifies the completed consumer.
- The isolated consumer clone starts at the captured remote default-branch
  head and contains no credential source files. The isolated protocol clone
  resolves the requested tag to the previously verified immutable commit.
- The target adapter receives current-launcher mode, repository, default
  branch, captured base SHA, requested tag, and target commit explicitly. Its
  source checkout, resolver, catalog, and assets must match that identity.
- The remote default head is re-read before the first issue, branch, or pull
  request mutation. Movement blocks and leaves the maintainer checkout and
  default branch unchanged.

### Atomic proposal and legacy cleanup

- The target adapter imports its resolver from the verified target source and
  limits release inventory to the explicit target ceiling.
- Catalogless releases are allowed only until the first catalog; a catalog may
  never disappear after that point. An existing ledger without a catalog is
  invalid.
- The ordinary production proposal path stages the gitlink, target-different
  updater assets, catalog outputs, and ledger as one exact path set.
- A `SupersedeOnly` candidate can never satisfy or replace the requested
  proposal. It is closed and lease-deleted only after the new schema-2 draft
  independently passes the same managed-candidate validation.
- No artificial tracking issue is created solely to retire a historical
  issue-less draft; the replacement receives the normal canonical issue.

| ID | Classification | Risk | Response and required evidence |
| --- | --- | --- | --- |
| `RISK-0123` | Atomicity | A core-only intermediate tree still reaches review | One production staging path and real consumer-validator regression, `TEST-0125` |
| `RISK-0124` | Provenance | A later release changes the requested target during the run | Explicit target ceiling and exact release/source/base identity, `TEST-0126` |
| `RISK-0125` | Containment | Local recovery changes the maintainer checkout or publishes from a moving base | Isolated clones, captured base SHA, remote-head revalidation, and bounded cleanup, `TEST-0126` |
| `RISK-0126` | Destructive cleanup | An unrelated or ambiguous historical PR is classified as legacy updater state | Narrow schema-1 `SupersedeOnly` contract and replacement-first cleanup, `TEST-0126` |
| `RISK-0127` | Authority | Recovery mutates the default branch or exposes secret values | Local `gh` authentication, no secret reads, exact proposal branch only, `TEST-0126` |
| `RISK-0128` | Recurrence | A future transition adds another source-version repair | Capability/catalog/ledger state detection with no source-tag or consumer-name branch, `TEST-0125` |

## Definition of Ready

- [x] Stable `FEAT-0028`, `BUG-0013`, `SUBF-0051`, `SUBF-0052`,
      `DEC-0020`, `TEST-0125`, `TEST-0126`, and issue #74 exist.
- [x] Problem, intended outcome, scope, non-goals, entry points, consumers,
      ownership, errors, cleanup, compatibility, and security boundaries are
      explicit.
- [x] The design reuses the existing updater, migration engine, and proposal
      validation instead of adding a second implementation.
- [x] Target/ref identity, catalogless legacy state, atomic staging,
      interruption, ambiguity, and replacement-first behavior have numbered
      success and negative scenarios.
- [x] Work is decomposed into launcher handoff and updater recovery slices.
- [x] Immutable v0.10.3 plus merged FEAT-0027 is the green baseline; test code
      is planned and not represented as passing.

## Acceptance criteria

1. The quick launcher routes an older completed compatible adoption through
   the verified target adapter in an isolated local clone without modifying
   the maintainer checkout or consumer default branch.
2. The run is pinned to the requested immutable target and cannot drift to a
   release published later.
3. A catalogless, ledgerless pre-engine consumer can plan through catalogless
   intermediate releases until the first valid append-only catalog; every
   partial, removed, reordered, drifted, or ledger-without-catalog state blocks.
4. One schema-2 proposal contains the target gitlink, every target-different
   updater asset, all required declarative migration outputs, and the exact
   ledger. There is no required red intermediate merge.
5. A Derdini-shaped core-only tree fails its real validator; the atomic
   proposal tree passes that validator and an exact rerun creates no duplicate
   work.
6. A strictly qualified legacy unbound draft is never retained as the current
   proposal and is cleaned only after the replacement validates. Ambiguous
   tracking, ownership, paths, bytes, head, or branch state blocks unchanged.
7. Isolated clone creation, exact base reuse, interruption cleanup, remote-base
   revalidation, and proposal publication are deterministic and fail closed on
   drift.
8. Existing engine-era single-proposal updates, adoption, supersession,
   finalization, and secret-preservation contracts remain green.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0051` | Target-bound isolated local launcher, exact-base handoff, and interruption-safe cleanup | [Issue #74](https://github.com/hasanmanzak/meAndAI/issues/74) | `TEST-0126` | Target/base/checkout/default-branch/secret/race negative matrix passes; fresh diff reviewed | Complete |
| `SUBF-0052` | Catalogless pre-engine planning, atomic production proposal, real validator, and `SupersedeOnly` cleanup | [Issue #74](https://github.com/hasanmanzak/meAndAI/issues/74) | `TEST-0125`, `TEST-0126` | Core-only red, atomic tree green, exact rerun no-op, replacement-first cleanup passes | Complete |

## Verification approach

Add focused failing tests before production changes. Reuse current adapter and
launcher mocks for local handoff and remote lifecycle evidence. Add one small Derdini-shaped
fixture containing the real pre-migration validator and only its required
project stubs; derive migration inputs from the immutable `MIG-0001` states.
Prove the core-only intermediate failure, invoke the production atomic staging
path, then run the real validator against the proposal tree. Finish with the
focused suites, one complete local suite, one bounded fresh-diff review, and
one hosted run on the converged branch.

## Relationships

- Migration model: [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) / [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
- Consumer lifecycle: [FEAT-0023](../FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) / [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- Quick launcher: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md)
- Tracking: [issue #74](https://github.com/hasanmanzak/meAndAI/issues/74)
- Shared release train: [FEAT-0027](../FEAT-0027-v0104-runner-minute-efficiency/README.md)

## Self-review state

The implementation uses one target-source adapter and one production proposal
path. Focused review found and closed two lifecycle gaps before publication:
schema-2 recovery branches now finalize after merge, and an interrupted rerun
selects only the verified recovery replacement before legacy cleanup. The real
Derdini validator, isolated-launcher shard, resolver, adapter, and finalizer
regressions pass locally with no unresolved blocking finding.

A later real v0.10.4 adoption exposed `FIND-0158`: Windows PowerShell 5.1
promoted successful native Git stderr to a terminating error before the target
adapter could inspect exit code 0. The immutable v0.10.4 release remains
unchanged; [FEAT-0029](../FEAT-0029-v0110-protocol-aware-initial-adoption/README.md),
[PR #78](https://github.com/hasanmanzak/meAndAI/pull/78), and the amended
`TEST-0126` carry the forward correction.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario ownership complete.
- [x] Both subfeature review gates and the complete local suite pass.
- [x] Bounded post-development scan converges with no unresolved `Blocking`
      finding.
- [x] Documentation, links, changelog, version, and project memory agree.
- [ ] Applicable hosted checks pass.
- [ ] Pull request, merge, exact branch cleanup, immutable v0.10.4 release,
      and post-publication evidence complete.

## Publication authority

[Issue #74](https://github.com/hasanmanzak/meAndAI/issues/74) owns exact hosted
run, merge, branch-deletion, immutable v0.10.4 release, asset, and
post-publication facts after they exist. Issue #72 remains the linked release
co-owner for FEAT-0027.
