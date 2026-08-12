namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class FindingIntent
{
    private FindingIntent(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences)
    {
        ArgumentNullException.ThrowIfNull(code);
        ArgumentNullException.ThrowIfNull(primaryReference);
        Code = code;
        PrimaryReference = primaryReference;
        RelatedReferences = DeclarationValidation.Snapshot(
            relatedReferences,
            nameof(relatedReferences));
    }

    public FindingCode Code { get; }

    public QualifiedEvidenceHandle PrimaryReference { get; }

    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }

    public static FindingIntent Create(
        FindingCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences) =>
        new(code, primaryReference, relatedReferences);
}
