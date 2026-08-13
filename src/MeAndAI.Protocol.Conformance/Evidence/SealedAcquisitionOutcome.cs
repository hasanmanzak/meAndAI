using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class SealedAcquisitionOutcome
{
    internal SealedAcquisitionOutcome(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        AcquisitionStatus status,
        bool isProjected,
        ExactSha256Digest outcomeDigest,
        EvidenceScope? scope,
        RequirementAcquisition? requirementAcquisition,
        QualifiedEvidenceReference? contextProof,
        IEnumerable<SealedAcquisitionAttempt> attempts,
        IEnumerable<AcquisitionFailure> failures)
    {
        Slot = slot;
        Target = target;
        Status = status;
        IsProjected = isProjected;
        OutcomeDigest = outcomeDigest;
        Scope = scope;
        RequirementAcquisition = requirementAcquisition;
        ContextProof = contextProof;
        Attempts = attempts.ToArray();
        Failures = failures.ToArray();
    }

    public EvidenceSlotDeclaration Slot { get; }

    public AcquisitionTarget Target { get; }

    public AcquisitionStatus Status { get; }

    public bool IsProjected { get; }

    public ExactSha256Digest OutcomeDigest { get; }

    public EvidenceScope? Scope { get; }

    public RequirementAcquisition? RequirementAcquisition { get; }

    public QualifiedEvidenceReference? ContextProof { get; }

    public IReadOnlyList<SealedAcquisitionAttempt> Attempts { get; }

    public IReadOnlyList<AcquisitionFailure> Failures { get; }
}
