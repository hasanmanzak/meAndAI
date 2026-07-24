# 2026-07-23 - v0.13.5 Slash-Safe Ref and Single-Owner Lifecycle

- Feature: [FEAT-0044](../../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md)
- Issue: [#108](https://github.com/hasanmanzak/meAndAI/issues/108)
- Branch: `codex/bug-0026-slash-safe-single-owner-lifecycle`
- Tests: [TEST-0169](../../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/test-cases.md#test-0169) and [TEST-0170](../../../docs/features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/test-cases.md#test-0170)
- Governing decisions: [DEC-0016](../../../docs/decisions/DEC-0016-managed-post-merge-finalization.md), [DEC-0017](../../../docs/decisions/DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0019](../../../docs/decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0022](../../../docs/decisions/DEC-0022-release-declared-semantic-capabilities.md), and [DEC-0027](../../../docs/decisions/DEC-0027-single-owner-consumer-merge-events.md)

## Durable context

Immutable v0.13.4 is the verified base at commit
[`089c63d2aeca2d8188bdaeeced5e33be8d01c256`](https://github.com/hasanmanzak/meAndAI/commit/089c63d2aeca2d8188bdaeeced5e33be8d01c256). A consumer merge exposed two
generic defects: the capability-review runner encoded a complete slash-bearing
branch as one URI component, and the consumer workflow let the same merged PR
and default-branch push both own follow-on discovery. A self-created review
branch push could then replace the pending PR event under GitHub's one-pending-
run concurrency behavior.

## Bounded correction

- Encode Git ref segments independently while preserving literal `/` path
  delimiters for reads, updates, cleanup checks, and recovery.
- Keep merged `pull_request.closed` as the sole managed-merge lifecycle owner.
- Remove push admission; keep schedule/manual repository-evidence recovery.
- Preserve exact OID leases, branch-first and
  issue-last cleanup, credentials, and immutable release behavior.
- Do not add generalized orphan cleanup or consumer-specific logic.

## Continuation

Complete the focused tests, bounded diff review, final relevant validation,
issue/PR delivery, and immutable v0.13.5 publication. Only after publication,
install the reviewed runtime in the affected consumer and revalidate its exact
branch OID, absent PR/issue ownership, and default head before recovery.
