using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

internal sealed class DebtEnforcementCore
{
    private DebtEnforcementCore() { }
    private const int MaximumSlots = 4_096;
    private const int MaximumScopes = 65_536;
    private const int MaximumOutcomes = 200_000;
    private const int MaximumReferences = 1_000_000;
    private const long MaximumCanonicalSetBytes = 67_108_864;

    internal static ProtectedPolicyEvaluation Evaluate(
        CompleteCatalogSnapshot catalog,
        KernelPlanningSession session,
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ActivatedExtensionPolicy activeExtensions,
        ProposedExtensionTransition? proposedTransition,
        WaiverSnapshot waivers,
        HistoricalDebtSnapshot historicalDebt,
        ProtectedDispositionAuthorityPayload dispositionPayload,
        ProtectedAuthorityEnvelope dispositionProof,
        EnforcementPhase enforcementPhase,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(session);
        ArgumentNullException.ThrowIfNull(baseline);
        ArgumentNullException.ThrowIfNull(closure);
        ArgumentNullException.ThrowIfNull(activeExtensions);
        ArgumentNullException.ThrowIfNull(waivers);
        ArgumentNullException.ThrowIfNull(historicalDebt);
        ArgumentNullException.ThrowIfNull(dispositionPayload);
        ArgumentNullException.ThrowIfNull(dispositionProof);
        ArgumentNullException.ThrowIfNull(enforcementPhase);
        cancellationToken.ThrowIfCancellationRequested();
        ValidateContext(
            catalog,
            session,
            baseline,
            closure,
            activeExtensions,
            proposedTransition,
            enforcementPhase);

        var input = closure.ProtectedInput;
        var extensionEvaluations = ExtensionEvaluationCore.Evaluate(
            activeExtensions,
            baseline.Profile.Axes,
            input is null ? [] : closure.Context.AdmittedSlotKeys,
            input?.Access ?? RejectingInputAccess.Instance,
            input?.References ?? EmptyReferences,
            cancellationToken);
        var evidenceSetDigest = ComputeEvidenceSetDigest(
            baseline,
            closure,
            activeExtensions,
            extensionEvaluations);
        var findings = ProtectFindings(
            catalog,
            activeExtensions,
            baseline.Evaluations,
            extensionEvaluations);
        var waiverOutcome = WaiverDispositionCore.Apply(
            activeExtensions,
            waivers,
            historicalDebt,
            dispositionPayload,
            dispositionProof,
            evidenceSetDigest,
            findings);
        var verdict = Verdict(baseline, extensionEvaluations);
        var debtOutcome = Apply(
            waiverOutcome,
            historicalDebt,
            catalog.ProtocolVersion,
            dispositionPayload.EvaluationUtc,
            verdict,
            enforcementPhase);
        var runtimeBinding = RuntimeBinding(catalog, session, activeExtensions);
        var outcomeSetDigest = ProjectOutcomeSet(
            baseline.Evaluations,
            extensionEvaluations,
            debtOutcome.Dispositions,
            verdict,
            debtOutcome.Enforcement).Digest;
        return new ProtectedPolicyEvaluation(
            runtimeBinding,
            baseline,
            activeExtensions,
            debtOutcome.Authority,
            proposedTransition,
            extensionEvaluations,
            debtOutcome.Dispositions,
            evidenceSetDigest,
            outcomeSetDigest,
            verdict,
            debtOutcome.Enforcement);
    }

    internal static DebtEnforcementOutcome Apply(
        WaiverDispositionOutcome waiverOutcome,
        HistoricalDebtSnapshot historicalDebt,
        string protocolVersion,
        DateTimeOffset evaluationUtc,
        ConformanceVerdict verdict,
        EnforcementPhase enforcementPhase)
    {
        ArgumentNullException.ThrowIfNull(waiverOutcome);
        ArgumentNullException.ThrowIfNull(historicalDebt);
        ArgumentException.ThrowIfNullOrEmpty(protocolVersion);
        ArgumentNullException.ThrowIfNull(verdict);
        ArgumentNullException.ThrowIfNull(enforcementPhase);
        var debtByFinding = historicalDebt.Entries.ToDictionary(
            static row => row.Finding.StableKey.Value.Value,
            StringComparer.Ordinal);
        var dispositions = waiverOutcome.Results.Select(row =>
        {
            if (!row.Disposition.Equals(FindingDisposition.ActiveViolation) ||
                !debtByFinding.TryGetValue(
                    row.Finding.Identity.StableKey.Value.Value,
                    out var debt) ||
                !IsExactDebt(
                    row.Finding,
                    debt,
                    protocolVersion,
                    evaluationUtc,
                    waiverOutcome.Authority.Payload.TrustedBaseAuthorityDigest))
            {
                return row;
            }

            return new FindingDispositionResult(
                row.Finding,
                FindingDisposition.HistoricalDebt,
                null,
                debt);
        }).ToArray();
        var enforcement = Enforcement(verdict, enforcementPhase, dispositions);
        return new DebtEnforcementOutcome(
            waiverOutcome.Authority,
            Array.AsReadOnly(dispositions),
            verdict,
            enforcement);
    }

