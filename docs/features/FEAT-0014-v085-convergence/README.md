# FEAT-0014 - Converge the v0.8.4 Scan Findings

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.6 |
| Issue and post-publication authority | [#43](https://github.com/hasanmanzak/meAndAI/issues/43) |
| Pull requests | [#45](https://github.com/hasanmanzak/meAndAI/pull/45); [#46](https://github.com/hasanmanzak/meAndAI/pull/46) |
| Decisions | [DEC-0014](../../decisions/DEC-0014-contained-adoption-and-observable-evidence.md); [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md) |
| Tests | [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065), [TEST-0086](test-cases.md#test-0086), [TEST-0087](test-cases.md#test-0087), [TEST-0088](test-cases.md#test-0088), [TEST-0089](test-cases.md#test-0089), [TEST-0090](test-cases.md#test-0090), [TEST-0091](test-cases.md#test-0091), [TEST-0092](test-cases.md#test-0092), [TEST-0093](test-cases.md#test-0093), [TEST-0094](test-cases.md#test-0094), and [TEST-0095](test-cases.md#test-0095) |

## Problem and intended outcome

The explicit read-only scan of immutable v0.8.4 commit
[`0d4a05e0ce09e5c5586d69a7868128e061f35295`](https://github.com/hasanmanzak/meAndAI/commit/0d4a05e0ce09e5c5586d69a7868128e061f35295) found nine actionable observations
that the passing suite did not expose. Managed destination paths can traverse a
linked ancestor before a secret mutation or bootstrap write, completed adoption
state receives weaker validation than publishing recovery, and runtime version
parsers disagree with the protocol grammar. Several declared test variants are
absent, workflow dispatch evidence is self-derived, and suite exit alone is
treated as evidence for every mapped scenario. Current governance records also
miscount the prior dispositions, overstate the original version scenario, and
leave GitHub closure projections inconsistent with canonical records.

This correction closes exactly `FIND-0123` through `FIND-0131`. The intended
outcome is contained adoption mutation, one exact completed-publication trust
boundary, one canonical version grammar, observable scenario evidence, and a
consistent GitHub/documentation projection. It does not add a generalized
validator, test framework, bootstrap layer, or another unchanged scan loop.

The first post-publication preflight for immutable v0.8.5 then exposed
`FIND-0132`: this feature still said publication was pending and mixed two
post-publication checks into its pre-merge Definition of Done, while
[TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) correctly requires the release-target feature to be `Complete`.
The bounded v0.8.6 correction separates those lifecycle gates and adds the
missing pre-publication regression guard; it does not change runtime behavior.

## Scope

- Reject a managed destination when its lexical path escapes the workspace or
  any existing ancestor is a symbolic link, junction, or reparse point, before
  launcher secret mutation or bootstrap filesystem mutation.
- Reuse one exact completed-publication validator before bootstrap retention or
  launcher readiness, including the single parent, bounded change set, protected
  paths, protocol reference, updater assets, and manifest state.
- Apply one ASCII, no-leading-zero `M.m.rev` parser and numeric comparator at
  every affected runtime boundary without an undocumented `Int32` limit.
- Add the missing declared fixtures, exact independent dispatch/run identity,
  and explicit per-scenario execution results without introducing a framework.
- Correct the v0.8.4 finding count and [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002) wording, and reconcile [issue
  #41](https://github.com/hasanmanzak/meAndAI/issues/41), [pull request #42](https://github.com/hasanmanzak/meAndAI/pull/42), and the open [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) follow-up projection.
- Require current-release feature records to be complete before publication
  and keep post-publication evidence outside their pre-merge Definition of Done.
- Update active protocol pins, version, changelog, indexes, documentation, and
  project-local memory only as required by the implemented correction.

## Non-goals

- Changing repository visibility, purchasing a plan, or treating the
  unprotected `main` condition in [RISK-0076](../FEAT-0013-v084-correction/README.md#risk-0076) as resolved.
- A new service, generalized validation framework, recursive bootstrapper,
  universal AI-memory validator, or consumer migration.
- Product or domain behavior unrelated to the frozen findings.
- New scan scope, speculative refactoring, or another pass without a verified
  actionable finding and remaining validation budget.
- Predicting the merge commit, release identifier, or hosted result in this
  pre-implementation record.

## Contracts and compatibility

- Containment is established from the repository root, lexical relative target,
  every existing ancestor entry type, and final resolved destination before the
  first affected side effect. A clean Git index is not containment evidence.
- `Publishing` and `Completed` are projections of one completion transition.
  Both must establish the same single parent, bounded changed paths, protected-path
  integrity, protocol gitlink, updater blobs, and manifest absence before a
  proposal is retained or marked ready.
- Canonical versions contain three unbounded ASCII decimal components with no
  leading zero except the single value `0`. Numeric comparison must not acquire
  an unstated `System.Version` or platform integer bound.
- A documented test variant exists only when a focused or parameterized fixture
  executes it. A workflow mock derives expected identity independently from the
  caller, and a scenario is complete only when its owning suite reports that
  scenario's observable execution and result.
- Existing canonical releases and contained ordinary-directory consumers remain
  compatible. Noncanonical version aliases, linked managed ancestors, drifted
  completed proposals, and ambiguous evidence fail closed because they were
  already outside the documented contract.
- Exact hosted publication facts remain external. Repository documents may
  designate the authority but do not predict their own released commit.

## Risks

| ID | Classification | Risk | Status / owner | Response and evidence |
| --- | --- | --- | --- | --- |
| `RISK-0077` <a name="risk-0077"></a> | Path containment and credential ordering | A linked managed ancestor can redirect reads or writes outside the consumer before a later Git failure, including after a repository secret is created | Mitigated / launcher and bootstrap owners | Pre-side-effect lexical and ancestor containment gates; launcher [TEST-0086](test-cases.md#test-0086) and bootstrap [TEST-0093](test-cases.md#test-0093) passed |
| `RISK-0078` <a name="risk-0078"></a> | Completed-state trust | A marker-consistent but drifted or unqualified completed proposal can be retained or marked ready | Mitigated / adoption lifecycle owner | Exact proposal and completed-publication validation; launcher [TEST-0087](test-cases.md#test-0087) and bootstrap [TEST-0094](test-cases.md#test-0094) passed |
| `RISK-0079` <a name="risk-0079"></a> | False-green evidence | Missing variants, caller-derived mocks, or suite-level success can preserve green evidence after a scenario contract regresses | Mitigated / test owners | Launcher [TEST-0089](test-cases.md#test-0089), [TEST-0090](test-cases.md#test-0090), and [TEST-0091](test-cases.md#test-0091), bootstrap [TEST-0095](test-cases.md#test-0095), and exact source-bound scenario results passed |
| `RISK-0080` <a name="risk-0080"></a> | GitHub projection | Closed delivery records, stale status labels, release-target feature drift, missing canonical links, or an untracked external follow-up can conceal the real repository state | Reconciled / [issue #44](https://github.com/hasanmanzak/meAndAI/issues/44) retains the residual external risk | [TEST-0092](test-cases.md#test-0092) now rejects incomplete current-release projection before publication; [RISK-0076](../FEAT-0013-v084-correction/README.md#risk-0076) remains separately open rather than falsely resolved |

## Baseline and finite validation budget

| Field | Declaration |
| --- | --- |
| Baseline commit | Immutable v0.8.4 commit [`0d4a05e0ce09e5c5586d69a7868128e061f35295`](https://github.com/hasanmanzak/meAndAI/commit/0d4a05e0ce09e5c5586d69a7868128e061f35295) |
| Completed initial scan | All tracked runtime, workflow, test, fixture, governance, memory, version, link, and relevant GitHub publication surfaces were reviewed without mutation |
| Baseline suite | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/protocol.tests.ps1` passed in 543.6 seconds; the green result did not invalidate these findings |
| Baseline structure | All 15 tracked PowerShell files parsed; diff hygiene and local links were clean |
| Initial disposition | All nine findings, `FIND-0123` through `FIND-0131`, are `Blocking` and open |
| Correction budget | One correction pass across the three initial slices; the verified v0.8.5 publication blocker permits one narrow `SUBF-0036` correction, one fresh-diff review, one complete suite, publication, and one fresh confirmation scan |
| Repeat rule | Repeat only for a verified actionable finding, changed evidence, or failed declared gate while budget remains; never repeat an unchanged scan |
| Stop condition | Every acceptance criterion and declared test passes, no `Blocking` finding remains, external projections are reconciled, and any non-blocking condition retains its required authority |

## Decomposition and gate ledger

| ID | Slice | Findings | Tests | Gate state |
| --- | --- | --- | --- | --- |
| `SUBF-0033` <a name="subf-0033"></a> | Contained runtime and exact completion boundaries | `FIND-0123` through `FIND-0125` | [TEST-0086](test-cases.md#test-0086), [TEST-0087](test-cases.md#test-0087), and [TEST-0088](test-cases.md#test-0088), [TEST-0093](test-cases.md#test-0093), [TEST-0094](test-cases.md#test-0094) | Implemented, self-reviewed, and passed |
| `SUBF-0034` <a name="subf-0034"></a> | Focused and observable evidence | `FIND-0126` through `FIND-0128` | [TEST-0089](test-cases.md#test-0089), [TEST-0090](test-cases.md#test-0090), and [TEST-0091](test-cases.md#test-0091), [TEST-0095](test-cases.md#test-0095) | Implemented, self-reviewed, and passed |
| `SUBF-0035` <a name="subf-0035"></a> | Governance and publication projection | `FIND-0129` through `FIND-0131` | [TEST-0088](test-cases.md#test-0088), [TEST-0092](test-cases.md#test-0092), and external projection review | Reconciled, self-reviewed, and passed |
| `SUBF-0036` <a name="subf-0036"></a> | Pre-merge versus post-publication projection | `FIND-0132` | [TEST-0092](test-cases.md#test-0092), [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) | Implemented, self-reviewed, and passed locally |

## Acceptance criteria

1. Every managed target is lexically contained and every existing ancestor is
   an ordinary in-workspace directory before affected secrets or files mutate.
2. Bootstrap retention and launcher readiness reject every completed proposal
   that the exact publishing-recovery completion contract rejects.
3. Launcher and updater version boundaries accept only the protocol's unbounded
   ASCII/no-leading-zero grammar and compare its components numerically.
4. Every variant named by `FIND-0126` executes at its owning boundary and fails
   before mutation when malformed, missing, drifted, or ambiguous.
5. Dispatch fixtures require the exact workflow, repository, ref, correlation,
   and independently derived run head.
6. Scenario ownership consumes an explicit observed result for each active
   scenario rather than inferring coverage from a successful suite exit.
7. The prior disposition count and [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002) wording match their canonical
   contracts; [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) and [PR #42](https://github.com/hasanmanzak/meAndAI/pull/42) link [FEAT-0013](../FEAT-0013-v084-correction/README.md)/[DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) correctly, and open
   [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) has a durable active finding record while [RISK-0076](../FEAT-0013-v084-correction/README.md#risk-0076) remains
   external and unresolved.
8. Every feature targeting the current protocol version is `Complete` before
   publication, and its post-publication evidence remains in the separate
   external gate required by [DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md).

## Frozen findings register

The register is frozen to the completed v0.8.4 scan. All nine rows were
`Blocking`; their implementation, focused evidence, slice self-review, and
complete local gate passed on 2026-07-16. Shared confidence is high. [Issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) owns delivery and later
post-publication evidence.

| ID | Classification | Severity / confidence | Evidence and impact | Required action | Disposition / status | Traceability |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0123` <a name="find-0123"></a> | Verified defect - trust and mutation ordering | High / High | The [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) follows a managed seed through a linked ancestor before its secret boundary, while the [bootstrap adapter](../../../templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1) inventories target strings but can write through linked ancestors. A later staging failure does not undo an external write or created secret. | Prove lexical containment and reject every existing linked/reparse ancestor before the first affected side effect | `Resolved` / Verified 2026-07-16 | `SUBF-0033`, `RISK-0077`, launcher [TEST-0086](test-cases.md#test-0086), bootstrap [TEST-0093](test-cases.md#test-0093) |
| `FIND-0124` <a name="find-0124"></a> | Verified defect - semantic validation | High / High | Completed retention in the [bootstrap adapter](../../../templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1) and readiness in the [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) establish less than the launcher's publishing recovery: they omit single-parent, protected-path, and updater-asset evidence. A drifted completed proposal can therefore be trusted. | Reuse one exact completed-publication validator before retention or readiness mutation | `Resolved` / Verified 2026-07-16 | `SUBF-0033`, `RISK-0078`, launcher [TEST-0087](test-cases.md#test-0087), bootstrap [TEST-0094](test-cases.md#test-0094) |
| `FIND-0125` <a name="find-0125"></a> | Contract drift - version semantics | Medium / High | [Protocol versioning](../../../PROTOCOL.md#8-versioning) requires unbounded ASCII components without leading zeros; the launcher uses a broader digit regex and the [updater resolver](../../../templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1) introduces a `System.Version` integer bound. Runtime entry points disagree about a valid tag. | Use one ASCII/no-leading-zero parser and unbounded numeric comparator at each runtime boundary | `Resolved` / Verified 2026-07-16 | `SUBF-0033`, [TEST-0088](test-cases.md#test-0088), [DEC-0014](../../decisions/DEC-0014-contained-adoption-and-observable-evidence.md) |
| `FIND-0126` <a name="find-0126"></a> | Evidence defect - missing declared variants | Medium / High | Existing fixtures do not execute every declared complete-updater exact/missing/drift variant, manifest identity/schema/type variant, post-ready/pre-issue interruption, missing release, or case-variant collision. Removal of a named guard can remain green. | Add focused or parameterized cases for every named variant and its pre-mutation result | `Resolved` / Verified 2026-07-16 | `SUBF-0034`, `RISK-0079`, launcher [TEST-0089](test-cases.md#test-0089), bootstrap [TEST-0095](test-cases.md#test-0095) |
| `FIND-0127` <a name="find-0127"></a> | Evidence defect - self-derived dispatch | Medium / High | The [quick-adoption fixtures](../../../tests/capabilities/initial-adoption/quick-adoption.tests.ps1) accept a workflow dispatch without exact workflow/repository/ref checks and fabricate the matching run head from the caller's later commit query. Wrong dispatch identity can remain green. | Persist independently expected dispatch identity and require the exact matching run | `Resolved` / Verified 2026-07-16 | `SUBF-0034`, `RISK-0079`, [TEST-0090](test-cases.md#test-0090) |
| `FIND-0128` <a name="find-0128"></a> | Evidence authority defect - unobserved scenario coverage | Medium / High | The [repository validator](../../../tests/protocol.tests.ps1) treats a successful child-suite exit as successful evidence for every mapped scenario even when some mapped IDs never occur in their owner. Scenario assertions can disappear without failing ownership validation. | Have each suite expose a compact explicit scenario-result set and compare it with the ownership map | `Resolved` / Verified 2026-07-16 | `SUBF-0034`, `RISK-0079`, [TEST-0091](test-cases.md#test-0091) |
| `FIND-0129` <a name="find-0129"></a> | Documentation defect - disposition count | Low / High | The [v0.8.4 memory handoff](../../../.ai/memory/log/2026-07-16-v084-correction.md) and [FEAT-0013 evidence](../FEAT-0013-v084-correction/test-cases.md) say the scan had ten blockers plus one external follow-up, while its canonical register has nine `Blocking`, one `OptionalImprovement`, and one `ExternalOrLegacyFollowUp`. | Correct both durable count statements without changing the frozen register | `Resolved` / Verified 2026-07-16 | `SUBF-0035`, [TEST-0092](test-cases.md#test-0092) |
| `FIND-0130` <a name="find-0130"></a> | Governance defect - GitHub projection | Medium / High | Open [RISK-0076](../FEAT-0013-v084-correction/README.md#risk-0076) has no active `type:finding` record; closed [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) retains `status:in-progress` and names a nonexistent [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) path; [PR #42](https://github.com/hasanmanzak/meAndAI/pull/42) omits canonical [FEAT-0013](../FEAT-0013-v084-correction/README.md) and [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) links. The external projection contradicts the canonical graph. | Reconcile stable issue/PR links and status, and create the durable open [FIND-0120](https://github.com/hasanmanzak/meAndAI/issues/44) follow-up without claiming branch protection is resolved | `Resolved` / Verified 2026-07-16 | `SUBF-0035`, `RISK-0080`, [TEST-0092](test-cases.md#test-0092), [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) |
| `FIND-0131` <a name="find-0131"></a> | Documentation defect - version scenario wording | Low / High | Active [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002) says any three non-negative components are accepted, which is broader than the ASCII/no-leading-zero protocol grammar and the boundary evidence added by [TEST-0085](../FEAT-0013-v084-correction/test-cases.md#test-0085). | State the exact canonical grammar in [TEST-0002](../FEAT-0001-common-development-protocol/test-cases.md#test-0002) while retaining [TEST-0085](../FEAT-0013-v084-correction/test-cases.md#test-0085) as its boundary regression evidence | `Resolved` / Verified 2026-07-16 | `SUBF-0035`, [TEST-0088](test-cases.md#test-0088), [TEST-0092](test-cases.md#test-0092) |

## Confirmation-scan finding

| ID | Classification | Severity / confidence | Evidence and impact | Required action | Disposition / status | Traceability |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0132` <a name="find-0132"></a> | Governance defect - release-state projection | High / High | Immutable v0.8.5 contains `Ready for review; publication pending` for FEAT-0014 and places publication-dependent checks inside its pre-merge Definition of Done. [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065) therefore cannot verify that release even though its runtime and hosted gates passed. | Separate the lifecycle gates, mark the current release feature complete before publication, and make the complete local suite reject the mismatch before another release | `Resolved` / Verified locally 2026-07-16; external evidence pending | `SUBF-0036`, `RISK-0080`, [TEST-0092](test-cases.md#test-0092), [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065), [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) |

## Definition of Ready

- [x] Stable ID, linked issue, intended outcome, frozen scope, and non-goals.
- [x] Runtime, filesystem, credential, lifecycle, version, evidence, and GitHub
      projection contracts identified with compatibility boundaries.
- [x] Four numbered risks and accepted [DEC-0014](../../decisions/DEC-0014-contained-adoption-and-observable-evidence.md) recorded.
- [x] Nine initial findings and one verified confirmation finding mapped to four
      independently reviewable slices.
- [x] Ten feature-specific scenarios plus existing post-publication [TEST-0065](../FEAT-0011-stability-closure/test-cases.md#test-0065)
      and their evidence owners defined.
- [x] Baseline suite, PowerShell parse, diff/link state, scan scope, finite budget,
      repeat rule, and stop condition recorded.
- [x] At Gate 1, test code was absent and every new scenario demonstrated its
      intended red state before the corresponding correction.

## Definition of Done

- [x] Acceptance criteria met and all ten findings resolved through evidence.
- [x] Mandatory test code and explicit scenario-result mapping implemented.
- [x] Each slice received one focused fresh-diff self-review with no unresolved
      `Blocking` finding.
- [x] One complete local suite passed after the v0.8.6 correction.
- [x] Documentation, links, version, changelog, memory, issue, and pull request
      are current for the corrective review.
- [x] Hosted CI and review gates are mandatory merge preconditions; their exact
      results remain external to this pre-merge record.

## Post-publication evidence

This gate is deliberately outside Definition of Done. The released feature is
complete before publication; exact release facts remain `Pending` here and are
written to [issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) only after they exist.

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #43](https://github.com/hasanmanzak/meAndAI/issues/43) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
