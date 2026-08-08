using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogPredecessorKind : IEquatable<CatalogPredecessorKind>
{
    private CatalogPredecessorKind(string value)
    {
        Value = value;
    }

    public static CatalogPredecessorKind Genesis { get; } = new("genesis");

    public static CatalogPredecessorKind Existing { get; } = new("existing");

    public string Value { get; }

    public static CatalogPredecessorKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical catalog predecessor kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CatalogPredecessorKind? result)
    {
        result = value switch
        {
            "genesis" => Genesis,
            "existing" => Existing,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(CatalogPredecessorKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as CatalogPredecessorKind);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
