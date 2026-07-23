# DEC-0003 - Use Review-Only Consumer Updates with Replacement-First Supersession

- Classification: Decision
- Status: Accepted
- Date: 2026-07-14
- Decision owners: Repository maintainers
- Related feature:
  [FEAT-0002](../features/FEAT-0002-semi-automatic-consumer-updates/README.md)
- Related decisions:
  [DEC-0001](DEC-0001-portable-protocol-reference.md),
  [DEC-0002](DEC-0002-project-local-memory.md), and
  [DEC-0005](DEC-0005-consumer-scoped-fine-grained-pat.md), which supersedes
  only the mutation credential, managed-path, and copied-updater clauses
- Operational guide: [Adoption and recovery](../adoption.md)

## Context

Immutable protocol pins prevent silent drift but require maintainers to notice
new releases. A scheduled check may find a second compatible release while an
older upgrade PR is still open. Closing the older work before a valid
replacement exists creates a gap; deleting a changed branch can lose work.

GitHub PR metadata, marker text, and a branch name are individually insufficient
proof of ownership. State may change between planning and mutation, API lists
may paginate, a branch can disappear or move, and a process can be interrupted
after pushing a branch. The updater also cannot exist retroactively in immutable
`v0.1.0`, and a consumer token cannot read a different private repository.

## Decision

Submodule consumers adopting `v0.2.0` or later install a consumer-resident,
protocol-owned scheduled/manual workflow projection from the pinned protocol
templates. The workflow:

1. verifies that `.ai/protocol` is the configured protocol submodule and that
   its gitlink resolves to exactly one canonical lowercase `vM.m.rev` tag;
2. paginates open PR inventory and selects the highest numeric same-major tag;
3. opens a version-targeted draft PR and never approves or merges it; and
4. uses one pure candidate validator for both the planning snapshot and every
   live pre-mutation check.


The pointer-only draft is the protocol's narrow pre-DoR discovery exception. It
is not implementation authorization and cannot be marked ready or merged until
the consumer assigns a stable work ID, links an issue, reviews impact, defines
tests, and satisfies its remaining Definition of Ready. The updater receives no
general authority to author product or domain changes.
A managed proposal must have exactly one case-sensitive ownership marker. The
marker binds schema, consumer repository, target tag, protocol commit, and
initial head SHA. Validation also binds the trusted actor, same-repository head,
default base, draft state, API head, live remote ref, `160000` protocol gitlink,
and the single changed path. Ambiguity blocks mutation.

Supersession is replacement-first and compensated, not a distributed
transaction. The workflow creates and fully verifies the newer proposal before
cleanup. Immediately before each old cleanup, it revalidates both the old and
replacement proposals. It then closes the old PR and deletes the exact expected
branch head with a Git lease. If deletion fails or the ref disappears, it tries
to reopen the old PR and reports manual recovery when compensation cannot
restore the prior review state. It never intentionally deletes a changed or
ambiguously owned branch.

Branch creation uses an expected-absent lease. An interruption after the push
but before PR creation can still leave an orphan reserved branch; the next run
fails closed. Maintainers use the lease-safe
[interrupted-run recovery procedure](../adoption.md#interrupted-run-recovery)
instead of force-resetting or guessing ownership.

The consumer `GITHUB_TOKEN` receives explicit write permissions only for the
consumer. A separate least-privilege secret reads private `meAndAI` content.
Consumers that need identity separation from other write workflows may use a
dedicated GitHub App through a project decision.

The `v0.2.0` updater requirement is prospective: it governs consumers that
adopt or upgrade to that release and does not invalidate a correctly pinned
`v0.1.0` consumer. A control that forced already-conforming earlier consumers
to migrate would require a major version increment.

Repository-reference consumers need a deterministic provider-specific writable
adapter or a documented manual gate. A generic adapter cannot safely mutate an
opaque provider configuration.

## Consequences

- Compatible releases are discovered eventually and remain review-gated.
- A successful reconciliation leaves at most one unambiguous managed update PR.
- Replacement verification failure preserves the older proposal.
- Cleanup is fail-safe and compensated, but cannot promise atomicity across Git
  refs, PR state, process cancellation, and network failures.
- Human changes, case drift, duplicate markers, missing refs, and origin mismatch
  stop automation instead of being guessed, rebased, or deleted.
- Major migrations, copied-template reconciliation, memory updates, consumer
  tests, and final merge remain maintainer responsibilities.
- Private consumers need a read credential and repository permission for
  GitHub Actions to create pull requests.

## Alternatives considered

- Follow moving `main`: rejected because it destroys reproducibility.
- Auto-merge protocol updates: rejected because project impact requires review.
- Close the old PR before creating its replacement: rejected because failure
  leaves no active upgrade path.
- Reuse one rolling PR and branch: rejected because immutable target history and
  explicit supersession links are clearer.
- Force-reset or delete changed automation branches: rejected because it can
  lose work.
- Treat cleanup as fully transactional: rejected because Git refs and PR state
  do not share one atomic commit boundary.
- Central GitHub App scanning every consumer: deferred as excessive authority
  and scope for this compact protocol.

## Review condition

Review when repository-reference providers gain a common writable contract,
consumer count justifies a centrally managed GitHub App, or GitHub provides an
atomic primitive spanning PR state and branch-ref deletion.
