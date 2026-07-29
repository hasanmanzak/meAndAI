using MeAndAI.Operations.Application.Ports;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal interface IGovernanceRepositorySnapshotPort : IRepositoryReadPort
{
    ValueTask<GovernanceRepositorySnapshot> CaptureCandidateAsync(
        CancellationToken cancellationToken);
}
