namespace MeAndAI.Protocol.Domain;

public sealed class SnapshotEvidenceLocation : EvidenceLocation
{
    private SnapshotEvidenceLocation(EvidenceScope scope)
        : base(scope)
    {
    }

    public static SnapshotEvidenceLocation Create(EvidenceScope scope)
    {
        ArgumentNullException.ThrowIfNull(scope);
        return new SnapshotEvidenceLocation(scope);
    }
}
