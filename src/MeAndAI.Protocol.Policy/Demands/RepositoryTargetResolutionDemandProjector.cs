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
        var candidates = new List<RepositoryTargetResolutionDemandCandidate>();
        for (var index = 0; index < input.Inputs.Count; index++)
        {
            var authority = input.SourceReferenceAuthorities[index];
            foreach (var reference in input.Inputs[index].References)
            {
                cancellationToken.ThrowIfCancellationRequested();
                if (!reference.Resolution.Equals(
                        GovernedReferenceResolution.ExternalEvidenceRequired))
                {
                    continue;
                }

                var owner = reference.OwningRepositoryIdentity ??
                    authority.OwningRepositoryIdentity;
                var sourceAuthority = authority.AuthorityProof;
                if (reference.CommitObjectId is not null)
                {
                    candidates.Add(
                        RepositoryTargetResolutionDemandCandidate.CommitObject(
                            owner,
                            reference.CommitObjectId,
                            reference.NormalizedRepositoryRelativePath,
                            reference.NormalizedFragment,
                            reference.Reference,
                            sourceAuthority));
                }
                else if (reference.NormalizedTagName is not null)
                {
                    candidates.Add(
                        RepositoryTargetResolutionDemandCandidate.TagRoot(
                            owner,
                            reference.NormalizedTagName,
                            reference.Reference,
                            sourceAuthority));
                }
                else if (reference.CapturedSnapshotIdentity is not null &&
                    reference.NormalizedRepositoryRelativePath is not null &&
                    reference.NormalizedFragment is not null &&
                    authority.CapturedManifestContentIdentity is not null)
                {
                    candidates.Add(
                        RepositoryTargetResolutionDemandCandidate
                            .CapturedSnapshotPath(
                                owner,
                                reference.CapturedSnapshotIdentity,
                                reference.NormalizedRepositoryRelativePath,
                                reference.NormalizedFragment,
                                authority.CapturedManifestContentIdentity,
                                reference.Reference,
                                sourceAuthority));
                }
            }
        }

        return DemandProjectionIntent.Projected(
            DemandProjectionProduct.Create(
                candidates,
                Usage(candidates.Count)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        DemandProjectionInput<IGovernedReferenceIndex> input,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate> value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.Count);
    }

    private static SemanticResourceLocalUsage Usage(int count) =>
        SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: count == 0 ? 0 : 1,
            layerNodes: count,
            additionalComplexity: count);
}
