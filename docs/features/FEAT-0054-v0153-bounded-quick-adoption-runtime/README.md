# FEAT-0054 - Bounded Quick-Adoption Runtime Reduction

| Field | Value |
| --- | --- |
| Classification | Backward-compatible runtime and test-execution optimization |
| Status | Complete |
| Target version | 0.15.3 |
| Issue | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) |
| Parent task | [TASK-0002 / issue #98](https://github.com/hasanmanzak/meAndAI/issues/98) |
| Pull request | Pending |
| Decisions | [DEC-0019](../../decisions/DEC-0019-hosted-runner-efficiency.md), [DEC-0029](../../decisions/DEC-0029-canonical-recurrence-knowledge-and-test-harness-ownership.md), [DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md) |
| Tests | [Test scenarios and evidence](test-cases.md) |

## Problem

The immutable [v0.15.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.2)
baseline retains correct evidence but spends disproportionate Windows time in
the quick-adoption owner. Every successful credential-containment checkpoint
starts five Git processes even though the same two canonical pathspecs can be
queried together. Separately, all seven ordinary GitHub CLI version variants
execute the complete launcher even though five exercise only the production
version parser.

## Outcome

Each existing credential checkpoint remains fail-closed and real-Git backed,
but its successful process count falls from five to three. All seven GitHub CLI
version cases continue to execute the exact production parser, while one
rejected-floor and one accepted-floor representative retain the full launcher
boundary. Deterministic operation counts are authoritative; hosted durations
remain observations.

## Immutable baseline

- Release: [v0.15.2](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.15.2).
- Commit: [`9bc12e3`](https://github.com/hasanmanzak/meAndAI/commit/9bc12e394725a86d29efb745cbdfa26407ffd3d2).
- Hosted run: [protocol validation run 30186941435](https://github.com/hasanmanzak/meAndAI/actions/runs/30186941435).
- Topology: one Ubuntu full job and one Windows PowerShell 5.1 full job.
- Observed job durations: Ubuntu 10m55s and Windows 30m26s.
- Quick-adoption owner observations: 216.519 seconds on Ubuntu and 814.141
  seconds on Windows.
- Exact operation baselines: five Git processes per successful credential
  scan and seven full-launcher executions in the
  [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
  version family.
- Rejected hotspot: fresh module import averaged about 72 milliseconds and is
  not a material target for this feature.

## Scope

- Build the two ordered recursive case-insensitive credential pathspecs once.
- Preserve the shallow-repository check, then use one tracked/staged query and
  one all-ref/reflog history query for both pathspecs.
- Treat an operational tracked-file query failure as a failure, not as absence.
- Preserve every existing containment checkpoint and its ordering.
- Exercise all seven [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
  inputs through the exact private production contract via the existing
  quick-adoption support adapter.
- Retain full-launcher slices for `older` and `exact-floor` only.
- Append two exact closure targets to the existing operation-budget authority.

## Non-goals

- No new numbered scenario, semantic capability, decision, test framework,
  workflow, job, runner, cache, daemon, or consumer asset.
- No removal, caching, or reordering of credential/TOCTOU checkpoints.
- No removal of real-Git reflog, unborn-head, shallow, staged, nested, case, or
  mutation-order evidence.
- No optimization of the other five potential direct-contract call families.
- No reopening of the completed [FEAT-0053](../FEAT-0053-v0152-distinct-test-intent/README.md)
  portfolio review.

## Scenario-intent review

No new identity is created. The seven CLI inputs remain one
`ParameterizedVariant` family under [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107).
[TEST-0055](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0055)
retains the real security/history boundary. [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159)
is the existing `InfrastructureContract` owner for deterministic operation
budgets, and [TEST-0160](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0160)
retains cross-runtime and hosted observations. Their contract, risk, evidence
level, and exercised boundaries are distinct and unchanged.

## Decomposition and review gates

| ID | Slice | Tracking | Tests/run | Review state | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0102` <a name="subf-0102"></a> | Exact-base observation and operation-budget authority | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) | [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) expected red then focused green | Baseline, observer digest, and lower maxima reviewed | Implemented |
| `SUBF-0103` <a name="subf-0103"></a> | Batched credential containment | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) | [TEST-0055](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0055), [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) focused PS5.1/7 green | Every checkpoint remains; combined tracked/history commands reviewed | Implemented |
| `SUBF-0104` <a name="subf-0104"></a> | Direct production version variants with retained vertical slices | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) | [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107), [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159) focused PS5.1/7 green | Exact production invocation and two representative vertical slices reviewed | Implemented |
| `SUBF-0105` <a name="subf-0105"></a> | Cross-runtime, hosted, release, and parent-task closure | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) | [TEST-0160](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0160), final suite and hosted validation | Candidate implementation complete; external delivery evidence remains pending | Implemented |

## Findings

| ID | Classification | Finding | Disposition |
| --- | --- | --- | --- |
| `FIND-0300` <a name="find-0300"></a> | Runtime / P2 | Each successful credential-containment scan starts one shallow check plus two tracked and two history processes for two fixed pathspecs. | `Resolved` in [SUBF-0103](#subf-0103); exact operation evidence is three. |
| `FIND-0301` <a name="find-0301"></a> | Test execution / P2 | Five [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107) parser-only variants repeat the full launcher without adding an integration boundary. | `Resolved` in [SUBF-0104](#subf-0104); all seven direct cases and exactly two full slices pass. |
| `FIND-0302` <a name="find-0302"></a> | Release fixture / P1 | Candidate diff review found that the mechanical current-version propagation also retained the former `v0.15.3` future tag, which would define the same mock tag twice. | `Blocking` / Resolved: every pre-change future-version occurrence was enumerated; the future fixture and newer-installed case now use `v0.15.4`, while current surfaces remain `v0.15.3`. |
| `FIND-0303` <a name="find-0303"></a> | Governance / P1 | The first structural gate grouped stale current-version examples, noncanonical record links, and an incomplete [TEST-0092](../FEAT-0014-v085-convergence/test-cases.md#test-0092) lifecycle status. | `Blocking` / Resolved: current-version surfaces, exact targets, finding declarations, and the pre-merge/post-publication boundary were corrected; the owning governance gate passes. |
| `FIND-0304` <a name="find-0304"></a> | Test architecture / P1 | The final suite proved all runtime owners but the role classifier treated the Support adapter's two named production `Assert-*` calls as test assertions. | `Blocking` / Resolved: the adapter resolves and invokes the same module-private production commands by exact command identity; no test assertion, production logic copy, or role exception is introduced. |

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0242` <a name="risk-0242"></a> | Batching loses one canonical credential name, nesting rule, or case-insensitive pathspec. | Launcher owner / construct both pathspecs from the ordered production mapping and assert the exact command records in [TEST-0159](../FEAT-0039-v0130-test-runtime-efficiency/test-cases.md#test-0159). |
| `RISK-0243` <a name="risk-0243"></a> | A failed tracked-file query is mistaken for an untracked repository. | Launcher owner / use a success-returning output query and fail on any nonzero exit. |
| `RISK-0244` <a name="risk-0244"></a> | Removing repeated scans weakens TOCTOU or mutation ordering. | Launcher owner / do not remove or cache any checkpoint; [TEST-0055](../FEAT-0010-protocol-stability-invariants/test-cases.md#test-0055) retains real-Git failure boundaries. |
| `RISK-0245` <a name="risk-0245"></a> | Direct parser cases copy production logic or stop proving the public boundary. | Test owner / invoke the loaded private production function through the existing support adapter and retain `older` plus `exact-floor` full-launcher slices. |
| `RISK-0246` <a name="risk-0246"></a> | Timing becomes a flaky correctness gate or triggers another unbounded optimization cycle. | Runtime owner / close on exact 5-to-3 and 7-to-2 ratchets; record durations only as observations and leave other families out of scope. |

## Definition of Ready

- [x] Stable feature, parent task, and [issue #135](https://github.com/hasanmanzak/meAndAI/issues/135).
- [x] Immutable baseline commit, release, topology, owner durations, and exact
  operation baselines recorded.
- [x] Production and test-support owners identified; no consumer surface.
- [x] Scope, non-goals, compatibility, risks, and failure behavior explicit.
- [x] Existing scenario identities and nearest-sibling relationships reviewed.
- [x] Lower maxima are exactly three credential Git processes and two
  [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
  full-launcher executions.
- [x] Test-first red, focused checks, one final suite, hosted validation, and
  immutable release path defined.

The maintainer's standing ordered-backlog directive authorizes implementation.

## Acceptance criteria

1. Every successful credential scan executes exactly one shallow, one combined
   tracked/staged, and one combined all-ref/reflog Git query.
2. Both canonical credential basenames remain protected at every depth and case
   variant; shallow, tracked/staged, history, and operational failures fail
   before authentication or mutation.
3. No credential checkpoint is removed, cached, or reordered.
4. All seven [TEST-0107](../FEAT-0021-v096-github-cli-prerequisite/test-cases.md#test-0107)
   inputs invoke the exact production parser; incompatible
   outputs retain upgrade guidance and compatible outputs return successfully.
5. `older` retains full-launcher rejection and `exact-floor` retains continuation
   to target validation; the family executes the full launcher exactly twice.
6. Existing quick-adoption and test-runtime owners emit valid, unique, declared
   operation evidence at or below the new maxima.
7. Focused PowerShell 5.1/7, the final full suite, and the unchanged one-Windows/
   one-Ubuntu hosted topology pass without scenario or evidence loss.
8. Documentation, memory, release surfaces, issue/PR links, immutable assets,
   post-publication evidence, and exact owned-branch cleanup close version
   `0.15.3`.

## Definition of Done

- [x] Candidate acceptance criteria and reused scenario families pass in the
  focused owner gates.
- [x] Exact focused operation observations prove 5-to-3 and 7-to-2 closure.
- [x] Focused PowerShell 5.1/7 and owning structural gates pass; the final
  canonical suite remains the candidate release gate.
- [x] Bounded self-review has no unresolved `Blocking` finding.
- [x] Protocol/version/changelog/feature/test/memory links are current.
- [ ] Applicable CI and review gates passed.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #135](https://github.com/hasanmanzak/meAndAI/issues/135) |
| Release authority | Pending immutable `v0.15.3` publication |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
