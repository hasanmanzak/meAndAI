using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogAuthorityKind : IEquatable<CatalogAuthorityKind>
{
    private CatalogAuthorityKind(string value)
    {
        Value = value;
    }

    public static CatalogAuthorityKind QualificationSlice { get; } =
        new("qualification-slice");

    public static CatalogAuthorityKind CompleteProtocolSnapshot { get; } =
        new("complete-protocol-snapshot");

    public string Value { get; }

    public static CatalogAuthorityKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        if (!TryParse(value, out var result))
        {
            throw new FormatException("The value is not a canonical catalog authority kind.");
        }

        return result;
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out CatalogAuthorityKind? result)
    {
        result = value switch
        {
            "qualification-slice" => QualificationSlice,
            "complete-protocol-snapshot" => CompleteProtocolSnapshot,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(CatalogAuthorityKind? other) =>
        other is not null &&
        string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) =>
        Equals(obj as CatalogAuthorityKind);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
