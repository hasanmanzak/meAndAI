using MeAndAI.Operations.Application.Ports;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal interface IExactGovernanceRepositorySnapshotPort : IRepositoryReadPort
{
    ValueTask<ExactGovernanceRepositoryCapture> CaptureSubjectAsync(
        GovernanceRequest request,
        CancellationToken cancellationToken);

    ValueTask<ExactIntegratedPolicyVersionCapture>
        CaptureIntegratedPolicyVersionAsync(
            ExactGitCommitId policyCommit,
            CancellationToken cancellationToken);
}
