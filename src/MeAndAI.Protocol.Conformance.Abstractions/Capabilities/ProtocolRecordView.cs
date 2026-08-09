namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ProtocolRecordView
{
    private ProtocolRecordView(
        string recordKind,
        string recordId,
        int ordinal,
        QualifiedEvidenceHandle evidence,
        IReadOnlyList<ProtocolRecordMemberView> members)
    {
        RecordKind = recordKind;
        RecordId = recordId;
        Ordinal = ordinal;
        Evidence = evidence;
        Members = members;
    }

    public string RecordKind { get; }

    public string RecordId { get; }

    public int Ordinal { get; }

    public QualifiedEvidenceHandle Evidence { get; }

    public IReadOnlyList<ProtocolRecordMemberView> Members { get; }

    internal static ProtocolRecordView Create(
        string recordKind,
        string recordId,
        int ordinal,
        QualifiedEvidenceHandle evidence,
        IEnumerable<ProtocolRecordMemberView> members)
    {
        ArgumentNullException.ThrowIfNull(recordKind);
        ArgumentNullException.ThrowIfNull(recordId);
        ArgumentNullException.ThrowIfNull(evidence);
        ArgumentNullException.ThrowIfNull(members);

        return new ProtocolRecordView(
            recordKind,
            recordId,
            ordinal,
            evidence,
            members.ToArray());
    }
}
