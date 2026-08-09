using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class RepositoryEntryKind : IEquatable<RepositoryEntryKind>
{
    private RepositoryEntryKind(string value)
    {
        Value = value;
    }

    public static RepositoryEntryKind Directory { get; } = new("directory");

    public static RepositoryEntryKind File { get; } = new("file");

    public static RepositoryEntryKind SymbolicLink { get; } =
        new("symbolic-link");

    public static RepositoryEntryKind GitLink { get; } = new("git-link");

    public string Value { get; }

    public static RepositoryEntryKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical repository entry kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out RepositoryEntryKind? result)
    {
        result = value switch
        {
            "directory" => Directory,
            "file" => File,
            "symbolic-link" => SymbolicLink,
            "git-link" => GitLink,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(RepositoryEntryKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as RepositoryEntryKind);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
