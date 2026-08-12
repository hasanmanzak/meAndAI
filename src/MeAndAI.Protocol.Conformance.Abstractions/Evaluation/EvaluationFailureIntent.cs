namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class EvaluationFailureIntent
{
    private EvaluationFailureIntent(
        EvaluationFailureCode code,
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

    public EvaluationFailureCode Code { get; }

    public QualifiedEvidenceHandle PrimaryReference { get; }

    public IReadOnlyList<QualifiedEvidenceHandle> RelatedReferences { get; }

    public static EvaluationFailureIntent Create(
        EvaluationFailureCode code,
        QualifiedEvidenceHandle primaryReference,
        IEnumerable<QualifiedEvidenceHandle> relatedReferences) =>
        new(code, primaryReference, relatedReferences);
}
