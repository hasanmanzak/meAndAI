# FEAT-0069 - Bounded Instruction-Graph Capacity Revision

| Field | Value |
| --- | --- |
| Classification | Backward-compatible prospective capacity revision |
| Status | Prospective edge/aggregate/per-blob capacity `ReviewedHostedGreen`; release/publication held |
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

The completed ContractSlice B repository-tree design then exposed a different
prospective limit before execution: the canonical typed-design blob reached
`525,145/524,288` bytes, and safe compaction left only `2,710` bytes of reserve.
Its first complete Tests-owned wire draft also reached `996` normalized changed
lines against a packet-local `700`-line redraw threshold. The accepted amendment
raises only the prospective per-blob ceiling to `1,048,576` and aligns that
packet with the existing general `1,200`-line micro-delivery ceiling.

## Scope

- Update the canonical bootstrap policy's current edge and aggregate ceilings.
- Update the prospective current per-blob ceiling while preserving every
  immutable target through `v0.16.0`.
- Make aggregate capacity target-profile-owned alongside schema, blob, node,
  edge, and path limits.
- Add exact `v0.17.0` profile selection without broad future-tag acceptance.
- Prove current values, digest participation, edge/per-blob/aggregate `N/N+1`,
  old target compatibility, unsupported gaps, and the ordinary self-consumer graph.
- Synchronize the decision, feature/test registries, project memory, issue, and
  draft pull request.

## Non-goals

- No graph grammar, schema, role, reason, projection, or mutation-authority change.
- No increase to node, depth, tree, or path ceilings.
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
| `RISK-0321` <a name="risk-0321"></a> | A larger single blob causes unbounded parsing or silently changes an older target | Graph-policy owner / exact `1,048,576/1,048,577` evidence, unchanged aggregate ceiling, and explicit `v0.16.0` compatibility |

## Decomposition and review gate

| ID | Slice | Test | Review gate | Status |
| --- | --- | --- | --- | --- |
| `SUBF-0155` <a name="subf-0155"></a> | Prospective edge and aggregate capacity with immutable target profiles | [TEST-0223](test-cases.md#test-0223) | Exact current/legacy limits, N/N+1, digest, actor parity, self-consumer graph, and no activation delta agree | `ReviewedHostedGreen`; immutable target profiles retained |
| `SUBF-0156` <a name="subf-0156"></a> | Prospective per-blob capacity and B-WIRE packet-budget alignment | [TEST-0223](test-cases.md#test-0223) | Exact current/legacy blob limits, N/N+1, digest, actor parity, self-consumer graph, and no semantic-limit expansion agree | `ReviewedHostedGreen`; release/publication held |

## Definition of Ready

- [x] Stable feature, subfeature, decision, issue, risk, and test identities exist.
- [x] Exact saturated baseline and intended prospective profile are recorded.
- [x] Canonical owner and all release-profile/consumer compatibility surfaces are inventoried.
- [x] Scope, non-goals, acceptance criteria, risks, test-first route, and review gate are explicit.
- [x] The maintainer approved completion of the bounded capacity revision on 2026-08-09.
- [x] The maintainer approved the per-blob and B-WIRE packet-budget amendment on 2026-08-09 after exact pre-failure limit observations.

## Design review

The pre-implementation source-to-consumer review closed `0 Blocking / 0
Important / 0 Minor`. The canonical bootstrap module remains the sole policy
owner; aggregate capacity becomes an exact target-profile field; immutable
profiles remain explicit; existing serializer/validator/digest surfaces already
carry both limits; and the activation/workflow mutation set is empty.

The amendment keeps the same schema and owners. Only the prospective current
policy and exact `v0.17.0` target row select `1,048,576`; every older profile
retains its released value. Existing dynamic per-blob `N/N+1`, digest, batch-
actor, quick-adoption, and self-consumer paths remain the proof surface. The
B-WIRE line ceiling changes only a design gate and does not widen wire semantics.

## Acceptance criteria

1. The current policy reports schema `2`, edges `8,192`, per-blob bytes
   `1,048,576`, and aggregate parsed bytes `8,388,608`; all unrelated limits are
   byte-for-byte semantically stable.
2. Exact edge, per-blob, and aggregate boundaries pass; one-over fails closed
   before mutation.
3. The graph digest changes when any revised limit changes.
4. Exact target profiles through `v0.16.0` remain unchanged; `v0.17.0` selects
   the new pair; gaps, unknown, and cross-major future tags fail closed.
5. The exact meAndAI tree passes as an ordinary consumer without name bypass.
6. B-WIRE retains its two-test-file allowlist but uses the general inclusive
   `1,200`-line ceiling; `1,201` requires redesign.
7. Focused graph and target-policy tests, StructureOnly, relevant full validation,
   fresh-diff review, and hosted stable jobs pass.

## Definition of Done

- [x] [TEST-0223](test-cases.md#test-0223) expected-red and focused-green evidence are recorded.
- [x] The per-blob amendment's fresh expected-red and focused-green evidence are recorded.
- [x] Focused compatibility, StructureOnly, and publication-evidence gates pass.
- [x] The amended exact-head hosted stable jobs pass.
- [x] Fresh-diff amendment code/test and content/scope reviews closed `0/0/0`.
- [x] Decision, registries, and project memory are synchronized.
- [x] The exact feature commit is pushed and the issue/draft PR are synchronized;
      merge/release/publication remain separate.
