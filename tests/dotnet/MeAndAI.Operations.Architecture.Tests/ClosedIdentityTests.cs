using MeAndAI.Operations.Domain.Authority;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ClosedIdentityTests
{
    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void ApplicationIdentitiesAreExactAndOrdinal()
    {
        Assert.Same(
            OperationalApplicationId.Governance,
            OperationalApplicationId.Parse("governance"));
        Assert.Same(
            OperationalApplicationId.Adoption,
            OperationalApplicationId.Parse("adoption"));
        Assert.Same(
            OperationalApplicationId.ConsumerUpdate,
            OperationalApplicationId.Parse("consumer-update"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            OperationalApplicationId.Parse("Governance"));
        Assert.Throws<ArgumentNullException>(() =>
            OperationalApplicationId.Parse(null!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void StageIdentitiesRejectUnknownValues()
    {
        Assert.Same(OperationStageId.Validate, OperationStageId.Parse("validate"));
        Assert.Same(OperationStageId.Finalize, OperationStageId.Parse("finalize"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            OperationStageId.Parse("unknown"));
        Assert.Throws<ArgumentNullException>(() => OperationStageId.Parse(null!));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void CapabilityIdentitiesRejectUnknownValues()
    {
        Assert.Same(
            OperationalCapability.RepositoryRead,
            OperationalCapability.Parse("repository.read"));
        Assert.Same(
            OperationalCapability.ProviderMutation,
            OperationalCapability.Parse("provider.mutate"));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            OperationalCapability.Parse("provider.write"));
        Assert.Throws<ArgumentNullException>(() =>
            OperationalCapability.Parse(null!));
    }
}
