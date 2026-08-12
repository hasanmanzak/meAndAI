using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class AcquisitionInstruction
{
    private AcquisitionInstruction(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        int roundOrdinal,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        ExactSha256Digest demandDigest,
        ExactSha256Digest instructionDigest)
    {
        Slot = slot;
        Target = target;
        RoundOrdinal = roundOrdinal;
        DemandItems = demandItems.ToArray();
        DemandDigest = demandDigest;
        InstructionDigest = instructionDigest;
    }

    public EvidenceSlotDeclaration Slot { get; }

    public AcquisitionTarget Target { get; }

    public int RoundOrdinal { get; }

    public IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }

    public ExactSha256Digest DemandDigest { get; }

    public ExactSha256Digest InstructionDigest { get; }

    internal static AcquisitionInstruction CreateApplicability(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    internal static AcquisitionInstruction CreateEvaluation(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        int roundOrdinal,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);
}
