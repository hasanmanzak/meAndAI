using System.IO.Compression;
using System.Text.Json;

namespace MeAndAI.Operations.Packaging;

public static class PortablePackageExecutor
{
    public static IReadOnlyList<ExecutedPortableAsset> Execute(
        VerifiedPortableRelease release,
        string dotnetExecutable = "dotnet")
    {
        ArgumentNullException.ThrowIfNull(release);
        ArgumentException.ThrowIfNullOrWhiteSpace(dotnetExecutable);
        var temporaryRoot = Path.Combine(
            Path.GetTempPath(),
            $"meandai-portable-execution-{Guid.NewGuid():N}");
        Directory.CreateDirectory(temporaryRoot);

        try
        {
            var results = new List<ExecutedPortableAsset>(release.Assets.Count);
            foreach (var asset in release.Assets)
            {
                var extraction = Path.Combine(temporaryRoot, asset.Application);
                Directory.CreateDirectory(extraction);
                ExtractVerifiedArchive(asset.AssetPath, extraction);
                var entryAssembly = Path.Combine(extraction, asset.EntryAssembly);
                var process = BoundedProcess.Run(
                    dotnetExecutable,
                    [entryAssembly, "--describe-contract"],
                    extraction,
                    TimeSpan.FromSeconds(30));
                if (process.ExitCode != 0 ||
                    !string.IsNullOrWhiteSpace(process.StandardError))
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

            return Array.AsReadOnly(results.ToArray());
        }
        finally
        {
            if (Directory.Exists(temporaryRoot))
            {
                Directory.Delete(temporaryRoot, recursive: true);
            }
        }
    }

    private static void ExtractVerifiedArchive(string assetPath, string extraction)
    {
        using var stream = File.OpenRead(assetPath);
        using var archive = new ZipArchive(
            stream,
            ZipArchiveMode.Read,
            leaveOpen: false);
        foreach (var entry in archive.Entries)
        {
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
            source.CopyTo(target);
        }
    }

    private static void ValidateDescriptor(
        string output,
        string expectedApplication,
        int expectedSchema)
    {
        try
        {
            using var document = JsonDocument.Parse(output);
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object)
            {
                throw new InvalidDataException(
                    $"Portable application '{expectedApplication}' returned mismatched identity.");
            }

            var properties = root.EnumerateObject().ToArray();
            if (properties.Length != 2 ||
                properties.Select(property => property.Name)
                    .Distinct(StringComparer.Ordinal).Count() != 2 ||
                !string.Equals(
                    root.GetProperty("application").GetString(),
                    expectedApplication,
                    StringComparison.Ordinal) ||
                root.GetProperty("contractSchemaVersion").GetInt32() != expectedSchema)
            {
                throw new InvalidDataException(
                    $"Portable application '{expectedApplication}' returned mismatched identity.");
            }
        }
        catch (JsonException exception)
        {
            throw new InvalidDataException(
                $"Portable application '{expectedApplication}' returned invalid JSON.",
                exception);
        }
    }
}

public sealed record ExecutedPortableAsset(
    string Application,
    int ContractSchema);
