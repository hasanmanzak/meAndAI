using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class ImmutableGovernanceReleaseBinding
{
    private ImmutableGovernanceReleaseBinding(
        ProtocolReleaseTag tag,
        ExactGitCommitId engineSourceCommit,
        ExactGitCommitId policySourceCommit,
        ExactSha256Digest catalogMetadataDigest,
        ExactSha256Digest portablePackageDigest)
    {
        Tag = tag;
        EngineSourceCommit = engineSourceCommit;
        PolicySourceCommit = policySourceCommit;
        CatalogMetadataDigest = catalogMetadataDigest;
        PortablePackageDigest = portablePackageDigest;
    }

    public ProtocolReleaseTag Tag { get; }

    public ExactGitCommitId EngineSourceCommit { get; }

    public ExactGitCommitId PolicySourceCommit { get; }

    public ExactSha256Digest CatalogMetadataDigest { get; }

    public ExactSha256Digest PortablePackageDigest { get; }

    internal static ImmutableGovernanceReleaseBinding Create(
        ProtocolReleaseTag tag,
        ExactGitCommitId engineSourceCommit,
        ExactGitCommitId policySourceCommit,
        ExactSha256Digest catalogMetadataDigest,
        ExactSha256Digest portablePackageDigest)
    {
        ArgumentNullException.ThrowIfNull(tag);
        ArgumentNullException.ThrowIfNull(engineSourceCommit);
        ArgumentNullException.ThrowIfNull(policySourceCommit);
        ArgumentNullException.ThrowIfNull(catalogMetadataDigest);
        ArgumentNullException.ThrowIfNull(portablePackageDigest);

        return new ImmutableGovernanceReleaseBinding(
            tag,
            engineSourceCommit,
            policySourceCommit,
            catalogMetadataDigest,
            portablePackageDigest);
    }
}
