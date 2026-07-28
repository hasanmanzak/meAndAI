using System.IO.Compression;
using System.Security.Cryptography;

namespace MeAndAI.Operations.Packaging;

public static class PortablePackageVerifier
{
    private const int MaximumArchiveEntries = 32;
    private const long MaximumArchiveEntryBytes = 64L * 1024 * 1024;
    private const long MaximumArchiveBytes = 128L * 1024 * 1024;
    private const long MaximumAssetBytes = 130L * 1024 * 1024;

    public static VerifiedPortableRelease Verify(
        PortablePackageVerificationRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(request.Inventory);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.ManifestPath);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AssetDirectory);
        ArgumentNullException.ThrowIfNull(request.RuntimeInventory);

        var assetDirectory = new DirectoryInfo(
            Path.GetFullPath(request.AssetDirectory));
        if (!assetDirectory.Exists ||
            (assetDirectory.Attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new InvalidDataException(
                "Portable asset directory must be one ordinary directory.");
        }

        var expectedManifestPath = Path.Combine(
            assetDirectory.FullName,
            PortableReleaseContract.ManifestFileName);
        var manifestPath = Path.GetFullPath(request.ManifestPath);
        if (!string.Equals(
                manifestPath,
                expectedManifestPath,
                StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException(
                "Portable release manifest has an unexpected path identity.");
        }

        var manifest = OperationsReleaseManifest.Read(manifestPath);
        ValidateManifestIdentity(manifest, request.Inventory);
        ValidateRuntimeInventory(manifest.Runtime, request.RuntimeInventory);

        var verified = new List<VerifiedPortableAsset>(manifest.Assets.Count);
        for (var index = 0; index < manifest.Assets.Count; index++)
        {
            var asset = manifest.Assets[index];
            var package = request.Inventory.Packages[index];
            ValidateAssetIdentity(asset, package);
            var assetPath = Path.Combine(assetDirectory.FullName, asset.AssetName);
            var file = new FileInfo(assetPath);
            if (!file.Exists ||
                (file.Attributes & FileAttributes.ReparsePoint) != 0 ||
                file.Length != asset.Length ||
                !string.Equals(
                    ComputeSha256(file.FullName),
                    asset.Sha256,
                    StringComparison.Ordinal))
            {
                throw new InvalidDataException(
                    $"Portable asset '{asset.AssetName}' length or digest does not match.");
            }

            ValidateArchive(file.FullName, package);
            verified.Add(new VerifiedPortableAsset(
                asset.Application,
                file.FullName,
                asset.EntryAssembly,
                asset.ContractSchema));
        }

        var expectedFiles = request.Inventory.Packages
            .Select(package => package.AssetName)
            .Append(PortableReleaseContract.ManifestFileName)
            .Order(StringComparer.Ordinal)
            .ToArray();
        var actualFiles = assetDirectory
            .EnumerateFiles("*", SearchOption.TopDirectoryOnly)
            .Select(file => file.Name)
            .Order(StringComparer.Ordinal)
            .ToArray();
        if (!actualFiles.SequenceEqual(expectedFiles, StringComparer.Ordinal) ||
            assetDirectory.EnumerateDirectories().Any())
        {
            throw new InvalidDataException(
                "Portable asset directory contains an unexpected file or directory.");
        }

        return new VerifiedPortableRelease(manifest, [.. verified]);
    }

    private static void ValidateManifestIdentity(
        OperationsReleaseManifest manifest,
        OperationsPackageInventory inventory)
    {
        if (manifest.ManifestSchema != PortableReleaseContract.ManifestSchemaVersion ||
            !string.Equals(
                manifest.Kind,
                "meandai.operations.release",
                StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(manifest.SourceCommit))
        {
            throw new InvalidDataException(
                "Portable release manifest has an unsupported schema or kind.");
        }

        PortablePackageBuilder.ValidateSourceCommit(manifest.SourceCommit);
        if (!string.Equals(
                manifest.Runtime.Framework,
                PortableReleaseContract.RuntimeFramework,
                StringComparison.Ordinal) ||
            !string.Equals(
                manifest.Runtime.TargetFramework,
                PortableReleaseContract.TargetFramework,
                StringComparison.Ordinal) ||
            !string.Equals(
                manifest.Runtime.MinimumVersion,
                PortableReleaseContract.MinimumRuntimeVersion,
                StringComparison.Ordinal) ||
            !string.Equals(
                manifest.Runtime.RollForward,
                PortableReleaseContract.RollForward,
                StringComparison.Ordinal) ||
            !string.Equals(
                manifest.SchemaCompatibility.Name,
                "meandai.operations.application",
                StringComparison.Ordinal) ||
            manifest.SchemaCompatibility.Minimum !=
                PortableReleaseContract.ApplicationContractSchemaVersion ||
            manifest.SchemaCompatibility.Maximum !=
                PortableReleaseContract.ApplicationContractSchemaVersion ||
            manifest.Assets.Count != inventory.Packages.Count)
        {
            throw new InvalidDataException(
                "Portable release manifest runtime or schema identity is incompatible.");
        }
    }

    private static void ValidateRuntimeInventory(
        PortableRuntimeContract runtime,
        string runtimeInventory)
    {
        var minimum = Version.Parse(runtime.MinimumVersion);
        var compatible = runtimeInventory
            .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Trim())
            .Where(line => line.StartsWith(
                runtime.Framework + " ",
                StringComparison.Ordinal))
            .Select(line => ParseRuntimeVersion(line, runtime.Framework))
            .Any(version =>
                version is not null &&
                version.Major == minimum.Major &&
                version.Minor == minimum.Minor &&
                version >= minimum);

        if (!compatible)
        {
            throw new InvalidDataException(
                "A compatible stable Microsoft.NETCore.App runtime is not installed.");
        }
    }

    private static Version? ParseRuntimeVersion(string line, string framework)
    {
        var versionStart = framework.Length + 1;
        var versionEnd = line.IndexOf(" [", versionStart, StringComparison.Ordinal);
        if (versionEnd <= versionStart)
        {
            return null;
        }

        var value = line[versionStart..versionEnd];
        return value.All(character => char.IsAsciiDigit(character) || character == '.') &&
            Version.TryParse(value, out var version)
                ? version
                : null;
    }

    private static void ValidateAssetIdentity(
        OperationsReleaseAsset asset,
        OperationsPackageDefinition package)
    {
        if (!string.Equals(asset.Application, package.Application, StringComparison.Ordinal) ||
            !string.Equals(asset.AssetName, package.AssetName, StringComparison.Ordinal) ||
            !string.Equals(
                asset.EntryAssembly,
                package.EntryAssembly,
                StringComparison.Ordinal) ||
            asset.ContractSchema !=
                PortableReleaseContract.ApplicationContractSchemaVersion ||
            asset.Length is <= 0 or > MaximumAssetBytes ||
            string.IsNullOrWhiteSpace(asset.Sha256) ||
            asset.Sha256.Length != 64 ||
            asset.Sha256.Any(character =>
                !char.IsAsciiHexDigit(character) || char.IsAsciiLetterUpper(character)))
        {
            throw new InvalidDataException(
                "Portable release manifest contains an invalid asset identity.");
        }
    }

    private static void ValidateArchive(
        string assetPath,
        OperationsPackageDefinition package)
    {
        try
        {
            using var stream = File.OpenRead(assetPath);
            using var archive = new ZipArchive(
                stream,
                ZipArchiveMode.Read,
                leaveOpen: false);
            if (archive.Entries.Count is < 3 or > MaximumArchiveEntries)
            {
                throw new InvalidDataException(
                    $"Portable asset '{package.AssetName}' has an invalid entry count.");
            }

            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            long totalLength = 0;
            foreach (var entry in archive.Entries)
            {
                if (!OperationsPackageInventory.IsCanonicalLeaf(entry.FullName) ||
                    !seen.Add(entry.FullName) ||
                    entry.Length is <= 0 or > MaximumArchiveEntryBytes)
                {
                    throw new InvalidDataException(
                        $"Portable asset '{package.AssetName}' contains an unsafe entry.");
                }

                totalLength = checked(totalLength + entry.Length);
                if (totalLength > MaximumArchiveBytes)
                {
                    throw new InvalidDataException(
                        $"Portable asset '{package.AssetName}' exceeds its size limit.");
                }
            }

            var assemblyName = Path.GetFileNameWithoutExtension(package.EntryAssembly);
            var runtimeConfigurationName = $"{assemblyName}.runtimeconfig.json";
            var required = new[]
            {
                package.EntryAssembly,
                $"{assemblyName}.deps.json",
                runtimeConfigurationName,
            };
            if (required.Any(name => !seen.Contains(name)) ||
                seen.Any(name =>
                    string.Equals(name, assemblyName, StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".so", StringComparison.OrdinalIgnoreCase) ||
                    name.EndsWith(".dylib", StringComparison.OrdinalIgnoreCase)))
            {
                throw new InvalidDataException(
                    $"Portable asset '{package.AssetName}' is incomplete or platform-specific.");
            }

            var runtimeConfiguration = archive.GetEntry(runtimeConfigurationName)
                ?? throw new InvalidDataException(
                    $"Portable asset '{package.AssetName}' has no runtime configuration.");
            using var configurationStream = runtimeConfiguration.Open();
            PortablePackageBuilder.ValidateRuntimeConfiguration(
                configurationStream,
                $"Runtime configuration in '{package.AssetName}'");
        }
        catch (InvalidDataException)
        {
            throw;
        }
        catch (Exception exception) when (
            exception is IOException or NotSupportedException or OverflowException)
        {
            throw new InvalidDataException(
                $"Portable asset '{package.AssetName}' could not be verified.",
                exception);
        }
    }

    private static string ComputeSha256(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
    }
}
