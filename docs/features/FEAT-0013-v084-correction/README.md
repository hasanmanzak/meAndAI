# FEAT-0013 - Close the Bounded v0.8.3 Scan Findings

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.4 |
| Issue and post-publication authority | [#41](https://github.com/hasanmanzak/meAndAI/issues/41) |
| Pull request | [#42](https://github.com/hasanmanzak/meAndAI/pull/42) |
| Decision | [DEC-0013](../../decisions/DEC-0013-trusted-adoption-and-recoverable-evidence.md) |
| Tests | [TEST-0077 through TEST-0085](test-cases.md) |

## Problem and outcome

The read-only v0.8.3 scan found eleven observations after the prior correction
had passed its declared suite. Ten are actionable in the authorized correction:
trusted-source validation happened after consumer-local updater execution,
seed rejection happened after secret mutation, one completion transition was
not rerunnable after an interruption, launcher manifest validation was weaker
than bootstrap validation, evidence descriptions exceeded their fixtures,
external comments were not paginated, delivery links were unstable or stale,
finding classification and disposition were conflated, the version grammar had
no boundary table, and completed scenarios still described implementations as
planned. The remaining observation is an owned external branch-protection risk.

This correction strengthens the existing boundaries and evidence. It does not
add another bootstrapper, validator layer, service, or scan loop.

## Scope

- Resolve only `FIND-0112` through `FIND-0122` under their recorded
  dispositions.
- Reuse the existing source-only bootstrap path and capabilities contract for
  trusted updater and exact manifest checks.
- Make seed rejection side-effect-free and completion publication exactly
  recoverable after interruption.
- Align scenario evidence, post-publication pagination, issue-form semantics,
  stable delivery links, version grammar, and completed documentation wording.
- Update protocol `0.8.4`, active adoption pins, canonical indexes, changelog,
  and project-local memory.

## Non-goals

- A new hosted coordinator, GitHub App, recursive validator, universal
  AI-memory validator, or replacement bootstrap architecture.
- Automatic pull-request approval or merge, consumer-repository migration, or
  changes outside the frozen register.
- Changing repository visibility, purchasing a GitHub plan, or bypassing the
  unavailable private-repository branch-protection control.
- A third or unchanged full-project scan.

## Readiness and contracts

- Trusted protocol source, consumer-local executable assets, repository
  credentials, seed workflow, adoption manifest, completion marker, planned
  head, evidence page, finding classification, finding disposition, and
  protocol version are distinct contracts.
- No consumer-local updater receives write credentials until trusted code from
  the exact source release validates its complete managed asset set.
- Existing seed drift is rejected before lock acquisition or secret mutation.
- A completion marker records enough pre-push intent to finalize a live planned
  head without rerunning semantic work or restore a still-live previous head
  before retry.
- The launcher and bootstrap share the exact manifest schema, paths,
  collisions, tasks, and target identity contract.
- Scenario prose names only behavior its fixture executes; paginated evidence
  proves a qualifying second-page comment.
- Version components are ASCII decimal integers with no leading zeros except
  the single value `0`.

## Risks

| ID | Classification | Risk | Status / owner | Response and review condition |
| --- | --- | --- | --- | --- |
| `RISK-0072` | Supply-chain boundary | A drifted consumer-local updater can receive repository credentials before trusted validation | Mitigated / automation owner | Exact-release source preflight and `TEST-0077` |
| `RISK-0073` | Credential side effect | A rejected seed can still leave a secret write behind | Mitigated / launcher owner | Read-only seed preflight before lock or secrets and `TEST-0078` |
| `RISK-0074` | Interrupted state transition | Push can succeed before the completion marker records the new head | Mitigated / launcher owner | Recoverable intent state and `TEST-0079` |
| `RISK-0075` | Evidence integrity | Weak manifest checks, overstated fixtures, or first-page-only evidence can produce false closure | Mitigated / test and release owners | `TEST-0080` through `TEST-0083` |
| `RISK-0076` | External repository control | The private repository's `main` branch is not protected under the current GitHub capability | Open `ExternalOrLegacyFollowUp` / maintainer | On 2026-07-16 the repository API reported `protected=false`; branch-protection and ruleset APIs returned HTTP 403 with the private-plan/public-repository limitation. Review when the repository becomes public or the account gains a plan that supports the control; do not change visibility as part of this feature. |

## Declared scan boundary and finite budget

| Field | Declaration |
| --- | --- |
| Initial scan | Completed read-only on 2026-07-16 against immutable v0.8.3 commit `7ec7f83c7190c3f064a3c572e7e30d29ea1e5454` |
| Tracked scope | All 109 tracked files, entry points, PowerShell call paths, both workflows, tests and fixtures, protocol/templates, feature/decision/memory graph, version/changelog, links, diff hygiene, and relevant live GitHub release/issue/PR/branch projections |
| Exclusions | External consumer repositories. No tracked generated or binary scope was identified. Branch protection was inspected but cannot be enabled under the current private-repository capability without a visibility or plan change. |
| Initial evidence | Complete suite passed in 273.3 seconds; all 15 tracked PowerShell files parsed; local links and diff hygiene passed. The green baseline did not invalidate `FIND-0112` through `FIND-0122`. |
| Budget | One completed initial scan plus one confirmation scan after remediation; no unchanged or third scan is authorized |
| Stop condition | Declared tests and relevant gates pass, the confirmation has no unresolved `Blocking` finding, and non-blocking dispositions remain owned here |

## Decomposition and gate ledger

| ID | Slice | Findings | Tests | Self-review and status |
| --- | --- | --- | --- | --- |
| `SUBF-0030` | Trusted adoption boundaries and recoverable completion | `FIND-0112` through `FIND-0115` | `TEST-0077` through `TEST-0080` | Fresh-diff review passed; no unresolved blocker |
| `SUBF-0031` | Contract-bearing evidence and traceability | `FIND-0116` through `FIND-0119`, `FIND-0121` | `TEST-0081` through `TEST-0085` | Fresh-diff review passed; no unresolved blocker |
| `SUBF-0032` | Protocol, documentation, memory, and external risk ownership | `FIND-0120`, `FIND-0122` | `TEST-0083` through `TEST-0085` plus link review | Fresh-diff review passed; only owned external follow-up remains |

## Acceptance criteria

1. Trusted code from the exact checked-out release validates every managed
   consumer-local updater asset before either credential is passed to it.
2. A differing existing seed workflow blocks before lock acquisition, secret
   inventory, or secret write.
3. An interruption after completion push but before marker/readiness update is
   exactly reconciled on rerun without repeating Codex semantic work.
4. The launcher rejects every manifest that the canonical bootstrap manifest
   contract rejects, including property, path, collision, task, and target
   drift.
5. `TEST-0069` has explicit malformed and duplicate-marker fixtures, and
   `TEST-0070` describes and proves its deterministic serialized state model
   without claiming unexecuted process concurrency.
6. Post-publication evidence exhausts comment pagination and accepts qualifying
   evidence that exists only on page two; issue-body text is not a substitute.
7. FEAT-0012 links the merged delivery PRs and keeps exact hosted publication
   facts in its designated external authority rather than mutable branch links.
8. The finding form offers exactly the four protocol dispositions and records
   defect/risk/improvement classification separately.
9. Executable version tests cover valid and invalid `M.m.rev` boundaries.
10. Completed feature scenario documents describe implemented evidence, while
    `RISK-0076` remains visible with its owner and review condition.

## Findings register

The register is frozen to the initial scan. `Blocking` means actionable and
in-scope; changing wording cannot clear it. Shared confidence is high. Issue
[#41](https://github.com/hasanmanzak/meAndAI/issues/41) owns delivery and later
post-publication evidence.

| ID | Classification | Severity / confidence | Specific evidence and impact | Required action | Disposition / status | Traceability |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0112` | Verified defect - trust boundary | High / High | The consumer workflow could invoke its local updater with both tokens before source bootstrap compared the updater assets; a drifted executable therefore reached credentials first | Run an exact-source managed-asset preflight before local execution | `Blocking` / Resolved | `SUBF-0030`, `TEST-0077`, [workflow](../../../templates/project/.github/workflows/meandai-protocol-update.yml) |
| `FIND-0113` | Verified defect - mutation ordering | High / High | The launcher reconciled missing secrets before rejecting a differing existing seed, leaving credential mutation after an otherwise rejected adoption | Move exact seed validation before the mutation boundary | `Blocking` / Resolved | `SUBF-0030`, `TEST-0078`, [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) |
| `FIND-0114` | Verified defect - recovery | Medium / High | Completion push preceded the ownership-marker update; interruption left new remote head with stale marker and exact rerun rejected it | Persist old/planned-head intent before push and reconcile either state | `Blocking` / Resolved | `SUBF-0030`, `TEST-0079`, [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) |
| `FIND-0115` | Verified defect - semantic validation | Medium / High | Launcher validation checked only manifest identity while bootstrap enforced the full property, path, collision, and task contract; malformed data could enter the Codex prompt | Reuse one exact manifest contract at both boundaries | `Blocking` / Resolved | `SUBF-0030`, `TEST-0080`, [capabilities module](../../../templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1) |
| `FIND-0116` | Verified evidence defect | Medium / High | `TEST-0069` named malformed/duplicate variants without explicit fixtures, and `TEST-0070` claimed concurrent launchers while its fixture modeled a pre-existing lock and sequential rerun | Add the missing variants and make scenario wording match executed semantics | `Blocking` / Resolved | `SUBF-0031`, `TEST-0081`, `TEST-0082`, [FEAT-0012 scenarios](../FEAT-0012-v082-correction/test-cases.md) |
| `FIND-0117` | Verified defect - external evidence | Medium / High | The verifier requested only the first 100 issue comments, while its mock allowed issue-body evidence; valid later-page evidence could be missed and body text could falsely satisfy closure | Traverse bounded pagination and prove comment-only page-two evidence | `Blocking` / Resolved | `SUBF-0031`, `TEST-0083`, [verifier](../../../tests/Verify-PostPublicationEvidence.ps1) |
| `FIND-0118` | Verified governance defect | Medium / High | FEAT-0012 still showed its PR as pending after PRs #39 and #40 merged, and external records linked deleted work branches instead of stable main/commit content | Link both merged PRs and repair external links to stable authorities | `Blocking` / Resolved | `SUBF-0031`, `TEST-0085`, [FEAT-0012](../FEAT-0012-v082-correction/README.md) |
| `FIND-0119` | Verified governance defect - taxonomy | Medium / High | The finding issue form offered defect/risk/improvement values as disposition choices, contradicting the four mutually exclusive protocol dispositions | Separate classification from the exact four dispositions | `Blocking` / Resolved | `SUBF-0031`, `TEST-0084`, [finding form](../../../.github/ISSUE_TEMPLATE/finding.yml) |
| `FIND-0120` | External repository risk | Medium / High | Live API evidence on 2026-07-16 reported unprotected `main`; protection/ruleset APIs returned HTTP 403 under the current private-repository capability | Retain owner and review when public or supported plan becomes available | `ExternalOrLegacyFollowUp` / Open; maintainer owned | `SUBF-0032`, `RISK-0076`, [issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) |
| `FIND-0121` | Verified evidence defect - version grammar | Low / High | The repository validator tested only the current literal version and had no valid/invalid grammar table | Add canonical boundary cases, including leading-zero and non-ASCII/shape failures | `Blocking` / Resolved | `SUBF-0031`, `TEST-0085`, [protocol](../../../PROTOCOL.md#8-versioning) |
| `FIND-0122` | Documentation clarity | Low / High | Completed FEAT-0005, FEAT-0006, FEAT-0008, and FEAT-0012 scenario records still called their evidence planned | Use implemented-evidence wording without changing historical outcomes | `OptionalImprovement` / Completed | `SUBF-0032`, `TEST-0085` |

## Definition of Ready

- [x] Stable ID, linked issue, problem, outcome, frozen scope, and non-goals.
- [x] Affected boundaries, consumers, compatibility, and semantic contracts.
- [x] Numbered risks, DEC-0013, three reviewable slices, and nine scenarios.
- [x] Baseline limitation, scan boundary, finite budget, and stop condition.

## Definition of Done

- [x] Acceptance criteria met and mandatory tests implemented and passing.
- [x] Each slice has one fresh-diff self-review with no unresolved `Blocking`
      finding.
- [x] One final relevant verification and the single confirmation scan pass.
- [x] Documentation, links, version, changelog, memory, issue, and pull request
      are current.
- [ ] Hosted CI and review gates pass before merge.
- [ ] Exact release evidence is written after publication to issue #41 and the
      GitHub Release; no release commit is predicted here.

## Post-publication evidence

| Field | Evidence |
| --- | --- |
| External evidence authority | [Issue #41](https://github.com/hasanmanzak/meAndAI/issues/41) |
| Release authority | Pending |
| Release identifier | Pending |
| Target commit | Pending |
| Verification evidence | Pending |
