using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.ExecutionAuthority;

namespace MeAndAI.Operations.Application.ExecutionAuthority;

public interface IExecutionAuthorityReadPort : IProviderReadPort
{
    ValueTask<ApprovalAuthoritySetSnapshot?> ReadAuthoritySetAsync(
        AuthoritySetId id, CancellationToken cancellationToken);
    ValueTask<AuthorityDigest?> ReadGrantStoreHeadAsync(
        JournalStoreReference store, CancellationToken cancellationToken);
    ValueTask<ExtensionActivationRecord?> ReadExtensionActivationAsync(
        ExecutionTarget repository, CancellationToken cancellationToken);
}

public interface IExecutionAuthorityMutationPort : IProviderMutationPort
{
    ValueTask<ExecutionGrantDecision> TryConsumeGrantAsync(
        GrantConsumptionRequest request, CancellationToken cancellationToken);
    ValueTask<ActivationCasDecision> TryActivateExtensionAsync(
        ExtensionActivationMutationRequest request,
        CancellationToken cancellationToken);
}
