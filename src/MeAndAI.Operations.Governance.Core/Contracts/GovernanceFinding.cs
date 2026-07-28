using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Repository;

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

public sealed class GovernanceFinding
{
    public GovernanceFinding(
        string ruleId,
        string canonicalScenarioId,
        string code,
        GovernanceSeverity severity,
        GovernanceEnforcement enforcement,
        RepositoryRelativePath path,
        IEnumerable<GovernanceRequirement> unsatisfiedRequirements)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(ruleId);
        ArgumentException.ThrowIfNullOrWhiteSpace(canonicalScenarioId);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);
        ArgumentNullException.ThrowIfNull(severity);
        ArgumentNullException.ThrowIfNull(enforcement);
        ArgumentNullException.ThrowIfNull(path);
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

        RuleId = ruleId;
        CanonicalScenarioId = canonicalScenarioId;
        Code = code;
        Severity = severity;
        Enforcement = enforcement;
        Path = path;
        UnsatisfiedRequirements =
            new ReadOnlyCollection<GovernanceRequirement>(
                orderedRequirements);
    }

    public string RuleId { get; }

    public string CanonicalScenarioId { get; }

    public string Code { get; }

    public GovernanceSeverity Severity { get; }

    public GovernanceEnforcement Enforcement { get; }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public IReadOnlyList<GovernanceRequirement> UnsatisfiedRequirements
    {
        get;
    }
}
