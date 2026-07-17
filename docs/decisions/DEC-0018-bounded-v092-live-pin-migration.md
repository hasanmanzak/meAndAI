# DEC-0018 - Repair Recognized v0.9.2 Live Pins Through an Explicit Local Migration

- Classification: Decision
- Status: Accepted
- Date: 2026-07-17
- Decision owners: meAndAI maintainers and affected consumer maintainers
- Related feature: [FEAT-0026](../features/FEAT-0026-v0103-v092-live-pin-migration/README.md)
- Related decisions: [DEC-0007](DEC-0007-local-quick-adoption-boundary.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), and [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md)
- Corrects: DEC-0017 only where its prospective sole-live-pin rule was claimed as executable coverage for already-created v0.9.2 consumer files

## Context

The v0.9.2 adoption path could ask local Codex to create consumer-owned records
that restated the adoption tag or commit as the current protocol identity.
FEAT-0023 later made that pattern invalid, but its `TEST-0114` checked current
templates instead of the historical consumer shape.

The consumer workflow and updater installed at v0.9.2 are immutable. During
their first later update, they stage only the protocol gitlink and the three
known updater assets. Code introduced by the target release is copied into that
proposal but cannot run before the proposal merges. A target release therefore
cannot truthfully add consumer-owned migration paths to that first proposal.

## Decision

The existing single-file quick-adoption launcher exposes an explicit
`-MigrateV092LivePins` mode. The mode first applies the ordinary completed
installation proof: one canonical submodule, exact v0.9.2 release commit, and
all three managed updater assets equal to that immutable release.

It then accepts only one of two exact eight-file states:

- every recognized legacy current-authority fragment occurs exactly once and
  no replacement fragment exists; or
- every replacement fragment occurs exactly once and no legacy fragment
  exists, which is an idempotent no-op.

Every output is computed before the first write. Missing, duplicated, drifted,
case-variant, mixed, non-UTF-8, linked-path, or unsupported content blocks with
zero writes. The writer preserves BOM state and newline style, changes only the
recognized fragments, and restores the original byte arrays if a later write
fails.

Migration mode stops immediately after local file reconciliation. It does not
inspect or change repository secrets, dispatch workflows, commit, push, create
or modify GitHub records, or merge. The maintainer reviews and merges that
bounded local change through the consumer's normal protocol. A later ordinary
launcher run then dispatches the still-installed updater, whose first managed
proposal installs current updater code. Routine updates thereafter remain
version-independent.

The executable local-Codex adoption prompt also states that the gitlink and its
`VERSION` are the sole live identity and prohibits live literals in
consumer-owned instructions, memory, decisions, features, indexes, and tests.

## Consequences

- The known v0.9.2 defect has a deterministic, reviewable, one-time bridge.
- Existing v0.9.2 consumers require one separate reviewed compatibility change
  before their ordinary update; a later release cannot remove that immutable
  retroactivity boundary.
- Recurring updater authority remains limited to the gitlink and its three
  updater assets.
- Unknown legacy shapes fail with an exact diagnostic and require explicit
  maintainer review; they are never guessed or overwritten.
- Dated adoption/update records may retain their exact historical tag and
  commit, while active decisions and verifiers derive current identity.

## Alternatives considered

- Mutate the immutable v0.9.2 release: rejected because it destroys release
  identity and supply-chain evidence.
- Pretend target-side updater code can change the first v0.9.2 proposal:
  rejected because that code is not executed before merge.
- Give every future updater permanent write authority over consumer-owned
  files: rejected because it violates ownership and creates a broad recurring
  overwrite surface.
- Build a generalized migration engine or external service: rejected as
  disproportionate to one known historical shape.
- Rewrite every repository occurrence of the tag/SHA: rejected because dated
  historical evidence must remain intact.

## Review condition

Review if another immutable release is proven to have the same defect with a
different exact consumer shape, or if the updater gains a prospective,
release-declared migration contract that was already installed before the
affected consumer state was created.
