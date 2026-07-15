# IDEA-0001 - Role-Based Multi-Agent Protocol

Status: **Parked**
Created: **2026-07-15**
Promoted record: **None**

This idea does not authorize implementation and does not satisfy Definition of
Ready.

## Observation

Complex feature delivery can benefit from separating analysis, implementation,
review, and test responsibilities. A single long-running agent may accumulate
noisy context or review its own assumptions without sufficient independence.

## Possibility

Define optional project-scoped analyst, developer, reviewer, and tester agents,
with the main agent acting as a bounded orchestrator. Read-heavy roles would be
isolated from write authority, only one developer would own a slice, and
reviewer/tester evidence would return to the main delivery gate.

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

Promote only after an explicit maintainer request defines which project sizes or
risks require multi-agent delivery, role authority, concurrency limits, evidence
handoffs, and a bounded validation budget. The resulting feature must remain
optional for small work and prohibit recursive delegation by default.

## Outcome

Parked for later evaluation. No feature, decision, agent configuration, or
protocol behavior is authorized by this record.
