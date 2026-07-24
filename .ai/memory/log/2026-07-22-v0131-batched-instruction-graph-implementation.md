# 2026-07-22 - v0.13.1 Batched Instruction-Graph Implementation

## Scope and authority

- Feature: [FEAT-0040](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
- Task and external evidence authority:
  [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
- Branch: `codex/task-0002-batched-instruction-graph-transport`
- Development protocol version: `0.13.1`
- Latest immutable release: `v0.13.0`, commit
  `299b8982cd57961e2b3a6136b07af3bfb49a16d1`
- Predecessor:
  [v0.13.1 planning handoff](2026-07-22-v0131-batched-instruction-graph-planning.md)

## Implemented state

- Production commit `78c8706e9d4d4f4c020d983b22114165687b475e`
  replaces each quick-adoption and hosted-bootstrap per-blob process loop with
  one lazy, acquisition-local, binary-safe `git cat-file --batch` session.
- The unchanged pure graph builder still receives `TreeEntries + ReadBlob`.
  The two actor-local transports enforce exact ASCII-LF requests, OID/type/
  canonical-size/hash/trailer identity, per-blob and aggregate limits, request
  and byte parity, a common monotonic deadline, bounded concurrent stderr, Git
  replace-object isolation, non-reentrancy, and fail-closed cleanup.
- The repository operation contract is schema 2. The immutable v0.13.0 actor
  baseline remains 175 blob processes and 175 requests per positive
  acquisition; the reviewed implemented boundary is one process and the same
  175 requests.
- Independent-reader commit
  `55764442820c884e8c3115726bb010a0a9004d77` gives the quick, hosted
  graph-identity, and instruction-graph expected sides their own test-owned
  batch readers. They do not import either production transport and are not
  counted as production savings.
- [SUBF-0078](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) and [SUBF-0079](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) are locally complete. Hosted delivery,
  publication, and release closure remain pending external facts.

## Focused and supporting evidence

- [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md) passed with exact operation observations `2/2` process starts and
  `4/4` requests: PowerShell 7 in 84.1 seconds and Windows PowerShell 5.1 in
  147.6 seconds. [TEST-0151](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md) and [TEST-0152](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md) remained green in the same owner.
- [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md) passed under PowerShell 7 in 5.3 seconds and Windows PowerShell 5.1
  in 6.5 seconds. [TEST-0158](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md) and [TEST-0159](../../../docs/features/FEAT-0039-v0130-test-runtime-efficiency/test-cases.md) remained green in the same owner.
- Structural validation passed in 4.8 seconds. Source dispatch passed in 2.6
  seconds, the quick-adoption bundle in 23.0 seconds, final quick instruction
  closure in 38.2 seconds, and local hosted-bootstrap `VerticalSlices` in
  280.3 seconds.
- The shared full-HEAD expected-graph fixture passed under PowerShell 7 in 22.2
  seconds and Windows PowerShell 5.1 in 34.8 seconds. Both returned digest
  `d0a03bde53b7652706059b5faf74ad9f748da9c0a3401df44eeea6ee365fe091`,
  178 parsed blobs, and 1,371,315 parsed bytes.
- No wall-clock improvement is claimed. The local PS5.1 [TEST-0161](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md) observation,
  147.6 seconds, is above the immutable hosted v0.13.0 graph-owner observation
  of 130.214 seconds, and those environments are not interchangeable. The
  deterministic process boundary is the current correctness evidence.
- `WindowsNative` passed in 343.0 seconds; its streaming and quick-adoption
  owners took 6.493 and 331.854 seconds. The one budgeted Windows PowerShell
  5.1 Full suite passed in 1,306.9 seconds; quick adoption took 742.281 seconds,
  hosted bootstrap 253.297 seconds, instruction graph 145.462 seconds, and the
  test-runtime owner 9.706 seconds.
- The bounded convergence scan found two Blocking observations. [FIND-0200](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
  added missing [TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md) ownership for the third independent expected reader;
  PS5.1/PS7 focused confirmations passed in 9.3/9.2 seconds and StructureOnly
  passed in 7.8 seconds. [FIND-0201](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) reconciled actual local gate evidence with
  the feature/index/DoD/memory projection. No unresolved `Blocking` finding
  remains. [FIND-0202](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)/[FIND-0203](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) are optional bounded improvements, while
  [FIND-0204](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md) keeps the unimproved Windows critical path owned by [issue #98](https://github.com/hasanmanzak/meAndAI/issues/98).

## Continuation

Create the converged candidate commit and push, open the delivery pull request,
and run the existing one-Windows/one-Ubuntu hosted topology. After applicable
checks and review pass, merge and publish immutable v0.13.1 with both required
assets, cleanup, and post-publication evidence through [issue #98](https://github.com/hasanmanzak/meAndAI/issues/98). None of those
live facts exists yet; pull request, hosted checks, merge, release, and cleanup
remain `Pending`.
