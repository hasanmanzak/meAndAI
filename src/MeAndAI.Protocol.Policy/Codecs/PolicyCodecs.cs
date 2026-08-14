using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy.Models;

namespace MeAndAI.Protocol.Policy.Codecs;

internal sealed class GovernedTextCodec(
    PayloadSchemaDeclaration declaration,
    ModelTypeToken<SourceTextModel> outputModel) :
    PolicyCodec<SourceTextModel>(declaration, outputModel)
{
    protected override CanonicalEvidencePayload Encode(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken) =>
        input.Source.Accept(new GovernedTextWriter(cancellationToken));

    protected override SourceTextModel Decode(
        CodecQualificationInput input,
        CancellationToken cancellationToken)
    {
        var body = PolicyWire.DecodeGovernedText(input.Binding, cancellationToken);
        return new SourceTextModel(input.Binding, body);
    }

    protected override SemanticResourceLocalUsage Usage(SourceTextModel value) =>
        SemanticResourceLocalUsage.Create(
            value.Binding.Payload.CanonicalBytes.Count,
            1,
            1,
            value.Body.Length);

    private sealed class GovernedTextWriter(CancellationToken cancellationToken) :
        ICanonicalPayloadWriteSourceVisitor<CanonicalEvidencePayload>
    {
        public CanonicalEvidencePayload VisitGovernedText(
            EvidenceScope scope,
            EvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            ReadOnlyMemory<byte> body) =>
            PolicyWire.EncodeGovernedText(scope, location, body, cancellationToken);

        public CanonicalEvidencePayload VisitRepositoryTree(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTreePayloadEntry> entries) =>
            throw new InvalidDataException("The governed-text codec received a repository-tree source.");

        public CanonicalEvidencePayload VisitRepositoryTargetResolution(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
            IReadOnlyList<RepositoryTargetResolutionContent> contents) =>
            throw new InvalidDataException("The governed-text codec received a repository-target source.");
    }
}

internal sealed class RepositoryTreeCodec(
    PayloadSchemaDeclaration declaration,
    ModelTypeToken<RepositoryTreeModel> outputModel) :
    PolicyCodec<RepositoryTreeModel>(declaration, outputModel)
{
    protected override CanonicalEvidencePayload Encode(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken) =>
        input.Source.Accept(new RepositoryTreeWriter(cancellationToken));

    protected override RepositoryTreeModel Decode(
        CodecQualificationInput input,
        CancellationToken cancellationToken)
    {
        var entries = PolicyWire.DecodeRepositoryTree(input.Binding, cancellationToken);
        return new RepositoryTreeModel(input.Binding, entries);
    }

    protected override SemanticResourceLocalUsage Usage(RepositoryTreeModel value) =>
        SemanticResourceLocalUsage.Create(
            value.Binding.Payload.CanonicalBytes.Count,
            value.Entries.Count == 0 ? 0 : 1,
            value.Entries.Count,
            value.Entries.Sum(entry => entry.RepositoryRelativePath.Length));

    private sealed class RepositoryTreeWriter(CancellationToken cancellationToken) :
        ICanonicalPayloadWriteSourceVisitor<CanonicalEvidencePayload>
    {
        public CanonicalEvidencePayload VisitRepositoryTree(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTreePayloadEntry> entries) =>
            PolicyWire.EncodeRepositoryTree(scope, location, entries, cancellationToken);

        public CanonicalEvidencePayload VisitGovernedText(
            EvidenceScope scope,
            EvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            ReadOnlyMemory<byte> body) =>
            throw new InvalidDataException("The repository-tree codec received a governed-text source.");

        public CanonicalEvidencePayload VisitRepositoryTargetResolution(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
            IReadOnlyList<RepositoryTargetResolutionContent> contents) =>
            throw new InvalidDataException("The repository-tree codec received a repository-target source.");
    }
}

internal sealed class RepositoryTargetResolutionCodec(
    PayloadSchemaDeclaration declaration,
    ModelTypeToken<RepositoryTargetResolutionModel> outputModel) :
    PolicyCodec<RepositoryTargetResolutionModel>(declaration, outputModel)
{
    protected override CanonicalEvidencePayload Encode(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken) =>
        input.Source.Accept(new RepositoryTargetWriter(cancellationToken));

    protected override RepositoryTargetResolutionModel Decode(
        CodecQualificationInput input,
        CancellationToken cancellationToken)
    {
        var decoded = PolicyWire.DecodeRepositoryTarget(
            input.Binding,
            input.DemandDigest,
            input.DemandItems,
            cancellationToken);
        return new RepositoryTargetResolutionModel(
            input.Binding,
            decoded.DemandDigest,
            decoded.DemandItems,
            decoded.Rows,
            decoded.Contents);
    }

    protected override SemanticResourceLocalUsage Usage(
        RepositoryTargetResolutionModel value) =>
        SemanticResourceLocalUsage.Create(
            value.Binding.Payload.CanonicalBytes.Count,
            value.DemandItems.Count == 0 ? 0 : 1,
            value.DemandItems.Count + value.Rows.Count + value.Contents.Count,
            value.Contents.Sum(content => content.Bytes.Length));

    private sealed class RepositoryTargetWriter(CancellationToken cancellationToken) :
        ICanonicalPayloadWriteSourceVisitor<CanonicalEvidencePayload>
    {
        public CanonicalEvidencePayload VisitRepositoryTargetResolution(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
            IReadOnlyList<RepositoryTargetResolutionContent> contents) =>
            PolicyWire.EncodeRepositoryTarget(
                scope,
                location,
                demandDigest,
                rows,
                contents,
                cancellationToken);

        public CanonicalEvidencePayload VisitGovernedText(
            EvidenceScope scope,
            EvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            ReadOnlyMemory<byte> body) =>
            throw new InvalidDataException("The repository-target codec received a governed-text source.");

        public CanonicalEvidencePayload VisitRepositoryTree(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest instructionDigest,
            ExactSha256Digest demandDigest,
            IReadOnlyList<RepositoryTreePayloadEntry> entries) =>
            throw new InvalidDataException("The repository-target codec received a repository-tree source.");
    }
}

