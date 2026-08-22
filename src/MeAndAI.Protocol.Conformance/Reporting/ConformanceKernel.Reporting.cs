using System.Security.Cryptography;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    public CanonicalConformanceReport SealReport(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(evaluation);
        cancellationToken.ThrowIfCancellationRequested();
        return SealReportCore(evaluation, cancellationToken);
    }

    private CanonicalConformanceReport SealReportCore(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken)
    {
        var baseline = evaluation.Baseline;
        var closure = baseline.Closure;
        var plan = closure.Applicability.Plan;
        ValidateCustody(evaluation, baseline, closure, plan);
        var subject = plan.SubjectRepository ??
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        ValidateDispositionDimensions(evaluation, cancellationToken);
        ValidateDimensions(evaluation, cancellationToken);
        ValidateFreshDigests(evaluation, closure);
        ValidateResourcePreflight(evaluation, cancellationToken);

        var acquisitionStatus = ProjectAcquisitionStatus(baseline.Acquisitions);
        var (baselineIdentities, extensionIdentities, dispositions) =
            ValidateAndProjectFindings(evaluation);
        var acquisitions = baseline.Acquisitions.Select(ProjectAcquisition).ToArray();
        var rules = baseline.Evaluations.Select(row => ProjectRule(
                row,
                baselineIdentities))
            .Concat(evaluation.ExtensionEvaluations.Select(row => ProjectRule(
                row,
                extensionIdentities)))
            .OrderBy(static row => row.Rule.BaselineRuleId is null ? 1 : 0)
            .ThenBy(static row => row.Rule.BaselineRuleId?.Value ??
                row.Rule.ExtensionId!.Value, StringComparer.Ordinal)
            .ThenBy(static row => row.Rule.Revision.Value)
            .ToArray();
        var authority = evaluation.DispositionAuthority;
        var payload = authority.Payload;
        var active = evaluation.ActiveExtensions;
        var activeFrame = new CanonicalActivePolicyFrame(
            active.Snapshot.SnapshotDigest,
            active.AuthoritySetDigest,
            active.ActivationRecordDigest,
            active.ActivationEpoch,
            authority.BindingDigest,
            payload.WaiverSnapshotDigest,
            payload.DebtSnapshotDigest,
            payload.EvaluationUtc);
        var frame = new CanonicalReportFrame(
            "protocol.conformance-report",
            "1",
            new CanonicalRuntimeFrame(evaluation.RuntimeBinding),
            subject,
            baseline.Catalog.CatalogVersion,
            baseline.Catalog.CompleteInventoryDigest,
            baseline.Profile.Name,
            baseline.Profile.Axes,
            activeFrame,
            evaluation.ProposedTransition is null
                ? null
                : new CanonicalTransitionFrame(evaluation.ProposedTransition),
            acquisitionStatus,
            baseline.Acquisitions,
            baseline.Evaluations,
            evaluation.ExtensionEvaluations,
            dispositions,
            rules.Any(static row => row.Status.Equals(RuleEvaluationStatus.Violated)),
            rules.Any(static row => row.IsApplicabilityUnresolved ||
                row.Status.Equals(RuleEvaluationStatus.NotEvaluated)),
            evaluation.EvidenceSetDigest,
            evaluation.OutcomeSetDigest,
            evaluation.Verdict,
            evaluation.Enforcement,
            baselineIdentities,
            extensionIdentities);
        var written = CanonicalReportCore.Write(frame, cancellationToken);
        var retained = written.ToArray();
        var digest = ExactSha256Digest.FromHashBytes(SHA256.HashData(retained));
        CanonicalReportCore.ValidateDigest(retained, digest);

        return new CanonicalConformanceReport(
            frame.SchemaKey,
            frame.SchemaVersion,
            evaluation.RuntimeBinding,
            subject,
            frame.CatalogVersion,
            frame.CatalogDigest,
            frame.ProfileName,
            frame.Profile,
            acquisitionStatus,
            acquisitions,
            rules,
            dispositions,
            activeFrame.SnapshotDigest,
            activeFrame.AuthoritySetDigest,
            activeFrame.ActivationRecordDigest,
            activeFrame.ActivationEpoch,
            activeFrame.DispositionAuthorityBindingDigest,
            activeFrame.WaiverSnapshotDigest,
            activeFrame.DebtSnapshotDigest,
            activeFrame.EvaluationUtc,
            evaluation.ProposedTransition?.ProposedSnapshot.SnapshotDigest,
            evaluation.ProposedTransition?.TargetCommit,
            evaluation.ProposedTransition?.TransitionDigest,
            frame.HasKnownViolation,
            frame.HasUnresolvedRequiredEvaluation,
            frame.EvidenceSetDigest,
            frame.OutcomeSetDigest,
            frame.Verdict,
            frame.Enforcement,
            retained,
            digest);
    }

    private void ValidateCustody(
        ProtectedPolicyEvaluation evaluation,
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ApplicabilityPlan plan)
    {
        NamedExecutionProfile issuedProfile;
        try
        {
            issuedProfile = _planningSession.GetNamedProfile(plan);
        }
        catch (CatalogIntegrityException)
        {
            throw Integrity(CanonicalReportIntegrityCode.EvaluationContextMismatch);
        }

        var active = evaluation.ActiveExtensions;
        var payload = evaluation.DispositionAuthority.Payload;
        var orderedClosureAcquisitions = closure.Acquisitions
            .OrderBy(static row => row.Slot.SlotKey, StringComparer.Ordinal)
            .ToArray();
        var runtimeArtifact = active.PolicyPackBinding.Artifacts.SingleOrDefault(
            static row => string.Equals(
                row.ArtifactKey,
                "protocol.artifact.conformance-runtime",
                StringComparison.Ordinal));
        var expectedRuntime = runtimeArtifact is null
            ? null
            : RuntimeBinding(active, runtimeArtifact);
        if (!ReferenceEquals(baseline.Catalog, Catalog) ||
            !ReferenceEquals(baseline.Closure, closure) ||
            !ReferenceEquals(baseline.Profile, issuedProfile) ||
            !ReferenceEquals(baseline.Profile.PlanningSession, _planningSession) ||
            !ReferenceEquals(plan.EvidenceSession, _planningSession) ||
            !ReferenceEquals(plan.Profile, baseline.Profile.Axes) ||
            !baseline.Acquisitions.SequenceEqual(
                orderedClosureAcquisitions,
                ReferenceEqualityComparer.Instance) ||
            closure.TerminalEvaluations.Any(row =>
                !baseline.Evaluations.Contains(
                    row,
                    ReferenceEqualityComparer.Instance)) ||
            expectedRuntime is null ||
            !SameRuntime(expectedRuntime, evaluation.RuntimeBinding) ||
            !Catalog.ManifestDigest.Equals(active.ActivationPayload.ManifestDigest) ||
            !Catalog.ManifestDigest.Equals(active.PolicyPackBinding.ManifestDigest) ||
            !string.Equals(
                _planningSession.Manifest.SourceCommit,
                active.ActivationPayload.ActivatedTargetCommit,
                StringComparison.Ordinal) ||
            !evaluation.RuntimeBinding.PolicyPackBindingDigest.Equals(
                active.PolicyPackBinding.BindingDigest) ||
            !active.Snapshot.SnapshotDigest.Equals(
                active.ActivationPayload.ActiveSnapshotDigest) ||
            !active.AuthoritySetDigest.Equals(
                active.ActivationPayload.AuthoritySetDigest) ||
            !active.ActivationRecordDigest.Equals(payload.ExpectedAuthorityRecordDigest) ||
            active.ActivationEpoch != payload.AuthorityEpoch ||
            !payload.ManifestDigest.Equals(Catalog.ManifestDigest) ||
            !payload.AuthoritySetDigest.Equals(active.AuthoritySetDigest) ||
            !payload.EvidenceSetDigest.Equals(evaluation.EvidenceSetDigest) ||
            !evaluation.DispositionAuthority.AuthorityRecordDigest.Equals(
                active.ActivationRecordDigest) ||
            evaluation.ProposedTransition is { } transition &&
            (!ReferenceEquals(transition.ActiveSnapshot, active.Snapshot) ||
             !transition.ActiveSnapshot.SnapshotDigest.Equals(
                 active.Snapshot.SnapshotDigest)))
        {
            throw Integrity(CanonicalReportIntegrityCode.EvaluationContextMismatch);
        }

        ValidateSubject(plan);
    }

    private RuntimeQualificationBinding RuntimeBinding(
        ActivatedExtensionPolicy active,
        ProtectedPolicyArtifactBinding runtimeArtifact)
    {
        var anchor = ProtectedPolicyFrame.Hash(
            "protocol.protected-current-trust-anchor/1\n",
            stream =>
            {
                ProtectedPolicyFrame.Digest(
                    stream,
                    active.Policy.AuthorityPublicKeyDigest);
                ProtectedPolicyFrame.Digest(stream, active.Policy.ExportDigest);
                ProtectedPolicyFrame.Digest(stream, active.Snapshot.SnapshotDigest);
                ProtectedPolicyFrame.Digest(stream, active.AuthoritySetDigest);
            });
        return RuntimeQualificationBinding.Create(
            Catalog.ProtocolVersion,
            _planningSession.Manifest.SourceCommit,
            Catalog.ManifestDigest,
            Catalog.CompleteInventoryDigest,
            active.PolicyPackBinding.BindingDigest,
            runtimeArtifact.FileDigest,
            anchor);
    }

    private static bool SameRuntime(
        RuntimeQualificationBinding left,
        RuntimeQualificationBinding right) =>
        string.Equals(left.ProtocolVersion, right.ProtocolVersion, StringComparison.Ordinal) &&
        string.Equals(left.SourceCommit, right.SourceCommit, StringComparison.Ordinal) &&
        left.ManifestDigest.Equals(right.ManifestDigest) &&
        left.CatalogDigest.Equals(right.CatalogDigest) &&
        left.PolicyPackBindingDigest.Equals(right.PolicyPackBindingDigest) &&
        left.RuntimeArtifactDigest.Equals(right.RuntimeArtifactDigest) &&
        left.TrustAnchorDigest.Equals(right.TrustAnchorDigest) &&
        left.BindingDigest.Equals(right.BindingDigest);

    private static void ValidateSubject(ApplicabilityPlan plan)
    {
        var subject = plan.SubjectRepository;
        if (subject is null)
        {
            return;
        }

        var repositoryTargets = plan.Targets.Where(static row =>
            row.Surface.Equals(SurfaceKind.Repository)).ToArray();
        if (!subject.Surface.Equals(SurfaceKind.Repository) ||
            !subject.SnapshotKind.Equals(plan.Profile.SnapshotKind) ||
            plan.Targets.Any(target =>
                !target.SubjectIdentity.Equals(
                    subject.SubjectIdentity,
                    StringComparison.Ordinal) ||
                target.Surface.Equals(SurfaceKind.Repository) &&
                !target.SourceIdentity.Equals(
                    subject.SourceIdentity,
                    StringComparison.Ordinal) ||
                !target.SnapshotKind.Equals(subject.SnapshotKind) ||
                !target.TargetIdentity.Equals(
                    subject.TargetIdentity,
                    StringComparison.Ordinal)) ||
            repositoryTargets.Length > 1 ||
            repositoryTargets.Length == 1 && !repositoryTargets[0].Equals(subject))
        {
            throw Integrity(CanonicalReportIntegrityCode.EvaluationContextMismatch);
        }
    }

    private static (
        IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity> Baseline,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity> Extension,
        IReadOnlyList<CanonicalFindingDisposition> Dispositions)
        ValidateAndProjectFindings(ProtectedPolicyEvaluation evaluation)
    {
        var baseline = new Dictionary<RuleFinding, ProtectedFindingIdentity>(
            ReferenceEqualityComparer.Instance);
        var extensions = new Dictionary<ExtensionFinding, ProtectedFindingIdentity>(
            ReferenceEqualityComparer.Instance);
        var rows = new List<CanonicalFindingDisposition>();
        var stableKeys = new HashSet<string>(StringComparer.Ordinal);
        foreach (var row in evaluation.Dispositions)
        {
            if (row?.Finding?.Identity is not { } identity ||
                !stableKeys.Add(identity.StableKey.Value.Value) ||
                !ValidDisposition(row))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }

            if (row.Finding.BaselineFinding is { } baselineFinding)
            {
                if (!baseline.TryAdd(baselineFinding, identity))
                {
                    throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
                }
            }
            else if (row.Finding.ExtensionFinding is { } extensionFinding)
            {
                if (!extensions.TryAdd(extensionFinding, identity))
                {
                    throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
                }
            }
            else
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }

            rows.Add(new CanonicalFindingDisposition(
                identity,
                row.Disposition,
                row.Waiver?.DeclarationDigest,
                row.Waiver?.DecisionAuthority,
                row.Waiver?.ExpiresUtc,
                row.Debt?.EntryDigest,
                row.Debt?.Authority,
                row.Debt?.ExpiresUtc));
        }

        var baselineFindings = evaluation.Baseline.Evaluations
            .SelectMany(static row => row.Findings).ToArray();
        var extensionFindings = evaluation.ExtensionEvaluations
            .SelectMany(static row => row.Findings).ToArray();
        if (baseline.Count != baselineFindings.Length ||
            extensions.Count != extensionFindings.Length ||
            baselineFindings.Any(row => !baseline.ContainsKey(row)) ||
            extensionFindings.Any(row => !extensions.ContainsKey(row)))
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }

        return (
            baseline,
            extensions,
            rows.OrderBy(static row => row.Finding.StableKey.Value.Value,
                StringComparer.Ordinal).ToArray());
    }

    private static bool ValidDisposition(FindingDispositionResult row) =>
        row.Disposition.Equals(FindingDisposition.ActiveViolation)
            ? row.Waiver is null && row.Debt is null
            : row.Disposition.Equals(FindingDisposition.Waived)
                ? row.Waiver is not null && row.Debt is null &&
                  SameFinding(row.Finding.Identity, row.Waiver.Finding)
                : row.Disposition.Equals(FindingDisposition.HistoricalDebt) &&
                  row.Waiver is null && row.Debt is not null &&
                  SameFinding(row.Finding.Identity, row.Debt.Finding);

    private static bool SameFinding(
        ProtectedFindingIdentity left,
        ProtectedFindingIdentity right) =>
        string.Equals(left.Rule.CanonicalKey, right.Rule.CanonicalKey,
            StringComparison.Ordinal) &&
        left.FindingCode.Equals(right.FindingCode) &&
        left.LocationDigest.Equals(right.LocationDigest) &&
        left.EvidenceDigest.Equals(right.EvidenceDigest) &&
        left.ExpectedValueDigest.Equals(right.ExpectedValueDigest) &&
        left.StableKey.Value.Equals(right.StableKey.Value);

    private static void ValidateDimensions(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken)
    {
        var baselineRows = evaluation.Baseline.Evaluations;
        var extensionRows = evaluation.ExtensionEvaluations;
        var baselineKeys = new HashSet<string>(StringComparer.Ordinal);
        var extensionKeys = new HashSet<string>(StringComparer.Ordinal);
        var baselineKnown = false;
        var baselineUnresolved = false;
        long observed = 0;
        foreach (var row in baselineRows)
        {
            ObserveRow(cancellationToken, ref observed);
            if (!baselineKeys.Add($"{row.RuleId.Value}/{row.RuleRevision.Value}"))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }

            baselineKnown |= row.Status.Equals(RuleEvaluationStatus.Violated);
            baselineUnresolved |= row.IsApplicabilityUnresolved ||
                row.Status.Equals(RuleEvaluationStatus.NotEvaluated);
        }

        var extensionKnown = false;
        var extensionUnresolved = false;
        foreach (var row in extensionRows)
        {
            ObserveRow(cancellationToken, ref observed);
            if (!extensionKeys.Add(
                    $"{row.ExtensionId.Value}/{row.RuleRevision.Value}"))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }

            extensionKnown |= row.Status.Equals(RuleEvaluationStatus.Violated);
            extensionUnresolved |= row.IsApplicabilityUnresolved ||
                row.Status.Equals(RuleEvaluationStatus.NotEvaluated);
        }

        cancellationToken.ThrowIfCancellationRequested();

        var known = evaluation.Baseline.HasKnownViolation ||
            extensionKnown;
        var unresolved = evaluation.Baseline.HasUnresolvedRequiredEvaluation ||
            extensionUnresolved;
        var verdict = unresolved
            ? ConformanceVerdict.Indeterminate
            : known
                ? ConformanceVerdict.NonConforming
                : ConformanceVerdict.Conforming;
        var enforcement = ExpectedEnforcement(
            verdict,
            evaluation.Baseline.Profile.Axes.EnforcementPhase,
            evaluation.Dispositions);
        if (!evaluation.Baseline.HasKnownViolation.Equals(baselineKnown) ||
            !evaluation.Baseline.HasUnresolvedRequiredEvaluation.Equals(
                baselineUnresolved) ||
            !evaluation.Baseline.Verdict.Equals(baselineUnresolved
                ? ConformanceVerdict.Indeterminate
                : baselineKnown
                    ? ConformanceVerdict.NonConforming
                    : ConformanceVerdict.Conforming) ||
            !evaluation.Verdict.Equals(verdict) ||
            !evaluation.Enforcement.Equals(enforcement))
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }
    }

    private static void ValidateDispositionDimensions(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken)
    {
        var baseline = new HashSet<RuleFinding>(ReferenceEqualityComparer.Instance);
        var extensions = new HashSet<ExtensionFinding>(ReferenceEqualityComparer.Instance);
        var stableKeys = new HashSet<string>(StringComparer.Ordinal);
        long observed = 0;
        foreach (var row in evaluation.Dispositions)
        {
            ObserveRow(cancellationToken, ref observed);
            if (row?.Finding?.Identity is not { } identity ||
                !stableKeys.Add(identity.StableKey.Value.Value) ||
                !ValidDisposition(row) ||
                (row.Finding.BaselineFinding is { } baselineFinding
                    ? !baseline.Add(baselineFinding)
                    : row.Finding.ExtensionFinding is not { } extensionFinding ||
                      !extensions.Add(extensionFinding)))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }
        }

        long baselineCount = 0;
        foreach (var finding in evaluation.Baseline.Evaluations
                     .SelectMany(static row => row.Findings))
        {
            ObserveRow(cancellationToken, ref observed);
            baselineCount = CheckedAdd(baselineCount, 1);
            if (!baseline.Contains(finding))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }
        }

        long extensionCount = 0;
        foreach (var finding in evaluation.ExtensionEvaluations
                     .SelectMany(static row => row.Findings))
        {
            ObserveRow(cancellationToken, ref observed);
            extensionCount = CheckedAdd(extensionCount, 1);
            if (!extensions.Contains(finding))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }
        }

        cancellationToken.ThrowIfCancellationRequested();
        if (baseline.Count != baselineCount || extensions.Count != extensionCount)
        {
            throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
        }
    }

    private static void ValidateResourcePreflight(
        ProtectedPolicyEvaluation evaluation,
        CancellationToken cancellationToken)
    {
        var evaluations = CheckedAdd(
            evaluation.Baseline.Evaluations.Count,
            evaluation.ExtensionEvaluations.Count);
        CanonicalReportCore.ValidatePreflightCounts(
            evaluation.Baseline.Acquisitions.Count,
            evaluations,
            evaluation.Dispositions.Count,
            0);
        ObserveRows(
            cancellationToken,
            CheckedAdd(
                CheckedAdd(
                    evaluation.Baseline.Acquisitions.Count,
                    evaluations),
                evaluation.Dispositions.Count));
        var walk = new PreflightWalk(cancellationToken);
        foreach (var row in evaluation.Baseline.Acquisitions)
        {
            walk.Row();
            walk.Reference(row.ContextProof);
            walk.Rows(row.Failures.Count);
            walk.Rows(row.RequirementAcquisition?.Failures.Count ?? 0);
            foreach (var attempt in row.Attempts)
            {
                walk.Row();
                walk.Rows(attempt.Failures.Count);
                walk.Rows(attempt.RequirementAcquisition?.Failures.Count ?? 0);
            }
        }

        foreach (var row in evaluation.Baseline.Evaluations)
        {
            walk.Evaluation(row.ApplicabilityReferences, row.Findings, row.Failures);
        }

        foreach (var row in evaluation.ExtensionEvaluations)
        {
            walk.Evaluation(row.ApplicabilityReferences, row.Findings, row.Failures);
        }

        walk.Rows(evaluation.Dispositions.Count);
        walk.Complete();
        CanonicalReportCore.ValidatePreflightCounts(
            evaluation.Baseline.Acquisitions.Count,
            evaluations,
            evaluation.Dispositions.Count,
            walk.References);
    }

    private static long CheckedAdd(long left, long right)
    {
        try
        {
            return checked(left + right);
        }
        catch (OverflowException)
        {
            throw Integrity(CanonicalReportIntegrityCode.ResourceLimitExceeded);
        }
    }

    private static void ObserveRows(CancellationToken token, long count)
    {
        long observed = 0;
        while (observed < count)
        {
            ObserveRow(token, ref observed);
        }

        token.ThrowIfCancellationRequested();
    }

    private static void ObserveRow(CancellationToken token, ref long observed)
    {
        observed = CheckedAdd(observed, 1);
        if ((observed & 1_023) == 0)
        {
            token.ThrowIfCancellationRequested();
        }
    }

    private sealed class PreflightWalk
    {
        private readonly CancellationToken _token;
        private long _rows;

        internal PreflightWalk(CancellationToken token) => _token = token;

        internal long References { get; private set; }

        internal void Row() => ObserveRow(_token, ref _rows);

        internal void Rows(int count)
        {
            for (var index = 0; index < count; index++)
            {
                Row();
            }
        }

        internal void Reference(QualifiedEvidenceReference? reference)
        {
            if (reference is null)
            {
                return;
            }

            References = CheckedAdd(References, 1);
            Row();
            Rows(reference.Root is null ? 0 : 1);
            Rows(reference.Derivations.Count);
        }

        internal void ReferencesIn(
            IReadOnlyList<QualifiedEvidenceReference> references)
        {
            foreach (var reference in references)
            {
                Reference(reference);
            }
        }

        internal void Evaluation<TFinding, TFailure>(
            IReadOnlyList<QualifiedEvidenceReference> applicability,
            IReadOnlyList<TFinding> findings,
            IReadOnlyList<TFailure> failures)
            where TFinding : class
            where TFailure : class
        {
            Row();
            ReferencesIn(applicability);
            foreach (var finding in findings)
            {
                Row();
                switch (finding)
                {
                    case RuleFinding baseline:
                        Reference(baseline.PrimaryReference);
                        ReferencesIn(baseline.RelatedReferences);
                        break;
                    case ExtensionFinding extension:
                        Reference(extension.PrimaryReference);
                        ReferencesIn(extension.RelatedReferences);
                        break;
                }
            }

            foreach (var failure in failures)
            {
                Row();
                switch (failure)
                {
                    case RuleEvaluationFailure baseline:
                        Reference(baseline.PrimaryReference);
                        ReferencesIn(baseline.RelatedReferences);
                        break;
                    case ExtensionEvaluationFailure extension:
                        Reference(extension.PrimaryReference);
                        ReferencesIn(extension.RelatedReferences);
                        break;
                }
            }
        }

        internal void Complete() => _token.ThrowIfCancellationRequested();
    }

    private static EnforcementDecision ExpectedEnforcement(
        ConformanceVerdict verdict,
        EnforcementPhase phase,
        IReadOnlyList<FindingDispositionResult> dispositions)
    {
        if (phase.Equals(EnforcementPhase.Audit))
        {
            return EnforcementDecision.ReportOnly;
        }

        return verdict.Equals(ConformanceVerdict.Indeterminate) ||
               dispositions.Any(static row =>
                   row.Disposition.Equals(FindingDisposition.ActiveViolation)) ||
               phase.Equals(EnforcementPhase.FullBlocking) &&
               dispositions.Any(static row =>
                   row.Disposition.Equals(FindingDisposition.HistoricalDebt)) ||
               verdict.Equals(ConformanceVerdict.NonConforming) &&
               dispositions.Count == 0
            ? EnforcementDecision.Block
            : EnforcementDecision.Allow;
    }

    private static void ValidateFreshDigests(
        ProtectedPolicyEvaluation evaluation,
        EvaluationClosure closure)
    {
        try
        {
            var evidence = DebtEnforcementCore.ComputeEvidenceSetDigest(
                evaluation.Baseline,
                closure,
                evaluation.ActiveExtensions,
                evaluation.ExtensionEvaluations);
            var outcome = DebtEnforcementCore.ProjectOutcomeSet(evaluation).Digest;
            if (!evidence.Equals(evaluation.EvidenceSetDigest) ||
                !outcome.Equals(evaluation.OutcomeSetDigest))
            {
                throw Integrity(CanonicalReportIntegrityCode.DimensionInconsistent);
            }
        }
        catch (ProtectedPolicyIntegrityException error)
            when (error.Code.Equals(
                ProtectedPolicyIntegrityCode.EvaluationContextMismatch))
        {
            throw Integrity(CanonicalReportIntegrityCode.EvaluationContextMismatch);
        }
        catch (ProtectedPolicyIntegrityException error)
            when (error.Code.Equals(
                ProtectedPolicyIntegrityCode.ResourceLimitExceeded))
        {
            throw Integrity(CanonicalReportIntegrityCode.ResourceLimitExceeded);
        }
    }

    private static AcquisitionStatus ProjectAcquisitionStatus(
        IReadOnlyList<SealedAcquisitionOutcome> rows) =>
        rows.Any(static row => row.Status.Equals(AcquisitionStatus.Failed))
            ? AcquisitionStatus.Failed
            : rows.Any(static row => row.Status.Equals(AcquisitionStatus.Incomplete))
                ? AcquisitionStatus.Incomplete
                : AcquisitionStatus.Complete;

    private static CanonicalAcquisitionResult ProjectAcquisition(
        SealedAcquisitionOutcome row)
    {
        var failures = row.Failures.Select(static failure => failure.Code)
            .Concat(row.RequirementAcquisition?.Failures.Select(
                static failure => failure.Code) ?? [])
            .Concat(row.Attempts.SelectMany(static attempt =>
                attempt.Failures.Select(static failure => failure.Code)))
            .Concat(row.Attempts.SelectMany(static attempt =>
                attempt.RequirementAcquisition?.Failures.Select(
                    static failure => failure.Code) ?? []))
            .Distinct(StringComparer.Ordinal)
            .Order(StringComparer.Ordinal)
            .ToArray();
        return new CanonicalAcquisitionResult(
            row.Slot.SlotKey,
            row.Target,
            row.Status,
            row.IsProjected,
            row.OutcomeDigest,
            row.Scope,
            row.ContextProof?.QualificationProofDigest,
            row.RequirementAcquisition?.Redaction.RequiredValuesOmitted,
            row.RequirementAcquisition?.Redaction.NonRequiredValuesOmitted,
            failures);
    }

    private static CanonicalRuleResult ProjectRule(
        RuleEvaluation row,
        IReadOnlyDictionary<RuleFinding, ProtectedFindingIdentity> identities) =>
        new(
            PolicyRuleIdentity.Baseline(row.RuleId, row.RuleRevision),
            row.Status,
            row.IsApplicabilityUnresolved,
            row.UnresolvedSlotKeys.Order(StringComparer.Ordinal),
            row.Findings.Select(finding => identities[finding])
                .OrderBy(static finding => finding.StableKey.Value.Value,
                    StringComparer.Ordinal),
            row.Failures.Select(static failure => failure.Code)
                .OrderBy(static code => code.Value, StringComparer.Ordinal));

    private static CanonicalRuleResult ProjectRule(
        ExtensionEvaluation row,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFindingIdentity> identities) =>
        new(
            PolicyRuleIdentity.Extension(row.ExtensionId, row.RuleRevision),
            row.Status,
            row.IsApplicabilityUnresolved,
            row.UnresolvedSlotKeys.Order(StringComparer.Ordinal),
            row.Findings.Select(finding => identities[finding])
                .OrderBy(static finding => finding.StableKey.Value.Value,
                    StringComparer.Ordinal),
            row.Failures.Select(static failure => failure.Code)
                .OrderBy(static code => code.Value, StringComparer.Ordinal));

    private static CanonicalReportIntegrityException Integrity(
        CanonicalReportIntegrityCode code) => new(code);
}
