using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Domain;

public sealed class SnapshotKind : IEquatable<SnapshotKind>
{
    private const string ExactCommitToken = "exact-commit";
    private const string CandidateToken = "candidate";
    private const string ProviderEventToken = "provider-event";
    private const string ProviderFullInventoryToken =
        "provider-full-inventory";
    private const string CapturedEvidenceToken = "captured-evidence";

    private SnapshotKind(string value)
    {
        Value = value;
    }

    public static SnapshotKind ExactCommit { get; } = new(ExactCommitToken);

    public static SnapshotKind Candidate { get; } = new(CandidateToken);

    public static SnapshotKind ProviderEvent { get; } =
        new(ProviderEventToken);

    public static SnapshotKind ProviderFullInventory { get; } =
        new(ProviderFullInventoryToken);

    public static SnapshotKind CapturedEvidence { get; } =
        new(CapturedEvidenceToken);

    public string Value { get; }

    public static SnapshotKind Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);

        return TryParse(value, out var result)
            ? result
            : throw new ArgumentOutOfRangeException(nameof(value), value, null);
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out SnapshotKind? result)
    {
        result = value switch
        {
            ExactCommitToken => ExactCommit,
            CandidateToken => Candidate,
            ProviderEventToken => ProviderEvent,
            ProviderFullInventoryToken => ProviderFullInventory,
            CapturedEvidenceToken => CapturedEvidence,
            _ => null,
        };

        return result is not null;
    }

    public bool Equals(SnapshotKind? other) =>
        other is not null &&
        StringComparer.Ordinal.Equals(Value, other.Value);

    public override bool Equals(object? obj) =>
        obj is SnapshotKind other && Equals(other);

    public override int GetHashCode() =>
        StringComparer.Ordinal.GetHashCode(Value);

    public override string ToString() => Value;
}
