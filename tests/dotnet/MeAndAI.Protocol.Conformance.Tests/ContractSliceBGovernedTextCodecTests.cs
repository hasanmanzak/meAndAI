using System.Buffers.Binary;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBGovernedTextCodecTests
{
    private const string Identity =
        "0123456789abcdef0123456789abcdef01234567";
    private const string OtherIdentity =
        "1123456789abcdef0123456789abcdef01234567";
    private const string ProviderBoundaryIdentity =
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    private const string RepositoryBase64 =
        "cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQAAAAAOZG9jcy9ib2R5LnRleHQBAAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAJYWxwaGEKzrIK";
    private const string EmptyBase64 =
        "cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQAAAAAOZG9jcy9ib2R5LnRleHQBAAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAAAAAAA";
    private const string ProviderBase64 =
        "cHJvdG9jb2wuZ292ZXJuZWQtdGV4dC8xCgAAAAhwcm92aWRlcgAAAAZnaXRodWIAAAAIcHJvdmlkZXIAAAAOcHJvdmlkZXItZXZlbnQAAAAIZXZlbnQtNDIAAAAOcHJvdmlkZXItZXZlbnQAAABAMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZgAAAAAAAAAAAAAAAAAAAAEBAAAABmdpdGh1YgAAAA5wcm92aWRlci5pc3N1ZQAAAAhvYmplY3Q0MgAAAAl2ZXJzaW9uLTcBAAAABGJvZHkAAAAAAA5wcm92aWRlciBib2R5Cg==";

    [Fact]
    [Trait("ContractSlice", "B")]
    public void Round_trips_exact_governed_text_wire()
    {
        var codec = new GovernedTextCodecMirror();
        var repository = Repository();
        var repositoryPayload = Written(Write(codec, repository));
        var repositoryGolden = Convert.FromBase64String(RepositoryBase64);
        var emptyGolden = Convert.FromBase64String(EmptyBase64);
        var providerGolden = Convert.FromBase64String(ProviderBase64);

        Assert.Throws<ArgumentNullException>(() => codec.WriteGovernedText(
            null!, repository.Location, repository.Body, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteGovernedText(
            repository.Scope, null!, repository.Body, CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() => codec.WriteGovernedText(
            repository.Scope, repository.Location, repository.Body, new CancellationToken(true)));
        Assert.Throws<ArgumentNullException>(() => codec.QualifyGovernedText(null!, CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() => codec.QualifyGovernedText(
            Bind(repositoryPayload, repository.Location), new CancellationToken(true)));

        Assert.Equal("protocol.governed-text", repositoryPayload.SchemaKey);
        Assert.Equal("1", repositoryPayload.SchemaVersion);
        Assert.Equal(repositoryGolden, repositoryPayload.CanonicalBytes);
        Assert.Equal("93261D439E5D04624BC1F832077CEB9BBD2CA7B83B1CF7EEE0EA679553CECDAA",
            Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(repositoryGolden)));
        AssertModel(Qualified(Qualify(codec, repository, repositoryPayload)), repository);

        var emptyPayload = Written(codec.WriteGovernedText(
            repository.Scope,
            repository.Location,
            ReadOnlyMemory<byte>.Empty,
            CancellationToken.None));
        Assert.Equal(emptyGolden, emptyPayload.CanonicalBytes);
        Assert.Empty(Qualified(Qualify(codec, repository, emptyPayload)).Body.ToArray());
        var noBlobLocation = RepositoryEvidenceLocation.Create(
            repository.Scope, "docs/body.text", null, null, null, null);
        var noBlob = new FixtureData(repository.Scope, noBlobLocation, repository.Body);
        AssertModel(Qualified(Qualify(codec, noBlob, Written(Write(codec, noBlob)))), noBlob);

        var provider = Provider();
        var providerPayload = Written(Write(codec, provider));
        Assert.Equal(providerGolden, providerPayload.CanonicalBytes);
        Assert.Equal("D75DBDC44A92B21AADF730B6E5D65A992E74C8847F613DC7D378CA1F6B104F5E",
            Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(providerGolden)));
        AssertModel(Qualified(Qualify(codec, provider, providerPayload)), provider);

        var other = Repository(OtherIdentity);
        WriteRejected(codec.WriteGovernedText(repository.Scope, other.Location,
            repository.Body, CancellationToken.None), GovernedTextCodecMirror.EmbeddedIdentityMismatch);
        QualifyRejected(Qualify(codec, repository, Written(Write(codec, other))),
            GovernedTextCodecMirror.EmbeddedIdentityMismatch);

        WriteRejected(codec.WriteGovernedText(repository.Scope,
            SnapshotEvidenceLocation.Create(repository.Scope), repository.Body,
            CancellationToken.None), GovernedTextCodecMirror.LocationMismatch);
        foreach (var refinement in new EvidenceLocation[]
        {
            RepositoryEvidenceLocation.Create(repository.Scope, "docs/body.text", Identity, 1, null, null),
            RepositoryEvidenceLocation.Create(repository.Scope, "docs/body.text", Identity, null, "anchor", null),
            RepositoryEvidenceLocation.Create(repository.Scope, "docs/body.text", Identity, null, null, "property"),
        })
        {
            WriteRejected(codec.WriteGovernedText(repository.Scope, refinement,
                repository.Body, CancellationToken.None), GovernedTextCodecMirror.LocationMismatch);
        }

        var providerNoField = Provider(field: null);
        var providerLine = Provider(line: 1);
        var providerFragment = Provider(fragment: "fragment");
        var workflow = Provider(surface: SurfaceKind.Workflow);
        foreach (var invalid in new[]
        {
            providerNoField,
            providerLine,
            providerFragment,
            workflow,
        })
        {
            WriteRejected(Write(codec, invalid), GovernedTextCodecMirror.LocationMismatch);
        }

        WriteRejected(codec.WriteGovernedText(repository.Scope, repository.Location,
            new byte[] { 0xC3, 0x28 }, CancellationToken.None), GovernedTextCodecMirror.InvalidUtf8);
        WriteRejected(codec.WriteGovernedText(repository.Scope, repository.Location,
            new byte[] { 0xEF, 0xBB, 0xBF, (byte)'x' }, CancellationToken.None),
            GovernedTextCodecMirror.NonCanonical);
        WriteRejected(codec.WriteGovernedText(repository.Scope, repository.Location,
            new byte[GovernedTextCodecMirror.MaximumBodyBytes + 1], CancellationToken.None),
            GovernedTextCodecMirror.ResourceLimit);

        var equalityBody = Enumerable.Repeat(
            (byte)'x',
            GovernedTextCodecMirror.MaximumPayloadBytes - emptyGolden.Length)
            .ToArray();
        var equalityPayload = Written(codec.WriteGovernedText(
            repository.Scope,
            repository.Location,
            equalityBody,
            CancellationToken.None));
        Assert.Equal(
            GovernedTextCodecMirror.MaximumPayloadBytes,
            equalityPayload.CanonicalBytes.Count);
        WriteRejected(
            codec.WriteGovernedText(
                repository.Scope,
                repository.Location,
                equalityBody.Append((byte)'x').ToArray(),
                CancellationToken.None),
            GovernedTextCodecMirror.ResourceLimit);
        WriteRejected(
            codec.WriteGovernedText(
                repository.Scope,
                repository.Location,
                Enumerable.Repeat(
                    (byte)'x',
                    GovernedTextCodecMirror.MaximumBodyBytes).ToArray(),
                CancellationToken.None),
            GovernedTextCodecMirror.ResourceLimit);
        QualifyRejected(
            Qualify(
                codec,
                repository,
                Payload(new byte[GovernedTextCodecMirror.MaximumPayloadBytes + 1])),
            GovernedTextCodecMirror.ResourceLimit);

        foreach (var length in Enumerable.Range(0, repositoryGolden.Length))
        {
            NonCanonical(
                codec,
                repository,
                repositoryGolden.AsSpan(0, length).ToArray());
        }
        foreach (var length in Enumerable.Range(0, providerGolden.Length))
        {
            NonCanonical(
                codec,
                provider,
                providerGolden.AsSpan(0, length).ToArray());
        }

        foreach (var malformed in new[]
        {
            SetByte(repositoryGolden, 0, (byte)'x'),
            SetUInt32(repositoryGolden, 25, uint.MaxValue),
            SetByte(repositoryGolden, 190, 4),
            SetByte(repositoryGolden, 254, 2),
            SetByte(repositoryGolden, 255, 2),
            SetByte(repositoryGolden, 256, 2),
            SetUInt32(repositoryGolden, 257, 10),
            [.. repositoryGolden, (byte)0],
            SetByte(providerGolden, 245, 2),
            SetByte(providerGolden, 254, 2),
            SetByte(providerGolden, 255, 2),
        })
        {
            var fixture = malformed.Length == providerGolden.Length &&
                malformed.AsSpan(0, 25).SequenceEqual(providerGolden.AsSpan(0, 25))
                    ? provider
                    : repository;
            NonCanonical(codec, fixture, malformed);
        }

        foreach (var invalidUtf8 in new[]
        {
            ReplaceText(repositoryGolden, 25, 29, 4, [0xC3, 0x28]),
            ReplaceText(repositoryGolden, 25, 29, 4, [0xC0, 0xAF]),
            ReplaceText(repositoryGolden, 25, 29, 4, [0xED, 0xA0, 0x80]),
            ReplaceBody(repositoryGolden, 257, 261, 9, [0xC3, 0x28]),
            ReplaceBody(repositoryGolden, 257, 261, 9, [0xC0, 0xAF]),
            ReplaceBody(repositoryGolden, 257, 261, 9, [0xED, 0xA0, 0x80]),
        })
        {
            QualifyRejected(
                Qualify(codec, repository, Payload(invalidUtf8)),
                GovernedTextCodecMirror.InvalidUtf8);
        }

        foreach (var bom in new[]
        {
            ReplaceText(repositoryGolden, 25, 29, 4, [0xEF, 0xBB, 0xBF]),
            ReplaceText(repositoryGolden, 191, 195, 14, [0xEF, 0xBB, 0xBF]),
            ReplaceBody(repositoryGolden, 257, 261, 9, [0xEF, 0xBB, 0xBF]),
        })
        {
            NonCanonical(codec, repository, bom);
        }

        foreach (var mismatch in new[]
        {
            ReplaceText(repositoryGolden, 40, 44, 10, Utf8("workflow")),
            SetByte(repositoryGolden, 190, 2),
            SetByte(repositoryGolden, 190, 3),
            ReplaceBytes(repositoryGolden, 254, 1, [1, 0, 0, 0, 1]),
            ReplaceBytes(repositoryGolden, 255, 1, [1, 0, 0, 0, 1, (byte)'a']),
            ReplaceBytes(repositoryGolden, 256, 1, [1, 0, 0, 0, 1, (byte)'p']),
        })
        {
            QualifyRejected(
                Qualify(codec, repository, Payload(mismatch)),
                GovernedTextCodecMirror.LocationMismatch);
        }
        foreach (var mismatch in new[]
        {
            ReplaceText(providerGolden, 47, 51, 8, Utf8("workflow")),
            ReplaceBytes(providerGolden, 245, 9, [0]),
            ReplaceBytes(providerGolden, 254, 1, [1, 0, 0, 0, 1]),
            ReplaceBytes(providerGolden, 255, 1, [1, 0, 0, 0, 1, (byte)'f']),
        })
        {
            QualifyRejected(
                Qualify(codec, provider, Payload(mismatch)),
                GovernedTextCodecMirror.LocationMismatch);
        }

        QualifyRejected(
            Qualify(
                codec,
                repository,
                CanonicalEvidencePayload.Create(
                    "protocol.other",
                    "1",
                    repositoryGolden)),
            GovernedTextCodecMirror.NonCanonical);
        QualifyRejected(
            Qualify(
                codec,
                repository,
                CanonicalEvidencePayload.Create(
                    "protocol.governed-text",
                    "2",
                    repositoryGolden)),
            GovernedTextCodecMirror.NonCanonical);

        var mutableBody = Utf8("alpha\nβ\n");
        var retainedPayload = Written(codec.WriteGovernedText(
            repository.Scope,
            repository.Location,
            mutableBody,
            CancellationToken.None));
        mutableBody[0] = (byte)'z';
        Assert.Equal(repositoryGolden, retainedPayload.CanonicalBytes);
        var retainedModel = Qualified(Qualify(codec, repository, retainedPayload));
        var exposed = retainedModel.Body.ToArray();
        exposed[0] = (byte)'z';
        Assert.Equal(Utf8("alpha\nβ\n"), retainedModel.Body.ToArray());
    }

    private static GovernedTextWriteMirrorResult Write(
        GovernedTextCodecMirror codec,
        FixtureData fixture) => codec.WriteGovernedText(
            fixture.Scope,
            fixture.Location,
            fixture.Body,
            CancellationToken.None);

    private static GovernedTextQualificationMirrorResult Qualify(
        GovernedTextCodecMirror codec,
        FixtureData fixture,
        CanonicalEvidencePayload payload) => codec.QualifyGovernedText(
            Bind(payload, fixture.Location),
            CancellationToken.None);

    private static EvidenceBinding Bind(
        CanonicalEvidencePayload payload,
        EvidenceLocation location) => EvidenceBinding.Create(
            payload,
            location,
            ["protocol.requirement"],
            new DateTimeOffset(1, TimeSpan.Zero));

    private static CanonicalEvidencePayload Payload(byte[] bytes) =>
        CanonicalEvidencePayload.Create("protocol.governed-text", "1", bytes);

    private static FixtureData Repository(string identity = Identity)
    {
        var target = AcquisitionTarget.Create(
            "repo",
            "git",
            SurfaceKind.Repository,
            SnapshotKind.ExactCommit,
            identity);
        var boundary = AcquisitionBoundary.Create(
            SnapshotKind.ExactCommit,
            identity,
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero));
        var scope = EvidenceScope.Create(target, boundary);
        var location = RepositoryEvidenceLocation.Create(
            scope,
            "docs/body.text",
            identity,
            null,
            null,
            null);
        return new FixtureData(scope, location, Utf8("alpha\nβ\n"));
    }

    private static FixtureData Provider(
        string? field = "body",
        int? line = null,
        string? fragment = null,
        SurfaceKind? surface = null)
    {
        var target = AcquisitionTarget.Create(
            "provider",
            "github",
            surface ?? SurfaceKind.Provider,
            SnapshotKind.ProviderEvent,
            "event-42");
        var boundary = AcquisitionBoundary.Create(
            SnapshotKind.ProviderEvent,
            ProviderBoundaryIdentity,
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero));
        var scope = EvidenceScope.Create(target, boundary);
        var location = ProviderEvidenceLocation.Create(
            scope,
            "github",
            "provider.issue",
            "object42",
            "version-7",
            field,
            line,
            fragment);
        return new FixtureData(scope, location, Utf8("provider body\n"));
    }

    private static CanonicalEvidencePayload Written(
        GovernedTextWriteMirrorResult result)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<CanonicalEvidencePayload>(value.Payload);
    }

    private static void WriteRejected(
        GovernedTextWriteMirrorResult result,
        string expected)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Payload);
        Assert.Equal(expected, value.Failure);
    }

    private static GovernedTextModelMirror Qualified(
        GovernedTextQualificationMirrorResult result)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<GovernedTextModelMirror>(value.Model);
    }

    private static void QualifyRejected(
        GovernedTextQualificationMirrorResult result,
        string expected)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Model);
        Assert.Equal(expected, value.Failure);
    }

    private static void NonCanonical(
        GovernedTextCodecMirror codec,
        FixtureData fixture,
        byte[] bytes) => QualifyRejected(
            Qualify(codec, fixture, Payload(bytes)),
            GovernedTextCodecMirror.NonCanonical);

    private static void AssertModel(
        GovernedTextModelMirror model,
        FixtureData fixture)
    {
        Assert.Equal(fixture.Scope, model.Scope);
        Assert.Equal(fixture.Location, model.Location);
        Assert.Equal(fixture.Body, model.Body.ToArray());
    }

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

    private static byte[] ReplaceText(
        byte[] source,
        int lengthOffset,
        int dataOffset,
        int oldLength,
        byte[] replacement)
    {
        var result = ReplaceBytes(source, dataOffset, oldLength, replacement);
        BinaryPrimitives.WriteUInt32BigEndian(
            result.AsSpan(lengthOffset, 4),
            checked((uint)replacement.Length));
        return result;
    }

    private static byte[] ReplaceBody(
        byte[] source,
        int lengthOffset,
        int dataOffset,
        int oldLength,
        byte[] replacement) => ReplaceText(
            source,
            lengthOffset,
            dataOffset,
            oldLength,
            replacement);

    private static byte[] ReplaceBytes(
        byte[] source,
        int offset,
        int oldLength,
        byte[] replacement)
    {
        var result = new byte[source.Length - oldLength + replacement.Length];
        source.AsSpan(0, offset).CopyTo(result);
        replacement.CopyTo(result, offset);
        source.AsSpan(offset + oldLength).CopyTo(
            result.AsSpan(offset + replacement.Length));
        return result;
    }

    private sealed record FixtureData(
        EvidenceScope Scope,
        EvidenceLocation Location,
        byte[] Body);

    private sealed record WriteValue(
        CanonicalEvidencePayload? Payload,
        string? Failure);

    private sealed class WriteObserver :
        IGovernedTextWriteMirrorResultVisitor<WriteValue>
    {
        internal static WriteObserver Instance { get; } = new();
        public WriteValue VisitWritten(CanonicalEvidencePayload payload) =>
            new(payload, null);
        public WriteValue VisitRejected(string failureCode) =>
            new(null, failureCode);
    }

    private sealed record QualificationValue(
        GovernedTextModelMirror? Model,
        string? Failure);

    private sealed class QualificationObserver :
        IGovernedTextQualificationMirrorResultVisitor<QualificationValue>
    {
        internal static QualificationObserver Instance { get; } = new();
        public QualificationValue VisitQualified(GovernedTextModelMirror model) =>
            new(model, null);
        public QualificationValue VisitRejected(string failureCode) =>
            new(null, failureCode);
    }
}

