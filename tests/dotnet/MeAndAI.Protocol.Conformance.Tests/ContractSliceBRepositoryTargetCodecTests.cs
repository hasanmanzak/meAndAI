using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBRepositoryTargetCodecTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0005";
    private const string Owner = "https://github.com/owner/repo";
    private const string Commit =
        "0123456789abcdef0123456789abcdef01234567";
    private const string Capture =
        "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789";
    private const string CommitBlob =
        "1e0981f10f35ca8f594fec2a03f11df5a7299098";
    private const string CapturedContent =
        "c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1";
    private const string DemandDigest =
        "9df61ac4d5f82c5fda121b05319b16399580fc0a8d28b4ac62d1879d24899cba";
    private const string DemandBase64 =
        "cHJvdG9jb2wuYWNxdWlzaXRpb24tZGVtYW5kLzEKAQAAAAMAAAAAAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAEAAAAFaW50cm8AAAABAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAQAAAAJ2MQAAAAIAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8CAAAAQGFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODkAAAAMc3JjL2ZpbGUudHh0AAAAAkwx";
    private const string GoldenBase64 =
        "cHJvdG9jb2wucmVwb3NpdG9yeS10YXJnZXQtcmVzb2x1dGlvbi8xCgAAAARyZXBvAAAAA2dpdAAAAApyZXBvc2l0b3J5AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADGV4YWN0LWNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAAAAAAAAAAAAAAAAAAAQOd9hrE1fgsX9oSGwUxmxY5lYD8Co0otKxi0YedJImcugAAAAMAAAAAAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAEAAAAFaW50cm8BAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAABmNvbW1pdAAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AQAAAA5kb2NzL1JFQURNRS5tZAAAAARibG9iAAAAKDFlMDk4MWYxMGYzNWNhOGY1OTRmZWMyYTAzZjExZGY1YTcyOTkwOTgBAAAAAAAAAAEAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8BAAAAAnYxAQAAAB1odHRwczovL2dpdGh1Yi5jb20vb3duZXIvcmVwbwAAAAxyZWZzL3RhZ3MvdjEAAAADdGFnAAAAKDExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTEAAAAGY29tbWl0AAAAKDAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1NjcAAAACAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAgAAAEBhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5AAAADHNyYy9maWxlLnR4dAAAAAJMMQEAAAAdaHR0cHM6Ly9naXRodWIuY29tL293bmVyL3JlcG8AAABAYWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OQAAAAxzcmMvZmlsZS50eHQAAAAEZmlsZQAAAEBjNzNiNzNhZjg4NTFlOWU5MWJjNmI0ZGMxMmU3ZGFjZTBhMmJmYjkzMWMxZDBiOGIzNmVmMzY3MzE5ZjU4Y2QxAAAAAQAAAAIAAAAAAAAAAB1odHRwczovL2dpdGh1Yi5jb20vb3duZXIvcmVwbwAAACgwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3AAAADmRvY3MvUkVBRE1FLm1kAAAAKDFlMDk4MWYxMGYzNWNhOGY1OTRmZWMyYTAzZjExZGY1YTcyOTkwOTgAAAAIKooGu7SkLu5g814sbqyxw7vg+HSIF9FUellpJ4S1PDMjIEludHJvCgAAAAEBAAAAHWh0dHBzOi8vZ2l0aHViLmNvbS9vd25lci9yZXBvAAAAQGFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVmMDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODkAAAAMc3JjL2ZpbGUudHh0AAAAQGM3M2I3M2FmODg1MWU5ZTkxYmM2YjRkYzEyZTdkYWNlMGEyYmZiOTMxYzFkMGI4YjM2ZWYzNjczMTlmNThjZDEAAAAFxztzr4hR6ekbxrTcEufazgor+5McHQuLNu82cxn1jNFsaW5lCg==";

    [Fact]
    [Trait("ContractSlice", "B")]
    [Trait("Scenario", "TEST-0210")]
    public void Round_trips_exact_repository_target_resolution_wire()
    {
        var fixture = CreateFixture();
        var codec = new RepositoryTargetCodecMirror();
        var first = Write(codec, fixture);
        if (first is null)
        {
            Assert.Fail(Marker);
        }

        var demandBytes = Convert.FromBase64String(DemandBase64);
        var golden = Convert.FromBase64String(GoldenBase64);
        Assert.Equal(318, demandBytes.Length);
        Assert.Equal(
            DemandDigest.ToUpperInvariant(),
            Convert.ToHexString(SHA256.HashData(demandBytes)));

        var payload = Written(first);
        Assert.Equal("protocol.repository-target-resolution", payload.SchemaKey);
        Assert.Equal("1", payload.SchemaVersion);
        Assert.Equal(golden, payload.CanonicalBytes);
        Assert.Equal(
            "936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0",
            Convert.ToHexString(SHA256.HashData(golden)));

        var model = Qualified(Qualify(codec, fixture, payload));
        Assert.Equal(fixture.Scope, model.Scope);
        Assert.Equal(fixture.Location, model.Location);
        Assert.Equal(fixture.DemandDigest, model.DemandDigest);
        Assert.Equal(
            RepositoryTargetCodecMirror.EncodeDemand(fixture.DemandItems),
            RepositoryTargetCodecMirror.EncodeDemand(model.DemandItems));
        Assert.Equal(
            golden,
            Written(codec.WriteRepositoryTargetResolution(
                model.Scope,
                model.Location,
                model.DemandDigest,
                model.DemandItems,
                model.Rows,
                model.Contents,
                CancellationToken.None)).CanonicalBytes);

        AssertArgumentBoundaries(codec, fixture, payload);
        AssertVariantClosure(codec, fixture);
        AssertWriterRejections(codec, fixture);
        AssertQualifierRejections(codec, fixture, golden);
        AssertDefensiveCopies(codec, fixture, golden);
        AssertCountAndContentLimits(codec, fixture);
    }

    private static void AssertArgumentBoundaries(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        CanonicalEvidencePayload payload)
    {
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            null!, fixture.Location, fixture.DemandDigest, fixture.DemandItems,
            fixture.Rows, fixture.Contents, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            fixture.Scope, null!, fixture.DemandDigest, fixture.DemandItems,
            fixture.Rows, fixture.Contents, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            fixture.Scope, fixture.Location, null!, fixture.DemandItems,
            fixture.Rows, fixture.Contents, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            fixture.Scope, fixture.Location, fixture.DemandDigest, null!,
            fixture.Rows, fixture.Contents, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            fixture.Scope, fixture.Location, fixture.DemandDigest,
            fixture.DemandItems, null!, fixture.Contents, CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() => codec.WriteRepositoryTargetResolution(
            fixture.Scope, fixture.Location, fixture.DemandDigest,
            fixture.DemandItems, fixture.Rows, null!, CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() =>
            codec.WriteRepositoryTargetResolution(
                fixture.Scope, fixture.Location, fixture.DemandDigest,
                fixture.DemandItems, fixture.Rows, fixture.Contents,
                new CancellationToken(true)));
        Assert.Throws<ArgumentNullException>(() =>
            codec.QualifyRepositoryTargetResolution(
                null!, fixture.DemandDigest, fixture.DemandItems,
                CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() =>
            codec.QualifyRepositoryTargetResolution(
                Bind(payload, fixture.Location), null!, fixture.DemandItems,
                CancellationToken.None));
        Assert.Throws<ArgumentNullException>(() =>
            codec.QualifyRepositoryTargetResolution(
                Bind(payload, fixture.Location), fixture.DemandDigest, null!,
                CancellationToken.None));
        Assert.Throws<OperationCanceledException>(() =>
            codec.QualifyRepositoryTargetResolution(
                Bind(payload, fixture.Location), fixture.DemandDigest,
                fixture.DemandItems, new CancellationToken(true)));

        var nullDemand = Assert.Throws<ArgumentException>(() =>
            codec.WriteRepositoryTargetResolution(
                fixture.Scope, fixture.Location, fixture.DemandDigest,
                [null!], fixture.Rows, fixture.Contents,
                CancellationToken.None));
        Assert.Equal("demandItems", nullDemand.ParamName);
        var nullRow = Assert.Throws<ArgumentException>(() =>
            codec.WriteRepositoryTargetResolution(
                fixture.Scope, fixture.Location, fixture.DemandDigest,
                fixture.DemandItems, [null!], fixture.Contents,
                CancellationToken.None));
        Assert.Equal("rows", nullRow.ParamName);
        var nullContent = Assert.Throws<ArgumentException>(() =>
            codec.WriteRepositoryTargetResolution(
                fixture.Scope, fixture.Location, fixture.DemandDigest,
                fixture.DemandItems, fixture.Rows, [null!],
                CancellationToken.None));
        Assert.Equal("contents", nullContent.ParamName);
    }

    private static void AssertVariantClosure(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture)
    {
        var commitOnly = Demand(0, commit: Commit);
        RoundTrip(
            codec,
            fixture,
            [commitOnly],
            [RepositoryTargetRowMirror.MissingCommit(commitOnly)],
            []);
        RoundTrip(
            codec,
            fixture,
            [commitOnly],
            [RepositoryTargetRowMirror.PresentCommit(
                commitOnly, Owner, "commit", Commit)],
            []);

        var commitPath = Demand(0, commit: Commit, path: "docs/README.md");
        RoundTrip(
            codec,
            fixture,
            [commitPath],
            [RepositoryTargetRowMirror.PresentCommitMissingPath(
                commitPath, Owner, "commit", Commit)],
            []);
        RoundTrip(
            codec,
            fixture,
            [commitPath],
            [RepositoryTargetRowMirror.PresentCommitPath(
                commitPath, Owner, "commit", Commit, "docs/README.md",
                "blob", CommitBlob, null)],
            []);

        var tag = Demand(0, tag: "v1");
        RoundTrip(
            codec,
            fixture,
            [tag],
            [RepositoryTargetRowMirror.MissingTag(tag)],
            []);
        RoundTrip(
            codec,
            fixture,
            [tag],
            [RepositoryTargetRowMirror.PresentTag(
                tag, Owner, "refs/tags/v1", "commit", Commit,
                "commit", Commit)],
            []);

        var captured = Demand(
            0,
            capture: Capture,
            path: "src/file.txt",
            fragment: "L1");
        RoundTrip(
            codec,
            fixture,
            [captured],
            [RepositoryTargetRowMirror.MissingCapturedPath(captured)],
            []);
    }

    private static void AssertWriterRejections(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture)
    {
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                CreateFixture(Commit.Replace('0', '2')).Location,
                fixture.DemandDigest,
                fixture.DemandItems,
                fixture.Rows,
                fixture.Contents,
                CancellationToken.None),
            RepositoryTargetCodecMirror.EmbeddedIdentityMismatch);

        var workflowTarget = AcquisitionTarget.Create(
            "repo", "git", SurfaceKind.Workflow, SnapshotKind.ExactCommit,
            Commit);
        var boundary = AcquisitionBoundary.Create(
            SnapshotKind.ExactCommit,
            Commit,
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero));
        var workflowScope = EvidenceScope.Create(workflowTarget, boundary);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                workflowScope,
                SnapshotEvidenceLocation.Create(workflowScope),
                fixture.DemandDigest,
                fixture.DemandItems,
                fixture.Rows,
                fixture.Contents,
                CancellationToken.None),
            RepositoryTargetCodecMirror.LocationMismatch);

        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                ExactSha256Digest.Parse(new string('0', 64)),
                fixture.DemandItems,
                fixture.Rows,
                fixture.Contents,
                CancellationToken.None),
            RepositoryTargetCodecMirror.InvalidTarget);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                fixture.DemandDigest,
                fixture.DemandItems.Reverse().ToArray(),
                fixture.Rows,
                fixture.Contents,
                CancellationToken.None),
            RepositoryTargetCodecMirror.InvalidTarget);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                fixture.DemandDigest,
                fixture.DemandItems,
                fixture.Rows.Reverse().ToArray(),
                fixture.Contents,
                CancellationToken.None),
            RepositoryTargetCodecMirror.InvalidTarget);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                fixture.DemandDigest,
                fixture.DemandItems,
                fixture.Rows,
                [.. fixture.Contents, fixture.Contents[0]],
                CancellationToken.None),
            RepositoryTargetCodecMirror.InvalidTarget);
    }

    private static void AssertQualifierRejections(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        byte[] golden)
    {
        QualifyRejected(
            Qualify(
                codec,
                fixture,
                CanonicalEvidencePayload.Create("protocol.other", "1", golden)),
            RepositoryTargetCodecMirror.InvalidTarget);
        QualifyRejected(
            Qualify(
                codec,
                fixture,
                CanonicalEvidencePayload.Create(
                    "protocol.repository-target-resolution", "2", golden)),
            RepositoryTargetCodecMirror.InvalidTarget);
        QualifyRejected(
            Qualify(
                codec,
                fixture,
                Payload(new byte[RepositoryTargetCodecMirror.MaximumPayloadBytes + 1])),
            RepositoryTargetCodecMirror.ResourceLimit);

        foreach (var length in Enumerable.Range(0, golden.Length))
        {
            Invalid(codec, fixture, golden.AsSpan(0, length).ToArray());
        }

        var wrongHeader = golden.ToArray();
        wrongHeader[0] ^= 1;
        foreach (var malformed in new[]
        {
            wrongHeader,
            [.. golden, (byte)0],
            SetByte(golden, 195, 4),
            SetUInt32(golden, 228, uint.MaxValue),
            SetByte(golden, 322, 3),
            SetByte(golden, 447, 2),
            SetByte(golden, 736, 2),
            SetUInt32(golden, 1059, 3),
        })
        {
            Invalid(codec, fixture, malformed);
        }

        var other = CreateFixture(Commit.Replace('0', '2'));
        var otherPayload = Written(Write(codec, other));
        QualifyRejected(
            Qualify(codec, fixture, otherPayload),
            RepositoryTargetCodecMirror.EmbeddedIdentityMismatch);

        var repositoryLocation = RepositoryEvidenceLocation.Create(
            fixture.Scope,
            "docs/README.md",
            CommitBlob,
            null,
            null,
            null);
        QualifyRejected(
            codec.QualifyRepositoryTargetResolution(
                Bind(Written(Write(codec, fixture)), repositoryLocation),
                fixture.DemandDigest,
                fixture.DemandItems,
                CancellationToken.None),
            RepositoryTargetCodecMirror.LocationMismatch);
    }

    private static void AssertDefensiveCopies(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        byte[] golden)
    {
        var mutable = Utf8("# Intro\n");
        var content = RepositoryTargetContentMirror.CommitObject(
            Owner, Commit, "docs/README.md", CommitBlob, mutable);
        var demand = Demand(
            0,
            commit: Commit,
            path: "docs/README.md",
            fragment: "intro");
        var row = RepositoryTargetRowMirror.PresentCommitPath(
            demand,
            Owner,
            "commit",
            Commit,
            "docs/README.md",
            "blob",
            CommitBlob,
            content);
        var payload = Written(codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            Digest([demand]),
            [demand],
            [row],
            [content],
            CancellationToken.None));
        mutable[0] = (byte)'x';
        Assert.Equal(
            Utf8("# Intro\n"),
            Qualified(codec.QualifyRepositoryTargetResolution(
                Bind(payload, fixture.Location),
                Digest([demand]),
                [demand],
                CancellationToken.None)).Contents[0]
                .Accept(ContentBytesObserver.Instance));
        Assert.Equal(golden, Written(Write(codec, fixture)).CanonicalBytes);
    }

    private static void AssertCountAndContentLimits(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture)
    {
        var countDemands = Enumerable.Range(
                0,
                RepositoryTargetCodecMirror.MaximumRows)
            .Select(index => Demand(index, tag: $"v{index:D5}"))
            .ToArray();
        var countRows = countDemands
            .Select(RepositoryTargetRowMirror.MissingTag)
            .ToArray();
        Written(codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            Digest(countDemands),
            countDemands,
            countRows,
            [],
            CancellationToken.None));
        var extraDemand = Demand(
            RepositoryTargetCodecMirror.MaximumRows,
            tag: $"v{RepositoryTargetCodecMirror.MaximumRows:D5}");
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                ExactSha256Digest.Parse(new string('0', 64)),
                [.. countDemands, extraDemand],
                [.. countRows, RepositoryTargetRowMirror.MissingTag(extraDemand)],
                [],
                CancellationToken.None),
            RepositoryTargetCodecMirror.ResourceLimit);

        var maximumBytes = new byte[RepositoryTargetCodecMirror.MaximumContentBytes];
        var maximum = ContentFixture(fixture, maximumBytes, 0);
        Written(codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            Digest([maximum.Demand]),
            [maximum.Demand],
            [maximum.Row],
            [maximum.Content],
            CancellationToken.None));
        var over = ContentFixture(fixture, [.. maximumBytes, (byte)0], 0);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                Digest([over.Demand]),
                [over.Demand],
                [over.Row],
                [over.Content],
                CancellationToken.None),
            RepositoryTargetCodecMirror.ResourceLimit);

        var sixtyFour = Enumerable.Range(0, 64)
            .Select(index => ContentFixture(fixture, [(byte)index], index))
            .ToArray();
        Written(codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            Digest(sixtyFour.Select(value => value.Demand).ToArray()),
            sixtyFour.Select(value => value.Demand).ToArray(),
            sixtyFour.Select(value => value.Row).ToArray(),
            sixtyFour.Select(value => value.Content).ToArray(),
            CancellationToken.None));
        var sixtyFive = ContentFixture(fixture, [65], 64);
        WriteRejected(
            codec.WriteRepositoryTargetResolution(
                fixture.Scope,
                fixture.Location,
                ExactSha256Digest.Parse(new string('0', 64)),
                [.. sixtyFour.Select(value => value.Demand), sixtyFive.Demand],
                [.. sixtyFour.Select(value => value.Row), sixtyFive.Row],
                [.. sixtyFour.Select(value => value.Content), sixtyFive.Content],
                CancellationToken.None),
            RepositoryTargetCodecMirror.ResourceLimit);
    }

    private static ContentFixtureData ContentFixture(
        FixtureData fixture,
        byte[] bytes,
        int index)
    {
        var path = $"content/{index:D5}.txt";
        var digest = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
        var demand = Demand(
            index,
            capture: Capture,
            path: path,
            fragment: "L1");
        var content = RepositoryTargetContentMirror.CapturedSnapshotPath(
            Owner,
            Capture,
            path,
            digest,
            bytes);
        var row = RepositoryTargetRowMirror.PresentCapturedPath(
            demand,
            Owner,
            Capture,
            path,
            "file",
            digest,
            content);
        return new ContentFixtureData(demand, row, content);
    }

    private static void RoundTrip(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        RepositoryTargetResolutionDemandItem[] demands,
        RepositoryTargetRowMirror[] rows,
        RepositoryTargetContentMirror[] contents)
    {
        var digest = Digest(demands);
        var payload = Written(codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            digest,
            demands,
            rows,
            contents,
            CancellationToken.None));
        var model = Qualified(codec.QualifyRepositoryTargetResolution(
            Bind(payload, fixture.Location),
            digest,
            demands,
            CancellationToken.None));
        Assert.Equal(
            RepositoryTargetCodecMirror.EncodeDemand(demands),
            RepositoryTargetCodecMirror.EncodeDemand(model.DemandItems));
        Assert.Equal(rows.Length, model.Rows.Count);
        Assert.Equal(contents.Length, model.Contents.Count);
        Assert.Equal(
            payload.CanonicalBytes,
            Written(codec.WriteRepositoryTargetResolution(
                model.Scope,
                model.Location,
                model.DemandDigest,
                model.DemandItems,
                model.Rows,
                model.Contents,
                CancellationToken.None)).CanonicalBytes);
    }

    private static FixtureData CreateFixture(string identity = Commit)
    {
        var target = AcquisitionTarget.Create(
            "repo", "git", SurfaceKind.Repository, SnapshotKind.ExactCommit,
            identity);
        var boundary = AcquisitionBoundary.Create(
            SnapshotKind.ExactCommit,
            identity,
            new DateTimeOffset(0, TimeSpan.Zero),
            new DateTimeOffset(1, TimeSpan.Zero));
        var scope = EvidenceScope.Create(target, boundary);
        var location = SnapshotEvidenceLocation.Create(scope);
        var demands = new[]
        {
            Demand(
                0,
                commit: Commit,
                path: "docs/README.md",
                fragment: "intro"),
            Demand(1, tag: "v1"),
            Demand(
                2,
                capture: Capture,
                path: "src/file.txt",
                fragment: "L1"),
        };
        var commitContent = RepositoryTargetContentMirror.CommitObject(
            Owner,
            Commit,
            "docs/README.md",
            CommitBlob,
            Utf8("# Intro\n"));
        var capturedContent =
            RepositoryTargetContentMirror.CapturedSnapshotPath(
                Owner,
                Capture,
                "src/file.txt",
                CapturedContent,
                Utf8("line\n"));
        var rows = new[]
        {
            RepositoryTargetRowMirror.PresentCommitPath(
                demands[0], Owner, "commit", Commit, "docs/README.md",
                "blob", CommitBlob, commitContent),
            RepositoryTargetRowMirror.PresentTag(
                demands[1], Owner, "refs/tags/v1", "tag",
                new string('1', 40), "commit", Commit),
            RepositoryTargetRowMirror.PresentCapturedPath(
                demands[2], Owner, Capture, "src/file.txt", "file",
                CapturedContent, capturedContent),
        };
        return new FixtureData(
            scope,
            location,
            ExactSha256Digest.Parse(DemandDigest),
            demands,
            rows,
            [commitContent, capturedContent]);
    }

    private static RepositoryTargetResolutionDemandItem Demand(
        int itemId,
        string? commit = null,
        string? tag = null,
        string? capture = null,
        string? path = null,
        string? fragment = null) => RepositoryTargetResolutionDemandItem.Create(
            itemId,
            Owner,
            commit,
            tag,
            capture,
            path,
            fragment);

    private static RepositoryTargetWriteMirrorResult Write(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture) => codec.WriteRepositoryTargetResolution(
            fixture.Scope,
            fixture.Location,
            fixture.DemandDigest,
            fixture.DemandItems,
            fixture.Rows,
            fixture.Contents,
            CancellationToken.None);

    private static RepositoryTargetQualificationMirrorResult Qualify(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        CanonicalEvidencePayload payload) =>
        codec.QualifyRepositoryTargetResolution(
            Bind(payload, fixture.Location),
            fixture.DemandDigest,
            fixture.DemandItems,
            CancellationToken.None);

    private static EvidenceBinding Bind(
        CanonicalEvidencePayload payload,
        EvidenceLocation location) => EvidenceBinding.Create(
            payload,
            location,
            ["protocol.requirement"],
            new DateTimeOffset(1, TimeSpan.Zero));

    private static CanonicalEvidencePayload Payload(byte[] bytes) =>
        CanonicalEvidencePayload.Create(
            "protocol.repository-target-resolution",
            "1",
            bytes);

    private static ExactSha256Digest Digest(
        IReadOnlyList<RepositoryTargetResolutionDemandItem> items) =>
        ExactSha256Digest.FromHashBytes(
            SHA256.HashData(RepositoryTargetCodecMirror.EncodeDemand(items)));

    private static CanonicalEvidencePayload Written(
        RepositoryTargetWriteMirrorResult result)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<CanonicalEvidencePayload>(value.Payload);
    }

    private static void WriteRejected(
        RepositoryTargetWriteMirrorResult result,
        string expected)
    {
        var value = result.Accept(WriteObserver.Instance);
        Assert.Null(value.Payload);
        Assert.Equal(expected, value.Failure);
    }

    private static RepositoryTargetModelMirror Qualified(
        RepositoryTargetQualificationMirrorResult result)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Failure);
        return Assert.IsType<RepositoryTargetModelMirror>(value.Model);
    }

    private static void QualifyRejected(
        RepositoryTargetQualificationMirrorResult result,
        string expected)
    {
        var value = result.Accept(QualificationObserver.Instance);
        Assert.Null(value.Model);
        Assert.Equal(expected, value.Failure);
    }

    private static void Invalid(
        RepositoryTargetCodecMirror codec,
        FixtureData fixture,
        byte[] bytes) => QualifyRejected(
            Qualify(codec, fixture, Payload(bytes)),
            RepositoryTargetCodecMirror.InvalidTarget);

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

    private static byte[] Utf8(string value) => Encoding.UTF8.GetBytes(value);

    private sealed record FixtureData(
        EvidenceScope Scope,
        SnapshotEvidenceLocation Location,
        ExactSha256Digest DemandDigest,
        RepositoryTargetResolutionDemandItem[] DemandItems,
        RepositoryTargetRowMirror[] Rows,
        RepositoryTargetContentMirror[] Contents);

    private sealed record ContentFixtureData(
        RepositoryTargetResolutionDemandItem Demand,
        RepositoryTargetRowMirror Row,
        RepositoryTargetContentMirror Content);

    private sealed record WriteValue(
        CanonicalEvidencePayload? Payload,
        string? Failure);

    private sealed class WriteObserver :
        IRepositoryTargetWriteMirrorResultVisitor<WriteValue>
    {
        internal static WriteObserver Instance { get; } = new();

        public WriteValue VisitWritten(CanonicalEvidencePayload payload) =>
            new(payload, null);

        public WriteValue VisitRejected(string failureCode) =>
            new(null, failureCode);
    }

    private sealed record QualificationValue(
        RepositoryTargetModelMirror? Model,
        string? Failure);

    private sealed class QualificationObserver :
        IRepositoryTargetQualificationMirrorResultVisitor<QualificationValue>
    {
        internal static QualificationObserver Instance { get; } = new();

        public QualificationValue VisitQualified(
            RepositoryTargetModelMirror model) => new(model, null);

        public QualificationValue VisitRejected(string failureCode) =>
            new(null, failureCode);
    }

    private sealed class ContentBytesObserver :
        IRepositoryTargetContentMirrorVisitor<byte[]>
    {
        internal static ContentBytesObserver Instance { get; } = new();

        public byte[] VisitCommitObject(
            string owner,
            string commit,
            string path,
            string blob,
            ReadOnlyMemory<byte> bytes) => bytes.ToArray();

        public byte[] VisitCapturedSnapshotPath(
            string owner,
            string capture,
            string path,
            string contentIdentity,
            ReadOnlyMemory<byte> bytes) => bytes.ToArray();
    }
}

