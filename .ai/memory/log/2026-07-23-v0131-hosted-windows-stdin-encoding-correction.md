# 2026-07-23 - v0.13.1 Hosted Windows Stdin Encoding Correction

## Scope and authority

- Feature: [FEAT-0040](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
- Pull request: [#100](https://github.com/hasanmanzak/meAndAI/pull/100)
- Delivery and post-publication authority:
  [issue #101](https://github.com/hasanmanzak/meAndAI/issues/101)
- Failed exact-head evidence:
  [run 29963388824](https://github.com/hasanmanzak/meAndAI/actions/runs/29963388824)

## Finding and cause

Ubuntu passed at candidate head
[`9b1b1d1c074294ea455f81439b505fb4b3e491fa`](https://github.com/hasanmanzak/meAndAI/commit/9b1b1d1c074294ea455f81439b505fb4b3e491fa), but the Windows PowerShell 5.1
job failed after 20:25.9 with an invalid independent expected-reader batch
header. [FIND-0206](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md#find-0206) established that `Get-TestCommittedGraphFixture` inherited
a preamble-bearing ambient stdin encoding. PowerShell initialized its redirected
writer with `EF-BB-BF`, so Git received a BOM-prefixed first OID and returned a
`missing` response.

Both production transports already had no-BOM source guards and a
preamble-bearing runtime regression. The shared test helper also implemented
the correct raw-pipe pattern, but [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) guarded that helper and the
independent reader only against per-blob process restoration. The complete
framing invariant had therefore not been applied to every repository-owned
batch transport.

## Correction and evidence

The independent reader now initializes and captures its raw stdin pipe under
UTF-8 without a BOM, writes, flushes, and closes only that captured stream,
restores ambient encoding in `finally`, and cleans up a child if post-start
stream capture fails. [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) reuses the existing self-HEAD fixture under a
preamble-bearing ambient UTF-8 encoding and verifies restoration. One reusable
[TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) source-contract helper guards both test-owned readers. Together with
[TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161), all four production/test batch transport owners now carry the same
framing invariant; no new repository fixture, production path, or hosted job
was added.

The expected-red PS5.1 run failed only with the hosted invalid-header symptom
in 114.1 seconds; [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) reported the five missing raw-stdin contract
checks. After AST-scoped guard review, [TEST-0151](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0151) and [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0152) and [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0161) passed under PS5.1
and PS7 in 163.6 and 97.7 seconds with exact `2/2` process and `4/4` request
observations. [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0158) and [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) and [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md#test-0162) passed in 9.2 and 8.5 seconds.

## Continuation

Run structural and fresh-diff confirmation, publish one corrected exact head,
and require fresh Windows/Ubuntu hosted evidence. Record live success on [PR
#100](https://github.com/hasanmanzak/meAndAI/pull/100) and [issue #101](https://github.com/hasanmanzak/meAndAI/issues/101) instead of creating a metadata-only candidate commit. Keep
[issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) open for the separate [FIND-0204](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md#find-0204) runtime residual.
