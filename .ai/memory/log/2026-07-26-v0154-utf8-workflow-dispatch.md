# 2026-07-26 - v0.15.4 UTF-8 Workflow Dispatch

## Scope and authority

- Feature: [FEAT-0055](../../../docs/features/FEAT-0055-v0154-utf8-workflow-dispatch/README.md)
- Bug: [BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137) /
  [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137)
- Decisions: [DEC-0023](../../../docs/decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
  and [DEC-0024](../../../docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
- Canonical scenario: [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
- Immutable baseline: [v0.15.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.3)
  at [`164543d939ef97ec02d96499d3e5b796eed64470`](https://github.com/hasanmanzak/meAndAI/commit/164543d939ef97ec02d96499d3e5b796eed64470)

## Finding and correction

The graph-aware Windows launcher supplied compact instruction-graph JSON as a
native `gh workflow run --field` argument. Native argument handling removed the
quotation marks, and the workflow capability bootstrap correctly rejected the
received text as invalid JSON. This is reusable upstream behavior; no consumer
implementation, fixture, or test belongs to the correction.

`Invoke-LifecycleWorkflow` now builds one ordered string-valued input map and
passes its compact outer JSON through `gh workflow run --json`. The optional
graph input is added only when the immutable target workflow declares it. The
shared `Invoke-External` stdin path now selects UTF-8 without a BOM for the
bounded native call and restores the prior output encoding in `finally`.

The project recurrence registry now joins the historical v0.13.1 Windows stdin
framing evidence with the workflow-specific native-argument failure. Future
structured workflow input maps must use the same JSON-stdin route.

## Test evidence

- Expected red: focused [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  failed in 1.3 seconds because v0.15.3 did not
  use one JSON stdin payload.
- Focused green: [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  passed in 3.7 seconds on Windows PowerShell 5.1 and
  3.2 seconds on PowerShell 7 with exact string-property, Unicode byte, no-BOM,
  encoding-restoration, graph-aware, and graph-unaware evidence.
- Capability Contracts passed in 4.5 seconds.
- The full-launcher `AdoptionLifecycle` shard passed in 195 seconds with the
  shared gh fixture consuming the new stdin contract.
- The first canonical full-suite attempt stopped only at
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
  after
  2,016.9 seconds because a reusable fixture JSON builder introduced an
  unreviewed dynamic scriptblock-operation identity. The helper was changed to
  a direct modular invocation without increasing the operation budget;
  [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158),
  [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159),
  and [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162)
  then passed in 6.8 seconds.
- The final canonical suite passed all discovered owners in 1,957.8 seconds.
- The first [PR #138](https://github.com/hasanmanzak/meAndAI/pull/138)
  [hosted run](https://github.com/hasanmanzak/meAndAI/actions/runs/30201366801)
  exposed a second native boundary: hosted Windows PowerShell 5.1 began with a
  BOM-bearing `[Console]::InputEncoding`, so changing only `$OutputEncoding`
  still prefixed stdin. Linux independently rejected unlinked delivery-
  evidence references.
- [TEST-0153](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  now installs the preamble-bearing ambient value deterministically. It
  reproduced the Windows failure in 3.3 seconds, then passed on Windows
  PowerShell 5.1 / PowerShell 7 in 3.0 / 3.2 seconds after the native owner
  pinned and restored both `$OutputEncoding` and `[Console]::InputEncoding`.
- The final canonical suite after this hosted correction passed every
  discovered owner in 2,026.3 seconds.
- Final hosted validation, immutable release, and branch cleanup remain the
  bounded delivery steps.

## Continuation

Publish the reviewed candidate through one PR, tag the exact merged commit as immutable
`v0.15.4`, verify the two release assets and post-publication evidence, close
[issue #137](https://github.com/hasanmanzak/meAndAI/issues/137), and remove only
the exact owned branch. Consumer recovery is a
separate operation and is not authorized by this feature.