internal abstract class RepositoryTargetContentMirror
{
    private RepositoryTargetContentMirror()
    {
    }

    internal static RepositoryTargetContentMirror CommitObject(
        string owningRepositoryIdentity,
        string commitObjectId,
        string normalizedRepositoryRelativePath,
        string observedBlobObjectId,
        ReadOnlyMemory<byte> bytes)
    {
        ArgumentNullException.ThrowIfNull(owningRepositoryIdentity);
        ArgumentNullException.ThrowIfNull(commitObjectId);
        ArgumentNullException.ThrowIfNull(normalizedRepositoryRelativePath);
        ArgumentNullException.ThrowIfNull(observedBlobObjectId);
        return new CommitObjectCase(
            owningRepositoryIdentity,
            commitObjectId,
            normalizedRepositoryRelativePath,
            observedBlobObjectId,
            bytes.ToArray());
    }

    internal static RepositoryTargetContentMirror CapturedSnapshotPath(
        string owningRepositoryIdentity,
        string capturedSnapshotIdentity,
        string normalizedRepositoryRelativePath,
        string observedContentIdentity,
        ReadOnlyMemory<byte> bytes)
    {
        ArgumentNullException.ThrowIfNull(owningRepositoryIdentity);
        ArgumentNullException.ThrowIfNull(capturedSnapshotIdentity);
        ArgumentNullException.ThrowIfNull(normalizedRepositoryRelativePath);
        ArgumentNullException.ThrowIfNull(observedContentIdentity);
        return new CapturedSnapshotPathCase(
            owningRepositoryIdentity,
            capturedSnapshotIdentity,
            normalizedRepositoryRelativePath,
            observedContentIdentity,
            bytes.ToArray());
    }

