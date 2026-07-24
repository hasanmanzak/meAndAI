# 2026-07-17 - v0.9.7 Managed Merge Finalization

## Scope

- Feature: [FEAT-0022](../../../docs/features/FEAT-0022-v097-managed-merge-finalization/README.md)
- Decision: [DEC-0016](../../../docs/decisions/DEC-0016-managed-post-merge-finalization.md)
- Tracking: [issue #61](https://github.com/hasanmanzak/meAndAI/issues/61)
- Delivery: [pull request #62](https://github.com/hasanmanzak/meAndAI/pull/62)
- Tests: [TEST-0108](../../../docs/features/FEAT-0022-v097-managed-merge-finalization/test-cases.md), [TEST-0109](../../../docs/features/FEAT-0022-v097-managed-merge-finalization/test-cases.md), and [TEST-0110](../../../docs/features/FEAT-0022-v097-managed-merge-finalization/test-cases.md)

## Durable handoff

- A consumer adopting or updating to `v0.9.7` receives a
  `pull_request.closed` finalization route plus an explicit
  `finalize_pull_request` recovery input in its managed lifecycle workflow.
- The quick-adoption launcher binds the canonical adoption issue through one
  exact, non-closing `Tracking issue: #N` line before making the proposal ready.
  A managed update maintainer must add the same line during DoR.
- The existing consumer updater adapter validates the fresh merged PR, current
  default-branch containment, marker, path class, issue, open branch reuse, API
  head, and live ref. It deletes only the exact branch through an expected-head
  lease before issue evidence, transient-label cleanup, and completion closure.
- Native closing keywords are intentionally forbidden because GitHub would
  close the issue before branch convergence. A closed issue without the exact
  finalization marker blocks rather than being treated as successful recovery.
- The job-scoped `GITHUB_TOKEN` write exception applies only to post-merge
  finalization. Update discovery, proposal creation, and workflow self-update
  retain the consumer-scoped `MEANDAI_UPDATER_TOKEN` contract.
- Existing merge events are not replayed. The first merge installing this route,
  a `GITHUB_TOKEN`-suppressed event, or a partial cleanup uses the explicit
  recovery dispatch. Existing-consumer remediation is outside this feature; adoption will
  be exercised later against another empty consumer.
- The focused managed-finalization suite and the complete repository suite pass;
  the latter completed in 543.1 seconds with all declared scenario evidence.

## Publication boundary

The repository files describe the intended `v0.9.7` release, but [issue #61](https://github.com/hasanmanzak/meAndAI/issues/61) and
GitHub Releases remain authoritative for exact merge, tag, asset, hosted-check,
and branch-cleanup evidence after publication.
