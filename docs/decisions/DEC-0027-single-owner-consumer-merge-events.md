# DEC-0027 - Use One Consumer Lifecycle Event per Managed Merge

- Classification: Decision
- Status: Accepted
- Date: 2026-07-23
- Decision owners: meAndAI maintainers and consumer maintainers
- Related feature: [FEAT-0044](../features/FEAT-0044-v0135-slash-safe-ref-single-owner-lifecycle/README.md)
- Related decisions: [DEC-0016](DEC-0016-managed-post-merge-finalization.md), [DEC-0017](DEC-0017-idempotent-consumer-lifecycle.md), [DEC-0019](DEC-0019-hosted-runner-efficiency.md), and [DEC-0022](DEC-0022-release-declared-semantic-capabilities.md)
- Supersedes: the v0.13.4 protocol requirement that default-branch push independently enter consumer merge recovery; explicit merged-PR, schedule, and manual recovery authority remain unchanged

## Context

GitHub emits both `pull_request.closed` and a default-branch `push` for a normal
managed merge. A workflow subscribed to both creates two hosted runs. A shared
concurrency group serializes them but does not deduplicate them, and GitHub
retains only one pending run per group. A push from a branch created by the
first run can therefore replace the pending exact pull-request event before
job-level guards execute.

Default-branch push does not carry the exact pull-request head/base metadata
needed by post-update semantic discovery. Keeping it as a second recovery run
also consumes Actions minutes for every normal merge. Schedule and explicit
manual dispatch already provide repository-evidence recovery when the exact
merge event is missed or fails.

## Decision

The canonical consumer lifecycle workflow has exactly three event classes:

1. merged same-repository managed `pull_request.closed` owns exact post-merge
   finalization and metadata-dependent follow-on discovery;
2. schedule owns bounded retained-merge recovery followed by ordinary
   discovery; and
3. manual dispatch owns ordinary recovery/discovery or one explicit pull-
   request-number finalization.

The workflow does not subscribe to `push`. Therefore a managed merge creates
one lifecycle run, and a branch created by that run creates none. The quick
adoption launcher continues to dispatch the workflow explicitly after its seed
push. A missed PR event, token-suppressed merge, direct default-branch change,
or partial finalization waits for the next schedule or an explicit manual
dispatch; both revalidate current repository evidence and remain idempotent.

One repository-scoped concurrency group with `cancel-in-progress: false`
remains. It serializes the three authoritative event classes without accepting
self-created branch pushes into the queue.

## Consequences

- A normal managed merge consumes one consumer lifecycle run, not two or three.
- Exact pull-request metadata cannot be displaced by an automation branch push.
- Recovery latency for a missed merge event is bounded by the schedule unless a
  maintainer invokes the explicit recovery dispatch sooner.
- Direct default-branch pushes no longer start lifecycle discovery; they are
  observed by schedule/manual inventory.
- Validation workflows may independently retain `push: main`; this decision is
  limited to the consumer adoption/update lifecycle workflow.

## Alternatives considered

- Keep push but make it finalization-only: rejected because it still starts a
  redundant hosted run and still competes for the single pending concurrency
  slot.
- Filter only reserved automation branches: rejected because the merge-caused
  default push still creates the duplicate run.
- Use separate concurrency groups: rejected because it permits simultaneous
  mutation and increases runner consumption.
- Add a queue, external coordinator, or GitHub App: rejected as disproportionate
  to an event-ownership correction already covered by schedule/manual recovery.

## Review condition

Review if GitHub supplies atomic cross-event deduplication before workflow
admission, the managed lifecycle stops using pull-request branches, or the
schedule/manual recovery route can no longer prove exact current repository
state.
