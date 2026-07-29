using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Xml.Linq;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Packaging;

namespace MeAndAI.Operations.Packaging.Tests;

public sealed class PortablePackagingTests
{
    private const string SourceCommit =
        "0123456789abcdef0123456789abcdef01234567";

    private const string GovernancePolicyBindingProperty =
        "MeAndAIGovernancePolicySourceCommit";

    private const string GovernancePolicyMetadataKey =
        "MeAndAI.Governance.PolicySourceCommit";

    private const string CompatibleRuntimeInventory =
        "Microsoft.NETCore.App 10.0.9 [runtime-root]";

    private static readonly string RepositoryRoot = FindRepositoryRoot();

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void DeclarativeInventoryOwnsExactIndependentMappings()
    {
        var inventory = ReadRepositoryInventory();

        Assert.Equal(1, inventory.Schema);
        Assert.Equal("meandai.operations.packages", inventory.Kind);
        Assert.Equal(
            ["adoption", "consumer-update", "governance"],
            inventory.Packages.Select(package => package.Application));
        Assert.Equal(
            [
                "src/MeAndAI.Operations.Adoption/MeAndAI.Operations.Adoption.csproj",
                "src/MeAndAI.Operations.ConsumerUpdate/MeAndAI.Operations.ConsumerUpdate.csproj",
                "src/MeAndAI.Operations.Governance/MeAndAI.Operations.Governance.csproj",
            ],
            inventory.Packages.Select(package => package.ProjectPath));
        Assert.Equal(
            [
                "maai-adoption.zip",
                "maai-consumer-update.zip",
                "maai-governance.zip",
            ],
            inventory.Packages.Select(package => package.AssetName));
        Assert.Equal(
            [
                "MeAndAI.Operations.Adoption.dll",
                "MeAndAI.Operations.ConsumerUpdate.dll",
                "MeAndAI.Operations.Governance.dll",
            ],
            inventory.Packages.Select(package => package.EntryAssembly));
    }

