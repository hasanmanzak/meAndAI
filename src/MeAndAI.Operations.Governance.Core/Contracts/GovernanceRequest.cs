using MeAndAI.Operations.Domain.Governance;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed record GovernanceRequest
{
    public GovernanceRequest(GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);
        Profile = profile;
    }

    public GovernanceProfileId Profile { get; }
}
