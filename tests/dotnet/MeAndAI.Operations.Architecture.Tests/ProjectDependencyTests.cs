using System.Xml.Linq;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ProjectDependencyTests
{
    private static readonly string RepositoryRoot = FindRepositoryRoot();
    private static readonly string[] ProductionSourceRoots = ["src", "tools"];
    private static readonly string[] ChildProcessPrimitiveTokens =
    [
        "using System.Diagnostics;",
        "ProcessStartInfo",
        "System.Diagnostics.Process",
        "Process.Start(",
        "new Process",
        "WaitForExitAsync(",
        "Kill(entireProcessTree:",
        "RedirectStandardOutput",
    ];
    private static readonly string[] PackagingJsonParserTokens =
    [
        "JsonDocument.Parse(",
        "JsonNode.Parse(",
        "JsonSerializer.Deserialize",
        "Utf8JsonReader",
    ];
    private static readonly string[] PackagingTextDecoderTokens =
    [
        "UTF8Encoding",
        "Encoding.UTF8.GetString",
        "DecoderFallbackException",
    ];

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    [Trait("Scenario", "TEST-0192")]
    public void ProductionDependencyDirectionIsInwardOnly()
    {
        const string domain =
            "src/MeAndAI.Operations.Domain/MeAndAI.Operations.Domain.csproj";
        const string application =
            "src/MeAndAI.Operations.Application/MeAndAI.Operations.Application.csproj";
        const string infrastructure =
            "src/MeAndAI.Operations.Infrastructure/MeAndAI.Operations.Infrastructure.csproj";
        const string adoption =
            "src/MeAndAI.Operations.Adoption/MeAndAI.Operations.Adoption.csproj";
        const string consumerUpdate =
            "src/MeAndAI.Operations.ConsumerUpdate/MeAndAI.Operations.ConsumerUpdate.csproj";
        const string governance =
            "src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj";
        const string governanceCore =
            "src/MeAndAI.Operations.Governance.Core/MeAndAI.Operations.Governance.Core.csproj";
        const string packaging =
            "tools/MeAndAI.Operations.Packaging/MeAndAI.Operations.Packaging.csproj";

        Assert.Empty(ReadProjectReferences(domain));
        Assert.Equal([domain], ReadProjectReferences(application));
        Assert.Equal([application, domain], ReadProjectReferences(infrastructure));
        Assert.Equal([domain, infrastructure], ReadProjectReferences(adoption));
        Assert.Equal([domain, infrastructure], ReadProjectReferences(consumerUpdate));
        Assert.Equal(
            [domain, governanceCore, infrastructure],
            ReadProjectReferences(governance));
        Assert.Equal(
            [application, domain],
            ReadProjectReferences(governanceCore));
        Assert.Equal([domain, infrastructure], ReadProjectReferences(packaging));
        Assert.Empty(ReadPackageReferences(domain));
        Assert.Empty(ReadPackageReferences(application));
        Assert.Empty(ReadPackageReferences(infrastructure));
        Assert.Empty(ReadPackageReferences(adoption));
        Assert.Empty(ReadPackageReferences(consumerUpdate));
        Assert.Empty(ReadPackageReferences(governance));
        Assert.Empty(ReadPackageReferences(governanceCore));
        Assert.Empty(ReadPackageReferences(packaging));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    [Trait("Scenario", "TEST-0192")]
    public void SolutionContainsOnlyTheAuthorizedFoundationProjects()
    {
        var solutionPath = Path.Combine(
            RepositoryRoot,
            "MeAndAI.Operations.slnx");
        var document = XDocument.Load(solutionPath);
        var projects = document
            .Descendants("Project")
            .Select(element => NormalizePath((string?)element.Attribute("Path")))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            [
                "src/MeAndAI.Operations.Adoption/MeAndAI.Operations.Adoption.csproj",
                "src/MeAndAI.Operations.Application/MeAndAI.Operations.Application.csproj",
                "src/MeAndAI.Operations.ConsumerUpdate/MeAndAI.Operations.ConsumerUpdate.csproj",
                "src/MeAndAI.Operations.Domain/MeAndAI.Operations.Domain.csproj",
                "src/MeAndAI.Operations.Governance.Core/MeAndAI.Operations.Governance.Core.csproj",
                "src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj",
                "src/MeAndAI.Operations.Infrastructure/MeAndAI.Operations.Infrastructure.csproj",
                "tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj",
                "tests/dotnet/MeAndAI.Operations.Governance.Tests/MeAndAI.Operations.Governance.Tests.csproj",
                "tests/dotnet/MeAndAI.Operations.Packaging.Tests/MeAndAI.Operations.Packaging.Tests.csproj",
                "tools/MeAndAI.Operations.Packaging/MeAndAI.Operations.Packaging.csproj",
            ],
            projects);
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void InfrastructureIsTheOnlyProductionChildProcessOwner()
    {
        var owners = ProductionSourceRoots
            .SelectMany(root => Directory.EnumerateFiles(
                Path.Combine(RepositoryRoot, root),
                "*.cs",
                SearchOption.AllDirectories))
            .Where(path => !HasBuildArtifactSegment(path))
            .Where(OwnsChildProcessPrimitive)
            .Select(path => NormalizePath(
                Path.GetRelativePath(RepositoryRoot, path)))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            ["src/MeAndAI.Operations.Infrastructure/Execution/BoundedProcessRunner.cs"],
            owners);
        Assert.False(File.Exists(Path.Combine(
            RepositoryRoot,
            "tools",
            "MeAndAI.Operations.Packaging",
            "BoundedProcess.cs")));
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    [Trait("Scenario", "TEST-0192")]
    public void ProcessKernelIsInternalAndPackagingConsumesItDirectly()
    {
        Assert.All(
            [
                typeof(BoundedProcessRequest),
                typeof(BoundedProcessResult),
                typeof(BoundedProcessRunner),
            ],
            type => Assert.False(type.IsVisible));

        var consumers = EnumeratePackagingSources()
            .Select(path => new
            {
                Path = NormalizePath(Path.GetRelativePath(RepositoryRoot, path)),
                References = CountOccurrences(
                    File.ReadAllText(path),
                    nameof(BoundedProcessRunner)),
            })
            .Where(candidate => candidate.References > 0)
            .Select(candidate => $"{candidate.Path}:{candidate.References}")
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            [
                "tools/MeAndAI.Operations.Packaging/PackagingCli.cs:4",
                "tools/MeAndAI.Operations.Packaging/PortablePackageExecutor.cs:1",
            ],
            consumers);
    }

    [Fact]
    [Trait("Scenario", "TEST-0191")]
    public void PackagingJsonParsingAndTextDecodingAreSingleOwned()
    {
        Assert.Equal(
            ["tools/MeAndAI.Operations.Packaging/StrictJson.cs"],
            FindPackagingOwners(PackagingJsonParserTokens));
        Assert.Equal(
            ["tools/MeAndAI.Operations.Packaging/StrictUtf8.cs"],
            FindPackagingOwners(PackagingTextDecoderTokens));
    }

    private static string[] ReadProjectReferences(string projectPath)
    {
        var fullPath = Path.Combine(
            RepositoryRoot,
            projectPath.Replace('/', Path.DirectorySeparatorChar));
        var projectDirectory = Path.GetDirectoryName(fullPath)
            ?? throw new InvalidOperationException("Project directory is missing.");
        var document = XDocument.Load(fullPath);

        return
        [
            .. document
                .Descendants("ProjectReference")
                .Select(element => (string?)element.Attribute("Include"))
                .Select(path => Path.GetFullPath(
                    path ?? throw new InvalidDataException(
                        "ProjectReference has no Include attribute."),
                    projectDirectory))
                .Select(path => NormalizePath(
                    Path.GetRelativePath(RepositoryRoot, path)))
                .Order(StringComparer.Ordinal),
        ];
    }

    private static string[] ReadPackageReferences(string projectPath)
    {
        var fullPath = Path.Combine(
            RepositoryRoot,
            projectPath.Replace('/', Path.DirectorySeparatorChar));
        var document = XDocument.Load(fullPath);

        return
        [
            .. document
                .Descendants("PackageReference")
                .Select(element => (string?)element.Attribute("Include"))
                .Select(package => package ?? throw new InvalidDataException(
                    "PackageReference has no Include attribute."))
                .Order(StringComparer.Ordinal),
        ];
    }

    private static string FindRepositoryRoot()
    {
        var candidate = new DirectoryInfo(AppContext.BaseDirectory);

        while (candidate is not null)
        {
            if (File.Exists(Path.Combine(candidate.FullName, "MeAndAI.Operations.slnx")))
            {
                return candidate.FullName;
            }

            candidate = candidate.Parent;
        }

        throw new DirectoryNotFoundException(
            "Could not locate the repository root from the test output directory.");
    }

    private static bool HasBuildArtifactSegment(string path) =>
        NormalizePath(Path.GetRelativePath(RepositoryRoot, path))
            .Split('/')
            .Any(segment =>
                string.Equals(segment, "bin", StringComparison.Ordinal) ||
                string.Equals(segment, "obj", StringComparison.Ordinal));

    private static bool OwnsChildProcessPrimitive(string path)
    {
        var source = File.ReadAllText(path);
        return ChildProcessPrimitiveTokens.Any(token =>
            source.Contains(token, StringComparison.Ordinal));
    }

    private static IEnumerable<string> EnumeratePackagingSources() =>
        Directory
            .EnumerateFiles(
                Path.Combine(
                    RepositoryRoot,
                    "tools",
                    "MeAndAI.Operations.Packaging"),
                "*.cs",
                SearchOption.AllDirectories)
            .Where(path => !HasBuildArtifactSegment(path));

    private static string[] FindPackagingOwners(IReadOnlyList<string> tokens) =>
    [
        .. EnumeratePackagingSources()
            .Where(path =>
            {
                var source = File.ReadAllText(path);
                return tokens.Any(token =>
                    source.Contains(token, StringComparison.Ordinal));
            })
            .Select(path => NormalizePath(
                Path.GetRelativePath(RepositoryRoot, path)))
            .Order(StringComparer.Ordinal),
    ];

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var offset = 0;
        while ((offset = source.IndexOf(
                   value,
                   offset,
                   StringComparison.Ordinal)) >= 0)
        {
            count++;
            offset += value.Length;
        }

        return count;
    }

    private static string NormalizePath(string? path) =>
        (path ?? throw new InvalidDataException("A project path is missing."))
        .Replace('\\', '/');
}
