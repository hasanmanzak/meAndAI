namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IRepositoryTargetResolutionIndex : IEvidenceCapability
{
    IReadOnlyList<RepositoryTargetResolutionView> Targets { get; }
}
