# DEC-0028 - Fix Reusable Consumer Failures at Their Common Upstream Authority

- Classification: Decision
- Status: Accepted
- Date: 2026-07-23
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0045](../features/FEAT-0045-v0140-canonical-repository-evidence/README.md)
- Related decisions: [DEC-0018](DEC-0018-release-declared-consumer-migrations.md), [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0024](DEC-0024-exact-instruction-graph-adoption-evidence.md)
- Supersedes: none

## Context

A reusable protocol defect may first become visible in one consumer. Correcting
the algorithm inside that named consumer duplicates common behavior, leaves
other consumers exposed, and can be mistaken for completion even though the
upstream authority remains defective. Conversely, common automation does not
own semantic consumer files and cannot silently rewrite them.

Checkout filters expose this boundary sharply: a Git-clean worktree file can
have different bytes from its committed blob. A validator that reads the
worktree as committed evidence can reject canonical state, while normalizing
the bytes would hide genuine drift.

## Decision

Classify the owning layer before implementing a correction. Reusable protocol
contracts, algorithms, automation, templates, capabilities, and adoption rules
are corrected in meAndAI with project-neutral regression evidence and an
immutable release. A consumer-only patch cannot close the common defect.

meAndAI provides one bounded repository-evidence reader. Clean tracked state is
read from the exact verified `HEAD` regular blob, staged-only state from the
stage-zero index blob, and unstaged or untracked state from the contained
ordinary worktree file. Ambiguous state fails closed and bytes are never
normalized.

Because existing capability definitions are immutable, this reusable rule is
introduced as a new append-only Semantic capability. Existing consumers review
only the new catalog suffix. Automation may open that review but does not edit,
approve, mark ready, or merge semantic consumer paths.

Protocol-provided reusable assets are single-owned by meAndAI. Consumers must
not reproduce their implementation or generic regression evidence through a
copy, port, rename, shadow implementation, fork, or consumer-local equivalent.
A consumer may own only a project-specific adapter, configuration, domain
behavior, or semantic assessment that cannot be expressed by the common asset.
If the shared asset is missing or insufficient, its correction and generic
regression close in meAndAI and ship in an immutable release before any linked
consumer recovery begins.

One exact release-declared managed projection may reside at its canonical
consumer path only when the execution platform requires a resident hook, such
as the consumer GitHub Actions workflow. It MUST have one
immutable-release-declared source path, canonical consumer target path, exact
content digest or Git blob, and lifecycle; it MUST be installed and updated
only by deterministic protocol automation; and it remains owned by meAndAI.
This exception does not permit consumer-local tests, fixtures, validators, or
shadow implementations.

## Consequences

- One common fix and anonymous regression protect future implementations.
- Existing consumers receive a reviewable capability suffix instead of a
  silent rewrite or a copied consumer-specific algorithm.
- Consumer recovery remains a separate linked operation after the upstream
  release and may adapt only genuinely project-specific structure.
- Common code, fixtures, and normative records do not embed a named consumer's
  repository, paths, domain facts, commits, or tests.
- Protocol-provided tests and fixtures remain upstream evidence; consumers
  reference them and add only tests for genuinely project-specific behavior.
- This decision grants no authority to inspect or mutate unrelated consumers.

## Alternatives considered

- Keep a consumer-local Git reader: rejected because it duplicates reusable
  protocol behavior and leaves every other consumer exposed.
- Add `.gitattributes`: rejected because attributes do not establish the
  correct authority for clean, staged, unstaged, and conflicted state.
- Normalize CRLF to LF before parsing: rejected because it hides real byte
  drift and weakens the strict evidence contract.
- Rewrite the released `test-architecture` definition: rejected because the
  capability catalog is append-only and definitions are immutable.

## Review condition

Review if Git exposes one cross-platform API that returns exact HEAD, index,
and worktree candidate bytes with equivalent ambiguity and containment guards,
or if capability definitions become safely versionable without rewriting an
immutable catalog prefix.
