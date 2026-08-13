namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class EvaluationIntent
{
    private EvaluationIntent(
        IEnumerable<FindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures)
    {
        Findings = DeclarationValidation.Snapshot(findings, nameof(findings));
        Failures = DeclarationValidation.Snapshot(failures, nameof(failures));
        if (HasDuplicateFindings(Findings) || HasDuplicateFailures(Failures))
        {
            throw new ArgumentException(
                "Evaluation intents must not contain duplicate semantic tuples.");
        }
    }

    public IReadOnlyList<FindingIntent> Findings { get; }

    public IReadOnlyList<EvaluationFailureIntent> Failures { get; }

    public static EvaluationIntent Create(
        IEnumerable<FindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures) =>
        new(findings, failures);

    private static bool HasDuplicateFindings(
        IReadOnlyList<FindingIntent> findings) =>
        findings.Select((left, index) => (left, index)).Any(candidate =>
            findings.Skip(candidate.index + 1).Any(right =>
                candidate.left.Code.Equals(right.Code) &&
                SameReferences(
                    candidate.left.PrimaryReference,
                    candidate.left.RelatedReferences,
                    right.PrimaryReference,
                    right.RelatedReferences)));

    private static bool HasDuplicateFailures(
        IReadOnlyList<EvaluationFailureIntent> failures) =>
        failures.Select((left, index) => (left, index)).Any(candidate =>
            failures.Skip(candidate.index + 1).Any(right =>
                candidate.left.Code.Equals(right.Code) &&
                SameReferences(
                    candidate.left.PrimaryReference,
                    candidate.left.RelatedReferences,
                    right.PrimaryReference,
                    right.RelatedReferences)));

    private static bool SameReferences(
        QualifiedEvidenceHandle leftPrimary,
        IReadOnlyList<QualifiedEvidenceHandle> leftRelated,
        QualifiedEvidenceHandle rightPrimary,
        IReadOnlyList<QualifiedEvidenceHandle> rightRelated) =>
        ReferenceEquals(leftPrimary, rightPrimary) &&
        leftRelated.Count == rightRelated.Count &&
        leftRelated.Zip(rightRelated).All(pair =>
            ReferenceEquals(pair.First, pair.Second));
}