internal sealed partial class GovernedTextModelMirror
{
    private GovernedTextModelMirror(
        EvidenceScope scope,
        EvidenceLocation location,
        byte[] body)
    {
        Scope = scope;
        Location = location;
        Body = body;
    }

    internal EvidenceScope Scope { get; }
    internal EvidenceLocation Location { get; }
    internal ReadOnlyMemory<byte> Body { get; }

    internal static GovernedTextModelMirror Create(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        if (!scope.Equals(location.Scope))
        {
            throw new ArgumentException(
                "The location must retain the supplied scope.",
                nameof(location));
        }
        return new GovernedTextModelMirror(scope, location, body.ToArray());
    }
}

internal abstract class GovernedTextWriteMirrorResult
{
    private GovernedTextWriteMirrorResult()
    {
    }

    internal static GovernedTextWriteMirrorResult Written(
        CanonicalEvidencePayload payload) => new WrittenCase(
            payload ?? throw new ArgumentNullException(nameof(payload)));

    internal static GovernedTextWriteMirrorResult Rejected(
        string failureCode) => new RejectedCase(
            string.IsNullOrWhiteSpace(failureCode)
                ? throw new ArgumentException(null, nameof(failureCode))
                : failureCode);

    internal abstract TResult Accept<TResult>(
        IGovernedTextWriteMirrorResultVisitor<TResult> visitor);

