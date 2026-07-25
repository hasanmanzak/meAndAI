# v0.15.0 Recurrence Prevention and Modular Test Harness Planning

Date: 2026-07-25

## Current state

- Latest immutable protocol release remains
  [v0.14.5](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.5).
- [FEAT-0051](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md)
  is registered as Proposed for target `0.15.0` under
  [issue #124](https://github.com/hasanmanzak/meAndAI/issues/124).
- The proposed ownership decision is
  [DEC-0029](../../../docs/decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md).
- The four independently tracked slices are
  [SUBF-0095](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0095) / [issue #128](https://github.com/hasanmanzak/meAndAI/issues/128),
  [SUBF-0096](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0096) / [issue #125](https://github.com/hasanmanzak/meAndAI/issues/125),
  [SUBF-0097](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0097) / [issue #126](https://github.com/hasanmanzak/meAndAI/issues/126),
  and [SUBF-0098](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0098) / [issue #127](https://github.com/hasanmanzak/meAndAI/issues/127).
- [TEST-0183](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0183),
  [TEST-0184](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0184),
  [TEST-0185](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0185),
  [TEST-0186](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0186),
  [TEST-0187](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0187),
  and [TEST-0188](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0188)
  are Planned. No v0.15.0 executable test or production change exists yet.
- This planning registration does not modify `VERSION`, release assets,
  capability catalogs, workflows, or the current `0.14.5` protocol.

## Approved scope retained for continuation

1. Add a prior-art and known-failure recurrence gate with a small active
   signature contract, sibling-surface inventory, canonical-owner routing,
   blind-retry prohibition, and executable-prevention-or-NotApplicable closure.
2. Centralize only proven generic assertion, failure, Git/blob/hash/byte,
   workspace, Markdown/link, and runtime-evidence mechanics under focused
   owners with explicit test context and a bounded AST redefinition guard.
3. Separate root runner, harness, executable case/scenario, capability support,
   inert fixture, mock, and exact runtime-evidence responsibilities.
4. Apply the contract in order to the protocol-update adapter,
   capabilities-bootstrap adapter, and quick-adoption suite; append
   `test-harness-modularity`; preserve active TEST identities, behavior,
   isolation, supported runtimes, immutable predecessors, and workflow topology.

## Planning baseline

- Repeated-definition signals: `Add-Failure` 17, `Assert-Equal` 8,
  `Assert-True` 7, `Assert-ThrowsLike` 6, and `Assert-SequenceEqual` 4.
- Initial migration file sizes: protocol-update adapter fixture 3,297 lines;
  capabilities-bootstrap adapter fixture 3,152 lines; quick-adoption suite
  11,227 lines.
- These are classification inputs, not automatic duplication findings or
  acceptance targets.
- The first planning `StructureOnly` run exposed
  [FIND-0243](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0243):
  the scenario registry could not represent numbered Gate 1 scenarios before
  executable test code existed. The bounded planning correction adds an exact
  `PlannedDocumentation` authority that must become an `ExecutableSuite`
  authority atomically when implementation begins. The confirming
  `tests/protocol.tests.ps1 -StructureOnly` run passed on 2026-07-25.
- Fresh-diff review found
  [FIND-0244](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#find-0244):
  the first guard draft duplicated a full-tree read per planned identity. The
  correction builds one shared source inventory for both planned and historical
  scenario-state checks. The final `StructureOnly` confirmation passed on
  2026-07-25.

## Boundaries

- Memory routes work and records durable safe routes; it never substitutes for
  a regression test.
- Reusable rules and assets stay upstream in meAndAI. Consumer repositories do
  not copy, reimplement, or retest them.
- No AI-memory validator, daemon, background loop, universal clone detector,
  full test-framework rewrite, new workflow/job/matrix, or hosted fan-out.
- [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98)
  remains separate.

## Continuation

Wait for a separate maintainer development directive. When authorized, begin
with [SUBF-0095](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0095)
and its [TEST-0183](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/test-cases.md#test-0183)
red/green contract; complete and review each slice independently before
starting the next. Use one focused validation per slice, one full suite after
[SUBF-0098](../../../docs/features/FEAT-0051-v0150-recurrence-prevention-modular-test-harness/README.md#subf-0098),
and one bounded confirmation scan.
