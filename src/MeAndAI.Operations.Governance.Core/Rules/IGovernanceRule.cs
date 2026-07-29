using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Rules;

public interface IGovernanceRule
{
    GovernanceCatalogRuleIdentity Identity { get; }

    string RuleId { get; }

    string CanonicalScenarioId { get; }

    string FindingCode { get; }

    GovernanceSeverity Severity { get; }

    GovernanceEnforcement Enforcement { get; }

    IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceAnalysisContext context);
}
