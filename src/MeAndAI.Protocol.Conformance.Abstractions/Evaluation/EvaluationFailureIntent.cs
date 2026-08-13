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
        if (RelatedReferences.Any(reference =>
                ReferenceEquals(reference, primaryReference)) ||
            RelatedReferences.Distinct(ReferenceEqualityComparer.Instance).Count() !=
                RelatedReferences.Count)
        {
            throw new ArgumentException(
                "Related references must be distinct and must not repeat the primary reference.",
                nameof(relatedReferences));
        }
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
