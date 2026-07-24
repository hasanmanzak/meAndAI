# 2026-07-23 - v0.13.1 Delivery Authority Correction

## Scope and authority

- Feature: [FEAT-0040](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
- Pull request: [#100](https://github.com/hasanmanzak/meAndAI/pull/100)
- Delivery and post-publication authority:
  [issue #101](https://github.com/hasanmanzak/meAndAI/issues/101)
- Implementation history and residual runtime owner:
  [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)

## Correction

The pre-delivery audit found [FIND-0205](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md#find-0205). [TEST-0065](../../../docs/features/FEAT-0011-stability-closure/test-cases.md#test-0065) requires the canonical
delivery issue to be closed before post-publication verification can succeed,
but [issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) must remain open as the explicit owner of [FIND-0204](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md#find-0204) and further
measured runtime work. Treating one issue as both authorities would either make
publication closure impossible or erase the durable residual owner.

[Issue #101](https://github.com/hasanmanzak/meAndAI/issues/101) is therefore the closeable [FEAT-0040](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) delivery and publication
authority. [Issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) retains implementation history and the open performance
follow-up. This correction changes no production behavior, protocol semantics,
test topology, release contents, or runtime evidence.

Windows PowerShell 5.1 `StructureOnly` passed in 4.9 seconds, and the focused
post-publication verifier fixture passed in 2.2 seconds without claiming live
published-state evidence. `git diff --check` also passed.

## Continuation

Push the documentation correction to [PR #100](https://github.com/hasanmanzak/meAndAI/pull/100) and require a fresh exact-head
Windows/Ubuntu hosted run. After final review, merge without bypass, validate
exact main, publish immutable v0.13.1 with both required assets, complete exact
owned-branch cleanup, write release evidence to [issue #101](https://github.com/hasanmanzak/meAndAI/issues/101), close [issue #101](https://github.com/hasanmanzak/meAndAI/issues/101),
and run [TEST-0065](../../../docs/features/FEAT-0011-stability-closure/test-cases.md#test-0065). Keep [issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) open for [FIND-0204](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md#find-0204).
