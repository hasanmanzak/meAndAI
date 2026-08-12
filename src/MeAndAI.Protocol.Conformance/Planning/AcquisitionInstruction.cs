using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class AcquisitionInstruction
{
    private AcquisitionInstruction(
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        int roundOrdinal,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        ExactSha256Digest demandDigest,
        ExactSha256Digest instructionDigest)
    {
        Slot = slot;
        Target = target;
        RoundOrdinal = roundOrdinal;
        DemandItems = Array.AsReadOnly(demandItems.ToArray());
        DemandDigest = demandDigest;
        InstructionDigest = instructionDigest;
    }

    public EvidenceSlotDeclaration Slot { get; }

    public AcquisitionTarget Target { get; }

    public int RoundOrdinal { get; }

    public IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }

    public ExactSha256Digest DemandDigest { get; }

    public ExactSha256Digest InstructionDigest { get; }

    internal static AcquisitionInstruction CreateApplicability(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target)
    {
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(slot);
        ArgumentNullException.ThrowIfNull(target);

        var demandFrame = CreateDemandFrame();
        var demandDigest = Digest(demandFrame);
        var instructionFrame = CreateInstructionFrame(
            manifestDigest,
            slot,
            target,
            demandDigest);
        return new AcquisitionInstruction(
            slot,
            target,
            0,
            [],
            demandDigest,
            Digest(instructionFrame));
    }

    internal static AcquisitionInstruction CreateEvaluation(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        int roundOrdinal,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems) =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);

    private static byte[] CreateDemandFrame()
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-demand/1\n"));
        stream.WriteByte(0);
        WriteUInt32(stream, 0);
        return stream.ToArray();
    }

    private static byte[] CreateInstructionFrame(
        ExactSha256Digest manifestDigest,
        EvidenceSlotDeclaration slot,
        AcquisitionTarget target,
        ExactSha256Digest demandDigest)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-instruction/1\n"));
        stream.Write(Convert.FromHexString(manifestDigest.Value));
        stream.WriteByte(0);
        WriteUInt32(stream, 0);
        WriteText(stream, slot.SlotKey);
        WriteText(stream, target.SubjectIdentity);
        WriteText(stream, target.SourceIdentity);
        WriteText(stream, target.Surface.Value);
        WriteText(stream, target.SnapshotKind.Value);
        WriteText(stream, target.TargetIdentity);
        stream.Write(Convert.FromHexString(demandDigest.Value));
        return stream.ToArray();
    }

    private static void WriteText(Stream stream, string value)
    {
        var bytes = new UTF8Encoding(false, true).GetBytes(value);
        WriteUInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[sizeof(uint)];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static ExactSha256Digest Digest(byte[] frame) =>
        ExactSha256Digest.FromHashBytes(SHA256.HashData(frame));
}
