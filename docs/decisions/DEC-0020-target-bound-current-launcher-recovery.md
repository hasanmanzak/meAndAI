# DEC-0020 - Use a Target-Bound Current Launcher for Atomic Legacy Recovery

- Classification: Decision
- Status: Accepted
- Date: 2026-07-18
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0028](../features/FEAT-0028-v0104-atomic-legacy-updater-recovery/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), and [DEC-0018](DEC-0018-release-declared-consumer-migrations.md)
- Supersedes: the mandatory two-proposal legacy-capability handoff in [DEC-0018](DEC-0018-release-declared-consumer-migrations.md)
  when a separately invoked, verified current launcher is available

## Context

[DEC-0018](DEC-0018-release-declared-consumer-migrations.md) correctly states that immutable old updater code cannot interpret a
future migration catalog. Its fallback installs the new engine in one proposal
and creates migration output in a second proposal. The first affected consumer demonstrates that a
consumer's required validator can reject the first core-only tree, making the
fallback incompatible with the protocol's pre-merge gate.

The latest quick launcher already verifies an explicit immutable target and
acts locally under maintainer authority. Running secret-bearing executable
workflow YAML from a temporary writable ref would create a ref-movement race
between local verification and server-side dispatch. The safer boundary is an
isolated local consumer clone plus the exact target release code, using the
maintainer's existing local GitHub CLI and Git authentication without reading
stored Actions secrets.

## Decision

For a completed compatible consumer that needs a capability unavailable in its
installed updater, the latest launcher captures the exact remote default head,
creates a contained temporary consumer clone at that commit, and clones the
requested immutable protocol release into a separate source directory. It
invokes that release's target-source adapter and resolver in `CurrentLauncher`
mode. The adapter treats catalogless,
ledgerless releases as pre-engine only until the first catalog, validates the
append-only chain, binds the available release ceiling to the explicit target,
and uses the ordinary production proposal path to create one atomic schema-2
draft.

Current-launcher parameters bind the repository, default branch, captured base
SHA, requested tag, and immutable target commit. The adapter verifies those
values against both clones and re-reads the remote default head before the first
GitHub mutation. It publishes only the ordinary managed proposal branch, issue,
and draft. The maintainer checkout and consumer default branch never receive a
bootstrap commit. The temporary directory is removed on success or failure.
Local `gh` and Git authentication are used directly; stored Actions secret
names may be inspected as metadata but their values are never requested.

A historical schema-1 draft without a canonical tracking issue may be
classified `LegacyUnbound` and `SupersedeOnly` only when its marker, release,
gitlink, updater asset blobs, exact changed paths, draft/base/head repository,
actor, branch, and live head all match immutable evidence. It never satisfies
the requested proposal. The workflow first creates and independently validates
the replacement; only then may it close the old PR and lease-delete its branch.
No issue is invented merely to close historical unbound state.

Every mismatch, target drift, ref drift, concurrent ownership ambiguity,
catalog/ledger inconsistency, customized consumer state, or cleanup uncertainty
fails closed. The maintainer still reviews and merges the resulting draft.

## Consequences

- Pre-engine consumers can cross a release-declared migration boundary with
  one reviewable green proposal instead of a knowingly red intermediate merge.
- Immutable old code remains truthful: it is not modified or claimed to know
  the future contract; a separately verified current launcher supplies it.
- The recovery mechanism is capability- and state-based, not tied to a named consumer or
  a source version.
- Recovery requires a locally authenticated maintainer invocation once for a
  pre-engine consumer; no Codex Cloud or temporary executable workflow ref is
  involved.
- Normal engine-era schedule/manual updates remain unchanged after recovery.

## Alternatives considered

- Permit the red core-only merge and rely on the second proposal: rejected
  because it weakens a mandatory consumer gate.
- Commit the current workflow to the default branch first: rejected because it
  creates another bootstrap merge and repeats the same atomicity problem.
- Dispatch target workflow YAML from a temporary consumer ref: rejected because
  a write-capable actor can move executable YAML between local verification and
  server-side dispatch while repository secrets are available to the run.
- Read or copy repository secrets into the launcher: rejected because secret
  values are intentionally non-readable and must remain inside Actions.
- Execute arbitrary target scripts: rejected because release-declared data and
  the bounded updater already provide the required authority.
- Add a `v0.9.2` or named-consumer-specific repair: rejected because the defect is a
  generic capability transition.

## Review condition

Review if GitHub provides an immutable-commit workflow-dispatch primitive with
an enforceable executable-code boundary, the migration schema can no longer
express a required deterministic transition, or local authenticated proposal
publication cannot preserve the exact-base and no-secret-read contracts.
