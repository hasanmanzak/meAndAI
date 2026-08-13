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
            demandDigest,
            phase: 0,
            roundOrdinal: 0);
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
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems)
    {
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(slot);
        ArgumentNullException.ThrowIfNull(target);
        ArgumentNullException.ThrowIfNull(demandItems);
        if (roundOrdinal < 0)
        {
            Invalid();
        }

        var items = demandItems.ToArray();
        if (items.Any(item => item is null))
        {
            Invalid();
        }

        var demandFrame = items.Length == 0
            ? CreateDemandFrame()
            : CreateRepositoryTargetDemandFrame(slot, items);
        var demandDigest = Digest(demandFrame);
        var instructionFrame = CreateInstructionFrame(
            manifestDigest,
            slot,
            target,
            demandDigest,
            phase: 1,
            roundOrdinal);
        return new AcquisitionInstruction(
            slot,
            target,
            roundOrdinal,
            items,
            demandDigest,
            Digest(instructionFrame));
    }

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
        ExactSha256Digest demandDigest,
        byte phase,
        int roundOrdinal)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-instruction/1\n"));
        stream.Write(Convert.FromHexString(manifestDigest.Value));
        stream.WriteByte(phase);
        WriteUInt32(stream, checked((uint)roundOrdinal));
        WriteText(stream, slot.SlotKey);
        WriteText(stream, target.SubjectIdentity);
        WriteText(stream, target.SourceIdentity);
        WriteText(stream, target.Surface.Value);
        WriteText(stream, target.SnapshotKind.Value);
        WriteText(stream, target.TargetIdentity);
        stream.Write(Convert.FromHexString(demandDigest.Value));
        return stream.ToArray();
    }

    private static byte[] CreateRepositoryTargetDemandFrame(
        EvidenceSlotDeclaration slot,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> items)
    {
        if (!string.Equals(
                slot.SlotKey,
                "protocol.slot.repository-target-resolution",
                StringComparison.Ordinal) ||
            items.Select(item => item.OwningRepositoryIdentity)
                .Distinct(StringComparer.Ordinal).Count() != 1)
        {
            Invalid();
        }

        for (var index = 1; index < items.Count; index++)
        {
            if (items[index].ItemId != items[index - 1].ItemId + 1)
            {
                Invalid();
            }
        }

        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes("protocol.acquisition-demand/1\n"));
        stream.WriteByte(1);
        WriteUInt32(stream, checked((uint)items.Count));
        foreach (var item in items)
        {
            WriteUInt32(stream, checked((uint)item.ItemId));
            WriteText(stream, item.OwningRepositoryIdentity);
            WriteSelector(stream, item);
        }

        return stream.ToArray();
    }

    private static void WriteSelector(
        Stream stream,
        RepositoryTargetResolutionDemandItem item)
    {
        if (item.CommitObjectId is not null &&
            item.NormalizedTagName is null &&
            item.CapturedSnapshotIdentity is null)
        {
            stream.WriteByte(0);
            WriteText(stream, item.CommitObjectId);
            WriteOptionalText(stream, item.NormalizedRepositoryRelativePath);
            WriteOptionalText(stream, item.NormalizedFragment);
            return;
        }

        if (item.CommitObjectId is null &&
            item.NormalizedTagName is not null &&
            item.CapturedSnapshotIdentity is null &&
            item.NormalizedRepositoryRelativePath is null &&
            item.NormalizedFragment is null)
        {
            stream.WriteByte(1);
            WriteText(stream, item.NormalizedTagName);
            return;
        }

        if (item.CommitObjectId is null &&
            item.NormalizedTagName is null &&
            item.CapturedSnapshotIdentity is not null &&
            item.NormalizedRepositoryRelativePath is not null &&
            item.NormalizedFragment is not null)
        {
            stream.WriteByte(2);
            WriteText(stream, item.CapturedSnapshotIdentity);
            WriteText(stream, item.NormalizedRepositoryRelativePath);
            WriteText(stream, item.NormalizedFragment);
            return;
        }

        Invalid();
    }

    private static void WriteOptionalText(Stream stream, string? value)
    {
        stream.WriteByte(value is null ? (byte)0 : (byte)1);
        if (value is not null)
        {
            WriteText(stream, value);
        }
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

    private static void Invalid() =>
        throw new CatalogIntegrityException(CatalogIntegrityCode.PlanStateInvalid);
}
