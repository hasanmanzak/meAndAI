# DEC-0025 - Allow Exact-Head Personal-Owner Attestation as a Review Fallback

- Classification: Decision
- Status: Accepted
- Date: 2026-07-23
- Decision owners: meAndAI maintainers and consumer repository owners
- Related feature: [FEAT-0041](../features/FEAT-0041-v0132-exact-head-owner-attestation/README.md)
- Related decisions: [DEC-0016](DEC-0016-managed-post-merge-finalization.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), and [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md)

## Context

Semantic capability completion must carry durable reviewed evidence. GitHub
prevents a pull-request creator from approving their own pull request, so the
existing exact-head `APPROVED` requirement cannot be satisfied in a personal
repository maintained only by its owner. Treating Ready or merge as review
would erase the semantic gate, while requiring an artificial second account
would not add meaningful review authority.

## Decision

Independent exact-head approval and every existing review-state rejection
remain unchanged. If any review submission exists, the finalizer must resolve
or reject that collection exactly as before and must not read owner-attestation
comments. Only when the pull request's complete review collection is empty may
the finalizer read its complete bounded issue-comment collection and accept one
canonical personal-owner attestation.

The attestation is one byte-exact single-line ASCII body whose marker binds the
lowercase repository identity, pull-request number, and lowercase 40-character
review head. Its author must be the same actor by ID and case-insensitive login
as the pull-request creator and the repository owner. The repository owner type
must be exactly `User`, and the collaborator-permission response must resolve
the same actor with permission exactly `admin`. Duplicate or conflicting
trusted attestation evidence fails closed.

The comment may be created before merge or after a failed merge finalization.
It authorizes only the existing reviewed-tree finalizer; it does not create,
ready, approve, or merge a pull request and does not bypass catalog, ledger,
manifest, commit-chain, merge-containment, branch, issue, or cleanup checks.
Ready, merge, commit authorship, ordinary comments, workflow actors, personal
repository collaborators, and organization owners are not equivalent.

## Consequences

- A personal repository owner has a deliberate, durable recovery path without
  a second GitHub identity.
- Independent and rejected review semantics and their lower API cost remain
  unchanged; a stale or adverse review cannot be bypassed with a comment.
- Self-attestation is intentionally narrower than general collaborator review
  and unavailable for organization repositories.
- Failed historical merges can converge by adding exact evidence and using the
  existing idempotent recovery dispatch; no polling or new workflow is needed.
- The fallback adds one bounded comments read and one existing collaborator-
  permission read only when independent approval cannot authorize finalization.

## Alternatives considered

- Treat Ready or merge as approval: rejected because neither proves semantic
  review of the exact head.
- Accept any write collaborator's self-comment: rejected because it broadens
  self-approval beyond the repository's personal owner.
- Require a second maintainer account: rejected because it is impossible or
  artificial for legitimate solo-owned repositories.
- List all collaborators to prove there is exactly one: rejected because it
  adds administration-scope and membership-enumeration dependencies while the
  personal-owner boundary is both narrower and already available.
- Add a GitHub App or separate finalizer: rejected as disproportionate and a
  duplicate authority surface.

## Review condition

Review if GitHub supports self-review with exact-head evidence, if organization
repositories need an equivalent single-maintainer policy, if repository-owner
identity is removed from the repository API, or if the fallback is shown to
weaken a protected-branch or required-review control.
