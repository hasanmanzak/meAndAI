# FEAT-0045 - Canonical Repository Evidence and Upstream-Owned Corrections

| Field | Value |
| --- | --- |
| Classification | Backward-compatible semantic capability / [BUG-0027](https://github.com/hasanmanzak/meAndAI/issues/110) |
| Status | Complete |
| Target version | 0.14.0 |
| Issue | [#110](https://github.com/hasanmanzak/meAndAI/issues/110) |
| Pull request | Pending |
| Decisions | [DEC-0018](../../decisions/DEC-0018-release-declared-consumer-migrations.md), [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md), [DEC-0024](../../decisions/DEC-0024-exact-instruction-graph-adoption-evidence.md), and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md) |
| Tests | [TEST-0171](test-cases.md#test-0171), [TEST-0172](test-cases.md#test-0172), and [TEST-0173](test-cases.md#test-0173) |

## Problem

A byte-strict validator can mistake checkout-filtered worktree bytes for the
canonical committed bytes even when Git reports the path clean. On Windows
with `core.autocrlf=true`, a committed LF JSON blob may therefore be presented
as CRLF in the worktree and rejected by the strict parser. Implementing the Git
reader in one consumer would duplicate common logic and leave other consumers
exposed.

## Outcome

Provide one common, binary-safe repository-evidence boundary; use it in the
production capability-review runner; declare the reusable rule as an
append-only Semantic capability; and require shared defects to be corrected at
their common upstream authority.

## Scope

- Resolve clean HEAD, staged-only index, and unstaged/untracked worktree bytes
  without normalization.
- Fail closed for ambiguous, conflicting, linked, escaping, deleted,
  renamed/copied, or non-regular state.
- Replace the production runner's clean-ledger worktree read with exact bytes
  from its already verified default-branch HEAD.
- Append `canonical-repository-evidence` without changing either released
  capability definition or tuple.
- Preserve semantic consumer ownership: automation requests review but does
  not rewrite consumer-owned validation logic.
- Add the common and repository-local upstream-ownership mandates.
- Use anonymous local Git fixtures only.

## Non-goals

- Consumer-specific paths, fixtures, commits, domain facts, or recovery code.
- Relaxing strict UTF-8, LF, catalog, or ledger validation.
- Automatic semantic edits, approvals, ready transitions, or merges.
- A new workflow, hosted job, service, GitHub App, or validation framework.
- Scanning or mutating unrelated consumers.

## Readiness evidence

- Domain and contracts: [DEC-0022](../../decisions/DEC-0022-release-declared-semantic-capabilities.md) owns append-only semantic review; [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md)
  owns upstream correction and byte-source authority.
- Dependencies: Git regular blobs, stage-zero index, contained ordinary
  worktree files, the existing strict capability parser, and the existing
  capability-review runner.
- Compatibility: the first two catalog tuples remain byte-identical; a two-
  entry terminal ledger remains a valid prefix and exposes only the new suffix.
- Risks: `RISK-0207` through `RISK-0210` below.
- Verification: three scenarios in existing suites, one bounded diff review,
  one structural run, one final relevant validation, and immutable publication.

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0171](test-cases.md#test-0171), [TEST-0172](test-cases.md#test-0172), and [TEST-0173](test-cases.md#test-0173) |
| Test code | Implemented in existing capability owners | [TEST-0171](test-cases.md#test-0171), [TEST-0172](test-cases.md#test-0172), and [TEST-0173](test-cases.md#test-0173) retain one executable owner each; no new suite or process |
| Baseline run | Failed as intended | The original production runner selected transformed worktree bytes for a Git-clean terminal ledger; the focused [TEST-0171](test-cases.md#test-0171) fixture reproduced that boundary |

## Risks

| ID | Classification | Risk | Owner / response |
| --- | --- | --- | --- |
| `RISK-0207` <a name="risk-0207"></a> | Evidence integrity | Newline normalization hides genuine noncanonical bytes | Repository-evidence owner / preserve exact bytes and prove strict rejection |
| `RISK-0208` <a name="risk-0208"></a> | Compatibility | A released capability tuple or terminal-prefix rule is rewritten | Catalog owner / append one new immutable tuple and test two-entry prefix behavior |
| `RISK-0209` <a name="risk-0209"></a> | Ownership | Common automation gains authority over semantic consumer files | Capability lifecycle owner / review-only handoff remains mandatory |
| `RISK-0210` <a name="risk-0210"></a> | Coupling | A named-consumer workaround is mistaken for generic closure | Protocol maintainer / upstream mandate and anonymous fixture gate |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0085` <a name="subf-0085"></a> | Upstream-ownership mandate and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md) | [Issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) | [TEST-0173](test-cases.md#test-0173); project-neutral artifact assertions passed | The mandate is common plus local, grants no consumer mutation authority, and rejects named-consumer canonical artifacts | Complete |
| `SUBF-0086` <a name="subf-0086"></a> | Shared canonical Git/index/worktree byte resolver and production integration | [Issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) | [TEST-0171](test-cases.md#test-0171); focused capability-catalog owner passed | Review found one non-Git injected-fixture compatibility blocker; the existing runtime seam now injects repository evidence while production still uses the shared resolver | Complete |
| `SUBF-0087` <a name="subf-0087"></a> | Append-only semantic capability and predecessor-ledger lifecycle | [Issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) | [TEST-0172](test-cases.md#test-0172); capability-review owner passed in 14.1 seconds | First two immutable tuples remain exact; only the appended suffix is reviewable and complete ledgers no-op | Complete |

## Definition of Ready

- [x] [BUG-0027](https://github.com/hasanmanzak/meAndAI/issues/110), `FEAT-0045`, `SUBF-0085` through `SUBF-0087`, and [issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) exist.
- [x] Problem, outcome, scope, non-goals, authority matrix, and semantic ownership are explicit.
- [x] Consumers, dependencies, compatibility, and immutable-prefix boundaries are known.
- [x] `RISK-0207` through `RISK-0210` and [DEC-0028](../../decisions/DEC-0028-upstream-owned-reusable-corrections.md) are recorded.
- [x] Independently testable slices and their gate ledger are defined.
- [x] [TEST-0171](test-cases.md#test-0171), [TEST-0172](test-cases.md#test-0172), and [TEST-0173](test-cases.md#test-0173) and the bounded verification approach are defined.

## Acceptance criteria

1. A clean tracked file is returned byte-for-byte from the exact requested HEAD
   regular blob, regardless of checkout newline transformation.
2. Staged-only state uses the exact stage-zero index blob; unstaged and
   untracked state uses raw contained worktree bytes; ambiguity fails closed.
3. Genuine CRLF or otherwise noncanonical bytes are not normalized and remain
   rejected by the strict parser.
4. Resolution is read-only, bounded, and idempotent in every supported state.
5. The production capability-review runner reads its clean terminal ledger
   from the already verified default-branch HEAD.
6. The new Semantic capability is appended after the exact two released tuples;
   predecessor ledgers request only the new suffix and complete ledgers no-op.
7. Common and local mandates require reusable defects to close upstream, while
   semantic consumer ownership and unrelated-repository containment remain.
8. No named consumer appears in new canonical code, tests, fixtures, decisions,
   feature records, or capability definitions.

## Verification approach

Create [TEST-0171](test-cases.md#test-0171), [TEST-0172](test-cases.md#test-0172), and [TEST-0173](test-cases.md#test-0173) in existing capability suites before the
production correction. Reproduce the transformed-worktree failure with an
anonymous real Git repository, implement the smallest shared reader and runner
integration, then run the focused owners. Finish with structural validation, a
fresh-diff review, one final relevant suite, and immutable release evidence.

## Self-review

One bounded fresh-diff review covered the repository-evidence module, production
runner integration, injected test seam, immutable capability append, release
projection, documentation, and project-neutrality boundary. The initial
integration run exposed that existing production-path fixtures inject Git but
are not physical Git repositories. The correction keeps production on the
shared resolver and injects repository evidence only through the existing test
runtime boundary; [TEST-0140](../FEAT-0032-general-capability-test-architecture/test-cases.md#test-0140) and [TEST-0172](test-cases.md#test-0172) then passed. [TEST-0171](test-cases.md#test-0171) independently
exercises the real Git implementation. [PR #111](https://github.com/hasanmanzak/meAndAI/pull/111)'s first hosted Windows run then
found that terminating an already completed `git ls-tree` process after a
rename/copy match can raise `Access denied`. The resolver now drains the bounded
process output and returns the already established match without an unnecessary
termination call; focused [TEST-0171](test-cases.md#test-0171) passed again. No duplicated consumer
implementation, named-consumer fixture, hidden normalization, new suite,
workflow, or unresolved `Blocking` finding remains.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Focused and final validation evidence recorded in the test scenarios.
- [x] Bounded self-review complete with no unresolved `Blocking` finding.
- [x] Documentation, version, changelog, links, and memory current for the
      pre-publication tree.

## Post-merge release evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #110](https://github.com/hasanmanzak/meAndAI/issues/110) |
| Pull request | [PR #111](https://github.com/hasanmanzak/meAndAI/pull/111) |
| Release authority | [GitHub release v0.14.0](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.14.0) |
| Release identifier | `v0.14.0` |
| Target commit | [`a2a987b322f5ea8d705ad6c5325cffc662a60978`](https://github.com/hasanmanzak/meAndAI/commit/a2a987b322f5ea8d705ad6c5325cffc662a60978) |
