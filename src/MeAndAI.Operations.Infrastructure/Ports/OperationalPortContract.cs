using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.Authority;

namespace MeAndAI.Operations.Infrastructure.Ports;

internal static class OperationalPortContract
{
    private static readonly (Type Marker, OperationalCapability Capability)[]
        KnownMarkers =
        [
            (typeof(IRepositoryReadPort), OperationalCapability.RepositoryRead),
            (typeof(IRepositoryMutationPort), OperationalCapability.RepositoryMutation),
            (typeof(IProviderReadPort), OperationalCapability.ProviderRead),
            (typeof(IProviderMutationPort), OperationalCapability.ProviderMutation),
        ];

    public static OperationalCapability GetRequiredCapability(Type contractType)
    {
        ArgumentNullException.ThrowIfNull(contractType);

        if (!contractType.IsInterface ||
            !typeof(IOperationalPort).IsAssignableFrom(contractType))
        {
            throw new ArgumentException(
                "An operational port contract must be an interface derived from one capability marker.",
                nameof(contractType));
        }

        if (KnownMarkers.Any(entry => entry.Marker == contractType))
        {
            throw new ArgumentException(
                "An operational port contract must derive from a capability marker rather than use the marker directly.",
                nameof(contractType));
        }

        var matches = KnownMarkers
            .Where(entry => entry.Marker.IsAssignableFrom(contractType))
            .Select(entry => entry.Capability)
            .ToArray();

        if (matches.Length != 1)
        {
            throw new ArgumentException(
                "An operational port contract must derive from exactly one capability marker.",
                nameof(contractType));
        }

        return matches[0];
    }

    public static void AssertImplementationMatches(
        Type implementationType,
        OperationalCapability requiredCapability)
    {
        ArgumentNullException.ThrowIfNull(implementationType);
        ArgumentNullException.ThrowIfNull(requiredCapability);

        var matches = KnownMarkers
            .Where(entry => entry.Marker.IsAssignableFrom(implementationType))
            .Select(entry => entry.Capability)
            .ToArray();

        if (matches.Length != 1 || matches[0] != requiredCapability)
        {
            throw new ArgumentException(
                "An operational port implementation must expose only its contract capability.",
                nameof(implementationType));
        }
    }
}
