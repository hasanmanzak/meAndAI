using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Declarations;
using MeAndAI.Protocol.Policy.Registration;

namespace MeAndAI.Protocol.Policy;

public static class InitialRuleQualificationPolicy
{
    public static PolicyQualificationSliceExport Export { get; } =
        InitialPolicyRegistrationGraph.Create(InitialPolicyDeclarations.Create());
}
