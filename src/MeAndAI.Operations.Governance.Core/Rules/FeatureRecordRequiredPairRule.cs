using System.Text.RegularExpressions;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed partial class FeatureRecordRequiredPairRule : IGovernanceRule
{
    private static readonly string[] RequiredFiles =
        ["README.md", "test-cases.md"];

    public string RuleId => "protocol.feature-record.required-pair.v1";

    public string CanonicalScenarioId => "TEST-0004";

    public string FindingCode =>
        "governance.feature.record-set-incomplete";

    public GovernanceSeverity Severity => GovernanceSeverity.High;

    public GovernanceEnforcement Enforcement =>
        GovernanceEnforcement.Blocking;

    public bool AppliesTo(GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(profile);
        return profile == GovernanceProfileId.ProtocolAuthority;
    }

    public IReadOnlyList<GovernanceFinding> Evaluate(
        GovernanceProfileId profile,
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(profile);
        ArgumentNullException.ThrowIfNull(snapshot);

        if (!AppliesTo(profile))
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "The rule does not apply to the selected profile.");
        }

        var normalFiles = snapshot.Entries
            .Where(entry => entry.Kind == GovernanceRepositoryEntryKind.File)
            .Select(entry => entry.RelativePath)
            .ToHashSet(StringComparer.Ordinal);

        return
        [
            .. snapshot.Entries
                .Where(entry =>
                    entry.Kind == GovernanceRepositoryEntryKind.Directory &&
                    FeatureDirectoryPattern().IsMatch(entry.RelativePath))
                .OrderBy(entry => entry.RelativePath, StringComparer.Ordinal)
                .Select(entry => CreateFindingIfIncomplete(
                    entry.Path,
                    normalFiles))
                .Where(finding => finding is not null)
                .Select(finding => finding!),
        ];
    }

    private GovernanceFinding? CreateFindingIfIncomplete(
        RepositoryRelativePath featureDirectory,
        HashSet<string> normalFiles)
    {
        var missingFiles = RequiredFiles
            .Where(requiredFile => !normalFiles.Contains(
                $"{featureDirectory.Value}/{requiredFile}"))
            .ToArray();

        return missingFiles.Length == 0
            ? null
            : new GovernanceFinding(
                RuleId,
                CanonicalScenarioId,
                FindingCode,
                Severity,
                Enforcement,
                featureDirectory,
                missingFiles);
    }

    [GeneratedRegex(
        "^docs/features/FEAT-[0-9]{4}-[^/]+$",
        RegexOptions.CultureInvariant)]
    private static partial Regex FeatureDirectoryPattern();
}
