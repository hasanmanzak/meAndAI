# DEC-0021 - Require Explicit Strategy for Existing-Protocol Initial Adoption

- Classification: Decision
- Status: Accepted
- Date: 2026-07-18
- Decision owners: meAndAI maintainers and the adopting repository maintainer
- Related feature: [FEAT-0029](../features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md)
- Tracking and post-publication authority: [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76)
- Related decisions: [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md), [DEC-0008](DEC-0008-local-codex-execution.md), [DEC-0013](DEC-0013-trusted-adoption-and-recoverable-evidence.md), and [DEC-0018](DEC-0018-release-declared-consumer-migrations.md)

## Context

The current lifecycle safely avoids overwriting canonical target collisions,
but collision detection is not a migration policy. A repository can have a
substantial legacy protocol under different paths and still be treated as a
fresh, collision-free adoption. Conversely, an existing `AGENTS.md` may contain
valuable repository-specific directives that must survive even when its common
protocol authority changes.

The choice among semantic migration, hybrid reconciliation, and discarding old
governance records changes what information is retained and which authority
remains live. That choice belongs to the repository maintainer, not to a
bootstrapper or AI agent. A strategy gate must remain small and deterministic;
it must not grow into a universal semantic scanner or another self-validating
framework.

## Decision

Initial adoption uses a separate strategy authorization dimension in addition
to the existing lifecycle and collision states.

### Strategies

- `FreshAdoption` asserts that the bounded known-surface inventory contains no
  prior protocol evidence. Generic canonical target collisions remain
  semantic-review inputs, but do not themselves force a fictional migration
  strategy. `Auto` may select this strategy only when that assertion is true.
- `FullMigration` semantically preserves valid project directives, decisions,
  scope, dependencies, risks, test intent, and approvals, then retires the old
  protocol as live authority. Legacy paths and identifiers need not remain in
  the final tree; Git history preserves their historical form.
- `HybridReconciliation` retains selected existing structures only after a
  consumer decision records their ownership and precedence. meAndAI remains
  the common pinned authority and no two ambiguous common authorities remain.
- `CleanStart` imports no legacy governance semantics. It requires a separate
  explicit acknowledgement and may delete only reviewed protocol/governance
  record paths. It never authorizes application, asset, runtime, product-test,
  or product-documentation deletion.
- `Abort` exits the initial-adoption operation without repository or GitHub
  adoption mutation.

The three migration strategies require at least one detected protocol or
governance surface. A protocol-evidence-free repository uses `FreshAdoption`
even when a generic canonical target collision still requires semantic review;
it cannot create a fictional migration, hybrid-precedence, or record-loss
decision.

An explicit command-line strategy is suitable for automation. `Auto` with
detected evidence prompts only when interactive input is available; otherwise
it fails closed. The AI actor receives the resolved choice and cannot select,
upgrade, downgrade, or reinterpret it.

### Bounded assessment and identity

The assessment recognizes a declared, inspectable set of likely protocol and
governance paths in the exact proposal-parent tree. It reports those paths and
canonical target collisions. It does not parse arbitrary documents, infer
meaning, or claim completeness for unknown protocol layouts. If semantic work
discovers an additional authority or needs a deletion outside the approved
surface, adoption blocks for a new maintainer assessment.

The immutable capabilities contract module is the sole pure-policy authority
for the known-surface predicate, policy casing, inventory, strategy state
machine, and migration/CleanStart authority predicates. The single-file
launcher loads that exact module read-only before repository or GitHub adoption
mutation, and the workflow adapter imports the same pinned module. Those actors
keep independent evidence and mutation-boundary checks because they operate at
different trust boundaries; they do not carry or cross-check competing policy
implementations.

