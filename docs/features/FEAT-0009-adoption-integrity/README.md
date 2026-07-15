# FEAT-0009 - Adoption and Updater Integrity Hardening

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Implemented; release gate pending |
| Target version | 0.7.2 |
| Issue | [#30](https://github.com/hasanmanzak/meAndAI/issues/30) |
| Pull request | [#31](https://github.com/hasanmanzak/meAndAI/pull/31) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The v0.7.1 completion scan found that collision-mode adoption can lack the Git
objects needed to establish the protocol reference, adoption drafts are not
fully bound to canonical ownership metadata, exact protocol-reference
validation is conditional, and renamed unmanaged paths can evade updater path
validation. The same scan found stale release and lifecycle status records and
an increasingly concentrated launcher completion function.

## Outcome

Both collision and full-bootstrap adoption fail closed unless one canonical,
automation-owned draft resolves to the exact manifest protocol commit. The
updater accounts for rename source paths, lifecycle labels reflect real state,
the v0.7.2 contract and release records are current, and the launcher gains
only the narrow internal seams required to keep these checks reviewable.

## Scope

- Resolve `FIND-0066` through `FIND-0073` in priority order.
- Mitigate `FIND-0074` through narrow helper extraction required by the fixes,
  without changing the one-command, source-only launcher boundary.
- Add executable regression coverage for collision completion, draft
  provenance, exact reference validation, rename semantics, and issue status.
- Publish the backward-compatible correction as `0.7.2`.

## Non-goals

- A broad launcher rewrite, plugin system, validator chain, or hosted service.
- Changing the updater credential model or managed path set.
- Giving Codex network, GitHub publication, approval, or merge authority.
- Automatically repairing ambiguous adoption branches or pull requests.
- Moving or rewriting the immutable `v0.7.1` tag.

## Readiness evidence

- Domain and contracts: adoption branch, pull request, ownership marker, base,
  actor, head repository, head SHA, manifest, protocol gitlink, `.gitmodules`,
  rename source path, issue workflow state, and release metadata are separate
  semantic boundaries.
- Consumers and dependencies: the source-only bootstrap adapter, local
  launcher, consumer updater, GitHub pull-request file API, and immutable
  protocol tags are affected. Existing consumer pins remain valid.
- Decisions: this correction enforces the existing fail-closed contracts in
  [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md),
  [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md), and
  [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md); no new
  architectural decision is required.
- Verification: focused PowerShell/real-Git fixtures per slice, one complete
  repository suite, one fresh-diff review, and one bounded confirmation scan.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0049` | Adoption integrity | An unrelated or altered pull request is mistaken for automation-owned adoption | Mitigated; launcher/bootstrap owner | Canonical marker and exact repository/base/actor/head validation |
| `RISK-0050` | Git reference | Collision adoption cannot materialize an exact submodule worktree without network | Mitigated; launcher owner | Validate the index gitlink and canonical metadata without requiring a populated worktree |
| `RISK-0051` | Consumer ownership | A rename hides deletion of an unmanaged path | Mitigated; updater owner | Reject rename and `previous_filename` metadata in inventory and revalidation |
| `RISK-0052` | Maintainability | Narrow fixes further concentrate the source-only launcher | Mitigated; maintainers | Extract cohesive internal validation/state helpers only; retain the source-only single-file boundary |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0046 through TEST-0050](test-cases.md) |
| Test code | Implemented; focused red/green complete | Quick-adoption and updater adapter fixtures |
| Baseline run | Passed | Windows PowerShell 5.1 passed `TEST-0001` through `TEST-0045` in 119.2 seconds on 2026-07-15 |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0017` | Collision-mode exact reference completion | [Issue #30](https://github.com/hasanmanzak/meAndAI/issues/30) | `TEST-0046`; passed 2026-07-15 | `FIND-0066`; resolved | Reviewed |
| `SUBF-0018` | Adoption provenance and unconditional pin validation | [Issue #30](https://github.com/hasanmanzak/meAndAI/issues/30) | `TEST-0047`; passed 2026-07-15 | `FIND-0067`, `FIND-0068`; resolved | Reviewed |
| `SUBF-0019` | Rename-safe updater validation | [Issue #30](https://github.com/hasanmanzak/meAndAI/issues/30) | `TEST-0048`; passed 2026-07-15 | `FIND-0069`; resolved | Reviewed |
| `SUBF-0020` | Lifecycle status, release records, and bounded launcher seams | [Issue #30](https://github.com/hasanmanzak/meAndAI/issues/30) | `TEST-0049`, `TEST-0050`; passed 2026-07-15 | `FIND-0070` through `FIND-0074`; resolved | Reviewed |

## Findings register

Scope: complete tracked repository at `v0.7.1`. Confidence is high for every
listed item. GitHub release state was verified against merged pull requests
and the annotated remote tag before this feature began.

| ID | Classification / severity | Evidence and required action | Status |
| --- | --- | --- | --- |
| `FIND-0066` | Correctness / High | Token-backed collision adoption has source files but no Git objects while the final gate requires a populated submodule; preserved the agent-staged gitlink across general staging and validate its exact index/metadata without requiring a populated worktree. | Resolved |
| `FIND-0067` | Ownership / High | Adoption retention/completion previously bound only the deterministic branch name and count; schema-2 marker validation now binds repository, base, trusted actor, same-repository head, and live head SHA. | Resolved |
| `FIND-0068` | Supply-chain / High | Exact gitlink and `.gitmodules` validation was conditional on `.ai/protocol` appearing in the diff; final reference validation is now unconditional. | Resolved |
| `FIND-0069` | Consumer ownership / Medium | Updater candidate paths ignored rename status and source; both inventory and revalidation now reject rename/previous-filename metadata before mutation. | Resolved |
| `FIND-0070` | Release traceability / Medium | v0.7.0/v0.7.1 feature and memory records described released work as pending; exact PR, merge-commit, and annotated-tag evidence now closes both histories. | Resolved |
| `FIND-0071` | Normative contract / Medium | The protocol did not clearly state optional mapped files and authenticated-`gh` fallback; it now distinguishes source transport from secret provisioning and preserves verification gates. | Resolved |
| `FIND-0072` | Workflow state / Medium | The adoption issue received `status:needs-review` before local completion; it now stays in progress until verified push and readiness succeed. | Resolved |
| `FIND-0073` | Decision traceability / Low | The decision index omitted DEC-0007's partial supersession by DEC-0008; the canonical index now exposes that relationship. | Resolved |
| `FIND-0074` | Maintainability / Low | The completion function concentrated manifest and final-diff validation; cohesive helpers reduce it from 195 measured pre-extraction lines to 158 while retaining the one-file quick command. | Resolved |

## Decisions and relationships

- Updater ownership: [FEAT-0004](../FEAT-0004-self-updating-consumer-updater/README.md)
- Local completion: [FEAT-0007](../FEAT-0007-local-codex-adoption/README.md)
- Bounded convergence: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Seed handoff: [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Local execution: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Tracking: [issue #30](https://github.com/hasanmanzak/meAndAI/issues/30)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Ownership, reference, rename, state, release, and compatibility contracts.
- [x] Numbered risks and existing governing decisions.
- [x] Four independently reviewable slices with a gate ledger.
- [x] Numbered test scenarios and bounded verification approach.
- [x] Successful pre-change baseline and planned red-test state recorded.

## Acceptance criteria

1. Token-backed collision adoption can create an exact canonical protocol
   gitlink without Codex network access or a populated source Git repository.
2. Full-bootstrap and collision completion both unconditionally validate the
   final `160000` gitlink, manifest commit, and canonical `.gitmodules` mapping.
3. Adoption work is retained or completed only when one canonical marker binds
   the expected repository, target, protocol commit, branch head, trusted actor,
   same-repository head, default base, and live draft/readiness state.
4. A renamed pull-request file contributes both destination and source paths to
   validation; any unmanaged source blocks update mutation and cleanup.
5. `status:needs-review` is applied only after the launcher has published and
   verified the completion commit and marked the pull request ready.
6. The v0.7.1 release record is historically complete, the current v0.7.2
   contract is explicit, and feature/decision/memory indexes agree.
7. The largest launcher completion path is split into cohesive internal helpers
   required by these checks without adding another persistent bootstrap layer.
8. Focused tests, the complete suite, internal links, fresh-diff review, and the
   bounded post-change scan pass with no unresolved actionable finding.

## Self-review

`SUBF-0017` fresh-diff review completed on 2026-07-15. `TEST-0046` first failed
on the token-backed manifest-only path, then exposed and resolved one invalid
submodule-descendant pathspec during the focused green run. The final focused
run passed in 70.6 seconds. The diff review confirmed that the launcher keeps
the exact `160000` manifest SHA and canonical `.gitmodules` checks, grants no
new network or credential authority, and no longer requires unavailable source
Git objects or a populated submodule worktree.

`SUBF-0018` first failed on five provenance variants, one unchanged wrong pin,
and one unverified retained proposal; the focused launcher and lifecycle suites
then passed in 87.1 and 44.9 seconds. `SUBF-0019` failed on rename metadata in
both inventory phases and passed after fail-closed validation in 10.0 seconds.
`SUBF-0020` passed the issue-state sequence in 87.1 seconds and reduced the
completion function to 158 lines through two cohesive validation helpers. The
source-only single-file launcher boundary remains unchanged. The first complete
suite exposed only a whitespace-sensitive TEST-0050 assertion after every
integration suite had passed; the allowed blocker-only confirmation run passed
`TEST-0001` through `TEST-0050` in 142.5 seconds.

The final scan budget remains one full tracked-repository pass after all slices
and one confirmation pass only if that first pass produces a blocking finding
that changes the diff.

The bounded post-change scan completed on 2026-07-15 after the confirmation
suite. It reviewed the tracked diff and repository structure, parsed all 13
PowerShell source files with zero errors, confirmed every active version surface
at `0.7.2`, found no credential-like value in the diff, rechecked the 158-line
completion seam, and relied on the passing link/full-suite gates. No new
actionable finding remained, so the convergence loop stopped without another
scan or hardening pass.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded scan stop condition complete.
- [x] No unresolved blocking finding; residual risks are explicit and owned.
- [x] Documentation, links, version, changelog, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked.
- [ ] Applicable CI and review gates passed.
