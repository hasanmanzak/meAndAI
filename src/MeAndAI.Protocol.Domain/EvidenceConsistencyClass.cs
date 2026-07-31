using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceConsistencyClass :
    IEquatable<EvidenceConsistencyClass>
{
    private const string ExactSnapshotToken = "exact-snapshot";
    private const string ObjectVersionBoundToken = "object-version-bound";
    private const string BoundedNonAtomicObservationToken =
        "bounded-non-atomic-observation";
    private const string InsufficientConsistencyToken =
        "insufficient-consistency";

    private EvidenceConsistencyClass(string value)
    {
        Value = value;
    }

    public static EvidenceConsistencyClass ExactSnapshot { get; } =
        new(ExactSnapshotToken);

    public static EvidenceConsistencyClass ObjectVersionBound { get; } =
        new(ObjectVersionBoundToken);

    public static EvidenceConsistencyClass BoundedNonAtomicObservation { get; } =
        new(BoundedNonAtomicObservationToken);

    public static EvidenceConsistencyClass InsufficientConsistency { get; } =
        new(InsufficientConsistencyToken);

    public string Value { get; }

    public static EvidenceConsistencyClass Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new FormatException(
                "The value is not a declared evidence consistency class.");
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out EvidenceConsistencyClass? result)
    {
        result = value switch
        {
            ExactSnapshotToken => ExactSnapshot,
            ObjectVersionBoundToken => ObjectVersionBound,
            BoundedNonAtomicObservationToken =>
                BoundedNonAtomicObservation,
            InsufficientConsistencyToken => InsufficientConsistency,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(EvidenceConsistencyClass? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is EvidenceConsistencyClass other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