internal abstract class PolicyCodec<TModel> : ICanonicalPayloadCodec<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private readonly PayloadSchemaDeclaration _declaration;
    private readonly ModelTypeToken<TModel> _outputModel;

    protected PolicyCodec(
        PayloadSchemaDeclaration declaration,
        ModelTypeToken<TModel> outputModel)
    {
        _declaration = declaration ?? throw new ArgumentNullException(nameof(declaration));
        _outputModel = outputModel ?? throw new ArgumentNullException(nameof(outputModel));
    }

    public CanonicalPayloadWriteIntent Write(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        try
        {
            var payload = Encode(input, cancellationToken);
            if (payload.CanonicalBytes.Count > _declaration.Budget.MaxBytes)
            {
                return RejectWrite(input, "protocol.codec.resource-limit-exceeded");
            }

            return CanonicalPayloadWriteIntent.Written(
                CanonicalPayloadWriteProduct.Create(payload));
        }
        catch (DecoderFallbackException)
        {
            return RejectWrite(input, "protocol.codec.invalid-utf8");
        }
        catch (PolicyCodecFailureException exception)
        {
            return RejectWrite(input, exception.Code);
        }
        catch (OverflowException)
        {
            return RejectWrite(input, "protocol.codec.resource-limit-exceeded");
        }
        catch (Exception exception) when (
            exception is ArgumentException or InvalidDataException or
            InvalidOperationException)
        {
            return RejectWrite(input, InvalidCode);
        }
    }

    public CodecQualificationIntent<TModel> Qualify(
        CodecQualificationInput input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        if (!string.Equals(
                input.Binding.Payload.SchemaKey,
                _declaration.SchemaKey,
                StringComparison.Ordinal) ||
            !string.Equals(
                input.Binding.Payload.SchemaVersion,
                _declaration.SchemaVersion,
                StringComparison.Ordinal))
        {
            return RejectQualification(input, InvalidCode);
        }

        try
        {
            var model = Decode(input, cancellationToken);
            var usage = Usage(model);
            if (!input.ResourceAllowance.FitsLocal(usage))
            {
                return RejectQualification(
                    input,
                    "protocol.codec.resource-limit-exceeded");
            }

            return CodecQualificationIntent<TModel>.Qualified(
                CodecModelHandle<TModel>.Create(
                    _outputModel,
                    input.Binding,
                    _declaration.Codec,
                    input.InstructionDigest,
                    input.DemandDigest,
                    input.DemandItems,
                    model,
                    usage));
        }
        catch (DecoderFallbackException)
        {
            return RejectQualification(input, "protocol.codec.invalid-utf8");
        }
        catch (PolicyCodecFailureException exception)
        {
            return RejectQualification(input, exception.Code);
        }
        catch (OverflowException)
        {
            return RejectQualification(
                input,
                "protocol.codec.resource-limit-exceeded");
        }
        catch (Exception exception) when (
            exception is ArgumentException or InvalidDataException or
            InvalidOperationException)
        {
            return RejectQualification(input, InvalidCode);
        }
    }

    public SemanticResourceLocalUsage MeasureLocal(
        CodecQualificationInput input,
        TModel value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value);
    }

    protected abstract CanonicalEvidencePayload Encode(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken);

    protected abstract TModel Decode(
        CodecQualificationInput input,
        CancellationToken cancellationToken);

    protected abstract SemanticResourceLocalUsage Usage(TModel value);

    private string InvalidCode => _declaration.SchemaKey switch
    {
        "protocol.governed-text" => "protocol.codec.noncanonical-encoding",
        "protocol.repository-tree" => "protocol.codec.invalid-repository-tree",
        _ => "protocol.codec.invalid-repository-target-resolution",
    };

    private static CanonicalPayloadWriteIntent RejectWrite(
        CanonicalPayloadWriteInput input,
        string code) =>
        CanonicalPayloadWriteIntent.Rejected(
            [AcquisitionFailure.Create(input.Slot.Requirement.Key, code)]);

    private static CodecQualificationIntent<TModel> RejectQualification(
        CodecQualificationInput input,
        string code) =>
        CodecQualificationIntent<TModel>.Rejected(
            [AcquisitionFailure.Create(input.Binding.RequirementKeys[0], code)]);
}

internal static class PolicyWire
{
    private const int GovernedMaximumBytes = 4_194_304;
    private const int TreeMaximumBytes = 16_777_216;
    private const int TreeMaximumEntries = 200_000;
    private static readonly byte[] GovernedHeader =
        Encoding.ASCII.GetBytes("protocol.governed-text/1\n");
    private static readonly byte[] TreeHeader =
        Encoding.ASCII.GetBytes("protocol.repository-tree/1\n");
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    internal static CanonicalEvidencePayload EncodeGovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        cancellationToken.ThrowIfCancellationRequested();
        if (!scope.Equals(location.Scope))
        {
            throw new InvalidDataException("The location scope does not match.");
        }
        if (body.Length > GovernedMaximumBytes)
        {
            throw new OverflowException("The governed body exceeds its limit.");
        }
        _ = StrictUtf8.GetCharCount(body.Span);
        if (body.Span.StartsWith(new byte[] { 0xEF, 0xBB, 0xBF }))
        {
            throw new InvalidDataException("UTF-8 BOM is not canonical.");
        }

