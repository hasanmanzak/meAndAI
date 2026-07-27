using System.Xml.Linq;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ProjectDependencyTests
{
    private static readonly string RepositoryRoot = FindRepositoryRoot();

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

        Assert.Empty(ReadProjectReferences(domain));
        Assert.Equal([domain], ReadProjectReferences(application));
        Assert.Equal([application, domain], ReadProjectReferences(infrastructure));
        Assert.Empty(ReadPackageReferences(domain));
        Assert.Empty(ReadPackageReferences(application));
        Assert.Empty(ReadPackageReferences(infrastructure));
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
                "src/MeAndAI.Operations.Application/MeAndAI.Operations.Application.csproj",
                "src/MeAndAI.Operations.Domain/MeAndAI.Operations.Domain.csproj",
                "src/MeAndAI.Operations.Infrastructure/MeAndAI.Operations.Infrastructure.csproj",
                "tests/dotnet/MeAndAI.Operations.Architecture.Tests/MeAndAI.Operations.Architecture.Tests.csproj",
            ],
            projects);
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

    private static string NormalizePath(string? path) =>
        (path ?? throw new InvalidDataException("A project path is missing."))
        .Replace('\\', '/');
}
