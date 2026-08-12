# IDEA-0001 - Role-Based Multi-Agent Protocol

Status: **Promoted**
Created: **2026-07-15**
Promoted record: **[EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179)**

Promotion creates durable planning authority; it does not authorize
implementation or satisfy Definition of Ready.

## Observation

Complex feature delivery can benefit from separating analysis, implementation,
review, and test responsibilities. A single long-running agent may accumulate
noisy context or review its own assumptions without sufficient independence.

## Possibility

Define optional project-scoped analyst, developer, reviewer, tester,
documenter, and delivery roles, with the main agent acting as a bounded
orchestrator. Extensible commands such as `/develop`, `/review`, and
`/document` would be thin aliases for reusable Workflow Contracts. Read-heavy
roles would be isolated from write authority, only one writer would own a
slice, canonical directives would be referenced rather than copied, and all
evidence would return to the existing SDLC gate assessment.

## Potential value

- Cleaner separation between requirements, code authorship, review, and tests.
- Less context pollution in the main task.
- Parallel read-heavy review where it materially reduces elapsed time.
- Reusable role definitions for consumer repositories.

## Concerns

- Token, latency, and coordination cost can exceed the value for small work.
- Parallel writers can conflict or duplicate changes.
- Recursive delegation can create unbounded review and bootstrap behavior.
- Fixed roles may become ceremony unless activation rules are narrow.

## Promotion condition

Satisfied on 2026-08-12 by the maintainer's explicit records directive. The
promoted [architecture](../architecture/agentic-sdlc-workflows/README.md),
proposed [DEC-0038](../decisions/DEC-0038-protocol-owned-workflow-contracts-and-bounded-agent-execution.md),
[FEAT-0057](../features/FEAT-0057-explicit-sdlc-backlog-governance/README.md),
and [FEAT-0070](../features/FEAT-0070-agentic-sdlc-workflow-capabilities/README.md)
define optional activation, role/grant separation, first-release concurrency,
exact handoffs, recursive-delegation denial, evidence, and open Definition of
Ready gaps.

## Outcome

Promoted to [EPIC-0003 / issue #179](https://github.com/hasanmanzak/meAndAI/issues/179)
for records-only architecture and future gated delivery. The two linked
features and proposed decisions preserve accepted conclusions, open choices,
risks, planned scenarios, and successor slices. No agent configuration,
protocol behavior, production/test implementation, consumer change, merge,
release, or authority transfer is authorized by this promotion.