    internal static ExactSha256Digest ComputeEvidenceSetDigest(
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ActivatedExtensionPolicy activeExtensions,
        IReadOnlyList<ExtensionEvaluation> extensionEvaluations)
    {
        ArgumentNullException.ThrowIfNull(baseline);
        ArgumentNullException.ThrowIfNull(closure);
        ArgumentNullException.ThrowIfNull(activeExtensions);
        ArgumentNullException.ThrowIfNull(extensionEvaluations);
        if (!ReferenceEquals(baseline.Closure, closure) ||
            !baseline.Catalog.ManifestDigest.Equals(closure.Context.ManifestDigest) ||
            !baseline.Catalog.CatalogVersion.Equals(closure.Context.CatalogVersion))
        {
            throw ContextInvalid();
        }

        try
        {
            var slots = OrderedUnique(
                closure.Context.AdmittedSlotKeys,
                static value => value,
                MaximumSlots);
            var scopes = CanonicalScopes(
                closure.Context.Scopes,
                allowIdenticalDuplicates: false);
            var acquisitionScopes = CanonicalScopes(
                closure.Acquisitions
                    .Where(static row => row.ContextProof is not null)
                    .Select(static row => row.ContextProof!.Scope),
                allowIdenticalDuplicates: true);
            if (!scopes.Select(static row => row.Value).SequenceEqual(
                    acquisitionScopes.Select(static row => row.Value),
                    StringComparer.Ordinal))
            {
                throw ContextInvalid();
            }

            var outcomes = OrderedUnique(
                closure.Acquisitions.Select(static row => row.OutcomeDigest),
                static value => value.Value,
                MaximumOutcomes);
            var references = CanonicalReferences(
                References(baseline, closure, extensionEvaluations));
            return EvidenceSetFrame(
                baseline.Catalog.ManifestDigest,
                baseline.Catalog.CompleteInventoryDigest,
                activeExtensions.Snapshot.SnapshotDigest,
                closure.CompletedRoundCount,
                closure.Context.AuthorityKind.Value,
                closure.Context.CatalogVersion.Value,
                slots,
                scopes,
                outcomes,
                references);
        }
        catch (OverflowException)
        {
            throw ResourceLimit();
        }
    }

