# Project-local AI Memory

Scope: **replace with project name**<br>
Last reviewed: **YYYY-MM-DD**

This memory belongs only to this consuming project. Read
[project.md](project.md), then the newest relevant record in
[log](log/README.md).

The common-protocol authority is the integration recorded in the
[project snapshot](project.md).
For the recommended submodule, resolve the current commit from the repository's
`.ai/protocol` gitlink and its version from `.ai/protocol/VERSION`. Do not copy
either value into memory as a separately maintained live fact. A
repository-reference consumer resolves the same identity from its configured
immutable-ref authority.

## Rules

- Store verified durable facts, explicit collaboration constraints, and concise
  dated handoffs.
- Link to canonical project features, decisions, issues, pull requests, tests,
  and evidence.
- Mark assumptions and stale facts.
- Keep exact protocol tags and commits only in dated historical event records,
  never as the current pin authority.
- Never store secrets, raw chat, or unrelated project details.