    internal abstract TResult Accept<TResult>(
        IRepositoryTargetContentMirrorVisitor<TResult> visitor);

    private sealed class CommitObjectCase(
        string owner,
        string commit,
        string path,
        string blob,
        byte[] bytes) : RepositoryTargetContentMirror
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetContentMirrorVisitor<TResult> visitor) =>
            visitor.VisitCommitObject(owner, commit, path, blob, bytes);
    }

    private sealed class CapturedSnapshotPathCase(
        string owner,
        string capture,
        string path,
        string contentIdentity,
        byte[] bytes) : RepositoryTargetContentMirror
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetContentMirrorVisitor<TResult> visitor) =>
            visitor.VisitCapturedSnapshotPath(
                owner,
                capture,
                path,
                contentIdentity,
                bytes);
    }
}

internal interface IRepositoryTargetContentMirrorVisitor<TResult>
{
    TResult VisitCommitObject(
        string owner,
        string commit,
        string path,
        string blob,
        ReadOnlyMemory<byte> bytes);

    TResult VisitCapturedSnapshotPath(
        string owner,
        string capture,
        string path,
        string contentIdentity,
        ReadOnlyMemory<byte> bytes);
}

internal abstract class RepositoryTargetRowMirror
{
    private RepositoryTargetRowMirror(
        RepositoryTargetResolutionDemandItem demandItem)
    {
        DemandItem = demandItem;
    }

