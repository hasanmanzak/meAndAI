# FEAT-0011 - Close End-to-End Protocol Stability Gaps

| Field | Value |
| --- | --- |
| Classification | Feature correction |
| Status | Complete |
| Target version | 0.8.1 |
| Issue | [#36](https://github.com/hasanmanzak/meAndAI/issues/36) |
| Pull request | Recorded in [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) and updated before publication |
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

| ID | Classification / severity / confidence | Required resolution | Status |
| --- | --- | --- | --- |
| `FIND-0093` | Credential identity / High / High | Preserve and enforce `github.com` in every launcher GitHub operation | Resolved |
| `FIND-0094` | Release authority / High / High | Use protocol credential and commit-bound immutable-release evidence | Resolved |
| `FIND-0095` | Path integrity / High / High | Validate complete bootstrap rename provenance | Resolved |
| `FIND-0096` | Process semantics / High / High | Unify finding disposition and bounded stop conditions | Resolved |
| `FIND-0097` | Workflow causality / Medium / High | Add dispatch correlation and issue convergence | Resolved |
| `FIND-0098` | Closure consistency / Medium / High | Reconcile published state, labels, memory, indexes, and durable links | Resolved |
| `FIND-0099` | Test evidence / Medium / High | Couple declared scenarios to executed assertions and supported boundaries | Resolved |
| `FIND-0100` | Test isolation / Medium / High | Restrict cleanup to run-owned temporary roots | Resolved |
| `FIND-0101` | CI least privilege / Low / High | Disable checkout credential persistence | Resolved |

## Self-review

Each slice received its focused review. The review found and corrected four
blocking fixture or implementation defects: an escaped mock URI, an empty issue
inventory binding failure, a timeout fixture using the wrong mock mode, and a
process-termination race that hid the canonical timeout result. The complete
suite then passed once in 225.3 seconds. The bounded confirmation found no
remaining blocking finding; no unchanged scan or validator layer was added.

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

| Field | Evidence |
| --- | --- |
| Release authority | [Immutable GitHub Release](https://github.com/hasanmanzak/meAndAI/releases/tag/v0.8.1) |
| Release identifier | `v0.8.1` |
| Target commit | Recorded by the immutable release and [issue #36](https://github.com/hasanmanzak/meAndAI/issues/36) after publication |
| Verification evidence | GitHub check and release/API evidence retained in the pull request and issue |
