# DEC-0015 - Use Event-Triggered Stability Cycles with a Convergence-Gated Push

- Classification: Decision
- Status: Accepted
- Date: 2026-07-16
- Decision owners: meAndAI maintainers
- Related feature: [FEAT-0015](../features/FEAT-0015-stability-consistency-mandate/README.md)
- Tracking and post-publication authority: [issue #47](https://github.com/hasanmanzak/meAndAI/issues/47)
- Related decisions: [DEC-0004](DEC-0004-bounded-completion-convergence.md) and [DEC-0012](DEC-0012-bounded-correction-and-external-release-evidence.md)

## Context

The protocol already requires a bounded post-development full-project scan,
finding dispositions, and fresh-diff self-review. It does not yet state one
persistent operating mandate that connects development, dependency-aware
finding order, per-finding correction review, the terminal push boundary, and
the waiting state shared by this repository and its consumers.

A literal loop until no observation of any kind exists would contradict the
accepted disposition model and bounded-validation decision. A background loop
would also repeat unchanged work, while using the word `release` for the
terminal action would collide with the protocol's separate Git tag and GitHub
Release meaning.

## Decision

Adopt one event-triggered stability and consistency cycle:

1. A materially changed development increment enters the existing bounded
   post-development full-project scan. The mandate covers feature, bug,
   refactor, review, test, documentation, governance, and consistency work.
2. Every observation receives the existing Gate 5 disposition. Only unresolved
   `Blocking` findings enter the remediation queue or prevent convergence.
3. Build the queue from explicit dependencies first. Among findings whose
   dependencies are satisfied, use priority, severity, impact rank, and then
   stable identifier order. Priority is `p0` through `p3`; severity and impact
   rank use the protocol's five-level scale. A dependency cycle or unavailable required authority is a
   blocked outcome, not permission to guess an order.
4. Resolve one `Blocking` finding at a time, except for the smallest explicitly
   recorded dependency-coherent group that cannot be changed safely in
   isolation. Each correction receives focused evidence and a fresh-diff
   self-review before the next independent queue item starts.
5. A `Blocking` defect caused or exposed by a correction remains inside the
   active cycle. Fix it in the current correction when coherent; otherwise add
   it to the queue with dependencies and priority. New debt introduced by the
   current change cannot be deferred as legacy or optional work.
6. If the initial scan has no unresolved `Blocking`, it is already the
   convergence evidence and no unchanged confirmation is run. After remediation
   changes the tree and empties the queue, use the one budgeted confirmation
   scan. If no unresolved `Blocking` finding remains, the tree has locally
   converged. Local convergence is not full normative cycle completion. The
   cycle completes only after the authorized converged final review-branch push
   exists and then enters `Waiting`. Without that authority, preserve
   push-eligible evidence and stop as `Blocked` without a completion claim. Do
   not repeat an unchanged scan merely because the process is persistent.
7. Hosted CI or review evidence found after a push reopens the same cycle and
   requires a corrected converged push. Correctable new failed evidence is a
   re-entry trigger, not itself a terminal outcome. Exhausted budget,
   unresolved dependency, missing authority, or evidence whose required
   correction cannot be completed within the remaining authority and budget
   stops the cycle as `Blocked` without a success claim or final corrective
   push.

The terminal action in this mandate is named the **converged final push**. It
is an ordinary Git push and does not create a tag or GitHub Release. Protocol
version publication remains a separate post-merge event governed by Gate 7 and
Section 8.

The mandate is normative in [PROTOCOL.md](../../PROTOCOL.md). It is not duplicated as a second
contract in consumer instructions. A consumer receives it by adopting or
upgrading its immutable protocol pin; consumer-owned instructions, memory,
features, decisions, and tests remain under consumer ownership.

## Consequences

- The repository has one durable operating loop without a service, scheduler,
  scanner framework, recursive bootstrapper, or validator chain.
- Dependency safety determines which findings are ready; priority orders only
  the ready set.
- Canonical findings record explicit dependencies or `None`, queue priority,
  severity, and impact rank so another actor can reproduce the ready set and
  order.
- Every correction has a bounded review boundary, and change-caused defects
  cannot escape into a later cycle.
- A clean cycle ends in a push and an explicit waiting state. New development
  re-enters the mandate; unchanged state does not consume more scan budget.
- Earlier consumer pins remain valid. Consumers receive the new mandatory
  control prospectively through a reviewed exact commit pin or the immutable
  protocol release that contains [FEAT-0015](../features/FEAT-0015-stability-consistency-mandate/README.md).
- Distribution of v0.9.0 MUST use the immutable GitHub Release required by Gate
  7 because that is the protocol's separate exact-pin distribution mechanism.
  This does not change the mandate's converged final push into a release or tag.

## Alternatives considered

- Repeat until every observation disappears: rejected because accepted
  residual, external, legacy, and optional observations are legitimate durable
  dispositions and do not invalidate completion.
- Re-run continuously while idle: rejected because it creates unchanged scans
  without new evidence and has no useful stop condition.
- Sort by priority before dependencies: rejected because a high-priority
  finding may be unsafe or impossible to resolve before its prerequisite.
- Batch every finding into one correction: rejected because it weakens focused
  evidence and self-review; only an explicitly inseparable dependency group may
  be atomic.
- Rewrite consumer-owned `AGENTS.md` during compatible updates: rejected
  because the pinned protocol already carries the mandate and consumer
  ownership is an existing safety boundary.
- Treat each converged push as a GitHub Release: rejected because ordinary
  development publication and protocol-version distribution are different
  lifecycle events.

## Review condition

Review if projects repeatedly exhaust the finite confirmation budget, if a
class of findings cannot be represented as a dependency graph, or if the
repository publication model no longer uses review-branch pushes.
