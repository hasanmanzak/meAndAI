namespace MeAndAI.Operations.Governance.Core.Repository;

public sealed record RepositoryRelativePath
{
    private RepositoryRelativePath(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static RepositoryRelativePath From(string value)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value);

        var normalized = value.Replace('\\', '/');
        if (normalized.StartsWith("/", StringComparison.Ordinal) ||
            IsDrivePrefixed(normalized) ||
            normalized.EndsWith("/", StringComparison.Ordinal) ||
            normalized.Any(char.IsControl))
        {
            throw new ArgumentException(
                "Repository paths must be safe repository-relative paths.",
                nameof(value));
        }

        var segments = normalized.Split('/');
        if (segments.Any(segment =>
                segment.Length == 0 ||
                string.Equals(segment, ".", StringComparison.Ordinal) ||
                string.Equals(segment, "..", StringComparison.Ordinal)))
        {
            throw new ArgumentException(
                "Repository paths must not contain empty or traversal segments.",
                nameof(value));
        }

        return new RepositoryRelativePath(normalized);
    }

    public override string ToString() => Value;

    private static bool IsDrivePrefixed(string path) =>
        path.Length >= 2 &&
        char.IsAsciiLetter(path[0]) &&
        path[1] == ':';
}
