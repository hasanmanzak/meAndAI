namespace MeAndAI.Operations.Packaging;

public sealed class OperationsPackageInventory
{
    private static readonly string[] ExpectedApplications =
        ["adoption", "consumer-update", "governance"];

    private OperationsPackageInventory(
        int schema,
        string kind,
        OperationsPackageDefinition[] packages)
    {
        Schema = schema;
        Kind = kind;
        Packages = Array.AsReadOnly(packages);
    }

    public int Schema { get; }

    public string Kind { get; }

    public IReadOnlyList<OperationsPackageDefinition> Packages { get; }

    public static OperationsPackageInventory Read(string path)
    {
        var document = StrictJson.Read<InventoryDocument>(
            path,
            "Operations package inventory");
        if (document.Schema != 1 ||
            !string.Equals(
                document.Kind,
                "meandai.operations.packages",
                StringComparison.Ordinal) ||
            document.Packages is null ||
            document.Packages.Length != ExpectedApplications.Length ||
            document.Packages.Any(package => package is null))
        {
            throw new InvalidDataException(
                "Operations package inventory has an unsupported identity or shape.");
        }

        var definitions = document.Packages
            .Select(package => ValidateDefinition(package!))
            .ToArray();
        if (!definitions
                .Select(definition => definition.Application)
                .SequenceEqual(ExpectedApplications, StringComparer.Ordinal) ||
            definitions.Select(definition => definition.ProjectPath)
                .Distinct(StringComparer.Ordinal).Count() != definitions.Length ||
            definitions.Select(definition => definition.AssetName)
                .Distinct(StringComparer.Ordinal).Count() != definitions.Length ||
            definitions.Select(definition => definition.EntryAssembly)
                .Distinct(StringComparer.Ordinal).Count() != definitions.Length)
        {
            throw new InvalidDataException(
                "Operations package inventory identities are missing, duplicated, or unordered.");
        }

        return new OperationsPackageInventory(
            document.Schema,
            document.Kind,
            definitions);
    }

    private static OperationsPackageDefinition ValidateDefinition(
        PackageDocument document)
    {
        if (!IsCanonicalIdentifier(document.Application) ||
            !IsCanonicalRelativePath(document.ProjectPath) ||
            !document.ProjectPath.StartsWith("src/", StringComparison.Ordinal) ||
            !document.ProjectPath.EndsWith(".csproj", StringComparison.Ordinal) ||
            !IsCanonicalLeaf(document.AssetName) ||
            !document.AssetName.StartsWith("maai-", StringComparison.Ordinal) ||
            !document.AssetName.EndsWith(".zip", StringComparison.Ordinal) ||
            !string.Equals(
                document.AssetName,
                document.AssetName.ToLowerInvariant(),
                StringComparison.Ordinal) ||
            !IsCanonicalLeaf(document.EntryAssembly) ||
            !document.EntryAssembly.StartsWith(
                "MeAndAI.Operations.",
                StringComparison.Ordinal) ||
            !document.EntryAssembly.EndsWith(".dll", StringComparison.Ordinal))
        {
            throw new InvalidDataException(
                "Operations package inventory contains an unsafe or unsupported mapping.");
        }

        return new OperationsPackageDefinition(
            document.Application,
            document.ProjectPath,
            document.AssetName,
            document.EntryAssembly);
    }

    internal static bool IsCanonicalLeaf(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        value.Length <= 128 &&
        !value.Contains('/') &&
        !value.Contains('\\') &&
        value is not "." and not ".." &&
        value.All(character =>
            char.IsAsciiLetterOrDigit(character) ||
            character is '.' or '-' or '_');

    internal static bool IsCanonicalRelativePath(string? value)
    {
        if (string.IsNullOrWhiteSpace(value) ||
            value.Length > 256 ||
            value.StartsWith('/') ||
            value.EndsWith('/') ||
            value.Contains('\\'))
        {
            return false;
        }

        var segments = value.Split('/');
        return segments.Length > 1 && segments.All(IsCanonicalLeaf);
    }

    private static bool IsCanonicalIdentifier(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        value.Length <= 32 &&
        value.All(character =>
            char.IsAsciiLetterOrDigit(character) || character == '-');

    private sealed class InventoryDocument
    {
        public int Schema { get; init; }

        public string Kind { get; init; } = string.Empty;

        public PackageDocument?[]? Packages { get; init; }
    }

    private sealed class PackageDocument
    {
        public string Application { get; init; } = string.Empty;

        public string ProjectPath { get; init; } = string.Empty;

        public string AssetName { get; init; } = string.Empty;

        public string EntryAssembly { get; init; } = string.Empty;
    }
}

public sealed class OperationsPackageDefinition
{
    internal OperationsPackageDefinition(
        string application,
        string projectPath,
        string assetName,
        string entryAssembly)
    {
        Application = application;
        ProjectPath = projectPath;
        AssetName = assetName;
        EntryAssembly = entryAssembly;
    }

    public string Application { get; }

    public string ProjectPath { get; }

    public string AssetName { get; }

    public string EntryAssembly { get; }
}
