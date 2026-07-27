using MeAndAI.Operations.Application.Authority;
using MeAndAI.Operations.Domain.Authority;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class OperationalAuthorityCatalogTests
{
    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void GovernanceIsReadOnly()
    {
        var definition = OperationalAuthorityCatalog.For(
            OperationalApplicationId.Governance);

        var grant = definition.For(OperationStageId.Validate);

        Assert.True(grant.Allows(OperationalCapability.RepositoryRead));
        Assert.True(grant.Allows(OperationalCapability.ProviderRead));
        Assert.False(grant.Allows(OperationalCapability.RepositoryMutation));
        Assert.False(grant.Allows(OperationalCapability.ProviderMutation));
        Assert.Single(definition.Grants);
    }

    [Theory]
    [Trait("Scenario", "TEST-0191")]
    [MemberData(nameof(ReadOnlyStages))]
    public void DiscoveryAssessmentAndPlanningAreReadOnly(
        string applicationValue,
        string stageValue)
    {
        var grant = OperationalAuthorityCatalog
            .For(OperationalApplicationId.Parse(applicationValue))
            .For(OperationStageId.Parse(stageValue));

        Assert.False(grant.Allows(OperationalCapability.RepositoryMutation));
        Assert.False(grant.Allows(OperationalCapability.ProviderMutation));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void UnknownApplicationStageDoesNotWidenAuthority()
    {
        var governance = OperationalAuthorityCatalog.For(
            OperationalApplicationId.Governance);

        Assert.Throws<ArgumentOutOfRangeException>(() =>
            governance.For(OperationStageId.Publish));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void MutationStagesReceiveOnlyTheirDeclaredCapabilities()
    {
        var adoption = OperationalAuthorityCatalog.For(
            OperationalApplicationId.Adoption);
        var update = OperationalAuthorityCatalog.For(
            OperationalApplicationId.ConsumerUpdate);

        Assert.Equal(
            [
                OperationalCapability.RepositoryRead,
                OperationalCapability.RepositoryMutation,
                OperationalCapability.ProviderRead,
            ],
            adoption.For(OperationStageId.Apply).Capabilities);
        Assert.Equal(
            [
                OperationalCapability.RepositoryRead,
                OperationalCapability.ProviderRead,
                OperationalCapability.ProviderMutation,
            ],
            adoption.For(OperationStageId.Publish).Capabilities);
        Assert.Equal(
            adoption.For(OperationStageId.Publish).Capabilities,
            update.For(OperationStageId.Finalize).Capabilities);
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void ApplicationsDeclareOnlyTheirReviewedStages()
    {
        Assert.Equal(
            ["validate"],
            StageValues(OperationalApplicationId.Governance));
        Assert.Equal(
            ["apply", "assess", "discover", "plan", "publish"],
            StageValues(OperationalApplicationId.Adoption));
        Assert.Equal(
            ["apply", "discover", "finalize", "plan", "publish"],
            StageValues(OperationalApplicationId.ConsumerUpdate));
    }

    private static string[] StageValues(OperationalApplicationId application) =>
        [
            .. OperationalAuthorityCatalog
                .For(application)
                .Grants
                .Select(grant => grant.Stage.Value),
        ];

    public static TheoryData<string, string>
        ReadOnlyStages => new()
        {
            { "adoption", "discover" },
            { "adoption", "assess" },
            { "adoption", "plan" },
            { "consumer-update", "discover" },
            { "consumer-update", "plan" },
        };
}
