namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IGovernedReferenceIndex : IEvidenceCapability
{
    IReadOnlyList<GovernedReferenceView> References { get; }
}
