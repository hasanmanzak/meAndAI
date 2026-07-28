# 2026-07-28 - C# operational foundation second slice

## Directive and authority

The maintainer authorized sequential continuation after the first foundation
slice. [FEAT-0059](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md)
/ [SUBF-0120](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0120)
/ [issue #154](https://github.com/hasanmanzak/meAndAI/issues/154) owns this
bounded slice; [DEC-0032](../../../docs/decisions/DEC-0032-csharp-operational-applications-and-portable-jit-distribution.md)
retains the JIT, framework-dependent, multi-application transition authority.

This slice may add deterministic result contracts, four single-capability port
markers, a grant-checked infrastructure scope, and an asynchronous dependency
boundary. It does not add repository, Git, provider, process, credential, or
consumer adapters; transfer production authority; publish a release; or retire
PowerShell.

## Implemented contract

- Closed result outcomes and failure codes reject impossible success/failure,
  value, null, and code combinations. Reference-type payloads retain explicit
  absence and the four-field base schema exposes no arbitrary diagnostic or
  credential surface.
- Repository read/mutation and provider read/mutation markers each express one
  capability. Registration rejects marker types, duplicates, ambiguous
  contracts, and implementation capability widening.
- Resolution checks the immutable stage grant before registration presence, so
  read-only callers cannot probe for mutation implementations.
- The asynchronous operation boundary maps requested cancellation and typed
  dependency failure to closed redacted results; unexpected programming
  exceptions remain exceptions.
- [TEST-0192](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0192)
  owns the compiled result, port, scope, and execution-boundary regression.
  Combined with [TEST-0191](../../../docs/features/FEAT-0059-csharp-operational-foundation/test-cases.md#test-0191),
  the exact hosted test set contains 31 cases.

## Tests-first and local evidence

The executable red run failed only because the authorized result, port,
infrastructure-scope, and execution-boundary types did not exist. The bounded
implementation then passed 16 focused cases. Fresh-diff review added
reference-type absence, exact four-field serialization, direct-marker
rejection, implementation-capability widening rejection, and analyzer-driven
concrete immutable collection coverage.

Locked restore, zero-warning Release build, format/analyzer verification, and
31 combined cases passed. The focused canonical streaming owner passed on
PowerShell 7 / Windows PowerShell 5.1 in 10.0 / 12.4 seconds after a tests-first
9.7 / 11.5-second red. Candidate- and exact-committed-tree Windows PowerShell
5.1 StructureOnly passed in 208.5 / 206.6 seconds.

## Hosted recurrence closure

The first implementation head
[`c5fa78dc71a6106beac8461acd950efa44c55976`](https://github.com/hasanmanzak/meAndAI/commit/c5fa78dc71a6106beac8461acd950efa44c55976)
passed the C# tests on both hosts and the complete Ubuntu job but exposed
[FIND-0362](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0362)
in the retained Windows streaming oracle. Exact correction
[`4b10fc9314157e83cd36ae8d3b45162459bd547a`](https://github.com/hasanmanzak/meAndAI/commit/4b10fc9314157e83cd36ae8d3b45162459bd547a)
removed the independent PID reopen, but hosted evidence showed that OS process
liveness itself remained an over-constrained consumption boundary and also
exposed one short commit-link reference.

[FIND-0363](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#find-0363)
retained the existing [TEST-0105](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0105)
/ [TEST-0106](../../../docs/features/FEAT-0020-v095-streamed-codex-cancellation/test-cases.md#test-0106)
identities and replaced OS liveness with the reader's exact `ActiveReadLoop`
versus `PostExitDrain` stage. No PID reopen, timing tolerance, retry, event
weakening, duplicate scenario, or adoption behavior was added. Exact correction
commit [`26b126858cd4a6612a8c19909bd4fd3958fb82f1`](https://github.com/hasanmanzak/meAndAI/commit/26b126858cd4a6612a8c19909bd4fd3958fb82f1)
then passed [run `30312104364`](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364):
[Ubuntu](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779014)
in 12 min 04 s and [Windows](https://github.com/hasanmanzak/meAndAI/actions/runs/30312104364/job/90129779066)
in 32 min 09 s. C# execution consumed 99 / 170 ms; Windows emitted the exact
streaming scenario manifest, and Ubuntu passed
[TEST-0178](../../../docs/features/FEAT-0047-v0142-clickable-cross-record-references/test-cases.md#test-0178).

## Closure and continuation

[SUBF-0120](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0120)
closes at five of five gates with 16 focused and 31 combined C# cases,
tests-first evidence, locked restore, clean build/analyzer evidence, fresh-diff
review, exact-tree validation, hosted cross-platform evidence, current
documentation and memory, and zero unresolved `Blocking` findings. Feature
completion is two of three subfeatures, or 67%.

[SUBF-0121](../../../docs/features/FEAT-0059-csharp-operational-foundation/README.md#subf-0121)
remains gated and unauthorized. This closure keeps the draft pull request and
feature issue open, changes no consumer, does not publish or merge, and leaves
PowerShell as production and compatibility authority.
