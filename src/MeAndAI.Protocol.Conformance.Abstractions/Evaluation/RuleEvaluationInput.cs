using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RuleEvaluationInput
{
    private readonly IRuleInputAccess _access;

    private RuleEvaluationInput(
        RuleId ruleId,
        RuleRevision ruleRevision,
        ExecutionProfile profile,
        IRuleInputAccess access)
    {
        ArgumentNullException.ThrowIfNull(ruleId);
        ArgumentNullException.ThrowIfNull(ruleRevision);
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(access);
        RuleId = ruleId;
        RuleRevision = ruleRevision;
        Profile = profile;
        _access = access;
    }

    public RuleId RuleId { get; }

    public RuleRevision RuleRevision { get; }

    public ExecutionProfile Profile { get; }

    public TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability =>
        _access.GetCapability<TCapability>(slotKey);

    public QualifiedEvidenceHandle GetContextProof(string slotKey) =>
        _access.GetContextProof(slotKey);

    public QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle) =>
        _access.GetExpectedReference(selectorKey, parentHandle);

    internal static RuleEvaluationInput Create(
        RuleId ruleId,
        RuleRevision ruleRevision,
        ExecutionProfile profile,
        IRuleInputAccess access) =>
        new(ruleId, ruleRevision, profile, access);
}
