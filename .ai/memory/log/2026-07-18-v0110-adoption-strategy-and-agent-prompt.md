# 2026-07-18 - v0.11.0 Adoption Strategy and Optional Agent Prompt

## Scope

- [FEAT-0029](../../../docs/features/FEAT-0029-v0110-protocol-aware-initial-adoption/README.md)
  adds a maintainer-owned strategy gate for initial adoption.
- [DEC-0021](../../../docs/decisions/DEC-0021-explicit-initial-adoption-strategy.md)
  defines fresh, full-migration, hybrid, clean-start, abort, inventory, and
  authority semantics.
- [FEAT-0030](../../../docs/features/FEAT-0030-v0110-stability-cycle-agent-prompt/README.md)
  publishes a non-normative prompt that maintainers may copy or reference for
  one bounded stability cycle without activating a task or goal.

## Durable implementation facts

- The quick launcher authenticates read-only, verifies the immutable v0.11.0
  capabilities contract module, and then assesses exact committed paths before
  any repository or GitHub adoption mutation. `Auto` selects only
  evidence-free `FreshAdoption`; evidence-bearing non-interactive runs require
  an explicit strategy.
- That exact module is the single pure-policy authority for the launcher and
  workflow adapter. Actor-specific Git/GitHub evidence and mutation-boundary
  checks remain independent, but copied classifiers and classifier-to-
  classifier validation are prohibited.
- The bounded classifier recognizes a declared protocol/governance surface and
  stops above 256 exact paths or 16 KiB of UTF-8 path inventory. It does not
  parse documents or infer migration semantics. Reserved `.ai/protocol`
  roots, exact active-rule roots, and `.ai/meandai-update-state.json` are
  migration evidence; ambiguous product/governance records remain read-only.
- GitHub path-specific Copilot instructions below `.github/instructions/` are
  included in the declared active-rule inventory and migration authority
  boundary; they cannot be left as an unnoticed parallel instruction source.
- New initial proposals bind strategy, exact sorted surfaces, and clean-start
  loss acknowledgement in manifest schema 2 and proposal marker schemas 5/6.
  Issue, prompt, rerun, and completion validation preserve the same tuple.
- Seed-push and scheduled events do not create an unselected initial migration
  proposal. Completed consumers retain their existing current/update route.
- Local semantic completion may delete only the transient manifest and exact
  assessed governance paths authorized by a migration strategy. One shared
  normal/recovery completion envelope rejects unauthorized application or
  product addition, modification, type change, and deletion.
- Seed, workflow proposal, local completion, and updater commits are validated
  again from committed Git trees before publication. Live repository/default
  branch identity, exact casing, reserved submodule ownership, clean
  index/worktree state, and lease-bounded race compensation fail closed.
- Empty-remote routing means zero advertised refs, including tags. The
  launcher rechecks that boundary before external mutation and seed
  publication; post-first-push drift permits compensation only for the exact
  launcher-owned default ref.
- Credential inputs are exact root regular non-link files and are revalidated
  at read time. The launcher appends one process-only empty `core.hooksPath`
  override and restores the previous Git configuration environment in its
  outer `finally`, so launcher-owned Git operations cannot execute consumer or
  global hooks while token files are present.
- The canonical stability-cycle prompt lives at
  `docs/agent-prompts/stability-and-consistency-cycle.md`. It is single-run,
  report-only by default, and cannot create or schedule its next invocation.
  Report-only may establish local convergence but leaves the normative cycle
  incomplete and `Blocked` until authorized final-push authority exists.

## Evidence and continuation

- `TEST-0127` and `TEST-0128` pass their resolver and adapter owners, including
  the 466.6-second full adapter suite after the single-policy refactor.
- `TEST-0129` and `TEST-0130` pass five focused launcher shards and the combined
  `-Shard All` harness in 1107 seconds, including cross-shard fixture isolation.
- `TEST-0131` and `TEST-0132` pass the final 2.5-second structure-only protocol
  suite after local convergence was separated from authorized full completion.
- The complete repository suite passes in 1576 seconds with every discovered
  suite and canonical scenario owner green before that documentation-and-
  assertion-only clarification. Fresh-diff review and bounded post-development
  confirmation report no unresolved `Blocking` finding.
- [Issue #76](https://github.com/hasanmanzak/meAndAI/issues/76) and
  [issue #77](https://github.com/hasanmanzak/meAndAI/issues/77) own delivery and
  post-publication facts. Pull request, hosted checks, merge, branch cleanup,
  immutable release, asset, and post-publication verification remain pending
  until they exist.
