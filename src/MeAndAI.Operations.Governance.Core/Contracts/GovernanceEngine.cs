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

    public GovernanceReport Evaluate(
        GovernanceRequest request,
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(snapshot);

        var applicableRules = catalog.GetApplicableRules(request.Profile);
        if (applicableRules.Length == 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(request),
                request.Profile,
                "No rule catalog exists for the selected profile.");
        }

        var context = GovernanceAnalysisContext.Create(snapshot);
        var findings = applicableRules
            .SelectMany(rule => rule.Evaluate(request.Profile, context))
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
            request.Profile,
            snapshot.Mode,
            snapshot.EvidenceDigest,
            catalog.Version,
            catalog.ComputeMetadataDigest(applicableRules),
            applicableRules.Select(rule => rule.RuleId).ToArray(),
            verdict,
            new GovernanceCounts(
                applicableRules.Length,
                blockingCount,
                advisoryCount),
            findings);
    }
}