    [Theory]
    [Trait("Scenario", "TEST-0193")]
    [InlineData("duplicate-application")]
    [InlineData("missing-project-path")]
    [InlineData("unknown-property")]
    public void InventoryAmbiguityOrInferenceFailsClosed(string mutation)
    {
        var sourcePath = Path.Combine(
            RepositoryRoot,
            "packaging",
            "operations-packages.json");
        var inventory = JsonNode.Parse(File.ReadAllText(sourcePath, Encoding.UTF8))
            ?? throw new InvalidDataException("Package inventory JSON is empty.");
        var packages = inventory["packages"]?.AsArray()
            ?? throw new InvalidDataException("Package inventory entries are absent.");
        var first = packages[0]?.AsObject()
            ?? throw new InvalidDataException("First package inventory entry is absent.");
        var second = packages[1]?.AsObject()
            ?? throw new InvalidDataException("Second package inventory entry is absent.");

        switch (mutation)
        {
            case "duplicate-application":
                second["application"] = (string?)first["application"];
                break;
            case "missing-project-path":
                Assert.True(first.Remove("projectPath"));
                break;
            case "unknown-property":
                first["repositoryPath"] = first["projectPath"]?.DeepClone();
                break;
            default:
                throw new InvalidOperationException("Unknown inventory mutation.");
        }

        var temporaryPath = Path.Combine(
            Path.GetTempPath(),
            $"meandai-package-inventory-{Guid.NewGuid():N}.json");
        try
        {
            File.WriteAllText(
                temporaryPath,
                inventory.ToJsonString() + "\n",
                new UTF8Encoding(false));
            Assert.Throws<InvalidDataException>(() =>
                OperationsPackageInventory.Read(temporaryPath));
        }
        finally
        {
            File.Delete(temporaryPath);
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void PackageSetIsDeterministicAndManifestBound()
    {
        using var fixture = PortablePackageFixture.Create();
        var firstOutput = fixture.CreateOutputDirectory("first");
        var secondOutput = fixture.CreateOutputDirectory("second");

        var first = PortablePackageBuilder.Build(
            fixture.CreateBuildRequest(firstOutput));
        var second = PortablePackageBuilder.Build(
            fixture.CreateBuildRequest(secondOutput));

        Assert.Equal(1, first.ManifestSchema);
        Assert.Equal("meandai.operations.release", first.Kind);
        Assert.Equal(SourceCommit, first.SourceCommit);
        Assert.Equal(3, first.Assets.Count);
        Assert.Equal(
            File.ReadAllBytes(Path.Combine(
                firstOutput,
                PortableReleaseContract.ManifestFileName)),
            File.ReadAllBytes(Path.Combine(
                secondOutput,
                PortableReleaseContract.ManifestFileName)));

        foreach (var package in fixture.Inventory.Packages)
        {
            Assert.Equal(
                File.ReadAllBytes(Path.Combine(firstOutput, package.AssetName)),
                File.ReadAllBytes(Path.Combine(secondOutput, package.AssetName)));
        }

        var verified = PortablePackageVerifier.Verify(
            fixture.CreateVerificationRequest(firstOutput));

        Assert.Equal(
            ["adoption", "consumer-update", "governance"],
            verified.Assets.Select(asset => asset.Application));
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void AssetDigestDriftFailsClosed()
    {
        using var fixture = PortablePackageFixture.Create();
        var output = fixture.CreateOutputDirectory("digest-drift");
        PortablePackageBuilder.Build(fixture.CreateBuildRequest(output));
        var assetPath = Path.Combine(
            output,
            fixture.Inventory.Packages[0].AssetName);

        using (var stream = File.Open(assetPath, FileMode.Append, FileAccess.Write))
        {
            stream.WriteByte(0x7f);
        }

        Assert.Throws<InvalidDataException>(() =>
            PortablePackageVerifier.Verify(
                fixture.CreateVerificationRequest(output)));
    }

    [Theory]
    [Trait("Scenario", "TEST-0193")]
    [InlineData("")]
    [InlineData("Microsoft.NETCore.App 9.0.17 [runtime-root]")]
    [InlineData("Microsoft.NETCore.App 10.0.0-preview.7 [runtime-root]")]
    [InlineData("Microsoft.AspNetCore.App 10.0.9 [runtime-root]")]
    public void MissingOrIncompatibleRuntimeFailsClosed(string runtimeInventory)
    {
        using var fixture = PortablePackageFixture.Create();
        var output = fixture.CreateOutputDirectory("runtime");
        PortablePackageBuilder.Build(fixture.CreateBuildRequest(output));

        Assert.Throws<InvalidDataException>(() =>
            PortablePackageVerifier.Verify(
                fixture.CreateVerificationRequest(output, runtimeInventory)));
    }

    [Theory]
    [Trait("Scenario", "TEST-0193")]
    [InlineData("\"manifestSchema\": 1", "\"manifestSchema\": 2")]
    [InlineData(
        "0123456789abcdef0123456789abcdef01234567",
        "0123456789ABCDEF0123456789ABCDEF01234567")]
    [InlineData("maai-governance.zip", "maai-governance-win-x64.zip")]
    [InlineData("\"minimum\": 1", "\"minimum\": 2")]
    public void ManifestIdentityOrSchemaTamperingFailsClosed(
        string original,
        string replacement)
    {
        using var fixture = PortablePackageFixture.Create();
        var output = fixture.CreateOutputDirectory("manifest-tamper");
        PortablePackageBuilder.Build(fixture.CreateBuildRequest(output));
        var manifestPath = Path.Combine(
            output,
            PortableReleaseContract.ManifestFileName);
        var manifestText = File.ReadAllText(manifestPath, Encoding.UTF8);
        Assert.Contains(original, manifestText, StringComparison.Ordinal);
        File.WriteAllText(
            manifestPath,
            manifestText.Replace(original, replacement, StringComparison.Ordinal),
            new UTF8Encoding(false));

        Assert.Throws<InvalidDataException>(() =>
            PortablePackageVerifier.Verify(
                fixture.CreateVerificationRequest(output)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void UnsafeArchiveEntryFailsAfterValidDigestBinding()
    {
        using var fixture = PortablePackageFixture.Create();
        var output = fixture.CreateOutputDirectory("unsafe-archive");
        PortablePackageBuilder.Build(fixture.CreateBuildRequest(output));
        var package = fixture.Inventory.Packages[0];
        var assetPath = Path.Combine(output, package.AssetName);

        using (var archive = ZipFile.Open(assetPath, ZipArchiveMode.Update))
        {
            var entry = archive.CreateEntry("../escape.dll");
            using var writer = new StreamWriter(
                entry.Open(),
                new UTF8Encoding(false),
                leaveOpen: false);
            writer.Write("escape");
        }

        RebindManifestAsset(output, package.AssetName);

        Assert.Throws<InvalidDataException>(() =>
            PortablePackageVerifier.Verify(
                fixture.CreateVerificationRequest(output)));
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void PlatformAppHostOrRidPayloadIsRejectedBeforePackaging()
    {
        using var fixture = PortablePackageFixture.Create();
        var package = fixture.Inventory.Packages[0];
        var publishDirectory = fixture.PublishDirectories[package.Application];
        File.WriteAllText(
            Path.Combine(
                publishDirectory,
                Path.ChangeExtension(package.EntryAssembly, ".exe")),
            "apphost",
            new UTF8Encoding(false));
        Directory.CreateDirectory(Path.Combine(publishDirectory, "runtimes", "win-x64"));
        File.WriteAllText(
            Path.Combine(publishDirectory, "runtimes", "win-x64", "native.dll"),
            "native",
            new UTF8Encoding(false));

        Assert.Throws<InvalidDataException>(() =>
            PortablePackageBuilder.Build(
                fixture.CreateBuildRequest(
                    fixture.CreateOutputDirectory("platform-payload"))));
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void EntryProjectsArePortableFrameworkDependentApplications()
    {
        var inventory = ReadRepositoryInventory();
        var sharedProperties = XDocument.Load(Path.Combine(
            RepositoryRoot,
            "Directory.Build.props"));
        Assert.Equal("net10.0", ReadProperty(sharedProperties, "TargetFramework"));
        Assert.Equal("false", ReadProperty(sharedProperties, "UseAppHost"));

        foreach (var package in inventory.Packages)
        {
            var projectPath = Path.Combine(
                RepositoryRoot,
                package.ProjectPath.Replace('/', Path.DirectorySeparatorChar));
            var project = XDocument.Load(projectPath);
            Assert.Equal("Exe", ReadProperty(project, "OutputType"));
            Assert.Equal("false", ReadProperty(project, "SelfContained"));
            Assert.Equal("LatestPatch", ReadProperty(project, "RollForward"));
            Assert.Null(ReadProperty(project, "RuntimeIdentifier"));
            Assert.Null(ReadProperty(project, "RuntimeIdentifiers"));
            Assert.Null(ReadProperty(project, "PublishAot"));
            Assert.Null(ReadProperty(project, "PublishReadyToRun"));
            Assert.Null(ReadProperty(project, "PublishSingleFile"));
            Assert.Empty(project.Descendants("PackageReference"));
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void GovernancePublishAloneReceivesTheValidatedPolicySourceCommit()
    {
        var inventory = ReadRepositoryInventory();
        var argumentSets = inventory.Packages
            .Select(package => new
            {
                Package = package,
                Arguments = PackagingCli.CreatePublishArguments(
                    package,
                    package.ProjectPath,
                    $"publish/{package.Application}",
                    SourceCommit),
            })
            .ToArray();

        Assert.Equal(inventory.Packages.Count, argumentSets.Length);
        Assert.Equal(
            argumentSets.Length,
            argumentSets.Select(item => item.Arguments).Distinct().Count());
        foreach (var item in argumentSets)
        {
            var bindings = item.Arguments
                .Where(argument => argument.StartsWith(
                    $"-p:{GovernancePolicyBindingProperty}=",
                    StringComparison.Ordinal))
                .ToArray();

            if (string.Equals(
                    item.Package.Application,
                    OperationalApplicationId.Governance.Value,
                    StringComparison.Ordinal))
            {
                Assert.Equal(
                    [$"-p:{GovernancePolicyBindingProperty}={SourceCommit}"],
                    bindings);
            }
            else
            {
                Assert.Empty(bindings);
                Assert.DoesNotContain(SourceCommit, item.Arguments);
            }
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0193")]
    public void OnlyGovernanceProjectOwnsTheConditionalBindingMetadata()
    {
        var sourceRoot = Path.Combine(RepositoryRoot, "src");
        var owners = Directory
            .EnumerateFiles(
                sourceRoot,
                "*.csproj",
                SearchOption.AllDirectories)
            .Select(path => new
            {
                Path = path,
                Project = XDocument.Load(path),
            })
            .SelectMany(item => item.Project
                .Descendants("AssemblyMetadata")
                .Where(element => string.Equals(
                    (string?)element.Attribute("Include"),
                    GovernancePolicyMetadataKey,
                    StringComparison.Ordinal))
                .Select(element => new
                {
                    item.Path,
                    Metadata = element,
                }))
            .ToArray();
        var owner = Assert.Single(owners);

        Assert.Equal(
            Path.Combine(
                sourceRoot,
                "MeAndAI.Operations.Governance",
                "MeAndAI.Operations.Governance.csproj"),
            owner.Path);
        Assert.Equal(
            $"$({GovernancePolicyBindingProperty})",
            (string?)owner.Metadata.Attribute("Value"));
        Assert.Equal(
            $"'$({GovernancePolicyBindingProperty})' != ''",
            (string?)owner.Metadata.Parent?.Attribute("Condition"));
        Assert.Null(owner.Metadata.Attribute("Condition"));
    }

    private static OperationsPackageInventory ReadRepositoryInventory() =>
        OperationsPackageInventory.Read(Path.Combine(
            RepositoryRoot,
            "packaging",
            "operations-packages.json"));

    private static void RebindManifestAsset(
        string outputDirectory,
        string assetName)
    {
        var manifestPath = Path.Combine(
            outputDirectory,
            PortableReleaseContract.ManifestFileName);
        var manifest = JsonNode.Parse(File.ReadAllText(manifestPath, Encoding.UTF8))
            ?? throw new InvalidDataException("Manifest JSON is empty.");
        var assets = manifest["assets"]?.AsArray()
            ?? throw new InvalidDataException("Manifest assets are absent.");
        var asset = assets
            .Select(node => node?.AsObject())
            .Single(node => string.Equals(
                (string?)node?["assetName"],
                assetName,
                StringComparison.Ordinal));
        var assetPath = Path.Combine(outputDirectory, assetName);
        var bytes = File.ReadAllBytes(assetPath);
        asset!["length"] = bytes.LongLength;
        asset["sha256"] = Convert.ToHexString(SHA256.HashData(bytes))
            .ToLowerInvariant();
        File.WriteAllText(
            manifestPath,
            manifest.ToJsonString(new JsonSerializerOptions { WriteIndented = true }) + "\n",
            new UTF8Encoding(false));
    }

    private static string? ReadProperty(XDocument project, string name) =>
        project.Descendants(name).Select(element => element.Value).SingleOrDefault();

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

    private sealed class PortablePackageFixture : IDisposable
    {
        private readonly string _root;

        private PortablePackageFixture(
            string root,
            OperationsPackageInventory inventory,
            Dictionary<string, string> publishDirectories)
        {
            _root = root;
            Inventory = inventory;
            PublishDirectories = publishDirectories;
        }

        public OperationsPackageInventory Inventory { get; }

        public Dictionary<string, string> PublishDirectories { get; }

        public static PortablePackageFixture Create()
        {
            var root = Path.Combine(
                Path.GetTempPath(),
                $"meandai-packaging-tests-{Guid.NewGuid():N}");
            Directory.CreateDirectory(root);
            var inventory = ReadRepositoryInventory();
            var publishDirectories = new Dictionary<string, string>(
                StringComparer.Ordinal);

            foreach (var package in inventory.Packages)
            {
                var directory = Path.Combine(root, "publish", package.Application);
                Directory.CreateDirectory(directory);
                publishDirectories.Add(package.Application, directory);
                File.WriteAllText(
                    Path.Combine(directory, package.EntryAssembly),
                    package.Application,
                    new UTF8Encoding(false));
                var assemblyName = Path.GetFileNameWithoutExtension(
                    package.EntryAssembly);
                File.WriteAllText(
                    Path.Combine(directory, $"{assemblyName}.deps.json"),
                    "{}\n",
                    new UTF8Encoding(false));
                File.WriteAllText(
                    Path.Combine(directory, $"{assemblyName}.runtimeconfig.json"),
                    """
                    {
                      "runtimeOptions": {
                        "tfm": "net10.0",
                        "rollForward": "LatestPatch",
                        "framework": {
                          "name": "Microsoft.NETCore.App",
                          "version": "10.0.0"
                        }
                      }
                    }
                    """ + "\n",
                    new UTF8Encoding(false));
            }

            return new PortablePackageFixture(root, inventory, publishDirectories);
        }

        public string CreateOutputDirectory(string name)
        {
            var directory = Path.Combine(_root, "output", name);
            Directory.CreateDirectory(directory);
            return directory;
        }

        public PortablePackageBuildRequest CreateBuildRequest(string outputDirectory) =>
            new(
                SourceCommit,
                Inventory,
                PublishDirectories,
                outputDirectory);

        public PortablePackageVerificationRequest CreateVerificationRequest(
            string outputDirectory,
            string runtimeInventory = CompatibleRuntimeInventory) =>
            new(
                Inventory,
                Path.Combine(
                    outputDirectory,
                    PortableReleaseContract.ManifestFileName),
                outputDirectory,
                runtimeInventory);

        public void Dispose()
        {
            if (Directory.Exists(_root))
            {
                Directory.Delete(_root, recursive: true);
            }
        }
    }
}
