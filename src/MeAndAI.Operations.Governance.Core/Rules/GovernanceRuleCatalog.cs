using System.Collections.ObjectModel;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Operations.Domain.Governance;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed class GovernanceRuleCatalog
{
    private const string CurrentVersion = "0.17.0-preview.1";

    public static GovernanceRuleCatalog Current { get; } = new(
        CurrentVersion,
        [
            new FeatureRecordRequiredPairRule(),
            new DecisionRecordRequiredStructureRule(),
        ]);

    private readonly IGovernanceRule[] rules;

    private GovernanceRuleCatalog(
        string version,
        IEnumerable<IGovernanceRule> rules)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(version);
        ArgumentNullException.ThrowIfNull(rules);

        var materializedRules = rules.ToArray();
        if (materializedRules.Length == 0 ||
            materializedRules.Any(rule => rule is null) ||
            materializedRules.Select(rule => rule.RuleId)
                .Distinct(StringComparer.Ordinal)
                .Count() != materializedRules.Length)
        {
            throw new ArgumentException(
                "A governance catalog requires distinct non-null rules.",
                nameof(rules));
        }

        var orderedRules = materializedRules
            .OrderBy(rule => rule.RuleId, StringComparer.Ordinal)
            .ToArray();

        Version = version;
        this.rules = orderedRules;
        Rules = new ReadOnlyCollection<IGovernanceRule>(this.rules);
    }

    public string Version { get; }

    public IReadOnlyList<IGovernanceRule> Rules { get; }

    internal IGovernanceRule[] GetApplicableRules(
        GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);

        return rules
            .Where(rule => rule.AppliesTo(profile))
            .ToArray();
    }

    internal string ComputeMetadataDigest(
        IEnumerable<IGovernanceRule> applicableRules)
    {
        ArgumentNullException.ThrowIfNull(applicableRules);

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
