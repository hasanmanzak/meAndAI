using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class RuleEvaluation
{
    internal RuleEvaluation(
        RuleId ruleId,
        RuleRevision ruleRevision,
        RuleEvaluationStatus status,
        bool isApplicabilityUnresolved,
        IEnumerable<QualifiedEvidenceReference> applicabilityReferences,
        IEnumerable<string> unresolvedSlotKeys,
        IEnumerable<RuleFinding> findings,
        IEnumerable<RuleEvaluationFailure> failures)
    {
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        Status = status;
        IsApplicabilityUnresolved = isApplicabilityUnresolved;
        ApplicabilityReferences = applicabilityReferences.ToArray();
        UnresolvedSlotKeys = unresolvedSlotKeys.ToArray();
        Findings = findings.ToArray();
        Failures = failures.ToArray();
    }

    public RuleId RuleId { get; }

    public RuleRevision RuleRevision { get; }

    public RuleEvaluationStatus Status { get; }

    public bool IsApplicabilityUnresolved { get; }

    public IReadOnlyList<QualifiedEvidenceReference> ApplicabilityReferences { get; }

    public IReadOnlyList<string> UnresolvedSlotKeys { get; }

    public IReadOnlyList<RuleFinding> Findings { get; }

    public IReadOnlyList<RuleEvaluationFailure> Failures { get; }
}