        using var stream = new MemoryStream();
        stream.Write(GovernedHeader);
        WriteScope(stream, scope);
        switch (location)
        {
            case RepositoryEvidenceLocation repository
                when scope.Target.Surface.Equals(SurfaceKind.Repository) &&
                     repository.Line is null && repository.Anchor is null &&
                     repository.Property is null:
                stream.WriteByte(0);
                WriteText(stream, repository.RepositoryRelativePath);
                WriteOptionalText(stream, repository.BlobIdentity);
                WriteOptionalInt32(stream, null);
                WriteOptionalText(stream, null);
                WriteOptionalText(stream, null);
                break;
            case ProviderEvidenceLocation provider
                when scope.Target.Surface.Equals(SurfaceKind.Provider) &&
                     provider.Field is not null && provider.Line is null &&
                     provider.Fragment is null:
                stream.WriteByte(1);
                WriteText(stream, provider.ProviderServiceIdentity);
                WriteText(stream, provider.ObjectType);
                WriteText(stream, provider.StableObjectIdentity);
                WriteText(stream, provider.VersionIdentity);
                WriteOptionalText(stream, provider.Field);
                WriteOptionalInt32(stream, null);
                WriteOptionalText(stream, null);
                break;
            default:
                throw new InvalidDataException("The governed-text location is invalid.");
        }
        WriteUInt32(stream, checked((uint)body.Length));
        stream.Write(body.Span);
        if (stream.Length > GovernedMaximumBytes)
        {
            throw new OverflowException("The governed payload exceeds its limit.");
        }
        return CanonicalEvidencePayload.Create("protocol.governed-text", "1", stream.ToArray());
    }

    internal static byte[] DecodeGovernedText(
        EvidenceBinding binding,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        cancellationToken.ThrowIfCancellationRequested();
        var reader = new WireReader(binding.Payload.CanonicalBytes);
        reader.Expect(GovernedHeader);
        var scope = reader.Scope();
        var rank = reader.Byte();
        EvidenceLocation location = rank switch
        {
            0 => RepositoryEvidenceLocation.Create(
                scope,
                reader.Text(),
                reader.OptionalText(),
                reader.OptionalInt32(),
                reader.OptionalText(),
                reader.OptionalText()),
            1 => ProviderEvidenceLocation.Create(
                scope,
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.OptionalText(),
                reader.OptionalInt32(),
                reader.OptionalText()),
            _ => throw new InvalidDataException("The governed location rank is invalid."),
        };
        var body = reader.Bytes();
        reader.RequireEnd();
        _ = StrictUtf8.GetCharCount(body);
        if (!location.Equals(binding.Location))
        {
            throw new InvalidDataException("The embedded governed location differs from the binding.");
        }
        return body;
    }

    internal static CanonicalEvidencePayload EncodeRepositoryTree(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        IReadOnlyList<RepositoryTreePayloadEntry> entries,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(entries);
        cancellationToken.ThrowIfCancellationRequested();
        if (!scope.Target.Surface.Equals(SurfaceKind.Repository) ||
            !scope.Equals(location.Scope) || entries.Count > TreeMaximumEntries)
        {
            throw new InvalidDataException("The repository-tree source is invalid.");
        }

        using var stream = new MemoryStream();
        stream.Write(TreeHeader);
        WriteScope(stream, scope);
        stream.WriteByte(3);
        WriteUInt32(stream, checked((uint)entries.Count));
        string? previous = null;
        foreach (var entry in entries)
        {
            ArgumentNullException.ThrowIfNull(entry);
            if (!ValidPath(entry.RepositoryRelativePath) ||
                previous is not null &&
                StringComparer.Ordinal.Compare(previous, entry.RepositoryRelativePath) >= 0)
            {
                throw new InvalidDataException("Repository-tree paths are not canonical.");
            }
            WriteText(stream, entry.RepositoryRelativePath);
            stream.WriteByte(KindByte(entry.Kind));
            previous = entry.RepositoryRelativePath;
        }
        if (stream.Length > TreeMaximumBytes)
        {
            throw new OverflowException("The repository-tree payload exceeds its limit.");
        }
        return CanonicalEvidencePayload.Create("protocol.repository-tree", "1", stream.ToArray());
    }

    internal static IReadOnlyList<RepositoryTreePayloadEntry> DecodeRepositoryTree(
        EvidenceBinding binding,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        cancellationToken.ThrowIfCancellationRequested();
        var reader = new WireReader(binding.Payload.CanonicalBytes);
        reader.Expect(TreeHeader);
        var scope = reader.Scope();
        if (reader.Byte() != 3 || binding.Location is not SnapshotEvidenceLocation outer ||
            !scope.Equals(outer.Scope))
        {
            throw new InvalidDataException("The repository-tree location is invalid.");
        }
        var count = reader.UInt32();
        if (count > TreeMaximumEntries)
        {
            throw new OverflowException("The repository-tree entry count exceeds its limit.");
        }
        var values = new RepositoryTreePayloadEntry[checked((int)count)];
        string? previous = null;
        for (var index = 0; index < values.Length; index++)
        {
            var path = reader.Text();
            if (!ValidPath(path) || previous is not null &&
                StringComparer.Ordinal.Compare(previous, path) >= 0)
            {
                throw new InvalidDataException("Repository-tree paths are not canonical.");
            }
            values[index] = RepositoryTreePayloadEntry.Create(path, Kind(reader.Byte()));
            previous = path;
        }
        reader.RequireEnd();
        return Array.AsReadOnly(values);
    }

    internal static CanonicalEvidencePayload EncodeRepositoryTarget(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents,
        CancellationToken cancellationToken) =>
        RepositoryTargetWire.Encode(
            scope,
            location,
            demandDigest,
            rows,
            contents,
            cancellationToken);

    internal static RepositoryTargetWire.Decoded DecodeRepositoryTarget(
        EvidenceBinding binding,
        ExactSha256Digest expectedDemandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> expectedDemandItems,
        CancellationToken cancellationToken) =>
        RepositoryTargetWire.Decode(
            binding,
            expectedDemandDigest,
            expectedDemandItems,
            cancellationToken);

    private static void WriteScope(Stream stream, EvidenceScope scope)
    {
        WriteText(stream, scope.Target.SubjectIdentity);
        WriteText(stream, scope.Target.SourceIdentity);
        WriteText(stream, scope.Target.Surface.Value);
        WriteText(stream, scope.Target.SnapshotKind.Value);
        WriteText(stream, scope.Target.TargetIdentity);
        WriteText(stream, scope.Boundary.SnapshotKind.Value);
        WriteText(stream, scope.Boundary.BoundaryIdentity);
        WriteInt64(stream, scope.Boundary.StartedAtUtc.UtcTicks);
        WriteInt64(stream, scope.Boundary.CompletedAtUtc.UtcTicks);
    }

    private static void WriteText(Stream stream, string value)
    {
        if (value.StartsWith('\uFEFF'))
        {
            throw new InvalidDataException("UTF-8 BOM is not canonical.");
        }
        var bytes = StrictUtf8.GetBytes(value);
        WriteUInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    private static void WriteOptionalText(Stream stream, string? value)
    {
        stream.WriteByte(value is null ? (byte)0 : (byte)1);
        if (value is not null)
        {
            WriteText(stream, value);
        }
    }

    private static void WriteOptionalInt32(Stream stream, int? value)
    {
        stream.WriteByte(value.HasValue ? (byte)1 : (byte)0);
        if (value.HasValue)
        {
            Span<byte> bytes = stackalloc byte[4];
            BinaryPrimitives.WriteInt32BigEndian(bytes, value.Value);
            stream.Write(bytes);
        }
    }

    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static void WriteInt64(Stream stream, long value)
    {
        Span<byte> bytes = stackalloc byte[8];
        BinaryPrimitives.WriteInt64BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static bool ValidPath(string path) =>
        path.Length > 0 && path[0] != '/' && path[^1] != '/' &&
        !path.Contains('\\', StringComparison.Ordinal) &&
        !(path.Length >= 2 && char.IsAsciiLetter(path[0]) && path[1] == ':') &&
        path.Split('/').All(segment => segment.Length > 0 && segment is not "." and not "..");

    private static byte KindByte(RepositoryEntryKind kind) => kind.Value switch
    {
        "directory" => 0,
        "file" => 1,
        "symbolic-link" => 2,
        "git-link" => 3,
        _ => throw new InvalidDataException("The repository entry kind is invalid."),
    };

    private static RepositoryEntryKind Kind(byte value) => value switch
    {
        0 => RepositoryEntryKind.Directory,
        1 => RepositoryEntryKind.File,
        2 => RepositoryEntryKind.SymbolicLink,
        3 => RepositoryEntryKind.GitLink,
        _ => throw new InvalidDataException("The repository entry kind is invalid."),
    };

    private ref struct WireReader
    {
        private readonly ReadOnlySpan<byte> _bytes;
        private int _offset;

        internal WireReader(IReadOnlyList<byte> bytes)
        {
            _bytes = bytes.ToArray();
            _offset = 0;
        }

        internal void Expect(ReadOnlySpan<byte> expected)
        {
            if (!Read(expected.Length).SequenceEqual(expected))
            {
                throw new InvalidDataException("The canonical header is invalid.");
            }
        }

        internal EvidenceScope Scope()
        {
            var target = AcquisitionTarget.Create(
                Text(),
                Text(),
                ParseSurface(Text()),
                ParseSnapshot(Text()),
                Text());
            var boundary = AcquisitionBoundary.Create(
                ParseSnapshot(Text()),
                Text(),
                new DateTimeOffset(Int64(), TimeSpan.Zero),
                new DateTimeOffset(Int64(), TimeSpan.Zero));
            return EvidenceScope.Create(target, boundary);
        }

        internal string Text()
        {
            var value = StrictUtf8.GetString(Bytes());
            return value.StartsWith('\uFEFF')
                ? throw new InvalidDataException("UTF-8 BOM is not canonical.")
                : value;
        }

        internal string? OptionalText() => Byte() switch
        {
            0 => null,
            1 => Text(),
            _ => throw new InvalidDataException("The optional-text tag is invalid."),
        };

        internal int? OptionalInt32() => Byte() switch
        {
            0 => null,
            1 => BinaryPrimitives.ReadInt32BigEndian(Read(4)),
            _ => throw new InvalidDataException("The optional-integer tag is invalid."),
        };

        internal byte[] Bytes()
        {
            var length = UInt32();
            return Read(checked((int)length)).ToArray();
        }

        internal uint UInt32() => BinaryPrimitives.ReadUInt32BigEndian(Read(4));
        internal long Int64() => BinaryPrimitives.ReadInt64BigEndian(Read(8));
        internal byte Byte() => Read(1)[0];

        internal void RequireEnd()
        {
            if (_offset != _bytes.Length)
            {
                throw new InvalidDataException("Trailing canonical bytes are forbidden.");
            }
        }

        private ReadOnlySpan<byte> Read(int count)
        {
            if (count < 0 || count > _bytes.Length - _offset)
            {
                throw new InvalidDataException("The canonical payload ended early.");
            }
            var result = _bytes.Slice(_offset, count);
            _offset += count;
            return result;
        }

        private static SurfaceKind ParseSurface(string value) =>
            SurfaceKind.TryParse(value, out var result)
                ? result
                : throw new InvalidDataException("The embedded surface is invalid.");

        private static SnapshotKind ParseSnapshot(string value) =>
            SnapshotKind.TryParse(value, out var result)
                ? result
                : throw new InvalidDataException("The embedded snapshot kind is invalid.");
    }
}

internal sealed class PolicyCodecFailureException(string code) : Exception(code)
{
    internal string Code { get; } = code;
}

internal static class RepositoryTargetWire
{
    private const string InvalidTarget =
        "protocol.codec.invalid-repository-target-resolution";
    private const string LocationMismatch =
        "protocol.codec.payload-location-mismatch";
    private const string EmbeddedIdentityMismatch =
        "protocol.codec.embedded-identity-mismatch";
    private const string ResourceLimit =
        "protocol.codec.resource-limit-exceeded";
    private const int MaximumRows = 50_000;
    private const int MaximumContents = 64;
    private const int MaximumRowTextBytes = 16_777_216;
    private const int MaximumContentBytes = 1_048_576;
    private const int MaximumAggregateContentBytes = 16_777_216;
    private const int MaximumPayloadBytes = 33_554_432;

    private static readonly byte[] Header = Encoding.ASCII.GetBytes(
        "protocol.repository-target-resolution/1\n");
    private static readonly byte[] DemandHeader = Encoding.ASCII.GetBytes(
        "protocol.acquisition-demand/1\n");
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    internal sealed record Decoded(
        ExactSha256Digest DemandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> Rows,
        IReadOnlyList<RepositoryTargetResolutionContent> Contents);

    internal static CanonicalEvidencePayload Encode(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionPayloadRow> rows,
        IReadOnlyList<RepositoryTargetResolutionContent> contents,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(demandDigest);
        ArgumentNullException.ThrowIfNull(rows);
        ArgumentNullException.ThrowIfNull(contents);
        cancellationToken.ThrowIfCancellationRequested();

        if (rows.Any(value => value is null))
        {
            throw new ArgumentException("Rows cannot contain null.", nameof(rows));
        }
        if (contents.Any(value => value is null))
        {
            throw new ArgumentException(
                "Contents cannot contain null.",
                nameof(contents));
        }
        if (rows.Count > MaximumRows || contents.Count > MaximumContents)
        {
            throw Failure(ResourceLimit);
        }
        if (rows.Count == 0)
        {
            throw Failure(InvalidTarget);
        }
        if (!scope.Target.Surface.Equals(SurfaceKind.Repository))
        {
            throw Failure(LocationMismatch);
        }
        if (!scope.Equals(location.Scope))
        {
            throw Failure(EmbeddedIdentityMismatch);
        }

        var rowValues = rows.ToArray();
        var contentValues = contents.ToArray();
        var demandValues = rowValues.Select(value => value.DemandItem).ToArray();
        byte[] demandFrame;
        try
        {
            demandFrame = EncodeDemand(demandValues);
        }
        catch (Exception exception) when (
            exception is ArgumentException or EncoderFallbackException)
        {
            throw Failure(InvalidTarget);
        }
        if (!ExactSha256Digest.FromHashBytes(SHA256.HashData(demandFrame))
            .Equals(demandDigest))
        {
            throw Failure(InvalidTarget);
        }

        var rowData = rowValues
            .Select(value => value.Accept(TargetRowCapture.Instance))
            .ToArray();
        var contentData = contentValues.Select(TargetContentData.Create).ToArray();
        ValidateRowsAndContents(
            demandValues,
            rowValues,
            rowData,
            contentValues,
            contentData);

        try
        {
            using var stream = new MemoryStream();
            stream.Write(Header);
            WriteScope(stream, scope);
            stream.WriteByte(3);
            stream.Write(Convert.FromHexString(demandDigest.Value));
            WriteUInt32(stream, checked((uint)rowData.Length));
            long rowTextBytes = 0;
            for (var index = 0; index < rowData.Length; index++)
            {
                WriteRow(
                    stream,
                    demandValues[index],
                    rowData[index],
                    contentValues,
                    ref rowTextBytes);
                if (rowTextBytes > MaximumRowTextBytes)
                {
                    throw Failure(ResourceLimit);
                }
            }
            WriteUInt32(stream, checked((uint)contentData.Length));
            long aggregateContentBytes = 0;
            for (var index = 0; index < contentData.Length; index++)
            {
                var content = contentData[index];
                if (content.Bytes.Length > MaximumContentBytes)
                {
                    throw Failure(ResourceLimit);
                }
                aggregateContentBytes = checked(
                    aggregateContentBytes + content.Bytes.Length);
                if (aggregateContentBytes > MaximumAggregateContentBytes)
                {
                    throw Failure(ResourceLimit);
                }
                WriteContent(stream, index, content, ref rowTextBytes);
                if (rowTextBytes > MaximumRowTextBytes)
                {
                    throw Failure(ResourceLimit);
                }
            }
            if (stream.Length > MaximumPayloadBytes)
            {
                throw Failure(ResourceLimit);
            }
            return CanonicalEvidencePayload.Create(
                "protocol.repository-target-resolution",
                "1",
                stream.ToArray());
        }
        catch (EncoderFallbackException)
        {
            throw Failure(InvalidTarget);
        }
        catch (OverflowException)
        {
            throw Failure(ResourceLimit);
        }
    }

    internal static Decoded Decode(
        EvidenceBinding binding,
        ExactSha256Digest expectedDemandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> expectedDemandItems,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        ArgumentNullException.ThrowIfNull(expectedDemandDigest);
        ArgumentNullException.ThrowIfNull(expectedDemandItems);
        cancellationToken.ThrowIfCancellationRequested();
        if (expectedDemandItems.Any(value => value is null))
        {
            throw new ArgumentException(
                "Demand items cannot contain null.",
                nameof(expectedDemandItems));
        }
        if (binding.Payload.CanonicalBytes.Count > MaximumPayloadBytes)
        {
            throw Failure(ResourceLimit);
        }

        try
        {
            var bytes = binding.Payload.CanonicalBytes.ToArray();
            var reader = new TargetReader(bytes);
            reader.Expect(Header);
            var scope = ReadScope(ref reader);
            var rank = reader.Byte();
            if (rank is 0 or 1 or 2)
            {
                throw Failure(LocationMismatch);
            }
            if (rank != 3)
            {
                throw Failure(InvalidTarget);
            }
            var digest = ExactSha256Digest.FromHashBytes(reader.Bytes(32));
            var rowCount = reader.UInt32();
            if (rowCount > MaximumRows)
            {
                throw Failure(ResourceLimit);
            }
            if (rowCount == 0)
            {
                throw Failure(InvalidTarget);
            }
            var parsedRows = new ParsedTargetRow[checked((int)rowCount)];
            for (var index = 0; index < parsedRows.Length; index++)
            {
                parsedRows[index] = ReadRow(ref reader);
            }

            var contentCount = reader.UInt32();
            if (contentCount > MaximumContents)
            {
                throw Failure(ResourceLimit);
            }
            var contents = new RepositoryTargetResolutionContent[
                checked((int)contentCount)];
            long aggregateContentBytes = 0;
            for (var index = 0; index < contents.Length; index++)
            {
                if (reader.UInt32() != index)
                {
                    throw Failure(InvalidTarget);
                }
                var kind = reader.Byte();
                var owner = reader.Text();
                var first = reader.Text();
                var path = reader.Text();
                var identity = reader.Text();
                var length = reader.UInt32();
                if (length > MaximumContentBytes)
                {
                    throw Failure(ResourceLimit);
                }
                aggregateContentBytes = checked(aggregateContentBytes + length);
                if (aggregateContentBytes > MaximumAggregateContentBytes)
                {
                    throw Failure(ResourceLimit);
                }
                var contentDigest = reader.Bytes(32);
                var contentBytes = reader.Bytes(checked((int)length));
                if (!SHA256.HashData(contentBytes).AsSpan()
                    .SequenceEqual(contentDigest))
                {
                    throw Failure(InvalidTarget);
                }
                contents[index] = kind switch
                {
                    0 => RepositoryTargetResolutionContent.CommitObject(
                        owner, first, path, identity, contentBytes),
                    1 => RepositoryTargetResolutionContent.CapturedSnapshotPath(
                        owner, first, path, identity, contentBytes),
                    _ => throw Failure(InvalidTarget),
                };
            }
            if (!reader.End)
            {
                throw Failure(InvalidTarget);
            }

            var demands = parsedRows.Select(value => value.Data.Demand).ToArray();
            var rows = parsedRows.Select(value => value.ToCarrier(contents)).ToArray();
            var location = SnapshotEvidenceLocation.Create(scope);
            var canonical = Encode(
                scope,
                location,
                digest,
                rows,
                contents,
                cancellationToken);
            if (!canonical.CanonicalBytes.SequenceEqual(bytes) ||
                !digest.Equals(expectedDemandDigest) ||
                !DemandListsEqual(demands, expectedDemandItems))
            {
                throw Failure(InvalidTarget);
            }
            if (binding.Location is not SnapshotEvidenceLocation outer ||
                !outer.Scope.Target.Surface.Equals(SurfaceKind.Repository))
            {
                throw Failure(LocationMismatch);
            }
            if (!scope.Equals(outer.Scope))
            {
                throw Failure(EmbeddedIdentityMismatch);
            }
            return new Decoded(digest, demands, rows, contents);
        }
        catch (PolicyCodecFailureException)
        {
            throw;
        }
        catch (OverflowException)
        {
            throw Failure(ResourceLimit);
        }
        catch (Exception exception) when (
            exception is ArgumentException or InvalidOperationException or
            DecoderFallbackException)
        {
            throw Failure(InvalidTarget);
        }
    }

    private static byte[] EncodeDemand(
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems)
    {
        if (demandItems.Count is 0 or > MaximumRows)
        {
            throw new ArgumentException("Demand count is invalid.");
        }
        using var stream = new MemoryStream();
        stream.Write(DemandHeader);
        stream.WriteByte(1);
        WriteUInt32(stream, checked((uint)demandItems.Count));
        string? owner = null;
        var priorItemId = -1;
        foreach (var demand in demandItems)
        {
            ArgumentNullException.ThrowIfNull(demand);
            var kind = ValidateDemand(demand, owner, priorItemId);
            owner ??= demand.OwningRepositoryIdentity;
            priorItemId = demand.ItemId;
            WriteDemand(stream, demand, kind, null);
        }
        return stream.ToArray();
    }

    private static void ValidateRowsAndContents(
        RepositoryTargetResolutionDemandItem[] demands,
        RepositoryTargetResolutionPayloadRow[] rows,
        TargetRowData[] rowData,
        RepositoryTargetResolutionContent[] contents,
        TargetContentData[] contentData)
    {
        var referenced = new HashSet<RepositoryTargetResolutionContent>(
            ReferenceEqualityComparer.Instance);
        string? previousContentKey = null;
        for (var index = 0; index < contents.Length; index++)
        {
            var current = contentData[index];
            if (!ValidContent(current) ||
                previousContentKey is not null &&
                StringComparer.Ordinal.Compare(
                    previousContentKey,
                    current.CanonicalKey) >= 0)
            {
                throw Failure(InvalidTarget);
            }
            previousContentKey = current.CanonicalKey;
        }

        for (var index = 0; index < rows.Length; index++)
        {
            var demand = demands[index];
            var row = rowData[index];
            if (!ReferenceEquals(rows[index].DemandItem, demand) ||
                !ReferenceEquals(row.Demand, demand) ||
                !ValidRow(demand, row))
            {
                throw Failure(InvalidTarget);
            }
            if (row.Content is null)
            {
                continue;
            }
            var ordinal = Array.FindIndex(
                contents,
                value => ReferenceEquals(value, row.Content));
            if (ordinal < 0 || !ContentMatchesRow(contentData[ordinal], row))
            {
                throw Failure(InvalidTarget);
            }
            referenced.Add(row.Content);
        }
        if (referenced.Count != contents.Length)
        {
            throw Failure(InvalidTarget);
        }
    }

    private static bool ValidRow(
        RepositoryTargetResolutionDemandItem demand,
        TargetRowData row)
    {
        var demandKind = DemandKindOf(demand);
        return row.Kind switch
        {
            TargetRowKind.MissingCommit => demandKind == DemandKind.Commit,
            TargetRowKind.PresentCommit => demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64),
            TargetRowKind.PresentCommitMissingPath =>
                demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is not null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64),
            TargetRowKind.PresentCommitPath =>
                demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is not null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64) && ValidPath(row.Path) &&
                ValidObjectType(row.PathType) &&
                ValidHex(row.PathIdentity, 40, 64) &&
                (demand.NormalizedFragment is null || row.Content is not null),
            TargetRowKind.MissingTag => demandKind == DemandKind.Tag,
            TargetRowKind.PresentTag => demandKind == DemandKind.Tag &&
                ValidOwner(row.Owner) && ValidRef(row.RefName) &&
                ValidObjectType(row.RefType) &&
                ValidHex(row.RefIdentity, 40, 64) &&
                ValidObjectType(row.PeeledType) &&
                ValidHex(row.PeeledIdentity, 40, 64),
            TargetRowKind.MissingCaptured => demandKind == DemandKind.Captured,
            TargetRowKind.PresentCaptured => demandKind == DemandKind.Captured &&
                ValidOwner(row.Owner) && ValidHex(row.Capture, 64) &&
                ValidPath(row.Path) && row.EntryKind == "file" &&
                ValidHex(row.ContentIdentity, 64) && row.Content is not null,
            _ => false,
        };
    }

    private static bool ValidContent(TargetContentData content)
    {
        if (!ValidOwner(content.Owner) || !ValidPath(content.Path))
        {
            return false;
        }
        if (content.Kind == TargetContentKind.Commit)
        {
            return ValidHex(content.FirstIdentity, 40, 64) &&
                ValidHex(content.ObservedIdentity, content.FirstIdentity.Length) &&
                GitBlobIdentity(content.Bytes, content.FirstIdentity.Length) ==
                    content.ObservedIdentity;
        }
        return ValidHex(content.FirstIdentity, 64) &&
            ValidHex(content.ObservedIdentity, 64) &&
            Convert.ToHexString(SHA256.HashData(content.Bytes))
                .ToLowerInvariant() == content.ObservedIdentity;
    }

    private static bool ContentMatchesRow(
        TargetContentData content,
        TargetRowData row) => row.Kind switch
        {
            TargetRowKind.PresentCommitPath =>
                content.Kind == TargetContentKind.Commit &&
                content.Owner == row.Owner &&
                content.FirstIdentity == row.Identity &&
                content.Path == row.Path &&
                content.ObservedIdentity == row.PathIdentity,
            TargetRowKind.PresentCaptured =>
                content.Kind == TargetContentKind.Captured &&
                content.Owner == row.Owner &&
                content.FirstIdentity == row.Capture &&
                content.Path == row.Path &&
                content.ObservedIdentity == row.ContentIdentity,
            _ => false,
        };

    private static void WriteRow(
        Stream stream,
        RepositoryTargetResolutionDemandItem demand,
        TargetRowData row,
        RepositoryTargetResolutionContent[] contents,
        ref long rowTextBytes)
    {
        var kind = DemandKindOf(demand) ??
            throw Failure(InvalidTarget);
        var demandTextBytes = 0;
        WriteDemand(stream, demand, kind, value => demandTextBytes += value);
        rowTextBytes = checked(rowTextBytes + demandTextBytes);
        switch (row.Kind)
        {
            case TargetRowKind.MissingCommit:
                stream.WriteByte(0);
                break;
            case TargetRowKind.PresentCommit:
                stream.WriteByte(1);
                WriteObservedCommit(stream, row, ref rowTextBytes);
                break;
            case TargetRowKind.PresentCommitMissingPath:
                stream.WriteByte(1);
                WriteObservedCommit(stream, row, ref rowTextBytes);
                stream.WriteByte(0);
                break;
            case TargetRowKind.PresentCommitPath:
                stream.WriteByte(1);
                WriteObservedCommit(stream, row, ref rowTextBytes);
                stream.WriteByte(1);
                WriteCountedText(stream, row.Path!, ref rowTextBytes);
                WriteCountedText(stream, row.PathType!, ref rowTextBytes);
                WriteCountedText(stream, row.PathIdentity!, ref rowTextBytes);
                if (row.Content is null)
                {
                    stream.WriteByte(0);
                }
                else
                {
                    stream.WriteByte(1);
                    WriteUInt32(stream, checked((uint)Array.FindIndex(
                        contents,
                        value => ReferenceEquals(value, row.Content))));
                }
                break;
            case TargetRowKind.MissingTag:
            case TargetRowKind.MissingCaptured:
                stream.WriteByte(0);
                break;
            case TargetRowKind.PresentTag:
                stream.WriteByte(1);
                WriteCountedText(stream, row.Owner!, ref rowTextBytes);
                WriteCountedText(stream, row.RefName!, ref rowTextBytes);
                WriteCountedText(stream, row.RefType!, ref rowTextBytes);
                WriteCountedText(stream, row.RefIdentity!, ref rowTextBytes);
                WriteCountedText(stream, row.PeeledType!, ref rowTextBytes);
                WriteCountedText(stream, row.PeeledIdentity!, ref rowTextBytes);
                break;
            case TargetRowKind.PresentCaptured:
                stream.WriteByte(1);
                WriteCountedText(stream, row.Owner!, ref rowTextBytes);
                WriteCountedText(stream, row.Capture!, ref rowTextBytes);
                WriteCountedText(stream, row.Path!, ref rowTextBytes);
                WriteCountedText(stream, row.EntryKind!, ref rowTextBytes);
                WriteCountedText(stream, row.ContentIdentity!, ref rowTextBytes);
                WriteUInt32(stream, checked((uint)Array.FindIndex(
                    contents,
                    value => ReferenceEquals(value, row.Content))));
                break;
            default:
                throw Failure(InvalidTarget);
        }
    }

    private static void WriteObservedCommit(
        Stream stream,
        TargetRowData row,
        ref long rowTextBytes)
    {
        WriteCountedText(stream, row.Owner!, ref rowTextBytes);
        WriteCountedText(stream, row.Type!, ref rowTextBytes);
        WriteCountedText(stream, row.Identity!, ref rowTextBytes);
    }

    private static void WriteContent(
        Stream stream,
        int ordinal,
        TargetContentData content,
        ref long rowTextBytes)
    {
        WriteUInt32(stream, checked((uint)ordinal));
        stream.WriteByte((byte)content.Kind);
        WriteCountedText(stream, content.Owner, ref rowTextBytes);
        WriteCountedText(stream, content.FirstIdentity, ref rowTextBytes);
        WriteCountedText(stream, content.Path, ref rowTextBytes);
        WriteCountedText(stream, content.ObservedIdentity, ref rowTextBytes);
        WriteUInt32(stream, checked((uint)content.Bytes.Length));
        stream.Write(SHA256.HashData(content.Bytes));
        stream.Write(content.Bytes);
    }

    private static void WriteDemand(
        Stream stream,
        RepositoryTargetResolutionDemandItem demand,
        DemandKind kind,
        Action<int>? countText)
    {
        WriteUInt32(stream, checked((uint)demand.ItemId));
        WriteText(stream, demand.OwningRepositoryIdentity, countText);
        stream.WriteByte((byte)kind);
        switch (kind)
        {
            case DemandKind.Commit:
                WriteText(stream, demand.CommitObjectId!, countText);
                WriteOptionalText(
                    stream,
                    demand.NormalizedRepositoryRelativePath,
                    countText);
                WriteOptionalText(stream, demand.NormalizedFragment, countText);
                break;
            case DemandKind.Tag:
                WriteText(stream, demand.NormalizedTagName!, countText);
                break;
            case DemandKind.Captured:
                WriteText(stream, demand.CapturedSnapshotIdentity!, countText);
                WriteText(
                    stream,
                    demand.NormalizedRepositoryRelativePath!,
                    countText);
                WriteText(stream, demand.NormalizedFragment!, countText);
                break;
        }
    }

    private static ParsedTargetRow ReadRow(ref TargetReader reader)
    {
        var itemId = checked((int)reader.UInt32());
        var owner = reader.Text();
        var selector = reader.Byte();
        if (selector == 0)
        {
            var commit = reader.Text();
            var path = reader.OptionalText();
            var fragment = reader.OptionalText();
            var demand = RepositoryTargetResolutionDemandItem.Create(
                itemId, owner, commit, null, null, path, fragment);
            var outcome = reader.Byte();
            if (outcome == 0)
            {
                return ParsedTargetRow.MissingCommit(demand);
            }
            if (outcome != 1)
            {
                throw Failure(InvalidTarget);
            }
            var observedOwner = reader.Text();
            var type = reader.Text();
            var identity = reader.Text();
            if (path is null)
            {
                return ParsedTargetRow.PresentCommit(
                    demand, observedOwner, type, identity);
            }
            var pathOutcome = reader.Byte();
            if (pathOutcome == 0)
            {
                return ParsedTargetRow.PresentCommitMissingPath(
                    demand, observedOwner, type, identity);
            }
            if (pathOutcome != 1)
            {
                throw Failure(InvalidTarget);
            }
            return ParsedTargetRow.PresentCommitPath(
                demand,
                observedOwner,
                type,
                identity,
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.OptionalUInt32());
        }
        if (selector == 1)
        {
            var demand = RepositoryTargetResolutionDemandItem.Create(
                itemId, owner, null, reader.Text(), null, null, null);
            var outcome = reader.Byte();
            if (outcome == 0)
            {
                return ParsedTargetRow.MissingTag(demand);
            }
            if (outcome != 1)
            {
                throw Failure(InvalidTarget);
            }
            return ParsedTargetRow.PresentTag(
                demand,
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text());
        }
        if (selector == 2)
        {
            var demand = RepositoryTargetResolutionDemandItem.Create(
                itemId,
                owner,
                null,
                null,
                reader.Text(),
                reader.Text(),
                reader.Text());
            var outcome = reader.Byte();
            if (outcome == 0)
            {
                return ParsedTargetRow.MissingCaptured(demand);
            }
            if (outcome != 1)
            {
                throw Failure(InvalidTarget);
            }
            return ParsedTargetRow.PresentCaptured(
                demand,
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.UInt32());
        }
        throw Failure(InvalidTarget);
    }

    private static EvidenceScope ReadScope(ref TargetReader reader)
    {
        var subject = reader.Text();
        var source = reader.Text();
        var surfaceText = reader.Text();
        var targetSnapshotText = reader.Text();
        var targetIdentity = reader.Text();
        var boundarySnapshotText = reader.Text();
        var boundaryIdentity = reader.Text();
        var started = new DateTimeOffset(reader.Int64(), TimeSpan.Zero);
        var completed = new DateTimeOffset(reader.Int64(), TimeSpan.Zero);
        if (!SurfaceKind.TryParse(surfaceText, out var surface) ||
            !SnapshotKind.TryParse(targetSnapshotText, out var targetSnapshot) ||
            !SnapshotKind.TryParse(boundarySnapshotText, out var boundarySnapshot))
        {
            throw Failure(InvalidTarget);
        }
        if (!surface.Equals(SurfaceKind.Repository))
        {
            throw Failure(LocationMismatch);
        }
        return EvidenceScope.Create(
            AcquisitionTarget.Create(
                subject, source, surface, targetSnapshot, targetIdentity),
            AcquisitionBoundary.Create(
                boundarySnapshot,
                boundaryIdentity,
                started,
                completed));
    }

    private static void WriteScope(Stream stream, EvidenceScope scope)
    {
        WriteText(stream, scope.Target.SubjectIdentity, null);
        WriteText(stream, scope.Target.SourceIdentity, null);
        WriteText(stream, scope.Target.Surface.Value, null);
        WriteText(stream, scope.Target.SnapshotKind.Value, null);
        WriteText(stream, scope.Target.TargetIdentity, null);
        WriteText(stream, scope.Boundary.SnapshotKind.Value, null);
        WriteText(stream, scope.Boundary.BoundaryIdentity, null);
        WriteInt64(stream, scope.Boundary.StartedAtUtc.UtcTicks);
        WriteInt64(stream, scope.Boundary.CompletedAtUtc.UtcTicks);
    }

    private static DemandKind ValidateDemand(
        RepositoryTargetResolutionDemandItem demand,
        string? owner,
        int priorItemId)
    {
        var kind = DemandKindOf(demand) ?? throw Failure(InvalidTarget);
        if (demand.ItemId < 0 || demand.ItemId <= priorItemId ||
            !ValidOwner(demand.OwningRepositoryIdentity) ||
            owner is not null && owner != demand.OwningRepositoryIdentity)
        {
            throw Failure(InvalidTarget);
        }
        if (kind == DemandKind.Commit &&
            (!ValidHex(demand.CommitObjectId, 40, 64) ||
             demand.NormalizedRepositoryRelativePath is not null &&
             !ValidPath(demand.NormalizedRepositoryRelativePath) ||
             demand.NormalizedFragment is not null &&
             (demand.NormalizedRepositoryRelativePath is null ||
              !ValidFragment(demand.NormalizedFragment))))
        {
            throw Failure(InvalidTarget);
        }
        if (kind == DemandKind.Tag && !ValidTag(demand.NormalizedTagName))
        {
            throw Failure(InvalidTarget);
        }
        if (kind == DemandKind.Captured &&
            (!ValidHex(demand.CapturedSnapshotIdentity, 64) ||
             !ValidPath(demand.NormalizedRepositoryRelativePath) ||
             !ValidFragment(demand.NormalizedFragment)))
        {
            throw Failure(InvalidTarget);
        }
        return kind;
    }

    private static DemandKind? DemandKindOf(
        RepositoryTargetResolutionDemandItem demand)
    {
        var count = (demand.CommitObjectId is null ? 0 : 1) +
            (demand.NormalizedTagName is null ? 0 : 1) +
            (demand.CapturedSnapshotIdentity is null ? 0 : 1);
        if (count != 1)
        {
            return null;
        }
        return demand.CommitObjectId is not null
            ? DemandKind.Commit
            : demand.NormalizedTagName is not null
                ? DemandKind.Tag
                : DemandKind.Captured;
    }

    private static bool DemandListsEqual(
        IReadOnlyList<RepositoryTargetResolutionDemandItem> left,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> right) =>
        left.Count == right.Count && left.Zip(right).All(pair =>
            pair.First.ItemId == pair.Second.ItemId &&
            pair.First.OwningRepositoryIdentity ==
                pair.Second.OwningRepositoryIdentity &&
            pair.First.CommitObjectId == pair.Second.CommitObjectId &&
            pair.First.NormalizedTagName == pair.Second.NormalizedTagName &&
            pair.First.CapturedSnapshotIdentity ==
                pair.Second.CapturedSnapshotIdentity &&
            pair.First.NormalizedRepositoryRelativePath ==
                pair.Second.NormalizedRepositoryRelativePath &&
            pair.First.NormalizedFragment == pair.Second.NormalizedFragment);

    private static bool ValidOwner(string? value)
    {
        const string prefix = "https://github.com/";
        if (value is null || !value.StartsWith(prefix, StringComparison.Ordinal) ||
            value.EndsWith("/", StringComparison.Ordinal))
        {
            return false;
        }
        var segments = value[prefix.Length..].Split('/');
        return segments.Length == 2 && segments.All(segment =>
            segment.Length > 0 && segment.All(character =>
                char.IsAsciiLetterOrDigit(character) ||
                character is '-' or '_' or '.'));
    }

    private static bool ValidPath(string? value) =>
        !string.IsNullOrEmpty(value) && value[0] != '/' && value[^1] != '/' &&
        !value.Contains('\\', StringComparison.Ordinal) &&
        !(value.Length >= 2 && char.IsAsciiLetter(value[0]) && value[1] == ':') &&
        value.Split('/').All(segment =>
            segment.Length > 0 && segment is not "." and not "..");

    private static bool ValidTag(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        !value.Contains('/', StringComparison.Ordinal) &&
        !value.Contains('\\', StringComparison.Ordinal) &&
        !value.Contains("..", StringComparison.Ordinal);

    private static bool ValidFragment(string? value) =>
        !string.IsNullOrEmpty(value) &&
        !value.Contains('\uFEFF', StringComparison.Ordinal);

    private static bool ValidRef(string? value) =>
        value is not null &&
        value.StartsWith("refs/tags/", StringComparison.Ordinal) &&
        ValidTag(value["refs/tags/".Length..]);

    private static bool ValidObjectType(string? value) =>
        value is "blob" or "commit" or "tag" or "tree";

    private static bool ValidHex(string? value, params int[] lengths) =>
        value is not null && lengths.Contains(value.Length) &&
        value.All(character =>
            character is >= '0' and <= '9' or >= 'a' and <= 'f');

    private static string GitBlobIdentity(byte[] bytes, int length)
    {
        var header = Encoding.ASCII.GetBytes($"blob {bytes.Length}\0");
        var framed = new byte[header.Length + bytes.Length];
        header.CopyTo(framed, 0);
        bytes.CopyTo(framed, header.Length);
        return length == 40
            ? Convert.ToHexString(SHA1.HashData(framed)).ToLowerInvariant()
            : Convert.ToHexString(SHA256.HashData(framed)).ToLowerInvariant();
    }

    private static void WriteOptionalText(
        Stream stream,
        string? value,
        Action<int>? countText)
    {
        stream.WriteByte(value is null ? (byte)0 : (byte)1);
        if (value is not null)
        {
            WriteText(stream, value, countText);
        }
    }

    private static void WriteCountedText(
        Stream stream,
        string value,
        ref long rowTextBytes)
    {
        var bytes = StrictUtf8.GetBytes(value);
        rowTextBytes = checked(rowTextBytes + bytes.Length);
        WriteUInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    private static void WriteText(
        Stream stream,
        string value,
        Action<int>? countText)
    {
        var bytes = StrictUtf8.GetBytes(value);
        countText?.Invoke(bytes.Length);
        WriteUInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    private static void WriteUInt32(Stream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static void WriteInt64(Stream stream, long value)
    {
        Span<byte> bytes = stackalloc byte[8];
        BinaryPrimitives.WriteInt64BigEndian(bytes, value);
        stream.Write(bytes);
    }

    private static PolicyCodecFailureException Failure(string code) => new(code);

    private enum DemandKind : byte { Commit, Tag, Captured }
    private enum TargetContentKind : byte { Commit, Captured }
    private enum TargetRowKind
    {
        MissingCommit,
        PresentCommit,
        PresentCommitMissingPath,
        PresentCommitPath,
        MissingTag,
        PresentTag,
        MissingCaptured,
        PresentCaptured,
    }

    private sealed record TargetRowData(
        TargetRowKind Kind,
        RepositoryTargetResolutionDemandItem Demand,
        string? Owner = null,
        string? Type = null,
        string? Identity = null,
        string? Path = null,
        string? PathType = null,
        string? PathIdentity = null,
        RepositoryTargetResolutionContent? Content = null,
        string? RefName = null,
        string? RefType = null,
        string? RefIdentity = null,
        string? PeeledType = null,
        string? PeeledIdentity = null,
        string? Capture = null,
        string? EntryKind = null,
        string? ContentIdentity = null);

    private sealed record TargetContentData(
        TargetContentKind Kind,
        string Owner,
        string FirstIdentity,
        string Path,
        string ObservedIdentity,
        byte[] Bytes)
    {
        internal string CanonicalKey =>
            $"{(int)Kind:D1}\0{Owner}\0{FirstIdentity}\0{Path}\0{ObservedIdentity}";

        internal static TargetContentData Create(
            RepositoryTargetResolutionContent content)
        {
            if (content.CommitObjectId is not null &&
                content.CapturedSnapshotIdentity is null)
            {
                return new(
                    TargetContentKind.Commit,
                    content.OwningRepositoryIdentity,
                    content.CommitObjectId,
                    content.NormalizedRepositoryRelativePath,
                    content.ObservedContentIdentity,
                    content.Bytes.ToArray());
            }
            if (content.CommitObjectId is null &&
                content.CapturedSnapshotIdentity is not null)
            {
                return new(
                    TargetContentKind.Captured,
                    content.OwningRepositoryIdentity,
                    content.CapturedSnapshotIdentity,
                    content.NormalizedRepositoryRelativePath,
                    content.ObservedContentIdentity,
                    content.Bytes.ToArray());
            }
            throw Failure(InvalidTarget);
        }
    }

    private sealed class TargetRowCapture :
        IRepositoryTargetResolutionPayloadRowVisitor<TargetRowData>
    {
        internal static TargetRowCapture Instance { get; } = new();

        public TargetRowData VisitMissingCommit(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(TargetRowKind.MissingCommit, demandItem);

        public TargetRowData VisitPresentCommit(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity) => new(
                TargetRowKind.PresentCommit,
                demandItem,
                Owner: observedOwner,
                Type: observedType,
                Identity: observedIdentity);

        public TargetRowData VisitPresentCommitMissingPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity) => new(
                TargetRowKind.PresentCommitMissingPath,
                demandItem,
                Owner: observedOwner,
                Type: observedType,
                Identity: observedIdentity);

        public TargetRowData VisitPresentCommitPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedType,
            string observedIdentity,
            string observedPath,
            string observedPathType,
            string observedPathIdentity,
            RepositoryTargetResolutionContent? content) => new(
                TargetRowKind.PresentCommitPath,
                demandItem,
                Owner: observedOwner,
                Type: observedType,
                Identity: observedIdentity,
                Path: observedPath,
                PathType: observedPathType,
                PathIdentity: observedPathIdentity,
                Content: content);

        public TargetRowData VisitMissingTag(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(TargetRowKind.MissingTag, demandItem);

        public TargetRowData VisitPresentTag(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedRefName,
            string observedRefType,
            string observedRefIdentity,
            string observedPeeledType,
            string observedPeeledIdentity) => new(
                TargetRowKind.PresentTag,
                demandItem,
                Owner: observedOwner,
                RefName: observedRefName,
                RefType: observedRefType,
                RefIdentity: observedRefIdentity,
                PeeledType: observedPeeledType,
                PeeledIdentity: observedPeeledIdentity);

        public TargetRowData VisitMissingCapturedPath(
            RepositoryTargetResolutionDemandItem demandItem) =>
            new(TargetRowKind.MissingCaptured, demandItem);

        public TargetRowData VisitPresentCapturedPath(
            RepositoryTargetResolutionDemandItem demandItem,
            string observedOwner,
            string observedCapture,
            string observedPath,
            string observedEntryKind,
            string observedContentIdentity,
            RepositoryTargetResolutionContent content) => new(
                TargetRowKind.PresentCaptured,
                demandItem,
                Owner: observedOwner,
                Path: observedPath,
                Content: content,
                Capture: observedCapture,
                EntryKind: observedEntryKind,
                ContentIdentity: observedContentIdentity);
    }

    private sealed record ParsedTargetRow(
        TargetRowData Data,
        uint? ContentOrdinal = null)
    {
        internal RepositoryTargetResolutionPayloadRow ToCarrier(
            RepositoryTargetResolutionContent[] contents)
        {
            RepositoryTargetResolutionContent? content = null;
            if (ContentOrdinal is not null)
            {
                if (ContentOrdinal.Value >= contents.Length)
                {
                    throw Failure(InvalidTarget);
                }
                content = contents[ContentOrdinal.Value];
            }
            return Data.Kind switch
            {
                TargetRowKind.MissingCommit =>
                    RepositoryTargetResolutionPayloadRow.MissingCommit(Data.Demand),
                TargetRowKind.PresentCommit =>
                    RepositoryTargetResolutionPayloadRow.PresentCommit(
                        Data.Demand, Data.Owner!, Data.Type!, Data.Identity!),
                TargetRowKind.PresentCommitMissingPath =>
                    RepositoryTargetResolutionPayloadRow.PresentCommitMissingPath(
                        Data.Demand, Data.Owner!, Data.Type!, Data.Identity!),
                TargetRowKind.PresentCommitPath =>
                    RepositoryTargetResolutionPayloadRow.PresentCommitPath(
                        Data.Demand,
                        Data.Owner!,
                        Data.Type!,
                        Data.Identity!,
                        Data.Path!,
                        Data.PathType!,
                        Data.PathIdentity!,
                        content),
                TargetRowKind.MissingTag =>
                    RepositoryTargetResolutionPayloadRow.MissingTag(Data.Demand),
                TargetRowKind.PresentTag =>
                    RepositoryTargetResolutionPayloadRow.PresentTag(
                        Data.Demand,
                        Data.Owner!,
                        Data.RefName!,
                        Data.RefType!,
                        Data.RefIdentity!,
                        Data.PeeledType!,
                        Data.PeeledIdentity!),
                TargetRowKind.MissingCaptured =>
                    RepositoryTargetResolutionPayloadRow.MissingCapturedPath(
                        Data.Demand),
                TargetRowKind.PresentCaptured =>
                    RepositoryTargetResolutionPayloadRow.PresentCapturedPath(
                        Data.Demand,
                        Data.Owner!,
                        Data.Capture!,
                        Data.Path!,
                        Data.EntryKind!,
                        Data.ContentIdentity!,
                        content ?? throw Failure(InvalidTarget)),
                _ => throw Failure(InvalidTarget),
            };
        }

        internal static ParsedTargetRow MissingCommit(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new TargetRowData(TargetRowKind.MissingCommit, demand));

        internal static ParsedTargetRow PresentCommit(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(new TargetRowData(
                TargetRowKind.PresentCommit,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity));

        internal static ParsedTargetRow PresentCommitMissingPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(new TargetRowData(
                TargetRowKind.PresentCommitMissingPath,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity));

        internal static ParsedTargetRow PresentCommitPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity,
            string path,
            string pathType,
            string pathIdentity,
            uint? contentOrdinal) => new(
                new TargetRowData(
                    TargetRowKind.PresentCommitPath,
                    demand,
                    Owner: owner,
                    Type: type,
                    Identity: identity,
                    Path: path,
                    PathType: pathType,
                    PathIdentity: pathIdentity),
                contentOrdinal);

        internal static ParsedTargetRow MissingTag(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new TargetRowData(TargetRowKind.MissingTag, demand));

        internal static ParsedTargetRow PresentTag(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string refName,
            string refType,
            string refIdentity,
            string peeledType,
            string peeledIdentity) => new(new TargetRowData(
                TargetRowKind.PresentTag,
                demand,
                Owner: owner,
                RefName: refName,
                RefType: refType,
                RefIdentity: refIdentity,
                PeeledType: peeledType,
                PeeledIdentity: peeledIdentity));

        internal static ParsedTargetRow MissingCaptured(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new TargetRowData(TargetRowKind.MissingCaptured, demand));

        internal static ParsedTargetRow PresentCaptured(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string capture,
            string path,
            string entryKind,
            string contentIdentity,
            uint contentOrdinal) => new(
                new TargetRowData(
                    TargetRowKind.PresentCaptured,
                    demand,
                    Owner: owner,
                    Path: path,
                    Capture: capture,
                    EntryKind: entryKind,
                    ContentIdentity: contentIdentity),
                contentOrdinal);
    }

    private ref struct TargetReader
    {
        private readonly ReadOnlySpan<byte> _bytes;
        private int _offset;

        internal TargetReader(ReadOnlySpan<byte> bytes)
        {
            _bytes = bytes;
            _offset = 0;
        }

        internal bool End => _offset == _bytes.Length;
        internal void Expect(ReadOnlySpan<byte> expected)
        {
            if (!Read(expected.Length).SequenceEqual(expected))
            {
                throw Failure(InvalidTarget);
            }
        }
        internal string Text()
        {
            var length = UInt32();
            if (length > int.MaxValue)
            {
                throw Failure(InvalidTarget);
            }
            var value = StrictUtf8.GetString(Read(checked((int)length)));
            return value.Contains('\uFEFF', StringComparison.Ordinal)
                ? throw Failure(InvalidTarget)
                : value;
        }
        internal string? OptionalText() => Byte() switch
        {
            0 => null,
            1 => Text(),
            _ => throw Failure(InvalidTarget),
        };
        internal uint? OptionalUInt32() => Byte() switch
        {
            0 => null,
            1 => UInt32(),
            _ => throw Failure(InvalidTarget),
        };
        internal byte Byte() => Read(1)[0];
        internal uint UInt32() =>
            BinaryPrimitives.ReadUInt32BigEndian(Read(4));
        internal long Int64() => BinaryPrimitives.ReadInt64BigEndian(Read(8));
        internal byte[] Bytes(int count) => Read(count).ToArray();
        private ReadOnlySpan<byte> Read(int count)
        {
            if (count < 0 || count > _bytes.Length - _offset)
            {
                throw Failure(InvalidTarget);
            }
            var value = _bytes.Slice(_offset, count);
            _offset += count;
            return value;
        }
    }
}
