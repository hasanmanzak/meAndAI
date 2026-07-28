using System.Security.Cryptography;
using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class GovernanceEngine
{
    public const string PolicyCatalogVersion = "0.17.0-preview.1";

    private readonly IGovernanceRule[] rules;

    private GovernanceEngine(IGovernanceRule[] rules)
    {
        this.rules = rules;
    }

    public static GovernanceEngine CreateDefault() =>
        new([new FeatureRecordRequiredPairRule()]);

    public GovernanceReport Evaluate(
        GovernanceRequest request,
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(snapshot);

        var applicableRules = rules
            .Where(rule => rule.AppliesTo(request.Profile))
            .OrderBy(rule => rule.RuleId, StringComparer.Ordinal)
            .ToArray();
        if (applicableRules.Length == 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(request),
                request.Profile,
                "No rule catalog exists for the selected profile.");
        }

        var findings = applicableRules
            .SelectMany(rule => rule.Evaluate(request.Profile, snapshot))
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
            PolicyCatalogVersion,
            ComputeCatalogMetadataDigest(applicableRules),
            verdict,
            new GovernanceCounts(
                applicableRules.Length,
                blockingCount,
                advisoryCount),
            findings);
    }

    private static string ComputeCatalogMetadataDigest(
        IEnumerable<IGovernanceRule> applicableRules)
    {
        var canonicalCatalog = string.Concat(
            applicableRules.Select(rule =>
                $"{rule.RuleId}\0{rule.CanonicalScenarioId}\0" +
                $"{rule.FindingCode}\0{rule.Severity.Value}\0" +
                $"{rule.Enforcement.Value}\n"));
        return Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(canonicalCatalog)))
            .ToLowerInvariant();
    }
}
