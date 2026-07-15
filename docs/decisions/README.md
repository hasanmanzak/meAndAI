# Decision Index

| ID | Decision | Status | Date |
| --- | --- | --- | --- |
| [DEC-0001](DEC-0001-portable-protocol-reference.md) | Use a pinned protocol reference with a project adapter | Accepted | 2026-07-14 |
| [DEC-0002](DEC-0002-project-local-memory.md) | Keep AI memory local to each consuming project | Accepted | 2026-07-14 |
| [DEC-0003](DEC-0003-reviewed-consumer-update-supersession.md) | Use review-only updates with replacement-first supersession | Accepted | 2026-07-14 |
| [DEC-0004](DEC-0004-bounded-completion-convergence.md) | Require bounded post-development convergence | Accepted | 2026-07-14 |
| [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md) | Use a consumer-scoped fine-grained PAT for updater mutations | Accepted | 2026-07-15 |
| [DEC-0006](DEC-0006-seed-workflow-adoption-handoff.md) | Use a seed workflow with collision-aware adoption handoff | Accepted | 2026-07-15 |

Create future records from the
[decision template](../../templates/decision.md). A newer decision does not edit
history silently. When it replaces an earlier decision, it links that record and
explicitly declares `Supersedes`; otherwise it records the earlier decision as
related context.
