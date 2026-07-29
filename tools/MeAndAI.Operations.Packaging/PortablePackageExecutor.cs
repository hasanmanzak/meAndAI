using System.IO.Compression;
using System.Text.Json;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Packaging;

public static class PortablePackageExecutor
{
    public static async Task<IReadOnlyList<ExecutedPortableAsset>> ExecuteAsync(
        VerifiedPortableRelease release,
        string dotnetExecutable = "dotnet",
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(release);
        ArgumentException.ThrowIfNullOrWhiteSpace(dotnetExecutable);
        cancellationToken.ThrowIfCancellationRequested();
        var temporaryDirectory = PackagingTemporaryDirectory.Create(
            "meandai-portable-execution-");
        var temporaryRoot = temporaryDirectory.FullName;

        try
        {
            var results = new List<ExecutedPortableAsset>(release.Assets.Count);
            foreach (var asset in release.Assets)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var extraction = Path.Combine(temporaryRoot, asset.Application);
                Directory.CreateDirectory(extraction);
                await ExtractVerifiedArchiveAsync(
                        asset.AssetPath,
                        extraction,
                        cancellationToken)
                    .ConfigureAwait(false);
                var entryAssembly = Path.Combine(extraction, asset.EntryAssembly);
                var process = await BoundedProcessRunner.ExecuteAsync(
                        PackagingProcessPolicy.CreateDescriptorRequest(
                            dotnetExecutable,
                            [entryAssembly, "--describe-contract"],
                            extraction),
                        cancellationToken)
                    .ConfigureAwait(false);
                if (process.ExitCode != 0 ||
                    !StrictUtf8.IsNullOrWhiteSpace(process.StandardError))
                {
                    throw new InvalidDataException(
                        $"Portable application '{asset.Application}' did not run cleanly.");
                }

                ValidateDescriptor(
                    process.StandardOutput,
                    asset.Application,
                    asset.ContractSchema);
                results.Add(new ExecutedPortableAsset(
                    asset.Application,
                    asset.ContractSchema));
            }

            cancellationToken.ThrowIfCancellationRequested();
            var completed = Array.AsReadOnly(results.ToArray());
            temporaryDirectory.DeleteOrThrow();
            cancellationToken.ThrowIfCancellationRequested();
            return completed;
        }
        finally
        {
            temporaryDirectory.Dispose();
        }
    }

    private static async Task ExtractVerifiedArchiveAsync(
        string assetPath,
        string extraction,
        CancellationToken cancellationToken)
    {
        using var stream = File.OpenRead(assetPath);
        using var archive = new ZipArchive(
            stream,
            ZipArchiveMode.Read,
            leaveOpen: false);
        foreach (var entry in archive.Entries)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!OperationsPackageInventory.IsCanonicalLeaf(entry.FullName))
            {
                throw new InvalidDataException(
                    "A previously verified archive entry is no longer safe.");
            }

            var destination = Path.Combine(extraction, entry.FullName);
            using var source = entry.Open();
            using var target = new FileStream(
                destination,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None);
            await source.CopyToAsync(target, cancellationToken)
                .ConfigureAwait(false);
        }
    }

    internal static void ValidateDescriptor(
        ReadOnlyMemory<byte> output,
        string expectedApplication,
        int expectedSchema)
    {
        JsonDocument document;
        try
        {
            document = StrictJson.Parse(
                output,
                "Portable application descriptor");
        }
        catch (InvalidDataException)
        {
            throw new InvalidDataException(
                $"Portable application '{expectedApplication}' returned invalid JSON.");
        }

        using (document)
        {
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object ||
                root.EnumerateObject().Count() != 2 ||
                !root.TryGetProperty("application", out var application) ||
                application.ValueKind != JsonValueKind.String ||
                !string.Equals(
                    application.GetString(),
                    expectedApplication,
                    StringComparison.Ordinal) ||
                !root.TryGetProperty(
                    "contractSchemaVersion",
                    out var contractSchemaVersion) ||
                contractSchemaVersion.ValueKind != JsonValueKind.Number ||
                !contractSchemaVersion.TryGetInt32(out var actualSchema) ||
                actualSchema != expectedSchema)
            {
                throw new InvalidDataException(
                    $"Portable application '{expectedApplication}' returned mismatched identity.");
            }
        }
    }
}

public sealed record ExecutedPortableAsset(
    string Application,
    int ContractSchema);
