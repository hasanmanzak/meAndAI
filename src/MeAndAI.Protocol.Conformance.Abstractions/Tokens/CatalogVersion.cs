using System.Globalization;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogVersion :
    IEquatable<CatalogVersion>,
    IComparable<CatalogVersion>
{
    private CatalogVersion(int value)
    {
        Value = value;
    }

    public int Value { get; }

    public static CatalogVersion Create(int value)
    {
        if (value <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "A catalog version must be positive.");
        }

        return new CatalogVersion(value);
    }

    public int CompareTo(CatalogVersion? other) =>
        other is null ? 1 : Value.CompareTo(other.Value);

    public bool Equals(CatalogVersion? other) =>
        other is not null && Value == other.Value;

    public override bool Equals(object? obj) => Equals(obj as CatalogVersion);

    public override int GetHashCode() => Value.GetHashCode();

    public override string ToString() =>
        Value.ToString(CultureInfo.InvariantCulture);
}
