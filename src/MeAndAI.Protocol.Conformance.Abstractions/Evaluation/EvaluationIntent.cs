namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class EvaluationIntent
{
    private EvaluationIntent(
        IEnumerable<FindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures)
    {
        Findings = DeclarationValidation.Snapshot(findings, nameof(findings));
        Failures = DeclarationValidation.Snapshot(failures, nameof(failures));
    }

    public IReadOnlyList<FindingIntent> Findings { get; }

    public IReadOnlyList<EvaluationFailureIntent> Failures { get; }

    public static EvaluationIntent Create(
        IEnumerable<FindingIntent> findings,
        IEnumerable<EvaluationFailureIntent> failures) =>
        new(findings, failures);
}
