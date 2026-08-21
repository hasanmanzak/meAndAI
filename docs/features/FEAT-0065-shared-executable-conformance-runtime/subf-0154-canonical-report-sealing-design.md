# [SUBF-0154](README.md#subf-0154) Canonical Report Sealing Design

| Field | Value |
| --- | --- |
| Classification | Gate 2 design freeze |
| Status | `AcceptedFrozenDesign`; implementation remains held |
| Exact design input | Reconciled exact main [`a291556b2fa3c6fbaac7fa564ed35baadb5e9626`](https://github.com/hasanmanzak/meAndAI/commit/a291556b2fa3c6fbaac7fa564ed35baadb5e9626), which merges [PR #186](https://github.com/hasanmanzak/meAndAI/pull/186); exact-main hosted-green evidence remains unclaimed in this checkpoint |
| Parent feature | [FEAT-0065](README.md) |
| Dependencies | [SUBF-0153](README.md#subf-0153), [SUBF-0143](README.md#subf-0143), and [SUBF-0144](README.md#subf-0144) |
| Canonical scenarios | [TEST-0222](test-cases.md#test-0222) and [TEST-0209](test-cases.md#test-0209) |
| Delivery control | [Consolidated micro-delivery plan](subf-0154-micro-delivery-plan.md) |

## Authority and activation boundary

This checkpoint consumes design-only authority. It freezes the report contract,
canonical byte grammar, digest boundary, security exclusions, errors, resource
limits, scenario seams, and implementation cohorts. It does not authorize an
expected-red invocation or a production, test, workflow, owner, status, push,
pull-request, hosted, merge, release, publication, or consumer mutation.

[SUBF-0144](README.md#subf-0144) is the exact predecessor input and is merged at
exact main [`a291556b2fa3c6fbaac7fa564ed35baadb5e9626`](https://github.com/hasanmanzak/meAndAI/commit/a291556b2fa3c6fbaac7fa564ed35baadb5e9626),
but exact-main hosted-green evidence is not established by this checkpoint.
Therefore [SUBF-0154](README.md#subf-0154) implementation cannot activate from
this design checkpoint. Activation requires all of the following, in order:

1. exact-main [`a291556b2fa3c6fbaac7fa564ed35baadb5e9626`](https://github.com/hasanmanzak/meAndAI/commit/a291556b2fa3c6fbaac7fa564ed35baadb5e9626)
   Ubuntu/Windows hosted green;
2. one fresh changed-diff design/security/evidence review with no `Blocking`;
3. an explicit implementation directive for the frozen cohorts.

The design cohort is deliberately consolidated. No appendix, secondary report
schema, derivative validator, or design-only per-boundary PR/hosted checkpoint
is created.

## Outcome and ownership

The protocol-owned Conformance kernel seals one complete typed protected-policy
evaluation into one immutable, safe report snapshot and one deterministic byte
sequence. SHA-256 of those exact bytes is the report digest. The report is
read-only product output; it performs no I/O and grants no publication,
mutation, release, or authority-transfer capability.

Ownership remains separated:

- Domain continues to own the closed outcome values and typed evidence
  locations from [SUBF-0152](README.md#subf-0152) and
  [SUBF-0153](README.md#subf-0153).
- Conformance continues to own acquisition closure, rule evaluation,
  protected-policy disposition, debt/waiver precedence, and the new report
  snapshot/writer.
- Application and hosts may later write already sealed `CanonicalBytes` to
  stdout or a local artifact. They cannot re-evaluate or reserialize it.
- Publication remains a separate future use case and envelope under
  [DEC-0035](../../decisions/DEC-0035-protocol-owned-governance-and-execution-architecture.md).
- Durable authority, grants, journals, recovery, provider adapters, consumer
  integration, release and publication remain outside this subfeature.

## Applicable recurrence knowledge

These exact Active project-memory recurrences apply:

1. `Record synchronization reintroduces noncanonical cross-record links`:
   every governed identifier remains linked to its canonical record and a PR
   record uses the canonical PR root, never `/checks`.
2. `Planned multi-slice scenario is asserted before final activation`: both
   new Facts remain trait-free until `REPORT-CONVERGE-01` atomically changes
   scenario status, owner rows, workflow filters and runtime inventory.
3. `Frozen delivery oracle contradicts locked adapter serialization`: the sole
   Cohort-1 R accepts zero or one nonempty marker-free standard xUnit assertion
   `StackTrace`; no other `ErrorInfo` sibling is accepted.
4. `VSTest testhost connection aborts before discovery`: the standard VSTest
   connection behavior and one `420`-second outer bound are retained; a
   zero-discovery connection abort is infrastructure evidence, never R.
5. `Small-context packet advancement outruns the canonical ledger`: the three
   cohort commits and their local/hosted state are recorded separately before
   any successor activates; no combined after-the-fact green claim is allowed.
6. `Human-facing commit reference lacks an exact commit permalink`: every
   human-facing commit identity uses its full 40-hex permalink.
7. `Untracked governance packet is absent from the HEAD self-consumer graph`:
   the new design, plan and handoff remain untracked-graph inputs until their
   complete packet is committed; pre-commit filesystem checks cannot be called
   exact-HEAD graph evidence.
8. `Selected-profile expected readers retain generic acquisition bounds`: the
   committed-HEAD graph/identity readers load the exact selected
   [DEC-0036](../../decisions/DEC-0036-prospective-instruction-graph-capacity.md)
   limits `1,048,576`/`8,388,608`, use their reviewed caller-owned `240000`
   deadline, and preserve the generic helper default `120000`; an unchanged
   failed acquisition is never rerun.

No additional report/canonical-serialization-specific Active recurrence is
present in the current project-memory inventory. This explicit `None` does not
retire or weaken the eight applicable recurrences above. The design, plan and
handoff are three new governance inputs that become graph nodes when committed,
and their canonical links can add relations. They add no new relation
vocabulary or validator. Exact node/relation delta and capacity remain pending
until the complete packet exists in a committed-HEAD graph.

## Same-contract and WIP inventory

The nearest same-contract artifacts were reviewed under
[DEC-0030](../../decisions/DEC-0030-distinct-test-intent-and-infrastructure-contract-boundary.md):

| Artifact | Disposition | Reason |
| --- | --- | --- |
| Preserved [FEAT-0060](../FEAT-0060-any-consumer-governance-cli/README.md) governance report/serializer at WIP commit [`1873c98638ba4960734aadb188eb8c8d70b4bc52`](https://github.com/hasanmanzak/meAndAI/commit/1873c98638ba4960734aadb188eb8c8d70b4bc52) | `SupersededDuplicate` | Repository-only, mixed outcomes and old authority labels cannot define the successor schema; it is historical oracle input only. |
| [TEST-0195](../FEAT-0060-any-consumer-governance-cli/test-cases.md#test-0195) | `Distinct` | Preserved WIP model scenario; it cannot be invoked or consumed as product evidence. |
| [TEST-0222](test-cases.md#test-0222) | Canonical owner | Owns schema completeness, byte order, digest, redaction, culture/runtime/OS equality and tamper rejection. |
| [TEST-0209](test-cases.md#test-0209) | `Distinct` composed owner | Owns direct production composition and the four-dimensional semantic matrix; it does not aggregate child-test results. |
| Protected-policy frames from [SUBF-0144](README.md#subf-0144) | Reusable input identity only | Their digests are typed report fields; their private writers are not the final report writer. |

The WIP extraction ledger therefore contributes no directly reusable report
implementation or passing state. Copying its DTOs, serializer, authority label,
test, workflow, or result is forbidden.

## Frozen typed input

The sole production input is the already completed
`ProtectedPolicyEvaluation` minted by the exact `ConformanceKernel` instance.
It contributes these immutable predecessor facts:

- `RuntimeBinding`: protocol version, source commit, manifest, catalog, policy
  pack, runtime artifact, trust anchor and binding digests;
- `Baseline`: exact catalog/profile, sealed acquisition outcomes, baseline rule
  evaluations, known-violation/unresolved flags and baseline verdict;
- `ActiveExtensions`: active snapshot, protected pack binding, authority set,
  activation record and epoch;
- optional `ProposedTransition`, reported separately and never allowed to alter
  active results;
- extension evaluations and finding disposition rows, projected to safe
  digest/authority/time fields rather than retained directly;
- protected disposition authority, waiver/debt snapshot digests and
  authority-supplied evaluation UTC;
- evidence-set and outcome-set digests;
- final conformance verdict and enforcement decision.

The report also needs the subject repository and exact snapshot/event identity
even when the selected profile has no evidence slots and therefore produces
zero acquisition outcomes. The accepted predecessor currently permits an empty
`ApplicabilityPlan.Targets`; no downstream outcome can reconstruct the missing
subject. This design therefore freezes one narrow predecessor correction rather
than adding caller metadata to `SealReport`:

```csharp
public sealed partial class ConformanceKernel
{
    public ApplicabilityPlan PlanApplicability(
        NamedExecutionProfile profile,
        AcquisitionTarget subjectRepository,
        IEnumerable<AcquisitionTarget> targets);
}
```

`subjectRepository` is an existing immutable typed `AcquisitionTarget`, not a
string bag or report-time argument. It must have `SurfaceKind.Repository`, the
profile `SnapshotKind`, and the exact subject/snapshot identity of every active
target. If an active repository target exists it must be value-equal to this
anchor. The planning session defensively retains the anchor on its issued
`ApplicabilityPlan`; `ApplicabilityClosure`, `EvaluationClosure`,
`CompleteCatalogEvaluation` and `ProtectedPolicyEvaluation` already preserve
that exact plan/closure custody chain. A no-input plan therefore has zero
outcomes but one predecessor-bound subject repository. The existing two-
argument overload remains source/binary compatible; a plan issued through it
without a repository target has no report anchor and `SealReport` rejects it as
`DimensionInconsistent`. It is never repaired from report-time metadata.

The implementation carve-out is restricted to
`Activation/ConformanceKernel.cs`, `Planning/ApplicabilityPlan.cs` and
`Planning/ApplicabilityPlanningCore.cs`: add the overload, an internal immutable
`SubjectRepository` carrier, and the validation above. No Domain type, catalog
rule, target equality, slice-kernel API, acquisition behavior or evaluation
advance behavior changes. The report projects the retained anchor through the
existing immutable `AcquisitionTarget` type.

The overload first preserves the existing `profile`/session validation, then
throws `ArgumentNullException(subjectRepository)` for a null anchor and the
existing `CatalogIntegrityException(PlanStateInvalid)` for a non-repository,
profile-snapshot-mismatched, active-target-mismatched or duplicate/invalid
target tuple. It materializes `targets` once under the existing cap/order rules
and stores either the supplied valid anchor or, for the old overload, the exact
single repository target already in that materialization. It never synthesizes
an `AcquisitionTarget` or retains the caller's enumerable.

The kernel validates reference custody before sealing: the evaluation's
baseline catalog is the kernel catalog, its internal consumed closure is the
same closure used to mint the evidence-set digest, its runtime manifest/catalog
digests match the kernel, and its protected active policy is exactly the one
bound into the runtime and disposition authority. Equal digest text cannot
substitute a foreign object where predecessor custody requires reference
identity.

The report does not retain `ProtectedPolicyEvaluation`,
`CompleteCatalogEvaluation`, `EvaluationClosure`, `SealedAcquisitionOutcome`,
`RuleEvaluation`, `ExtensionEvaluation`, `FindingDispositionResult`, an
evaluator, capability, repository tree, parser/index/projector, verifier,
delegate, stream, provider DTO, or mutable collection. Report-owned immutable
rows project only safe typed identities, status, digests, flags and codes into
fresh read-only collections. Caller mutation or an array cast against a
predecessor collection cannot change the report after sealing.

## Four independent result dimensions

The report keeps these dimensions separate and never derives one by rewriting
another:

1. `AcquisitionStatus` is `Failed` when any retained required acquisition is
   `Failed`, otherwise `Incomplete` when any is `Incomplete`, otherwise
   `Complete`. Every acquisition row remains separately visible.
2. `RuleEvaluations` project each baseline and extension rule's exact
   `Satisfied`, `Violated`, `NotApplicable`, or `NotEvaluated` status and
   findings/failures. Missing or failed required acquisition remains
   `NotEvaluated`, never `NotApplicable`.
3. `Verdict` is the already validated aggregate `Conforming`,
   `NonConforming`, or `Indeterminate`. Known violations remain visible when
   unresolved required work makes the verdict `Indeterminate`.
4. `Enforcement` is the already validated `Allow`, `Block`, or `ReportOnly`
   result of the exact profile phase and waiver/debt precedence. Waiver or
   unchanged historical debt can affect enforcement but never converts a
   violation to satisfaction or a non-conforming verdict to conforming.

`Dispositions` are a reported explanation of enforcement, not a fifth verdict.
The report rejects a disposition that does not correspond one-to-one with a
retained finding or that changes the protected evaluation's frozen outcome-set
projection.

## Exact public API

All new public types are in `MeAndAI.Protocol.Conformance`. No new Domain,
Conformance.Abstractions or Policy public type is added.

```csharp
public sealed class CanonicalConformanceReport
{
    public string SchemaKey { get; }
    public string SchemaVersion { get; }
    public RuntimeQualificationBinding RuntimeBinding { get; }
    public AcquisitionTarget SubjectRepository { get; }
    public CatalogVersion CatalogVersion { get; }
    public ExactSha256Digest CatalogDigest { get; }
    public string ProfileName { get; }
    public ExecutionProfile Profile { get; }
    public AcquisitionStatus AcquisitionStatus { get; }
    public IReadOnlyList<CanonicalAcquisitionResult> Acquisitions { get; }
    public IReadOnlyList<CanonicalRuleResult> RuleEvaluations { get; }
    public IReadOnlyList<CanonicalFindingDisposition> Dispositions { get; }
    public ExactSha256Digest ActiveExtensionSnapshotDigest { get; }
    public ExactSha256Digest ActiveAuthoritySetDigest { get; }
    public ExactSha256Digest ActivationRecordDigest { get; }
    public long ActivationEpoch { get; }
    public ExactSha256Digest DispositionAuthorityBindingDigest { get; }
    public ExactSha256Digest WaiverSnapshotDigest { get; }
    public ExactSha256Digest DebtSnapshotDigest { get; }
    public DateTimeOffset EvaluationUtc { get; }
    public ExactSha256Digest? ProposedExtensionSnapshotDigest { get; }
    public string? ProposedTargetCommit { get; }
    public ExactSha256Digest? ProposedTransitionDigest { get; }
    public bool HasKnownViolation { get; }
    public bool HasUnresolvedRequiredEvaluation { get; }
    public ExactSha256Digest EvidenceSetDigest { get; }
    public ExactSha256Digest OutcomeSetDigest { get; }
    public ConformanceVerdict Verdict { get; }
    public EnforcementDecision Enforcement { get; }
    public IReadOnlyList<byte> CanonicalBytes { get; }
    public ExactSha256Digest ReportDigest { get; }
}

public sealed class CanonicalAcquisitionResult
{
    public string SlotKey { get; }
    public AcquisitionTarget Target { get; }
    public AcquisitionStatus Status { get; }
    public bool IsProjected { get; }
    public ExactSha256Digest OutcomeDigest { get; }
    public EvidenceScope? Scope { get; }
    public ExactSha256Digest? ContextQualificationProofDigest { get; }
    public bool? RequiredValuesOmitted { get; }
    public bool? NonRequiredValuesOmitted { get; }
    public IReadOnlyList<string> FailureCodes { get; }
}

public sealed class CanonicalRuleResult
{
    public PolicyRuleIdentity Rule { get; }
    public RuleEvaluationStatus Status { get; }
    public bool IsApplicabilityUnresolved { get; }
    public IReadOnlyList<string> UnresolvedSlotKeys { get; }
    public IReadOnlyList<ProtectedFindingIdentity> Findings { get; }
    public IReadOnlyList<EvaluationFailureCode> Failures { get; }
}

public sealed class CanonicalFindingDisposition
{
    public ProtectedFindingIdentity Finding { get; }
    public FindingDisposition Disposition { get; }
    public ExactSha256Digest? WaiverDeclarationDigest { get; }
    public ReviewedAuthorityPermalink? WaiverDecisionAuthority { get; }
    public DateTimeOffset? WaiverExpiresUtc { get; }
    public ExactSha256Digest? DebtEntryDigest { get; }
    public ReviewedAuthorityPermalink? DebtAuthority { get; }
    public DateTimeOffset? DebtExpiresUtc { get; }
}

public sealed class CanonicalReportIntegrityException : InvalidOperationException
{
    public CanonicalReportIntegrityCode Code { get; }
    internal CanonicalReportIntegrityException(CanonicalReportIntegrityCode code);
}

public sealed class CanonicalReportIntegrityCode :
    IEquatable<CanonicalReportIntegrityCode>
{
    public static CanonicalReportIntegrityCode EvaluationContextMismatch { get; }
    public static CanonicalReportIntegrityCode DimensionInconsistent { get; }
    public static CanonicalReportIntegrityCode DigestMismatch { get; }
    public static CanonicalReportIntegrityCode ResourceLimitExceeded { get; }
    public string Value { get; }
    public static CanonicalReportIntegrityCode Parse(string value);
    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CanonicalReportIntegrityCode? result);
    public bool Equals(CanonicalReportIntegrityCode? other);
    public override bool Equals(object? obj);
    public override int GetHashCode();
    public override string ToString();
}

public sealed partial class ConformanceKernel
{
    public ApplicabilityPlan PlanApplicability(
        NamedExecutionProfile profile,
        AcquisitionTarget subjectRepository,
        IEnumerable<AcquisitionTarget> targets);

    public CanonicalConformanceReport SealReport(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken = default);
}
```

The report and its three report-row types have no public constructor, factory,
setter,
conversion, deconstruction, serializer attribute, mutable byte exposure, or
public parser. `CanonicalBytes` is a defensive read-only snapshot. The report
digest is SHA-256 over exactly that snapshot; it is not inserted into its own
digest scope. A later publication envelope binds `ReportDigest`, avoiding a
cycle.

The four exact integrity tokens are:

```text
protocol.report.evaluation-context-mismatch
protocol.report.dimension-inconsistent
protocol.report.digest-mismatch
protocol.report.resource-limit-exceeded
```

The code value follows the established closed-token parse/equality contract.
The exception constructor is internal, rejects null, and uses `Code.Value` as
its message. Message text beyond that token, `ParamName`, private layout and
hash integer values are not compatibility oracles.

The final public surface adds exactly six Conformance types, one planning
overload and one sealing method. Starting from the accepted
[SUBF-0144](README.md#subf-0144) totals, the
expected export totals become Domain `40`, Conformance.Abstractions `112`,
Conformance `41`, Policy `2`, and non-Domain aggregate `155`. The final API
oracle owns the complete ordinal type/member signature inventory, not counts
alone.

## Canonical frame and digest

There is one writer: internal `CanonicalReportCore`. It emits one versioned
binary frame beginning with exact ASCII/UTF-8 separator
`protocol.conformance-report/1\n`. No other production or test writer may
serialize a report or duplicate its digest scope.

Its frozen internal seams are
`CanonicalReportCore.Write(CanonicalReportFrame frame, CancellationToken cancellationToken)`
returning a fresh `byte[]`, and
`CanonicalReportCore.ValidateDigest(IReadOnlyList<byte> canonicalBytes,
ExactSha256Digest expectedDigest)`. `CanonicalReportFrame` is an internal,
immutable, defensively-owned projection in `CanonicalReportCore.cs`; it carries
only the fields in the exhaustive table below and has no public/test-only
factory or mutable collection.

Primitive framing matches the accepted predecessor conventions:

- UTF-8 is strict, without BOM or replacement fallback; strings are unsigned
  big-endian 32-bit byte length plus exact bytes;
- lists use unsigned big-endian 32-bit count;
- revisions and bounded nonnegative 32-bit scalars use unsigned big-endian
  32-bit values;
- epochs, counts and UTC ticks use big-endian signed 64-bit two's-complement
  after range validation;
- digests are raw 32 bytes, booleans are one byte `00` or `01`, and optional
  fields are one-byte absence/presence followed by the value when present;
- all comparisons and sorting are ordinal; no culture, platform newline,
  enum ordinal, JSON property order, assembly identity, MVID, object identity,
  localized text, exception message, or filesystem path normalization enters
  the frame.

The root field order is exact:

1. schema key `protocol.conformance-report` and version `1`;
2. runtime binding fields in their public declaration order;
3. predecessor-bound `SubjectRepository` target fields;
4. catalog version, complete inventory digest, profile name, then the five
   profile axes in [SUBF-0152](README.md#subf-0152) order;
5. active extension snapshot, authority-set, activation-record, epoch,
   disposition-authority binding, waiver snapshot, debt snapshot and UTC;
6. optional proposed transition as active digest, proposed digest, target
   commit, rationale digest, transition digest and ordinal change rows;
7. acquisition dimension summary followed by acquisition rows;
8. baseline evaluation rows;
9. extension evaluation rows;
10. finding-disposition rows;
11. known-violation and unresolved-required flags, evidence-set digest,
    outcome-set digest, verdict and enforcement.

Every composite begins with the framed string tag shown below. `O(x)` is the
one-byte optional presence followed by `x`; `L(x)` is the unsigned count then
rows; a union is exactly one listed tag and its fields. This table is the
exhaustive tag/field order; “fields in declaration order” is not an alternate
writer rule.

| Composite / union tag | Exact following fields |
| --- | --- |
| `report` | schema key, schema version, `runtime`, `target` subject repository, `profile`, `active-policy`, `O(transition)`, acquisition status, `L(acquisition)`, `L(baseline-rule)`, `L(extension-rule)`, `L(disposition)`, known-violation, unresolved-required, evidence-set digest, outcome-set digest, verdict, enforcement |
| `runtime` | protocol version, source commit, manifest digest, catalog digest, policy-pack-binding digest, runtime-artifact digest, trust-anchor digest, binding digest |
| `target` | subject identity, source identity, surface token, snapshot-kind token, target identity |
| `profile` | catalog-version u32, catalog inventory digest, profile name, subject-role, operation, snapshot-kind, `L(surface token)`, enforcement-phase |
| `active-policy` | active snapshot digest, authority-set digest, activation-record digest, activation epoch i64, disposition-authority-binding digest, waiver-snapshot digest, debt-snapshot digest, evaluation UTC ticks i64 |
| `transition` | active snapshot digest, proposed snapshot digest, target commit, rationale digest, transition digest, `L(change)` |
| `change` union: `added` / `removed` / `revised` | extension ID, `O(previous-definition digest)`, `O(proposed-definition digest)`; absence tuple is respectively `0/1`, `1/0`, `1/1` |
| `acquisition` | slot key, `target`, status, projected flag, outcome digest, `O(scope)`, `O(requirement-acquisition)`, `O(reference)` context proof, `L(attempt)`, `L(acquisition-failure)` |
| `scope` | `target`, `boundary` |
| `boundary` | snapshot-kind, boundary identity, started-UTC ticks i64, completed-UTC ticks i64 |
| `requirement-acquisition` | `requirement`, consistency-class, `redaction`, `L(acquisition-failure)`, status |
| `requirement` | key, surface, kind, completeness contract, payload schema key, payload schema version, `L(accepted consistency class)` |
| `redaction` | required-values-omitted, non-required-values-omitted |
| `attempt` | instruction digest, admission-kind, status, receipt digest, `O(scope)`, `O(requirement-acquisition)`, `L(acquisition-failure)` |
| `acquisition-failure` | requirement key, code |
| `baseline-rule` | rule ID, revision u32, status, applicability-unresolved, `L(reference)` applicability, `L(unresolved slot key)`, `L(baseline-finding)`, `L(evaluation-failure)` |
| `extension-rule` | extension ID, revision u32, status, applicability-unresolved, `L(reference)` applicability, `L(unresolved slot key)`, `L(extension-finding)`, `L(evaluation-failure)` |
| `baseline-finding` | rule ID, revision u32, finding code, severity, remediation, `reference` primary, `L(reference)` related |
| `extension-finding` | extension ID, revision u32, finding code, severity, remediation, `reference` primary, `L(reference)` related, stable-state token, `O(stable-state value)` |
| `evaluation-failure` union: `baseline-failure` / `extension-failure` | rule ID or extension ID, revision u32, failure code, `reference` primary, `L(reference)` related |
| `reference` | reference-kind, manifest digest, catalog-version u32, slot key, requirement key, `scope`, qualification-proof digest, `O(root-reference)`, `O(location union)`, `L(derivation)`, `O(expected-selector-parent-kind)`, `O(selector)` |
| `root-reference` | `scope`, content schema key, content schema version, content digest, `location`, `L(requirement key)`, capture UTC ticks i64 |
| `derivation` | `component`, artifact filename, artifact digest, `O(model)`, `O(capability)`, typed-node kind, typed-node identity, `location` |
| `component` | component key, component version, assembly name, type name |
| `model` | model key, model version, implementation `component` |
| `capability` | capability key, capability version, interface `component` |
| `selector` | selector key, selector schema key, canonical value |
| `location` union: `repository-location` | `scope`, repository-relative path, `O(blob identity)`, `O(line u32)`, `O(anchor)`, `O(property)` |
| `location` union: `provider-location` | `scope`, provider-service identity, object type, stable-object identity, version identity, `O(field)`, `O(line u32)`, `O(fragment)`; workflow is represented only by `scope.Target.Surface`, never a fifth location tag |
| `location` union: `release-asset-location` | `scope`, release-object identity, tag, asset name, asset digest |
| `location` union: `snapshot-location` | `scope` only |
| `protected-finding` | `policy-rule` union, finding code, location digest, evidence digest, expected-value digest, stable-key digest |
| `policy-rule` union: `baseline-policy-rule` / `extension-policy-rule` | rule ID or extension ID, revision u32 |
| `disposition` union: `active` / `waived` / `debt` | `protected-finding` and disposition token, then no fields / waiver declaration digest, reviewed decision authority permalink value, expiry UTC ticks / debt entry digest, reviewed authority permalink value, expiry UTC ticks |

Tags, fields, lists and optionals never share a byte discriminator: tags are
length-framed strings, list counts are u32, and optional presence is one byte.
Nested row order uses the same ordinal/canonical-byte ordering rules as its
owning list. Unknown tags, tags inconsistent with optional fields, surplus
union fields and nonzero values other than `01` for presence are invalid.

Input order never determines collection order. Rows sort as follows:

- acquisitions by ordinal slot key, then target surface/snapshot/subject/
  source/target identity, then outcome digest;
- unified report-owned rule rows by baseline before extension, then baseline
  `RuleId` or extension `ExtensionId.Value`, then numeric revision;
- findings by stable finding key;
- failures by code, primary-reference digest and related-reference digest;
- report-safe dispositions by stable finding key;
- proposed changes by extension ID;
- every set-like nested string/reference list by its canonical row bytes, with
  duplicates rejected rather than silently collapsed.

One report-owned location/reference writer frames typed evidence without raw
content according to the exhaustive table. The report writer must not call
`ToString()` on a composite or infer a field from presentation text.

Acquisition rows include status, projection flag, outcome digest, optional
scope, requirement acquisition/redaction/failure rows, optional context proof,
attempt receipt/status/authority rows and acquisition failures. Evaluation rows
include identity/revision, applicability state, applicability references,
unresolved slots, typed findings and failures. The public projection exposes
only the safe status/identity/code subset while canonical bytes retain the
complete safe provenance frame. Disposition rows include stable
finding identity, disposition token and only the matching waiver declaration
digest/decision authority/expiry or debt entry digest/authority/expiry.
`WaiverDeclaration.Rationale`, `WaiverDeclaration.Owner`,
`HistoricalDebtEntry.AccountableOwner`, and
`HistoricalDebtEntry.ReviewCondition` are neither retained nor framed. The
declaration/entry digest binds those reviewed source records without copying
their free text. The canonical bytes contain no display message.

Before writing, `DebtEnforcementCore.ComputeEvidenceSetDigest` and
`DebtEnforcementCore.ProjectOutcomeSet` remain the single owners of their
existing digest projections. The report compares their fresh results to the
input digests and frames those digests; it does not reproduce either algorithm.
`ReportDigest` is `SHA256(CanonicalBytes)` and is computed only after the exact
frame succeeds.

### Reviewed literal grammar golden

The production writer is not the golden's author. A reviewer-owned literal
grammar vector fixes the zero-acquisition/no-transition frame shape using
schema `1`, runtime
`1.0.0`, source/target commit `0000000000000000000000000000000000000001`,
subject/source `repo:fixture`, exact-commit repository target, catalog version
`1`, profile `fixture/consumer/adoption-assessment/exact-commit/audit` with one
repository surface, activation epoch `1`, evaluation ticks `0`, digest bytes
`01`..`06` for the runtime fields, `02` again for catalog inventory,
`07`..`0C` for active-policy fields, and `0D`/`0E` for evidence/outcome,
`Complete`, empty acquisition/baseline/extension/disposition lists, both flags
false, `Conforming` and `Allow`. Its authoritative bytes are the Base64 literal
below after removing only ASCII layout whitespace; no test helper or production
writer generates or rewrites it.

```text
cHJvdG9jb2wuY29uZm9ybWFuY2UtcmVwb3J0LzEKAAAABnJlcG9ydAAAABtwcm90b2NvbC5jb25mb3JtYW5jZS1yZXBvcnQAAAABMQAAAAdydW50aW1lAAAABTEuMC4wAAAAKDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYAAAAGdGFyZ2V0AAAADHJlcG86Zml4dHVyZQAAAAxyZXBvOmZpeHR1cmUAAAAKcmVwb3NpdG9yeQAAAAxleGFjdC1jb21taXQAAAAoMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMQAAAAdwcm9maWxlAAAAAQICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAB2ZpeHR1cmUAAAAIY29uc3VtZXIAAAATYWRvcHRpb24tYXNzZXNzbWVudAAAAAxleGFjdC1jb21taXQAAAABAAAACnJlcG9zaXRvcnkAAAAFYXVkaXQAAAANYWN0aXZlLXBvbGljeQcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQAAAAAAAAABCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMAAAAAAAAAAAAAAAACGNvbXBsZXRlAAAAAAAAAAAAAAAAAAAAAAAADQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODgAAAApjb25mb3JtaW5nAAAABWFsbG93
```

The decoded literal is exactly `927` bytes; its SHA-256
is `960F98690439111A04A9DB1BE3CC31CB790FFD5C10056E3BF088EB20DE92C2BE`.
This vector is a writer-grammar oracle, not a claim that its deliberately small
row inventory is a complete accepted catalog evaluation. Production validation
first creates one internal immutable `CanonicalReportFrame`; the sole writer
accepts that frame. The friend test constructs the same internal frame shape
directly, compares `CanonicalReportCore.Write` to this independently reviewed
literal, and changes one literal byte to reach the digest-validation seam below.
A separate real-kernel fixture calls public `SealReport` and proves completeness,
custody, projections and the four result dimensions; it does not weaken or
regenerate the literal. `CanonicalReportFrame` and `CanonicalReportCore.Write`
remain internal in `CanonicalReportCore.cs`, add no test-only production branch,
and are not a second writer.

## Completeness, redaction and credential exclusion

The report is complete or sealing fails. Completeness requires:

- exact kernel/evaluation/protected-policy custody described above;
- a nonempty acquisition list only where the closure retained outcomes; zero
  is valid only for a valid no-input closure;
- one acquisition summary derived from all retained rows;
- unique baseline and extension rule identities;
- every finding exactly once in the disposition set;
- no disposition for an absent finding;
- evidence/outcome digest recomputation equality;
- baseline `HasKnownViolation` and unresolved flags equal the baseline rows;
  report `HasKnownViolation` and unresolved are recomputed across baseline and
  extension rows and remain consistent with protected verdict/enforcement;
- profile enforcement phase equal to the phase used by protected evaluation;
- proposed transition isolated from active evaluation and reported only when
  present.

Canonical evidence payload bytes are prohibited. The writer may retain schema
identity, content digest, typed location, scope, requirement, capture UTC,
redaction flags and qualified provenance only. It also prohibits credentials,
authorization headers, tokens, secrets, environment values, raw provider
bodies, raw repository blobs, exception messages/stacks, evaluator objects,
delegates and diagnostic text. `RequiredValuesOmitted` and
`NonRequiredValuesOmitted` remain visible as typed flags; omitted data is never
reconstructed, replaced with a placeholder string, or hashed into a new
report-only surrogate.

Security tests use sentinel raw-content and credential byte sequences and
prove they are absent from `CanonicalBytes`; substring absence alone is not the
completeness oracle. Typed field and digest equality must also pass.

## Validation order and resource limits

Public null input throws `ArgumentNullException(evaluation)`. A pre-cancelled
token throws `OperationCanceledException` before enumeration. After that, the
first-error order is:

1. foreign kernel/catalog/closure/runtime/authority custody ->
   `EvaluationContextMismatch`;
2. missing, duplicate, contradictory or projection-inconsistent typed
   dimension -> `DimensionInconsistent`;
3. count, byte or checked-arithmetic overflow -> `ResourceLimitExceeded`;
4. internal retained-byte/digest validation mismatch -> `DigestMismatch`.

The writer validates before retention and checks cancellation at least every
`1,024` rows or references. Exact equality passes; first one over fails without
truncation or partial report publication:

| Resource | Maximum |
| --- | ---: |
| Acquisition outcomes | `4,096` |
| Total baseline plus extension evaluations | `200,000` |
| Finding dispositions | `100,000` |
| Total qualified/reference occurrences | `1,000,000` |
| Canonical report bytes | `67,108,864` |

Subject-repository retention consumes one target and is valid when acquisition
count is zero. It does not raise the `4,096` acquisition cap. The existing
Domain opaque-identity/target-identity length limits remain authoritative; the
report neither expands them nor adds a second string budget.

These caps do not expand graph/schema-2 limits, predecessor producer/cache
budgets, waiver/debt limits, or any evidence payload limit. A lower predecessor
cap may make a report maximum algebraically unreachable; the report test then
uses the greatest valid production shape plus direct internal boundary seams
only for the independent writer counter.

Exception handling is narrow and ordered:

| Origin | Public result |
| --- | --- |
| null `evaluation` | preserve `ArgumentNullException` with `ParamName=\"evaluation\"` |
| token already cancelled or cancellation observed while walking rows | preserve `OperationCanceledException` and its token |
| report-owned foreign kernel/catalog/planning session/closure/runtime/active authority reference, including a foreign issued subject anchor | `CanonicalReportIntegrityException(EvaluationContextMismatch)` |
| fresh predecessor projection throws `ProtectedPolicyIntegrityException(EvaluationContextMismatch)` | translate to `CanonicalReportIntegrityException(EvaluationContextMismatch)` |
| fresh predecessor projection throws `ProtectedPolicyIntegrityException(ResourceLimitExceeded)` | translate to `CanonicalReportIntegrityException(ResourceLimitExceeded)` |
| `ProtectedPolicyIntegrityException` with any other code | preserve unchanged; a previously minted evaluation is not reclassified |
| owned closure missing its subject anchor, contradictory dimension, duplicate/absent projection or invalid union tuple | `CanonicalReportIntegrityException(DimensionInconsistent)` |
| report-owned count/byte bound or `OverflowException` from checked report arithmetic | `CanonicalReportIntegrityException(ResourceLimitExceeded)` |
| retained canonical bytes differ from the supplied expected digest in `CanonicalReportCore.ValidateDigest` | `CanonicalReportIntegrityException(DigestMismatch)` |
| predecessor `CatalogIntegrityException(PlanStateInvalid)` before a report-owned predicate is established | preserve unchanged; do not guess a translation |
| unexpected `ArgumentException`, `InvalidOperationException`, encoder defect or any other exception | preserve unchanged; no broad catch |
| `OutOfMemoryException`, `StackOverflowException`, `AccessViolationException` | never catch or translate |

`DigestMismatch` is reachable without reflection or a second writer through the
internal production seam
`CanonicalReportCore.ValidateDigest(IReadOnlyList<byte> canonicalBytes,
ExactSha256Digest expectedDigest)`. The factory calls it after defensive byte
retention and before publishing the report; the friend test calls the same seam
with the reviewed literal plus a one-byte mutation. The method checks null,
resource limit and cancellation-independent byte ownership before the digest,
and only the final unequal digest maps to `DigestMismatch`.

## Cross-runtime and culture matrix

[TEST-0222](test-cases.md#test-0222) proves byte-for-byte and digest equality on
the repository's supported .NET runtime under Ubuntu and Windows stable jobs,
with at least `en-US` and `tr-TR` cultures. The same typed values produce the
same bytes on both operating systems; the writer performs no platform newline
normalization. A framed string containing LF and the otherwise identical string
containing CRLF are different typed inputs and must produce different bytes and
digest. Diagnostic/display text is excluded from the frame, so changing only
that excluded text is irrelevant. Tests prove all three cases and also vary
input collection order and independently mutate every root field group,
optional presence byte, location subtype, outcome dimension and final
canonical byte/digest pair.

## Canonical expected-red seam

The exact [TEST-0222](test-cases.md#test-0222) behavior-red identity is:

```text
MeAndAI.Protocol.Conformance.Tests.CanonicalReportSealingTests.Seals_exact_typed_report_bytes_digest_redaction_and_dimensions
TEST-0222-REPORT-SEALING-RED-0001
```

Its predecessor-compilable scaffold uses exact reflection only to establish
that the frozen public report surface is absent, then reaches the sole marker.
Missing discovery, build/restore failure, a different exception, an assertion
before the marker, broad execution or alternate FQN is invalid red. After the
single accepted red, the retained green test calls the public API directly;
the red source/TRX identity is immutable and never rerun.

The exact [TEST-0209](test-cases.md#test-0209) direct composed-test identity is:

```text
MeAndAI.Protocol.Conformance.Tests.ComposedQualificationTests.Qualifies_exact_acquisition_evaluation_conformance_enforcement_and_report_dimensions
```

For `COMPOSED-QUALIFICATION-01`, P and R are `NotApplicable`: it starts only
from exact-head-hosted-green report sealing, invokes no sibling Fact, and
executes one fresh real kernel composition directly. There is no artificial
marker, legacy branch or synthetic absence predicate. The expected change is a
test/evidence-only addition on unchanged product. If the direct test exposes a
natural report-owned behavior defect, Cohort 1 is reopened, repaired and
revalidated through a new exact-head hosted-green predecessor before Cohort 2
continues; the defect is not converted into a retrospective R.

For `REPORT-CONVERGE-01`, P and R are also `NotApplicable`; its inputs are the
two already green behavior Facts and the existing structural owners. A natural
behavior defect reopens its owning earlier cohort. Structural failure remains
ordinary validation evidence, never a fabricated behavior-red marker.

Both Facts remain direct, public, sealed-class Facts with no trait, Theory,
skip, overload or class trait until final atomic activation. Only Cohort 1 may
consume canonical R for this subfeature.

## Implementation boundary

The exact source/test allowlist and line budgets are in the
[micro-delivery plan](subf-0154-micro-delivery-plan.md). The implementation has
three semantic cohorts: report sealing, composed qualification, and atomic
convergence. One branch and one PR carry the sequence; no micro-boundary receives
its own PR. Each cohort still owns one focused local commit and exact-head
hosted gate before its successor activates.

No report parser, JSON DTO, alternate schema, host output, CLI, stdout/file I/O,
publication envelope, check-run mapping, exit-code mapping, consumer adapter,
release binding, authority state transition, self-consumption redesign, new
evaluator, evidence acquisition, durable storage, network/filesystem access,
credential handling, localization, telemetry, or diagnostic artifact enters
this subfeature.

## Gate 2 review outcome

The consolidated correction review found no unresolved architectural choice.
The accepted predecessor types plus the narrow planning-carrier carve-out can
supply every frozen field without crossing an I/O or trust boundary; the
acyclic report byte/digest pair avoids publication cycles; the four dimensions
remain independent; and WIP reuse is explicitly rejected. The correction
author's static self-review candidate is
`0 Blocking / 0 Important / 0 Minor`; final independent changed-diff review and
the committed-HEAD graph/capacity gate remain pending, so this is not yet a
final review closure.

Implementation remains held by the predecessor and explicit-authority gates at
the start of this document. This acceptance is design readiness, not product
completion, passing scenario evidence, hosted evidence, merge readiness,
release or publication.
