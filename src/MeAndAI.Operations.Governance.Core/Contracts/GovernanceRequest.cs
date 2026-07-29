using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed record GovernanceRequest
{
    private GovernanceRequest(
        GovernanceProfileId profile,
        ExactGitCommitId subjectCommit)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(subjectCommit);

        Profile = profile;
        SubjectCommit = subjectCommit;
    }

    public GovernanceProfileId Profile { get; }

    public ExactGitCommitId SubjectCommit { get; }

    public RepositorySnapshotMode SnapshotMode =>
        RepositorySnapshotMode.ExactCommit;

    public EvidenceScope EvidenceScope => EvidenceScope.Repository;

    public static GovernanceRequest Create(
        GovernanceProfileId profile,
        ExactGitCommitId subjectCommit) =>
        new(profile, subjectCommit);
}
