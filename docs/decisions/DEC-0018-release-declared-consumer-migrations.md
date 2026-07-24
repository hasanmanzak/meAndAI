# DEC-0018 - Use Release-Declared Consumer Migrations for Protocol Transitions

- Classification: Decision
- Status: Accepted
- Date: 2026-07-17
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0026](../features/FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md)
- Related decisions: [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md), [DEC-0010](DEC-0010-stable-automation-invariants.md), [DEC-0011](DEC-0011-qualified-evidence-and-closure.md), and [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md)
- Corrects: [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md) only where prospective version-neutral templates were
  treated as sufficient evidence for consumers created by an earlier release

## Context

The updater historically treats the protocol gitlink and three updater assets
as its complete managed path set. That boundary safely updates common protocol
code, but it cannot reconcile consumer-owned derived state when a protocol
release changes the required shape of that state. The first affected adoption exposed
the first concrete example: eight active files retained a copied live protocol
tag or commit while three dated historical records legitimately retained the
same values.

This is a transition problem, not a source-version problem. A consumer can
carry the same stale state after one or more ordinary gitlink updates, so the
currently installed tag cannot identify whether reconciliation is required. A
one-off switch or runner named after the release where the symptom first
appeared would only defer the same design defect to the next transition.

## Decision

### Immutable release catalog

Each protocol release carries a canonical migration catalog at
[`migrations/index.json`](../../migrations/index.json). A migration is an
immutable declarative definition at `migrations/MIG-NNNN.json`. The catalog is
ordered and append-only within a compatible major line: every semantically
ordered intermediate descendant catalog must exactly extend its predecessor,
and an accepted target catalog must contain the current satisfied prefix with
identical definition blob identities before it may append new definitions.

A definition declares one stable ID, schema, exact allowed consumer paths, and
deterministic state transitions. The catalog order is the execution order; no
runtime dependency graph is inferred. A definition cannot invoke a shell,
network service, AI agent, or arbitrary target-release script. The pure
[`MeAndAI.ConsumerMigrations.psm1`](../../scripts/MeAndAI.ConsumerMigrations.psm1)
engine validates the catalog and definitions, classifies repository state, and
computes every output in memory before any write or GitHub mutation.

Migration applicability is state-based and idempotent. For every required
definition, the engine accepts only its exact legacy state or exact satisfied
state. Exact legacy state produces a planned transformation; exact satisfied
state is a no-op. Missing, duplicated, mixed, drifted, unsupported, linked, or
out-of-root state blocks the complete plan. The engine preserves unrelated
content, historical evidence, UTF-8 BOM state, and newline style. The bounded
updater adapter applies the complete plan and restores original byte arrays if
a later local write fails.

### Consumer ledger

The consumer records automation state in
`.ai/meandai-update-state.json`. Schema 1 contains an ordered `satisfied` list
whose entries bind a migration ID to its immutable `definitionBlob`. The
ledger is protocol-automation state, not project memory and not a substitute
for the gitlink or `VERSION` authority.

Before an engine-era transition, the current ledger must be an exact prefix of
the target catalog. After planning the catalog suffix, the resulting ledger
must be the exact target satisfied prefix. A reordered, unknown, duplicated,
missing, or hash-mismatched entry blocks before mutation. An absent ledger is
accepted only by the explicit legacy-capability handoff below.

A fresh adoption creates the ledger with the target catalog's complete ordered
ID/blob sequence already satisfied. Adoption therefore prevents the stale
shape prospectively without replaying historical migrations against a new
consumer or inventing project content.

### One reviewed transition proposal

When the installed updater already supports this decision, it plans one
transaction from the current default-branch commit to the latest compatible
immutable target. The draft pull request stages exactly:

1. the target protocol gitlink;
2. updater assets whose target blobs differ;
3. consumer paths changed by the validated catalog suffix; and
4. the resulting ledger.

The proposal marker and issue evidence bind the base, target tag and commit,
catalog identity, ordered migration IDs, definition blobs, exact changed-path
set, and plan digest. Candidate validation recomputes this evidence before
merge. Finalization independently reloads the immutable target engine and
catalog, reconstructs the plan from the pull-request base blobs, and compares
the head gitlink, updater assets, migration outputs, ledger, and exact path set
before cleanup. A newer target supersedes an older proposal only through the existing
owned pull-request, branch, and issue cleanup rules, then creates a replacement
plan from the unchanged default-branch base. The maintainer still reviews and
merges; automation does not approve or merge.

### Immutable legacy-capability handoff

An updater installed before this engine existed cannot retroactively execute
the target release's new migration contract while creating its first proposal.
The old updater therefore creates only the ordinary gitlink/updater proposal it
can prove. After that proposal merges, the newly installed engine detects the
absent ledger as a capability boundary, classifies the target catalog against
the consumer's actual state, and automatically opens one same-target migration
reconciliation draft. This is a generic `MigrationRequired` capability state,
not a tag-specific switch.

That one-time second reviewed proposal is unavoidable for a pre-engine
consumer unless a separately authorized current launcher owns the complete
transition proposal. Documentation must not claim that immutable old code can
produce a target-defined same-PR migration. After the handoff ledger merges,
all later compatible transitions use the normal single-proposal path.

### First catalog entry

[MIG-0001](../../migrations/MIG-0001.json) represents the first-observed duplicated-live-pin state as data,
not as version-specific control flow. It recognizes the exact eight active
current-authority fragments and replaces them with gitlink/`VERSION`-derived
forms. It explicitly leaves the dated adoption memory log, completed adoption
feature, and other historical version evidence unchanged. The same definition
must reconcile both the original duplicated-live-pin shape and that same state
state after an intermediate protocol gitlink update.

## Consequences

- Consumer reconciliation becomes a normal, reviewable part of compatible
  protocol transitions instead of a new custom repair for every release.
- Engine-era consumers receive protocol, updater, migration, and ledger changes
  in one owned draft pull request.
- Pre-engine consumers require one truthful capability handoff and then join
  the same normal path; the boundary is detected by ledger/engine capability,
  not an installed release name.
- Consumer-owned paths are never a permanently broad overwrite surface. Each
  release declares the exact temporary path and transformation authority, and
  the updater recomputes it from immutable evidence.
- Unknown consumer customization blocks for maintainer review instead of being
  guessed, discarded, or silently marked satisfied.

## Alternatives considered

- Add a source-version-named migration switch: rejected because the same stale
  state can survive under a later gitlink and future transitions would require
  more switches.
- Infer migrations only from current and target version tags: rejected because
  repository state, not the current tag, determines whether derived consumer
  content is stale.
- Give every updater unrestricted write authority over consumer files:
  rejected because it breaks the consumer-ownership boundary.
- Execute arbitrary scripts from the target release: rejected because it
  expands the credential and supply-chain execution boundary unnecessarily.
- Claim a same-PR migration from every historical updater: rejected because an
  immutable pre-engine updater cannot interpret a contract introduced later.
- Require manual issue, branch, or migration setup for every transition:
  rejected because the lifecycle already owns deterministic proposal and
  cleanup orchestration.

## Review condition

Review if the migration schema cannot express a required deterministic state
transition, if catalog growth creates an unacceptable validation cost, if a
major-version policy is approved, or if GitHub provides a narrower atomic
proposal/finalization primitive.
