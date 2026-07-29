namespace MeAndAI.Operations.Governance.Core.Analysis;

internal static class ProtocolIntegrationPath
{
    internal const string Canonical = ".ai/protocol";

    internal static bool IsExactOrCaseVariant(string value)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value);
        return string.Equals(
            Normalize(value),
            Canonical,
            StringComparison.OrdinalIgnoreCase);
    }

    internal static bool CollidesWithReservedPath(string value)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value);
        var normalized = Normalize(value);
        return string.Equals(
                normalized,
                Canonical,
                StringComparison.OrdinalIgnoreCase) ||
            normalized.StartsWith(
                $"{Canonical}/",
                StringComparison.OrdinalIgnoreCase) ||
            Canonical.StartsWith(
                $"{normalized}/",
                StringComparison.OrdinalIgnoreCase);
    }

    private static string Normalize(string value) => value.Replace('\\', '/');
}
