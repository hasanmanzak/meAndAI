using System.Collections.ObjectModel;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed class GovernanceRuleCatalog
{
    private static readonly IGovernanceRule[] BoundedRules =
    [
        new DecisionRecordRequiredStructureRule(),
        new FeatureRecordRequiredPairRule(),
    ];

    public static GovernanceRuleCatalog Current { get; } = new(
        BoundedGovernanceContract.Version,
        BoundedRules);

    private readonly IGovernanceRule[] rules;

    private GovernanceRuleCatalog(
        ProtocolVersion version,
        IEnumerable<IGovernanceRule> rules)
    {
        ArgumentNullException.ThrowIfNull(version);
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

        Version = version;
        this.rules = materializedRules;
        Rules = new ReadOnlyCollection<IGovernanceRule>(this.rules);
        Identity = CreateBoundedIdentity(
            this.rules.Select(rule => rule.Identity));
    }

    public ProtocolVersion Version { get; }

    public IReadOnlyList<IGovernanceRule> Rules { get; }

    public GovernanceCatalogIdentity Identity { get; }

    internal IGovernanceRule[] GetApplicableRules(
        GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);

        if (profile != GovernanceProfileId.ProtocolAuthority &&
            profile != GovernanceProfileId.Consumer)
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "No rule catalog exists for the selected profile.");
        }

        return [.. rules];
    }

    internal static GovernanceCatalogRuleIdentity[]
        GetBoundedRuleIdentities() =>
        [.. BoundedRules.Select(rule => rule.Identity)];

    internal static GovernanceCatalogIdentity CreateBoundedIdentity(
        IEnumerable<GovernanceCatalogRuleIdentity> rules)
    {
        ArgumentNullException.ThrowIfNull(rules);

        var materializedRules = rules.ToArray();
        if (!materializedRules.SequenceEqual(GetBoundedRuleIdentities()))
        {
            throw new ArgumentException(
                "The governance catalog must match the exact bounded rule inventory and order.",
                nameof(rules));
        }

        var canonicalMetadata = string.Concat(
            materializedRules.Select(rule =>
                $"{rule.RuleId}\0{rule.CanonicalScenarioId}\0" +
                $"{rule.FindingCode}\0{rule.Severity.Value}\0" +
                $"{rule.Enforcement.Value}\n"));
        var canonicalMetadataBytes = Encoding.UTF8.GetBytes(canonicalMetadata);
        var metadataDigest = ExactSha256Digest.FromHashBytes(
            SHA256.HashData(canonicalMetadataBytes));

        return GovernanceCatalogIdentity.CreateFromCatalog(
            materializedRules,
            canonicalMetadataBytes,
            metadataDigest);
    }
}
