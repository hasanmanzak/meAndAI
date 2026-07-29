using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed record GovernanceRequirementKind
{
    public static GovernanceRequirementKind RepositoryFile { get; } =
        new("repository-file");

    public static GovernanceRequirementKind DocumentIdentity { get; } =
        new("document-identity");

    public static GovernanceRequirementKind MetadataField { get; } =
        new("metadata-field");

    public static GovernanceRequirementKind Section { get; } =
        new("section");

    private GovernanceRequirementKind(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}

public sealed record GovernanceRequirement
{
    public GovernanceRequirement(
        GovernanceRequirementKind kind,
        string name)
    {
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        Kind = kind;
        Name = name;
    }

    public GovernanceRequirementKind Kind { get; }

    public string Name { get; }
}

public sealed record GovernanceFindingEvidenceScope
{
    public static GovernanceFindingEvidenceScope ContentObject { get; } =
        new("content-object");

    public static GovernanceFindingEvidenceScope Snapshot { get; } =
        new("snapshot");

    private GovernanceFindingEvidenceScope(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public override string ToString() => Value;
}

public sealed class GovernanceFindingEvidence
{
    private GovernanceFindingEvidence(
        GovernanceFindingEvidenceScope scope,
        ExactSha256Digest digest)
    {
        Scope = scope;
        Digest = digest;
    }

    public GovernanceFindingEvidenceScope Scope { get; }

    public ExactSha256Digest Digest { get; }

    internal static GovernanceFindingEvidence FromContentObject(
        ExactSha256Digest digest)
    {
        ArgumentNullException.ThrowIfNull(digest);
        return new GovernanceFindingEvidence(
            GovernanceFindingEvidenceScope.ContentObject,
            digest);
    }

    internal static GovernanceFindingEvidence FromSnapshot(
        string digest) =>
        new(
            GovernanceFindingEvidenceScope.Snapshot,
            ExactSha256Digest.Parse(digest));
}

public sealed class GovernanceFindingLocation
{
    internal GovernanceFindingLocation(
        RepositoryRelativePath path,
        int? line,
        string? anchor)
    {
        ArgumentNullException.ThrowIfNull(path);
        if (line is <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(line),
                line,
                "A finding line must be positive when present.");
        }

        if (anchor is not null && !IsSafeAnchor(anchor))
        {
            throw new ArgumentException(
                "A finding anchor must be a non-empty lowercase ASCII anchor token.",
                nameof(anchor));
        }

        Path = path;
        Line = line;
        Anchor = anchor;
    }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public int? Line { get; }

    public string? Anchor { get; }

    private static bool IsSafeAnchor(string value) =>
        value.Length > 0 && value.All(character =>
            character is >= 'a' and <= 'z' or
                >= '0' and <= '9' or '-' or '_');
}

public sealed class GovernanceFinding
{
    internal GovernanceFinding(
        GovernanceCatalogRuleIdentity ruleIdentity,
        GovernanceFindingLocation location,
        GovernanceFindingEvidence evidence,
        IEnumerable<GovernanceRequirement> unsatisfiedRequirements)
    {
        ArgumentNullException.ThrowIfNull(ruleIdentity);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(evidence);
        ArgumentNullException.ThrowIfNull(unsatisfiedRequirements);

        var materializedRequirements = unsatisfiedRequirements.ToArray();
        if (materializedRequirements.Length == 0 ||
            materializedRequirements.Any(requirement => requirement is null) ||
            materializedRequirements.Distinct().Count() !=
                materializedRequirements.Length)
        {
            throw new ArgumentException(
                "A finding requires distinct non-null requirements.",
                nameof(unsatisfiedRequirements));
        }

        var orderedRequirements = materializedRequirements
            .OrderBy(
                requirement => requirement.Kind.Value,
                StringComparer.Ordinal)
            .ThenBy(
                requirement => requirement.Name,
                StringComparer.Ordinal)
            .ToArray();

        RuleIdentity = ruleIdentity;
        Location = location;
        Evidence = evidence;
        UnsatisfiedRequirements =
            new ReadOnlyCollection<GovernanceRequirement>(
                orderedRequirements);
    }

    public GovernanceCatalogRuleIdentity RuleIdentity { get; }

    public string RuleId => RuleIdentity.RuleId;

    public string CanonicalScenarioId => RuleIdentity.CanonicalScenarioId;

    public string CanonicalScenarioOwner =>
        RuleIdentity.CanonicalScenarioOwner;

    public string Code => RuleIdentity.FindingCode;

    public GovernanceSeverity Severity => RuleIdentity.Severity;

    public GovernanceEnforcement Enforcement => RuleIdentity.Enforcement;

    public GovernanceFindingLocation Location { get; }

    public RepositoryRelativePath Path => Location.Path;

    public string RelativePath => Location.RelativePath;

    public GovernanceFindingEvidence Evidence { get; }

    public IReadOnlyList<GovernanceRequirement> UnsatisfiedRequirements
    {
        get;
    }
}
