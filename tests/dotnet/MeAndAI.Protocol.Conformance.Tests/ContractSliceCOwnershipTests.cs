using System.Reflection;
using System.Runtime.CompilerServices;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCOwnershipTests
{
    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Retains_exact_friend_project_and_policy_ownership_boundary()
    {
        var abstractions = typeof(IRuleEvaluator).Assembly;
        var conformance = typeof(ConformanceKernel).Assembly;
        var policy = Assembly.Load(new AssemblyName("MeAndAI.Protocol.Policy"));

        Assert.Equal(
            [
                "MeAndAI.Protocol.Conformance",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Policy",
            ],
            Friends(abstractions));
        Assert.Equal(
            ["MeAndAI.Protocol.Conformance.Tests"],
            Friends(conformance));
        Assert.Equal(
            ["MeAndAI.Protocol.Conformance.Tests"],
            Friends(policy));
        Assert.DoesNotContain(
            abstractions.GetReferencedAssemblies(),
            assembly => string.Equals(
                assembly.Name,
                "MeAndAI.Protocol.Policy",
                StringComparison.Ordinal));
        Assert.DoesNotContain(
            conformance.GetReferencedAssemblies(),
            assembly => string.Equals(
                assembly.Name,
                "MeAndAI.Protocol.Policy",
                StringComparison.Ordinal));
    }

    private static string[] Friends(Assembly assembly) =>
        assembly.GetCustomAttributes<InternalsVisibleToAttribute>()
            .Select(attribute => attribute.AssemblyName)
            .Order(StringComparer.Ordinal)
            .ToArray();
}
