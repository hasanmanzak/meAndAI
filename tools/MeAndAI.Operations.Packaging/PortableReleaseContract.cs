namespace MeAndAI.Operations.Packaging;

public static class PortableReleaseContract
{
    public const string ManifestFileName =
        "maai-operations-release-manifest.json";

    public const int ManifestSchemaVersion = 1;

    public const int ApplicationContractSchemaVersion = 1;

    public const string RuntimeFramework = "Microsoft.NETCore.App";

    public const string TargetFramework = "net10.0";

    public const string MinimumRuntimeVersion = "10.0.0";

    public const string RollForward = "LatestPatch";
}

public sealed class OperationsReleaseManifest
{
    internal OperationsReleaseManifest(
        int manifestSchema,
        string kind,
        string sourceCommit,
        PortableRuntimeContract runtime,
        PortableSchemaCompatibility schemaCompatibility,
        OperationsReleaseAsset[] assets)
    {
        ManifestSchema = manifestSchema;
        Kind = kind;
        SourceCommit = sourceCommit;
        Runtime = runtime;
        SchemaCompatibility = schemaCompatibility;
        Assets = Array.AsReadOnly(assets);
    }

    public int ManifestSchema { get; }

    public string Kind { get; }

    public string SourceCommit { get; }

    public PortableRuntimeContract Runtime { get; }

    public PortableSchemaCompatibility SchemaCompatibility { get; }

    public IReadOnlyList<OperationsReleaseAsset> Assets { get; }

    internal static OperationsReleaseManifest Read(string path)
    {
        var document = StrictJson.Read<ManifestDocument>(
            path,
            "Operations release manifest");
        if (document.Runtime is null ||
            document.SchemaCompatibility is null ||
            document.Assets is null ||
            document.Assets.Any(asset => asset is null))
        {
            throw new InvalidDataException(
                "Operations release manifest is incomplete.");
        }

        return new OperationsReleaseManifest(
            document.ManifestSchema,
            document.Kind,
            document.SourceCommit,
            new PortableRuntimeContract(
                document.Runtime.Framework,
                document.Runtime.TargetFramework,
                document.Runtime.MinimumVersion,
                document.Runtime.RollForward),
            new PortableSchemaCompatibility(
                document.SchemaCompatibility.Name,
                document.SchemaCompatibility.Minimum,
                document.SchemaCompatibility.Maximum),
            [.. document.Assets.Select(asset => new OperationsReleaseAsset(
                asset!.Application,
                asset.AssetName,
                asset.EntryAssembly,
                asset.ContractSchema,
                asset.Length,
                asset.Sha256))]);
    }

    private sealed class ManifestDocument
    {
        public int ManifestSchema { get; init; }

        public string Kind { get; init; } = string.Empty;

        public string SourceCommit { get; init; } = string.Empty;

        public RuntimeDocument? Runtime { get; init; }

        public SchemaDocument? SchemaCompatibility { get; init; }

        public AssetDocument?[]? Assets { get; init; }
    }

    private sealed class RuntimeDocument
    {
        public string Framework { get; init; } = string.Empty;

        public string TargetFramework { get; init; } = string.Empty;

        public string MinimumVersion { get; init; } = string.Empty;

        public string RollForward { get; init; } = string.Empty;
    }

    private sealed class SchemaDocument
    {
        public string Name { get; init; } = string.Empty;

        public int Minimum { get; init; }

        public int Maximum { get; init; }
    }

    private sealed class AssetDocument
    {
        public string Application { get; init; } = string.Empty;

        public string AssetName { get; init; } = string.Empty;

        public string EntryAssembly { get; init; } = string.Empty;

        public int ContractSchema { get; init; }

        public long Length { get; init; }

        public string Sha256 { get; init; } = string.Empty;
    }
}

public sealed record PortableRuntimeContract(
    string Framework,
    string TargetFramework,
    string MinimumVersion,
    string RollForward);

public sealed record PortableSchemaCompatibility(
    string Name,
    int Minimum,
    int Maximum);

public sealed record OperationsReleaseAsset(
    string Application,
    string AssetName,
    string EntryAssembly,
    int ContractSchema,
    long Length,
    string Sha256);

public sealed record PortablePackageBuildRequest(
    string SourceCommit,
    OperationsPackageInventory Inventory,
    IReadOnlyDictionary<string, string> PublishDirectories,
    string OutputDirectory);

public sealed record PortablePackageVerificationRequest(
    OperationsPackageInventory Inventory,
    string ManifestPath,
    string AssetDirectory,
    string RuntimeInventory);

public sealed class VerifiedPortableRelease
{
    internal VerifiedPortableRelease(
        OperationsReleaseManifest manifest,
        VerifiedPortableAsset[] assets)
    {
        Manifest = manifest;
        Assets = Array.AsReadOnly(assets);
    }

    public OperationsReleaseManifest Manifest { get; }

    public IReadOnlyList<VerifiedPortableAsset> Assets { get; }
}

public sealed record VerifiedPortableAsset(
    string Application,
    string AssetPath,
    string EntryAssembly,
    int ContractSchema);
