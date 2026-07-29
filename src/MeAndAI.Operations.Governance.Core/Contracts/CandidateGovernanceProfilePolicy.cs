using MeAndAI.Operations.Domain.Governance;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal static class CandidateGovernanceProfilePolicy
{
    internal static void RequireEligible(GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);

        if (profile != GovernanceProfileId.ProtocolAuthority)
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "The internal candidate shadow profile is not active.");
        }
    }
}
