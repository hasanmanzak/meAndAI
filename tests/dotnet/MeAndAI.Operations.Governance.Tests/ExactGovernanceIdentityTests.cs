using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ExactGovernanceIdentityTests
{
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";

    private const string Digest =
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ClosedProfilesUseExactOrdinalValues()
    {
        Assert.Same(
            GovernanceProfileId.ProtocolAuthority,
            GovernanceProfileId.Parse("protocol-authority"));
        Assert.Same(
            GovernanceProfileId.Consumer,
            GovernanceProfileId.Parse("consumer"));
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData("Protocol-authority")]
    [InlineData("CONSUMER")]
    [InlineData(" consumer")]
    [InlineData("consumer ")]
    [InlineData("unknown")]
    public void UnknownOrNonOrdinalProfilesAreRejected(string value)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            GovernanceProfileId.Parse(value));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ExactCommitAndDigestAreAcceptedWithoutNormalization()
    {
        Assert.Equal(Commit, ExactGitCommitId.Parse(Commit).Value);
        Assert.Equal(Digest, ExactSha256Digest.Parse(Digest).Value);
        Assert.True(ExactGitCommitId.TryParse(Commit, out var commit));
        Assert.True(ExactSha256Digest.TryParse(Digest, out var digest));
        Assert.Equal(Commit, commit!.Value);
        Assert.Equal(Digest, digest!.Value);
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" 0123456789abcdef0123456789abcdef01234567")]
    [InlineData("0123456789abcdef0123456789abcdef01234567 ")]
    [InlineData("0123456789abcdef0123456789abcdef0123456")]
    [InlineData("0123456789abcdef0123456789abcdef012345678")]
    [InlineData("0123456789ABCDEF0123456789abcdef01234567")]
    [InlineData("0123456789abcdef0123456789abcdef0123456g")]
    [InlineData("0123456789abcdef0123456789abcdef0123456é")]
    public void NonExactCommitFormsAreRejected(string? value)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            ExactGitCommitId.Parse(value!));
        Assert.False(ExactGitCommitId.TryParse(value, out var parsed));
        Assert.Null(parsed);
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")]
    [InlineData("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef ")]
    [InlineData("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde")]
    [InlineData("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0")]
    [InlineData("0123456789ABCDEF0123456789abcdef0123456789abcdef0123456789abcdef")]
    [InlineData("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdeg")]
    [InlineData("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdeé")]
    public void NonExactDigestFormsAreRejected(string? value)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            ExactSha256Digest.Parse(value!));
        Assert.False(ExactSha256Digest.TryParse(value, out var parsed));
        Assert.Null(parsed);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void Sha256HashBytesRequireTheExactBinaryDigestLength()
    {
        Assert.Throws<ArgumentException>(() =>
            ExactSha256Digest.FromHashBytes(new byte[31]));
        Assert.Throws<ArgumentException>(() =>
            ExactSha256Digest.FromHashBytes(new byte[33]));
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData("0.0.0")]
    [InlineData("0.17.0")]
    [InlineData("12.345.6789")]
    public void CanonicalProtocolVersionsPreserveExactAsciiGrammar(string value)
    {
        Assert.Equal(value, ProtocolVersion.Parse(value).Value);
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" 0.17.0")]
    [InlineData("0.17.0 ")]
    [InlineData("v0.17.0")]
    [InlineData("0.17")]
    [InlineData("0.17.0.1")]
    [InlineData("00.17.0")]
    [InlineData("0.017.0")]
    [InlineData("0.17.00")]
    [InlineData("0.-1.0")]
    [InlineData("０.17.0")]
    public void NonCanonicalProtocolVersionsAreRejected(string? value)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            ProtocolVersion.Parse(value!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ReleaseTagDelegatesToTheSharedVersionIdentity()
    {
        var tag = ProtocolReleaseTag.Parse("v0.17.0");

        Assert.Equal("v0.17.0", tag.Value);
        Assert.Equal(ProtocolVersion.Parse("0.17.0"), tag.Version);
    }

    [Theory]
    [Trait("Scenario", "TEST-0194")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("0.17.0")]
    [InlineData("V0.17.0")]
    [InlineData("vv0.17.0")]
    [InlineData("v00.17.0")]
    [InlineData("v0.17.0 ")]
    public void NonCanonicalReleaseTagsAreRejected(string? value)
    {
        Assert.ThrowsAny<ArgumentException>(() =>
            ProtocolReleaseTag.Parse(value!));
    }
}
