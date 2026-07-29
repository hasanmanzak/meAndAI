using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class GovernanceEngine
{
    private readonly GovernanceRuleCatalog catalog;
    private readonly GovernanceReportFactory reportFactory;

    private GovernanceEngine(GovernanceRuleCatalog catalog)
    {
        this.catalog = catalog;
        reportFactory = new GovernanceReportFactory(catalog);
    }

    public static GovernanceEngine CreateDefault() =>
        new(GovernanceRuleCatalog.Current);

    internal void RequireCandidateProfile(GovernanceProfileId profile) =>
        CandidateGovernanceProfilePolicy.RequireEligible(profile);

    internal GovernanceReport EvaluateCandidateShadow(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(snapshot);

        if (!string.Equals(
                snapshot.Mode,
                "candidate",
                StringComparison.Ordinal))
        {
            throw new ArgumentException(
                "The internal shadow path accepts only a candidate snapshot.",
                nameof(snapshot));
        }

        RequireCandidateProfile(profile);

        return EvaluateCore(profile, snapshot);
    }

    private GovernanceReport EvaluateCore(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot)
    {
        var applicableRules = catalog.GetApplicableRules(profile);
        if (applicableRules.Length == 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "No rule catalog exists for the selected profile.");
        }

        var context = GovernanceAnalysisContext.Create(snapshot);
        var evaluations = applicableRules
            .Select(rule => new GovernanceRuleEvaluation(
                rule.Identity,
                rule.Evaluate(context)))
            .ToArray();

        return reportFactory.Create(
            profile,
            snapshot,
            evaluations);
    }
}
