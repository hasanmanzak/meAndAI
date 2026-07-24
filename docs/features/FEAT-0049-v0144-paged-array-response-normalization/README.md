# FEAT-0049 - Paged GitHub Array Response Normalization

| Field | Value |
| --- | --- |
| Classification | Backward-compatible runtime-shape correction / [BUG-0032](https://github.com/hasanmanzak/meAndAI/issues/119) |
| Status | Complete |
| Target version | 0.14.4 |
| Issue | [#119](https://github.com/hasanmanzak/meAndAI/issues/119) |
| Pull request | Pending |
| Decisions | Reuses [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md) and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md); no new architecture |
| Tests | [TEST-0181](test-cases.md#test-0181) |

## Problem and outcome

The shared API-2026 merge-event resolver delivered by
[FEAT-0048](../FEAT-0048-v0143-shared-merge-evidence/README.md) is correct, but
the dedicated immutable `v0.14.3` publication gate failed in
[run 30117735612](https://github.com/hasanmanzak/meAndAI/actions/runs/30117735612).
PowerShell `Invoke-RestMethod` emits a top-level JSON array as one unenumerated
`System.Object[]` pipeline object. `Invoke-GitHubPagedGet` directly wrapped the
transport invocation in `@(...)`, so it retained one nested array instead of
the page items. The existing mock enumerated its return values and concealed
that runtime boundary.

The outcome is one local-variable response boundary in the existing pagination
helper. Assignment captures the transport response; the following `@($response)`
enumerates the actual page items. The test double must emit the same
unenumerated top-level array shape as real `Invoke-RestMethod`.

## Prior-art and current-main classification

- Classification: `RuntimeShapeGap`, not a new merge-evidence or pagination
  design.
- Canonical resolver: [FEAT-0048](../FEAT-0048-v0143-shared-merge-evidence/README.md)
  / [BUG-0031](https://github.com/hasanmanzak/meAndAI/issues/117).
- Original finalization contract: [FEAT-0038](../FEAT-0038-v0127-api-safe-merge-finalization/README.md)
  / [issue #96](https://github.com/hasanmanzak/meAndAI/issues/96).
- Owning layer: common publication transport and its project-neutral fixture;
  no consumer change is authorized.

## Scope

- Normalize the existing paged GitHub transport response after one explicit
  local assignment.
- Make the publication fixture reproduce the unenumerated top-level array
  returned by real PowerShell `Invoke-RestMethod`.
- Publish immutable `v0.14.4`, then rerun the `v0.14.3` and `v0.14.2`
  publication gates with current verifier authority.

## Non-goals

- No resolver, updater, API-version, workflow-job, or release-asset topology
  change.
- No named-consumer file or fixture.
- No broad test-harness or pagination refactor.
- No mutation of immutable historical releases.

## Risks

| ID | Risk | Owner / response |
| --- | --- | --- |
| `RISK-0224` <a name="risk-0224"></a> | A test double enumerates transport output differently from real PowerShell and hides another adapter defect | Protocol maintainers / require [TEST-0181](test-cases.md#test-0181) to emit one unenumerated top-level `System.Object[]` and exercise the real verifier boundary |
| `RISK-0225` <a name="risk-0225"></a> | Response normalization weakens pagination bounds or null filtering | Protocol maintainers / change only the response-assignment boundary and retain exact page-limit, termination, and negative evidence coverage |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0093` <a name="subf-0093"></a> | Normalize paged array response shape and correct fixture fidelity | [Issue #119](https://github.com/hasanmanzak/meAndAI/issues/119) | [TEST-0181](test-cases.md#test-0181) and existing [TEST-0180](../FEAT-0048-v0143-shared-merge-evidence/test-cases.md#test-0180) | Real and mocked transport shapes exercise the same bounded pagination path | Complete |

## Definition of Ready

- [x] Stable feature, bug, subfeature, test, risk, finding, and issue identities
      are assigned and linked.
- [x] The failed hosted run and a local real-transport reproduction establish
      the exact runtime shape before implementation.
- [x] Prior art classifies the work as a common transport propagation gap; no
      duplicate resolver or consumer patch is authorized.
- [x] Scope, non-goals, compatibility boundary, one reviewable slice, risks,
      acceptance criteria, test intent, and release placement are explicit.
- [x] Existing accepted decisions cover the correction; no new decision record
      is required.

## Acceptance criteria

1. One real top-level GitHub JSON array becomes its exact page items before
   pagination termination and resolver selection.
2. Missing, duplicate, malformed, wrong-commit, page-two, null-filtering, and
   bounded-pagination behavior remains fail closed and unchanged.
3. The project-neutral fixture emits one unenumerated `System.Object[]` so the
   pre-fix verifier fails and the corrected verifier passes on PowerShell 7 and
   Windows PowerShell 5.1.
4. No common behavior is copied to a consumer and no unrelated test-harness
   refactor enters the patch.
5. Immutable `v0.14.4` publication evidence passes; current verifier authority
   then closes the retained `v0.14.3` and `v0.14.2` publication evidence.

## Self-review

The bounded implementation review found no unresolved blocking item:

- the production change is limited to assigning one transport response before
  enumerating its exact page items;
- the fixture emits one unenumerated `System.Object[]`, so the test-first tree
  failed at the same boundary as the hosted run;
- page-two success, `null` filtering, missing, duplicate, malformed, wrong-
  commit, and 100-page overflow evidence all pass through the real verifier
  entry point;
- the shared resolver, consumer updater, API version, workflow jobs, release
  assets, and named consumers are unchanged;
- independent review found stale managed-template pins and missing declared
  edge coverage; both were corrected within [TEST-0181](test-cases.md#test-0181)
  without widening the architecture.

## Definition of Done

- [x] [TEST-0181](test-cases.md#test-0181) and existing publication scenarios
      pass on PowerShell 7 and Windows PowerShell 5.1; bounded aggregate gates
      retain their separate delivery evidence.
- [x] Fresh-diff self-review has no unresolved blocking finding.
- [x] Version, changelog, feature index, project memory, and delivery issue are
      current and correctly linked before publication.

## Post-merge publication closure

- Publish one reviewed pull request and immutable `v0.14.4` release under
  [issue #119](https://github.com/hasanmanzak/meAndAI/issues/119).
- Run exact `v0.14.4` publication evidence, then rerun retained `v0.14.3` and
  `v0.14.2` evidence with current verifier authority.
- Close linked issues only after their exact gates pass, then remove only the
  exact owned delivery branch.
