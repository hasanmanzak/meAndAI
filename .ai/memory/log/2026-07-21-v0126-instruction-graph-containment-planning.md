# 2026-07-21 - v0.12.6 Instruction-Graph Containment Planning

## Status

- Feature: [FEAT-0037](../../../docs/features/FEAT-0037-v0126-instruction-graph-adoption-containment/README.md)
- Decision: [DEC-0024](../../../docs/decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
- Tracking and future post-publication authority: [issue #93](https://github.com/hasanmanzak/meAndAI/issues/93)
- Maintainer disposition: [accepted on 2026-07-21](https://github.com/hasanmanzak/meAndAI/issues/93#issuecomment-5033653638)
- Candidate version: `0.12.6`, provisional compatibility disposition
- State: maintainer accepted FEAT-0037 and DEC-0024 on 2026-07-21; technical
  Definition of Ready is satisfied, while a separate development directive
  remains required

## Verified baseline

- Local `main`, local `origin/main`, the live GitHub default-branch commit, and
  immutable release `v0.12.5` resolve to
  `252488a88d2a64ea8816239bbf6d953f506b8840`.
- The release is non-draft, non-prerelease, immutable, and issue #89 contains
  final publication, hosted validation, Derdini replay, and cleanup evidence.
- FEAT-0036 and issue #89 are complete. This planning branch starts from the
  released merge commit.

## Planning boundary

- FEAT-0037 replaces path-only instruction-authority discovery with one
  exact-base deterministic graph and independent completion closure.
- It is shared initial-adoption/capability-bootstrap infrastructure, not a new
  release-declared capability.
- It does not change the capability catalog, capability ledger, migration
  catalog, `MIG-NNNN`, product records, or semantic mutation envelope.
- Graph-discovered paths outside the existing envelope remain evidence-only and
  block required mutation or retirement.
- `TEST-0151` through `TEST-0154`, `SUBF-0070` through `SUBF-0072`, and
  `RISK-0171` through `RISK-0178` define the proposed tests-first delivery.
- No production script or executable test has been changed. Implementation may
  begin only after the maintainer accepts FEAT-0037 and DEC-0024 and then gives
  a separate explicit development directive.

## Continue from here

The planning disposition is complete. Stop for the separate development
directive. The first implementation action must create the declared executable
scenarios and record the current path-only inventory and partial-completion
behavior as expected-red evidence before changing production behavior.
