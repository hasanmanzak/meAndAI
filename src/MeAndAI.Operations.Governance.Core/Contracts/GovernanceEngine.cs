using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class GovernanceEngine
{
    private readonly GovernanceRuleCatalog catalog;

    private GovernanceEngine(GovernanceRuleCatalog catalog)
    {
        this.catalog = catalog;
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
        var findings = applicableRules
            .SelectMany(rule => rule.Evaluate(context))
            .OrderBy(finding => finding.RelativePath, StringComparer.Ordinal)
            .ThenBy(finding => finding.Code, StringComparer.Ordinal)
            .ThenBy(finding => finding.RuleId, StringComparer.Ordinal)
            .ToArray();
        var blockingCount = findings.Count(finding =>
            finding.Enforcement == GovernanceEnforcement.Blocking);
        var advisoryCount = findings.Length - blockingCount;
        var verdict = blockingCount == 0
            ? GovernanceVerdict.Conforming
            : GovernanceVerdict.Nonconforming;

        return new GovernanceReport(
            profile,
            snapshot.Mode,
            snapshot.EvidenceDigest,
            catalog.Version.Value,
            catalog.Identity.MetadataDigest.Value,
            applicableRules.Select(rule => rule.RuleId).ToArray(),
            verdict,
            new GovernanceCounts(
                applicableRules.Length,
                blockingCount,
                advisoryCount),
            findings);
    }
}
