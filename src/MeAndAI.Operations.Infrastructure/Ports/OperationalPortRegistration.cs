using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.Authority;

namespace MeAndAI.Operations.Infrastructure.Ports;

public sealed class OperationalPortRegistration
{
    private OperationalPortRegistration(
        Type contractType,
        IOperationalPort implementation,
        OperationalCapability capability)
    {
        ContractType = contractType;
        Implementation = implementation;
        Capability = capability;
    }

    internal Type ContractType { get; }

    internal IOperationalPort Implementation { get; }

    internal OperationalCapability Capability { get; }

    public static OperationalPortRegistration Create<TPort>(TPort implementation)
        where TPort : class, IOperationalPort
    {
        ArgumentNullException.ThrowIfNull(implementation);

        var contractType = typeof(TPort);
        var capability = OperationalPortContract.GetRequiredCapability(contractType);
        OperationalPortContract.AssertImplementationMatches(
            implementation.GetType(),
            capability);

        return new OperationalPortRegistration(
            contractType,
            implementation,
            capability);
    }
}
