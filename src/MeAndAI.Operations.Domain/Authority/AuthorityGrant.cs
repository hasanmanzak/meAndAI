using System.Collections.ObjectModel;

namespace MeAndAI.Operations.Domain.Authority;

public sealed class AuthorityGrant
{
    private AuthorityGrant(OperationalCapability[] capabilities)
    {
        Capabilities = new ReadOnlyCollection<OperationalCapability>(capabilities);
    }

    public IReadOnlyList<OperationalCapability> Capabilities { get; }

    public static AuthorityGrant Create(
        params OperationalCapability[] capabilities)
    {
        ArgumentNullException.ThrowIfNull(capabilities);

        if (capabilities.Length == 0 || capabilities.Any(capability => capability is null))
        {
            throw new ArgumentException(
                "At least one non-null capability is required.",
                nameof(capabilities));
        }

        var unique = new HashSet<OperationalCapability>();
        foreach (var capability in capabilities)
        {
            if (!unique.Add(capability))
            {
                throw new ArgumentException(
                    $"Capability '{capability}' is duplicated.",
                    nameof(capabilities));
            }
        }

        RequireReadBeforeMutation(
            unique,
            OperationalCapability.RepositoryMutation,
            OperationalCapability.RepositoryRead,
            nameof(capabilities));
        RequireReadBeforeMutation(
            unique,
            OperationalCapability.ProviderMutation,
            OperationalCapability.ProviderRead,
            nameof(capabilities));

        return new AuthorityGrant(
            [.. unique.OrderBy(capability => capability.SortOrder)]);
    }

    public bool Allows(OperationalCapability capability)
    {
        ArgumentNullException.ThrowIfNull(capability);
        return Capabilities.Contains(capability);
    }

    private static void RequireReadBeforeMutation(
        HashSet<OperationalCapability> capabilities,
        OperationalCapability mutation,
        OperationalCapability read,
        string parameterName)
    {
        if (capabilities.Contains(mutation) && !capabilities.Contains(read))
        {
            throw new ArgumentException(
                $"Capability '{mutation}' requires '{read}'.",
                parameterName);
        }
    }
}
