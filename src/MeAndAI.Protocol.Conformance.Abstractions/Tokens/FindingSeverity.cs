using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class FindingSeverity : IEquatable<FindingSeverity>
{
    private FindingSeverity(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static FindingSeverity Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical finding severity.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out FindingSeverity? result)
    {
        if (!ValueSyntax.IsNamespacedToken(value))
        {
            result = null;
            return false;
        }

        result = new FindingSeverity(value!);
        return true;
    }

    public bool Equals(FindingSeverity? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as FindingSeverity);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