    private sealed class WrittenCase(CanonicalEvidencePayload payload) :
        GovernedTextWriteMirrorResult
    {
        internal override TResult Accept<TResult>(
            IGovernedTextWriteMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitWritten(payload);
    }

    private sealed class RejectedCase(string failureCode) :
        GovernedTextWriteMirrorResult
    {
        internal override TResult Accept<TResult>(
            IGovernedTextWriteMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitRejected(failureCode);
    }
}

internal interface IGovernedTextWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}

internal abstract class GovernedTextQualificationMirrorResult
{
    private GovernedTextQualificationMirrorResult()
    {
    }

    internal static GovernedTextQualificationMirrorResult Qualified(
        GovernedTextModelMirror model) => new QualifiedCase(
            model ?? throw new ArgumentNullException(nameof(model)));

    internal static GovernedTextQualificationMirrorResult Rejected(
        string failureCode) => new RejectedCase(
            string.IsNullOrWhiteSpace(failureCode)
                ? throw new ArgumentException(null, nameof(failureCode))
                : failureCode);

    internal abstract TResult Accept<TResult>(
        IGovernedTextQualificationMirrorResultVisitor<TResult> visitor);

    private sealed class QualifiedCase(GovernedTextModelMirror model) :
        GovernedTextQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(
            IGovernedTextQualificationMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitQualified(model);
    }

