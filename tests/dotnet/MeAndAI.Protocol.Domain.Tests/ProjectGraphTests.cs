using System.Text.Json;
using System.Xml.Linq;
using Xunit;

namespace MeAndAI.Protocol.Domain.Tests;

public sealed class ProjectGraphTests
{
    private static readonly string RepositoryRoot = FindRepositoryRoot();
    private static readonly string[] ExpectedFrameworkReferences =
        ["Microsoft.NETCore.App"];

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ProtocolSolutionContainsDomainAndDomainTests()
    {
        var solutionPath = Path.Combine(RepositoryRoot, "MeAndAI.Protocol.slnx");
        var document = XDocument.Load(solutionPath);
        var projects = document
            .Descendants("Project")
            .Select(element => NormalizePath((string?)element.Attribute("Path")))
            .Order(StringComparer.Ordinal)
            .ToArray();

        var expectedProjects = new[]
        {
            "src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj",
            "tests/dotnet/MeAndAI.Protocol.Domain.Tests/" +
                "MeAndAI.Protocol.Domain.Tests.csproj",
        };

        Assert.All(
            expectedProjects,
            expectedProject => Assert.Contains(expectedProject, projects));
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void ProjectsDeclareOnlyDomainPlusCentralTestInfrastructure()
    {
        const string domainProject =
            "src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj";
        const string testProject =
            "tests/dotnet/MeAndAI.Protocol.Domain.Tests/" +
            "MeAndAI.Protocol.Domain.Tests.csproj";

        Assert.Empty(ReadProjectReferences(domainProject));
        Assert.Empty(ReadPackageReferences(domainProject));
        Assert.Equal(
            [domainProject],
            ReadProjectReferences(testProject));

        var packageReferences = ReadPackageReferences(testProject);
        Assert.Equal(
            [
                "Microsoft.NET.Test.Sdk",
                "xunit",
                "xunit.runner.visualstudio",
            ],
            packageReferences.Select(reference => reference.Name));
        Assert.All(
            packageReferences,
            reference =>
            {
                Assert.Null(reference.Version);
                Assert.Null(reference.VersionOverride);
            });
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DomainLockContainsOnlyNet10AndNoDependencies()
    {
        var root = ReadJson(
            "src/MeAndAI.Protocol.Domain/packages.lock.json");

        Assert.Equal(2, root.GetProperty("version").GetInt32());
        var framework = GetOnlyFramework(
            root.GetProperty("dependencies"),
            "net10.0");

        Assert.Empty(framework.EnumerateObject());
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void TestLockContainsOnlyExpectedDirectAndProjectDependencies()
    {
        var root = ReadJson(
            "tests/dotnet/MeAndAI.Protocol.Domain.Tests/packages.lock.json");

        Assert.Equal(2, root.GetProperty("version").GetInt32());
        var framework = GetOnlyFramework(
            root.GetProperty("dependencies"),
            "net10.0");
        var declaredDependencies = framework
            .EnumerateObject()
            .Select(dependency => new LockDependency(
                dependency.Name,
                dependency.Value.GetProperty("type").GetString()
                    ?? throw new InvalidDataException(
                        $"Lock dependency '{dependency.Name}' has no type.")))
            .Where(dependency =>
                dependency.Type is "Direct" or "Project")
            .OrderBy(dependency => dependency.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            new[]
            {
                new LockDependency("Microsoft.NET.Test.Sdk", "Direct"),
                new LockDependency("meandai.protocol.domain", "Project"),
                new LockDependency("xunit", "Direct"),
                new LockDependency("xunit.runner.visualstudio", "Direct"),
            },
            declaredDependencies);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void DomainEffectiveRestoreGraphIsBclOnly()
    {
        const string domainProject =
            "src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj";
        var root = ReadJson(
            "src/MeAndAI.Protocol.Domain/obj/project.assets.json");

        var targets = root.GetProperty("targets");
        Assert.Empty(GetOnlyFramework(targets, "net10.0").EnumerateObject());
        Assert.Empty(root.GetProperty("libraries").EnumerateObject());

        var dependencyGroups = root.GetProperty("projectFileDependencyGroups");
        Assert.Empty(
            GetOnlyFramework(dependencyGroups, "net10.0")
                .EnumerateArray());

        var project = root.GetProperty("project");
        var restore = project.GetProperty("restore");
        Assert.Equal(
            NormalizePath(ToFullPath(domainProject)),
            NormalizePath(restore.GetProperty("projectPath").GetString()));

        var restoreFramework = GetOnlyFramework(
            restore.GetProperty("frameworks"),
            "net10.0");
        Assert.Empty(
            restoreFramework.GetProperty("projectReferences")
                .EnumerateObject());

        var projectFramework = GetOnlyFramework(
            project.GetProperty("frameworks"),
            "net10.0");
        var frameworkReferences = projectFramework
            .GetProperty("frameworkReferences")
            .EnumerateObject()
            .Select(reference => reference.Name)
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(ExpectedFrameworkReferences, frameworkReferences);
    }

    [Fact]
    [Trait("Scenario", "TEST-0220")]
    public void TestEffectiveRestoreGraphContainsOnlyDomainAndTestInfrastructure()
    {
        const string domainProject =
            "src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj";
        const string testProject =
            "tests/dotnet/MeAndAI.Protocol.Domain.Tests/" +
            "MeAndAI.Protocol.Domain.Tests.csproj";
        var root = ReadJson(
            "tests/dotnet/MeAndAI.Protocol.Domain.Tests/obj/" +
            "project.assets.json");
        var project = root.GetProperty("project");
        var projectFramework = GetOnlyFramework(
            project.GetProperty("frameworks"),
            "net10.0");
        var dependencies = projectFramework
            .GetProperty("dependencies")
            .EnumerateObject()
            .OrderBy(dependency => dependency.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            [
                "Microsoft.NET.Test.Sdk",
                "xunit",
                "xunit.runner.visualstudio",
            ],
            dependencies.Select(dependency => dependency.Name));
        Assert.All(
            dependencies,
            dependency => Assert.Equal(
                "Package",
                dependency.Value.GetProperty("target").GetString()));

        var frameworkReferences = projectFramework
            .GetProperty("frameworkReferences")
            .EnumerateObject()
            .Select(reference => reference.Name)
            .Order(StringComparer.Ordinal)
            .ToArray();
        Assert.Equal(ExpectedFrameworkReferences, frameworkReferences);

        var restore = project.GetProperty("restore");
        Assert.Equal(
            NormalizePath(ToFullPath(testProject)),
            NormalizePath(restore.GetProperty("projectPath").GetString()));
        var restoreFramework = GetOnlyFramework(
            restore.GetProperty("frameworks"),
            "net10.0");
        var projectReferences = restoreFramework
            .GetProperty("projectReferences")
            .EnumerateObject()
            .Select(reference => NormalizePath(reference.Name))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            new[] { NormalizePath(ToFullPath(domainProject)) },
            projectReferences);
    }

    private static IReadOnlyList<string> ReadProjectReferences(string projectPath)
    {
        var fullPath = ToFullPath(projectPath);
        var projectDirectory = Path.GetDirectoryName(fullPath)
            ?? throw new InvalidOperationException("Project directory is missing.");
        var document = XDocument.Load(fullPath);

        return [.. document
            .Descendants("ProjectReference")
            .Select(element => (string?)element.Attribute("Include"))
            .Select(path => Path.GetFullPath(
                path ?? throw new InvalidDataException(
                    "ProjectReference has no Include attribute."),
                projectDirectory))
            .Select(path => NormalizePath(
                Path.GetRelativePath(RepositoryRoot, path)))
            .Order(StringComparer.Ordinal)];
    }

    private static IReadOnlyList<PackageReference> ReadPackageReferences(
        string projectPath)
    {
        var document = XDocument.Load(ToFullPath(projectPath));

        return [.. document
            .Descendants("PackageReference")
            .Select(element => new PackageReference(
                (string?)element.Attribute("Include")
                    ?? throw new InvalidDataException(
                        "PackageReference has no Include attribute."),
                ReadMetadata(element, "Version"),
                ReadMetadata(element, "VersionOverride")))
            .OrderBy(reference => reference.Name, StringComparer.Ordinal)];
    }

    private static JsonElement ReadJson(string repositoryRelativePath)
    {
        using var stream = File.OpenRead(ToFullPath(repositoryRelativePath));
        using var document = JsonDocument.Parse(stream);

        return document.RootElement.Clone();
    }

    private static JsonElement GetOnlyFramework(
        JsonElement frameworks,
        string expectedName)
    {
        var properties = frameworks.EnumerateObject().ToArray();
        var property = Assert.Single(properties);
        Assert.Equal(expectedName, property.Name);

        return property.Value;
    }

    private static string? ReadMetadata(XElement element, string name) =>
        (string?)element.Attribute(name) ?? (string?)element.Element(name);

    private static string FindRepositoryRoot()
    {
        var candidate = new DirectoryInfo(AppContext.BaseDirectory);

        while (candidate is not null)
        {
            if (File.Exists(Path.Combine(
                candidate.FullName,
                "MeAndAI.Protocol.slnx")))
            {
                return candidate.FullName;
            }

            candidate = candidate.Parent;
        }

        throw new DirectoryNotFoundException(
            "Could not locate the protocol solution from the test output directory.");
    }

    private static string ToFullPath(string repositoryRelativePath) =>
        Path.Combine(
            RepositoryRoot,
            repositoryRelativePath.Replace('/', Path.DirectorySeparatorChar));

    private static string NormalizePath(string? path) =>
        (path ?? throw new InvalidDataException("A project path is missing."))
        .Replace('\\', '/');

    private sealed record PackageReference(
        string Name,
        string? Version,
        string? VersionOverride);

    private sealed record LockDependency(string Name, string Type);
}
