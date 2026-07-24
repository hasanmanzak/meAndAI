# 2026-07-18 - v0.10.4 Atomic Legacy Updater Recovery

## Scope

- [FEAT-0028](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md) and [BUG-0013](https://github.com/hasanmanzak/meAndAI/issues/74)
- [DEC-0020](../../../docs/decisions/DEC-0020-target-bound-current-launcher-recovery.md)
- [Issue #74](https://github.com/hasanmanzak/meAndAI/issues/74)

## Durable decisions

- A current launcher may recover a capability gap only from the exact requested
  immutable target release and exact captured consumer default-branch SHA.
- Recovery runs the target release's ordinary adapter, resolver, migration
  engine, staging, and managed-PR validation in isolated local clones. It does
  not dispatch executable workflow YAML from a writable temporary ref.
- The maintainer checkout and consumer default branch remain unchanged. Local
  GitHub CLI and Git authentication are used without reading Actions secret
  values or copying local credential files into the recovery clone.
- Catalogless releases are accepted only before the first catalog and only
  while no committed ledger exists. Once present, the catalog remains
  append-only through the requested target.
- One schema-2 proposal contains the target gitlink, target-different updater
  assets, all required migrations, and ledger. A red core-only intermediate
  merge is not part of the supported recovery path.
- Exact schema-1 legacy drafts are cleanup-only. An unbound historical draft
  receives no synthetic issue and is retired only after the replacement passes
  the same ownership, path, blob, head, and branch checks.

## Evidence state

- [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) freezes a minimal project-neutral pre-migration validator by exact Git blob.
  It proves core-only red and the production 13-path atomic proposal green.
- [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) covers requested-target ceiling, invalid target forms, recovery
  branch separation, legacy cleanup identity, isolated-clone cleanup, and
  maintainer checkout preservation.
- Focused resolver, adapter, current-launcher recovery, and merge-finalization
  suites pass locally. The complete discovered suite passed in 589.1 seconds
  and emitted canonical [TEST-0125](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) and [TEST-0126](../../../docs/features/FEAT-0028-v0104-atomic-legacy-updater-recovery/test-cases.md) evidence.
- The bounded fresh-diff review found two lifecycle gaps, both corrected before
  publication; exact re-review found no unresolved Blocking/High issue.
- Hosted, merge, branch cleanup, immutable release, and post-publication
  evidence remain separate completion gates.

## Continuation

Publish the converged branch once. [Issue #74](https://github.com/hasanmanzak/meAndAI/issues/74) owns external delivery facts after
they exist; [issue #72](https://github.com/hasanmanzak/meAndAI/issues/72) co-owns the shared v0.10.4 release.
