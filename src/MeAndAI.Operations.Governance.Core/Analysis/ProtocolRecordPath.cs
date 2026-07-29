using System.Collections.ObjectModel;
using System.Text.RegularExpressions;

namespace MeAndAI.Operations.Governance.Core.Analysis;

internal static partial class ProtocolRecordPath
{
    private static readonly ReadOnlyCollection<string> RequiredFeatureFiles =
        Array.AsReadOnly(["README.md", "test-cases.md"]);

    internal static IReadOnlyList<string> RequiredFeatureFileNames =>
        RequiredFeatureFiles;

    internal static string? GetFeatureRecordId(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        var match = FeatureRecordPathPattern().Match(relativePath);
        return match.Success ? match.Groups["id"].Value : null;
    }

    internal static string? GetDecisionRecordId(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        var match = DecisionRecordPathPattern().Match(relativePath);
        return match.Success ? match.Groups["id"].Value : null;
    }

    internal static bool IsRequiredFeatureFile(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        var separator = relativePath.LastIndexOf('/');
        if (separator <= 0 || separator == relativePath.Length - 1)
        {
            return false;
        }

        var directory = relativePath[..separator];
        var fileName = relativePath[(separator + 1)..];
        return GetFeatureRecordId(directory) is not null &&
            RequiredFeatureFiles.Contains(fileName, StringComparer.Ordinal);
    }

    [GeneratedRegex(
        "^docs/features/(?<id>FEAT-[0-9]{4})-[^/]+$",
        RegexOptions.CultureInvariant)]
    private static partial Regex FeatureRecordPathPattern();

    [GeneratedRegex(
        "^docs/decisions/(?<id>DEC-[0-9]{4})-[^/]+\\.md$",
        RegexOptions.CultureInvariant)]
    private static partial Regex DecisionRecordPathPattern();
}
