using System.Buffers.Binary;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBRepositoryTreeCodecTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0002";
    private const string Identity =
        "0123456789abcdef0123456789abcdef01234567";
    private const string GoldenBase64 =
        "cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAQAAAAJQUdFTlRTLm1kAQAAAARkb2NzAAAAAAxsaW5rcy9sYXRlc3QCAAAAD3ZlbmRvci9wcm90b2NvbAM=";
    private const string EmptyBase64 =
        "cHJvdG9jb2wucmVwb3NpdG9yeS10cmVlLzEKAAAABHJlcG8AAAADZ2l0AAAACnJlcG9zaXRvcnkAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAMZXhhY3QtY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAAAAAAAAAAAAABAwAAAAA=";
    [Fact]
    [Trait("ContractSlice", "B")]
    public void Round_trips_exact_repository_tree_wire()
    {
        var fixture = Fixture();
        var codec = new RepositoryTreeCodecMirror();
        var first = Write(codec, fixture, fixture.Entries);
        if (first is null)
        {
            Assert.Fail(Marker);
        }
        var golden = Convert.FromBase64String(GoldenBase64);
        var payload = Written(first);
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTree(null!, fixture.Location, fixture.Entries, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTree(fixture.Scope, null!, fixture.Entries, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTree(fixture.Scope, fixture.Location, null!, CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() => codec.WriteRepositoryTree(fixture.Scope, fixture.Location, fixture.Entries, new CancellationToken(true)));
        Assert.Throws<ArgumentNullException>(() => codec.QualifyRepositoryTree(null!, CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() => codec.QualifyRepositoryTree(Bind(payload, fixture.Location), new CancellationToken(true)));
        Assert.Throws<ArgumentNullException>(() => Entry(null!, RepositoryEntryKind.File));
        Assert.Throws<ArgumentNullException>(() => Entry("x", null!));
        Assert.Equal("protocol.repository-tree", payload.SchemaKey);
        Assert.Equal("1", payload.SchemaVersion);
        Assert.Equal(golden, payload.CanonicalBytes);
        Assert.Equal("C5A8CB268E42C8A8C532A42C86ECDB0200B4C75186364B6399AD1AE5A40AE97F", Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(golden)));
        var model = Qualified(Qualify(codec, fixture, payload));
        Assert.Equal(fixture.Scope, model.Scope);
        Assert.Equal(fixture.Location, model.Location);
        Assert.Equal(fixture.Entries.Select(Row), model.Entries.Select(Row));
        var empty = Written(Write(codec, fixture, []));
        Assert.Equal(Convert.FromBase64String(EmptyBase64), empty.CanonicalBytes);
        Assert.Empty(Qualified(Qualify(codec, fixture, empty)).Entries);
        foreach (var path in new[]
        {
            "", "/root", "root/", "a\\b", "a//b", "a/./b", "a/../b", "C:/a", })
        {
            WriteRejected(Write(codec, fixture, [Entry(path, RepositoryEntryKind.File)]), RepositoryTreeCodecMirror.InvalidTree);
            QualifyRejected(Qualify(codec, fixture, Payload(ReplaceText(golden, 197, 201, 9, Utf8(path)))), RepositoryTreeCodecMirror.InvalidTree);
        }
        WriteRejected(Write(codec, fixture, [Entry("a", RepositoryEntryKind.File), Entry("a", RepositoryEntryKind.File)]), RepositoryTreeCodecMirror.InvalidTree);
        WriteRejected(Write(codec, fixture, [Entry("z", RepositoryEntryKind.File), Entry("a", RepositoryEntryKind.File)]), RepositoryTreeCodecMirror.InvalidTree);
        foreach (var path in new[] { "docs", "z" })
        {
            QualifyRejected(Qualify(codec, fixture, Payload(ReplaceText(golden, 197, 201, 9, Utf8(path)))), RepositoryTreeCodecMirror.InvalidTree);
        }
        var nullEntry = Assert.Throws<ArgumentException>(() => Write(codec, fixture, [null!]));
        Assert.Equal("entries", nullEntry.ParamName);
        var other = Fixture("1123456789abcdef0123456789abcdef01234567");
        WriteRejected(codec.WriteRepositoryTree(fixture.Scope, other.Location, fixture.Entries, CancellationToken.None), RepositoryTreeCodecMirror.EmbeddedIdentityMismatch);
        var workflow = Fixture(Identity, SurfaceKind.Workflow);
        WriteRejected(Write(codec, workflow, workflow.Entries), RepositoryTreeCodecMirror.LocationMismatch);
        var countLimit = Enumerable.Range(0, 200_000).Select(index => Entry($"e{index:D6}", RepositoryEntryKind.File)).ToArray();
        Written(Write(codec, fixture, countLimit));
        WriteRejected(Write(codec, fixture, [.. countLimit, Entry("e200000", RepositoryEntryKind.File)]), RepositoryTreeCodecMirror.ResourceLimit);
        var payloadLimit = Padded(4_091, 4_096, 3_924);
        Assert.Equal(RepositoryTreeCodecMirror.MaximumPayloadBytes, Written(Write(codec, fixture, payloadLimit)).CanonicalBytes.Count);
        payloadLimit[^1] = Entry(payloadLimit[^1].RepositoryRelativePath + "x", RepositoryEntryKind.File);
        WriteRejected(Write(codec, fixture, payloadLimit), RepositoryTreeCodecMirror.ResourceLimit);
        var pathLimit = Padded(4_096, 4_096, 4_096);
        WriteRejected(Write(codec, fixture, pathLimit), RepositoryTreeCodecMirror.ResourceLimit);
        pathLimit[^1] = Entry(pathLimit[^1].RepositoryRelativePath + "x", RepositoryEntryKind.File);
        WriteRejected(Write(codec, fixture, pathLimit), RepositoryTreeCodecMirror.ResourceLimit);
        foreach (var length in Enumerable.Range(0, golden.Length))
        {
            Invalid(codec, fixture, golden.AsSpan(0, length).ToArray());
        }
        var wrongHeader = golden.ToArray();
        wrongHeader[0] ^= 1;
        foreach (var malformed in new[]
        {
            wrongHeader, ReplaceText(golden, 27, 31, 4, [0xEF, 0xBB, 0xBF]), ReplaceText(golden, 27, 31, 4, [0xC3, 0x28]), ReplaceText(golden, 27, 31, 4, [0xC0, 0xAF]), ReplaceText(golden, 27, 31, 4, [0xED, 0xA0, 0x80]), SetUInt32(golden, 27, uint.MaxValue), SetUInt32(golden, 193, 3), SetUInt32(golden, 193, 5), [.. golden, 0], SetByte(golden, 192, 4), SetByte(golden, golden.Length - 1, 4), ReplaceText(golden, 42, 46, 10, Utf8("unknown___")), })
        {
            Invalid(codec, fixture, malformed);
        }
        QualifyRejected(Qualify(codec, fixture, Payload(ReplaceText(golden, 42, 46, 10, Utf8("workflow")))), RepositoryTreeCodecMirror.LocationMismatch);
        QualifyRejected(Qualify(codec, fixture, Payload(SetByte(golden, 192, 0))), RepositoryTreeCodecMirror.LocationMismatch);
        QualifyRejected(Qualify(codec, fixture, Payload(SetUInt32(golden, 193, 200_001))), RepositoryTreeCodecMirror.ResourceLimit);
        QualifyRejected(Qualify(codec, fixture, CanonicalEvidencePayload.Create("protocol.other", "1", golden)), RepositoryTreeCodecMirror.InvalidTree);
        QualifyRejected(Qualify(codec, fixture, CanonicalEvidencePayload.Create("protocol.repository-tree", "2", golden)), RepositoryTreeCodecMirror.InvalidTree);
        QualifyRejected(Qualify(codec, fixture, Payload(new byte[RepositoryTreeCodecMirror.MaximumPayloadBytes + 1])), RepositoryTreeCodecMirror.ResourceLimit);
        var otherPayload = Written(Write(codec, other, other.Entries));
        QualifyRejected(Qualify(codec, fixture, otherPayload), RepositoryTreeCodecMirror.EmbeddedIdentityMismatch);
        var repositoryLocation = RepositoryEvidenceLocation.Create(fixture.Scope, "AGENTS.md", null, null, null, null);
        QualifyRejected(codec.QualifyRepositoryTree(Bind(payload, repositoryLocation), CancellationToken.None), RepositoryTreeCodecMirror.LocationMismatch);
    }
    private static RepositoryTreeWriteMirrorResult Write(RepositoryTreeCodecMirror codec, FixtureData fixture, IReadOnlyList<RepositoryTreePayloadEntryMirror> entries) => codec.WriteRepositoryTree(fixture.Scope, fixture.Location, entries, CancellationToken.None);
    private static RepositoryTreeQualificationMirrorResult Qualify(RepositoryTreeCodecMirror codec, FixtureData fixture, CanonicalEvidencePayload payload) => codec.QualifyRepositoryTree(Bind(payload, fixture.Location), CancellationToken.None);
    private static RepositoryTreePayloadEntryMirror[] Padded(int count, int ordinaryLength, int lastLength) => Enumerable.Range(0, count).Select(index =>
    {
        var prefix = $"p{index:D6}/";
        var length = index == count - 1 ? lastLength : ordinaryLength;
        return Entry(prefix + new string('x', length - prefix.Length), RepositoryEntryKind.File);
    }).ToArray();
    private static FixtureData Fixture(string identity = Identity, SurfaceKind? surface = null)
    {
        var target = AcquisitionTarget.Create("repo", "git", surface ?? SurfaceKind.Repository, SnapshotKind.ExactCommit, identity);
        var boundary = AcquisitionBoundary.Create(SnapshotKind.ExactCommit, identity, new DateTimeOffset(0, TimeSpan.Zero), new DateTimeOffset(1, TimeSpan.Zero));
        var scope = EvidenceScope.Create(target, boundary);
        return new FixtureData(scope, SnapshotEvidenceLocation.Create(scope), [
                Entry("AGENTS.md", RepositoryEntryKind.File), Entry("docs", RepositoryEntryKind.Directory), Entry("links/latest", RepositoryEntryKind.SymbolicLink), Entry("vendor/protocol", RepositoryEntryKind.GitLink), ]);
    }
    private static RepositoryTreePayloadEntryMirror Entry(string path, RepositoryEntryKind kind) => RepositoryTreePayloadEntryMirror.Create(path, kind);
    private static (string Path, string Kind) Row(RepositoryTreePayloadEntryMirror entry) => (entry.RepositoryRelativePath, entry.Kind.Value);
    private static EvidenceBinding Bind(CanonicalEvidencePayload payload, EvidenceLocation location) => EvidenceBinding.Create(payload, location, ["protocol.requirement"], new DateTimeOffset(1, TimeSpan.Zero));
    private static CanonicalEvidencePayload Payload(byte[] bytes) => CanonicalEvidencePayload.Create("protocol.repository-tree", "1", bytes);
    private static CanonicalEvidencePayload Written(RepositoryTreeWriteMirrorResult result)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<CanonicalEvidencePayload>(value.Payload);
    }
    private static void WriteRejected(RepositoryTreeWriteMirrorResult result, string expected)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Payload);
        Assert.Equal(expected, value.Failure);
    }
    private static RepositoryTreeModelMirror Qualified(RepositoryTreeQualificationMirrorResult result)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<RepositoryTreeModelMirror>(value.Model);
    }
    private static void QualifyRejected(RepositoryTreeQualificationMirrorResult result, string expected)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Model);
        Assert.Equal(expected, value.Failure);
    }
    private static void Invalid(RepositoryTreeCodecMirror codec, FixtureData fixture, byte[] bytes) => QualifyRejected(Qualify(codec, fixture, Payload(bytes)), RepositoryTreeCodecMirror.InvalidTree);
    private static byte[] Utf8(string value) => Encoding.UTF8.GetBytes(value);
    private static byte[] SetByte(byte[] source, int offset, byte value)
    {
        var result = source.ToArray();
        result[offset] = value;
        return result;
    }
    private static byte[] SetUInt32(byte[] source, int offset, uint value)
    {
        var result = source.ToArray();
        BinaryPrimitives.WriteUInt32BigEndian(result.AsSpan(offset, 4), value);
        return result;
    }
    private static byte[] ReplaceText(byte[] source, int lengthOffset, int dataOffset, int oldLength, byte[] replacement)
    {
        var result = new byte[source.Length - oldLength + replacement.Length];
        source.AsSpan(0, dataOffset).CopyTo(result);
        replacement.CopyTo(result, dataOffset);
        source.AsSpan(dataOffset + oldLength).CopyTo(result.AsSpan(dataOffset + replacement.Length));
        BinaryPrimitives.WriteUInt32BigEndian(result.AsSpan(lengthOffset, 4), checked((uint)replacement.Length));
        return result;
    }
    private sealed record FixtureData(EvidenceScope Scope, SnapshotEvidenceLocation Location, RepositoryTreePayloadEntryMirror[] Entries);
    private sealed record WriteValue(CanonicalEvidencePayload? Payload, string? Failure);
    private sealed class WriteObserver :
        IRepositoryTreeWriteMirrorResultVisitor<WriteValue>
    {
        internal static WriteObserver Instance { get; } = new();
        public WriteValue VisitWritten(CanonicalEvidencePayload payload) => new(payload, null);
        public WriteValue VisitRejected(string failureCode) => new(null, failureCode);
    }
    private sealed record QualificationValue(RepositoryTreeModelMirror? Model, string? Failure);
    private sealed class QualificationObserver :
        IRepositoryTreeQualificationMirrorResultVisitor<QualificationValue>
    {
        internal static QualificationObserver Instance { get; } = new();
        public QualificationValue VisitQualified(RepositoryTreeModelMirror model) => new(model, null);
        public QualificationValue VisitRejected(string failureCode) => new(null, failureCode);
    }
}
internal sealed class RepositoryTreePayloadEntryMirror
{
    private RepositoryTreePayloadEntryMirror(string path, RepositoryEntryKind kind)
    {
        RepositoryRelativePath = path;
        Kind = kind;
    }
    internal string RepositoryRelativePath { get; }
    internal RepositoryEntryKind Kind { get; }
    internal static RepositoryTreePayloadEntryMirror Create(string repositoryRelativePath, RepositoryEntryKind kind)
    {
        ArgumentNullException.ThrowIfNull(repositoryRelativePath);
        ArgumentNullException.ThrowIfNull(kind);
        return new RepositoryTreePayloadEntryMirror(repositoryRelativePath, kind);
    }
}
internal sealed partial class RepositoryTreeModelMirror
{
    private RepositoryTreeModelMirror(EvidenceScope scope, SnapshotEvidenceLocation location, RepositoryTreePayloadEntryMirror[] entries)
    {
        Scope = scope;
        Location = location;
        Entries = Array.AsReadOnly(entries);
    }
    internal EvidenceScope Scope { get; }
    internal SnapshotEvidenceLocation Location { get; }
    internal IReadOnlyList<RepositoryTreePayloadEntryMirror> Entries { get; }
    internal static RepositoryTreeModelMirror Create(EvidenceScope scope, SnapshotEvidenceLocation location, IEnumerable<RepositoryTreePayloadEntryMirror> entries)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(entries);
        var values = entries.ToArray();
        if (values.Any(value => value is null))
        {
            throw new ArgumentException("Repository-tree entries cannot contain null.", nameof(entries));
        }
        if (!scope.Equals(location.Scope))
        {
            throw new ArgumentException("The location must retain the supplied scope.", nameof(location));
        }
        return new RepositoryTreeModelMirror(scope, location, values);
    }
}
internal abstract class RepositoryTreeWriteMirrorResult
{
    private RepositoryTreeWriteMirrorResult()
    {
    }
    internal static RepositoryTreeWriteMirrorResult Written(CanonicalEvidencePayload payload) => new WrittenCase(payload ?? throw new ArgumentNullException(nameof(payload)));
    internal static RepositoryTreeWriteMirrorResult Rejected(string failureCode) => new RejectedCase(string.IsNullOrWhiteSpace(failureCode) ? throw new ArgumentException(null, nameof(failureCode)) : failureCode);
    internal abstract TResult Accept<TResult>(IRepositoryTreeWriteMirrorResultVisitor<TResult> visitor);
    private sealed class WrittenCase(CanonicalEvidencePayload payload) :
        RepositoryTreeWriteMirrorResult
    {
        internal override TResult Accept<TResult>(IRepositoryTreeWriteMirrorResultVisitor<TResult> visitor) => visitor.VisitWritten(payload);
    }
    private sealed class RejectedCase(string failureCode) :
        RepositoryTreeWriteMirrorResult
    {
        internal override TResult Accept<TResult>(IRepositoryTreeWriteMirrorResultVisitor<TResult> visitor) => visitor.VisitRejected(failureCode);
    }
}
internal interface IRepositoryTreeWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}
internal abstract class RepositoryTreeQualificationMirrorResult
{
    private RepositoryTreeQualificationMirrorResult()
    {
    }
    internal static RepositoryTreeQualificationMirrorResult Qualified(RepositoryTreeModelMirror model) => new QualifiedCase(model ?? throw new ArgumentNullException(nameof(model)));
    internal static RepositoryTreeQualificationMirrorResult Rejected(string failureCode) => new RejectedCase(string.IsNullOrWhiteSpace(failureCode) ? throw new ArgumentException(null, nameof(failureCode)) : failureCode);
    internal abstract TResult Accept<TResult>(IRepositoryTreeQualificationMirrorResultVisitor<TResult> visitor);
    private sealed class QualifiedCase(RepositoryTreeModelMirror model) :
        RepositoryTreeQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(IRepositoryTreeQualificationMirrorResultVisitor<TResult> visitor) => visitor.VisitQualified(model);
    }
    private sealed class RejectedCase(string failureCode) :
        RepositoryTreeQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(IRepositoryTreeQualificationMirrorResultVisitor<TResult> visitor) => visitor.VisitRejected(failureCode);
    }
}
internal interface IRepositoryTreeQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(RepositoryTreeModelMirror model);
    TResult VisitRejected(string failureCode);
}
internal sealed partial class RepositoryTreeCodecMirror
{
    internal const string InvalidTree = "protocol.codec.invalid-repository-tree";
    internal const string LocationMismatch =
        "protocol.codec.payload-location-mismatch";
    internal const string EmbeddedIdentityMismatch =
        "protocol.codec.embedded-identity-mismatch";
    internal const string ResourceLimit = "protocol.codec.resource-limit-exceeded";
    internal const int MaximumPayloadBytes = 16_777_216;
    private const int MaximumEntries = 200_000;
    private const int MaximumPathBytes = 16_777_216;
    private static readonly byte[] Header =
        Encoding.ASCII.GetBytes("protocol.repository-tree/1\n");
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);
    internal RepositoryTreeWriteMirrorResult WriteRepositoryTree(EvidenceScope scope, SnapshotEvidenceLocation location, IReadOnlyList<RepositoryTreePayloadEntryMirror> entries, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(entries);
        cancellationToken.ThrowIfCancellationRequested();
        var prepared = Prepare(scope, location, entries);
        if (prepared.Failure is not null)
        {
            return RepositoryTreeWriteMirrorResult.Rejected(prepared.Failure);
        }
        return Encode(prepared);
    }
    internal RepositoryTreeQualificationMirrorResult QualifyRepositoryTree(EvidenceBinding binding, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        cancellationToken.ThrowIfCancellationRequested();
        if (binding.Payload.CanonicalBytes.Count > MaximumPayloadBytes)
        {
            return Reject(ResourceLimit);
        }
        if (binding.Payload.SchemaKey != "protocol.repository-tree" || binding.Payload.SchemaVersion != "1")
        {
            return Reject(InvalidTree);
        }
        try
        {
            return Decode(binding);
        }
        catch (Exception exception) when (exception is ArgumentException or InvalidOperationException or
                OverflowException or DecoderFallbackException)
        {
            return Reject(InvalidTree);
        }
    }
    private static RepositoryTreeQualificationMirrorResult Decode(EvidenceBinding binding)
    {
        var reader = new Reader(binding.Payload.CanonicalBytes);
        reader.Expect(Header);
        var subject = reader.Text();
        var source = reader.Text();
        var surfaceText = reader.Text();
        var targetSnapshotText = reader.Text();
        var targetIdentity = reader.Text();
        var boundarySnapshotText = reader.Text();
        var boundaryIdentity = reader.Text();
        var started = new DateTimeOffset(reader.Int64(), TimeSpan.Zero);
        var completed = new DateTimeOffset(reader.Int64(), TimeSpan.Zero);
        var rank = reader.Byte();
        if (rank is 0 or 1 or 2)
        {
            return Reject(LocationMismatch);
        }
        if (rank != 3)
        {
            return Reject(InvalidTree);
        }
        var count = reader.UInt32();
        if (count > MaximumEntries)
        {
            return Reject(ResourceLimit);
        }
        var entries = new RepositoryTreePayloadEntryMirror[count];
        long pathBytes = 0;
        string? previous = null;
        for (var index = 0; index < entries.Length; index++)
        {
            var path = reader.Text(out var length);
            pathBytes += length;
            if (pathBytes > MaximumPathBytes)
            {
                return Reject(ResourceLimit);
            }
            if (!ValidPath(path) || previous is not null && StringComparer.Ordinal.Compare(previous, path) >= 0)
            {
                return Reject(InvalidTree);
            }
            var kind = Kind(reader.Byte());
            if (kind is null)
            {
                return Reject(InvalidTree);
            }
            entries[index] = RepositoryTreePayloadEntryMirror.Create(path, kind);
            previous = path;
        }
        if (!reader.End || !SurfaceKind.TryParse(surfaceText, out var surface) || !SnapshotKind.TryParse(targetSnapshotText, out var targetSnapshot) || !SnapshotKind.TryParse(boundarySnapshotText, out var boundarySnapshot))
        {
            return Reject(InvalidTree);
        }
        if (!surface.Equals(SurfaceKind.Repository))
        {
            return Reject(LocationMismatch);
        }
        var target = AcquisitionTarget.Create(subject, source, surface, targetSnapshot, targetIdentity);
        var boundary = AcquisitionBoundary.Create(boundarySnapshot, boundaryIdentity, started, completed);
        var scope = EvidenceScope.Create(target, boundary);
        var location = SnapshotEvidenceLocation.Create(scope);
        var model = RepositoryTreeModelMirror.Create(scope, location, entries);
        if (binding.Location is not SnapshotEvidenceLocation outer || !outer.Scope.Target.Surface.Equals(SurfaceKind.Repository))
        {
            return Reject(LocationMismatch);
        }
        return scope.Equals(outer.Scope) ? RepositoryTreeQualificationMirrorResult.Qualified(model) : Reject(EmbeddedIdentityMismatch);
    }
    private static Prepared Prepare(EvidenceScope scope, SnapshotEvidenceLocation location, IReadOnlyList<RepositoryTreePayloadEntryMirror> source)
    {
        if (!scope.Target.Surface.Equals(SurfaceKind.Repository))
        {
            return Prepared.Rejected(LocationMismatch);
        }
        if (!scope.Equals(location.Scope))
        {
            return Prepared.Rejected(EmbeddedIdentityMismatch);
        }
        if (source.Count > MaximumEntries)
        {
            return Prepared.Rejected(ResourceLimit);
        }
        var entries = new RepositoryTreePayloadEntryMirror[source.Count];
        var paths = new byte[source.Count][];
        long pathBytes = 0;
        string? previous = null;
        try
        {
            for (var index = 0; index < source.Count; index++)
            {
                var entry = source[index];
                if (entry is null)
                {
                    throw new ArgumentException("Repository-tree entries cannot contain null.", "entries");
                }
                var path = entry.RepositoryRelativePath;
                var encoded = StrictUtf8.GetBytes(path);
                pathBytes += encoded.Length;
                if (pathBytes > MaximumPathBytes)
                {
                    return Prepared.Rejected(ResourceLimit);
                }
                if (!ValidPath(path) || previous is not null && StringComparer.Ordinal.Compare(previous, path) >= 0 || KindByte(entry.Kind) < 0)
                {
                    return Prepared.Rejected(InvalidTree);
                }
                entries[index] = entry;
                paths[index] = encoded;
                previous = path;
            }
            var length = Header.Length + ScopeLength(scope) + 5;
            foreach (var path in paths)
            {
                length = checked(length + 5 + path.Length);
            }
            return length > MaximumPayloadBytes ? Prepared.Rejected(ResourceLimit) : Prepared.Accepted(scope, entries, paths, length);
        }
        catch (EncoderFallbackException)
        {
            return Prepared.Rejected(InvalidTree);
        }
        catch (OverflowException)
        {
            return Prepared.Rejected(ResourceLimit);
        }
    }
    private static RepositoryTreeWriteMirrorResult Encode(Prepared value)
    {
        using var stream = new MemoryStream(value.Length);
        stream.Write(Header);
        WriteText(stream, value.Scope.Target.SubjectIdentity);
        WriteText(stream, value.Scope.Target.SourceIdentity);
        WriteText(stream, value.Scope.Target.Surface.Value);
        WriteText(stream, value.Scope.Target.SnapshotKind.Value);
        WriteText(stream, value.Scope.Target.TargetIdentity);
        WriteText(stream, value.Scope.Boundary.SnapshotKind.Value);
        WriteText(stream, value.Scope.Boundary.BoundaryIdentity);
        WriteInt64(stream, value.Scope.Boundary.StartedAtUtc.UtcTicks);
        WriteInt64(stream, value.Scope.Boundary.CompletedAtUtc.UtcTicks);
        stream.WriteByte(3);
        WriteUInt32(stream, checked((uint)value.Entries.Length));
        for (var index = 0; index < value.Entries.Length; index++)
        {
            WriteUInt32(stream, checked((uint)value.Paths[index].Length));
            stream.Write(value.Paths[index]);
            stream.WriteByte(checked((byte)KindByte(value.Entries[index].Kind)));
        }
        var bytes = stream.ToArray();
        if (bytes.Length != value.Length)
        {
            throw new InvalidOperationException("Repository-tree length drifted.");
        }
        return RepositoryTreeWriteMirrorResult.Written(CanonicalEvidencePayload.Create("protocol.repository-tree", "1", bytes));
    }
    private static int ScopeLength(EvidenceScope scope) => TextLength(scope.Target.SubjectIdentity) + TextLength(scope.Target.SourceIdentity) + TextLength(scope.Target.Surface.Value) + TextLength(scope.Target.SnapshotKind.Value) + TextLength(scope.Target.TargetIdentity) + TextLength(scope.Boundary.SnapshotKind.Value) + TextLength(scope.Boundary.BoundaryIdentity) + 16;
    private static int TextLength(string value) => checked(4 + StrictUtf8.GetByteCount(value));
    private static void WriteText(Stream stream, string value)
    {
        var bytes = StrictUtf8.GetBytes(value);
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
    private static bool ValidPath(string path)
    {
        if (path.Length == 0 || path[0] == '/' || path[^1] == '/' || path.Contains('\\', StringComparison.Ordinal) || path.Length >= 2 && char.IsAsciiLetter(path[0]) && path[1] == ':')
        {
            return false;
        }
        return path.Split('/').All(segment => segment.Length > 0 && segment is not "." and not "..");
    }
    private static int KindByte(RepositoryEntryKind kind) => kind.Value switch
    {
        "directory" => 0,
        "file" => 1,
        "symbolic-link" => 2,
        "git-link" => 3,
        _ => -1,
    };
    private static RepositoryEntryKind? Kind(byte value) => value switch
    {
        0 => RepositoryEntryKind.Directory,
        1 => RepositoryEntryKind.File,
        2 => RepositoryEntryKind.SymbolicLink,
        3 => RepositoryEntryKind.GitLink,
        _ => null,
    };
    private static RepositoryTreeQualificationMirrorResult Reject(string code) => RepositoryTreeQualificationMirrorResult.Rejected(code);
    private sealed record Prepared(EvidenceScope Scope, RepositoryTreePayloadEntryMirror[] Entries, byte[][] Paths, int Length, string? Failure)
    {
        internal static Prepared Accepted(EvidenceScope scope, RepositoryTreePayloadEntryMirror[] entries, byte[][] paths, int length) => new(scope, entries, paths, length, null);
        internal static Prepared Rejected(string failure) => new(null!, [], [], 0, failure);
    }
    private ref struct Reader
    {
        private readonly ReadOnlySpan<byte> _bytes;
        private int _offset;
        internal Reader(IReadOnlyList<byte> bytes)
        {
            _bytes = bytes.ToArray();
            _offset = 0;
        }
        internal bool End => _offset == _bytes.Length;
        internal void Expect(ReadOnlySpan<byte> expected)
        {
            if (!Read(expected.Length).SequenceEqual(expected))
            {
                throw new InvalidOperationException("Unexpected header.");
            }
        }
        internal string Text() => Text(out _);
        internal string Text(out int encodedLength)
        {
            var length = UInt32();
            if (length > int.MaxValue)
            {
                throw new InvalidOperationException("Invalid text length.");
            }
            encodedLength = checked((int)length);
            var value = StrictUtf8.GetString(Read(encodedLength));
            return value.Contains('\uFEFF', StringComparison.Ordinal)
                ? throw new InvalidOperationException("UTF-8 BOM is forbidden.")
                : value;
        }
        internal uint UInt32() => BinaryPrimitives.ReadUInt32BigEndian(Read(4));
        internal long Int64() => BinaryPrimitives.ReadInt64BigEndian(Read(8));
        internal byte Byte() => Read(1)[0];
        private ReadOnlySpan<byte> Read(int count)
        {
            if (count < 0 || count > _bytes.Length - _offset)
            {
                throw new InvalidOperationException("Payload ended early.");
            }
            var value = _bytes.Slice(_offset, count);
            _offset += count;
            return value;
        }
    }
}
