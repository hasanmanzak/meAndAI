# Stability and Consistency Mandate

- Work: [FEAT-0015](../../../docs/features/FEAT-0015-stability-consistency-mandate/README.md)
- Decision: [DEC-0015](../../../docs/decisions/DEC-0015-event-triggered-stability-cycles.md)
- Delivery and post-publication authority: [issue #47](https://github.com/hasanmanzak/meAndAI/issues/47)
- Review: [pull request #48](https://github.com/hasanmanzak/meAndAI/pull/48)
- Target: `0.9.0`
- Status: Local convergence complete; review publication and hosted evidence pending.

The mandate uses the protocol's existing bounded full-project scan rather than
adding an autonomous scanner or bootstrap layer. Material development starts
one cycle. Every observation retains a Gate 5 disposition; explicit
dependencies determine which `Blocking` findings are ready, and priority orders
that ready set. Each correction receives focused evidence and fresh-diff
self-review, including any blocker caused or exposed by the change.

One confirmation scan proves zero unresolved `Blocking` findings. The
converged final push is an ordinary Git push, not a tag or GitHub Release. The
repository then waits until new development or failed evidence re-enters the
cycle. Consumer projects receive the mandate through a reviewed exact protocol
pin; their instructions, memory, feature/decision records, and tests remain
consumer-owned.

Local evidence on 2026-07-16: TEST-0096 through TEST-0099 passed in the
structural owner, the quick-adoption suite passed in 372.3 seconds, and the
complete suite passed in 560.1 seconds. The initial scan and correction queue
resolved FIND-0133 through FIND-0139; the bounded confirmation and final
evidence-only structural verification found no unresolved `Blocking` finding.
Exact converged-push evidence remains external until the push exists.
