# FEAT-0055 - UTF-8 Workflow Dispatch

| Field | Value |
| --- | --- |
| Classification | Backward-compatible quick-adoption defect correction / [BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137) |
| Status | Complete |
| Target version | 0.15.4 |
| Bug | [BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137) / [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) |
| Pull request | Pending |
| Decisions | [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md), [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md) |
| Tests | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153); [feature evidence](test-cases.md) |

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

The project recurrence registry contained a related multiline native-argument
hazard, and the historical
[v0.13.1 Windows stdin correction](../../../.ai/memory/log/2026-07-23-v0131-hosted-windows-stdin-encoding-correction.md)
already proved UTF-8/no-BOM framing for repository-owned batch transports. No
entry covered structured `gh workflow run` input maps. The exact workflow-
dispatch match was therefore `None`, while UTF-8 framing was a sibling match;
this feature promotes both into one active, applicability-scoped recurrence
route without duplicating their executable owners.

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
| `SUBF-0106` <a name="subf-0106"></a> | Exact UTF-8 JSON workflow dispatch | [Issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) | Existing [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) expected red, focused PS5.1/7 green, and full-launcher lifecycle green | Input type, Unicode bytes, encoding restoration, older-target omission, and shared mock reviewed | Implemented |

## Findings

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0305` <a name="find-0305"></a> | Launcher correctness / P1 | Structured graph JSON crosses the native argument boundary through `--field` and can lose JSON quotation marks. | `Resolved` in [SUBF-0106](#subf-0106): one typed outer input map crosses UTF-8 stdin with `--json`; graph-aware/current and graph-unaware/legacy variants pass. |
| `FIND-0306` <a name="find-0306"></a> | Governance / P1 | The first structural review grouped an escaped prior-version fixture, incomplete current-feature status, noncanonical visible record links, and the missing BUG-to-issue registry mapping into derivative diagnostics. | `Resolved` at the common owners: current/future tags are `v0.15.4`/`v0.15.5`, every visible record uses its canonical clickable target, [BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137) maps once to [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137), and the final StructureOnly gate passes. |
| `FIND-0307` <a name="find-0307"></a> | Delivery lifecycle / P1 | Independent diff review found that the first record mixed merge, release, and branch cleanup into the pre-merge acceptance/DoD boundary. | `Resolved`: the current-release projection remains `Complete` as required by [TEST-0092](../FEAT-0014-v085-convergence/test-cases.md#test-0092), pre-merge DoD contains only candidate/review gates, and publication plus cleanup are a separate post-merge gate with external evidence. |
| `FIND-0308` <a name="find-0308"></a> | Test operation ownership / P1 | The first canonical full-suite attempt found that the new negative-dispatch fixture invoked a reusable JSON builder through an unreviewed scriptblock identity, increasing the [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) dynamic-operation inventory from 31 to 32. | `Resolved` without expanding the operation budget: the builder is a directly invoked modular test helper; focused TEST-0158/0159/0162 and the final canonical suite pass. |

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0247` <a name="risk-0247"></a> | Nested graph JSON is dispatched as an object rather than the workflow's required string input. | Launcher owner / serialize the graph once as a string value inside the outer input object and assert exact type and bytes. |
| `RISK-0248` <a name="risk-0248"></a> | PowerShell 5.1 adds a BOM or uses a legacy code page that corrupts non-ASCII graph paths. | Native-process owner / explicit UTF-8 without BOM, strict byte round-trip evidence on PS5.1 and PS7, and encoding restoration. |
| `RISK-0249` <a name="risk-0249"></a> | Older graph-unaware workflows receive an undeclared input or lose a required input. | Lifecycle owner / retain immutable-target input detection and assert the exact legacy/current property sets in [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153). |

## Definition of Ready

- [x] Stable feature [FEAT-0055](README.md), bug [BUG-0035](https://github.com/hasanmanzak/meAndAI/issues/137), subfeature [SUBF-0106](#subf-0106),
  finding `FIND-0305`, and [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137) assigned.
- [x] Problem, outcome, scope, non-goals, immutable baseline, ownership,
  compatibility, failure behavior, and risks recorded.
- [x] Canonical production owners are `Invoke-LifecycleWorkflow` and
  `Invoke-External`; no sibling or consumer implementation is permitted.
- [x] Existing scenario review classifies the new evidence as a
  `ParameterizedVariant` of [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153), not a duplicate test.
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
7. Documentation, project memory, version surfaces, canonical issue/PR links,
   and the external post-publication authority are current before merge.

## Definition of Done

- [x] [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) records expected-red evidence against the v0.15.3 behavior.
- [x] Focused [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) passes on Windows PowerShell 5.1 and PowerShell 7.
- [x] One final relevant owner passes on the final candidate tree.
- [x] One canonical full suite passes.
- [x] Bounded diff/self-review has no unresolved `Blocking` finding.
- [x] Protocol, version, changelog, feature, test, memory, and issue/PR links are current.
- [ ] Applicable PR review and hosted pre-merge gates pass.

## Post-merge release gate

- Publish immutable `v0.15.4` for the exact merged commit with the two
  [DEC-0023](../../decisions/DEC-0023-verified-quick-adoption-module-bundle.md)
  assets.
- Run the current-authority post-publication verifier and record exact evidence
  in [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137).
- Close only [issue #137](https://github.com/hasanmanzak/meAndAI/issues/137)
  and remove only the exact owned branch after all release checks pass.

## Delivery evidence

| Field | Evidence |
| --- | --- |
| Expected-red | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) failed as expected in 1.3 seconds against the v0.15.3 transport. |
| Focused PS5.1 / PS7 | [TEST-0153](../FEAT-0037-v0126-instruction-graph-adoption-containment/test-cases.md#test-0153) passed in 3.7 / 3.2 seconds; TEST-0158/0159/0162 passed in 6.8 seconds after [FIND-0308](#find-0308). |
| Final local suite | `tests/protocol.tests.ps1` passed all discovered suites in 1,957.8 seconds. |
| Pull request | Pending |
| Hosted validation | Pending |
| Release | Pending immutable `v0.15.4` |
| Branch cleanup | Pending |
