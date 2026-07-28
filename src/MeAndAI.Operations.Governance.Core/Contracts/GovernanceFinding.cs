using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class GovernanceFinding
{
    public GovernanceFinding(
        string ruleId,
        string canonicalScenarioId,
        string code,
        GovernanceSeverity severity,
        GovernanceEnforcement enforcement,
        RepositoryRelativePath path,
        IEnumerable<string> missingFiles)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(ruleId);
        ArgumentException.ThrowIfNullOrWhiteSpace(canonicalScenarioId);
        ArgumentException.ThrowIfNullOrWhiteSpace(code);
        ArgumentNullException.ThrowIfNull(severity);
        ArgumentNullException.ThrowIfNull(enforcement);
        ArgumentNullException.ThrowIfNull(path);
        ArgumentNullException.ThrowIfNull(missingFiles);

        var orderedMissingFiles = missingFiles
            .Order(StringComparer.Ordinal)
            .ToArray();
        if (orderedMissingFiles.Length == 0 ||
            orderedMissingFiles.Any(string.IsNullOrWhiteSpace) ||
            orderedMissingFiles.Distinct(StringComparer.Ordinal).Count() !=
                orderedMissingFiles.Length)
        {
            throw new ArgumentException(
                "A finding requires distinct non-empty missing file roles.",
                nameof(missingFiles));
        }

        RuleId = ruleId;
        CanonicalScenarioId = canonicalScenarioId;
        Code = code;
        Severity = severity;
        Enforcement = enforcement;
        Path = path;
        MissingFiles = new ReadOnlyCollection<string>(orderedMissingFiles);
    }

    public string RuleId { get; }

    public string CanonicalScenarioId { get; }

    public string Code { get; }

    public GovernanceSeverity Severity { get; }

    public GovernanceEnforcement Enforcement { get; }

    public RepositoryRelativePath Path { get; }

    public string RelativePath => Path.Value;

    public IReadOnlyList<string> MissingFiles { get; }
}
