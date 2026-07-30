using System.Globalization;

namespace MeAndAI.Protocol.Domain;

public sealed class RuleRevision :
    IEquatable<RuleRevision>,
    IComparable<RuleRevision>
{
    private RuleRevision(int value)
    {
        Value = value;
    }

    public int Value { get; }

    public static RuleRevision Create(int value)
    {
        if (value <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(value),
                value,
                "A rule revision must be positive.");
        }

        return new RuleRevision(value);
    }

    public int CompareTo(RuleRevision? other) =>
        other is null ? 1 : Value.CompareTo(other.Value);

    public bool Equals(RuleRevision? other) =>
        other is not null && Value == other.Value;

    public override bool Equals(object? obj) => Equals(obj as RuleRevision);

    public override int GetHashCode() => Value.GetHashCode();

    public override string ToString() =>
        Value.ToString(CultureInfo.InvariantCulture);
}
