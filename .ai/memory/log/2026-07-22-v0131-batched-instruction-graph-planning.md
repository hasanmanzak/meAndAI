# 2026-07-22 - v0.13.1 Batched Instruction-Graph Planning

## Scope and authority

- Feature: [FEAT-0040](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/README.md)
- Task and tracking authority: [`TASK-0002` / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
- Branch: `codex/task-0002-batched-instruction-graph-transport`
- Baseline: immutable [v0.13.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.13.0),
  commit `299b8982cd57961e2b3a6136b07af3bfb49a16d1`
- Planned tests: [TEST-0161 and TEST-0162](../../../docs/features/FEAT-0040-v0131-batched-instruction-graph-acquisition/test-cases.md)

## Verified starting state

- PR #99 completed every deterministic fixture/operation ratchet and merged as
  the exact tree later published in immutable v0.13.0. Issue #95 retains PR,
  hosted, release, asset, cleanup, and post-publication evidence.
- Final released-tree hosted observations were Ubuntu 5:33 total and Windows
  20:33 total. Windows PowerShell 5.1 hotspots were quick adoption 723.326
  seconds, bootstrap 202.782 seconds, and instruction graph 130.214 seconds.
- Reusable fixture construction is no longer the unexplained residual. Both
  production graph adapters still start one `git cat-file blob <sha>` process
  per parsed blob.
- FEAT-0040 proposes a lazy binary-safe `git cat-file --batch` session per
  graph acquisition as the first candidate bounded correction. Pure graph policy,
  topology, semantic capability definitions, and mutation authority stay fixed.

## Gate 1 continuation

- FEAT-0040, SUBF-0078/0079, TEST-0161/0162, and RISK-0190..0192 are
  collision-free and defined.
- `0.13.1` is the backward-compatible target; no version surface changes during
  planning.
- No new capability or decision is required while the session remains actor-
  local and acquisition-local. Shared cache/state, a daemon, policy-module I/O,
  or hosted topology change remains outside scope.
- Operation-budget schema 2 preserves FEAT-0039's exact v0.12.7 measurement as
  one identified entry and appends a distinct v0.13.0 graph-transport
  measurement; every closure target binds one measurement identity. The new
  stable route counts only the existing small real-Git fixture's two production
  actor acquisitions: aggregate blob processes `4 -> 2` and requests `4 -> 4`.
  The separate immutable self-repository evidence remains `175 -> 1` and
  `175 -> 175` per actor.
- The released-tree observer is now frozen with digest
  `sha256:1f0471fbe882ce959afe52f65713a4f3332c3ba0bc1616db0c5b256687fcf4a8`.
  Quick and bootstrap each started 175 blob processes for 175 unique requests,
  parsed 1,332,781 bytes, and produced the same graph digest. The per-
  acquisition target is one blob process with all 175 requests and graph
  evidence unchanged.
- Focused Windows PowerShell 5.1 expected-red is frozen before production:
  TEST-0161 reports exactly six actor-contract findings in 146.507 seconds with
  TEST-0151/0152 intact; TEST-0162 reports 25 schema-2/batch-ratchet findings in
  8.3 seconds without parse/null failure. The final 6.0-second `StructureOnly`
  run accepts both canonical owners. Gate 1 is complete.
- The private session factory may receive exact transport/monotonic-clock hooks
  only in focused tests. Production graph entry points cannot receive them and
  retain literal 120-second/5-second deadlines, allowing hung/unreapable N/N+1
  paths to run without real waits. Real-Git default transport and active
  replace-ref isolation remain required.
- Issue #98's prior local quick/bootstrap/graph timings remain historical
  observations; its unproven 333.1-second WindowsNative value is superseded by
  the verified 341.0-second FEAT-0039 record. Final v0.13.0 hosted values and the
  exact observer are FEAT-0040's comparison authority.
- The first Windows PowerShell 5.1 `StructureOnly` run produced exactly the two
  planned missing-authority findings for `TEST-0161` and `TEST-0162`; no other
  structural problem was reported.
