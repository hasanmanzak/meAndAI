using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

public abstract class EvaluationAdvanceResult
{
    private protected EvaluationAdvanceResult(int completedRoundCount)
    {
        if (completedRoundCount < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(completedRoundCount));
        }

        CompletedRoundCount = completedRoundCount;
    }

    public int CompletedRoundCount { get; }
}

public sealed class EvaluationPlan : EvaluationAdvanceResult
{
    internal EvaluationPlan(
        int completedRoundCount,
        ApplicabilityClosure applicability,
        IEnumerable<EvidenceSlotDeclaration> slots,
        IEnumerable<AcquisitionInstruction> instructions,
        IPlanBoundEvidenceSession evidenceSession)
        : base(completedRoundCount)
    {
        Applicability = applicability;
        Slots = slots.ToArray();
        Instructions = instructions.ToArray();
        EvidenceSession = evidenceSession;
    }

    public ApplicabilityClosure Applicability { get; }

    public IReadOnlyList<EvidenceSlotDeclaration> Slots { get; }

    public IReadOnlyList<AcquisitionInstruction> Instructions { get; }

    internal IPlanBoundEvidenceSession EvidenceSession { get; }
}

public sealed class EvaluationClosure : EvaluationAdvanceResult
{
    internal EvaluationClosure(
        int completedRoundCount,
        ApplicabilityClosure applicability,
        SealedEvaluationContext context,
        IEnumerable<SealedAcquisitionOutcome> acquisitions,
        IEnumerable<RuleEvaluation> terminalEvaluations)
        : base(completedRoundCount)
    {
        Applicability = applicability;
        Context = context;
        Acquisitions = acquisitions.ToArray();
        TerminalEvaluations = terminalEvaluations.ToArray();
    }

    public ApplicabilityClosure Applicability { get; }

    public SealedEvaluationContext Context { get; }

    public IReadOnlyList<SealedAcquisitionOutcome> Acquisitions { get; }

    public IReadOnlyList<RuleEvaluation> TerminalEvaluations { get; }
}
