using MeAndAI.Operations.Application.Ports;

namespace MeAndAI.Operations.Governance.Core.Repository;

public interface IGovernanceRepositorySnapshotPort : IRepositoryReadPort
{
    ValueTask<GovernanceRepositorySnapshot> CaptureCandidateAsync(
        CancellationToken cancellationToken);
}
