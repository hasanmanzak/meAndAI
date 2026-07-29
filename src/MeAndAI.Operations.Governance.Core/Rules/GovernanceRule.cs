using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Rules;

public abstract class GovernanceRule : IGovernanceRule
{
    public abstract GovernanceCatalogRuleIdentity Identity { get; }

    public string RuleId => Identity.RuleId;

    public string CanonicalScenarioId => Identity.CanonicalScenarioId;

    public string FindingCode => Identity.FindingCode;

    public GovernanceSeverity Severity => Identity.Severity;

    public GovernanceEnforcement Enforcement => Identity.Enforcement;

    public abstract IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context);
}
