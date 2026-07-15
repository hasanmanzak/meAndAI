# FEAT-0011 - Close End-to-End Protocol Stability Gaps

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.1 |
| Issue | [#36](https://github.com/hasanmanzak/meAndAI/issues/36) |
| Pull request | [#37](https://github.com/hasanmanzak/meAndAI/pull/37) |
| Decision | [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md) |
| Tests | [Test scenarios](test-cases.md) |

## Problem

The v0.8.0 stability work fixed several local symptoms but did not carry
repository, release, path, workflow-run, and closure identity through every
consumer boundary. Its self-review also treated declared test identifiers and
green structural checks as stronger evidence than the executed scenarios
provided. This left older gaps undetected and introduced new release and
bootstrap defects while claiming their invariant classes were resolved.

## Outcome

The protocol uses qualified evidence from source through mutation: GitHub
repository identity includes its host, release authority includes the
credential boundary and locked commit, bootstrap path evidence includes both
sides of a rename, and lifecycle runs include a dispatch correlation ID.
Completion terminology has one bounded meaning, post-publication projections
converge, and test claims are derived from executable evidence rather than a
blanket range message.

## Scope

- Resolve `FIND-0093` through `FIND-0101` without adding a validator service or
  another bootstrap layer.
- Qualify every launcher-owned GitHub repository operation with `github.com`.
- Verify updater targets with the read-only protocol credential and bind the
  immutable release to the exact fetched commit.
- Validate bootstrap diffs from complete rename provenance.
- Correlate a launcher dispatch to exactly its workflow run and converge
  adoption issue creation after a race.
- Make actionable/blocking/follow-up scan terminology unambiguous and bounded.
- Reconcile release status, memory, issue labels, durable links, and canonical
  indexes after publication.
- Close false-green test-evidence, temp ownership, compatibility, YAML, and CI
  credential-persistence gaps with focused existing-suite changes.

## Non-goals

- A hosted coordinator, GitHub App, central scanner, universal bootstrapper,
  semantic memory validator, or validator-for-validator chain.
- Automatic consumer merge, approval, or repair of ambiguous work.
- Retrofitting the correction into consumers that remain pinned before 0.8.1.
- Claiming distributed atomicity across local Git, GitHub Actions, and Issues.

## Readiness evidence

- Domain and contracts: repository host/slug, credential authority, release
  tag/commit, rename source/destination, dispatch correlation, issue identity,
  finding disposition, release projection, test scenario, runtime, and cleanup
  ownership are distinct concepts.
- Consumers and dependencies: the source launcher, seed workflow, bootstrap
  adapter, updater adapter, project protocol, documentation templates, memory,
  repository tests, and GitHub delivery records are affected.
- Compatibility: this is a backward-compatible correction released as 0.8.1;
  earlier pinned consumers remain governed by their reviewed version.
- Verification: focused PowerShell fixtures first, Windows PowerShell 5.1 and
  PowerShell 7 coverage, YAML parsing, one complete suite, one fresh-diff
  self-review, and one bounded confirmation after blocking fixes.

| ID | Classification | Risk | Status and owner | Response/evidence |
| --- | --- | --- | --- | --- |
| `RISK-0061` | Credential confidentiality | A hostless GitHub identity redirects PAT values | Mitigated; launcher owner | Host-qualified identity and multi-host regression fixture |
| `RISK-0062` | Release integrity | A target uses the wrong token or a stale pre-lock tag commit | Mitigated; updater owner | Protocol-token API boundary and exact locked-commit evidence |
| `RISK-0063` | Repository integrity | Bootstrap validation hides a rename-away deletion | Mitigated; bootstrap owner | Rename inference disabled for exact path sets plus a real-Git rename fixture |
| `RISK-0064` | Concurrency | Another run or issue creation is mistaken for this launcher session | Mitigated; launcher owner | Dispatch correlation and post-create issue convergence |
| `RISK-0065` | Process safety | Conflicting completion terms cause a blind loop or false completion | Mitigated; protocol owner | One disposition taxonomy and finite budget |
| `RISK-0066` | Evidence integrity | Declared test/status/link evidence outlives executed or published state | Mitigated; maintainers | Executable scenario inventory and post-publication reconciliation |
| `RISK-0067` | Test isolation | A suite deletes another run's temporary workspace | Mitigated; test owner | Cleanup only from an owned temp-root ledger |

| Test readiness | Gate 1 state | Evidence |
| --- | --- | --- |
| Scenarios | Defined | [TEST-0060 through TEST-0068](test-cases.md) |
| Test code | Planned before production changes | Existing suites receive focused regression cases; no new framework |
| Baseline run | Passed | v0.8.0 complete suite passed locally before this correction; the new scenarios are expected to expose the recorded gaps |

## Historical scan boundary and finite budget

This section reconstructs the FEAT-0011 scan declaration that its original
record should have contained. It describes the evidence available to that
delivery; it does not claim that the later FEAT-0012 findings were absent.

| Field | Historical declaration |
| --- | --- |
| Tracked scope | The complete post-change inventory of 102 tracked files: root protocol/version/release records, source launcher, consumer workflow and updater/bootstrap scripts, all PowerShell test suites and fixtures, templates, feature/decision/idea documentation, and project memory |
| Exclusions | External consumer repositories and their runtime state. No tracked generated or binary files existed. PSScriptAnalyzer was unavailable; hosted Windows/Ubuntu CI and PowerShell parsing supplied the declared portability evidence. Publication state did not yet exist during the pre-merge review. |
| Budget | One initial full-project scan, remediation of its blocking findings, and one confirmation scan. The later hosted `matrix.shell` failure was new failed evidence and reopened only its affected CI slice; it did not authorize another unchanged scan. |
| Initial result | `FIND-0093` through `FIND-0101` were prioritized and resolved in the slices below. |
| Historical stop claim | The local suite, slice reviews, and confirmation were reported green; hosted CI then exposed the fifth in-slice blocker. FEAT-0012 later proved that the evidence model still allowed `FIND-0102` through `FIND-0111`. |

## Decomposition and subfeature gates

| ID | Slice | Tracking | Tests/run | Self-review/findings | Status |
| --- | --- | --- | --- | --- | --- |
| `SUBF-0024` | Qualified repository, release, path, and dispatch evidence | [Issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) | `TEST-0060` through `TEST-0063`; passed | `FIND-0093` through `FIND-0095`, `FIND-0097`; resolved | Complete |
| `SUBF-0025` | Bounded governance and post-publication closure | [Issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) | `TEST-0064`, `TEST-0065`; passed | `FIND-0096`, `FIND-0098`; resolved | Complete |
| `SUBF-0026` | Executable test evidence, isolation, and CI least privilege | [Issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) | `TEST-0066` through `TEST-0068`; passed | `FIND-0099` through `FIND-0101`; resolved | Complete |

## Decisions and relationships

- Decision: [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md)
- Predecessor: [FEAT-0010](../FEAT-0010-protocol-stability-invariants/README.md)
- Existing invariant decision: [DEC-0010](../../decisions/DEC-0010-stable-automation-invariants.md)
- Bounded convergence: [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md)
- Credential boundary: [DEC-0005](../../decisions/DEC-0005-consumer-scoped-fine-grained-pat.md)
- Local execution boundary: [DEC-0008](../../decisions/DEC-0008-local-codex-execution.md)
- Tracking: [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36)

## Definition of Ready

- [x] Stable ID and linked issue.
- [x] Problem, outcome, scope, and non-goals.
- [x] Measurable acceptance criteria.
- [x] Identity, credential, release, path, concurrency, process, evidence, and
      cleanup contracts and consumers identified.
- [x] Numbered risks and DEC-0011.
- [x] Three independently reviewable slices.
- [x] Numbered test scenarios and verification approach.
- [x] Test-code and baseline states recorded.

## Acceptance criteria

1. Every launcher-owned GitHub operation targets the host verified from the
   Git remote; a configured alternate `GH_HOST` cannot redirect metadata or
   secret writes.
2. The updater verifies a selected private protocol release with the source
   credential and uses the exact locked tag commit for planning and mutation.
3. Full and manifest-only bootstrap proposals reject rename/copy provenance
   that removes any unrelated consumer path.
4. A lifecycle dispatch carries a unique correlation ID, and only a run with
   that identity is accepted; concurrent issue creation converges to one
   canonical issue or blocks without duplicate success.
5. One finding-disposition taxonomy makes bounded self-review and convergence
   completion agree without an unchanged review loop.
6. Published work reconciles feature/index/memory/issue state and uses durable
   main, tag, or commit links before an owned branch is deleted.
7. Every declared TEST ID maps to executable evidence; exact asset inventory,
   timeout behavior, YAML syntax, and supported PowerShell engines have
   meaningful regression coverage.
8. Test cleanup removes only paths created by that run, and read-only CI does
   not persist an unnecessary checkout credential.
9. Focused tests, the complete cross-platform suite, self-review, and one
   bounded confirmation pass with no unresolved blocking finding.

## Findings register

All rows had high confidence, affected the authorized FEAT-0011 scope, and were
`Blocking` until the referenced correction passed. The rows remain historical;
the later derivative evidence gaps are owned by
[FEAT-0012](../FEAT-0012-v082-correction/README.md).

| ID | Classification | Severity / confidence | Evidence and affected scope | Impact | Required action | Status and links |
| --- | --- | --- | --- | --- | --- | --- |
| `FIND-0093` | Verified defect - credential identity | High / High | Host identity was dropped before launcher GitHub operations in the [source launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) | A configured alternate CLI host could receive metadata or secret operations | Preserve and enforce `github.com` through every launcher-owned operation | Resolved by `TEST-0060`; [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) |
| `FIND-0094` | Verified defect - release authority | High / High | Updater release checks did not bind source credential, immutable state, and fetched commit in the [updater adapter](../../../templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1) | A wrong authority or moved pre-publication tag could drive mutation | Use the protocol credential and exact locked-commit evidence | Resolved by `TEST-0061`; [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md) |
| `FIND-0095` | Verified defect - path integrity | High / High | Bootstrap evidence could omit a rename-away source in the [bootstrap adapter](../../../templates/project/.github/scripts/Invoke-MeAndAICapabilitiesBootstrap.ps1) | An unrelated consumer path could be removed while the destination appeared allowed | Validate complete source/destination provenance | Resolved by `TEST-0062` |
| `FIND-0096` | Verified process defect | High / High | Review and scan completion used conflicting actionable/blocking terminology in the [protocol](../../../PROTOCOL.md) | Relabeling could hide a blocker or trigger an unchanged loop | Use one mutually exclusive disposition taxonomy and finite stop condition | Resolved by `TEST-0064`; [DEC-0011](../../decisions/DEC-0011-qualified-evidence-and-closure.md) |
| `FIND-0097` | Verified defect - workflow causality | Medium / High | Workflow-run selection used an insufficient time/commit window and issue creation lacked convergence in the [launcher](../../../scripts/Invoke-MeAndAIQuickAdoption.ps1) | A concurrent run or issue could be mistaken for the launcher session | Add dispatch correlation and post-create issue convergence | Resolved by `TEST-0063` |
| `FIND-0098` | Verified governance defect | Medium / High | Feature/index/memory/issue projections and branch-bound links could drift after publication | Canonical records could report inconsistent completion state | Reconcile current projections and use durable links | Resolved by historical `TEST-0065`; current v0.8.1 facts are retained by [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) and [release v0.8.1](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1) |
| `FIND-0099` | Verified evidence defect | Medium / High | Test-range text, asset counts, timeout claims, YAML parsing, and runtime labels exceeded the assertions in the repository suites | Green tests could overstate executed coverage | Couple each claim to focused executable evidence and supported boundaries | Partially corrected by historical `TEST-0066`/`TEST-0067`; the remaining semantic ownership gap is `FIND-0104` in [FEAT-0012](../FEAT-0012-v082-correction/README.md) |
| `FIND-0100` | Verified defect - test isolation | Medium / High | Cleanup selected same-prefix temporary paths not proven to belong to the current run | One suite could delete another run's workspace | Maintain an owned temporary-root ledger | Resolved by `TEST-0068` |
| `FIND-0101` | Verified risk - CI least privilege | Low / High | Root checkout persisted a credential unnecessary to read-only validation in [protocol CI](../../../.github/workflows/protocol-tests.yml) | A later step had broader credential availability than required | Set checkout credential persistence to false | Resolved by `TEST-0068` |

## In-slice blocking observations

The original review narrative mentioned five blocking observations without
making their ownership auditable. They were derivative implementation/test
failures under the root findings above, not independent root findings. All five
blocked their slice until corrected:

| No. | Owning finding | Classification / severity | Evidence and impact | Resolution / status |
| --- | --- | --- | --- | --- |
| 1 | `FIND-0093` | Test fixture contract / High | An escaped mock URI prevented the host-qualified fixture from exercising the intended request | Corrected in [quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1); resolved before merge |
| 2 | `FIND-0097` | Boundary binding / High | An empty issue inventory bound incorrectly and could hide the zero-result convergence path | Corrected in [quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1); resolved before merge |
| 3 | `FIND-0099` | Timeout fixture semantics / High | The timeout fixture selected the wrong mock mode and did not exercise the documented path | Corrected in [quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1); resolved before merge |
| 4 | `FIND-0099` | Process termination race / High | A child-process race hid the canonical timeout result | Corrected in [quick-adoption fixtures](../../../tests/quick-adoption.tests.ps1); resolved before merge |
| 5 | `FIND-0099` | Workflow compatibility / High | Hosted Actions rejected unsupported `matrix.shell` before any validation job started | Replaced with OS-qualified constant shells in [protocol CI](../../../.github/workflows/protocol-tests.yml); actionlint and hosted CI passed before merge |

## Self-review

Each slice received its focused review. The five blocking observations are now
enumerated and owned above. Four local fixture/implementation blockers were
corrected before the complete suite passed once in 225.3 seconds. The bounded
confirmation reported no remaining finding; new hosted evidence then exposed
the unsupported `matrix.shell` context before any job could start. The workflow
was corrected and hosted CI passed without adding an unchanged scan or validator
layer.

**2026-07-16 correction:** the confirmation claim was too strong because the
test-evidence model could still accept identifier substrings and contract-poor
mocks. The later full-project scan recorded `FIND-0102` through `FIND-0111` in
[FEAT-0012](../FEAT-0012-v082-correction/README.md). That correction does not
rewrite the commands that passed; it limits what those commands proved.

## Definition of Done

- [x] Acceptance criteria met.
- [x] Mandatory test code and scenario mapping complete.
- [x] Test commands and successful results recorded.
- [x] Slice reviews and bounded convergence stop condition complete.
- [x] No unresolved blocking finding; follow-ups, if any, are explicitly out of
      current scope and owned.
- [x] Documentation, durable links, version, changelog, and project memory current.
- [x] Issue, pull request, decisions, and related work cross-linked through the
      canonical external delivery record.
- [x] Applicable local gates pass; GitHub checks and publication evidence are
      retained by the linked pull request, issue, and immutable release.

## Post-merge release evidence

This section was authored in the FEAT-0011 pre-merge commit as though the
immutable release already existed. That was incorrect evidence timing and is
recorded as `FIND-0108` in
[FEAT-0012](../FEAT-0012-v082-correction/README.md). The release was later
published validly; the current facts below come from its external records and
do not retroactively validate the premature claim. Issue #36 also omitted direct
links back to FEAT-0011 and DEC-0011; future delivery issues must satisfy the
bidirectional link rule before closure.

| Field | Evidence |
| --- | --- |
| Release authority | [Immutable GitHub Release](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1) |
| Release identifier | `v0.8.1` |
| Target commit | Recorded by the immutable release and [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) after publication |
| Verification evidence | GitHub check and release/API evidence retained in the pull request and issue |
