namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceScope : IEquatable<EvidenceScope>
{
    private EvidenceScope(
        AcquisitionTarget target,
        AcquisitionBoundary boundary)
    {
        Target = target;
        Boundary = boundary;
    }

    public AcquisitionTarget Target { get; }

    public AcquisitionBoundary Boundary { get; }

    public static EvidenceScope Create(
        AcquisitionTarget target,
        AcquisitionBoundary boundary)
    {
        ArgumentNullException.ThrowIfNull(target);
        ArgumentNullException.ThrowIfNull(boundary);

        if (!target.SnapshotKind.Equals(boundary.SnapshotKind))
        {
            throw new ArgumentException(
                "The target and boundary snapshot kinds must match.",
                nameof(boundary));
        }

        if (RequiresExactIdentity(target.SnapshotKind) &&
            !StringComparer.Ordinal.Equals(
                target.TargetIdentity,
                boundary.BoundaryIdentity))
        {
            throw new ArgumentException(
                "The target and boundary identities must match.",
                nameof(boundary));
        }

        return new EvidenceScope(target, boundary);
    }

    public bool Equals(EvidenceScope? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (Target.Equals(other.Target) &&
             Boundary.Equals(other.Boundary)));

    public override bool Equals(object? obj) =>
        obj is EvidenceScope other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(Target, Boundary);

    private static bool RequiresExactIdentity(SnapshotKind snapshotKind) =>
        snapshotKind.Equals(SnapshotKind.ExactCommit) ||
        snapshotKind.Equals(SnapshotKind.Candidate) ||
        snapshotKind.Equals(SnapshotKind.CapturedEvidence);
}