    private sealed class RejectedCase(string failureCode) :
        GovernedTextQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(
            IGovernedTextQualificationMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitRejected(failureCode);
    }
}

internal interface IGovernedTextQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(GovernedTextModelMirror model);
    TResult VisitRejected(string failureCode);
}

internal sealed partial class GovernedTextCodecMirror
{
    internal const string InvalidUtf8 = "protocol.codec.invalid-utf8";
    internal const string NonCanonical = "protocol.codec.noncanonical-encoding";
    internal const string LocationMismatch =
        "protocol.codec.payload-location-mismatch";
    internal const string EmbeddedIdentityMismatch =
        "protocol.codec.embedded-identity-mismatch";
    internal const string ResourceLimit = "protocol.codec.resource-limit-exceeded";
    internal const int MaximumBodyBytes = 4_194_304;
    internal const int MaximumPayloadBytes = 4_194_304;

    private static readonly byte[] Header =
        Encoding.ASCII.GetBytes("protocol.governed-text/1\n");
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    internal GovernedTextWriteMirrorResult WriteGovernedText(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        cancellationToken.ThrowIfCancellationRequested();
        if (body.Length > MaximumBodyBytes)
        {
            return RejectWrite(ResourceLimit);
        }
        try
        {
            var prepared = Prepare(scope, location, body);
            if (prepared.Failure is not null)
            {
                return RejectWrite(prepared.Failure);
            }
            return Encode(prepared);
        }
        catch (Exception exception) when (exception is DecoderFallbackException or EncoderFallbackException)
        {
            return RejectWrite(InvalidUtf8);
        }
        catch (InvalidUtf8Signal)
        {
            return RejectWrite(InvalidUtf8);
        }
        catch (NonCanonicalSignal)
        {
            return RejectWrite(NonCanonical);
        }
        catch (OverflowException)
        {
            return RejectWrite(ResourceLimit);
        }
    }

