using MeAndAI.Operations.Domain.Governance;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed record GovernanceCatalogRuleIdentity(
    string RuleId,
    string CanonicalScenarioId,
    string FindingCode,
    GovernanceSeverity Severity,
    GovernanceEnforcement Enforcement);