    internal RepositoryTargetResolutionDemandItem DemandItem { get; }

    internal static RepositoryTargetRowMirror MissingCommit(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingCommitCase(RequireDemand(demandItem));

    internal static RepositoryTargetRowMirror PresentCommit(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity) => new PresentCommitCase(
            RequireDemand(demandItem),
            Require(observedOwner),
            Require(observedType),
            Require(observedIdentity));

    internal static RepositoryTargetRowMirror PresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity) => new PresentCommitMissingPathCase(
            RequireDemand(demandItem),
            Require(observedOwner),
            Require(observedType),
            Require(observedIdentity));

    internal static RepositoryTargetRowMirror PresentCommitPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedType,
        string observedIdentity,
        string observedPath,
        string observedPathType,
        string observedPathIdentity,
        RepositoryTargetContentMirror? content) => new PresentCommitPathCase(
            RequireDemand(demandItem),
            Require(observedOwner),
            Require(observedType),
            Require(observedIdentity),
            Require(observedPath),
            Require(observedPathType),
            Require(observedPathIdentity),
            content);

    internal static RepositoryTargetRowMirror MissingTag(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingTagCase(RequireDemand(demandItem));

    internal static RepositoryTargetRowMirror PresentTag(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedRefName,
        string observedRefType,
        string observedRefIdentity,
        string observedPeeledType,
        string observedPeeledIdentity) => new PresentTagCase(
            RequireDemand(demandItem),
            Require(observedOwner),
            Require(observedRefName),
            Require(observedRefType),
            Require(observedRefIdentity),
            Require(observedPeeledType),
            Require(observedPeeledIdentity));

    internal static RepositoryTargetRowMirror MissingCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem) =>
        new MissingCapturedPathCase(RequireDemand(demandItem));

    internal static RepositoryTargetRowMirror PresentCapturedPath(
        RepositoryTargetResolutionDemandItem demandItem,
        string observedOwner,
        string observedCapture,
        string observedPath,
        string observedEntryKind,
        string observedContentIdentity,
        RepositoryTargetContentMirror content) => new PresentCapturedPathCase(
            RequireDemand(demandItem),
            Require(observedOwner),
            Require(observedCapture),
            Require(observedPath),
            Require(observedEntryKind),
            Require(observedContentIdentity),
            content ?? throw new ArgumentNullException(nameof(content)));

    internal abstract TResult Accept<TResult>(
        IRepositoryTargetRowMirrorVisitor<TResult> visitor);

    private static RepositoryTargetResolutionDemandItem RequireDemand(
        RepositoryTargetResolutionDemandItem demandItem) =>
        demandItem ?? throw new ArgumentNullException(nameof(demandItem));

    private static string Require(string value) =>
        value ?? throw new ArgumentNullException(nameof(value));

    private sealed class MissingCommitCase(
        RepositoryTargetResolutionDemandItem demand) :
        RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitMissingCommit(DemandItem);
    }

    private sealed class PresentCommitCase(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity) : RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitPresentCommit(DemandItem, owner, type, identity);
    }

    private sealed class PresentCommitMissingPathCase(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity) : RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitPresentCommitMissingPath(
                DemandItem,
                owner,
                type,
                identity);
    }

    private sealed class PresentCommitPathCase(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity,
        string path,
        string pathType,
        string pathIdentity,
        RepositoryTargetContentMirror? content) :
        RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitPresentCommitPath(
                DemandItem,
                owner,
                type,
                identity,
                path,
                pathType,
                pathIdentity,
                content);
    }

    private sealed class MissingTagCase(
        RepositoryTargetResolutionDemandItem demand) :
        RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitMissingTag(DemandItem);
    }

    private sealed class PresentTagCase(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string refName,
        string refType,
        string refIdentity,
        string peeledType,
        string peeledIdentity) : RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitPresentTag(
                DemandItem,
                owner,
                refName,
                refType,
                refIdentity,
                peeledType,
                peeledIdentity);
    }

    private sealed class MissingCapturedPathCase(
        RepositoryTargetResolutionDemandItem demand) :
        RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitMissingCapturedPath(DemandItem);
    }

    private sealed class PresentCapturedPathCase(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string capture,
        string path,
        string entryKind,
        string contentIdentity,
        RepositoryTargetContentMirror content) :
        RepositoryTargetRowMirror(demand)
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetRowMirrorVisitor<TResult> visitor) =>
            visitor.VisitPresentCapturedPath(
                DemandItem,
                owner,
                capture,
                path,
                entryKind,
                contentIdentity,
                content);
    }
}

internal interface IRepositoryTargetRowMirrorVisitor<TResult>
{
    TResult VisitMissingCommit(RepositoryTargetResolutionDemandItem demand);

    TResult VisitPresentCommit(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity);

    TResult VisitPresentCommitMissingPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity);

    TResult VisitPresentCommitPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string type,
        string identity,
        string path,
        string pathType,
        string pathIdentity,
        RepositoryTargetContentMirror? content);

    TResult VisitMissingTag(RepositoryTargetResolutionDemandItem demand);

    TResult VisitPresentTag(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string refName,
        string refType,
        string refIdentity,
        string peeledType,
        string peeledIdentity);

    TResult VisitMissingCapturedPath(
        RepositoryTargetResolutionDemandItem demand);

    TResult VisitPresentCapturedPath(
        RepositoryTargetResolutionDemandItem demand,
        string owner,
        string capture,
        string path,
        string entryKind,
        string contentIdentity,
        RepositoryTargetContentMirror content);
}

internal abstract class RepositoryTargetWriteMirrorResult
{
    private RepositoryTargetWriteMirrorResult()
    {
    }

    internal static RepositoryTargetWriteMirrorResult Written(
        CanonicalEvidencePayload payload) =>
        new WrittenCase(payload ?? throw new ArgumentNullException(nameof(payload)));

    internal static RepositoryTargetWriteMirrorResult Rejected(
        string failureCode) => new RejectedCase(
            string.IsNullOrWhiteSpace(failureCode)
                ? throw new ArgumentException(null, nameof(failureCode))
                : failureCode);

    internal abstract TResult Accept<TResult>(
        IRepositoryTargetWriteMirrorResultVisitor<TResult> visitor);

    private sealed class WrittenCase(CanonicalEvidencePayload payload) :
        RepositoryTargetWriteMirrorResult
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetWriteMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitWritten(payload);
    }

    private sealed class RejectedCase(string failureCode) :
        RepositoryTargetWriteMirrorResult
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetWriteMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitRejected(failureCode);
    }
}

internal interface IRepositoryTargetWriteMirrorResultVisitor<TResult>
{
    TResult VisitWritten(CanonicalEvidencePayload payload);
    TResult VisitRejected(string failureCode);
}

internal abstract class RepositoryTargetQualificationMirrorResult
{
    private RepositoryTargetQualificationMirrorResult()
    {
    }

    internal static RepositoryTargetQualificationMirrorResult Qualified(
        RepositoryTargetModelMirror model) =>
        new QualifiedCase(model ?? throw new ArgumentNullException(nameof(model)));

    internal static RepositoryTargetQualificationMirrorResult Rejected(
        string failureCode) => new RejectedCase(
            string.IsNullOrWhiteSpace(failureCode)
                ? throw new ArgumentException(null, nameof(failureCode))
                : failureCode);

    internal abstract TResult Accept<TResult>(
        IRepositoryTargetQualificationMirrorResultVisitor<TResult> visitor);

    private sealed class QualifiedCase(RepositoryTargetModelMirror model) :
        RepositoryTargetQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetQualificationMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitQualified(model);
    }

    private sealed class RejectedCase(string failureCode) :
        RepositoryTargetQualificationMirrorResult
    {
        internal override TResult Accept<TResult>(
            IRepositoryTargetQualificationMirrorResultVisitor<TResult> visitor) =>
            visitor.VisitRejected(failureCode);
    }
}

internal interface IRepositoryTargetQualificationMirrorResultVisitor<TResult>
{
    TResult VisitQualified(RepositoryTargetModelMirror model);
    TResult VisitRejected(string failureCode);
}

internal sealed partial class RepositoryTargetModelMirror
{
    private RepositoryTargetModelMirror(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        RepositoryTargetResolutionDemandItem[] demandItems,
        RepositoryTargetRowMirror[] rows,
        RepositoryTargetContentMirror[] contents)
    {
        Scope = scope;
        Location = location;
        DemandDigest = demandDigest;
        DemandItems = Array.AsReadOnly(demandItems);
        Rows = Array.AsReadOnly(rows);
        Contents = Array.AsReadOnly(contents);
    }

    internal EvidenceScope Scope { get; }
    internal SnapshotEvidenceLocation Location { get; }
    internal ExactSha256Digest DemandDigest { get; }
    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    internal IReadOnlyList<RepositoryTargetRowMirror> Rows { get; }
    internal IReadOnlyList<RepositoryTargetContentMirror> Contents { get; }

    internal static RepositoryTargetModelMirror Create(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        IEnumerable<RepositoryTargetRowMirror> rows,
        IEnumerable<RepositoryTargetContentMirror> contents)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(demandDigest);
        ArgumentNullException.ThrowIfNull(demandItems);
        ArgumentNullException.ThrowIfNull(rows);
        ArgumentNullException.ThrowIfNull(contents);
        var demandValues = demandItems.ToArray();
        var rowValues = rows.ToArray();
        var contentValues = contents.ToArray();
        if (demandValues.Any(value => value is null))
        {
            throw new ArgumentException(
                "Repository-target demands cannot contain null.",
                nameof(demandItems));
        }
        if (rowValues.Any(value => value is null))
        {
            throw new ArgumentException(
                "Repository-target rows cannot contain null.",
                nameof(rows));
        }
        if (contentValues.Any(value => value is null))
        {
            throw new ArgumentException(
                "Repository-target contents cannot contain null.",
                nameof(contents));
        }
        if (!scope.Equals(location.Scope))
        {
            throw new ArgumentException(
                "The location must retain the supplied scope.",
                nameof(location));
        }
        return new RepositoryTargetModelMirror(
            scope,
            location,
            demandDigest,
            demandValues,
            rowValues,
            contentValues);
    }
}