    internal GovernedTextQualificationMirrorResult QualifyGovernedText(
        EvidenceBinding binding,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        cancellationToken.ThrowIfCancellationRequested();
        if (binding.Payload.CanonicalBytes.Count > MaximumPayloadBytes)
        {
            return RejectQualification(ResourceLimit);
        }
        if (binding.Payload.SchemaKey != "protocol.governed-text" ||
            binding.Payload.SchemaVersion != "1")
        {
            return RejectQualification(NonCanonical);
        }
        try
        {
            return Decode(binding);
        }
        catch (Exception exception) when (exception is InvalidUtf8Signal or DecoderFallbackException)
        {
            return RejectQualification(InvalidUtf8);
        }
        catch (ResourceLimitSignal)
        {
            return RejectQualification(ResourceLimit);
        }
        catch (Exception exception) when (
            exception is NonCanonicalSignal or ArgumentException or
            InvalidOperationException or OverflowException)
        {
            return RejectQualification(NonCanonical);
        }
    }

    private static Prepared Prepare(
        EvidenceScope scope,
        EvidenceLocation location,
        ReadOnlyMemory<byte> body)
    {
        var locationLength = LocationLength(scope, location, out var failure);
        if (failure is not null)
        {
            return Prepared.Rejected(failure);
        }
        if (!scope.Equals(location.Scope))
        {
            return Prepared.Rejected(EmbeddedIdentityMismatch);
        }
        ValidateBody(body.Span);
        var length = checked(
            Header.Length + ScopeLength(scope) + locationLength + 4 + body.Length);
        return length > MaximumPayloadBytes
            ? Prepared.Rejected(ResourceLimit)
            : Prepared.Accepted(scope, location, body, length);
    }