The reserved `.ai/protocol` path, its descendants, and
`.ai/meandai-update-state.json` are always protocol evidence. Evidence
classification is separate from mutation authority: known instruction, rule,
memory, legacy `ai/` governance, GitHub path-specific instruction records below
`.github/instructions/`, `docs/governance/`, `docs/agent-prompts/`, and reserved
protocol-tree records are migration-safe surfaces, while ambiguous
product/release documents and existing feature, decision, finding, or idea
records are evidence-only. Full and hybrid modes may preserve those ambiguous
records unchanged; clean start blocks before mutation rather than assuming
they are disposable governance. Managed target and ancestor casing must be
exact.

New adoption manifests and ownership markers bind the resolved strategy and
exact detected surfaces alongside the existing repository, target, protocol,
base, branch, actor, and head evidence. The project-owned adoption issue and
agent prompt state the same choice. A rerun with a different choice or changed
surface set does not retarget an existing proposal silently.

The initial seed's default-branch push and later scheduled events do not create
an unselected initial migration proposal. The launcher or an explicit manual
dispatch owns initial strategy authorization. Already completed consumers keep
the existing update and finalization routes; a strategy file is not persisted
and no consumer migration entry is required merely for this decision.

Completion publication uses one status-aware path envelope in normal and
recovery routes. Required adoption targets must exist with canonical modes;
consumer-authored additions are limited to scoped `AGENTS.md`, declared
governance/memory Markdown roots, and `tests/meandai-adoption/`. Existing
application, product-documentation, product-test, asset, and runtime paths are
not writable under any strategy.

An unborn or non-Git target can enter new-repository adoption only when its
working tree contains the fixed local credential files and the exact canonical
seed workflow. Other project files must first be committed. Every launcher,
workflow, and recovery commit is checked again from the committed tree and a
clean index/worktree before publication, so a hook or concurrent index change
cannot expand the authorized proposal.

The exact canonical consumer repository identity, live default-branch name,
and base commit are revalidated before completion publication and again before
readiness. A concurrent rename or advance blocks instead of silently changing
the maintainer-authorized migration input.

### Ownership and final state

`.ai/protocol` remains the immutable common authority. Repository-specific
rules are rehomed to consumer-owned root/scoped instructions, local memory,
features, decisions, findings, and tests. Full migration and hybrid work create
the consumer records necessary to explain preservation and precedence. The
transient assessment is removed with the manifest; no permanent compatibility
register or second common protocol is introduced.

## Consequences

- Maintainers make the only policy choice that can intentionally preserve,
  combine, or discard prior governance semantics.
- Empty and protocol-free repositories retain a one-command fresh path.
- Existing-protocol repositories stop safely in non-interactive automation
  unless an explicit strategy is provided.
- Clean-final-tree and semantic-normalization outcomes are both representable
  as `FullMigration` without forcing either policy on every consumer.
- Hybrid adoption is possible but must end with explicit authority precedence.
- Clean start is deliberately harder to invoke because its information loss is
  irreversible in the current tree.
- The detector stays bounded and inspectable; unknown layouts cause a reported
  re-plan instead of a larger autonomous bootstrapper.

## Alternatives considered

- Always perform full migration: rejected because preservation policy belongs
  to the maintainer and some repositories intentionally want a clean start.
- Always merge protocols: rejected because it creates dual authority and
  retains unwanted legacy topology.
- Always overwrite canonical files: rejected because it loses project-specific
  directives and contradicts collision safety.
- Let the AI infer the best strategy: rejected because it delegates an
  irreversible governance decision and makes reruns non-deterministic.
- Persist a universal compatibility ledger: rejected because it expands
  consumer state and preserves legacy structure after semantics are reconciled.
- Build a universal protocol parser: rejected because a small declared
  inventory plus maintainer choice provides the needed gate without recursive
  semantic validation.

## Review condition

Review if the declared path inventory repeatedly misses real protocol
authorities, if a strategy cannot be represented without product-content
mutation, if GitHub adds an immutable typed workflow-input primitive spanning
push and dispatch, or if consumer evidence shows that transient strategy
binding is insufficient for safe reruns.
