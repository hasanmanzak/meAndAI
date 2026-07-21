# 2026-07-21 - v0.12.6 Instruction-Graph Containment Implementation

## Status

- Feature: [FEAT-0037](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md)
- Decision: [DEC-0024](../../../docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
- Tracking and future publication authority: [issue #93](https://github.com/hasanmanzak/meAndAI/issues/93)
- Working branch: `codex/feat-0037-instruction-graph-containment`
- Development version: `0.12.6`; latest immutable release remains `v0.12.5`
- State: locally complete and validated; focused graph/lifecycle/closure owners,
  `StructureOnly`, `WindowsNative`, and the complete protocol suite pass, while
  hosted PowerShell 7/CI, pull request, merge, release, and post-publication
  verification remain pending

## Implemented boundary

- `SUBF-0070` supplies one canonical exact-base instruction-graph contract,
  deterministic roots and reference traversal, compatibility-seed projection,
  finite acquisition and traversal limits, canonical serialization and digest,
  special-entry containment, and project-neutral real-Git fixtures.
- `SUBF-0071` binds graph identity through local assessment, target-aware
  dispatch, workflow reconstruction, manifest schema 3, proposal marker schema
  7, publishing/recovery marker schema 8, and exact source-drift rejection.
- `SUBF-0072` independently rebuilds source and final graphs, preserves the
  existing bounded mutation envelope, protects non-authorized content, and
  blocks completion when live or newly introduced authority remains unresolved.
- Current-runtime dispatch feature-detects immutable older target workflows and
  omits `source_graph_identity` when the target does not declare that input.
- The meAndAI repository is exercised as an ordinary consumer of the same
  graph contract; no repository-name bypass was added.

This work is deterministic discovery and containment infrastructure. It is not
the future semantic migration converter or planner: it does not translate a
consumer product catalog, task tracker, feature/decision model, or project
memory into meAndAI records, prove semantic parity, or authorize broader writes
and deletions.

## Confirmed local evidence

- `TEST-0151` and `TEST-0152` have canonical executable ownership in
  `tests/capabilities/instruction-graph-discovery/`. Their final focused owner
  passed in 137.452 seconds after culture, encoding/line-ending, lexical-path,
  authority grammar, command/URI negative-control, cycle-depth, discovery-reason,
  protected-terminal, and exact-validator review corrections.
- `TEST-0153` current graph-aware versus immutable v0.12.5 graph-unaware target
  dispatch passed. Capability-bootstrap `All` passed with exit 0 in 322.254
  seconds and emitted canonical `MEANDAI_SCENARIO_RESULTS` including
  `TEST-0153`. The expanded hosted-adapter fixture also passed with exit 0.
- `TEST-0154` local `InstructionGraphClosure` passed in a final 40.202-second
  rerun. The actual local launcher/Codex temporary-commit path rejected the
  exact four live custom authorities before publication-marker, push, or
  readiness mutation. The
  expanded adapter run also passed the new actual hosted graph-aware
  FullMigration closure-block scenario.
- Quick-adoption `ContractsPreflight` passed in 22.444 seconds,
  `AdoptionLifecycle` passed in 193.227 seconds, and quick-adoption `All` passed
  in 948.236 seconds. Empty-array, graph-specific issue-fixture, helper-closure,
  dynamic-module restoration, and fixture-inventory corrections are test-harness
  only; the exact production validator was not relaxed.
- `StructureOnly` passed in 5.989 seconds, `WindowsNative` passed in 374.494
  seconds, and the complete discovered protocol suite passed with exit 0 in
  1,582.88 seconds. The final suite includes canonical `TEST-0151` through
  `TEST-0154`, `TEST-0059`, and `TEST-0138` evidence on one tree.
- Scenario ownership is registered for `TEST-0151` through `TEST-0154` without
  adding consumer-specific production paths.

These results are working-tree evidence, not immutable release or hosted-CI
evidence. Local `pwsh` is unavailable, so supported PowerShell 7 evidence remains
a hosted delivery gate.

## Continue from here

1. Open and review the future pull request, then obtain supported PowerShell 7
   plus hosted Windows and Ubuntu evidence.
2. Resolve any hosted or review failure before merge.
3. Do not project a pull request, hosted CI, merge, immutable v0.12.6 release,
   cleanup, or post-publication verification until each fact exists.