    private static int LocationLength(
        EvidenceScope scope,
        EvidenceLocation location,
        out string? failure)
    {
        failure = null;
        if (location is RepositoryEvidenceLocation repository)
        {
            if (!scope.Target.Surface.Equals(SurfaceKind.Repository) ||
                repository.Line is not null ||
                repository.Anchor is not null ||
                repository.Property is not null)
            {
                failure = LocationMismatch;
                return 0;
            }
            return checked(
                1 + TextLength(repository.RepositoryRelativePath) +
                OptionalTextLength(repository.BlobIdentity) + 3);
        }
        if (location is ProviderEvidenceLocation provider)
        {
            if (!scope.Target.Surface.Equals(SurfaceKind.Provider) ||
                provider.Field is null ||
                provider.Line is not null ||
                provider.Fragment is not null)
            {
                failure = LocationMismatch;
                return 0;
            }
            return checked(
                1 + TextLength(provider.ProviderServiceIdentity) +
                TextLength(provider.ObjectType) +
                TextLength(provider.StableObjectIdentity) +
                TextLength(provider.VersionIdentity) +
                OptionalTextLength(provider.Field) + 2);
        }
        failure = LocationMismatch;
        return 0;
    }

    private static GovernedTextWriteMirrorResult Encode(Prepared value)
    {
        using var stream = new MemoryStream(value.Length);
        stream.Write(Header);
        WriteScope(stream, value.Scope);
        switch (value.Location)
        {
            case RepositoryEvidenceLocation repository:
                stream.WriteByte(0);
                WriteText(stream, repository.RepositoryRelativePath);
                WriteOptionalText(stream, repository.BlobIdentity);
                WriteOptionalInt32(stream, repository.Line);
                WriteOptionalText(stream, repository.Anchor);
                WriteOptionalText(stream, repository.Property);
                break;
            case ProviderEvidenceLocation provider:
                stream.WriteByte(1);
                WriteText(stream, provider.ProviderServiceIdentity);
                WriteText(stream, provider.ObjectType);
                WriteText(stream, provider.StableObjectIdentity);
                WriteText(stream, provider.VersionIdentity);
                WriteOptionalText(stream, provider.Field);
                WriteOptionalInt32(stream, provider.Line);
                WriteOptionalText(stream, provider.Fragment);
                break;
            default:
                throw new InvalidOperationException("Unsupported governed-text location.");
        }
        WriteUInt32(stream, checked((uint)value.Body.Length));
        stream.Write(value.Body.Span);
        var bytes = stream.ToArray();
        if (bytes.Length != value.Length)
        {
            throw new InvalidOperationException("Governed-text length drifted.");
        }
        return GovernedTextWriteMirrorResult.Written(
            CanonicalEvidencePayload.Create("protocol.governed-text", "1", bytes));
    }

