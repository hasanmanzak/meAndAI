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

        if (!snapshot.IsCandidate)
        {
            throw new ArgumentException(
                "The internal shadow path accepts only a candidate snapshot.",
                nameof(snapshot));
        }

        RequireCandidateProfile(profile);

        return reportFactory.Create(
            profile,
            snapshot,
            EvaluateCore(profile, snapshot));
    }

    internal GovernanceReport EvaluateExactShadow(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot,
        ProtocolPolicyIdentity policy,
        GovernanceProfileEvidenceState profileEvidenceState)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(snapshot);
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(profileEvidenceState);

        if (!snapshot.IsExactCommit)
        {
            throw new ArgumentException(
                "The exact shadow path accepts only an exact-commit snapshot.",
                nameof(snapshot));
        }

        return reportFactory.CreateExact(
            profile,
            snapshot,
            policy,
            profileEvidenceState,
            EvaluateCore(profile, snapshot));
    }

    private GovernanceRuleEvaluation[] EvaluateCore(
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

        return evaluations;
    }
}
