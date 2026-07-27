using MeAndAI.Operations.Domain.Authority;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Application.Authority;

public static class OperationalAuthorityCatalog
{
    private static readonly Dictionary<
        OperationalApplicationId,
        OperationalApplicationDefinition> Definitions = CreateDefinitions();

    public static OperationalApplicationDefinition For(
        OperationalApplicationId application)
    {
        ArgumentNullException.ThrowIfNull(application);

        return Definitions.TryGetValue(application, out var definition)
            ? definition
            : throw new ArgumentOutOfRangeException(
                nameof(application),
                application,
                "Unknown operational application authority.");
    }

    private static Dictionary<
        OperationalApplicationId,
        OperationalApplicationDefinition> CreateDefinitions()
    {
        var readOnly = new[]
        {
            OperationalCapability.RepositoryRead,
            OperationalCapability.ProviderRead,
        };

        var repositoryMutation = new[]
        {
            OperationalCapability.RepositoryRead,
            OperationalCapability.RepositoryMutation,
            OperationalCapability.ProviderRead,
        };

        var providerMutation = new[]
        {
            OperationalCapability.RepositoryRead,
            OperationalCapability.ProviderRead,
            OperationalCapability.ProviderMutation,
        };

        var governance = OperationalApplicationDefinition.Create(
            OperationalApplicationId.Governance,
            OperationalAuthorityGrant.Create(
                OperationStageId.Validate,
                readOnly));

        var adoption = OperationalApplicationDefinition.Create(
            OperationalApplicationId.Adoption,
            OperationalAuthorityGrant.Create(OperationStageId.Discover, readOnly),
            OperationalAuthorityGrant.Create(OperationStageId.Assess, readOnly),
            OperationalAuthorityGrant.Create(OperationStageId.Plan, readOnly),
            OperationalAuthorityGrant.Create(
                OperationStageId.Apply,
                repositoryMutation),
            OperationalAuthorityGrant.Create(
                OperationStageId.Publish,
                providerMutation));

        var consumerUpdate = OperationalApplicationDefinition.Create(
            OperationalApplicationId.ConsumerUpdate,
            OperationalAuthorityGrant.Create(OperationStageId.Discover, readOnly),
            OperationalAuthorityGrant.Create(OperationStageId.Plan, readOnly),
            OperationalAuthorityGrant.Create(
                OperationStageId.Apply,
                repositoryMutation),
            OperationalAuthorityGrant.Create(
                OperationStageId.Publish,
                providerMutation),
            OperationalAuthorityGrant.Create(
                OperationStageId.Finalize,
                providerMutation));

        return new Dictionary<
            OperationalApplicationId,
            OperationalApplicationDefinition>
        {
            [governance.Application] = governance,
            [adoption.Application] = adoption,
            [consumerUpdate.Application] = consumerUpdate,
        };
    }
}
