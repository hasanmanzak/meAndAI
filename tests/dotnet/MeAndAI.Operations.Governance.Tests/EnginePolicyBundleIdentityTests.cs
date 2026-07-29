using System.Reflection;
using System.Security.Cryptography;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Protocol;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class EnginePolicyBundleIdentityTests
{
    private static readonly ExactGitCommitId EngineCommit =
        ExactGitCommitId.Parse(
            "0123456789abcdef0123456789abcdef01234567");

    private static readonly ExactGitCommitId PolicyCommit =
        ExactGitCommitId.Parse(
            "89abcdef0123456789abcdef0123456789abcdef");

    private static readonly ExactSha256Digest PackageDigest =
        PackageDigestFor([0x50, 0x4b, 0x03, 0x04]);

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void UnreleasedBundleDerivesShadowAndPowerShellAuthority()
    {
        var bundle = EnginePolicyBundleIdentity.CreateUnreleased(
            EngineCommit,
            Policy(),
            PackageDigest);

        Assert.Same(EngineCommit, bundle.EngineSourceCommit);
        Assert.Same(PackageDigest, bundle.PortablePackageDigest);
        Assert.Null(bundle.ReleaseBinding);
        Assert.Same(GovernanceEngineState.CSharpShadow, bundle.EngineState);
        Assert.Same(
            GovernanceAuthorityState.PowerShellAuthority,
            bundle.AuthorityState);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void MatchingImmutableReleaseRemainsNonAuthoritative()
    {
        var policy = Policy();
        var binding = Binding(
            "v0.17.0",
            EngineCommit,
            PolicyCommit,
            policy.Catalog.MetadataDigest,
            PackageDigest);

        var bundle = EnginePolicyBundleIdentity.CreateReleased(
            EngineCommit,
            policy,
            PackageDigest,
            binding);

        Assert.Same(binding, bundle.ReleaseBinding);
        Assert.Same(
            GovernanceEngineState.CSharpReleasedNonAuthoritative,
            bundle.EngineState);
        Assert.Same(
            GovernanceAuthorityState.PowerShellAuthority,
            bundle.AuthorityState);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void EveryReleaseBindingMismatchIsRejected()
    {
        var policy = Policy();
        var otherCommit = ExactGitCommitId.Parse(
            "fedcba9876543210fedcba9876543210fedcba98");
        var otherDigest = ExactSha256Digest.Parse(
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        var mismatches = new[]
        {
            Binding(
                "v0.17.1",
                EngineCommit,
                PolicyCommit,
                policy.Catalog.MetadataDigest,
                PackageDigest),
            Binding(
                "v0.17.0",
                otherCommit,
                PolicyCommit,
                policy.Catalog.MetadataDigest,
                PackageDigest),
            Binding(
                "v0.17.0",
                EngineCommit,
                otherCommit,
                policy.Catalog.MetadataDigest,
                PackageDigest),
            Binding(
                "v0.17.0",
                EngineCommit,
                PolicyCommit,
                otherDigest,
                PackageDigest),
            Binding(
                "v0.17.0",
                EngineCommit,
                PolicyCommit,
                policy.Catalog.MetadataDigest,
                otherDigest),
        };

        foreach (var mismatch in mismatches)
        {
            Assert.Throws<ArgumentException>(() =>
                EnginePolicyBundleIdentity.CreateReleased(
                    EngineCommit,
                    policy,
                    PackageDigest,
                    mismatch));
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ReleaseBindingIsAllOrNothingAndBundleHasOneNullableField()
    {
        var policy = Policy();
        var exactTag = ProtocolReleaseTag.Parse("v0.17.0");
        var catalogDigest = policy.Catalog.MetadataDigest;
        var nullArguments = new Action[]
        {
            () => ImmutableGovernanceReleaseBinding.Create(
                null!, EngineCommit, PolicyCommit, catalogDigest, PackageDigest),
            () => ImmutableGovernanceReleaseBinding.Create(
                exactTag, null!, PolicyCommit, catalogDigest, PackageDigest),
            () => ImmutableGovernanceReleaseBinding.Create(
                exactTag, EngineCommit, null!, catalogDigest, PackageDigest),
            () => ImmutableGovernanceReleaseBinding.Create(
                exactTag, EngineCommit, PolicyCommit, null!, PackageDigest),
            () => ImmutableGovernanceReleaseBinding.Create(
                exactTag, EngineCommit, PolicyCommit, catalogDigest, null!),
        };

        foreach (var action in nullArguments)
        {
            Assert.Throws<ArgumentNullException>(action);
        }

        Assert.Throws<ArgumentNullException>(() =>
            EnginePolicyBundleIdentity.CreateUnreleased(
                null!, policy, PackageDigest));
        Assert.Throws<ArgumentNullException>(() =>
            EnginePolicyBundleIdentity.CreateUnreleased(
                EngineCommit, null!, PackageDigest));
        Assert.Throws<ArgumentNullException>(() =>
            EnginePolicyBundleIdentity.CreateUnreleased(
                EngineCommit, policy, null!));
        Assert.Throws<ArgumentNullException>(() =>
            EnginePolicyBundleIdentity.CreateReleased(
                EngineCommit,
                policy,
                PackageDigest,
                null!));

        var nullability = new NullabilityInfoContext();
        Assert.Equal(
            ["ReleaseBinding"],
            typeof(EnginePolicyBundleIdentity)
                .GetProperties(BindingFlags.Public | BindingFlags.Instance)
                .Where(property =>
                    nullability.Create(property).ReadState ==
                    NullabilityState.Nullable)
                .Select(property => property.Name)
                .Order(StringComparer.Ordinal));
        Assert.Empty(typeof(EnginePolicyBundleIdentity).GetConstructors());
        Assert.Empty(typeof(ProtocolPolicyIdentity).GetConstructors());
        Assert.Empty(
            typeof(ImmutableGovernanceReleaseBinding).GetConstructors());
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void PortablePackageDigestBindsExactZipBytes()
    {
        var first = PackageDigestFor([0x50, 0x4b, 0x03, 0x04]);
        var second = PackageDigestFor([0x50, 0x4b, 0x03, 0x05]);

        Assert.NotEqual(first, second);
        Assert.Equal(PackageDigest, first);
    }

    private static ProtocolPolicyIdentity Policy() =>
        ProtocolPolicyIdentity.CreateBounded(
            ProtocolVersion.Parse("0.17.0"),
            PolicyCommit,
            GovernanceRuleCatalog.Current.Identity,
            InstructionGraphPolicyIdentity.Create(
                2,
                65536,
                4194304,
                512,
                4096,
                32,
                524288,
                4194304,
                32768));

    private static ImmutableGovernanceReleaseBinding Binding(
        string tag,
        ExactGitCommitId engineCommit,
        ExactGitCommitId policyCommit,
        ExactSha256Digest catalogDigest,
        ExactSha256Digest packageDigest) =>
        ImmutableGovernanceReleaseBinding.Create(
            ProtocolReleaseTag.Parse(tag),
            engineCommit,
            policyCommit,
            catalogDigest,
            packageDigest);

    private static ExactSha256Digest PackageDigestFor(byte[] bytes) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(bytes));
}
