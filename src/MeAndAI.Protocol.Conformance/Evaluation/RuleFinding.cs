using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class RuleFinding
{
    internal RuleFinding(
        RuleId ruleId,
        RuleRevision ruleRevision,
        FindingCode code,
        FindingSeverity severity,
        RemediationKey remediation,
        QualifiedEvidenceReference primaryReference,
        IEnumerable<QualifiedEvidenceReference> relatedReferences)
    {
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        Code = code;
        Severity = severity;
        Remediation = remediation;
        PrimaryReference = primaryReference;
        RelatedReferences = relatedReferences.ToArray();
    }

    public RuleId RuleId { get; }

    public RuleRevision RuleRevision { get; }

    public FindingCode Code { get; }

    public FindingSeverity Severity { get; }

    public RemediationKey Remediation { get; }

    public QualifiedEvidenceReference PrimaryReference { get; }

    public IReadOnlyList<QualifiedEvidenceReference> RelatedReferences { get; }
}
