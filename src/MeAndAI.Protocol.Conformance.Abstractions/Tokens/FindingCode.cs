using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class FindingCode : IEquatable<FindingCode>
{
    private FindingCode(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static FindingCode Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical finding code.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out FindingCode? result)
    {
        if (!ValueSyntax.IsNamespacedToken(value))
        {
            result = null;
            return false;
        }

        result = new FindingCode(value!);
        return true;
    }

    public bool Equals(FindingCode? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as FindingCode);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
