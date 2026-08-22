# [SUBF-0154](README.md#subf-0154) Consolidated Micro-Delivery Plan

| Field | Value |
| --- | --- |
| Classification | Ordered implementation control plan |
| Status | `AcceptedFrozenDesign`; `REPORT-SEALING-01` is `ReviewedLocalGreen`; its local route is green while [TEST-0222](test-cases.md#test-0222) remains Planned; canonical R remains immutable; Cohort 2 and exact-head hosted validation remain pending |
| Parent design | [Canonical report sealing design](subf-0154-canonical-report-sealing-design.md) |
| Exact design input | Reconciled exact main [`a291556b2fa3c6fbaac7fa564ed35baadb5e9626`](https://github.com/hasanmanzak/meAndAI/commit/a291556b2fa3c6fbaac7fa564ed35baadb5e9626) |
| Scenarios | [TEST-0222](test-cases.md#test-0222) and [TEST-0209](test-cases.md#test-0209) |

## Activation hold

This plan originally granted no implementation or expected-red authority.
Later scoped authority activated only the Cohort-1 predecessor-compilable
scaffold and its single immutable accepted canonical R under
[FIND-0464](README.md#find-0464); it is never rerun. The no-child offline
verifier passed, fresh final reviews closed without `Blocking`, and the
marker-free transform is `ReviewedLocalGreen`.

The design delivery is one consolidated checkpoint. The implementation uses
one branch and one PR with three semantic cohorts; there is no PR or hosted run
per internal micro-boundary. Each cohort nevertheless ends in one focused local
commit, one push to that PR branch, and exact-head Ubuntu/Windows hosted green
before its successor starts.

## Universal cohort gates

For every cohort:

1. record the cohort P/R classification; only Cohort 1 consumes canonical R,
   once, using the exact FQN, one fresh results directory, one TRX, the default
   VSTest connection behavior, a `420`-second outer bound, no fallback/retry/
   reuse, and the locked-adapter allowance of zero or one nonempty marker-free
   standard assertion `StackTrace`; the authoritative marker is the exact
   `ErrorInfo/Message`, while at most one same-result `StdOut` transcript may
   name the exact assembly/FQN, contain the marker once, and present that
   standard stack with no `StdErr`, foreign result, or independent diagnostic;
2. implement only its exact dependency-closed mutation and record allowlists;
3. run the exact focused Fact, cumulative [TEST-0222](test-cases.md#test-0222)/
   [TEST-0209](test-cases.md#test-0209) route reached so far, full Conformance
   and Domain tests, warning-as-error Release builds, format, diff, locks,
   public API/ownership and relevant structural checks;
4. perform one independent security/behavior/evidence review and resolve every
   `Blocking` before recording `ReviewedLocalGreen`;
5. synchronize only the canonical records owned by that cohort and create one
   focused local commit;
6. push the reviewed cohort commits once to the existing PR branch and require
   remote-equal exact-head Ubuntu/Windows hosted green before activating the
   next cohort.

Hosted failure reopens only the owning cohort. Separate local commits identify
the owner; repair, repeat the full cohort validation, push a new exact head and
wait for green. No later cohort advances across a failed hosted predecessor.

The final cohort alone activates scenario traits, status, owner rows, workflow
filters and runtime-efficiency inventory. Partial Facts remain trait-free under
the Active planned-scenario recurrence.

The cohort ledger records each focused commit, local gate, pushed exact head,
hosted run and repair separately. A short SHA is never a record identity: every
human-facing commit reference uses its full 40-hex commit permalink. New design,
plan and handoff paths are graph inputs only after the complete packet is
committed; filesystem-only pre-commit checks are not exact-HEAD graph evidence.
Committed-HEAD graph/identity readers must load the exact selected
[DEC-0036](../../decisions/DEC-0036-prospective-instruction-graph-capacity.md)
`1,048,576`/`8,388,608` limits, retain their reviewed caller-owned `240000`
deadline and the generic helper default `120000`, and never rerun an unchanged
failed acquisition.

The following six lock files are immutable fingerprints throughout all three
cohorts; any byte change stops for dependency review:

```text
src/MeAndAI.Protocol.Domain/packages.lock.json
src/MeAndAI.Protocol.Conformance.Abstractions/packages.lock.json
src/MeAndAI.Protocol.Conformance/packages.lock.json
src/MeAndAI.Protocol.Policy/packages.lock.json
tests/dotnet/MeAndAI.Protocol.Domain.Tests/packages.lock.json
tests/dotnet/MeAndAI.Protocol.Conformance.Tests/packages.lock.json
```

No cohort may add or update a package/project reference. Release validation
builds the four protocol source projects and both protocol test projects with
`--no-restore` and warnings as errors after the existing locked restore gate.

## Cohort 1: `REPORT-SEALING-01`

Outcome: add the exact six-type public report surface, kernel sealing method,
single canonical writer, completeness/redaction/resource checks and
[TEST-0222](test-cases.md#test-0222) behavior.

Canonical expected red:

```text
P: Applicable
R: Applicable / BehaviorRed
FQN: MeAndAI.Protocol.Conformance.Tests.CanonicalReportSealingTests.Seals_exact_typed_report_bytes_digest_redaction_and_dimensions
Marker: TEST-0222-REPORT-SEALING-RED-0001
```

The predecessor-compilable scaffold is direct and trait-free. It verifies the
frozen public type/member surface is absent through exact reflection and then
fails solely on the marker. Canonical acceptance requires exactly one discovered,
executed and failed result with no unrelated diagnostic. The green transform
uses direct public calls and preserves the red source/TRX separately.

The immutable accepted canonical R is frozen at source `1,886` bytes / SHA-256
`F7BC82040457A1CB585B152BBDAD8E69FBA88FC5A7210E6ED167FC079D47581E`
and accepted TRX `5,108` bytes / SHA-256
`4FFB591EAB6247DFC661D108501156BEEB33FBE746D191CE7E1B3B2F489D6C83`.
The raw TRX marker count is exactly `2`: one authoritative Message and one
locked same-result transcript occurrence. It has the exact Failed `1/1`
16-counter inventory, no attachment, and one permitted marker-free same-FQN
`[FAIL]` RunInfo. The original external runner remains separate diagnostic
evidence at `17,741` bytes / SHA-256
`61627FE78AF9E97BD5F5848F7BEBFF011D5E648DDFBDD710FEA74E723E92E89F`;
its exit `1` occurred after the completed invocation because its validator
overconstrained the permitted transcript to a byte-identical marker-only echo.
The corrected no-child verifier, SHA-256
`79AF177BDAFFA2A03BDAEBE18B84BCCEA059FC9639DA3FAD9040A1404C741F66`,
exited `0` with `accepted=true`. R was not rerun; the marker-free transform is
locally green and [FIND-0464](README.md#find-0464) custody remains immutable.

Mutation allowlist:

- modify `src/MeAndAI.Protocol.Conformance/Activation/ConformanceKernel.cs`
  only for the frozen subject-repository planning overload;
- modify `src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityPlan.cs` only
  for the internal immutable subject-repository carrier;
- modify `src/MeAndAI.Protocol.Conformance/Planning/ApplicabilityPlanningCore.cs`
  only for anchor validation/retention and existing-overload compatibility;
- add `src/MeAndAI.Protocol.Conformance/Reporting/CanonicalConformanceReport.cs`;
- add `src/MeAndAI.Protocol.Conformance/Reporting/CanonicalReportIntegrityException.cs`;
- add `src/MeAndAI.Protocol.Conformance/Reporting/CanonicalReportCore.cs`;
- add `src/MeAndAI.Protocol.Conformance/Reporting/ConformanceKernel.Reporting.cs`;
- add `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/CanonicalReportSealingTests.cs`;
- modify `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ProtectedPolicySurfaceTests.cs`
  only to advance the exact final public signature inventory from Conformance
  `35`/non-Domain `149` to Conformance `41`/non-Domain `155` and include
  `CanonicalConformanceReport.SubjectRepository`, the three-argument
  `ConformanceKernel.PlanApplicability` overload and
  `ConformanceKernel.SealReport`;
- synchronize exactly the eleven record paths in the record allowlist below,
  only after product/test gates pass.

No other Activation/Planning source, project reference, lock file,
Domain/Abstractions/Policy source, predecessor test FQN/trait, workflow or owner
file may change. Existing `CatalogSliceKernel.PlanApplicability` and evaluation
advance behavior remain unchanged.

Hard changed-line cap: `4,200` normalized production plus test additions/
deletions. Canonical source frame cap: `67,108,864` bytes. Equality passes;
first one over stops for design review.

Minimum focused verification:

```text
dotnet test tests/dotnet/MeAndAI.Protocol.Conformance.Tests/MeAndAI.Protocol.Conformance.Tests.csproj -c Release --no-restore --filter FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests.CanonicalReportSealingTests.Seals_exact_typed_report_bytes_digest_redaction_and_dimensions
```

Oracles include exact signature inventory, all four result dimensions,
predecessor-bound subject repository for nonempty and zero-outcome plans,
canonical reviewed-literal bytes/digest, input-order equality, `en-US`/`tr-TR`,
same-input OS equality, framed LF-versus-CRLF inequality,
typed location variants, proposed-transition presence/absence, report-safe
acquisition/rule/disposition projection, predecessor-array mutation isolation,
waiver/debt free-text plus credential/raw-content exclusion, every integrity
error/order branch, defensive byte/list
ownership, exact resource equality/first-over, cancellation, and one-byte/root-
field tampering.

## Cohort 2: `COMPOSED-QUALIFICATION-01`

Outcome: prove the direct real-kernel composition across
[SUBF-0152](README.md#subf-0152), [SUBF-0153](README.md#subf-0153),
[SUBF-0143](README.md#subf-0143), [SUBF-0144](README.md#subf-0144), and
[SUBF-0154](README.md#subf-0154) without consuming child-test results.

P/R classification:

```text
P: NotApplicable
R: NotApplicable
FQN: MeAndAI.Protocol.Conformance.Tests.ComposedQualificationTests.Qualifies_exact_acquisition_evaluation_conformance_enforcement_and_report_dimensions
```

The direct test uses one fresh project-neutral production fixture and the
public report seam from cohort 1. It invokes no prior Fact, runner, source text,
pass marker or green result and contains no artificial failure marker. A
natural product defect reopens Cohort 1; no retrospective R is invented.

Mutation allowlist:

- add `tests/dotnet/MeAndAI.Protocol.Conformance.Tests/ComposedQualificationTests.cs`;
- change the four report production files from cohort 1 only if a fresh review
  identifies a genuine report-owned defect; such a repair reopens cohort 1,
  repeats its full gates, and requires a new exact-head hosted-green predecessor;
- synchronize exactly the eleven record paths in the record allowlist below,
  only after test gates pass.

No convenience composition facade, evaluator, Policy export, acquisition
adapter, protected-policy behavior, predecessor Fact, workflow or owner file is
allowed. Expected green is normally test/evidence-only.

Hard changed-line cap: `2,000` normalized additions/deletions. The scenario
matrix must cover at least one row for every acquisition status, every rule
evaluation status, every verdict, every enforcement decision, valid waiver,
unchanged debt, new/worsened/resurrected violation, missing/duplicate/stale/
unknown/malformed/redacted evidence, and proposed-versus-active isolation.

Minimum focused verification is the exact FQN above. Cumulative verification
selects both exact new FQNs, then full Conformance and Domain. The direct
fixture must build its own typed values and call the real kernel; child Facts
remain independent evidence.

## Cohort 3: `REPORT-CONVERGE-01`

Outcome: freeze the final two-FQN topology and atomically activate
[TEST-0222](test-cases.md#test-0222) and [TEST-0209](test-cases.md#test-0209)
only after cohorts 1 and 2 are exact-head hosted green.

This cohort has no expected-red marker and no product behavior. P and R are
`NotApplicable`; existing structural/ownership/runtime-efficiency checks are
ordinary validation gates, not R. It may add one direct convergence Fact only
when the existing infrastructure contract cannot express the exact two-FQN
topology without invoking either behavior Fact.

Mutation allowlist:

- modify only the two new test files to add their final exact `Scenario`
  traits;
- modify `tests/scenario-ownership.psd1` for exactly the two owner rows;
- modify `.github/workflows/protocol-tests.yml` for exactly the stable-job
  target/filter additions;
- modify `tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1`
  only for the exact [TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146)
  two-FQN owner inventory required by its current contract;
- synchronize exactly the eleven record paths below to mark only proven state;
- no production source, project reference, lock file or predecessor test
  mutation.

Hard changed-line cap: `1,200`; aggregate [SUBF-0154](README.md#subf-0154)
production plus test cap: `7,400`. Equality passes; first one over requires a
design redraw. Documentation and append-only evidence logs are outside the
product/test cap but remain subject to the repository's graph/blob limits.

Final local gates include both exact focused FQNs, the exact two-FQN Scenario
filter, full Conformance and Domain, stable workflow target/filter topology,
[TEST-0146](../FEAT-0035-test-runtime-efficiency/test-cases.md#test-0146),
Release builds, format, locks, API/ownership, graph/StructureOnly and
publication-evidence checks without a publication claim, plus one full cohort
diff review. Only then may records say `ReviewedLocalGreen`; push and exact-head
hosted green change it to `ExactHeadHostedGreen`.

## Exact record allowlist

Every cohort may synchronize only these records; unchanged paths are not
mechanically rewritten. This design packet's design, plan and handoff are three
new governance inputs and become nodes, with ordinary canonical-link relations,
only after commit. No new graph vocabulary or validator is created; exact
node/relation delta and capacity are proved only from the complete committed-
HEAD graph and remain pending before that gate:

```text
.ai/memory/README.md
.ai/memory/log/README.md
.ai/memory/project.md
.ai/memory/log/2026-08-21-feat-0065-subf-0154-design-freeze.md
docs/architecture/protocol-governance-and-execution/README.md
docs/architecture/protocol-governance-and-execution/successor-delivery-plan.md
docs/features/README.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/README.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/test-cases.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0154-canonical-report-sealing-design.md
docs/features/FEAT-0065-shared-executable-conformance-runtime/subf-0154-micro-delivery-plan.md
```

## Commit, PR and completion semantics

The three cohort commits remain separate and focused on one branch and one PR.
The final PR body links [FEAT-0065](README.md), [SUBF-0154](README.md#subf-0154),
[TEST-0222](test-cases.md#test-0222), [TEST-0209](test-cases.md#test-0209), the
exact expected-red evidence and exact-head hosted run. A canonical PR root URL
is used; `/checks` is never the record identity.

Merge readiness requires all review threads closed, exact remote head equal to
the reviewed local head, mergeability green, both stable jobs green on that
head, records synchronized, and no unauthorized diff. Slice completion is
claimed only after merge, exact-main Ubuntu/Windows hosted green, final record
sync, feature-level composed audit and the applicable Definition of Done gates.

This plan does not authorize release, publication, consumer mutation, shared
execution authority, managed integration, authority transfer or PowerShell
retirement.

## Design-cohort verification budget

This Gate 2 checkpoint uses one fresh static design/security/evidence review
and at most one changed-diff confirmation if a `Blocking` repair is required,
under [DEC-0004](../../decisions/DEC-0004-bounded-completion-convergence.md) and
[DEC-0012](../../decisions/DEC-0012-bounded-correction-and-external-release-evidence.md).
No long StructureOnly, publication-evidence, build/test, expected-red, hosted,
push or PR action belongs to the design checkpoint.

Design readability cap is `1,400` normalized lines; this plan cap is `480`.
Equality passes. First one over requires removal of redundancy or an explicit
reviewed split, never deletion of trust, framing, redaction, resource, oracle
or authority content.
