namespace MeAndAI.Protocol.Conformance.Abstractions;

public interface IProtocolRecordIndex : IEvidenceCapability
{
    IReadOnlyList<ProtocolRecordView> Records { get; }
}
