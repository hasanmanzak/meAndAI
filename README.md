# meAndAI

`meAndAI` is a compact, versioned development protocol for human-AI software
delivery. A project can pin this repository as a Git submodule or repository
reference while keeping its own context and AI memory inside that project.

Current protocol version: **0.15.4**

Immutable [v0.15.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.3)
is the prior published release at
[`164543d939ef97ec02d96499d3e5b796eed64470`](https://github.com/hasanmanzak/meAndAI/commit/164543d939ef97ec02d96499d3e5b796eed64470).
[PR #136](https://github.com/hasanmanzak/meAndAI/pull/136) and closed
[issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) retain the
[FEAT-0054](docs/features/FEAT-0054-v0153-bounded-quick-adoption-runtime/README.md)
delivery and publication evidence. The `v0.15.4` UTF-8 workflow-dispatch
correction is tracked by
[FEAT-0055](docs/features/FEAT-0055-v0154-utf8-workflow-dispatch/README.md) and
[BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137) /
[issue #137](https://github.com/hasanmanzak/meAndAI/issues/137).

## Start here

- Read the [common protocol](PROTOCOL.md).
- Follow the [adoption guide](docs/adoption.md) in a consuming repository.
- Use [quick adoption](docs/quick-adoption.md) for the one-command thin
  launcher backed by one verified immutable module bundle.
- Browse the [optional agent prompts](docs/agent-prompts/README.md) for
  maintainer-invoked, non-activating aids.
- Browse the [feature index](docs/features/README.md) and
  [decision index](docs/decisions/README.md).
- Browse incubating possibilities in the [idea index](docs/ideas/README.md).
- Read this repository's isolated [project memory](.ai/memory/README.md).
- See the [changelog](CHANGELOG.md) for version history.

## Design boundary

The common protocol owns delivery rules, quality gates, identifiers, and
templates. Each consuming project owns its domain decisions, feature records,
test evidence, and AI memory. Those project-specific records must not be stored
inside the protocol submodule.

Compatible releases may declare deterministic consumer-state transitions in
the immutable, append-only [migration catalog](migrations/index.json). The
consumer's `.ai/meandai-update-state.json` ledger records satisfied definition
blobs without becoming another protocol pin. An updater that already supports
the catalog includes required migrations in the ordinary reviewed update draft;
an older immutable updater first installs the capability, after which the new
workflow automatically opens one same-target reconciliation draft. Both paths
fail closed for customized, partial, or otherwise ambiguous state and still
leave the final merge to the consumer maintainer.

Releases may also declare repository practices through the immutable
[capability catalog](capabilities/index.json). Consumers record reviewed
terminal evidence in `.ai/meandai-capabilities-state.json`; open semantic work
is handed off through one separately reviewed proposal and never becomes
deterministic updater ownership. The first definition,
[`test-architecture`](capabilities/test-architecture.json), keeps tests
physically capability-oriented while preserving feature-owned `TEST-NNNN`
traceability. The append-only
[`test-runtime-efficiency`](capabilities/test-runtime-efficiency.json)
definition requires reuse-first deterministic setup, isolated mutable
derivatives, machine-readable resource evidence, and reviewed operation-budget
deltas without turning elapsed time into a correctness gate.
The appended
[`canonical-repository-evidence`](capabilities/canonical-repository-evidence.json)
definition binds byte-sensitive clean, staged, and worktree evidence to their
exact Git authorities without normalization, and keeps reusable corrections in
the common upstream protocol while semantic consumer changes remain reviewed.
The appended
[`test-harness-modularity`](capabilities/test-harness-modularity.json)
definition requires recurrence and sibling-owner routing, one owner for generic
test mechanics, explicit result contexts, exact executable Case evidence, and
non-overlapping runner, harness, case, support, fixture, and mock roles without
creating a second test framework.

The protocol's stability and consistency mandate starts one bounded project
scan after material development, resolves dependency-ready blocking findings
with per-finding self-review, pushes only after local convergence, and then
waits for the next development event. That converged push is distinct from a
protocol-version tag or GitHub Release.

Quick adoption keeps one maintainer-downloaded PowerShell entry point while
the release contains exactly two release assets: that reviewed thin launcher
and one deterministic module bundle. The launcher verifies its own immutable
runtime release, bundle and payload identities outside the consumer before
import; its runtime release is independent of the protocol release requested
for the consumer.

The canonical [feature index](docs/features/README.md),
[decision index](docs/decisions/README.md), and [changelog](CHANGELOG.md) own
the detailed work and release history. The overview deliberately does not
duplicate that changing inventory.

The repository is publicly readable. An environment using authenticated GitHub
operations must still provide credentials appropriate to those operations.
