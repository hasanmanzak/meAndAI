# FEAT-0026 - v0.10.3 Generic Consumer Transition Reconciliation

| Field | Value |
| --- | --- |
| Classification | Compatibility architecture correction / `BUG-0012` |
| Status | Complete |
| Target version | 0.10.3 |
| Issue | [#69](https://github.com/hasanmanzak/meAndAI/issues/69) |
| Pull request | [#71](https://github.com/hasanmanzak/meAndAI/pull/71) |
| Decision | [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md) |
| Tests | [TEST-0119 through TEST-0122](test-cases.md) |

## Problem and intended outcome

Compatible protocol updates currently reconcile the protocol gitlink and three
updater assets. They do not have a generic contract for consumer-owned derived
state that must change with the protocol. The first affected adoption exposed
the initial instance:
eight active files retained a copied protocol tag or commit, while three dated
records correctly retained the same values as historical evidence.

The defect is not confined to the version that created those files. An
ordinary update can move that consumer to a newer gitlink while leaving the
same stale content in place. Replace the version-specific repair prototype
with a generic, release-declared transition mechanism. Engine-era consumers
must receive the protocol pin, updater assets, required consumer migrations,
and migration ledger in one reviewed pull request. Consumers whose immutable
updater predates the engine must enter one explicit capability handoff and then
use that same path for every later compatible transition.

## Scope

- Add the ordered immutable catalog `migrations/index.json` and declarative
  definitions `migrations/MIG-NNNN.json`.
- Add the pure `scripts/MeAndAI.ConsumerMigrations.psm1` engine. It validates,
  classifies, plans, and verifies deterministic migrations without network,
  shell, AI, commit, push, issue, pull-request, or merge authority.
- Add consumer automation ledger `.ai/meandai-update-state.json`, binding each
  satisfied migration ID to the exact immutable definition blob.
- Make fresh adoption write a complete target-catalog baseline ledger so
  historical definitions are satisfied without rewriting unrelated files.
- Require an exact current-ledger prefix and validate every compatible,
  semantically ordered intermediate catalog as an append-only extension before
  planning an engine-era transition.
- Stage the gitlink, changed updater assets, exact migration outputs, and
  resulting ledger in one managed draft; bind its marker, issue, candidate
  validation, supersession, and finalization to the complete plan.
- Detect pre-engine consumers by missing capability/ledger rather than by a
  source tag. After their ordinary updater-installing proposal merges, have the
  newly installed engine open one same-target reconciliation draft.
- Express the duplicated-live-pin regression only as `MIG-0001` data and prove that it
  applies to matching state even after an intermediate gitlink update.
- Keep the executable adoption prompt version-neutral so new consumers do not
  recreate duplicated live protocol identity.

## Non-goals

- Automatically approving or merging a consumer pull request.
- Claiming that immutable pre-engine updater code can run a target-defined
  migration in its first proposal.
- A tag-named migration switch, one script per source version, or a hardcoded
  named-consumer branch in the transition engine.
- Arbitrary search-and-replace, arbitrary target-release script execution, an
  AI migration agent, hosted service, daemon, or unrestricted consumer-tree
  write authority.
- Guessing how to merge a customized, partial, mixed, or unsupported consumer
  state.
- Defining cross-major migration policy.

## Domain contracts

### Catalog and definition identity

- Migration IDs use `MIG-NNNN` and appear once in canonical execution order.
- Every catalog entry resolves to one regular definition file in the same
  immutable protocol release and binds its Git blob identity.
- A compatible target catalog is append-only relative to the consumer's exact
  satisfied ledger prefix. Existing IDs and definition blobs cannot change,
  disappear, or reorder.
- A migration definition declares an exact path set and deterministic state
  alternatives. It cannot expand its path authority at runtime.

### State and ledger

- The engine classifies actual bytes, not the installed release name. Exact
  legacy state plans a transformation; exact target state is already
  satisfied; every ambiguous state blocks the complete plan.
- Schema 1 ledger entries are ordered `{id, definitionBlob}` records. The
  ledger is automation evidence and never a second live protocol version.
- Planning and candidate verification independently derive the same catalog
  suffix, path set, output blobs, ledger, and plan digest from immutable source
  and the pull request base.

### Mutation and ownership

- All outputs and every destination component, including the leaf itself, are
  computed and validated before the first write. Linked/reparse destinations
  fail before mutation. Local failure restores original bytes; remote proposal
  mutation begins only after the full plan is valid.
- The managed path contract for one proposal is the normal updater path set
  plus that proposal's exact catalog-derived changed paths and ledger. This is
  temporary release-declared authority, not permanent ownership of consumer
  files.
- Historical event records may preserve exact tags and commits. `MIG-0001`
  changes only the eight active duplicated-live-pin current-authority fragments.

### Lifecycle behavior

- An engine-era update produces one draft and one tracking issue for the whole
  transition. Supersession rebuilds the plan from unchanged default-branch
  state before closing exact older owned state.
- A pre-engine updater may only install the new engine through its existing
  proven path set. Once merged, the new engine detects `MigrationRequired` and
  emits one automatic reconciliation draft for the still-unsatisfied target
  catalog. Later transitions are single-draft.
- Schema-2 merge finalization independently reloads the immutable target
  engine/catalog and the pull-request base blobs, recomputes the plan, and
  verifies the target gitlink, updater assets, outputs, ledger, and path set
  before cleanup. Cleanup remains pull-request and branch first, issue last,
  under the existing exact ownership and idempotency rules.

## Risks

| ID | Classification | Risk | Response and required evidence |
| --- | --- | --- | --- |
| `RISK-0112` | Atomicity | A rejected or interrupted migration leaves a partial tree | Pure full-plan computation, byte snapshots, rollback, and `TEST-0120` |
| `RISK-0113` | Ownership | Release migration authority becomes an unrestricted consumer overwrite surface | Immutable exact paths, exact state preconditions, plan digest, and `TEST-0120` |
| `RISK-0114` | Retroactivity | Documentation promises same-PR behavior from code installed before the engine | Explicit generic legacy handoff and `TEST-0122` |
| `RISK-0115` | Recurrence | A future transition needs another version-named repair | Append-only generic catalog, state-based applicability, and `TEST-0119` / `TEST-0121` |
| `RISK-0116` | Provenance | A changed or reordered definition is treated as previously satisfied | Exact definition-blob ledger prefix and `TEST-0121` |
| `RISK-0117` | Proposal integrity | Candidate validation accepts migration paths not produced by the target catalog | Recomputed exact path/output/ledger/plan evidence and `TEST-0121` |
| `RISK-0118` | Historical accuracy | Live-pin cleanup erases legitimate adoption evidence | Explicit `MIG-0001` preservation set and project-neutral regression in `TEST-0119` |

## Definition of Ready

- [x] Stable `FEAT-0026`, `BUG-0012`, `SUBF-0046` through `SUBF-0048`,
      `MIG-0001`, `TEST-0119` through `TEST-0122`, and issue #69 exist.
- [x] Catalog, definition, ledger, state classification, temporary path
      authority, proposal identity, and fail-closed contracts are explicit.
- [x] Same-PR engine-era behavior and immutable pre-engine handoff are separated
      without a false retroactivity claim.
- [x] Affected active and historical files are classified, and the regression
      must survive a simulated intermediate protocol update.
- [x] Scope excludes arbitrary execution, AI migration, major transitions, and
      automatic merge.
- [x] Baseline is the green immutable v0.10.2 release; revised generic tests are
      planned and not represented as already passing.

## Acceptance criteria

1. No public parameter, function, file, feature, or decision names a specific
   source version as the migration mechanism.
2. A target immutable release exposes a validated append-only migration catalog
   and exact declarative definition blobs.
3. The pure engine classifies and plans from repository state, produces a
   deterministic exact path/output/ledger plan, and has no remote authority.
4. An engine-era compatible update creates one draft containing the gitlink,
   changed updater assets, exact required migration paths, and ledger.
5. Candidate validation, supersession, and merge finalization independently
   prove the catalog, ordered IDs, definition blobs, changed paths, and plan.
6. The real duplicated-live-pin stale state is reconciled by `MIG-0001` both at its
   original pin and after a simulated update to an intermediate pin. The eight
   active fragments change and dated historical evidence does not.
7. A directly adopted version-neutral consumer records `MIG-0001` as satisfied
   without rewriting unrelated consumer files.
8. Missing, duplicated, reordered, mixed, drifted, unsupported-schema, linked,
   out-of-root, or write-failure states stop without remote mutation and do not
   leave a partial local tree.
9. A pre-engine consumer first installs the engine through the immutable old
   updater's ordinary proposal, then receives one automatically created
   same-target reconciliation draft; no source tag is hardcoded.
10. After that handoff, later and skipped compatible releases use the same
    single-draft catalog/ledger flow and idempotent reruns create no duplicate
    work.

## Decomposition and review gates

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0046` | Immutable catalog, pure engine, ledger model, and project-neutral `MIG-0001` data | [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) | `TEST-0119`, `TEST-0120` | Exact state/bytes, cumulative catalog chain, leaf-link rejection, historical preservation, and rollback passed | Implemented |
| `SUBF-0047` | Engine-era one-draft updater, candidate, supersession, and finalization integration | [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) | `TEST-0121` | Exact ledger/path/plan evidence and independent schema-2 base-to-head finalization passed, including fabricated-output rejection | Implemented |
| `SUBF-0048` | Generic pre-engine capability handoff and prospective adoption prevention | [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) | `TEST-0122` and `TEST-0119` | Capability-based automatic handoff, adoption baseline, and absence of tag-specific control flow passed | Implemented |

## Verification approach

Use a minimal project-neutral legacy-consumer fixture and an independent expected-byte oracle for
`MIG-0001`. Exercise that same consumer state under both its original gitlink
and a simulated intermediate gitlink; also exercise a direct version-neutral
consumer. Add catalog/ledger contract fixtures, skipped releases, supersession,
idempotent reruns, exact candidate/finalizer proof, and the pre-engine two-draft
handoff. The negative matrix must cover identity, schema, ordering, path,
content, encoding, linked-path, dirty-tree, and injected write/publish
failures before one complete repository validation run.

## Relationships

- Consumer update lifecycle: [FEAT-0023](../FEAT-0023-v0100-idempotent-consumer-lifecycle/README.md) / [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- Reviewed supersession: [FEAT-0002](../FEAT-0002-semi-automatic-consumer-updates/README.md) / [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Managed finalization: [FEAT-0022](../FEAT-0022-v097-managed-merge-finalization/README.md) / [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md)
- Generic migration decision: [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md)
- Tracking: [issue #69](https://github.com/hasanmanzak/meAndAI/issues/69)
- Delivery draft: [pull request #71](https://github.com/hasanmanzak/meAndAI/pull/71)

## Self-review state

The tag-specific prototype was removed. The bounded generic review found three
blocking gaps: intermediate catalogs were compared only with the installed
catalog, schema-2 finalization trusted self-asserted hashes, and a linked leaf
could pass the parent-only containment check. The implementation now validates
the complete semver-ordered catalog chain, independently recomputes merged
schema-2 evidence from immutable source and PR-base blobs, and rejects linked
leaf destinations before any write. Dedicated negative cases cover all three
findings; the focused migration, updater, finalizer, adoption, and launcher
suites pass with no unresolved in-scope blocker.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory generic test code and scenario ownership complete.
- [x] Each subfeature passed focused self-review with no unresolved blocking
      finding.
- [x] One complete local repository validation passes.
- [ ] Applicable hosted checks pass.
- [x] Documentation, links, version, changelog, and project memory agree.
- [ ] Pull request, merge, exact branch cleanup, immutable release, and
      post-publication evidence complete.

## Publication authority

[Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69) owns the external
pull-request, hosted-check, merge, branch-deletion, release, asset, and
post-publication facts after they exist. This record does not project them.
