using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Authority;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Application.Authority;

public sealed class OperationalApplicationDefinition
{
    private OperationalApplicationDefinition(
        OperationalApplicationId application,
        OperationalAuthorityGrant[] grants)
    {
        Application = application;
        Grants = new ReadOnlyCollection<OperationalAuthorityGrant>(grants);
    }

    public OperationalApplicationId Application { get; }

    public IReadOnlyList<OperationalAuthorityGrant> Grants { get; }

    public static OperationalApplicationDefinition Create(
        OperationalApplicationId application,
        params OperationalAuthorityGrant[] grants)
    {
        ArgumentNullException.ThrowIfNull(application);
        ArgumentNullException.ThrowIfNull(grants);

        if (grants.Length == 0 || grants.Any(grant => grant is null))
        {
            throw new ArgumentException(
                "At least one non-null stage grant is required.",
                nameof(grants));
        }

        if (grants.Select(grant => grant.Stage).Distinct().Count() != grants.Length)
        {
            throw new ArgumentException(
                "An application cannot declare a stage more than once.",
                nameof(grants));
        }

        var ordered = grants
            .OrderBy(grant => grant.Stage.Value, StringComparer.Ordinal)
            .ToArray();

        return new OperationalApplicationDefinition(application, ordered);
    }

    public OperationalAuthorityGrant For(OperationStageId stage)
    {
        ArgumentNullException.ThrowIfNull(stage);

        return Grants.SingleOrDefault(grant => grant.Stage == stage)
            ?? throw new ArgumentOutOfRangeException(
                nameof(stage),
                stage,
                $"Application '{Application}' does not declare stage '{stage}'.");
    }
}
