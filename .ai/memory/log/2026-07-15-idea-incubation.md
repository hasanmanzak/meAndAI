# 2026-07-15 - Repository-Native Idea Incubation

## Scope

- Feature: [FEAT-0008](../../../docs/features/FEAT-0008-idea-incubation/README.md)
- Decision: [DEC-0009](../../../docs/decisions/DEC-0009-repository-native-idea-incubation.md)
- Tracking: [issue #26](https://github.com/hasanmanzak/meAndAI/issues/26)
- Delivery: [pull request #28](https://github.com/hasanmanzak/meAndAI/pull/28)
- Target release: `v0.7.0`

## Durable facts

- `IDEA-NNNN` preserves a worthwhile possibility but is not authorized work and
  does not satisfy Definition of Ready.
- Idea records live under `docs/ideas` with `Exploring`, `Parked`, `Promoted`,
  or `Rejected` status and remain in history after a terminal outcome.
- Promotion creates bidirectional links to an `EPIC`, `FEAT`, `TASK`, or `DEC`;
  the promoted record independently passes normal delivery gates.
- Consumers use the template from their immutable protocol pin. New
  collision-free submodule adoption receives only an absent idea index;
  existing consumer content is never overwritten or updater-managed.
- [IDEA-0001](../../../docs/ideas/IDEA-0001-role-based-multi-agent-protocol.md)
  parks the role-based multi-agent possibility without implementing it.

## Verification contract

- [TEST-0043](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md#test-0043) covers lifecycle, index, template, and first-idea semantics.
- [TEST-0044](../../../docs/features/FEAT-0008-idea-incubation/test-cases.md#test-0044) covers consumer source access, absent-only bootstrap, collision
  preservation, and updater managed-path non-expansion.

## Release evidence

[Pull request #28](https://github.com/hasanmanzak/meAndAI/pull/28) merged at [`1b420322058d73a974ccb61d8b7f828eb38cce8e`](https://github.com/hasanmanzak/meAndAI/commit/1b420322058d73a974ccb61d8b7f828eb38cce8e),
and annotated tag
[`v0.7.0`](https://github.com/hasanmanzak/meAndAI/tree/v0.7.0) resolves to that
exact release commit. [FEAT-0008](../../../docs/features/FEAT-0008-idea-incubation/README.md) is complete.
