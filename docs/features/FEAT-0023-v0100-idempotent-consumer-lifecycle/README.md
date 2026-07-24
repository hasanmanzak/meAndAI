# FEAT-0023 - v0.10.0 Idempotent Consumer Lifecycle Reconciliation

| Field | Value |
| --- | --- |
| Classification | Feature correction / [BUG-0011](https://github.com/hasanmanzak/meAndAI/issues/63) |
| Status | Complete |
| Target version | 0.10.0 |
| Issue | [#63](https://github.com/hasanmanzak/meAndAI/issues/63) |
| Pull request | [#64](https://github.com/hasanmanzak/meAndAI/pull/64) |
| Decision | [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

Consumer update discovery still expects a maintainer to prepare the update
tracking issue and replace a pull-request placeholder. Consumer-owned memory and
test templates can duplicate the live protocol version, which creates an
unrelated reconciliation change after an otherwise complete managed update.
Re-running the current quick-adoption launcher against an adopted repository is
also treated as a seed collision instead of a classified lifecycle operation.

Consumers installed before managed finalization can therefore complete a valid
installing update without the tracking evidence needed by the newer finalizer.
That transition needs a narrow, evidence-based bridge rather than a permanent
compatibility framework.

## Outcome

One consumer-owned lifecycle reconciles adoption, compatible updates,
supersession, and post-merge cleanup. It creates or reuses the exact update
issue and labels before proposing a change, writes the authoritative issue link
into the pull request, and closes only proven superseded or merged work. The
quick-adoption launcher classifies an existing repository before mutation and
routes a complete older same-major installation through its installed updater.

The protocol submodule gitlink and `.ai/protocol/VERSION` become the sole live
pin authority. Consumer-owned records and tests resolve that authority
dynamically and do not need a second reconciliation pull request merely to copy
the new pin. This prospective rule did not prove that every older consumer
already had the required shape; [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md)
owns generic transition reconciliation for release-declared derived state.

## Scope

- Create or reuse one marker-owned protocol-update issue per immutable target,
  create only missing standard labels, and add exact issue/pull-request
  backlinks.
- Replace manual `Tracking issue: #REQUIRED` and memory reconciliation steps
  with machine-produced, verified evidence.
- Close a superseded issue only after the older managed pull request is closed
  and its unchanged owned branch is deleted.
- Repair one exact legacy installing update when its merged proposal is
  otherwise fully qualified, then invoke the normal managed finalizer.
- Classify repeated launcher runs as unadopted, already current, compatible
  same-major update, or unsafe drift/newer/cross-major state.
- Preserve existing secrets, never overwrite an installed seed during a repeat
  run, and dispatch the installed updater for a compatible update.
- Remove live protocol tag/SHA duplication from reusable consumer templates,
  prompt requirements, and validation contracts.

## Non-goals

- Automatically approving or merging pull requests.
- Updating across a protocol major-version boundary.
- Repairing arbitrary partial installations, foreign branches, pull requests,
  or issues.
- Adding a GitHub App, hosted service, polling daemon, generalized migration
  framework, or self-validating bootstrap platform.
- Retrospectively mutating a consumer unless its repository evidence satisfies
  the exact legacy bridge contract.

## Readiness evidence

- Domain and identity: a managed update issue is selected by a canonical
  first-line marker binding schema, target tag, protocol SHA, and consumer
  repository. The pull request carries exactly one
  `Tracking issue: [#N](https://github.com/<owner>/<repository>/issues/N)` line.
- Ordering: issue reconciliation precedes pull-request creation; supersession
  closes the old proposal and deletes its unchanged branch before it closes the
  old issue; merge finalization remains branch-first and issue-second.
- Existing-install classification: the launcher proves the exact gitlink,
  canonical submodule registration, installed release mapping, workflow,
  scripts, and absence of transient adoption state before it chooses no-op or
  update routing. Ambiguous or unsupported states fail before mutation.
- Authority: the submodule gitlink and `.ai/protocol/VERSION` are the current
  protocol pin. Consumer-owned files may retain dated historical evidence but
  cannot declare a second live version/SHA.
- Credential boundary: the updater PAT remains responsible for contents,
  pull-request, and workflow changes. Issue reconciliation uses the
  job-scoped consumer `GITHUB_TOKEN` with `issues: write`; no new PAT scope is
  required.
- Verification: focused mocked GitHub/Git tests, structural workflow and
  template tests, PowerShell parsing, complete repository validation, and
  hosted Ubuntu/Windows checks.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0102` | Identity / traceability | Automation reuses or closes an unrelated issue | Mitigated / consumer workflow | Repository-bound first-line issue marker, exact target/SHA identity, backlink checks, and passing [TEST-0111](test-cases.md) |
| `RISK-0103` | Compatibility | A legacy installing update cannot enter managed finalization safely | Mitigated / consumer workflow | One bounded bridge requiring merged same-repository proposal, marker/head/base/path/gitlink proof, and passing [TEST-0112](test-cases.md) |
| `RISK-0104` | State classification | Repeat adoption overwrites a seed or dispatches from drifted state | Mitigated / quick launcher | Complete-footprint classifier, installed-release blob verification, no-downgrade/cross-major rejection, and passing [TEST-0113](test-cases.md) |
| `RISK-0105` | Consistency | Consumer-owned files retain a stale second protocol pin | Corrected prospectively / templates and root validation; transition reconciliation gap tracked by [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md) | Sole-authority rule and version-neutral templates remain covered by [TEST-0114](test-cases.md); the duplicated-live-pin state is the [MIG-0001](../../../migrations/MIG-0001.json) regression under [TEST-0119](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md), while generic transition and handoff evidence are [TEST-0120](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md), [TEST-0121](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md), and [TEST-0122](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/test-cases.md) |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0039` | Automatic update issue ownership, supersession, and merge cleanup | [Issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) | [TEST-0111](test-cases.md); expected-red then focused pass | Exact token boundary, backlinks, reuse, supersession, and branch-first closure reviewed; no open finding | Complete |
| `SUBF-0040` | Repeat-launch routing and bounded legacy transition | [Issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) | [TEST-0112](test-cases.md) and [TEST-0113](test-cases.md); expected-red then focused pass | Legacy proof, repeat-route ordering, interrupted state, and `FIND-0156` correction reviewed | Complete |
| `SUBF-0041` | Version-neutral consumer pin authority | [Issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) | [TEST-0114](test-cases.md); expected-red then focused pass | Template destinations, links, and dynamic pin authority reviewed; no open finding | Complete |

## Decisions and relationships

- Decision: [DEC-0017](../../decisions/DEC-0017-idempotent-consumer-lifecycle.md)
- Reviewed update supersession: [FEAT-0002](../FEAT-0002-semi-automatic-consumer-updates/README.md) / [DEC-0003](../../decisions/DEC-0003-reviewed-consumer-update-supersession.md)
- Consumer lifecycle: [FEAT-0005](../FEAT-0005-ai-capabilities-lifecycle/README.md) / [DEC-0006](../../decisions/DEC-0006-seed-workflow-adoption-handoff.md)
- Local launcher: [FEAT-0006](../FEAT-0006-quick-adoption-launcher/README.md), [DEC-0007](../../decisions/DEC-0007-local-quick-adoption-boundary.md), and [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Managed finalization: [FEAT-0022](../FEAT-0022-v097-managed-merge-finalization/README.md) / [DEC-0016](../../decisions/DEC-0016-managed-post-merge-finalization.md)
- Tracking: [issue #63](https://github.com/hasanmanzak/meAndAI/issues/63)

## Definition of Ready

- [x] Stable `FEAT-0023`, [BUG-0011](https://github.com/hasanmanzak/meAndAI/issues/63), and linked [issue #63](https://github.com/hasanmanzak/meAndAI/issues/63).
- [x] Problem, outcome, scope, non-goals, compatibility, and credential
      boundaries are explicit.
- [x] Automatic issue identity, lifecycle ordering, repeat-run classification,
      live pin authority, and fail-closed error contracts are defined.
- [x] `RISK-0102` through `RISK-0105` have owners and planned evidence.
- [x] Work is decomposed into three independently reviewable subfeatures.
- [x] [TEST-0111](test-cases.md), [TEST-0112](test-cases.md), [TEST-0113](test-cases.md), and [TEST-0114](test-cases.md) and the verification approach are defined.
- [x] Baseline is the green published `v0.9.7` repository state.

## Acceptance criteria

1. Scheduled or ordinary manual update discovery creates/reuses the exact
   target-owned issue, standard labels, backlinks, deterministic branch, and
   draft pull request without maintainer setup.
2. A newer target supersedes an older open proposal and closes its exact issue
   only after the old pull request and unchanged branch converge.
3. A qualified merge closes the tracking issue and deletes only its exact
   owned branch; repeated finalization is idempotent.
4. A qualified legacy installing update can acquire missing tracking evidence
   and enter normal finalization without accepting arbitrary legacy state.
5. Re-running the launcher is a no-op when current, dispatches the installed
   updater for an older same-major complete installation, and fails before
   mutation for partial, drifted, newer, or cross-major state.
6. Consumer-owned memory, tests, and reusable docs derive the live version from
   `.ai/protocol/VERSION`; a compatible update requires no separate change
   solely to restate the pin. Any independently required derived-state change
   follows the release-declared migration contract in [FEAT-0026](../FEAT-0026-v0103-generic-consumer-transition-reconciliation/README.md).
7. Focused scenarios and the complete protocol suite pass with documentation,
   version, changelog, memory, and the publication handoff aligned.

## Self-review

The 2026-07-17 review was bounded to the changed call flows, credentials,
issue/branch/PR ownership, repeat-run classification, template authority,
interrupted-state ordering, version alignment, and regression evidence. It did
not reopen unrelated history or add a general validator/migration framework.

The updater review confirmed job-token-only issue authority, updater-PAT
proposal authority, protocol-token release proof, replacement-first
supersession, and branch-first issue completion. The launcher review confirmed
that unsupported completed states fail before managed content or secret
mutation and that local Git identity is initialized only for initial adoption.
Consumer template links were reviewed in their copied destination context.

| ID | Classification | Priority / impact | Finding | Disposition |
| --- | --- | --- | --- | --- |
| `FIND-0156` | Mutation-order defect / `Blocking` | `p1` / an unsupported completed installation could receive a local Git identity write before classification | The first implementation initialized `user.name` and `user.email` before `Get-ExistingAdoptionRoute`. The initialization now runs only after the classifier returns `InitialAdoption`; current, compatible, and rejected completed states do not receive that write. | Resolved in the same bounded review; PowerShell parsing and the 615.1-second complete suite confirmed the correction |

No unresolved in-scope `Blocking` finding remains. Focused test fixture
corrections initialized the synthetic submodule from its local immutable mock
source and require the missing-gitlink case to reach the intended classifier,
preventing a false pass through an earlier generic clean-tree gate.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario ownership complete.
- [x] Focused and complete test evidence recorded.
- [x] Fresh self-review and one bounded post-development scan complete.
- [x] No unresolved blocking finding.
- [x] Documentation, links, version, changelog, and project memory current.

## Publication handoff

[Issue #63](https://github.com/hasanmanzak/meAndAI/issues/63) owns the external
pull-request, hosted-check, merge, exact branch-deletion, tag, release-asset,
and post-publication evidence after each fact exists. This repository record
does not predict those values.
