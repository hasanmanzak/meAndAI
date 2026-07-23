# FEAT-0046 - Consumer Non-Duplication Mandate

| Field | Value |
| --- | --- |
| Classification | Backward-compatible protocol correction / `BUG-0028` |
| Status | Complete |
| Target version | 0.14.1 |
| Issue | [#112](https://github.com/hasanmanzak/meAndAI/issues/112) |
| Pull request | To be recorded in [issue #112](https://github.com/hasanmanzak/meAndAI/issues/112) |
| Decisions | [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md) |
| Tests | [TEST-0174](test-cases.md) |

## Problem and outcome

The upstream-ownership rule assigns reusable corrections to meAndAI but does
not explicitly prohibit a consumer from recreating protocol-provided tests,
fixtures, validators, workflows, templates, or other reusable assets. That
ambiguity can place common adoption machinery and its regression evidence in
an otherwise product-empty consumer.

The outcome is one explicit single-owner rule: consumers reuse or reference
protocol-provided assets through their pinned integration. They contain only
genuinely project-specific integration, configuration, domain behavior, and
semantic evidence. Missing or defective common behavior and its generic
regression are corrected once in meAndAI and published before consumer recovery.

## Scope

- Strengthen `PROTOCOL.md`, repository instructions, and DEC-0028 with the
  explicit non-duplication boundary.
- Add one focused structural scenario to the existing protocol-governance
  suite.
- Publish the clarification as immutable patch release `v0.14.1`.
- Correct current release and project-memory facts for completed `v0.14.0`.

## Non-goals

- Mutate any consumer repository or semantic review pull request.
- Add a workflow, validator framework, bootstrapper, or new test suite.
- Reimplement an existing protocol asset under a different consumer path.
- Change consumer domain ownership or permit automatic semantic edits.

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0211` | Ownership ambiguity | A renamed or slightly adapted protocol asset is treated as project-specific | Protocol maintainers / prohibit copy, reimplementation, port, shadow, fork, and consumer-local equivalent forms |
| `RISK-0212` | Consumer overreach | Common correction work mutates a named consumer before an upstream release exists | Protocol maintainers / require upstream issue, project-neutral regression, correction, and immutable release first |

## Decomposition and gate

| ID | Slice | Tracking | Tests | Review gate | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0088` | Explicit single-owner reusable-asset mandate | [Issue #112](https://github.com/hasanmanzak/meAndAI/issues/112) | [TEST-0174](test-cases.md) | Protocol, DEC, local instruction, version, and memory agree; no consumer mutation | Complete |

## Definition of Ready

- [x] `BUG-0028`, `FEAT-0046`, `SUBF-0088`, `TEST-0174`, and risks exist.
- [x] Issue #112 is the delivery authority.
- [x] Problem, outcome, scope, non-goals, ownership, and compatibility are explicit.
- [x] DEC-0028 remains the architectural authority; no new decision is needed.
- [x] One focused existing-suite scenario owns the normative regression.

## Acceptance criteria

1. The protocol enumerates reusable assets and prohibits their consumer-local
   copy, reimplementation, port, shadow, fork, equivalent, or generic retest.
2. Consumers reuse or reference the pinned authority and retain only genuinely
   project-specific integration, configuration, domain behavior, and semantic
   evidence.
3. Missing, defective, or insufficient common behavior and its regression are
   corrected in meAndAI and published before bounded consumer recovery.
4. Only an exact release-declared managed projection required by the consumer
   execution platform may reside at one canonical consumer path; its immutable
   release source, target, digest/blob, and lifecycle remain declared and owned
   by meAndAI, deterministic protocol automation alone installs or updates it,
   and it grants no test/fixture exception.
5. Repository-local instructions repeat the rule for work performed in meAndAI.
6. TEST-0174 fails without the mandate and passes after the smallest coherent
   protocol, decision, and instruction change.
7. No consumer repository, workflow, branch, pull request, fixture, or test is
   changed by this feature.

## Definition of Done

- [x] Acceptance criteria and TEST-0174 pass.
- [x] Focused verification evidence is recorded; final structure verification
  is the publication gate.
- [x] One bounded fresh-diff review has no unresolved `Blocking` finding.
- [x] Version, changelog, feature links, and project memory are current.
- [x] Issue #112 owns the PR, merge, immutable release, two-asset, verification,
  and branch-cleanup evidence that can exist only after this tree is merged.

## Self-review

| Finding | Severity | Disposition | Resolution |
| --- | --- | --- | --- |
| `FIND-0205` | Blocking | Resolved | The initial categorical prohibition and legacy `consumer-owned updater` terminology conflicted with resident workflow hooks. All active updater contracts now call the hook a consumer-resident, protocol-owned managed projection. The exception pins source, target, digest/blob, lifecycle, and deterministic installation; TEST-0174 protects both the positive boundary and absence of the conflicting legacy term. |
| `FIND-0206` | Blocking | Resolved | Feature, subfeature, test, evidence, version, links, and memory completion records were reconciled before publication. |
| `FIND-0207` | Blocking | Resolved | Mechanical current-version propagation collapsed the quick-adoption fixture's current and future same-major releases into one tag. The future node is again `v0.14.2`, and fixture construction now rejects duplicate release identities before attempting a commit. |

## Post-merge release evidence

[Issue #112](https://github.com/hasanmanzak/meAndAI/issues/112) owns the exact
pull request, merged commit, immutable `v0.14.1` release, two runtime assets,
post-publication verification, and branch cleanup. Those external facts are
recorded in the issue when they occur and do not require a post-release rewrite
of this immutable feature tree.
