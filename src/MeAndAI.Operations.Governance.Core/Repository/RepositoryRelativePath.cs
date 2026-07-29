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
        return CreateValidated(normalized, nameof(value));
    }

    internal static RepositoryRelativePath FromExactGit(string value)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value);
        if (value.Contains('\\', StringComparison.Ordinal))
        {
            throw new ArgumentException(
                "Exact Git paths cannot contain platform path separators.",
                nameof(value));
        }

        return CreateValidated(value, nameof(value));
    }

    private static RepositoryRelativePath CreateValidated(
        string value,
        string parameterName)
    {
        if (value.StartsWith("/", StringComparison.Ordinal) ||
            IsDrivePrefixed(value) ||
            value.EndsWith("/", StringComparison.Ordinal) ||
            value.Any(char.IsControl))
        {
            throw new ArgumentException(
                "Repository paths must be safe repository-relative paths.",
                parameterName);
        }

        var segments = value.Split('/');
        if (segments.Any(segment =>
                segment.Length == 0 ||
                string.Equals(segment, ".", StringComparison.Ordinal) ||
                string.Equals(segment, "..", StringComparison.Ordinal)))
        {
            throw new ArgumentException(
                "Repository paths must not contain empty or traversal segments.",
                parameterName);
        }

        return new RepositoryRelativePath(value);
    }

    public override string ToString() => Value;

    private static bool IsDrivePrefixed(string path) =>
        path.Length >= 2 &&
        char.IsAsciiLetter(path[0]) &&
        path[1] == ':';
}
