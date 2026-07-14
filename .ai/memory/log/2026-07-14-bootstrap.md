# 2026-07-14 - Protocol Bootstrap

## Context

The maintainer requested a common protocol reusable through a Git submodule or
pinned repository reference. Every consuming project's AI memory must remain
independent. The protocol must enforce deliberate design, decomposition,
self-review, full-project scans, test documentation and code, GitHub tracking,
clickable references, and `M.m.rev` versioning without becoming a large
bootstrap framework.

## Durable outcomes

- The common rules are centralized in [PROTOCOL.md](../../../PROTOCOL.md).
- Portable consumption is defined by
  [DEC-0001](../../../docs/decisions/DEC-0001-portable-protocol-reference.md).
- Memory isolation is defined by
  [DEC-0002](../../../docs/decisions/DEC-0002-project-local-memory.md).
- Initial delivery is tracked by
  [FEAT-0001](../../../docs/features/FEAT-0001-common-development-protocol/README.md),
  [issue #1](https://github.com/hasanmanzak/meAndAI/issues/1), and
  [pull request #2](https://github.com/hasanmanzak/meAndAI/pull/2).
- The target release is `v0.1.0`.

## Continuation

Before modifying the protocol, load the files above, inspect the current GitHub
issue and pull request state, and apply the protocol's Definition of Ready and
Definition of Done. Do not import facts from consuming projects into this
memory.
