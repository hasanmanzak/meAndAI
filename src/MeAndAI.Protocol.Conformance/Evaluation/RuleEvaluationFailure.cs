using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class RuleEvaluationFailure
{
    internal RuleEvaluationFailure(
        RuleId ruleId,
        RuleRevision ruleRevision,
        EvaluationFailureCode code,
        QualifiedEvidenceReference primaryReference,
        IEnumerable<QualifiedEvidenceReference> relatedReferences)
    {
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        Code = code;
        PrimaryReference = primaryReference;
        RelatedReferences = relatedReferences.ToArray();
    }

    public RuleId RuleId { get; }

    public RuleRevision RuleRevision { get; }

    public EvaluationFailureCode Code { get; }

    public QualifiedEvidenceReference PrimaryReference { get; }

    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}
