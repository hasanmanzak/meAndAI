namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class QualifiedEvidenceHandle
{
    private QualifiedEvidenceHandle()
    {
    }

    internal static QualifiedEvidenceHandle Create() => new();
}
