using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CanonicalConformanceReport
{
    internal CanonicalConformanceReport(
        string schemaKey,
        string schemaVersion,
        RuntimeQualificationBinding runtimeBinding,
        AcquisitionTarget subjectRepository,
        CatalogVersion catalogVersion,
        ExactSha256Digest catalogDigest,
        string profileName,
        ExecutionProfile profile,
        AcquisitionStatus acquisitionStatus,
        IEnumerable<CanonicalAcquisitionResult> acquisitions,
        IEnumerable<CanonicalRuleResult> ruleEvaluations,
        IEnumerable<CanonicalFindingDisposition> dispositions,
        ExactSha256Digest activeExtensionSnapshotDigest,
        ExactSha256Digest activeAuthoritySetDigest,
        ExactSha256Digest activationRecordDigest,
        long activationEpoch,
        ExactSha256Digest dispositionAuthorityBindingDigest,
        ExactSha256Digest waiverSnapshotDigest,
        ExactSha256Digest debtSnapshotDigest,
        DateTimeOffset evaluationUtc,
        ExactSha256Digest? proposedExtensionSnapshotDigest,
        string? proposedTargetCommit,
        ExactSha256Digest? proposedTransitionDigest,
        bool hasKnownViolation,
        bool hasUnresolvedRequiredEvaluation,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest outcomeSetDigest,
        ConformanceVerdict verdict,
        EnforcementDecision enforcement,
        byte[] canonicalBytes,
        ExactSha256Digest reportDigest)
    {
        SchemaKey = schemaKey;
        SchemaVersion = schemaVersion;
        RuntimeBinding = runtimeBinding;
        SubjectRepository = subjectRepository;
        CatalogVersion = catalogVersion;
        CatalogDigest = catalogDigest;
        ProfileName = profileName;
        Profile = profile;
        AcquisitionStatus = acquisitionStatus;
        Acquisitions = Snapshot(acquisitions);
        RuleEvaluations = Snapshot(ruleEvaluations);
        Dispositions = Snapshot(dispositions);
        ActiveExtensionSnapshotDigest = activeExtensionSnapshotDigest;
        ActiveAuthoritySetDigest = activeAuthoritySetDigest;
        ActivationRecordDigest = activationRecordDigest;
        ActivationEpoch = activationEpoch;
        DispositionAuthorityBindingDigest = dispositionAuthorityBindingDigest;
        WaiverSnapshotDigest = waiverSnapshotDigest;
        DebtSnapshotDigest = debtSnapshotDigest;
        EvaluationUtc = evaluationUtc;
        ProposedExtensionSnapshotDigest = proposedExtensionSnapshotDigest;
        ProposedTargetCommit = proposedTargetCommit;
        ProposedTransitionDigest = proposedTransitionDigest;
        HasKnownViolation = hasKnownViolation;
        HasUnresolvedRequiredEvaluation = hasUnresolvedRequiredEvaluation;
        EvidenceSetDigest = evidenceSetDigest;
        OutcomeSetDigest = outcomeSetDigest;
        Verdict = verdict;
        Enforcement = enforcement;
        CanonicalBytes = Array.AsReadOnly(canonicalBytes.ToArray());
        ReportDigest = reportDigest;
    }

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

    private static IReadOnlyList<T> Snapshot<T>(IEnumerable<T> values) =>
        Array.AsReadOnly(values.ToArray());
}

public sealed class CanonicalAcquisitionResult
{
    internal CanonicalAcquisitionResult(
        string slotKey,
        AcquisitionTarget target,
        AcquisitionStatus status,
        bool isProjected,
        ExactSha256Digest outcomeDigest,
        EvidenceScope? scope,
        ExactSha256Digest? contextQualificationProofDigest,
        bool? requiredValuesOmitted,
        bool? nonRequiredValuesOmitted,
        IEnumerable<string> failureCodes)
    {
        SlotKey = slotKey;
        Target = target;
        Status = status;
        IsProjected = isProjected;
        OutcomeDigest = outcomeDigest;
        Scope = scope;
        ContextQualificationProofDigest = contextQualificationProofDigest;
        RequiredValuesOmitted = requiredValuesOmitted;
        NonRequiredValuesOmitted = nonRequiredValuesOmitted;
        FailureCodes = Array.AsReadOnly(failureCodes.ToArray());
    }

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
    internal CanonicalRuleResult(
        PolicyRuleIdentity rule,
        RuleEvaluationStatus status,
        bool isApplicabilityUnresolved,
        IEnumerable<string> unresolvedSlotKeys,
        IEnumerable<ProtectedFindingIdentity> findings,
        IEnumerable<EvaluationFailureCode> failures)
    {
        Rule = rule;
        Status = status;
        IsApplicabilityUnresolved = isApplicabilityUnresolved;
        UnresolvedSlotKeys = Array.AsReadOnly(unresolvedSlotKeys.ToArray());
        Findings = Array.AsReadOnly(findings.ToArray());
        Failures = Array.AsReadOnly(failures.ToArray());
    }

    public PolicyRuleIdentity Rule { get; }
    public RuleEvaluationStatus Status { get; }
    public bool IsApplicabilityUnresolved { get; }
    public IReadOnlyList<string> UnresolvedSlotKeys { get; }
    public IReadOnlyList<ProtectedFindingIdentity> Findings { get; }
    public IReadOnlyList<EvaluationFailureCode> Failures { get; }
}

public sealed class CanonicalFindingDisposition
{
    internal CanonicalFindingDisposition(
        ProtectedFindingIdentity finding,
        FindingDisposition disposition,
        ExactSha256Digest? waiverDeclarationDigest,
        ReviewedAuthorityPermalink? waiverDecisionAuthority,
        DateTimeOffset? waiverExpiresUtc,
        ExactSha256Digest? debtEntryDigest,
        ReviewedAuthorityPermalink? debtAuthority,
        DateTimeOffset? debtExpiresUtc)
    {
        Finding = finding;
        Disposition = disposition;
        WaiverDeclarationDigest = waiverDeclarationDigest;
        WaiverDecisionAuthority = waiverDecisionAuthority;
        WaiverExpiresUtc = waiverExpiresUtc;
        DebtEntryDigest = debtEntryDigest;
        DebtAuthority = debtAuthority;
        DebtExpiresUtc = debtExpiresUtc;
    }

    public ProtectedFindingIdentity Finding { get; }
    public FindingDisposition Disposition { get; }
    public ExactSha256Digest? WaiverDeclarationDigest { get; }
    public ReviewedAuthorityPermalink? WaiverDecisionAuthority { get; }
    public DateTimeOffset? WaiverExpiresUtc { get; }
    public ExactSha256Digest? DebtEntryDigest { get; }
    public ReviewedAuthorityPermalink? DebtAuthority { get; }
    public DateTimeOffset? DebtExpiresUtc { get; }
}
