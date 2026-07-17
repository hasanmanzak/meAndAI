# 2026-07-17 - v0.10.3 Generic Consumer Transition Reconciliation

## Scope

- [FEAT-0026 / BUG-0012](../../../docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md)
- [DEC-0018](../../../docs/decisions/DEC-0018-release-declared-consumer-migrations.md)
- [Issue #69](https://github.com/hasanmanzak/meAndAI/issues/69)

## Durable decisions

- Consumer migration is a generic protocol-transition capability, not a
  version-named repair. The immutable target release declares an ordered,
  append-only catalog in `migrations/index.json`; each `MIG-NNNN` definition
  is declarative and bound by its Git blob identity.
- `.ai/meandai-update-state.json` is the consumer automation ledger. Its
  ordered `{id, definitionBlob}` entries must be an exact prefix of the target
  catalog before an engine-era transition can append newly satisfied entries.
- The pure migration engine classifies actual consumer state, plans every
  output in memory, and has no shell, network, credential, GitHub, commit,
  push, or merge authority. Exact legacy state may change; exact satisfied
  state is a no-op; ambiguous state blocks the full plan.
- An engine-era update stages the target gitlink, changed updater assets,
  catalog-derived consumer paths, and ledger in one reviewed draft. Proposal,
  supersession, candidate, and finalization evidence bind the complete plan.
- Fresh adoption writes the target catalog as a fully satisfied baseline; it
  does not replay historical migrations or invent consumer content.
- Immutable updater code installed before the engine cannot execute a contract
  introduced by its target release. It first merges the ordinary updater
  proposal it can prove. The newly installed engine then detects absent legacy
  capability/ledger state and automatically opens one same-target migration
  reconciliation draft. The ordinary finalizer cleans its exact branch and
  issue after maintainer merge. Later compatible transitions are single-draft.
- Derdini is the first regression fixture, not a control-flow exception.
  `MIG-0001` changes its eight active duplicated-live-pin fragments while
  preserving dated adoption memory, the completed adoption feature, and other
  historical version evidence.
- Customized, partial, mixed, linked, escaping, and otherwise ambiguous states
  fail closed before remote mutation.
- Compatible descendant catalogs are validated cumulatively in numeric release
  order. An intermediate migration cannot disappear or change when a consumer
  skips directly to a later release.
- Schema-2 finalization does not trust its marker or issue as proof. It reloads
  the immutable target engine/catalog, recomputes from the pull-request base,
  and verifies gitlink, updater assets, outputs, ledger, and path set before
  deleting the exact branch or closing the issue.
- Migration destination validation includes the leaf. A symlink, junction, or
  other reparse destination blocks before any write and cannot redirect output
  outside the consumer repository.

## Evidence state

- [TEST-0119 through TEST-0122](../../../docs/features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md)
  define the Derdini state-based regression, negative/atomic engine matrix,
  single-draft lifecycle, and generic pre-engine handoff.
- Focused `TEST-0119` through `TEST-0122` evidence passes, including cumulative
  catalog removal/rewrite negatives, linked-leaf containment, rollback,
  one-draft engine-era updates, generic pre-engine handoff, and independent
  schema-2 merge-finalization recomputation.
- The complete local Windows PowerShell 5.1 suite passed in 531.5 seconds with
  every discovered child suite and root scenario aggregation green.
- Hosted and post-publication evidence remain separate external gates.

## Continuation

Continue PR, hosted-check, merge, branch-cleanup, immutable-release, and
post-publication work. Record external facts only after they exist.
