# FEAT-0069 - Bounded Instruction-Graph Capacity Revision

| Field | Value |
| --- | --- |
| Classification | Backward-compatible prospective capacity revision |
| Status | Local verification complete; exact-head hosted gate pending |
| Target version | 0.17.0 |
| Issue | [#175](https://github.com/hasanmanzak/meAndAI/issues/175) |
| Pull request | [#174](https://github.com/hasanmanzak/meAndAI/pull/174) |
| Decision | [DEC-0036](../../decisions/DEC-0036-prospective-instruction-graph-capacity.md) |
| Test | [TEST-0223](test-cases.md#test-0223) |

## Problem and outcome

The exact self-consumer graph is accepted but has reached `4,096/4,096` edges
and `4,192,113/4,194,304` aggregate parsed bytes. A bounded audit found no
remaining low-risk duplicate-owner compaction large enough to fund the next
defined delivery. The feature introduces one prospective schema-2 profile with
`8,192` edges and `8,388,608` aggregate parsed bytes while preserving every
immutable target profile through `v0.16.0`.

## Scope

- Update the canonical bootstrap policy's current edge and aggregate ceilings.
- Make aggregate capacity target-profile-owned alongside schema, blob, node,
  edge, and path limits.
- Add exact `v0.17.0` profile selection without broad future-tag acceptance.
- Prove current values, digest participation, edge and aggregate `N/N+1`, old
  target compatibility, unsupported gaps, and the ordinary self-consumer graph.
- Synchronize the decision, feature/test registries, project memory, issue, and
  draft pull request.

## Non-goals

- No graph grammar, schema, role, reason, projection, or mutation-authority change.
- No increase to node, depth, tree, path, or per-blob ceilings.
- No ContractSlice activation, workflow filter, runtime-efficiency scenario,
  B/C/D implementation, merge, release, or publication.
- No consumer mutation or named-consumer fixture.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0317` <a name="risk-0317"></a> | A current-only constant silently reinterprets an immutable target | Initial-adoption maintainers / exact per-tag profile table and old-policy fixtures in [TEST-0223](test-cases.md#test-0223) |
| `RISK-0318` <a name="risk-0318"></a> | A larger envelope causes unbounded resource use | Graph-policy owner / retain finite inclusive limits, exact N/N+1, and supported-host validation |
| `RISK-0319` <a name="risk-0319"></a> | Only one actor or identity surface receives the new values | Graph-policy owner / one exported policy plus release-profile validation, digest, quick/hosted, and self-consumer evidence |
| `RISK-0320` <a name="risk-0320"></a> | Capacity work accidentally activates the parent ContractSlice scenario | Parent-feature owner / empty activation/workflow allowlist and explicit held boundary |

## Decomposition and review gate

| ID | Slice | Test | Review gate | Status |
| --- | --- | --- | --- | --- |
| `SUBF-0155` <a name="subf-0155"></a> | Prospective edge and aggregate capacity with immutable target profiles | [TEST-0223](test-cases.md#test-0223) | Exact current/legacy limits, N/N+1, digest, actor parity, self-consumer graph, and no activation delta agree | Local verification complete; exact-head hosted gate pending |

## Definition of Ready

- [x] Stable feature, subfeature, decision, issue, risk, and test identities exist.
- [x] Exact saturated baseline and intended prospective profile are recorded.
- [x] Canonical owner and all release-profile/consumer compatibility surfaces are inventoried.
- [x] Scope, non-goals, acceptance criteria, risks, test-first route, and review gate are explicit.
- [x] The maintainer approved completion of the bounded capacity revision on 2026-08-09.

## Design review

The pre-implementation source-to-consumer review closed `0 Blocking / 0
Important / 0 Minor`. The canonical bootstrap module remains the sole policy
owner; aggregate capacity becomes an exact target-profile field; immutable
profiles remain explicit; existing serializer/validator/digest surfaces already
carry both limits; and the activation/workflow mutation set is empty.

## Acceptance criteria

1. The current policy reports schema `2`, edges `8,192`, and aggregate parsed
   bytes `8,388,608`; all unrelated limits are byte-for-byte semantically stable.
2. Exact edge and aggregate boundaries pass; one-over fails closed before mutation.
3. The graph digest changes when either revised limit changes.
4. Exact target profiles through `v0.16.0` remain unchanged; `v0.17.0` selects
   the new pair; gaps, unknown, and cross-major future tags fail closed.
5. The exact meAndAI tree passes as an ordinary consumer without name bypass.
6. Focused graph and target-policy tests, StructureOnly, relevant full validation,
   fresh-diff review, and hosted stable jobs pass.

## Definition of Done

- [x] [TEST-0223](test-cases.md#test-0223) expected-red and focused-green evidence are recorded.
- [x] Focused compatibility, StructureOnly, and publication-evidence gates pass.
- [ ] The exact-head hosted stable jobs pass.
- [x] Fresh-diff code/test and content/scope reviews closed `0/0/0`.
- [x] Decision, registries, and project memory are synchronized.
- [ ] The exact feature commit is pushed and the issue/draft PR are synchronized;
      merge/release/publication remain separate.
