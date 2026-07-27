using System.Collections.ObjectModel;
using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.Authority;

namespace MeAndAI.Operations.Infrastructure.Ports;

public sealed class OperationalPortScope
{
    private readonly OperationalAuthorityGrant authority;
    private readonly ReadOnlyDictionary<Type, IOperationalPort> ports;

    private OperationalPortScope(
        OperationalAuthorityGrant authority,
        Dictionary<Type, IOperationalPort> ports)
    {
        this.authority = authority;
        this.ports = new ReadOnlyDictionary<Type, IOperationalPort>(ports);
    }

    public static OperationalPortScope Create(
        OperationalAuthorityGrant authority,
        params OperationalPortRegistration[] registrations)
    {
        ArgumentNullException.ThrowIfNull(authority);
        ArgumentNullException.ThrowIfNull(registrations);

        var ports = new Dictionary<Type, IOperationalPort>();
        foreach (var registration in registrations)
        {
            if (registration is null)
            {
                throw new ArgumentException(
                    "Port registrations cannot contain null values.",
                    nameof(registrations));
            }

            if (!authority.Allows(registration.Capability))
            {
                throw new UnauthorizedAccessException(
                    $"Stage '{authority.Stage}' does not allow capability '{registration.Capability}'.");
            }

            if (!ports.TryAdd(
                    registration.ContractType,
                    registration.Implementation))
            {
                throw new ArgumentException(
                    $"Port contract '{registration.ContractType.FullName}' is duplicated.",
                    nameof(registrations));
            }
        }

        return new OperationalPortScope(authority, ports);
    }

    public TPort Require<TPort>()
        where TPort : class, IOperationalPort
    {
        var contractType = typeof(TPort);
        var capability = OperationalPortContract.GetRequiredCapability(contractType);

        if (!authority.Allows(capability))
        {
            throw new UnauthorizedAccessException(
                $"Stage '{authority.Stage}' does not allow capability '{capability}'.");
        }

        if (!ports.TryGetValue(contractType, out var implementation))
        {
            throw new InvalidOperationException(
                $"No implementation is registered for port contract '{contractType.FullName}'.");
        }

        return (TPort)implementation;
    }
}
