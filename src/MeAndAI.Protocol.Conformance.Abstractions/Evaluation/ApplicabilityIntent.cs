namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ApplicabilityIntent
{
    private ApplicabilityIntent(
        ApplicabilityIntentKind kind,
        IEnumerable<QualifiedEvidenceHandle> references)
    {
        Kind = kind;
        References = DeclarationValidation.Snapshot(references, nameof(references));
        if (References.Distinct(ReferenceEqualityComparer.Instance).Count() !=
            References.Count)
        {
            throw new ArgumentException(
                "Applicability references must be distinct.",
                nameof(references));
        }
    }

    public ApplicabilityIntentKind Kind { get; }

    public IReadOnlyList<QualifiedEvidenceHandle> References { get; }

    public static ApplicabilityIntent Applicable(
        IEnumerable<QualifiedEvidenceHandle> references) =>
        new(ApplicabilityIntentKind.Applicable, references);

    public static ApplicabilityIntent NotApplicable(
        IEnumerable<QualifiedEvidenceHandle> references) =>
        CreateNonEmpty(ApplicabilityIntentKind.NotApplicable, references);

    public static ApplicabilityIntent Unresolved(
        IEnumerable<QualifiedEvidenceHandle> references) =>
        CreateNonEmpty(ApplicabilityIntentKind.Unresolved, references);

    private static ApplicabilityIntent CreateNonEmpty(
        ApplicabilityIntentKind kind,
        IEnumerable<QualifiedEvidenceHandle> references)
    {
        var result = new ApplicabilityIntent(kind, references);
        if (result.References.Count == 0)
        {
            throw new ArgumentException(
                "The intent requires at least one reference.",
                nameof(references));
        }

        return result;
    }
}