    private static GovernedTextQualificationMirrorResult Decode(
        EvidenceBinding binding)
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
        var startedTicks = reader.Int64();
        var completedTicks = reader.Int64();
        var rank = reader.Byte();

        LocationFrame location;
        switch (rank)
        {
            case 0:
                location = LocationFrame.Repository(
                    reader.Text(),
                    reader.OptionalText(),
                    reader.OptionalInt32(),
                    reader.OptionalText(),
                    reader.OptionalText());
                break;
            case 1:
                location = LocationFrame.Provider(
                    reader.Text(),
                    reader.Text(),
                    reader.Text(),
                    reader.Text(),
                    reader.OptionalText(),
                    reader.OptionalInt32(),
                    reader.OptionalText());
                break;
            case 2:
            case 3:
                return RejectQualification(LocationMismatch);
            default:
                throw new NonCanonicalSignal();
        }

        var body = reader.Body();
        if (!reader.End)
        {
            throw new NonCanonicalSignal();
        }
        ValidateBody(body);
        if (!SurfaceKind.TryParse(surfaceText, out var surface) ||
            !SnapshotKind.TryParse(targetSnapshotText, out var targetSnapshot) ||
            !SnapshotKind.TryParse(boundarySnapshotText, out var boundarySnapshot))
        {
            throw new NonCanonicalSignal();
        }
        if (rank == 0 &&
            (!surface.Equals(SurfaceKind.Repository) ||
             location.Line is not null ||
             location.FirstOptional is not null ||
             location.SecondOptional is not null) ||
            rank == 1 &&
            (!surface.Equals(SurfaceKind.Provider) ||
             location.FirstOptional is null ||
             location.Line is not null ||
             location.SecondOptional is not null))
        {
            return RejectQualification(LocationMismatch);
        }

        var target = AcquisitionTarget.Create(
            subject,
            source,
            surface,
            targetSnapshot,
            targetIdentity);
        var boundary = AcquisitionBoundary.Create(
            boundarySnapshot,
            boundaryIdentity,
            new DateTimeOffset(startedTicks, TimeSpan.Zero),
            new DateTimeOffset(completedTicks, TimeSpan.Zero));
        var scope = EvidenceScope.Create(target, boundary);
        EvidenceLocation decodedLocation = rank == 0
            ? RepositoryEvidenceLocation.Create(
                scope,
                location.A,
                location.B,
                location.Line,
                location.FirstOptional,
                location.SecondOptional)
            : ProviderEvidenceLocation.Create(
                scope,
                location.A,
                location.B!,
                location.C!,
                location.D!,
                location.FirstOptional,
                location.Line,
                location.SecondOptional);

