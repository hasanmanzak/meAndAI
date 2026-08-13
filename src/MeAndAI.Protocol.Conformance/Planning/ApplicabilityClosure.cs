namespace MeAndAI.Protocol.Conformance;

public sealed class ApplicabilityClosure
{
    internal ApplicabilityClosure(
        ApplicabilityPlan plan,
        SealedEvaluationContext context,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> terminalEvaluations)
    {
        Plan = plan;
        Context = context;
        Acquisitions = acquisitions.ToArray();
        TerminalEvaluations = terminalEvaluations.ToArray();
    }

    public ApplicabilityPlan Plan { get; }

    public SealedEvaluationContext Context { get; }

    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }

    public IReadOnlyList<RuleEvaluation> TerminalEvaluations { get; }
}
