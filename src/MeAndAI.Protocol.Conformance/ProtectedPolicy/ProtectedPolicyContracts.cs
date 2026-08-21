using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class ExtensionFinding
{
    internal ExtensionFinding(
        ExtensionId extensionId,
        RuleRevision ruleRevision,
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        QualifiedEvidenceReference primaryReference,
        IEnumerable<QualifiedEvidenceReference> relatedReferences,
        string stableStateToken,
        string? stableStateValue)
    {
        ExtensionId = extensionId;
        RuleRevision = ruleRevision;
        Code = code;
        Severity = severity;
        Remediation = remediation;
        PrimaryReference = primaryReference;
        RelatedReferences = Array.AsReadOnly(relatedReferences.ToArray());
        StableStateToken = stableStateToken;
        StableStateValue = stableStateValue;
    }

    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public FindingCode Code { get; }
    public FindingSeverity Severity { get; }
    public RemediationKey Remediation { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
    public string StableStateToken { get; }
    public string? StableStateValue { get; }
}

public sealed class ExtensionEvaluationFailure
{
    internal ExtensionEvaluationFailure(
        ExtensionId extensionId,
        RuleRevision ruleRevision,
        EvaluationFailureCode code,
        QualifiedEvidenceReference primaryReference,
        IEnumerable<QualifiedEvidenceReference> relatedReferences)
    {
        ExtensionId = extensionId;
        RuleRevision = ruleRevision;
        Code = code;
        PrimaryReference = primaryReference;
        RelatedReferences = Array.AsReadOnly(relatedReferences.ToArray());
    }

    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public EvaluationFailureCode Code { get; }
    public QualifiedEvidenceReference PrimaryReference { get; }
    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}

public sealed class ExtensionEvaluation
{
    internal ExtensionEvaluation(
        ExtensionId extensionId,
        RuleRevision ruleRevision,
        RuleEvaluationStatus status,
        bool isApplicabilityUnresolved,
        IEnumerable<QualifiedEvidenceReference> applicabilityReferences,
        IEnumerable<string> unresolvedSlotKeys,
        IEnumerable<ExtensionFinding> findings,
        IEnumerable<ExtensionEvaluationFailure> failures)
    {
        ExtensionId = extensionId;
        RuleRevision = ruleRevision;
        Status = status;
        IsApplicabilityUnresolved = isApplicabilityUnresolved;
        ApplicabilityReferences = Array.AsReadOnly(applicabilityReferences.ToArray());
        UnresolvedSlotKeys = Array.AsReadOnly(unresolvedSlotKeys.ToArray());
        Findings = Array.AsReadOnly(findings.ToArray());
        Failures = Array.AsReadOnly(failures.ToArray());
    }

    public ExtensionId ExtensionId { get; }
    public RuleRevision RuleRevision { get; }
    public RuleEvaluationStatus Status { get; }
    public bool IsApplicabilityUnresolved { get; }
    public IReadOnlyList<QualifiedEvidenceReference> ApplicabilityReferences { get; }
    public IReadOnlyList<string> UnresolvedSlotKeys { get; }
    public IReadOnlyList<ExtensionFinding> Findings { get; }
    public IReadOnlyList<ExtensionEvaluationFailure> Failures { get; }
}

public sealed class ProtectedFinding
{
    private ProtectedFinding(
        ProtectedFindingIdentity identity,
        RuleFinding? baselineFinding,
        ExtensionFinding? extensionFinding)
    {
        Identity = identity;
        BaselineFinding = baselineFinding;
        ExtensionFinding = extensionFinding;
    }

    public ProtectedFindingIdentity Identity { get; }
    public RuleFinding? BaselineFinding { get; }
    public ExtensionFinding? ExtensionFinding { get; }

    internal static ProtectedFinding Baseline(
        ProtectedFindingIdentity identity,
        RuleFinding finding,
        RuleDeclaration declaration)
    {
        ArgumentNullException.ThrowIfNull(identity);
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(declaration);
        if (identity.Rule.BaselineRuleId is null ||
            !identity.Rule.BaselineRuleId.Equals(finding.RuleId) ||
            !identity.Rule.Revision.Equals(finding.RuleRevision) ||
            !identity.FindingCode.Equals(finding.Code) ||
            !declaration.RuleId.Equals(finding.RuleId) ||
            !declaration.RuleRevision.Equals(finding.RuleRevision))
        {
            throw new ArgumentException("The baseline finding identity does not match its finding.", nameof(identity));
        }

        return new ProtectedFinding(identity, finding, null);
    }

    internal static ProtectedFinding Extension(
        ProtectedFindingIdentity identity,
        ExtensionFinding finding,
        ExtensionRuleDeclaration declaration,
        ExtensionEvaluatorKindDeclaration evaluatorKind)
    {
        ArgumentNullException.ThrowIfNull(identity);
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(evaluatorKind);
        if (identity.Rule.ExtensionId is null ||
            !identity.Rule.ExtensionId.Equals(finding.ExtensionId) ||
            !identity.Rule.Revision.Equals(finding.RuleRevision) ||
            !identity.FindingCode.Equals(finding.Code) ||
            !declaration.ExtensionId.Equals(finding.ExtensionId) ||
            !declaration.Revision.Equals(finding.RuleRevision) ||
            !string.Equals(declaration.EvaluatorKind, evaluatorKind.EvaluatorKind, StringComparison.Ordinal))
        {
            throw new ArgumentException("The extension finding identity does not match its finding.", nameof(identity));
        }

        return new ProtectedFinding(identity, null, finding);
    }
}

public sealed class FindingDispositionResult
{
    internal FindingDispositionResult(
        ProtectedFinding finding,
        FindingDisposition disposition,
        WaiverDeclaration? waiver,
        HistoricalDebtEntry? debt)
    {
        ArgumentNullException.ThrowIfNull(finding);
        ArgumentNullException.ThrowIfNull(disposition);
        var valid = disposition.Equals(FindingDisposition.ActiveViolation)
            ? waiver is null && debt is null
            : disposition.Equals(FindingDisposition.Waived)
                ? waiver is not null && debt is null
                : waiver is null && debt is not null;
        if (!valid)
        {
            throw new ArgumentException("The disposition union is invalid.");
        }

        Finding = finding;
        Disposition = disposition;
        Waiver = waiver;
        Debt = debt;
    }

    public ProtectedFinding Finding { get; }
    public FindingDisposition Disposition { get; }
    public WaiverDeclaration? Waiver { get; }
    public HistoricalDebtEntry? Debt { get; }
}

public sealed class ActivatedExtensionPolicy
{
    internal ActivatedExtensionPolicy(
        ExtensionCatalogSnapshot snapshot,
        ProtectedExtensionActivationPayload activationPayload,
        ProtectedPolicyPackBinding policyPackBinding,
        ExtensionPolicyPackExport policy,
        ExactSha256Digest authoritySetDigest,
        ExactSha256Digest activationRecordDigest,
        long activationEpoch)
    {
        Snapshot = snapshot;
        ActivationPayload = activationPayload;
        PolicyPackBinding = policyPackBinding;
        Policy = policy;
        AuthoritySetDigest = authoritySetDigest;
        ActivationRecordDigest = activationRecordDigest;
        ActivationEpoch = activationEpoch;
    }

    public ExtensionCatalogSnapshot Snapshot { get; }
    public ProtectedExtensionActivationPayload ActivationPayload { get; }
    public ProtectedPolicyPackBinding PolicyPackBinding { get; }
    public ExtensionPolicyPackExport Policy { get; }
    public ExactSha256Digest AuthoritySetDigest { get; }
    public ExactSha256Digest ActivationRecordDigest { get; }
    public long ActivationEpoch { get; }
}

public sealed class ProtectedPolicyEvaluation
{
    internal ProtectedPolicyEvaluation(
        RuntimeQualificationBinding runtimeBinding,
        CompleteCatalogEvaluation baseline,
        ActivatedExtensionPolicy activeExtensions,
        ProtectedDispositionAuthority dispositionAuthority,
        ProposedExtensionTransition? proposedTransition,
        IEnumerable<ExtensionEvaluation> extensionEvaluations,
        IEnumerable<FindingDispositionResult> dispositions,
        ExactSha256Digest evidenceSetDigest,
        ExactSha256Digest outcomeSetDigest,
        ConformanceVerdict verdict,
        EnforcementDecision enforcement)
    {
        RuntimeBinding = runtimeBinding;
        Baseline = baseline;
        ActiveExtensions = activeExtensions;
        DispositionAuthority = dispositionAuthority;
        ProposedTransition = proposedTransition;
        ExtensionEvaluations = Array.AsReadOnly(extensionEvaluations.ToArray());
        Dispositions = Array.AsReadOnly(dispositions.ToArray());
        EvidenceSetDigest = evidenceSetDigest;
        OutcomeSetDigest = outcomeSetDigest;
        Verdict = verdict;
        Enforcement = enforcement;
    }

    public RuntimeQualificationBinding RuntimeBinding { get; }
    public CompleteCatalogEvaluation Baseline { get; }
    public ActivatedExtensionPolicy ActiveExtensions { get; }
    public ProtectedDispositionAuthority DispositionAuthority { get; }
    public ProposedExtensionTransition? ProposedTransition { get; }
    public IReadOnlyList<ExtensionEvaluation> ExtensionEvaluations { get; }
    public IReadOnlyList<FindingDispositionResult> Dispositions { get; }
    public ExactSha256Digest EvidenceSetDigest { get; }
    public ExactSha256Digest OutcomeSetDigest { get; }
    public ConformanceVerdict Verdict { get; }
    public EnforcementDecision Enforcement { get; }
}

public sealed class CandidateIndependentQualificationInput
{
    private CandidateIndependentQualificationInput(
        string fixtureSetKey,
        string fixtureSetVersion,
        ExactSha256Digest fixtureSetDigest,
        ExactSha256Digest expectedOutcomeSetDigest,
        ProtectedPolicyEvaluation evaluation,
        ExactSha256Digest inputDigest)
    {
        FixtureSetKey = fixtureSetKey;
        FixtureSetVersion = fixtureSetVersion;
        FixtureSetDigest = fixtureSetDigest;
        ExpectedOutcomeSetDigest = expectedOutcomeSetDigest;
        Evaluation = evaluation;
        InputDigest = inputDigest;
    }

    public string FixtureSetKey { get; }
    public string FixtureSetVersion { get; }
    public ExactSha256Digest FixtureSetDigest { get; }
    public ExactSha256Digest ExpectedOutcomeSetDigest { get; }
    public ProtectedPolicyEvaluation Evaluation { get; }
    public ExactSha256Digest InputDigest { get; }

    public static CandidateIndependentQualificationInput Create(
        string fixtureSetKey,
        string fixtureSetVersion,
        ExactSha256Digest fixtureSetDigest,
        ExactSha256Digest expectedOutcomeSetDigest,
        ProtectedPolicyEvaluation evaluation)
    {
        ArgumentNullException.ThrowIfNull(evaluation);
        var key = ProtectedPolicyValueFrame.Text(fixtureSetKey, nameof(fixtureSetKey), 128);
        var version = ProtectedPolicyValueFrame.Text(fixtureSetVersion, nameof(fixtureSetVersion), 32);
        ProtectedPolicyValueFrame.RequireDigest(fixtureSetDigest, nameof(fixtureSetDigest));
        ProtectedPolicyValueFrame.RequireDigest(expectedOutcomeSetDigest, nameof(expectedOutcomeSetDigest));
        var digest = ProtectedPolicyValueFrame.Hash("protocol.qualification-fixture-input/1\n", stream =>
        {
            ProtectedPolicyValueFrame.String(stream, key);
            ProtectedPolicyValueFrame.String(stream, version);
            ProtectedPolicyValueFrame.Digest(stream, fixtureSetDigest);
            ProtectedPolicyValueFrame.Digest(stream, expectedOutcomeSetDigest);
            ProtectedPolicyValueFrame.Digest(stream, evaluation.EvidenceSetDigest);
            ProtectedPolicyValueFrame.Digest(stream, evaluation.OutcomeSetDigest);
        });
        return new CandidateIndependentQualificationInput(
            key, version, fixtureSetDigest, expectedOutcomeSetDigest, evaluation, digest);
    }
}

public sealed class CandidateIndependentQualification
{
    private CandidateIndependentQualification(CandidateIndependentQualificationInput input) => Input = input;

    public CandidateIndependentQualificationInput Input { get; }

    internal static CandidateIndependentQualification Create(
        CandidateIndependentQualificationInput input)
    {
        ArgumentNullException.ThrowIfNull(input);
        return new CandidateIndependentQualification(input);
    }
}

public sealed class SelfConsumptionQualification
{
    internal SelfConsumptionQualification(
        PredecessorTrustBinding predecessor,
        RuntimeQualificationBinding candidate,
        ProtectedPolicyEvaluation predecessorOverlap,
        ProtectedPolicyEvaluation candidateOverlap,
        CandidateIndependentQualification candidateIndependentQualification,
        IEnumerable<ReviewedOutcomeDifference> reviewedDifferences,
        bool hasUnexplainedDifference,
        bool isQualified)
    {
        Predecessor = predecessor;
        Candidate = candidate;
        PredecessorOverlap = predecessorOverlap;
        CandidateOverlap = candidateOverlap;
        CandidateIndependentQualification = candidateIndependentQualification;
        ReviewedDifferences = Array.AsReadOnly(reviewedDifferences.ToArray());
        HasUnexplainedDifference = hasUnexplainedDifference;
        IsQualified = isQualified;
    }

    public PredecessorTrustBinding Predecessor { get; }
    public RuntimeQualificationBinding Candidate { get; }
    public ProtectedPolicyEvaluation PredecessorOverlap { get; }
    public ProtectedPolicyEvaluation CandidateOverlap { get; }
    public CandidateIndependentQualification CandidateIndependentQualification { get; }
    public IReadOnlyList<ReviewedOutcomeDifference> ReviewedDifferences { get; }
    public bool HasUnexplainedDifference { get; }
    public bool IsQualified { get; }
}

internal static class ProtectedPolicyValueFrame
{
    internal static ExactSha256Digest Hash(string separator, Action<MemoryStream> write)
        => ProtectedPolicyFrame.Hash(separator, write);

    internal static void String(MemoryStream stream, string value)
        => ProtectedPolicyFrame.String(stream, value);

    internal static void Digest(MemoryStream stream, ExactSha256Digest value) =>
        ProtectedPolicyFrame.Digest(stream, value);

    internal static string Text(string value, string name, int maximum)
        => ProtectedPolicyFrame.Text(value, name, maximum);

    internal static void RequireDigest(ExactSha256Digest value, string name)
        => ProtectedPolicyFrame.RequireDigest(value, name);
}
