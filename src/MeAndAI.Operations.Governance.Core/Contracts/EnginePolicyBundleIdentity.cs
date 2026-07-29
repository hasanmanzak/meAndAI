using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class EnginePolicyBundleIdentity
{
    private EnginePolicyBundleIdentity(
        ExactGitCommitId engineSourceCommit,
        ProtocolPolicyIdentity policy,
        ExactSha256Digest portablePackageDigest,
        ImmutableGovernanceReleaseBinding? releaseBinding)
    {
        EngineSourceCommit = engineSourceCommit;
        Policy = policy;
        PortablePackageDigest = portablePackageDigest;
        ReleaseBinding = releaseBinding;
    }

    public ExactGitCommitId EngineSourceCommit { get; }

    public ProtocolPolicyIdentity Policy { get; }

    public ExactSha256Digest PortablePackageDigest { get; }

    public ImmutableGovernanceReleaseBinding? ReleaseBinding { get; }

    public GovernanceEngineState EngineState => ReleaseBinding is null
        ? GovernanceEngineState.CSharpShadow
        : GovernanceEngineState.CSharpReleasedNonAuthoritative;

    public GovernanceAuthorityState AuthorityState =>
        GovernanceAuthorityState.PowerShellAuthority;

    internal static EnginePolicyBundleIdentity CreateUnreleased(
        ExactGitCommitId engineSourceCommit,
        ProtocolPolicyIdentity policy,
        ExactSha256Digest portablePackageDigest)
    {
        ValidateRequiredIdentities(
            engineSourceCommit,
            policy,
            portablePackageDigest);

        return new EnginePolicyBundleIdentity(
            engineSourceCommit,
            policy,
            portablePackageDigest,
            releaseBinding: null);
    }

    internal static EnginePolicyBundleIdentity CreateReleased(
        ExactGitCommitId engineSourceCommit,
        ProtocolPolicyIdentity policy,
        ExactSha256Digest portablePackageDigest,
        ImmutableGovernanceReleaseBinding releaseBinding)
    {
        ValidateRequiredIdentities(
            engineSourceCommit,
            policy,
            portablePackageDigest);
        ArgumentNullException.ThrowIfNull(releaseBinding);

        if (releaseBinding.Tag != BoundedGovernanceContract.ReleaseTag ||
            releaseBinding.Tag.Version != policy.Version ||
            releaseBinding.EngineSourceCommit != engineSourceCommit ||
            releaseBinding.PolicySourceCommit != policy.SourceCommit ||
            releaseBinding.CatalogMetadataDigest !=
                policy.Catalog.MetadataDigest ||
            releaseBinding.PortablePackageDigest != portablePackageDigest)
        {
            throw new ArgumentException(
                "The immutable governance release binding does not match the engine-policy bundle.",
                nameof(releaseBinding));
        }

        return new EnginePolicyBundleIdentity(
            engineSourceCommit,
            policy,
            portablePackageDigest,
            releaseBinding);
    }

    private static void ValidateRequiredIdentities(
        ExactGitCommitId engineSourceCommit,
        ProtocolPolicyIdentity policy,
        ExactSha256Digest portablePackageDigest)
    {
        ArgumentNullException.ThrowIfNull(engineSourceCommit);
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(portablePackageDigest);
    }
}
