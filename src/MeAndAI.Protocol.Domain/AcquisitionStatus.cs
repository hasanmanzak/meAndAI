using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionStatus : IEquatable<AcquisitionStatus>
{
    private const string CompleteToken = "complete";
    private const string IncompleteToken = "incomplete";
    private const string FailedToken = "failed";

    private AcquisitionStatus(string value)
    {
        Value = value;
    }

    public static AcquisitionStatus Complete { get; } = new(CompleteToken);

    public static AcquisitionStatus Incomplete { get; } = new(IncompleteToken);

    public static AcquisitionStatus Failed { get; } = new(FailedToken);

    public string Value { get; }

    public static AcquisitionStatus Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out AcquisitionStatus? result)
    {
        result = value switch
        {
            CompleteToken => Complete,
            IncompleteToken => Incomplete,
            FailedToken => Failed,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(AcquisitionStatus? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is AcquisitionStatus other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
