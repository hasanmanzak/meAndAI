namespace MeAndAI.Protocol.Domain;

public sealed class ExecutionProfile : IEquatable<ExecutionProfile>
{
    private ExecutionProfile(
        SubjectRole subjectRole,
        ProtocolOperation operation,
        SnapshotKind snapshotKind,
        SurfaceSet surfaces,
        EnforcementPhase enforcementPhase)
    {
        SubjectRole = subjectRole;
        Operation = operation;
        SnapshotKind = snapshotKind;
        Surfaces = surfaces;
        EnforcementPhase = enforcementPhase;
    }

    public SubjectRole SubjectRole { get; }

    public ProtocolOperation Operation { get; }

    public SnapshotKind SnapshotKind { get; }

    public SurfaceSet Surfaces { get; }

    public EnforcementPhase EnforcementPhase { get; }

    public static ExecutionProfile Create(
        SubjectRole subjectRole,
        ProtocolOperation operation,
        SnapshotKind snapshotKind,
        SurfaceSet surfaces,
        EnforcementPhase enforcementPhase)
    {
        ArgumentNullException.ThrowIfNull(subjectRole);
        ArgumentNullException.ThrowIfNull(operation);
        ArgumentNullException.ThrowIfNull(snapshotKind);
        ArgumentNullException.ThrowIfNull(surfaces);
        ArgumentNullException.ThrowIfNull(enforcementPhase);

        return new ExecutionProfile(
            subjectRole,
            operation,
            snapshotKind,
            surfaces,
            enforcementPhase);
    }

    public bool Equals(ExecutionProfile? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (SubjectRole.Equals(other.SubjectRole) &&
             Operation.Equals(other.Operation) &&
             SnapshotKind.Equals(other.SnapshotKind) &&
             Surfaces.Equals(other.Surfaces) &&
             EnforcementPhase.Equals(other.EnforcementPhase)));

    public override bool Equals(object? obj) =>
        obj is ExecutionProfile other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        SubjectRole,
        Operation,
        SnapshotKind,
        Surfaces,
        EnforcementPhase);
}
