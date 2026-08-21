using System.Reflection;
using MeAndAI.Operations.Application.ExecutionAuthority;
using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExecutionAuthorityPortTests
{
    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_execution_authority_ports_are_least_authority()
    {
        Assert.Equal(
            [typeof(IOperationalPort), typeof(IProviderReadPort)],
            typeof(IExecutionAuthorityReadPort).GetInterfaces()
                .OrderBy(static type => type.Name, StringComparer.Ordinal));
        Assert.Equal(
            [typeof(IOperationalPort), typeof(IProviderMutationPort)],
            typeof(IExecutionAuthorityMutationPort).GetInterfaces()
                .OrderBy(static type => type.Name, StringComparer.Ordinal));
        AssertMethods(typeof(IExecutionAuthorityReadPort),
        [
            ("ReadAuthoritySetAsync", typeof(ValueTask<ApprovalAuthoritySetSnapshot?>),
                new[] { typeof(AuthoritySetId), typeof(CancellationToken) }),
            ("ReadGrantStoreHeadAsync", typeof(ValueTask<AuthorityDigest?>),
                new[] { typeof(JournalStoreReference), typeof(CancellationToken) }),
            ("ReadExtensionActivationAsync", typeof(ValueTask<ExtensionActivationRecord?>),
                new[] { typeof(ExecutionTarget), typeof(CancellationToken) })
        ]);
        AssertMethods(typeof(IExecutionAuthorityMutationPort),
        [
            ("TryConsumeGrantAsync", typeof(ValueTask<ExecutionGrantDecision>),
                new[] { typeof(GrantConsumptionRequest), typeof(CancellationToken) }),
            ("TryActivateExtensionAsync", typeof(ValueTask<ActivationCasDecision>),
                new[] { typeof(ExtensionActivationMutationRequest), typeof(CancellationToken) })
        ]);
        Assert.DoesNotContain(typeof(IExecutionAuthorityReadPort).GetInterfaces(),
            static type => type == typeof(IProviderMutationPort));
        Assert.DoesNotContain(typeof(IExecutionAuthorityMutationPort).GetInterfaces(),
            static type => type == typeof(IProviderReadPort));
    }

    [Fact]
    [Trait("Subfeature", "SUBF-0145")]
    public void TEST_0212_authorizer_factory_rejects_null_ports_by_name()
    {
        StubPort port = new();
        Assert.Equal("readPort", Assert.Throws<ArgumentNullException>(() =>
            ExecutionGrantAuthorizer.Create(null!, port)).ParamName);
        Assert.Equal("mutationPort", Assert.Throws<ArgumentNullException>(() =>
            ExecutionGrantAuthorizer.Create(port, null!)).ParamName);
    }

    private static void AssertMethods(
        Type type,
        (string Name, Type ReturnType, Type[] Parameters)[] expected)
    {
        MethodInfo[] methods = type.GetMethods(
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly);
        Assert.Equal(expected.Length, methods.Length);
        foreach ((string name, Type returnType, Type[] parameters) in expected)
        {
            MethodInfo method = Assert.Single(methods,
                value => value.Name == name);
            Assert.Equal(returnType, method.ReturnType);
            Assert.Equal(parameters,
                method.GetParameters().Select(static value => value.ParameterType));
            Assert.Equal(parameters.Length == 2
                    ? new[] { name == "ReadAuthoritySetAsync" ? "id" :
                        name == "ReadGrantStoreHeadAsync" ? "store" :
                        name == "ReadExtensionActivationAsync" ? "repository" : "request",
                        "cancellationToken" }
                    : [],
                method.GetParameters().Select(static value => value.Name));
        }
    }

    private sealed class StubPort :
        IExecutionAuthorityReadPort, IExecutionAuthorityMutationPort
    {
        public ValueTask<ApprovalAuthoritySetSnapshot?> ReadAuthoritySetAsync(
            AuthoritySetId id, CancellationToken cancellationToken) =>
            ValueTask.FromResult<ApprovalAuthoritySetSnapshot?>(null);
        public ValueTask<AuthorityDigest?> ReadGrantStoreHeadAsync(
            JournalStoreReference store, CancellationToken cancellationToken) =>
            ValueTask.FromResult<AuthorityDigest?>(null);
        public ValueTask<ExtensionActivationRecord?> ReadExtensionActivationAsync(
            ExecutionTarget repository, CancellationToken cancellationToken) =>
            ValueTask.FromResult<ExtensionActivationRecord?>(null);
        public ValueTask<ExecutionGrantDecision> TryConsumeGrantAsync(
            GrantConsumptionRequest request, CancellationToken cancellationToken) =>
            ValueTask.FromResult(ExecutionGrantDecision.Rejected(
                ExecutionGrantRejection.GrantStoreDrift));
        public ValueTask<ActivationCasDecision> TryActivateExtensionAsync(
            ExtensionActivationMutationRequest request,
            CancellationToken cancellationToken) =>
            ValueTask.FromResult(ActivationCasDecision.Rejected(
                ExecutionGrantRejection.CasConflict));
    }
}
