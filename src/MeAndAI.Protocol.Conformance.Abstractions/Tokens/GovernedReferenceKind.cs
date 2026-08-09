using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class GovernedReferenceKind : IEquatable<GovernedReferenceKind>
{
    private GovernedReferenceKind(string value)
    {
        Value = value;
    }

    public static GovernedReferenceKind CrossRecord { get; } =
        new("cross-record");

    public static GovernedReferenceKind EmbeddedRecord { get; } =
        new("embedded-record");

    public static GovernedReferenceKind Commit { get; } = new("commit");

    public string Value { get; }

    public static GovernedReferenceKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (!TryParse(value, out var result))
        {
            throw new FormatException(
                "The value is not a canonical governed reference kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out GovernedReferenceKind? result)
    {
        result = value switch
        {
            "cross-record" => CrossRecord,
            "embedded-record" => EmbeddedRecord,
            "commit" => Commit,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(GovernedReferenceKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as GovernedReferenceKind);

    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
