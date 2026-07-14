# Decision Index

| ID | Decision | Status | Date |
| --- | --- | --- | --- |
| [DEC-0001](DEC-0001-portable-protocol-reference.md) | Use a pinned protocol reference with a project adapter | Accepted | 2026-07-14 |
| [DEC-0002](DEC-0002-project-local-memory.md) | Keep AI memory local to each consuming project | Accepted | 2026-07-14 |
| [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md) | Use review-only updates with replacement-first supersession | Accepted | 2026-07-14 |

Create future records from the
[decision template](../../templates/decision.md). A newer decision does not edit
history silently. When it replaces an earlier decision, it links that record and
explicitly declares `Supersedes`; otherwise it records the earlier decision as
related context.