        if (rank == 0 && binding.Location is not RepositoryEvidenceLocation ||
            rank == 1 && binding.Location is not ProviderEvidenceLocation ||
            rank == 0 && !binding.Location.Scope.Target.Surface.Equals(
                SurfaceKind.Repository) ||
            rank == 1 && !binding.Location.Scope.Target.Surface.Equals(
                SurfaceKind.Provider))
        {
            return RejectQualification(LocationMismatch);
        }
        if (!scope.Equals(binding.Location.Scope))
        {
            return RejectQualification(EmbeddedIdentityMismatch);
        }
        return GovernedTextQualificationMirrorResult.Qualified(
            GovernedTextModelMirror.Create(scope, decodedLocation, body));
    }

    private static int ScopeLength(EvidenceScope scope) => checked(
        TextLength(scope.Target.SubjectIdentity) +
        TextLength(scope.Target.SourceIdentity) +
        TextLength(scope.Target.Surface.Value) +
        TextLength(scope.Target.SnapshotKind.Value) +
        TextLength(scope.Target.TargetIdentity) +
        TextLength(scope.Boundary.SnapshotKind.Value) +
        TextLength(scope.Boundary.BoundaryIdentity) + 16);

    private static int TextLength(string value)
    {
        if (value.StartsWith('\uFEFF'))
        {
            throw new NonCanonicalSignal();
        }
        return checked(4 + StrictUtf8.GetByteCount(value));
    }

    private static int OptionalTextLength(string? value) =>
        value is null ? 1 : checked(1 + TextLength(value));

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

    private static void ValidateBody(ReadOnlySpan<byte> body)
    {
        try
        {
            StrictUtf8.GetCharCount(body);
        }
        catch (DecoderFallbackException exception)
        {
            throw new InvalidUtf8Signal(exception);
        }
        if (body.StartsWith(new byte[] { 0xEF, 0xBB, 0xBF }))
        {
            throw new NonCanonicalSignal();
        }
    }

    private static GovernedTextWriteMirrorResult RejectWrite(string code) =>
        GovernedTextWriteMirrorResult.Rejected(code);

    private static GovernedTextQualificationMirrorResult RejectQualification(
        string code) => GovernedTextQualificationMirrorResult.Rejected(code);

    private sealed record Prepared(
        EvidenceScope Scope,
        EvidenceLocation Location,
        ReadOnlyMemory<byte> Body,
        int Length,
        string? Failure)
    {
        internal static Prepared Accepted(
            EvidenceScope scope,
            EvidenceLocation location,
            ReadOnlyMemory<byte> body,
            int length) => new(scope, location, body, length, null);

        internal static Prepared Rejected(string failure) =>
            new(null!, null!, ReadOnlyMemory<byte>.Empty, 0, failure);
    }

    private sealed record LocationFrame(
        string A,
        string? B,
        string? C,
        string? D,
        string? FirstOptional,
        int? Line,
        string? SecondOptional)
    {
        internal static LocationFrame Repository(
            string path,
            string? blob,
            int? line,
            string? anchor,
            string? property) => new(
                path,
                blob,
                null,
                null,
                anchor,
                line,
                property);

        internal static LocationFrame Provider(
            string service,
            string objectType,
            string stableObject,
            string version,
            string? field,
            int? line,
            string? fragment) => new(
                service,
                objectType,
                stableObject,
                version,
                field,
                line,
                fragment);
    }

    private sealed class InvalidUtf8Signal(Exception inner) : Exception(null, inner);
    private sealed class NonCanonicalSignal : Exception;
    private sealed class ResourceLimitSignal : Exception;

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
                throw new NonCanonicalSignal();
            }
        }

        internal string Text()
        {
            var bytes = LengthPrefixed();
            string value;
            try
            {
                value = StrictUtf8.GetString(bytes);
            }
            catch (DecoderFallbackException exception)
            {
                throw new InvalidUtf8Signal(exception);
            }
            return value.StartsWith('\uFEFF')
                ? throw new NonCanonicalSignal()
                : value;
        }

        internal string? OptionalText()
        {
            var tag = Byte();
            return tag switch
            {
                0 => null,
                1 => Text(),
                _ => throw new NonCanonicalSignal(),
            };
        }

        internal int? OptionalInt32()
        {
            var tag = Byte();
            return tag switch
            {
                0 => null,
                1 => BinaryPrimitives.ReadInt32BigEndian(Read(4)),
                _ => throw new NonCanonicalSignal(),
            };
        }

        internal long Int64() => BinaryPrimitives.ReadInt64BigEndian(Read(8));
        internal byte Byte() => Read(1)[0];

        internal byte[] Body()
        {
            var body = LengthPrefixed();
            if (body.Length > MaximumBodyBytes)
            {
                throw new ResourceLimitSignal();
            }
            return body.ToArray();
        }

        private ReadOnlySpan<byte> LengthPrefixed()
        {
            var length = BinaryPrimitives.ReadUInt32BigEndian(Read(4));
            if (length > int.MaxValue)
            {
                throw new NonCanonicalSignal();
            }
            return Read(checked((int)length));
        }

        private ReadOnlySpan<byte> Read(int count)
        {
            if (count < 0 || count > _bytes.Length - _offset)
            {
                throw new NonCanonicalSignal();
            }
            var value = _bytes.Slice(_offset, count);
            _offset += count;
            return value;
        }
    }
}
