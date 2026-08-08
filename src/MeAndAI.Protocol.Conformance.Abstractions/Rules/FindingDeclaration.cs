namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class FindingDeclaration
{
    private FindingDeclaration(
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        IReadOnlyList<QualifiedEvidenceReferenceKind>
            allowedPrimaryReferenceKinds,
        IReadOnlyList<QualifiedEvidenceReferenceKind>
            allowedRelatedReferenceKinds)
    {
        Code = code;
        Severity = severity;
        Remediation = remediation;
        AllowedPrimaryReferenceKinds = allowedPrimaryReferenceKinds;
        AllowedRelatedReferenceKinds = allowedRelatedReferenceKinds;
    }

    public FindingCode Code { get; }

    public FindingSeverity Severity { get; }

    public RemediationKey Remediation { get; }

    public IReadOnlyList<QualifiedEvidenceReferenceKind>
        AllowedPrimaryReferenceKinds
    { get; }

    public IReadOnlyList<QualifiedEvidenceReferenceKind>
        AllowedRelatedReferenceKinds
    { get; }

    public static FindingDeclaration Create(
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        IEnumerable<QualifiedEvidenceReferenceKind>
            allowedPrimaryReferenceKinds,
        IEnumerable<QualifiedEvidenceReferenceKind>
            allowedRelatedReferenceKinds)
    {
        ArgumentNullException.ThrowIfNull(code);
        ArgumentNullException.ThrowIfNull(severity);
        ArgumentNullException.ThrowIfNull(remediation);

        return new FindingDeclaration(
            code,
            severity,
            remediation,
            ExpectedSelectorDeclaration.CanonicalReferenceKinds(
                allowedPrimaryReferenceKinds,
                nameof(allowedPrimaryReferenceKinds),
                requireNonEmpty: true),
            ExpectedSelectorDeclaration.CanonicalReferenceKinds(
                allowedRelatedReferenceKinds,
                nameof(allowedRelatedReferenceKinds)));
    }
}
