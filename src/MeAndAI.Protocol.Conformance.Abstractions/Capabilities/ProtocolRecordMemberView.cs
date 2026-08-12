namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ProtocolRecordMemberView
{
    private ProtocolRecordMemberView(
        string memberKey,
        int ordinal,
        QualifiedEvidenceHandle evidence)
    {
        MemberKey = memberKey;
        Ordinal = ordinal;
        Evidence = evidence;
    }

    public string MemberKey { get; }

    public int Ordinal { get; }

    public QualifiedEvidenceHandle Evidence { get; }

    internal static ProtocolRecordMemberView Create(
        string memberKey,
        int ordinal,
        QualifiedEvidenceHandle evidence)
    {
        ArgumentNullException.ThrowIfNull(memberKey);
        ArgumentNullException.ThrowIfNull(evidence);

        return new ProtocolRecordMemberView(memberKey, ordinal, evidence);
    }
}
