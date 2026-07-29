using System.IO.Compression;
using System.Security.Cryptography;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Packaging;

public static class PortablePackageBuilder
{
    private const long MaximumPublishedFileBytes = 64L * 1024 * 1024;
    private const long MaximumPublishedSetBytes = 128L * 1024 * 1024;

    private static readonly DateTimeOffset FixedArchiveTimestamp =
        new(1980, 1, 1, 0, 0, 0, TimeSpan.Zero);

    public static OperationsReleaseManifest Build(
        PortablePackageBuildRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        ValidateSourceCommit(request.SourceCommit);
        ArgumentNullException.ThrowIfNull(request.Inventory);
        ArgumentNullException.ThrowIfNull(request.PublishDirectories);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.OutputDirectory);

        if (request.PublishDirectories.Count != request.Inventory.Packages.Count)
        {
            throw new InvalidDataException(
                "Published application directory identity is incomplete or unexpected.");
        }

        var output = ValidateOutputPath(request.OutputDirectory);
        var staging = Path.Combine(
            output.Parent?.FullName
                ?? throw new InvalidDataException("Package output has no parent."),
            $".meandai-package-staging-{Guid.NewGuid():N}");
        Directory.CreateDirectory(staging);

        try
        {
            var assets = new List<OperationsReleaseAsset>(
                request.Inventory.Packages.Count);
            foreach (var package in request.Inventory.Packages)
            {
                if (!request.PublishDirectories.TryGetValue(
                        package.Application,
                        out var publishDirectory))
                {
                    throw new InvalidDataException(
                        $"Published output for '{package.Application}' is absent.");
                }

                var files = ValidatePublishedOutput(package, publishDirectory);
                var assetPath = Path.Combine(staging, package.AssetName);
                CreateArchive(files, assetPath);
                var asset = new FileInfo(assetPath);
                assets.Add(new OperationsReleaseAsset(
                    package.Application,
                    package.AssetName,
                    package.EntryAssembly,
                    PortableReleaseContract.ApplicationContractSchemaVersion,
                    asset.Length,
                    ComputeSha256(asset.FullName)));
            }

            var manifest = new OperationsReleaseManifest(
                PortableReleaseContract.ManifestSchemaVersion,
                "meandai.operations.release",
                request.SourceCommit,
                new PortableRuntimeContract(
                    PortableReleaseContract.RuntimeFramework,
                    PortableReleaseContract.TargetFramework,
                    PortableReleaseContract.MinimumRuntimeVersion,
                    PortableReleaseContract.RollForward),
                new PortableSchemaCompatibility(
                    "meandai.operations.application",
                    PortableReleaseContract.ApplicationContractSchemaVersion,
                    PortableReleaseContract.ApplicationContractSchemaVersion),
                [.. assets]);
            File.WriteAllBytes(
                Path.Combine(staging, PortableReleaseContract.ManifestFileName),
                StrictJson.Write(manifest));

            Directory.Move(staging, output.FullName);

            return manifest;
        }
        finally
        {
            if (Directory.Exists(staging))
            {
                Directory.Delete(staging, recursive: true);
            }
        }
    }

    internal static void ValidateSourceCommit(string sourceCommit)
    {
        if (!ExactGitCommitId.TryParse(sourceCommit, out _))
        {
            throw new InvalidDataException(
                "Source commit must be one exact lowercase 40-hex identity.");
        }
    }

    internal static void ValidateRuntimeConfiguration(
        Stream stream,
        string surface)
    {
        ArgumentNullException.ThrowIfNull(stream);
        ArgumentException.ThrowIfNullOrWhiteSpace(surface);

        try
        {
            using var document = StrictJson.Parse(stream, surface);
            var runtimeOptions = document.RootElement.GetProperty("runtimeOptions");
            var framework = runtimeOptions.GetProperty("framework");
            if (!string.Equals(
                    runtimeOptions.GetProperty("tfm").GetString(),
                    PortableReleaseContract.TargetFramework,
                    StringComparison.Ordinal) ||
                !string.Equals(
                    runtimeOptions.GetProperty("rollForward").GetString(),
                    PortableReleaseContract.RollForward,
                    StringComparison.Ordinal) ||
                !string.Equals(
                    framework.GetProperty("name").GetString(),
                    PortableReleaseContract.RuntimeFramework,
                    StringComparison.Ordinal) ||
                !string.Equals(
                    framework.GetProperty("version").GetString(),
                    PortableReleaseContract.MinimumRuntimeVersion,
                    StringComparison.Ordinal))
            {
                throw new InvalidDataException(
                    $"{surface} does not match the portable runtime contract.");
            }
        }
        catch (Exception exception) when (
            exception is InvalidDataException or
            InvalidOperationException or
            KeyNotFoundException)
        {
            throw new InvalidDataException(
                $"{surface} is not valid runtime configuration JSON.",
                exception);
        }
    }

    private static DirectoryInfo ValidateOutputPath(string path)
    {
        var output = new DirectoryInfo(Path.GetFullPath(path));
        if (output.Exists)
        {
            if ((output.Attributes & FileAttributes.ReparsePoint) != 0 ||
                output.EnumerateFileSystemInfos().Any())
            {
                throw new InvalidDataException(
                    "Package output must be absent or one empty ordinary directory.");
            }

            output.Delete();
        }

        var parent = output.Parent;
        if (parent is null ||
            !parent.Exists ||
            (parent.Attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new InvalidDataException(
                "Package output parent must be one ordinary directory.");
        }

        return output;
    }

    private static PublishedFile[] ValidatePublishedOutput(
        OperationsPackageDefinition package,
        string publishDirectory)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(publishDirectory);
        var directory = new DirectoryInfo(Path.GetFullPath(publishDirectory));
        if (!directory.Exists ||
            (directory.Attributes & FileAttributes.ReparsePoint) != 0 ||
            directory.EnumerateDirectories().Any())
        {
            throw new InvalidDataException(
                $"Published output for '{package.Application}' is absent, linked, or not flat.");
        }

        var files = directory
            .EnumerateFiles("*", SearchOption.TopDirectoryOnly)
            .OrderBy(file => file.Name, StringComparer.Ordinal)
            .ToArray();
        if (files.Length is < 3 or > 32 ||
            files.Any(file =>
                (file.Attributes & FileAttributes.ReparsePoint) != 0 ||
                file.Length is <= 0 or > MaximumPublishedFileBytes) ||
            files.Sum(file => file.Length) > MaximumPublishedSetBytes ||
            files.Select(file => file.Name)
                .Distinct(StringComparer.OrdinalIgnoreCase).Count() != files.Length)
        {
            throw new InvalidDataException(
                $"Published output for '{package.Application}' is unsafe or unbounded.");
        }

        var assemblyName = Path.GetFileNameWithoutExtension(package.EntryAssembly);
        var required = new[]
        {
            package.EntryAssembly,
            $"{assemblyName}.deps.json",
            $"{assemblyName}.runtimeconfig.json",
        };
        if (required.Any(name => !files.Any(file =>
                string.Equals(file.Name, name, StringComparison.Ordinal))) ||
            files.Any(file => IsPlatformSpecificPayload(file.Name, assemblyName)))
        {
            throw new InvalidDataException(
                $"Published output for '{package.Application}' is incomplete or platform-specific.");
        }

        var runtimeConfiguration = files.Single(file => string.Equals(
            file.Name,
            $"{assemblyName}.runtimeconfig.json",
            StringComparison.Ordinal));
        using (var stream = runtimeConfiguration.OpenRead())
        {
            ValidateRuntimeConfiguration(
                stream,
                $"Runtime configuration for '{package.Application}'");
        }

        return [.. files.Select(file => new PublishedFile(file.Name, file.FullName))];
    }

    private static bool IsPlatformSpecificPayload(string name, string assemblyName) =>
        string.Equals(name, assemblyName, StringComparison.OrdinalIgnoreCase) ||
        name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) ||
        name.EndsWith(".so", StringComparison.OrdinalIgnoreCase) ||
        name.EndsWith(".dylib", StringComparison.OrdinalIgnoreCase);

    private static void CreateArchive(
        IReadOnlyList<PublishedFile> files,
        string assetPath)
    {
        using var fileStream = new FileStream(
            assetPath,
            FileMode.CreateNew,
            FileAccess.Write,
            FileShare.None);
        using var archive = new ZipArchive(
            fileStream,
            ZipArchiveMode.Create,
            leaveOpen: false);
        foreach (var file in files)
        {
            var entry = archive.CreateEntry(
                file.Name,
                CompressionLevel.NoCompression);
            entry.LastWriteTime = FixedArchiveTimestamp;
            entry.ExternalAttributes = unchecked((int)0x81A40000);
            using var source = File.OpenRead(file.Path);
            using var destination = entry.Open();
            source.CopyTo(destination);
        }
    }

    private static string ComputeSha256(string path)
    {
        using var stream = File.OpenRead(path);
        return ExactSha256Digest
            .FromHashBytes(SHA256.HashData(stream))
            .Value;
    }

    private sealed record PublishedFile(string Name, string Path);
}