internal sealed partial class RepositoryTargetCodecMirror
{
    internal const string InvalidTarget =
        "protocol.codec.invalid-repository-target-resolution";
    internal const string LocationMismatch =
        "protocol.codec.payload-location-mismatch";
    internal const string EmbeddedIdentityMismatch =
        "protocol.codec.embedded-identity-mismatch";
    internal const string ResourceLimit =
        "protocol.codec.resource-limit-exceeded";
    internal const int MaximumRows = 50_000;
    internal const int MaximumContents = 64;
    internal const int MaximumRowTextBytes = 16_777_216;
    internal const int MaximumContentBytes = 1_048_576;
    internal const int MaximumAggregateContentBytes = 16_777_216;
    internal const int MaximumPayloadBytes = 33_554_432;

    private static readonly byte[] Header = Encoding.ASCII.GetBytes(
        "protocol.repository-target-resolution/1\n");
    private static readonly byte[] DemandHeader = Encoding.ASCII.GetBytes(
        "protocol.acquisition-demand/1\n");
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    internal RepositoryTargetWriteMirrorResult WriteRepositoryTargetResolution(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems,
        IReadOnlyList<RepositoryTargetRowMirror> rows,
        IReadOnlyList<RepositoryTargetContentMirror> contents,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(location);
        ArgumentNullException.ThrowIfNull(demandDigest);
        ArgumentNullException.ThrowIfNull(demandItems);
        ArgumentNullException.ThrowIfNull(rows);
        ArgumentNullException.ThrowIfNull(contents);
        cancellationToken.ThrowIfCancellationRequested();

        var prepared = Prepare(
            scope,
            location,
            demandDigest,
            demandItems,
            rows,
            contents);
        if (prepared.Failure is not null)
        {
            return RepositoryTargetWriteMirrorResult.Rejected(prepared.Failure);
        }

        return RepositoryTargetWriteMirrorResult.Written(
            CanonicalEvidencePayload.Create(
                "protocol.repository-target-resolution",
                "1",
                prepared.Bytes));
    }

    internal RepositoryTargetQualificationMirrorResult
        QualifyRepositoryTargetResolution(
            EvidenceBinding binding,
            ExactSha256Digest expectedDemandDigest,
            IReadOnlyList<RepositoryTargetResolutionDemandItem> expectedDemandItems,
            CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(binding);
        ArgumentNullException.ThrowIfNull(expectedDemandDigest);
        ArgumentNullException.ThrowIfNull(expectedDemandItems);
        cancellationToken.ThrowIfCancellationRequested();

        if (binding.Payload.CanonicalBytes.Count > MaximumPayloadBytes)
        {
            return Reject(ResourceLimit);
        }
        if (!string.Equals(
                binding.Payload.SchemaKey,
                "protocol.repository-target-resolution",
                StringComparison.Ordinal) ||
            !string.Equals(
                binding.Payload.SchemaVersion,
                "1",
                StringComparison.Ordinal))
        {
            return Reject(InvalidTarget);
        }

        try
        {
            return Decode(binding, expectedDemandDigest, expectedDemandItems);
        }
        catch (ResourceLimitException)
        {
            return Reject(ResourceLimit);
        }
        catch (LocationMismatchException)
        {
            return Reject(LocationMismatch);
        }
        catch (Exception exception) when (exception is ArgumentException or
            InvalidOperationException or OverflowException or
            DecoderFallbackException)
        {
            return Reject(InvalidTarget);
        }
    }

    internal static byte[] EncodeDemand(
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems)
    {
        ArgumentNullException.ThrowIfNull(demandItems);
        if (demandItems.Count is 0 or > MaximumRows)
        {
            throw new ArgumentException("Demand count is invalid.", nameof(demandItems));
        }
        using var stream = new MemoryStream();
        stream.Write(DemandHeader);
        stream.WriteByte(1);
        WriteUInt32(stream, checked((uint)demandItems.Count));
        string? owner = null;
        var priorItemId = -1;
        foreach (var demand in demandItems)
        {
            if (demand is null)
            {
                throw new ArgumentException(
                    "Demand items cannot contain null.",
                    nameof(demandItems));
            }
            var kind = ValidateDemand(demand, owner, priorItemId);
            owner ??= demand.OwningRepositoryIdentity;
            priorItemId = demand.ItemId;
            WriteDemand(stream, demand, kind, null);
        }
        return stream.ToArray();
    }

