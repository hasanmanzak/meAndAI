# DEC-0038 - Use Protocol-Owned Workflow Contracts and Bounded Agent Execution

- Classification: Decision
- Status: Proposed; implementation authority withheld
- Date: 2026-08-12
- Decision owners: meAndAI maintainers
- Related feature: [FEAT-0070](../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
- Related decisions: [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), [DEC-0029](DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md), and proposed [DEC-0037](DEC-0037-explicit-sdlc-and-github-native-workflow-authority.md)
- Originating idea: [IDEA-0001](../ideas/IDEA-0001-role-based-multi-agent-protocol.md)
- Tracking: [Issue #180](https://github.com/hasanmanzak/meAndAI/issues/180)

## Context

The maintainer wants extensible requests such as `/develop`, `/review`, and
`/document`, plus other future commands, to select reusable delivery behavior,
engineering directives, specialist roles, and bounded multi-agent execution.
The same model must include the existing SDLC without copying DDD, Rich Entity
Model, TDD, SOLID, documentation-link, recurrence, review, or release rules
into every command.

[DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md)
already makes the executable protocol the product authority and treats CLI,
workflow, action, and agent surfaces as thin hosts. A new agent layer therefore
cannot become a second policy catalog, grant authority, lifecycle, or consumer
implementation.

The [DRN workflow operating model](https://github.com/duranserkan/DRN-Project/blob/0f74ade879c2285a2a4ac19350edd95015dd03fd/.agent/workflows/_shared/workflow-operating-model.md),
[status lifecycle](https://github.com/duranserkan/DRN-Project/blob/0f74ade879c2285a2a4ac19350edd95015dd03fd/.agent/workflows/_shared/status-lifecycle.md),
[goal router](https://github.com/duranserkan/DRN-Project/blob/0f74ade879c2285a2a4ac19350edd95015dd03fd/.agent/workflows/goal.md),
[development workflow](https://github.com/duranserkan/DRN-Project/blob/0f74ade879c2285a2a4ac19350edd95015dd03fd/.agent/workflows/develop.md),
and [skill index](https://github.com/duranserkan/DRN-Project/blob/0f74ade879c2285a2a4ac19350edd95015dd03fd/.agent/skills/overview-skill-index/SKILL.md)
demonstrate useful routing, workflow ownership, focused skill loading, explicit
handoff state, and bounded subagent guidance. They also demonstrate costs that
meAndAI should not copy as protocol defaults: mandatory artifact chains, long
persona prompts, routine approval envelopes, repeated rules, and per-command
state machines.

## Decision

1. A command is an alias in a thin adapter. A **Workflow Contract** is the
   canonical behavior contract. An **Execution Role Contract** bounds
   responsibility. An **actor** is the temporary agent, tool, or host assigned
   to a role. A **grant** is separate authority under [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md).
2. Commands are open-ended and many-to-many with workflows. `/develop`,
   `/review`, `/document`, `/test`, `/clarify`, `/goal`, `/update`, and natural
   language are examples, not a closed protocol vocabulary.
3. Each Workflow Contract declares identity, class, admitted SDLC evidence,
   input and output schema, side effects, required grants, canonical rule and
   practice references, eligible roles, context recipe, handoff schema,
   concurrency, stop, recovery, idempotence, validation-budget, and alias
   bindings.
4. Workflow families are `Support`, `DiscoveryPlanning`, `Production`,
   `Assurance`, `Records`, `Delivery`, `ProtocolLifecycle`, and
   `Orchestration`. A family does not itself grant behavior or authority.
5. Normative rules remain in the protocol, accepted decisions, and their future
   canonical rule catalog. A workflow selects references; it does not copy
   their text. Project overlays remain in repository instructions, project
   memory, and numbered project decisions. Skills are operational techniques,
   not normative acceptance or grant authority.
6. DDD, Rich Entity Model, TDD, SOLID, and documentation-graph rules are
   selected by applicability. Domain development selects domain practices;
   documentation-only work does not pretend to apply entity modeling.
   Documentation rules apply to every workflow that emits records, not only a
   `/document` alias.
7. The existing Gate 0 through Gate 7 lifecycle is canonical. A workflow-run
   lifecycle is separately modeled as `Requested`, `Resolved`, `Admitted`,
   `Assigned`, `Running`, `Assessed`, then `Completed`, `Blocked`, or
   `NeedsDecision`. Completion of a run never advances a gate without the
   required canonical evidence.
8. The Context and Handoff Router binds exact base, stable work, current gate,
   include/exclude scope, writable paths, role assignment, real authority,
   canonical rule references, project overlays, applicable recurrence safe
   responses and unsafe retry boundaries, dependencies, acceptance and tests,
   validation budget, output contract, expiry, and stop conditions. A summary
   cannot replace the delegated actor's required instruction and recurrence
   reads.
9. Single-agent execution is the default. Multi-agent execution activates only
   for independent reviewable slices, an independent read-only assurance lane,
   or a materially separable evidence inventory.
10. The proposed first topology is at most one orchestrator and two workers,
    one writer per slice, no parallel writers in the first release, and no
    worker-to-worker or recursive delegation. Read-heavy analysis, review, and
    verification may run in parallel when scopes are disjoint.
11. Missing readiness, ambiguous recurrence, stale base, overlapping write
    scope, missing owner, missing validation budget, or absent mutation/provider
    authority disables multi-agent dispatch and fails closed where necessary.
12. Reviewers report evidence and findings but cannot approve their own output
    or advance a gate without the required maintainer or protocol authority.
    Orchestrators route and assess but inherit no repository, provider, merge,
    release, or authority-transfer grant.
13. Released reusable workflow and role definitions remain protocol-owned and
    pinned. Consumers do not copy or shadow them; project-specific integration,
    configuration, domain behavior, and evidence remain consumer-owned.
14. This decision proposes architecture and future delivery only. It does not
    authorize executable catalogs, agent prompts, protocol amendments, tests,
    workflows, consumer projections, provider effects, merge, or release.

## Consequences

- New commands can be added without duplicating rules or inventing new agent
  personas as governance authorities.
- Development, review, testing, and documentation share the same selected
  practices and evidence vocabulary.
- Multi-agent work is optional and cost-bounded; small work stays simple.
- Exact context and return envelopes improve auditability but add schema and
  stale-state handling that must be proven before mutation.
- Real grants remain explicit and non-transitive, so a role name cannot grant
  provider or release access.
- The terms `Workflow Contract Catalog` and `Execution Role Contract Catalog`
  avoid collision with the existing semantic capability and policy catalogs.

## Alternatives considered

- Put all rules in each slash command: rejected because it duplicates
  normative authority and drifts between development, review, and tests.
- Give named agents standing permissions: rejected because role assignment is
  not a grant and candidate-controlled personas cannot authorize mutation.
- Always use a fixed multi-agent chain: rejected because transfer cost and
  ceremony exceed value for small work.
- Allow recursive delegation: rejected because it creates unbounded cost,
  unclear ownership, and recursive bootstrap behavior.
- Treat a handoff summary as sufficient context: rejected because it can omit
  repository instructions, recurrence routing, exact base, or authority.
- Copy DRN's complete workflow stack: rejected because meAndAI already owns a
  different canonical gate and authority model; only bounded routing patterns
  are transferable.

## Review condition

Review before accepting [FEAT-0070](../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md), when [DEC-0035](DEC-0035-protocol-owned-governance-and-execution-architecture.md) changes its host or grant boundaries, or when pilot evidence shows the proposed activation, concurrency, context, or non-recursive topology is insufficient.