    private static ExactSha256Digest EvidenceSetFrame(
        ExactSha256Digest manifest,
        ExactSha256Digest inventory,
        ExactSha256Digest snapshot,
        int rounds,
        string authority,
        int catalogVersion,
        IReadOnlyList<string> slots,
        IReadOnlyList<ExactSha256Digest> scopes,
        IReadOnlyList<ExactSha256Digest> outcomes,
        IReadOnlyList<ExactSha256Digest> references) => ProtectedPolicyFrame.Hash(
        "protocol.protected-evidence-set/1\n",
        stream =>
        {
            ProtectedPolicyFrame.Digest(stream, manifest);
            ProtectedPolicyFrame.Digest(stream, inventory);
            ProtectedPolicyFrame.Digest(stream, snapshot);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)rounds));
            ProtectedPolicyFrame.String(stream, authority);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)catalogVersion));
            WriteStrings(stream, slots);
            WriteDigests(stream, scopes);
            WriteDigests(stream, outcomes);
            WriteDigests(stream, references);
        });

    private static readonly IReadOnlyDictionary<QualifiedEvidenceHandle,
        QualifiedEvidenceReference> EmptyReferences =
        new Dictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>(
            ReferenceEqualityComparer.Instance);

    private static void ValidateContext(
        CompleteCatalogSnapshot catalog,
        KernelPlanningSession session,
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        ActivatedExtensionPolicy activeExtensions,
        ProposedExtensionTransition? proposedTransition,
        EnforcementPhase enforcementPhase)
    {
        if (!ReferenceEquals(
                closure.Applicability.Plan.EvidenceSession,
                session))
        {
            throw ContextInvalid();
        }

        NamedExecutionProfile expectedProfile;
        try
        {
            expectedProfile = session.GetNamedProfile(
                closure.Applicability.Plan);
        }
        catch (CatalogIntegrityException)
        {
            throw ContextInvalid();
        }

        var orderedClosureAcquisitions = closure.Acquisitions
            .OrderBy(static row => row.Slot.SlotKey, StringComparer.Ordinal)
            .ToArray();
        if (!ReferenceEquals(catalog, baseline.Catalog) ||
            !ReferenceEquals(baseline.Closure, closure) ||
            !ReferenceEquals(baseline.Profile, expectedProfile) ||
            !ReferenceEquals(
                baseline.Profile.Axes,
                closure.Applicability.Plan.Profile) ||
            !ReferenceEquals(baseline.Profile.PlanningSession, session) ||
            !baseline.Acquisitions.SequenceEqual(
                orderedClosureAcquisitions,
                ReferenceEqualityComparer.Instance) ||
            closure.TerminalEvaluations.Any(row =>
                !baseline.Evaluations.Contains(
                    row,
                    ReferenceEqualityComparer.Instance)) ||
            !catalog.ManifestDigest.Equals(
                activeExtensions.ActivationPayload.ManifestDigest) ||
            !string.Equals(
                session.Manifest.SourceCommit,
                activeExtensions.ActivationPayload.ActivatedTargetCommit,
                StringComparison.Ordinal) ||
            !activeExtensions.PolicyPackBinding.ManifestDigest.Equals(
                catalog.ManifestDigest) ||
            !enforcementPhase.Equals(baseline.Profile.Axes.EnforcementPhase) ||
            proposedTransition is not null &&
            (!ReferenceEquals(
                    proposedTransition.ActiveSnapshot,
                    activeExtensions.Snapshot) ||
             !proposedTransition.ActiveSnapshot.SnapshotDigest.Equals(
                 activeExtensions.Snapshot.SnapshotDigest)))
        {
            throw ContextInvalid();
        }
    }

    private static IReadOnlyList<ProtectedFinding> ProtectFindings(
        CompleteCatalogSnapshot catalog,
        ActivatedExtensionPolicy activeExtensions,
        IReadOnlyList<RuleEvaluation> baselineEvaluations,
        IReadOnlyList<ExtensionEvaluation> extensionEvaluations)
    {
        var result = new List<ProtectedFinding>();
        foreach (var evaluation in baselineEvaluations)
        {
            var declaration = catalog.Rules.SingleOrDefault(row =>
                row.RuleId.Equals(evaluation.RuleId) &&
                row.RuleRevision.Equals(evaluation.RuleRevision)) ??
                throw ContextInvalid();
            result.AddRange(evaluation.Findings.Select(finding =>
                WaiverDispositionCore.Protect(finding, declaration)));
        }

        foreach (var evaluation in extensionEvaluations)
        {
            var declaration = activeExtensions.Snapshot.Extensions.SingleOrDefault(row =>
                row.ExtensionId.Equals(evaluation.ExtensionId) &&
                row.Revision.Equals(evaluation.RuleRevision)) ??
                throw ContextInvalid();
            var evaluator = activeExtensions.Policy.EvaluatorKinds.SingleOrDefault(row =>
                string.Equals(
                    row.EvaluatorKind,
                    declaration.EvaluatorKind,
                    StringComparison.Ordinal) &&
                string.Equals(
                    row.EvaluatorVersion,
                    declaration.EvaluatorVersion,
                    StringComparison.Ordinal)) ?? throw ContextInvalid();
            result.AddRange(evaluation.Findings.Select(finding =>
                WaiverDispositionCore.Protect(finding, declaration, evaluator)));
        }

        return Array.AsReadOnly(result.ToArray());
    }

    private static ConformanceVerdict Verdict(
        CompleteCatalogEvaluation baseline,
        IReadOnlyList<ExtensionEvaluation> extensions) =>
        baseline.Verdict.Equals(ConformanceVerdict.Indeterminate) ||
        extensions.Any(static row =>
            row.IsApplicabilityUnresolved ||
            row.Status.Equals(RuleEvaluationStatus.NotEvaluated))
            ? ConformanceVerdict.Indeterminate
            : baseline.Verdict.Equals(ConformanceVerdict.NonConforming) ||
              extensions.Any(static row =>
                  row.Status.Equals(RuleEvaluationStatus.Violated))
                ? ConformanceVerdict.NonConforming
                : ConformanceVerdict.Conforming;

    private static EnforcementDecision Enforcement(
        ConformanceVerdict verdict,
        EnforcementPhase phase,
        IReadOnlyList<FindingDispositionResult> dispositions)
    {
        if (phase.Equals(EnforcementPhase.Audit))
        {
            return EnforcementDecision.ReportOnly;
        }

        if (verdict.Equals(ConformanceVerdict.Indeterminate) ||
            dispositions.Any(static row =>
                row.Disposition.Equals(FindingDisposition.ActiveViolation)) ||
            phase.Equals(EnforcementPhase.FullBlocking) &&
            dispositions.Any(static row =>
                row.Disposition.Equals(FindingDisposition.HistoricalDebt)) ||
            verdict.Equals(ConformanceVerdict.NonConforming) &&
            dispositions.Count == 0)
        {
            return EnforcementDecision.Block;
        }

        return EnforcementDecision.Allow;
    }

    private static bool IsExactDebt(
        ProtectedFinding finding,
        HistoricalDebtEntry debt,
        string protocolVersion,
        DateTimeOffset evaluationUtc,
        ExactSha256Digest trustedBaseAuthorityDigest) =>
        SameIdentity(finding.Identity, debt.Finding) &&
        string.Equals(debt.ProtocolVersion, protocolVersion, StringComparison.Ordinal) &&
        debt.StableEvidenceDigest.Equals(finding.Identity.EvidenceDigest) &&
        debt.TrustedBaseAuthorityDigest.Equals(trustedBaseAuthorityDigest) &&
        debt.ClosedUtc is null &&
        (debt.ExpiresUtc is null || evaluationUtc < debt.ExpiresUtc.Value);

    private static bool SameIdentity(
        ProtectedFindingIdentity left,
        ProtectedFindingIdentity right) =>
        string.Equals(
            left.Rule.CanonicalKey,
            right.Rule.CanonicalKey,
            StringComparison.Ordinal) &&
        left.FindingCode.Equals(right.FindingCode) &&
        left.LocationDigest.Equals(right.LocationDigest) &&
        left.EvidenceDigest.Equals(right.EvidenceDigest) &&
        left.ExpectedValueDigest.Equals(right.ExpectedValueDigest) &&
        left.StableKey.Value.Equals(right.StableKey.Value);

    private static RuntimeQualificationBinding RuntimeBinding(
        CompleteCatalogSnapshot catalog,
        KernelPlanningSession session,
        ActivatedExtensionPolicy activeExtensions)
    {
        var runtimeArtifact = activeExtensions.PolicyPackBinding.Artifacts.SingleOrDefault(
            static row => string.Equals(
                row.ArtifactKey,
                "protocol.artifact.conformance-runtime",
                StringComparison.Ordinal)) ?? throw ContextInvalid();
        var anchor = ProtectedPolicyFrame.Hash(
            "protocol.protected-current-trust-anchor/1\n",
            stream =>
            {
                ProtectedPolicyFrame.Digest(
                    stream,
                    activeExtensions.Policy.AuthorityPublicKeyDigest);
                ProtectedPolicyFrame.Digest(
                    stream,
                    activeExtensions.Policy.ExportDigest);
                ProtectedPolicyFrame.Digest(
                    stream,
                    activeExtensions.Snapshot.SnapshotDigest);
                ProtectedPolicyFrame.Digest(
                    stream,
                    activeExtensions.AuthoritySetDigest);
            });
        return RuntimeQualificationBinding.Create(
            catalog.ProtocolVersion,
            session.Manifest.SourceCommit,
            catalog.ManifestDigest,
            catalog.CompleteInventoryDigest,
            activeExtensions.PolicyPackBinding.BindingDigest,
            runtimeArtifact.FileDigest,
            anchor);
    }

    internal static ProtectedOutcomeSetProjection ProjectOutcomeSet(
        ProtectedPolicyEvaluation evaluation)
    {
        ArgumentNullException.ThrowIfNull(evaluation);
        return ProjectOutcomeSet(
            evaluation.Baseline.Evaluations,
            evaluation.ExtensionEvaluations,
            evaluation.Dispositions,
            evaluation.Verdict,
            evaluation.Enforcement);
    }

    private static ProtectedOutcomeSetProjection ProjectOutcomeSet(
        IReadOnlyList<RuleEvaluation> baseline,
        IReadOnlyList<ExtensionEvaluation> extensions,
        IReadOnlyList<FindingDispositionResult> dispositions,
        ConformanceVerdict verdict,
        EnforcementDecision enforcement)
    {
        if ((long)baseline.Count + extensions.Count + 3 > MaximumOutcomes)
        {
            throw ResourceLimit();
        }

        ValidateOutcomeSetBounds(baseline.Select(row =>
                ProtectedOutcomeIdentity.ForRule(
                    PolicyRuleIdentity.Baseline(
                        row.RuleId,
                        row.RuleRevision)).RowKey)
            .Concat(extensions.Select(row =>
                ProtectedOutcomeIdentity.ForRule(
                    PolicyRuleIdentity.Extension(
                        row.ExtensionId,
                        row.RuleRevision)).RowKey))
            .Concat([
                "global:dispositions",
                "global:verdict",
                "global:enforcement",
            ]));
        var protectedByBaselineFinding =
            new Dictionary<RuleFinding, ProtectedFinding>(
                ReferenceEqualityComparer.Instance);
        var protectedByExtensionFinding =
            new Dictionary<ExtensionFinding, ProtectedFinding>(
                ReferenceEqualityComparer.Instance);
        foreach (var disposition in dispositions)
        {
            if (disposition.Finding.BaselineFinding is { } baselineFinding)
            {
                protectedByBaselineFinding.Add(
                    baselineFinding,
                    disposition.Finding);
            }
            else if (disposition.Finding.ExtensionFinding is { } extensionFinding)
            {
                protectedByExtensionFinding.Add(
                    extensionFinding,
                    disposition.Finding);
            }
        }
        var entries = new List<OutcomeEntry>();
        entries.AddRange(baseline.Select(row => new OutcomeEntry(
            ProtectedOutcomeIdentity.ForRule(
                PolicyRuleIdentity.Baseline(row.RuleId, row.RuleRevision)).RowKey,
            RuleOutcome(row, protectedByBaselineFinding))));
        entries.AddRange(extensions.Select(row => new OutcomeEntry(
            ProtectedOutcomeIdentity.ForRule(
                PolicyRuleIdentity.Extension(
                    row.ExtensionId,
                    row.RuleRevision)).RowKey,
            RuleOutcome(row, protectedByExtensionFinding))));
        entries.Sort(static (left, right) =>
            StringComparer.Ordinal.Compare(left.Key, right.Key));
        entries.Add(new OutcomeEntry(
            "global:dispositions",
            DispositionsOutcome(dispositions)));
        entries.Add(new OutcomeEntry(
            "global:verdict",
            ScalarOutcome(ProtectedOutcomeKind.Verdict.Value, verdict.Value)));
        entries.Add(new OutcomeEntry(
            "global:enforcement",
            ScalarOutcome(
                ProtectedOutcomeKind.Enforcement.Value,
                enforcement.Value)));
        var rows = entries.Select(static entry =>
            KeyValuePair.Create(entry.Key, entry.Digest)).ToArray();
        return new ProtectedOutcomeSetProjection(rows, OutcomeSetFrame(rows));
    }

    private static ExactSha256Digest OutcomeSetFrame(
        IReadOnlyList<KeyValuePair<string, ExactSha256Digest>> entries)
    {
        ValidateOutcomeSetBounds(entries.Select(static entry => entry.Key));
        return ProtectedPolicyFrame.Hash(
            "protocol.protected-outcome-set/1\n",
            stream =>
            {
                ProtectedPolicyFrame.UInt32(
                    stream,
                    checked((uint)entries.Count));
                foreach (var entry in entries)
                {
                    ProtectedPolicyFrame.String(stream, entry.Key);
                    ProtectedPolicyFrame.Digest(stream, entry.Value);
                }
            });
    }

    private static void ValidateOutcomeSetBounds(IEnumerable<string> keys)
    {
        var count = 0;
        var globalIndex = 0;
        string? previousRule = null;
        long bytes = "protocol.protected-outcome-set/1\n"u8.Length + 4;
        try
        {
            foreach (var key in keys)
            {
                if (key.StartsWith("rule:", StringComparison.Ordinal))
                {
                    if (globalIndex != 0 || previousRule is not null &&
                        StringComparer.Ordinal.Compare(previousRule, key) >= 0)
                    {
                        throw ContextInvalid();
                    }

                    previousRule = key;
                }
                else
                {
                    var expected = globalIndex switch
                    {
                        0 => "global:dispositions",
                        1 => "global:verdict",
                        2 => "global:enforcement",
                        _ => string.Empty,
                    };
                    if (!string.Equals(key, expected, StringComparison.Ordinal))
                    {
                        throw ContextInvalid();
                    }

                    globalIndex++;
                }

                if (count >= MaximumOutcomes ||
                    !ProtectedPolicyFrame.TryUtf8ByteCount(key, out var keyBytes))
                {
                    throw ResourceLimit();
                }

                bytes = checked(bytes + 4L + keyBytes + 32L);
                if (bytes > MaximumCanonicalSetBytes)
                {
                    throw ResourceLimit();
                }

                count++;
            }

            if (globalIndex != 3)
            {
                throw ContextInvalid();
            }
        }
        catch (OverflowException)
        {
            throw ResourceLimit();
        }
    }

    private static ExactSha256Digest RuleOutcome(
        RuleEvaluation evaluation,
        IReadOnlyDictionary<RuleFinding, ProtectedFinding> findings) =>
        ProtectedPolicyFrame.Hash(
            "protocol.protected-outcome-entry/1\n",
            stream =>
            {
                ProtectedPolicyFrame.String(stream, ProtectedOutcomeKind.Rule.Value);
                stream.WriteByte(0);
                ProtectedPolicyFrame.String(stream, evaluation.RuleId.Value);
                ProtectedPolicyFrame.UInt32(
                    stream,
                    checked((uint)evaluation.RuleRevision.Value));
                WriteEvaluation(
                    stream,
                    evaluation.Status,
                    evaluation.IsApplicabilityUnresolved,
                    evaluation.ApplicabilityReferences,
                    evaluation.UnresolvedSlotKeys,
                    evaluation.Findings.Select(row => FindingRow(
                        findings[row],
                        row.Severity.Value,
                        row.Remediation.Value,
                        row.PrimaryReference,
                        row.RelatedReferences)),
                    evaluation.Failures.Select(row => FailureRow(
                        row.Code.Value,
                        row.PrimaryReference,
                        row.RelatedReferences)));
            });

    private static ExactSha256Digest RuleOutcome(
        ExtensionEvaluation evaluation,
        IReadOnlyDictionary<ExtensionFinding, ProtectedFinding> findings) =>
        ProtectedPolicyFrame.Hash(
            "protocol.protected-outcome-entry/1\n",
            stream =>
            {
                ProtectedPolicyFrame.String(stream, ProtectedOutcomeKind.Rule.Value);
                stream.WriteByte(1);
                ProtectedPolicyFrame.String(stream, evaluation.ExtensionId.Value);
                ProtectedPolicyFrame.UInt32(
                    stream,
                    checked((uint)evaluation.RuleRevision.Value));
                WriteEvaluation(
                    stream,
                    evaluation.Status,
                    evaluation.IsApplicabilityUnresolved,
                    evaluation.ApplicabilityReferences,
                    evaluation.UnresolvedSlotKeys,
                    evaluation.Findings.Select(row => FindingRow(
                        findings[row],
                        row.Severity.Value,
                        row.Remediation.Value,
                        row.PrimaryReference,
                        row.RelatedReferences)),
                    evaluation.Failures.Select(row => FailureRow(
                        row.Code.Value,
                        row.PrimaryReference,
                        row.RelatedReferences)));
            });

    private static void WriteEvaluation(
        MemoryStream stream,
        RuleEvaluationStatus status,
        bool applicabilityUnresolved,
        IEnumerable<QualifiedEvidenceReference> applicabilityReferences,
        IEnumerable<string> unresolvedSlotKeys,
        IEnumerable<FindingProjection> findings,
        IEnumerable<FailureProjection> failures)
    {
        if (applicabilityUnresolved &&
            !status.Equals(RuleEvaluationStatus.NotEvaluated))
        {
            throw ContextInvalid();
        }

        ProtectedPolicyFrame.String(
            stream,
            applicabilityUnresolved
                ? "unresolved"
                : status.Equals(RuleEvaluationStatus.NotApplicable)
                    ? "not-applicable"
                    : "applicable");
        ProtectedPolicyFrame.String(stream, status.Value);
        WriteDigests(
            stream,
            CanonicalReferences(applicabilityReferences));
        WriteStrings(
            stream,
            OrderedUnique(
                unresolvedSlotKeys,
                static value => value,
                MaximumSlots));
        var findingRows = findings.OrderBy(
            static row => row.Finding.Identity.StableKey.Value.Value,
            StringComparer.Ordinal).ToArray();
        ProtectedPolicyFrame.UInt32(
            stream,
            checked((uint)findingRows.Length));
        foreach (var row in findingRows)
        {
            ProtectedPolicyFrame.String(
                stream,
                row.Finding.Identity.StableKey.Value.Value);
            ProtectedPolicyFrame.String(stream, row.Severity);
            ProtectedPolicyFrame.String(stream, row.Remediation);
            ProtectedPolicyFrame.Digest(stream, row.Primary);
            WriteDigests(stream, row.Related);
        }

        var failureRows = failures.OrderBy(
            static row => row.Code,
            StringComparer.Ordinal).ThenBy(
            static row => row.Primary.Value,
            StringComparer.Ordinal).ToArray();
        ProtectedPolicyFrame.UInt32(
            stream,
            checked((uint)failureRows.Length));
        foreach (var row in failureRows)
        {
            ProtectedPolicyFrame.String(stream, row.Code);
            ProtectedPolicyFrame.Digest(stream, row.Primary);
            WriteDigests(stream, row.Related);
        }
    }

    private static FindingProjection FindingRow(
        ProtectedFinding finding,
        string severity,
        string remediation,
        QualifiedEvidenceReference primary,
        IReadOnlyList<QualifiedEvidenceReference> related) => new(
            finding,
            severity,
            remediation,
            WaiverDispositionCore.ReferenceDigest(primary),
            CanonicalReferences(related));

    private static FailureProjection FailureRow(
        string code,
        QualifiedEvidenceReference primary,
        IReadOnlyList<QualifiedEvidenceReference> related) => new(
            code,
            WaiverDispositionCore.ReferenceDigest(primary),
            CanonicalReferences(related));

    private static ExactSha256Digest DispositionsOutcome(
        IReadOnlyList<FindingDispositionResult> dispositions) =>
        ProtectedPolicyFrame.Hash(
            "protocol.protected-outcome-entry/1\n",
            stream =>
            {
                ProtectedPolicyFrame.String(
                    stream,
                    ProtectedOutcomeKind.Dispositions.Value);
                var rows = dispositions.OrderBy(
                    static row => row.Finding.Identity.StableKey.Value.Value,
                    StringComparer.Ordinal).ToArray();
                ProtectedPolicyFrame.UInt32(
                    stream,
                    checked((uint)rows.Length));
                foreach (var row in rows)
                {
                    ProtectedPolicyFrame.String(
                        stream,
                        row.Finding.Identity.StableKey.Value.Value);
                    ProtectedPolicyFrame.String(
                        stream,
                        row.Disposition.Value);
                    ProtectedPolicyFrame.OptionalDigest(
                        stream,
                        row.Waiver?.DeclarationDigest);
                    ProtectedPolicyFrame.OptionalDigest(
                        stream,
                        row.Debt?.EntryDigest);
                }
            });

    private static ExactSha256Digest ScalarOutcome(
        string kind,
        string value) => ProtectedPolicyFrame.Hash(
        "protocol.protected-outcome-entry/1\n",
        stream =>
        {
            ProtectedPolicyFrame.String(stream, kind);
            ProtectedPolicyFrame.String(stream, value);
        });

    private static IEnumerable<QualifiedEvidenceReference> References(
        CompleteCatalogEvaluation baseline,
        EvaluationClosure closure,
        IReadOnlyList<ExtensionEvaluation> extensions)
    {
        foreach (var reference in closure.Acquisitions
                     .Select(static row => row.ContextProof)
                     .Where(static row => row is not null))
        {
            yield return reference!;
        }

        foreach (var evaluation in baseline.Evaluations)
        {
            foreach (var reference in EvaluationReferences(evaluation))
            {
                yield return reference;
            }
        }

        foreach (var evaluation in extensions)
        {
            foreach (var reference in EvaluationReferences(evaluation))
            {
                yield return reference;
            }
        }
    }

    private static IEnumerable<QualifiedEvidenceReference> EvaluationReferences(
        RuleEvaluation evaluation) => evaluation.ApplicabilityReferences
        .Concat(evaluation.Findings.Select(static row => row.PrimaryReference))
        .Concat(evaluation.Findings.SelectMany(static row => row.RelatedReferences))
        .Concat(evaluation.Failures.Select(static row => row.PrimaryReference))
        .Concat(evaluation.Failures.SelectMany(static row => row.RelatedReferences));

    private static IEnumerable<QualifiedEvidenceReference> EvaluationReferences(
        ExtensionEvaluation evaluation) => evaluation.ApplicabilityReferences
        .Concat(evaluation.Findings.Select(static row => row.PrimaryReference))
        .Concat(evaluation.Findings.SelectMany(static row => row.RelatedReferences))
        .Concat(evaluation.Failures.Select(static row => row.PrimaryReference))
        .Concat(evaluation.Failures.SelectMany(static row => row.RelatedReferences));

    internal static IReadOnlyList<T> OrderedUnique<T>(
        IEnumerable<T> values,
        Func<T, string> key,
        int maximum)
    {
        var rows = new SortedDictionary<string, T>(StringComparer.Ordinal);
        foreach (var value in values)
        {
            if (value is null)
            {
                throw ContextInvalid();
            }

            var rowKey = key(value);
            if (rows.ContainsKey(rowKey))
            {
                throw ContextInvalid();
            }

            if (rows.Count >= maximum)
            {
                throw ResourceLimit();
            }

            rows.Add(rowKey, value);
        }

        return Array.AsReadOnly(rows.Values.ToArray());
    }

    private static IReadOnlyList<ExactSha256Digest> CanonicalReferences(
        IEnumerable<QualifiedEvidenceReference> references,
        int maximum = MaximumReferences) => CanonicalFrames(
        references,
        WaiverDispositionCore.ReferenceDigest,
        WaiverDispositionCore.ReferenceFrame,
        maximum,
        allowIdenticalDuplicates: true);

    private static IReadOnlyList<ExactSha256Digest> CanonicalScopes(
        IEnumerable<EvidenceScope> scopes,
        bool allowIdenticalDuplicates,
        int maximum = MaximumScopes) => CanonicalFrames(
        scopes,
        WaiverDispositionCore.ScopeDigest,
        WaiverDispositionCore.ScopeFrame,
        maximum,
        allowIdenticalDuplicates);

    internal static IReadOnlyList<ExactSha256Digest> CanonicalFrames<T>(
        IEnumerable<T> values,
        Func<T, ExactSha256Digest> digestOf,
        Func<T, byte[]> frameOf,
        int maximum,
        bool allowIdenticalDuplicates)
        where T : class
    {
        var rows = new Dictionary<string, (ExactSha256Digest Digest, T Value)>(
            StringComparer.Ordinal);
        foreach (var value in values)
        {
            if (value is null)
            {
                throw ContextInvalid();
            }

            var digest = digestOf(value);
            if (rows.TryGetValue(digest.Value, out var existing))
            {
                if (!frameOf(existing.Value).SequenceEqual(frameOf(value)) ||
                    !allowIdenticalDuplicates)
                {
                    throw ContextInvalid();
                }

                continue;
            }

            if (rows.Count >= maximum)
            {
                throw ResourceLimit();
            }

            rows.Add(digest.Value, (digest, value));
        }

        return Array.AsReadOnly(rows.Values
            .Select(static row => row.Digest)
            .OrderBy(static row => row.Value, StringComparer.Ordinal)
            .ToArray());
    }

    private static void WriteStrings(
        MemoryStream stream,
        IReadOnlyList<string> values)
    {
        ProtectedPolicyFrame.UInt32(stream, checked((uint)values.Count));
        foreach (var value in values)
        {
            ProtectedPolicyFrame.String(stream, value);
        }
    }

    private static void WriteDigests(
        MemoryStream stream,
        IReadOnlyList<ExactSha256Digest> values)
    {
        ProtectedPolicyFrame.UInt32(stream, checked((uint)values.Count));
        foreach (var value in values)
        {
            ProtectedPolicyFrame.Digest(stream, value);
        }
    }

    private static ProtectedPolicyIntegrityException ContextInvalid() =>
        new(ProtectedPolicyIntegrityCode.EvaluationContextMismatch);

    private static ProtectedPolicyIntegrityException ResourceLimit() =>
        new(ProtectedPolicyIntegrityCode.ResourceLimitExceeded);

    private sealed class RejectingInputAccess : IRuleInputAccess
    {
        internal static RejectingInputAccess Instance { get; } = new();

        public TCapability GetCapability<TCapability>(string slotKey)
            where TCapability : class, IEvidenceCapability =>
            throw ContextInvalid();

        public QualifiedEvidenceHandle GetContextProof(string slotKey) =>
            throw ContextInvalid();

        public QualifiedEvidenceHandle GetExpectedReference(
            string selectorKey,
            QualifiedEvidenceHandle parentHandle) => throw ContextInvalid();
    }

    private sealed record OutcomeEntry(string Key, ExactSha256Digest Digest);

    private sealed record FindingProjection(
        ProtectedFinding Finding,
        string Severity,
        string Remediation,
        ExactSha256Digest Primary,
        IReadOnlyList<ExactSha256Digest> Related);

    private sealed record FailureProjection(
        string Code,
        ExactSha256Digest Primary,
        IReadOnlyList<ExactSha256Digest> Related);
}

internal sealed record DebtEnforcementOutcome(
    ProtectedDispositionAuthority Authority,
    IReadOnlyList<FindingDispositionResult> Dispositions,
    ConformanceVerdict Verdict,
    EnforcementDecision Enforcement);

internal sealed class ProtectedOutcomeSetProjection
{
    internal ProtectedOutcomeSetProjection(
        IEnumerable<KeyValuePair<string, ExactSha256Digest>> entries,
        ExactSha256Digest digest)
    {
        Entries = Array.AsReadOnly(entries.ToArray());
        Digest = digest;
    }

    internal IReadOnlyList<KeyValuePair<string, ExactSha256Digest>> Entries { get; }
    internal ExactSha256Digest Digest { get; }
}
