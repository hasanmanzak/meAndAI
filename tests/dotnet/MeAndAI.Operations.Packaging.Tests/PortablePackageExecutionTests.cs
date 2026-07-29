using System.IO.Compression;
using System.Text;
using MeAndAI.Operations.Infrastructure.Execution;
using MeAndAI.Operations.Packaging;

namespace MeAndAI.Operations.Packaging.Tests;

public sealed class PortablePackageExecutionTests
{
    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void RuntimeConfigurationUsesTheSharedStrictJsonBoundary()
    {
        var duplicateProperty = Encoding.UTF8.GetBytes(
            """
            {"runtimeOptions":{},"runtimeOptions":{}}
            """);
        var bom = new byte[]
        {
            0xef,
            0xbb,
            0xbf,
            (byte)'{',
            (byte)'}',
        };

        foreach (var payload in new[] { duplicateProperty, bom })
        {
            using var stream = new MemoryStream(payload);
            var exception = Assert.Throws<InvalidDataException>(() =>
                PortablePackageBuilder.ValidateRuntimeConfiguration(
                    stream,
                    "Runtime fixture"));

            Assert.Equal(
                "Runtime fixture is not valid runtime configuration JSON.",
                exception.Message);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void ExactDescriptorShapeIsAccepted()
    {
        PortablePackageExecutor.ValidateDescriptor(
            Encoding.UTF8.GetBytes(
                """
                {"application":"fixture","contractSchemaVersion":1}
                """),
            "fixture",
            1);
    }

    [Theory]
    [Trait("Scenario", "TEST-0193")]
    [InlineData("{}")]
    [InlineData("{\"name\":\"fixture\",\"schema\":1}")]
    [InlineData("{\"application\":\"fixture\",\"contractSchemaVersion\":\"1\"}")]
    [InlineData("{\"application\":\"fixture\",\"contractSchemaVersion\":2147483648}")]
    [InlineData("{\"application\":\"fixture\",\"contractSchemaVersion\":1,\"extra\":true}")]
    [InlineData("{\"application\":\"fixture\",\"application\":\"fixture\",\"contractSchemaVersion\":1}")]
    public void DescriptorShapeOrTypeDriftFailsAsControlledData(string json)
    {
        var exception = Assert.Throws<InvalidDataException>(() =>
            PortablePackageExecutor.ValidateDescriptor(
                Encoding.UTF8.GetBytes(json),
                "fixture",
                1));

        Assert.StartsWith(
            "Portable application 'fixture' returned ",
            exception.Message,
            StringComparison.Ordinal);
        Assert.Null(exception.InnerException);
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void InvalidUtf8DescriptorFailsWithoutParserDiagnostics()
    {
        var exception = Assert.Throws<InvalidDataException>(() =>
            PortablePackageExecutor.ValidateDescriptor(
                new byte[] { 0xff, 0xfe },
                "fixture",
                1));

        Assert.Equal(
            "Portable application 'fixture' returned invalid JSON.",
            exception.Message);
        Assert.Null(exception.InnerException);
    }

    [Theory]
    [Trait("Scenario", "TEST-0193")]
    [InlineData("", true)]
    [InlineData(" \t\r\n", true)]
    [InlineData("diagnostic", false)]
    public void ProcessTextWhitespacePolicyRemainsCompatible(
        string value,
        bool expected)
    {
        Assert.Equal(
            expected,
            StrictUtf8.IsNullOrWhiteSpace(Encoding.UTF8.GetBytes(value)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void InvalidUtf8ProcessTextFailsWithoutDecoderDiagnostics()
    {
        var exception = Assert.Throws<InvalidDataException>(() =>
            StrictUtf8.IsNullOrWhiteSpace(new byte[] { 0xff }));

        Assert.Equal(
            "Process dependency returned invalid UTF-8 text.",
            exception.Message);
        Assert.Null(exception.InnerException);
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public async Task NonzeroPortableProcessFailsClosedAndRemovesTemporaryState()
    {
        using var fixture = ExecutionFixture.Create();
        var before = SnapshotExecutionDirectories();

        var exception = await Assert.ThrowsAsync<InvalidDataException>(() =>
            PortablePackageExecutor.ExecuteAsync(fixture.Release))
            .ConfigureAwait(true);

        Assert.Equal(
            "Portable application 'fixture' did not run cleanly.",
            exception.Message);
        Assert.Null(exception.InnerException);
        Assert.Equal(before, SnapshotExecutionDirectories());
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public async Task StartFailureIsRedactedAndRemovesTemporaryState()
    {
        using var fixture = ExecutionFixture.Create();
        var before = SnapshotExecutionDirectories();
        var secret = "missing-secret-" + Guid.NewGuid().ToString("N");
        var executable = Path.Combine(fixture.Root, secret);

        var exception = await Assert.ThrowsAsync<OperationalDependencyException>(() =>
            PortablePackageExecutor.ExecuteAsync(
                fixture.Release,
                executable))
            .ConfigureAwait(true);

        Assert.Equal("Process dependency could not be started.", exception.Message);
        Assert.DoesNotContain(secret, exception.ToString(), StringComparison.Ordinal);
        Assert.Null(exception.InnerException);
        Assert.Equal(before, SnapshotExecutionDirectories());
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public async Task PreCanceledExecutionCreatesNoTemporaryStateAndPreservesToken()
    {
        using var fixture = ExecutionFixture.Create();
        var before = SnapshotExecutionDirectories();
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();

        var exception = await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            PortablePackageExecutor.ExecuteAsync(
                fixture.Release,
                cancellationToken: cancellation.Token))
            .ConfigureAwait(true);

        Assert.Equal(cancellation.Token, exception.CancellationToken);
        Assert.Equal(before, SnapshotExecutionDirectories());
    }

    private static string[] SnapshotExecutionDirectories() =>
    [
        .. Directory
            .EnumerateDirectories(
                Path.GetTempPath(),
                "meandai-portable-execution-*",
                SearchOption.TopDirectoryOnly)
            .Select(Path.GetFullPath)
            .Order(StringComparer.Ordinal),
    ];

    private sealed class ExecutionFixture : IDisposable
    {
        private ExecutionFixture(string root, VerifiedPortableRelease release)
        {
            Root = root;
            Release = release;
        }

        internal string Root { get; }

        internal VerifiedPortableRelease Release { get; }

        internal static ExecutionFixture Create()
        {
            var root = Path.Combine(
                Path.GetTempPath(),
                "meandai-executor-tests-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            const string application = "fixture";
            const string assetName = "fixture.zip";
            const string entryAssembly = "fixture.dll";
            var assetPath = Path.Combine(root, assetName);
            using (var archive = ZipFile.Open(assetPath, ZipArchiveMode.Create))
            {
                var entry = archive.CreateEntry(entryAssembly);
                using var writer = new StreamWriter(
                    entry.Open(),
                    new UTF8Encoding(false),
                    leaveOpen: false);
                writer.Write("not-a-managed-assembly");
            }

            var releaseAsset = new OperationsReleaseAsset(
                application,
                assetName,
                entryAssembly,
                1,
                new FileInfo(assetPath).Length,
                new string('0', 64));
            var manifest = new OperationsReleaseManifest(
                1,
                "meandai.operations.release",
                "0123456789abcdef0123456789abcdef01234567",
                new PortableRuntimeContract(
                    "Microsoft.NETCore.App",
                    "net10.0",
                    "10.0.0",
                    "LatestPatch"),
                new PortableSchemaCompatibility(
                    "meandai.operations.application",
                    1,
                    1),
                [releaseAsset]);
            var release = new VerifiedPortableRelease(
                manifest,
                [
                    new VerifiedPortableAsset(
                        application,
                        assetPath,
                        entryAssembly,
                        1),
                ]);
            return new ExecutionFixture(root, release);
        }

        public void Dispose()
        {
            if (Directory.Exists(Root))
            {
                Directory.Delete(Root, recursive: true);
            }
        }
    }
}
