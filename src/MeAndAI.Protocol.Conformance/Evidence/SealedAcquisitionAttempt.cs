using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class SealedAcquisitionAttempt
{
    internal SealedAcquisitionAttempt(
        AcquisitionInstruction instruction,
        AdmissionProofKind admissionKind,
        AcquisitionStatus status,
        ExactSha256Digest receiptDigest,
        EvidenceScope? scope,
        RequirementAcquisition? requirementAcquisition,
        IEnumerable<AcquisitionFailure> failures)
    {
        Instruction = instruction;
        AdmissionKind = admissionKind;
        Status = status;
        ReceiptDigest = receiptDigest;
        Scope = scope;
        RequirementAcquisition = requirementAcquisition;
        Failures = failures.ToArray();
    }

    public AcquisitionInstruction Instruction { get; }

    public AdmissionProofKind AdmissionKind { get; }

    public AcquisitionStatus Status { get; }

    public ExactSha256Digest ReceiptDigest { get; }

    public EvidenceScope? Scope { get; }

    public RequirementAcquisition? RequirementAcquisition { get; }

    public IReadOnlyList<AcquisitionFailure> Failures { get; }
}