    private static Prepared Prepare(
        EvidenceScope scope,
        SnapshotEvidenceLocation location,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems,
        IReadOnlyList<RepositoryTargetRowMirror> rows,
        IReadOnlyList<RepositoryTargetContentMirror> contents)
    {
        if (demandItems.Any(value => value is null))
        {
            throw new ArgumentException(
                "Demand items cannot contain null.",
                "demandItems");
        }
        if (rows.Any(value => value is null))
        {
            throw new ArgumentException("Rows cannot contain null.", "rows");
        }
        if (contents.Any(value => value is null))
        {
            throw new ArgumentException(
                "Contents cannot contain null.",
                "contents");
        }
        if (rows.Count > MaximumRows || demandItems.Count > MaximumRows ||
            contents.Count > MaximumContents)
        {
            return Prepared.Rejected(ResourceLimit);
        }
        if (demandItems.Count == 0 || demandItems.Count != rows.Count)
        {
            return Prepared.Rejected(InvalidTarget);
        }

        var demandValues = demandItems.ToArray();
        var rowValues = rows.ToArray();
        var contentValues = contents.ToArray();
        if (!scope.Target.Surface.Equals(SurfaceKind.Repository) ||
            location is null)
        {
            return Prepared.Rejected(LocationMismatch);
        }
        if (!scope.Equals(location.Scope))
        {
            return Prepared.Rejected(EmbeddedIdentityMismatch);
        }

        byte[] demandFrame;
        try
        {
            demandFrame = EncodeDemand(demandValues);
        }
        catch (EncoderFallbackException)
        {
            return Prepared.Rejected(InvalidTarget);
        }
        catch (ArgumentException)
        {
            return Prepared.Rejected(InvalidTarget);
        }
        var computedDemandDigest = ExactSha256Digest.FromHashBytes(
            SHA256.HashData(demandFrame));
        if (!computedDemandDigest.Equals(demandDigest))
        {
            return Prepared.Rejected(InvalidTarget);
        }

        var rowData = rowValues
            .Select(value => value.Accept(RowCaptureVisitor.Instance))
            .ToArray();
        var contentData = contentValues
            .Select(value => value.Accept(ContentCaptureVisitor.Instance))
            .ToArray();
        var validation = ValidateRowsAndContents(
            demandValues,
            rowValues,
            rowData,
            contentValues,
            contentData);
        if (validation is not null)
        {
            return Prepared.Rejected(validation);
        }

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
                    return Prepared.Rejected(ResourceLimit);
                }
            }
            WriteUInt32(stream, checked((uint)contentData.Length));
            long aggregateContentBytes = 0;
            for (var index = 0; index < contentData.Length; index++)
            {
                var content = contentData[index];
                if (content.Bytes.Length > MaximumContentBytes)
                {
                    return Prepared.Rejected(ResourceLimit);
                }
                aggregateContentBytes = checked(
                    aggregateContentBytes + content.Bytes.Length);
                if (aggregateContentBytes > MaximumAggregateContentBytes)
                {
                    return Prepared.Rejected(ResourceLimit);
                }
                WriteContent(stream, index, content, ref rowTextBytes);
                if (rowTextBytes > MaximumRowTextBytes)
                {
                    return Prepared.Rejected(ResourceLimit);
                }
            }
            if (stream.Length > MaximumPayloadBytes)
            {
                return Prepared.Rejected(ResourceLimit);
            }
            return Prepared.Accepted(
                scope,
                location,
                demandDigest,
                demandValues,
                rowValues,
                contentValues,
                stream.ToArray());
        }
        catch (EncoderFallbackException)
        {
            return Prepared.Rejected(InvalidTarget);
        }
        catch (OverflowException)
        {
            return Prepared.Rejected(ResourceLimit);
        }
    }

    private static RepositoryTargetQualificationMirrorResult Decode(
        EvidenceBinding binding,
        ExactSha256Digest expectedDemandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> expectedDemandItems)
    {
        if (expectedDemandItems.Any(value => value is null))
        {
            throw new ArgumentException(
                "Demand items cannot contain null.",
                nameof(expectedDemandItems));
        }
        var bytes = binding.Payload.CanonicalBytes.ToArray();
        var reader = new Reader(bytes);
        reader.Expect(Header);
        var scope = ReadScope(ref reader);
        var rank = reader.Byte();
        if (rank is 0 or 1 or 2)
        {
            throw new LocationMismatchException();
        }
        if (rank != 3)
        {
            throw new InvalidOperationException("Invalid location rank.");
        }
        var digest = ExactSha256Digest.FromHashBytes(reader.Bytes(32));
        var rowCount = reader.UInt32();
        if (rowCount > MaximumRows)
        {
            throw new ResourceLimitException();
        }
        if (rowCount == 0)
        {
            throw new InvalidOperationException("Rows are required.");
        }

        var parsedRows = new ParsedRow[checked((int)rowCount)];
        for (var index = 0; index < parsedRows.Length; index++)
        {
            parsedRows[index] = ReadRow(ref reader);
        }
        var contentCount = reader.UInt32();
        if (contentCount > MaximumContents)
        {
            throw new ResourceLimitException();
        }
        var contents = new RepositoryTargetContentMirror[checked((int)contentCount)];
        long aggregateContentBytes = 0;
        for (var index = 0; index < contents.Length; index++)
        {
            var ordinal = reader.UInt32();
            if (ordinal != index)
            {
                throw new InvalidOperationException("Content ordinal drifted.");
            }
            var ownerKind = reader.Byte();
            var owner = reader.Text();
            var first = reader.Text();
            var path = reader.Text();
            var identity = reader.Text();
            var length = reader.UInt32();
            if (length > MaximumContentBytes)
            {
                throw new ResourceLimitException();
            }
            aggregateContentBytes = checked(aggregateContentBytes + length);
            if (aggregateContentBytes > MaximumAggregateContentBytes)
            {
                throw new ResourceLimitException();
            }
            var contentDigest = reader.Bytes(32);
            var contentBytes = reader.Bytes(checked((int)length));
            if (!SHA256.HashData(contentBytes).AsSpan().SequenceEqual(contentDigest))
            {
                throw new InvalidOperationException("Content digest drifted.");
            }
            contents[index] = ownerKind switch
            {
                0 => RepositoryTargetContentMirror.CommitObject(
                    owner, first, path, identity, contentBytes),
                1 => RepositoryTargetContentMirror.CapturedSnapshotPath(
                    owner, first, path, identity, contentBytes),
                _ => throw new InvalidOperationException("Invalid content kind."),
            };
        }
        if (!reader.End)
        {
            throw new InvalidOperationException("Trailing bytes are forbidden.");
        }

        var demands = parsedRows.Select(value => value.Demand).ToArray();
        var rows = parsedRows
            .Select(value => value.ToCarrier(contents))
            .ToArray();
        var location = SnapshotEvidenceLocation.Create(scope);
        var prepared = Prepare(
            scope,
            location,
            digest,
            demands,
            rows,
            contents);
        if (prepared.Failure is not null)
        {
            return Reject(prepared.Failure);
        }
        if (!prepared.Bytes.AsSpan().SequenceEqual(bytes) ||
            !digest.Equals(expectedDemandDigest) ||
            !DemandListsEqual(demands, expectedDemandItems))
        {
            return Reject(InvalidTarget);
        }
        if (binding.Location is not SnapshotEvidenceLocation outer ||
            !outer.Scope.Target.Surface.Equals(SurfaceKind.Repository))
        {
            return Reject(LocationMismatch);
        }
        if (!scope.Equals(outer.Scope))
        {
            return Reject(EmbeddedIdentityMismatch);
        }

        return RepositoryTargetQualificationMirrorResult.Qualified(
            RepositoryTargetModelMirror.Create(
                scope,
                location,
                digest,
                demands,
                rows,
                contents));
    }

    private static string? ValidateRowsAndContents(
        RepositoryTargetResolutionDemandItem[] demands,
        RepositoryTargetRowMirror[] rows,
        RowData[] rowData,
        RepositoryTargetContentMirror[] contents,
        ContentData[] contentData)
    {
        var referenced = new HashSet<RepositoryTargetContentMirror>(
            ReferenceEqualityComparer.Instance);
        string? previousContentKey = null;
        for (var index = 0; index < contents.Length; index++)
        {
            var current = contentData[index];
            if (!ValidContent(current))
            {
                return InvalidTarget;
            }
            var key = current.CanonicalKey;
            if (previousContentKey is not null &&
                StringComparer.Ordinal.Compare(previousContentKey, key) >= 0)
            {
                return InvalidTarget;
            }
            previousContentKey = key;
        }

        for (var index = 0; index < rows.Length; index++)
        {
            var demand = demands[index];
            var row = rowData[index];
            if (!ReferenceEquals(rows[index].DemandItem, demand) ||
                !ReferenceEquals(row.Demand, demand) ||
                !ValidRow(demand, row))
            {
                return InvalidTarget;
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
                return InvalidTarget;
            }
            referenced.Add(row.Content);
        }
        return referenced.Count == contents.Length ? null : InvalidTarget;
    }

    private static bool ValidRow(
        RepositoryTargetResolutionDemandItem demand,
        RowData row)
    {
        var demandKind = DemandKindOf(demand);
        if (demandKind is null)
        {
            return false;
        }
        return row.Kind switch
        {
            RowKind.MissingCommit => demandKind == DemandKind.Commit,
            RowKind.PresentCommit => demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64),
            RowKind.PresentCommitMissingPath =>
                demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is not null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64),
            RowKind.PresentCommitPath =>
                demandKind == DemandKind.Commit &&
                demand.NormalizedRepositoryRelativePath is not null &&
                ValidOwner(row.Owner) && ValidObjectType(row.Type) &&
                ValidHex(row.Identity, 40, 64) && ValidPath(row.Path) &&
                ValidObjectType(row.PathType) &&
                ValidHex(row.PathIdentity, 40, 64) &&
                (demand.NormalizedFragment is null || row.Content is not null),
            RowKind.MissingTag => demandKind == DemandKind.Tag,
            RowKind.PresentTag => demandKind == DemandKind.Tag &&
                ValidOwner(row.Owner) && ValidRef(row.RefName) &&
                ValidObjectType(row.RefType) &&
                ValidHex(row.RefIdentity, 40, 64) &&
                ValidObjectType(row.PeeledType) &&
                ValidHex(row.PeeledIdentity, 40, 64),
            RowKind.MissingCaptured => demandKind == DemandKind.Captured,
            RowKind.PresentCaptured => demandKind == DemandKind.Captured &&
                ValidOwner(row.Owner) && ValidHex(row.Capture, 64) &&
                ValidPath(row.Path) &&
                string.Equals(row.EntryKind, "file", StringComparison.Ordinal) &&
                ValidHex(row.ContentIdentity, 64) && row.Content is not null,
            _ => false,
        };
    }

    private static bool ValidContent(ContentData content)
    {
        if (!ValidOwner(content.Owner) || !ValidPath(content.Path))
        {
            return false;
        }
        if (content.Kind == ContentKind.Commit)
        {
            if (!ValidHex(content.FirstIdentity, 40, 64) ||
                !ValidHex(content.ObservedIdentity, content.FirstIdentity.Length))
            {
                return false;
            }
            return string.Equals(
                GitBlobIdentity(content.Bytes, content.FirstIdentity.Length),
                content.ObservedIdentity,
                StringComparison.Ordinal);
        }
        return ValidHex(content.FirstIdentity, 64) &&
            ValidHex(content.ObservedIdentity, 64) &&
            string.Equals(
                Convert.ToHexString(SHA256.HashData(content.Bytes))
                    .ToLowerInvariant(),
                content.ObservedIdentity,
                StringComparison.Ordinal);
    }

    private static bool ContentMatchesRow(ContentData content, RowData row) =>
        row.Kind switch
        {
            RowKind.PresentCommitPath => content.Kind == ContentKind.Commit &&
                string.Equals(content.Owner, row.Owner, StringComparison.Ordinal) &&
                string.Equals(
                    content.FirstIdentity,
                    row.Identity,
                    StringComparison.Ordinal) &&
                string.Equals(content.Path, row.Path, StringComparison.Ordinal) &&
                string.Equals(
                    content.ObservedIdentity,
                    row.PathIdentity,
                    StringComparison.Ordinal),
            RowKind.PresentCaptured =>
                content.Kind == ContentKind.Captured &&
                string.Equals(content.Owner, row.Owner, StringComparison.Ordinal) &&
                string.Equals(
                    content.FirstIdentity,
                    row.Capture,
                    StringComparison.Ordinal) &&
                string.Equals(content.Path, row.Path, StringComparison.Ordinal) &&
                string.Equals(
                    content.ObservedIdentity,
                    row.ContentIdentity,
                    StringComparison.Ordinal),
            _ => false,
        };

    private static void WriteRow(
        Stream stream,
        RepositoryTargetResolutionDemandItem demand,
        RowData row,
        RepositoryTargetContentMirror[] contents,
        ref long rowTextBytes)
    {
        var kind = DemandKindOf(demand) ??
            throw new InvalidOperationException("Invalid demand selector.");
        var demandTextBytes = 0;
        WriteDemand(stream, demand, kind, value => demandTextBytes += value);
        rowTextBytes = checked(rowTextBytes + demandTextBytes);
        switch (row.Kind)
        {
            case RowKind.MissingCommit:
                stream.WriteByte(0);
                break;
            case RowKind.PresentCommit:
                stream.WriteByte(1);
                WriteObservedCommit(stream, row, ref rowTextBytes);
                break;
            case RowKind.PresentCommitMissingPath:
                stream.WriteByte(1);
                WriteObservedCommit(stream, row, ref rowTextBytes);
                stream.WriteByte(0);
                break;
            case RowKind.PresentCommitPath:
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
                    WriteUInt32(
                        stream,
                        checked((uint)Array.FindIndex(
                            contents,
                            value => ReferenceEquals(value, row.Content))));
                }
                break;
            case RowKind.MissingTag:
            case RowKind.MissingCaptured:
                stream.WriteByte(0);
                break;
            case RowKind.PresentTag:
                stream.WriteByte(1);
                WriteCountedText(stream, row.Owner!, ref rowTextBytes);
                WriteCountedText(stream, row.RefName!, ref rowTextBytes);
                WriteCountedText(stream, row.RefType!, ref rowTextBytes);
                WriteCountedText(stream, row.RefIdentity!, ref rowTextBytes);
                WriteCountedText(stream, row.PeeledType!, ref rowTextBytes);
                WriteCountedText(stream, row.PeeledIdentity!, ref rowTextBytes);
                break;
            case RowKind.PresentCaptured:
                stream.WriteByte(1);
                WriteCountedText(stream, row.Owner!, ref rowTextBytes);
                WriteCountedText(stream, row.Capture!, ref rowTextBytes);
                WriteCountedText(stream, row.Path!, ref rowTextBytes);
                WriteCountedText(stream, row.EntryKind!, ref rowTextBytes);
                WriteCountedText(stream, row.ContentIdentity!, ref rowTextBytes);
                WriteUInt32(
                    stream,
                    checked((uint)Array.FindIndex(
                        contents,
                        value => ReferenceEquals(value, row.Content))));
                break;
            default:
                throw new InvalidOperationException("Invalid row kind.");
        }
    }

    private static void WriteObservedCommit(
        Stream stream,
        RowData row,
        ref long rowTextBytes)
    {
        WriteCountedText(stream, row.Owner!, ref rowTextBytes);
        WriteCountedText(stream, row.Type!, ref rowTextBytes);
        WriteCountedText(stream, row.Identity!, ref rowTextBytes);
    }

    private static void WriteContent(
        Stream stream,
        int ordinal,
        ContentData content,
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
            default:
                throw new InvalidOperationException("Invalid demand kind.");
        }
    }

    private static ParsedRow ReadRow(ref Reader reader)
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
                return ParsedRow.MissingCommit(demand);
            }
            if (outcome != 1)
            {
                throw new InvalidOperationException("Invalid commit outcome.");
            }
            var observedOwner = reader.Text();
            var type = reader.Text();
            var identity = reader.Text();
            if (path is null)
            {
                return ParsedRow.PresentCommit(
                    demand, observedOwner, type, identity);
            }
            var pathOutcome = reader.Byte();
            if (pathOutcome == 0)
            {
                return ParsedRow.PresentCommitMissingPath(
                    demand, observedOwner, type, identity);
            }
            if (pathOutcome != 1)
            {
                throw new InvalidOperationException("Invalid path outcome.");
            }
            var observedPath = reader.Text();
            var pathType = reader.Text();
            var pathIdentity = reader.Text();
            var contentOrdinal = reader.OptionalUInt32();
            return ParsedRow.PresentCommitPath(
                demand,
                observedOwner,
                type,
                identity,
                observedPath,
                pathType,
                pathIdentity,
                contentOrdinal);
        }
        if (selector == 1)
        {
            var tag = reader.Text();
            var demand = RepositoryTargetResolutionDemandItem.Create(
                itemId, owner, null, tag, null, null, null);
            var outcome = reader.Byte();
            if (outcome == 0)
            {
                return ParsedRow.MissingTag(demand);
            }
            if (outcome != 1)
            {
                throw new InvalidOperationException("Invalid tag outcome.");
            }
            return ParsedRow.PresentTag(
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
            var capture = reader.Text();
            var path = reader.Text();
            var fragment = reader.Text();
            var demand = RepositoryTargetResolutionDemandItem.Create(
                itemId, owner, null, null, capture, path, fragment);
            var outcome = reader.Byte();
            if (outcome == 0)
            {
                return ParsedRow.MissingCaptured(demand);
            }
            if (outcome != 1)
            {
                throw new InvalidOperationException("Invalid capture outcome.");
            }
            return ParsedRow.PresentCaptured(
                demand,
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.Text(),
                reader.UInt32());
        }
        throw new InvalidOperationException("Invalid selector kind.");
    }

    private static EvidenceScope ReadScope(ref Reader reader)
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
            !SnapshotKind.TryParse(
                boundarySnapshotText,
                out var boundarySnapshot))
        {
            throw new InvalidOperationException("Invalid scope identity.");
        }
        if (!surface.Equals(SurfaceKind.Repository))
        {
            throw new LocationMismatchException();
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
            started,
            completed);
        return EvidenceScope.Create(target, boundary);
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
        var kind = DemandKindOf(demand) ??
            throw new ArgumentException("Demand selector is not closed.");
        if (demand.ItemId < 0 || demand.ItemId <= priorItemId ||
            !ValidOwner(demand.OwningRepositoryIdentity) ||
            owner is not null && !string.Equals(
                owner,
                demand.OwningRepositoryIdentity,
                StringComparison.Ordinal))
        {
            throw new ArgumentException("Demand order or owner is invalid.");
        }
        if (kind == DemandKind.Commit &&
            (!ValidHex(demand.CommitObjectId, 40, 64) ||
             demand.NormalizedRepositoryRelativePath is not null &&
             !ValidPath(demand.NormalizedRepositoryRelativePath) ||
             demand.NormalizedFragment is not null &&
             (demand.NormalizedRepositoryRelativePath is null ||
              !ValidFragment(demand.NormalizedFragment))))
        {
            throw new ArgumentException("Commit demand is invalid.");
        }
        if (kind == DemandKind.Tag && !ValidTag(demand.NormalizedTagName))
        {
            throw new ArgumentException("Tag demand is invalid.");
        }
        if (kind == DemandKind.Captured &&
            (!ValidHex(demand.CapturedSnapshotIdentity, 64) ||
             !ValidPath(demand.NormalizedRepositoryRelativePath) ||
             !ValidFragment(demand.NormalizedFragment)))
        {
            throw new ArgumentException("Captured demand is invalid.");
        }
        return kind;
    }

    private static DemandKind? DemandKindOf(
        RepositoryTargetResolutionDemandItem demand)
    {
        var present = 0;
        if (demand.CommitObjectId is not null)
        {
            present++;
        }
        if (demand.NormalizedTagName is not null)
        {
            present++;
        }
        if (demand.CapturedSnapshotIdentity is not null)
        {
            present++;
        }
        if (present != 1)
        {
            return null;
        }
        if (demand.CommitObjectId is not null)
        {
            return DemandKind.Commit;
        }
        return demand.NormalizedTagName is not null
            ? DemandKind.Tag
            : DemandKind.Captured;
    }

    private static bool DemandListsEqual(
        IReadOnlyList<RepositoryTargetResolutionDemandItem> actual,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> expected)
    {
        if (actual.Count != expected.Count)
        {
            return false;
        }
        for (var index = 0; index < actual.Count; index++)
        {
            var left = actual[index];
            var right = expected[index];
            if (left.ItemId != right.ItemId ||
                !string.Equals(left.OwningRepositoryIdentity,
                    right.OwningRepositoryIdentity, StringComparison.Ordinal) ||
                !string.Equals(left.CommitObjectId,
                    right.CommitObjectId, StringComparison.Ordinal) ||
                !string.Equals(left.NormalizedTagName,
                    right.NormalizedTagName, StringComparison.Ordinal) ||
                !string.Equals(left.CapturedSnapshotIdentity,
                    right.CapturedSnapshotIdentity, StringComparison.Ordinal) ||
                !string.Equals(left.NormalizedRepositoryRelativePath,
                    right.NormalizedRepositoryRelativePath,
                    StringComparison.Ordinal) ||
                !string.Equals(left.NormalizedFragment,
                    right.NormalizedFragment, StringComparison.Ordinal))
            {
                return false;
            }
        }
        return true;
    }

    private static bool ValidOwner(string? value)
    {
        if (value is null || !value.StartsWith(
                "https://github.com/",
                StringComparison.Ordinal) ||
            value.EndsWith("/", StringComparison.Ordinal))
        {
            return false;
        }
        var tail = value["https://github.com/".Length..];
        var segments = tail.Split('/');
        return segments.Length == 2 &&
            segments.All(segment => segment.Length > 0 &&
                segment.All(character => char.IsAsciiLetterOrDigit(character) ||
                    character is '-' or '_' or '.'));
    }

    private static bool ValidPath(string? value)
    {
        if (string.IsNullOrEmpty(value) || value[0] == '/' || value[^1] == '/' ||
            value.Contains('\\', StringComparison.Ordinal) ||
            value.Length >= 2 && char.IsAsciiLetter(value[0]) && value[1] == ':')
        {
            return false;
        }
        return value.Split('/').All(segment =>
            segment.Length > 0 && segment is not "." and not "..");
    }

    private static bool ValidTag(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        !value.Contains('/', StringComparison.Ordinal) &&
        !value.Contains('\\', StringComparison.Ordinal) &&
        !value.Contains("..", StringComparison.Ordinal);

    private static bool ValidFragment(string? value) =>
        !string.IsNullOrEmpty(value) &&
        !value.Contains('\uFEFF', StringComparison.Ordinal);

    private static bool ValidRef(string? value) =>
        value is not null && value.StartsWith("refs/tags/", StringComparison.Ordinal) &&
        ValidTag(value["refs/tags/".Length..]);

    private static bool ValidObjectType(string? value) =>
        value is "blob" or "commit" or "tag" or "tree";

    private static bool ValidHex(string? value, params int[] lengths) =>
        value is not null && lengths.Contains(value.Length) &&
        value.All(character => character is >= '0' and <= '9' or >= 'a' and <= 'f');

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
        if (value is null)
        {
            stream.WriteByte(0);
            return;
        }
        stream.WriteByte(1);
        WriteText(stream, value, countText);
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

    private static RepositoryTargetQualificationMirrorResult Reject(string code) =>
        RepositoryTargetQualificationMirrorResult.Rejected(code);

    private enum DemandKind : byte
    {
        Commit = 0,
        Tag = 1,
        Captured = 2,
    }

    private enum RowKind
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

    private enum ContentKind : byte
    {
        Commit = 0,
        Captured = 1,
    }

    private sealed record Prepared(
        EvidenceScope Scope,
        SnapshotEvidenceLocation Location,
        ExactSha256Digest DemandDigest,
        RepositoryTargetResolutionDemandItem[] DemandItems,
        RepositoryTargetRowMirror[] Rows,
        RepositoryTargetContentMirror[] Contents,
        byte[] Bytes,
        string? Failure)
    {
        internal static Prepared Accepted(
            EvidenceScope scope,
            SnapshotEvidenceLocation location,
            ExactSha256Digest demandDigest,
            RepositoryTargetResolutionDemandItem[] demandItems,
            RepositoryTargetRowMirror[] rows,
            RepositoryTargetContentMirror[] contents,
            byte[] bytes) => new(
                scope,
                location,
                demandDigest,
                demandItems,
                rows,
                contents,
                bytes,
                null);

        internal static Prepared Rejected(string failure) => new(
            null!,
            null!,
            null!,
            [],
            [],
            [],
            [],
            failure);
    }

    private sealed record RowData(
        RowKind Kind,
        RepositoryTargetResolutionDemandItem Demand,
        string? Owner = null,
        string? Type = null,
        string? Identity = null,
        string? Path = null,
        string? PathType = null,
        string? PathIdentity = null,
        RepositoryTargetContentMirror? Content = null,
        string? RefName = null,
        string? RefType = null,
        string? RefIdentity = null,
        string? PeeledType = null,
        string? PeeledIdentity = null,
        string? Capture = null,
        string? EntryKind = null,
        string? ContentIdentity = null);

    private sealed record ContentData(
        ContentKind Kind,
        string Owner,
        string FirstIdentity,
        string Path,
        string ObservedIdentity,
        byte[] Bytes)
    {
        internal string CanonicalKey =>
            $"{(int)Kind:D1}\0{Owner}\0{FirstIdentity}\0{Path}\0{ObservedIdentity}";
    }

    private sealed class RowCaptureVisitor :
        IRepositoryTargetRowMirrorVisitor<RowData>
    {
        internal static RowCaptureVisitor Instance { get; } = new();

        public RowData VisitMissingCommit(
            RepositoryTargetResolutionDemandItem demand) =>
            new(RowKind.MissingCommit, demand);

        public RowData VisitPresentCommit(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(
                RowKind.PresentCommit,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity);

        public RowData VisitPresentCommitMissingPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(
                RowKind.PresentCommitMissingPath,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity);

        public RowData VisitPresentCommitPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity,
            string path,
            string pathType,
            string pathIdentity,
            RepositoryTargetContentMirror? content) => new(
                RowKind.PresentCommitPath,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity,
                Path: path,
                PathType: pathType,
                PathIdentity: pathIdentity,
                Content: content);

        public RowData VisitMissingTag(
            RepositoryTargetResolutionDemandItem demand) =>
            new(RowKind.MissingTag, demand);

        public RowData VisitPresentTag(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string refName,
            string refType,
            string refIdentity,
            string peeledType,
            string peeledIdentity) => new(
                RowKind.PresentTag,
                demand,
                Owner: owner,
                RefName: refName,
                RefType: refType,
                RefIdentity: refIdentity,
                PeeledType: peeledType,
                PeeledIdentity: peeledIdentity);

        public RowData VisitMissingCapturedPath(
            RepositoryTargetResolutionDemandItem demand) =>
            new(RowKind.MissingCaptured, demand);

        public RowData VisitPresentCapturedPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string capture,
            string path,
            string entryKind,
            string contentIdentity,
            RepositoryTargetContentMirror content) => new(
                RowKind.PresentCaptured,
                demand,
                Owner: owner,
                Path: path,
                Content: content,
                Capture: capture,
                EntryKind: entryKind,
                ContentIdentity: contentIdentity);
    }

    private sealed class ContentCaptureVisitor :
        IRepositoryTargetContentMirrorVisitor<ContentData>
    {
        internal static ContentCaptureVisitor Instance { get; } = new();

        public ContentData VisitCommitObject(
            string owner,
            string commit,
            string path,
            string blob,
            ReadOnlyMemory<byte> bytes) => new(
                ContentKind.Commit,
                owner,
                commit,
                path,
                blob,
                bytes.ToArray());

        public ContentData VisitCapturedSnapshotPath(
            string owner,
            string capture,
            string path,
            string contentIdentity,
            ReadOnlyMemory<byte> bytes) => new(
                ContentKind.Captured,
                owner,
                capture,
                path,
                contentIdentity,
                bytes.ToArray());
    }

    private sealed record ParsedRow(
        RowData Data,
        uint? ContentOrdinal = null)
    {
        internal RepositoryTargetResolutionDemandItem Demand => Data.Demand;

        internal RepositoryTargetRowMirror ToCarrier(
            RepositoryTargetContentMirror[] contents)
        {
            RepositoryTargetContentMirror? content = null;
            if (ContentOrdinal is not null)
            {
                if (ContentOrdinal.Value >= contents.Length)
                {
                    throw new InvalidOperationException(
                        "Content ordinal is out of range.");
                }
                content = contents[ContentOrdinal.Value];
            }
            return Data.Kind switch
            {
                RowKind.MissingCommit =>
                    RepositoryTargetRowMirror.MissingCommit(Data.Demand),
                RowKind.PresentCommit =>
                    RepositoryTargetRowMirror.PresentCommit(
                        Data.Demand, Data.Owner!, Data.Type!, Data.Identity!),
                RowKind.PresentCommitMissingPath =>
                    RepositoryTargetRowMirror.PresentCommitMissingPath(
                        Data.Demand, Data.Owner!, Data.Type!, Data.Identity!),
                RowKind.PresentCommitPath =>
                    RepositoryTargetRowMirror.PresentCommitPath(
                        Data.Demand,
                        Data.Owner!,
                        Data.Type!,
                        Data.Identity!,
                        Data.Path!,
                        Data.PathType!,
                        Data.PathIdentity!,
                        content),
                RowKind.MissingTag =>
                    RepositoryTargetRowMirror.MissingTag(Data.Demand),
                RowKind.PresentTag =>
                    RepositoryTargetRowMirror.PresentTag(
                        Data.Demand,
                        Data.Owner!,
                        Data.RefName!,
                        Data.RefType!,
                        Data.RefIdentity!,
                        Data.PeeledType!,
                        Data.PeeledIdentity!),
                RowKind.MissingCaptured =>
                    RepositoryTargetRowMirror.MissingCapturedPath(Data.Demand),
                RowKind.PresentCaptured =>
                    RepositoryTargetRowMirror.PresentCapturedPath(
                        Data.Demand,
                        Data.Owner!,
                        Data.Capture!,
                        Data.Path!,
                        Data.EntryKind!,
                        Data.ContentIdentity!,
                        content ?? throw new InvalidOperationException(
                            "Captured content is required.")),
                _ => throw new InvalidOperationException("Invalid row kind."),
            };
        }

        internal static ParsedRow MissingCommit(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new RowData(RowKind.MissingCommit, demand));

        internal static ParsedRow PresentCommit(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(new RowData(
                RowKind.PresentCommit,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity));

        internal static ParsedRow PresentCommitMissingPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity) => new(new RowData(
                RowKind.PresentCommitMissingPath,
                demand,
                Owner: owner,
                Type: type,
                Identity: identity));

        internal static ParsedRow PresentCommitPath(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string type,
            string identity,
            string path,
            string pathType,
            string pathIdentity,
            uint? contentOrdinal) => new(
                new RowData(
                    RowKind.PresentCommitPath,
                    demand,
                    Owner: owner,
                    Type: type,
                    Identity: identity,
                    Path: path,
                    PathType: pathType,
                    PathIdentity: pathIdentity),
                contentOrdinal);

        internal static ParsedRow MissingTag(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new RowData(RowKind.MissingTag, demand));

        internal static ParsedRow PresentTag(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string refName,
            string refType,
            string refIdentity,
            string peeledType,
            string peeledIdentity) => new(new RowData(
                RowKind.PresentTag,
                demand,
                Owner: owner,
                RefName: refName,
                RefType: refType,
                RefIdentity: refIdentity,
                PeeledType: peeledType,
                PeeledIdentity: peeledIdentity));

        internal static ParsedRow MissingCaptured(
            RepositoryTargetResolutionDemandItem demand) =>
            new(new RowData(RowKind.MissingCaptured, demand));

        internal static ParsedRow PresentCaptured(
            RepositoryTargetResolutionDemandItem demand,
            string owner,
            string capture,
            string path,
            string entryKind,
            string contentIdentity,
            uint contentOrdinal) => new(
                new RowData(
                    RowKind.PresentCaptured,
                    demand,
                    Owner: owner,
                    Path: path,
                    Capture: capture,
                    EntryKind: entryKind,
                    ContentIdentity: contentIdentity),
                contentOrdinal);
    }

    private ref struct Reader
    {
        private readonly ReadOnlySpan<byte> _bytes;
        private int _offset;

        internal Reader(ReadOnlySpan<byte> bytes)
        {
            _bytes = bytes;
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

        internal string Text()
        {
            var length = UInt32();
            if (length > int.MaxValue)
            {
                throw new InvalidOperationException("Invalid text length.");
            }
            var value = StrictUtf8.GetString(Read(checked((int)length)));
            return value.Contains('\uFEFF', StringComparison.Ordinal)
                ? throw new InvalidOperationException("UTF-8 BOM is forbidden.")
                : value;
        }

        internal string? OptionalText()
        {
            var present = Byte();
            return present switch
            {
                0 => null,
                1 => Text(),
                _ => throw new InvalidOperationException(
                    "Invalid optional text tag."),
            };
        }

        internal uint? OptionalUInt32()
        {
            var present = Byte();
            return present switch
            {
                0 => null,
                1 => UInt32(),
                _ => throw new InvalidOperationException(
                    "Invalid optional integer tag."),
            };
        }

        internal byte Byte() => Read(1)[0];
        internal uint UInt32() => BinaryPrimitives.ReadUInt32BigEndian(Read(4));
        internal long Int64() => BinaryPrimitives.ReadInt64BigEndian(Read(8));
        internal byte[] Bytes(int count) => Read(count).ToArray();

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

    private sealed class ResourceLimitException : Exception;
    private sealed class LocationMismatchException : Exception;
}
