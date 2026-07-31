namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionBoundary : IEquatable<AcquisitionBoundary>
{
    private AcquisitionBoundary(
        SnapshotKind snapshotKind,
        string boundaryIdentity,
        DateTimeOffset startedAtUtc,
        DateTimeOffset completedAtUtc)
    {
        SnapshotKind = snapshotKind;
        BoundaryIdentity = boundaryIdentity;
        StartedAtUtc = startedAtUtc;
        CompletedAtUtc = completedAtUtc;
    }

    public SnapshotKind SnapshotKind { get; }

    public string BoundaryIdentity { get; }

    public DateTimeOffset StartedAtUtc { get; }

    public DateTimeOffset CompletedAtUtc { get; }

    public static AcquisitionBoundary Create(
        SnapshotKind snapshotKind,
        string boundaryIdentity,
        DateTimeOffset startedAtUtc,
        DateTimeOffset completedAtUtc)
    {
        ArgumentNullException.ThrowIfNull(snapshotKind);
        var validatedBoundaryIdentity =
            EvidenceContractValidation.BoundaryIdentity(
                snapshotKind,
                boundaryIdentity,
                nameof(boundaryIdentity));
        EvidenceContractValidation.OrderedInterval(
            startedAtUtc,
            nameof(startedAtUtc),
            completedAtUtc,
            nameof(completedAtUtc));

        return new AcquisitionBoundary(
            snapshotKind,
            validatedBoundaryIdentity,
            startedAtUtc,
            completedAtUtc);
    }

    public bool Equals(AcquisitionBoundary? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (SnapshotKind.Equals(other.SnapshotKind) &&
             StringComparer.Ordinal.Equals(
                 BoundaryIdentity,
                 other.BoundaryIdentity) &&
             StartedAtUtc.Equals(other.StartedAtUtc) &&
             CompletedAtUtc.Equals(other.CompletedAtUtc)));

    public override bool Equals(object? obj) =>
        obj is AcquisitionBoundary other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        SnapshotKind,
        StringComparer.Ordinal.GetHashCode(BoundaryIdentity),
        StartedAtUtc,
        CompletedAtUtc);
}
