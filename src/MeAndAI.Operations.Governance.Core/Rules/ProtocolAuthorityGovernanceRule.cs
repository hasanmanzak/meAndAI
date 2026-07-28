using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Rules;

public abstract class ProtocolAuthorityGovernanceRule : IGovernanceRule
{
    public abstract string RuleId { get; }

    public abstract string CanonicalScenarioId { get; }

    public abstract string FindingCode { get; }

    public abstract GovernanceSeverity Severity { get; }

    public abstract GovernanceEnforcement Enforcement { get; }

    public bool AppliesTo(GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);
        return profile == GovernanceProfileId.ProtocolAuthority;
    }

    public IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceProfileId profile,
        GovernanceAnalysisContext context)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(context);

        if (!AppliesTo(profile))
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "The rule does not apply to the selected profile.");
        }

        return Evaluate(context);
    }

    protected abstract IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context);
}
