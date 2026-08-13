using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Demands;

internal sealed class RepositoryTargetResolutionDemandProjector :
    IAcquisitionDemandProjector<IGovernedReferenceIndex>
{
    public DemandProjectionIntent Project(
        DemandProjectionInput<IGovernedReferenceIndex> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        return DemandProjectionIntent.Projected(
            DemandProjectionProduct.Create(
                [],
                SemanticResourceLocalUsage.Create(0, 0, 0, 0)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        DemandProjectionInput<IGovernedReferenceIndex> input,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate> value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: value.Count == 0 ? 0 : 1,
            layerNodes: value.Count,
            additionalComplexity: value.Count);
    }
}
