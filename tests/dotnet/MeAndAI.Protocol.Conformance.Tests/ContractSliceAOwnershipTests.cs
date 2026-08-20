using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Xml.Linq;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceAOwnershipTests
{
    private const string DomainProject =
        "src/MeAndAI.Protocol.Domain/MeAndAI.Protocol.Domain.csproj";
    private const string AbstractionsProject =
        "src/MeAndAI.Protocol.Conformance.Abstractions/" +
        "MeAndAI.Protocol.Conformance.Abstractions.csproj";
    private const string ConformanceProject =
        "src/MeAndAI.Protocol.Conformance/MeAndAI.Protocol.Conformance.csproj";
    private const string PolicyProject =
        "src/MeAndAI.Protocol.Policy/MeAndAI.Protocol.Policy.csproj";
    private const string DomainTestsProject =
        "tests/dotnet/MeAndAI.Protocol.Domain.Tests/" +
        "MeAndAI.Protocol.Domain.Tests.csproj";
    private const string ConformanceTestsProject =
        "tests/dotnet/MeAndAI.Protocol.Conformance.Tests/" +
        "MeAndAI.Protocol.Conformance.Tests.csproj";
    private const string RunnerIncludeAssets =
        "runtime; build; native; contentfiles; analyzers; buildtransitive";

    private static readonly string RepositoryRoot = FindRepositoryRoot();

    private static readonly string[] PredecessorInventory =
    [
        "AcquisitionStatus",
        "ConformanceVerdict",
        "EnforcementDecision",
        "EnforcementPhase",
        "ExactSha256Digest",
        "ExecutionProfile",
        "ProtocolOperation",
        "RuleEvaluationStatus",
        "RuleId",
        "RuleRevision",
        "SnapshotKind",
        "SubjectRole",
        "SurfaceKind",
        "SurfaceSet",
    ];

    private static readonly string[] SliceInventory =
    [
        "AbsentAcquisitionResult",
        "AcquisitionBoundary",
        "AcquisitionFailure",
        "AcquisitionPage",
        "AcquisitionRequest",
        "AcquisitionResult",
        "AcquisitionTarget",
        "CanonicalEvidencePayload",
        "EvidenceBinding",
        "EvidenceConsistencyClass",
        "EvidenceContext",
        "EvidenceLocation",
        "EvidenceRedaction",
        "EvidenceRequirement",
        "EvidenceScope",
        "FailedAcquisitionResult",
        "ObservedAcquisitionResult",
        "ProviderEvidenceLocation",
        "ReleaseAssetEvidenceLocation",
        "RepositoryEvidenceLocation",
        "RequirementAcquisition",
        "RootEvidenceReference",
        "SnapshotEvidenceLocation",
    ];

    private static readonly ProjectExpectation[] ExpectedProjects =
    [
        new(DomainProject, [], []),
        new(AbstractionsProject, [DomainProject], []),
        new(
            ConformanceProject,
            [AbstractionsProject, DomainProject],
            []),
        new(
            PolicyProject,
            [AbstractionsProject, DomainProject],
            [new("Markdig")]),
        new(
            DomainTestsProject,
            [DomainProject],
            TestPackageReferences()),
        new(
            ConformanceTestsProject,
            [
                AbstractionsProject,
                ConformanceProject,
                DomainProject,
                PolicyProject,
            ],
            TestPackageReferences()),
    ];

    private static readonly LockExpectation[] ExpectedLocks =
    [
        new(LockPath(DomainProject), []),
        new(
            LockPath(AbstractionsProject),
            [ProjectLock("meandai.protocol.domain")]),
        new(
            LockPath(ConformanceProject),
            [
                ProjectLock("meandai.protocol.conformance.abstractions"),
                ProjectLock("meandai.protocol.domain"),
            ]),
        new(
            LockPath(PolicyProject),
            [
                DirectLock("Markdig", "1.3.2"),
                ProjectLock("meandai.protocol.conformance.abstractions"),
                ProjectLock("meandai.protocol.domain"),
            ]),
        new(
            LockPath(DomainTestsProject),
            TestLockDependencies(ProjectLock("meandai.protocol.domain"))),
        new(
            LockPath(ConformanceTestsProject),
            TestLockDependencies(
                new("Markdig", "CentralTransitive", "[1.3.2, )", "1.3.2"),
                ProjectLock("meandai.protocol.conformance"),
                ProjectLock("meandai.protocol.conformance.abstractions"),
                ProjectLock("meandai.protocol.domain"),
                ProjectLock("meandai.protocol.policy"))),
    ];

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void DomainExportsEqualTheOrdinalUnionOfPredecessorInventories()
    {
        var expected = PredecessorInventory
            .Concat(SliceInventory)
            .Select(name => $"MeAndAI.Protocol.Domain.{name}")
            .Order(StringComparer.Ordinal)
            .ToArray();
        var assembly = Assembly.Load(
            new AssemblyName("MeAndAI.Protocol.Domain"));

        ProtectedPolicySurfaceTests.AssertPredecessorInventory(assembly, expected);
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void SolutionAndProjectReferencesEqualTheContractSliceAGraph()
    {
        var solution = XDocument.Load(
            ToFullPath("MeAndAI.Protocol.slnx"));
        var projects = solution
            .Descendants("Project")
            .Select(element => NormalizePath(
                (string?)element.Attribute("Path")))
            .Order(StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            ExpectedProjects
                .Select(project => project.Path)
                .Order(StringComparer.Ordinal),
            projects);

        foreach (var project in ExpectedProjects)
        {
            Assert.Equal(
                project.ProjectReferences.Order(StringComparer.Ordinal),
                ReadProjectReferences(project.Path));
        }
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void PackageReferencesEqualTheContractSliceAGraph()
    {
        var centralPackages = XDocument.Load(
                ToFullPath("Directory.Packages.props"))
            .Descendants("PackageVersion")
            .Select(element => new CentralPackageExpectation(
                ReadRequiredAttribute(element, "Include"),
                ReadRequiredAttribute(element, "Version")))
            .OrderBy(package => package.Name, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(
            new[]
            {
                new CentralPackageExpectation("Markdig", "1.3.2"),
                new CentralPackageExpectation(
                    "Microsoft.NET.Test.Sdk",
                    "17.14.1"),
                new CentralPackageExpectation("xunit", "2.9.3"),
                new CentralPackageExpectation(
                    "xunit.runner.visualstudio",
                    "3.1.4"),
            },
            centralPackages);

        foreach (var project in ExpectedProjects)
        {
            Assert.Equal(
                project.PackageReferences
                    .OrderBy(reference => reference.Name, StringComparer.Ordinal),
                ReadPackageReferences(project.Path));
        }
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void LocksEqualTheContractSliceATotalGraph()
    {
        Assert.Equal(
            ExpectedProjects
                .Select(project => LockPath(project.Path))
                .Order(StringComparer.Ordinal),
            ExpectedLocks
                .Select(expectation => expectation.Path)
                .Order(StringComparer.Ordinal));

        foreach (var expectation in ExpectedLocks)
        {
            var root = ReadJson(expectation.Path);
            Assert.Equal(2, root.GetProperty("version").GetInt32());
            var framework = GetOnlyFramework(
                root.GetProperty("dependencies"),
                "net10.0");
            var actual = framework
                .EnumerateObject()
                .Select(dependency => new LockDependencyExpectation(
                    dependency.Name,
                    ReadRequiredString(dependency.Value, "type"),
                    ReadOptionalString(dependency.Value, "requested"),
                    ReadOptionalString(dependency.Value, "resolved")))
                .OrderBy(dependency => dependency.Name, StringComparer.Ordinal)
                .ToArray();

            Assert.Equal(
                expectation.Dependencies
                    .OrderBy(dependency => dependency.Name, StringComparer.Ordinal),
                actual);
        }
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void EffectiveRestoreGraphsEqualTheContractSliceATotalGraph()
    {
        foreach (var project in ExpectedProjects)
        {
            var lockExpectation = Assert.Single(
                ExpectedLocks,
                expectation => expectation.Path == LockPath(project.Path));
            var assetsPath = NormalizePath(Path.Combine(
                Path.GetDirectoryName(project.Path)
                    ?? throw new InvalidDataException(
                        $"Project '{project.Path}' has no directory."),
                "obj/project.assets.json"));
            var root = ReadJson(assetsPath);
            var target = GetOnlyFramework(
                root.GetProperty("targets"),
                "net10.0");
            var libraries = root.GetProperty("libraries");

            var expectedGraph = lockExpectation.Dependencies
                .Select(dependency => new AssetDependency(
                    dependency.Name.ToLowerInvariant(),
                    dependency.Type == "Project" ? "project" : "package"))
                .OrderBy(dependency => dependency.Name, StringComparer.Ordinal)
                .ToArray();
            var actualLibraries = libraries
                .EnumerateObject()
                .Select(library => new AssetDependency(
                    AssetName(library.Name).ToLowerInvariant(),
                    ReadRequiredString(library.Value, "type")))
                .OrderBy(dependency => dependency.Name, StringComparer.Ordinal)
                .ToArray();

            Assert.Equal(expectedGraph, actualLibraries);
            Assert.Equal(
                expectedGraph.Select(dependency => dependency.Name),
                target
                    .EnumerateObject()
                    .Select(library => AssetName(library.Name).ToLowerInvariant())
                    .Order(StringComparer.Ordinal));

            var projectNode = root.GetProperty("project");
            var projectFramework = GetOnlyFramework(
                projectNode.GetProperty("frameworks"),
                "net10.0");
            var directPackages = projectFramework.TryGetProperty(
                "dependencies",
                out var dependencies)
                ? dependencies
                    .EnumerateObject()
                    .OrderBy(
                        dependency => dependency.Name,
                        StringComparer.Ordinal)
                    .ToArray()
                : [];

            Assert.Equal(
                project.PackageReferences.Select(reference => reference.Name),
                directPackages.Select(dependency => dependency.Name));
            Assert.All(
                directPackages,
                dependency => Assert.Equal(
                    "Package",
                    ReadRequiredString(dependency.Value, "target")));
            Assert.Equal(
                ["Microsoft.NETCore.App"],
                projectFramework
                    .GetProperty("frameworkReferences")
                    .EnumerateObject()
                    .Select(reference => reference.Name)
                    .Order(StringComparer.Ordinal));

            var restore = projectNode.GetProperty("restore");
            Assert.Equal(
                NormalizePath(ToFullPath(project.Path)),
                NormalizePath(ReadRequiredString(restore, "projectPath")));
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
                project.ProjectReferences
                    .Select(ToFullPath)
                    .Select(NormalizePath)
                    .Order(StringComparer.Ordinal),
                projectReferences);
        }
    }

    [Fact]
    [Trait("ContractSlice", "A")]
    [Trait("Scenario", "TEST-0210")]
    public void FriendAssembliesEqualTheCurrentContractSliceAMatrix()
    {
        var expected = new[]
        {
            new FriendExpectation("MeAndAI.Protocol.Domain", []),
            new FriendExpectation(
                "MeAndAI.Protocol.Conformance.Abstractions",
                [
                    "MeAndAI.Protocol.Conformance",
                    "MeAndAI.Protocol.Conformance.Tests",
                    "MeAndAI.Protocol.Policy",
                ]),
            new FriendExpectation(
                "MeAndAI.Protocol.Conformance",
                ["MeAndAI.Protocol.Conformance.Tests"]),
            new FriendExpectation("MeAndAI.Protocol.Policy", []),
        };

        foreach (var expectation in expected)
        {
            var assembly = Assembly.Load(
                new AssemblyName(expectation.AssemblyName));
            var actual = assembly
                .GetCustomAttributes<InternalsVisibleToAttribute>()
                .Select(attribute => new AssemblyName(
                    attribute.AssemblyName).Name
                    ?? throw new InvalidDataException(
                        "InternalsVisibleTo has no simple assembly name."))
                .Order(StringComparer.Ordinal)
                .ToArray();

            Assert.Equal(
                expectation.Friends.Order(StringComparer.Ordinal),
                actual);
        }
    }

    private static PackageReferenceExpectation[] TestPackageReferences() =>
    [
        new("Microsoft.NET.Test.Sdk"),
        new("xunit"),
        new(
            "xunit.runner.visualstudio",
            PrivateAssets: "all",
            IncludeAssets: RunnerIncludeAssets),
    ];

    private static LockDependencyExpectation[] TestLockDependencies(
        params LockDependencyExpectation[] additional) =>
    [
        DirectLock("Microsoft.NET.Test.Sdk", "17.14.1"),
        DirectLock("xunit", "2.9.3"),
        DirectLock("xunit.runner.visualstudio", "3.1.4"),
        new("Microsoft.CodeCoverage", "Transitive", null, "17.14.1"),
        new("Microsoft.TestPlatform.ObjectModel", "Transitive", null, "17.14.1"),
        new("Microsoft.TestPlatform.TestHost", "Transitive", null, "17.14.1"),
        new("Newtonsoft.Json", "Transitive", null, "13.0.3"),
        new("xunit.abstractions", "Transitive", null, "2.0.3"),
        new("xunit.analyzers", "Transitive", null, "1.18.0"),
        new("xunit.assert", "Transitive", null, "2.9.3"),
        new("xunit.core", "Transitive", null, "2.9.3"),
        new("xunit.extensibility.core", "Transitive", null, "2.9.3"),
        new("xunit.extensibility.execution", "Transitive", null, "2.9.3"),
        .. additional,
    ];

    private static LockDependencyExpectation DirectLock(
        string name,
        string version) =>
        new(name, "Direct", $"[{version}, )", version);

    private static LockDependencyExpectation ProjectLock(string name) =>
        new(name, "Project", null, null);

    private static string LockPath(string projectPath) =>
        NormalizePath(Path.Combine(
            Path.GetDirectoryName(projectPath)
                ?? throw new InvalidDataException(
                    $"Project '{projectPath}' has no directory."),
            "packages.lock.json"));

    private static IReadOnlyList<string> ReadProjectReferences(
        string projectPath)
    {
        var fullPath = ToFullPath(projectPath);
        var projectDirectory = Path.GetDirectoryName(fullPath)
            ?? throw new InvalidOperationException("Project directory is missing.");
        var document = XDocument.Load(fullPath);

        return [.. document
            .Descendants("ProjectReference")
            .Select(element => ReadRequiredAttribute(element, "Include"))
            .Select(path => Path.GetFullPath(path, projectDirectory))
            .Select(path => NormalizePath(
                Path.GetRelativePath(RepositoryRoot, path)))
            .Order(StringComparer.Ordinal)];
    }

    private static IReadOnlyList<PackageReferenceExpectation>
        ReadPackageReferences(string projectPath)
    {
        var document = XDocument.Load(ToFullPath(projectPath));

        return [.. document
            .Descendants("PackageReference")
            .Select(element => new PackageReferenceExpectation(
                ReadRequiredAttribute(element, "Include"),
                ReadMetadata(element, "Version"),
                ReadMetadata(element, "VersionOverride"),
                ReadMetadata(element, "PrivateAssets"),
                ReadMetadata(element, "IncludeAssets")))
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

    private static string ReadRequiredAttribute(XElement element, string name) =>
        (string?)element.Attribute(name)
        ?? throw new InvalidDataException(
            $"Element '{element.Name}' has no '{name}' attribute.");

    private static string? ReadMetadata(XElement element, string name) =>
        (string?)element.Attribute(name) ?? (string?)element.Element(name);

    private static string ReadRequiredString(JsonElement element, string name) =>
        element.GetProperty(name).GetString()
        ?? throw new InvalidDataException($"Property '{name}' is not a string.");

    private static string? ReadOptionalString(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) ? value.GetString() : null;

    private static string AssetName(string libraryIdentity)
    {
        var separator = libraryIdentity.LastIndexOf('/');
        if (separator <= 0)
        {
            throw new InvalidDataException(
                $"Asset identity '{libraryIdentity}' has no version separator.");
        }

        return libraryIdentity[..separator];
    }

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
        (path ?? throw new InvalidDataException("A path is missing."))
        .Replace('\\', '/');

    private sealed record ProjectExpectation(
        string Path,
        IReadOnlyList<string> ProjectReferences,
        IReadOnlyList<PackageReferenceExpectation> PackageReferences);

    private sealed record PackageReferenceExpectation(
        string Name,
        string? Version = null,
        string? VersionOverride = null,
        string? PrivateAssets = null,
        string? IncludeAssets = null);

    private sealed record CentralPackageExpectation(string Name, string Version);

    private sealed record LockExpectation(
        string Path,
        IReadOnlyList<LockDependencyExpectation> Dependencies);

    private sealed record LockDependencyExpectation(
        string Name,
        string Type,
        string? Requested,
        string? Resolved);

    private sealed record AssetDependency(string Name, string Type);

    private sealed record FriendExpectation(
        string AssemblyName,
        IReadOnlyList<string> Friends);
}
