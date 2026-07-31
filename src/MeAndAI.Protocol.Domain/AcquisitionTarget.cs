namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionTarget : IEquatable<AcquisitionTarget>
{
    private AcquisitionTarget(
        string subjectIdentity,
        string sourceIdentity,
        SurfaceKind surface,
        SnapshotKind snapshotKind,
        string targetIdentity)
    {
        SubjectIdentity = subjectIdentity;
        SourceIdentity = sourceIdentity;
        Surface = surface;
        SnapshotKind = snapshotKind;
        TargetIdentity = targetIdentity;
    }

    public string SubjectIdentity { get; }

    public string SourceIdentity { get; }

    public SurfaceKind Surface { get; }

    public SnapshotKind SnapshotKind { get; }

    public string TargetIdentity { get; }

    public static AcquisitionTarget Create(
        string subjectIdentity,
        string sourceIdentity,
        SurfaceKind surface,
        SnapshotKind snapshotKind,
        string targetIdentity)
    {
        var validatedSubjectIdentity =
            EvidenceContractValidation.OpaqueIdentity(
                subjectIdentity,
                nameof(subjectIdentity));
        var validatedSourceIdentity =
            EvidenceContractValidation.OpaqueIdentity(
                sourceIdentity,
                nameof(sourceIdentity));
        ArgumentNullException.ThrowIfNull(surface);
        ArgumentNullException.ThrowIfNull(snapshotKind);
        var validatedTargetIdentity = EvidenceContractValidation.TargetIdentity(
            snapshotKind,
            targetIdentity,
            nameof(targetIdentity));

        return new AcquisitionTarget(
            validatedSubjectIdentity,
            validatedSourceIdentity,
            surface,
            snapshotKind,
            validatedTargetIdentity);
    }

    public bool Equals(AcquisitionTarget? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (StringComparer.Ordinal.Equals(
                 SubjectIdentity,
                 other.SubjectIdentity) &&
             StringComparer.Ordinal.Equals(
                 SourceIdentity,
                 other.SourceIdentity) &&
             Surface.Equals(other.Surface) &&
             SnapshotKind.Equals(other.SnapshotKind) &&
             StringComparer.Ordinal.Equals(
                 TargetIdentity,
                 other.TargetIdentity)));

    public override bool Equals(object? obj) =>
        obj is AcquisitionTarget other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        StringComparer.Ordinal.GetHashCode(SubjectIdentity),
        StringComparer.Ordinal.GetHashCode(SourceIdentity),
        Surface,
        SnapshotKind,
        StringComparer.Ordinal.GetHashCode(TargetIdentity));
}
