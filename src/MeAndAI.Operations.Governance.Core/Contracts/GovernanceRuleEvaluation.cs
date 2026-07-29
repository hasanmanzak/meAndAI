using System.Collections.ObjectModel;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal sealed class GovernanceRuleEvaluation
{
    internal GovernanceRuleEvaluation(
        GovernanceCatalogRuleIdentity ruleIdentity,
        IEnumerable<GovernanceFinding> findings)
    {
        ArgumentNullException.ThrowIfNull(ruleIdentity);
        ArgumentNullException.ThrowIfNull(findings);

        var materialized = findings.ToArray();
        if (materialized.Any(finding => finding is null))
        {
            throw new ArgumentException(
                "A rule evaluation cannot contain null findings.",
                nameof(findings));
        }

        RuleIdentity = ruleIdentity;
        Findings = new ReadOnlyCollection<GovernanceFinding>(materialized);
    }

    internal GovernanceCatalogRuleIdentity RuleIdentity { get; }

    internal IReadOnlyList<GovernanceFinding> Findings { get; }
}
