# FEAT-0055 - UTF-8 Workflow Dispatch

| Field | Value |
| --- | --- |
| Classification | Backward-compatible quick-adoption defect correction |
| Status | In progress |
| Target version | 0.15.4 |
| Bug | `BUG-0035` / [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) |
| Pull request | Pending |
| Decisions | [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0153 dispatch variants and evidence](test-cases.md) |

## Problem

The Windows quick-adoption launcher supplies the compact instruction-graph
identity to `gh workflow run` as a native `--field key=value` argument. Native
argument transport can remove the JSON quotation marks before the value reaches
the workflow input, so the capability bootstrap correctly rejects the received
text as invalid JSON. This strands fresh adoption even though the graph was
valid at the launcher's committed-base boundary.

## Outcome

The launcher sends every workflow input as one JSON document over UTF-8 stdin
with `gh workflow run --json`. The graph identity remains a JSON string input,
round-trips exactly, and remains optional when the immutable target workflow
does not declare that input.

## Immutable baseline

- Release: [v0.15.3](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.3).
- Commit: [`164543d`](https://github.com/hasanmanzak/meAndAI/commit/164543d939ef97ec02d96499d3e5b796eed64470).
- Failing boundary: graph-aware workflow dispatch receives syntactically
  invalid JSON after native argument parsing.
- Existing canonical owner: [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153).

## Ownership and prior-art review

This is reusable launcher behavior owned by meAndAI. No consumer code, fixture,
test, or workaround is in scope. [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md)
already owns graph identity and older-target compatibility; [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
already owns the immutable modular runtime. No new architectural decision or
scenario identity is required.

The project recurrence registry contains related native-argument hazards, but
no entry whose applicability is structured `gh workflow run` input transport.
The exact-match recurrence result is therefore `None`; this feature adds the
confirmed transport signature and prevention rule after the regression passes.

## Scope

- Extend the existing [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153)
  owner before production changes.
- Serialize the complete workflow input map once and pass it through stdin with
  `--json`.
- Make stdin encoding explicitly UTF-8 without BOM under Windows PowerShell 5.1
  and PowerShell 7, restoring the caller's encoding afterward.
- Preserve graph-aware feature detection, required input values, fail-closed
  external command handling, and immutable release packaging.
- Publish the correction as immutable `v0.15.4`.

## Non-goals

- No named-consumer knowledge, recovery mutation, or consumer-local test.
- No new workflow, job, process abstraction, graph schema, or numbered test.
- No change to remote planning, migration semantics, committed-base integrity,
  staged/result verification, or managed merge finalization.
- No unrelated refactor, runtime optimization, or full-suite hardening cycle.

## Decomposition and review gate

| ID | Slice | Tracking | Test | Review state | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0106` <a name="subf-0106"></a> | Exact UTF-8 JSON workflow dispatch | [Issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) | Existing [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) expected red, then focused PS5.1/7 green | Pending | In progress |

## Findings

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0305` <a name="find-0305"></a> | Launcher correctness / P1 | Structured graph JSON crosses the native argument boundary through `--field` and can lose JSON quotation marks. | `Blocking`; resolve in [SUBF-0106](#subf-0106) with one UTF-8 JSON stdin payload and exact regression evidence. |

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0247` <a name="risk-0247"></a> | Nested graph JSON is dispatched as an object rather than the workflow's required string input. | Launcher owner / serialize the graph once as a string value inside the outer input object and assert exact type and bytes. |
| `RISK-0248` <a name="risk-0248"></a> | PowerShell 5.1 adds a BOM or uses a legacy code page that corrupts non-ASCII graph paths. | Native-process owner / explicit UTF-8 without BOM, strict byte round-trip evidence on PS5.1 and PS7, and encoding restoration. |
| `RISK-0249` <a name="risk-0249"></a> | Older graph-unaware workflows receive an undeclared input or lose a required input. | Lifecycle owner / retain immutable-target input detection and assert the exact legacy/current property sets in TEST-0153. |

## Definition of Ready

- [x] Stable feature `FEAT-0055`, bug `BUG-0035`, subfeature `SUBF-0106`,
  finding `FIND-0305`, and [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) assigned.
- [x] Problem, outcome, scope, non-goals, immutable baseline, ownership,
  compatibility, failure behavior, and risks recorded.
- [x] Canonical production owners are `Invoke-LifecycleWorkflow` and
  `Invoke-External`; no sibling or consumer implementation is permitted.
- [x] Existing scenario review classifies the new evidence as a
  `ParameterizedVariant` of TEST-0153, not a duplicate test.
- [x] Test-first red, focused PS5.1/7 green, one final relevant suite, one full
  suite, hosted validation, immutable release, and branch cleanup are defined.
- [x] Maintainer approval to implement the upstream correction was received on
  2026-07-26.

## Acceptance criteria

1. Workflow dispatch uses `gh workflow run --json` and supplies one compact
   outer JSON document through stdin; no structured value uses `--field` or
   `--raw-field`.
2. Every required lifecycle input remains an exact string value.
3. A graph-aware target receives `source_graph_identity` as the exact compact
   nested JSON string, including non-ASCII content.
4. A graph-unaware target omits only `source_graph_identity`.
5. UTF-8 input has no BOM, round-trips under PS5.1 and PS7, and does not leak a
   changed process encoding after invocation.
6. Existing committed-base, integrity, compatibility, recovery, packaging, and
   immutable-release behavior remains green.
7. Documentation, project memory, issue/PR links, hosted evidence, release
   assets, and exact owned-branch cleanup close `0.15.4`.

## Definition of Done

- [ ] TEST-0153 records expected-red evidence against the v0.15.3 behavior.
- [ ] Focused TEST-0153 passes on Windows PowerShell 5.1 and PowerShell 7.
- [ ] One final relevant owner and one canonical full suite pass.
- [ ] Bounded diff/self-review has no unresolved `Blocking` finding.
- [ ] Protocol, version, changelog, feature, test, memory, and release links are current.
- [ ] PR and hosted gates pass; exact merged commit is released as `v0.15.4`.
- [ ] Issue is closed and the exact owned branch is absent locally and remotely.

## Delivery evidence

| Field | Evidence |
| --- | --- |
| Expected-red | Pending |
| Focused PS5.1 / PS7 | Pending |
| Final local suite | Pending |
| Pull request | Pending |
| Hosted validation | Pending |
| Release | Pending immutable `v0.15.4` |
| Branch cleanup | Pending |
