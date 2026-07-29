using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class ConformanceVerdict : IEquatable<ConformanceVerdict>
{
    private const string ConformingToken = "conforming";
    private const string NonConformingToken = "non-conforming";
    private const string IndeterminateToken = "indeterminate";

    private ConformanceVerdict(string value)
    {
        Value = value;
    }

    public static ConformanceVerdict Conforming { get; } =
        new(ConformingToken);

    public static ConformanceVerdict NonConforming { get; } =
        new(NonConformingToken);

    public static ConformanceVerdict Indeterminate { get; } =
        new(IndeterminateToken);

    public string Value { get; }

    public static ConformanceVerdict Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ConformanceVerdict? result)
    {
        result = value switch
        {
            ConformingToken => Conforming,
            NonConformingToken => NonConforming,
            IndeterminateToken => Indeterminate,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(ConformanceVerdict? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is ConformanceVerdict other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
