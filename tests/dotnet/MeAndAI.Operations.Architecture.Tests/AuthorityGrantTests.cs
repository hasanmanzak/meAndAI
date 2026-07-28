using MeAndAI.Operations.Domain.Authority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class AuthorityGrantTests
{
    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void RepositoryMutationRequiresRepositoryRead()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            AuthorityGrant.Create(
                OperationalCapability.RepositoryMutation));

        Assert.Equal("capabilities", exception.ParamName);
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void ProviderMutationRequiresProviderRead()
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            AuthorityGrant.Create(
                OperationalCapability.ProviderMutation));

        Assert.Equal("capabilities", exception.ParamName);
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void CapabilitiesAreUniqueAndOrdinallyOrdered()
    {
        var grant = AuthorityGrant.Create(
            OperationalCapability.ProviderRead,
            OperationalCapability.RepositoryRead);

        Assert.Equal(
            [
                OperationalCapability.RepositoryRead,
                OperationalCapability.ProviderRead,
            ],
            grant.Capabilities);
        Assert.Throws<ArgumentException>(() =>
            AuthorityGrant.Create(
                OperationalCapability.RepositoryRead,
                OperationalCapability.RepositoryRead));
    }
}
