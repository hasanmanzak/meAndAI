using System.Text.Json;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceCliTests
{
    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public async Task CandidateRepositoryProducesDeterministicShadowReport()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: true);

        var first = await InvokeAsync(fixture.Root);
        var second = await InvokeAsync(fixture.Root);

        Assert.Equal(0, first.ExitCode);
        Assert.Equal(string.Empty, first.StandardError);
        Assert.Equal(first.StandardOutput, second.StandardOutput);

        using var report = JsonDocument.Parse(first.StandardOutput);
        var root = report.RootElement;
        Assert.Equal("protocol-authority", root.GetProperty("profile").GetString());
        Assert.Equal(
            "candidate",
            root.GetProperty("snapshot").GetProperty("mode").GetString());
        Assert.Equal("conforming", root.GetProperty("verdict").GetString());
        Assert.Equal("bounded-catalog", root.GetProperty("coverage").GetString());
        Assert.Equal(
            [
                "protocol.decision-record.required-structure.v1",
                "protocol.feature-record.required-pair.v1",
            ],
            root.GetProperty("policy")
                .GetProperty("evaluatedRuleIds")
                .EnumerateArray()
                .Select(rule => rule.GetString()));
        Assert.Equal("csharp-shadow", root.GetProperty("engineState").GetString());
        Assert.Equal(
            "powershell-authority",
            root.GetProperty("authorityState").GetString());
        Assert.Equal(64, root.GetProperty("reportDigest").GetString()!.Length);
        Assert.DoesNotContain(
            fixture.Root,
            first.StandardOutput,
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public async Task MissingFeatureRecordRoleReturnsNonconformingExit()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: false);

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(1, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        Assert.Equal(
            "nonconforming",
            report.RootElement.GetProperty("verdict").GetString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public async Task RequiredFileNameUsesOrdinalCaseOnEveryPlatform()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: false,
            includeTests: true);
        fixture.AddFeatureFile("FEAT-0001-example", "readme.md");

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(1, result.ExitCode);
        using var report = JsonDocument.Parse(result.StandardOutput);
        var finding = Assert.Single(
            report.RootElement.GetProperty("findings").EnumerateArray());
        Assert.Equal(
            "repository-file",
            Assert.Single(
                finding
                    .GetProperty("unsatisfiedRequirements")
                    .EnumerateArray())
                .GetProperty("kind")
                .GetString());
        Assert.Equal(
            "README.md",
            Assert.Single(
                finding
                    .GetProperty("unsatisfiedRequirements")
                    .EnumerateArray())
                .GetProperty("name")
                .GetString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public async Task ValidDecisionRecordIsIncludedInTheBoundedCatalog()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: true);
        fixture.AddDecision(
            "DEC-0001-example.md",
            """
            # DEC-0001 - Example
            - Classification: Decision
            - Status: Accepted
            ## Context
            ## Decision
            ## Consequences
            """);

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(0, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        Assert.Equal(
            "conforming",
            report.RootElement.GetProperty("verdict").GetString());
        Assert.Equal(
            2,
            report.RootElement
                .GetProperty("counts")
                .GetProperty("evaluatedRules")
                .GetInt32());
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public async Task InvalidDecisionRecordReturnsTypedNonconformingFinding()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: true);
        fixture.AddDecision(
            "DEC-0001-example.md",
            """
            # DEC-0001 - Example
            - Classification: Decision
            - Status:
            ## Context
            ## Decision
            ## Consequences
            """);

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(1, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        var finding = Assert.Single(
            report.RootElement.GetProperty("findings").EnumerateArray());
        Assert.Equal(
            "protocol.decision-record.required-structure.v1",
            finding.GetProperty("ruleId").GetString());
        Assert.Equal(
            "governance.decision.record-structure-incomplete",
            finding.GetProperty("code").GetString());
        var requirement = Assert.Single(
            finding
                .GetProperty("unsatisfiedRequirements")
                .EnumerateArray());
        Assert.Equal(
            "metadata-field",
            requirement.GetProperty("kind").GetString());
        Assert.Equal("Status", requirement.GetProperty("name").GetString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public async Task UnrelatedInvalidUtf8MarkdownDoesNotAffectTheBoundedCatalog()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: true);
        fixture.AddDecisionBytes("README.md", [0xff]);

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(0, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var report = JsonDocument.Parse(result.StandardOutput);
        Assert.Equal(
            "conforming",
            report.RootElement.GetProperty("verdict").GetString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0005")]
    public async Task InvalidUtf8NumberedDecisionIsAnOperationalFailure()
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        fixture.AddFeature(
            "FEAT-0001-example",
            includeReadme: true,
            includeTests: true);
        fixture.AddDecisionBytes("DEC-0001-invalid.md", [0xff]);

        var result = await InvokeAsync(fixture.Root);

        Assert.Equal(70, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Repository snapshot capture failed.\n",
            NormalizeNewline(result.StandardError));
    }

    [Theory]
    [InlineData("root")]
    [InlineData("feature-directory")]
    [InlineData("required-file")]
    [InlineData("dangling-required-file")]
    [InlineData("dangling-docs")]
    [InlineData("dangling-features")]
    [InlineData("file-link-docs")]
    [InlineData("file-link-features")]
    [InlineData("decision-file")]
    [InlineData("dangling-decision-file")]
    public async Task RepositoryLinksFailWithoutGovernanceVerdict(string linkKind)
    {
        using var fixture = GovernanceRepositoryFixture.Create();
        var repository = linkKind switch
        {
            "root" => fixture.CreateRootLink(),
            "feature-directory" =>
                fixture.CreateFeatureDirectoryLink("FEAT-0001-linked"),
            "required-file" =>
                fixture.CreateRequiredFileLink(dangling: false),
            "dangling-required-file" =>
                fixture.CreateRequiredFileLink(dangling: true),
            "dangling-docs" =>
                fixture.CreateIntermediateLink("docs", dangling: true),
            "dangling-features" =>
                fixture.CreateIntermediateLink("features", dangling: true),
            "file-link-docs" =>
                fixture.CreateIntermediateLink("docs", dangling: false),
            "file-link-features" =>
                fixture.CreateIntermediateLink("features", dangling: false),
            "decision-file" =>
                fixture.CreateDecisionFileLink(dangling: false),
            "dangling-decision-file" =>
                fixture.CreateDecisionFileLink(dangling: true),
            _ => throw new InvalidOperationException("Unknown link fixture."),
        };

        var result = await InvokeAsync(repository);

        Assert.Equal(70, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Repository snapshot capture failed.\n",
            NormalizeNewline(result.StandardError));
    }

    [Fact]
    public async Task FoundationContractDescriptionRemainsAvailable()
    {
        var result = await InvokeArgumentsAsync(["--describe-contract"]);

        Assert.Equal(0, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardError);
        using var descriptor = JsonDocument.Parse(result.StandardOutput);
        Assert.Equal(
            "governance",
            descriptor.RootElement.GetProperty("application").GetString());
    }

    [Fact]
    public async Task UnknownProfileIsRejectedBeforeRepositoryAccess()
    {
        var result = await InvokeAsync(
            "does-not-need-to-exist",
            profile: "automatic");

        Assert.Equal(64, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Unknown governance profile.\n",
            NormalizeNewline(result.StandardError));
    }

    [Fact]
    public async Task MissingRepositoryIsAnOperationalFailure()
    {
        var missingPath = Path.Combine(
            Path.GetTempPath(),
            $"meandai-governance-missing-{Guid.NewGuid():N}");

        var result = await InvokeAsync(missingPath);

        Assert.Equal(70, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Repository snapshot capture failed.\n",
            NormalizeNewline(result.StandardError));
    }

    [Fact]
    public async Task PreCanceledRunReturnsCanceledExit()
    {
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();

        var result = await InvokeAsync(
            ".",
            cancellationToken: cancellation.Token);

        Assert.Equal(130, result.ExitCode);
        Assert.Equal(string.Empty, result.StandardOutput);
        Assert.Equal(
            "Governance validation canceled.\n",
            NormalizeNewline(result.StandardError));
    }

    private static async Task<CliResult> InvokeAsync(
        string repository,
        string profile = "protocol-authority",
        CancellationToken cancellationToken = default)
    {
        return await InvokeArgumentsAsync(
            [
                "validate",
                "--repository",
                repository,
                "--profile",
                profile,
            ],
            cancellationToken);
    }

    private static async Task<CliResult> InvokeArgumentsAsync(
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken = default)
    {
        using var output = new StringWriter();
        using var error = new StringWriter();
        var exitCode = await GovernanceCli.RunAsync(
            arguments,
            output,
            error,
            cancellationToken);

        return new CliResult(exitCode, output.ToString(), error.ToString());
    }

    private static string NormalizeNewline(string value) =>
        value.Replace("\r\n", "\n", StringComparison.Ordinal);

    private sealed record CliResult(
        int ExitCode,
        string StandardOutput,
        string StandardError);

    private sealed class GovernanceRepositoryFixture : IDisposable
    {
        private readonly string container;

        private GovernanceRepositoryFixture(string container, string root)
        {
            this.container = container;
            Root = root;
            Directory.CreateDirectory(Path.Combine(root, "docs", "features"));
            Directory.CreateDirectory(Path.Combine(root, "docs", "decisions"));
        }

        public string Root { get; }

        public static GovernanceRepositoryFixture Create()
        {
            var container = Path.Combine(
                Path.GetTempPath(),
                $"meandai-governance-tests-{Guid.NewGuid():N}");
            return new GovernanceRepositoryFixture(
                container,
                Path.Combine(container, "repository"));
        }

        public void AddFeature(
            string directoryName,
            bool includeReadme,
            bool includeTests)
        {
            var directory = Path.Combine(Root, "docs", "features", directoryName);
            Directory.CreateDirectory(directory);
            if (includeReadme)
            {
                File.WriteAllText(Path.Combine(directory, "README.md"), "# Feature\n");
            }

            if (includeTests)
            {
                File.WriteAllText(
                    Path.Combine(directory, "test-cases.md"),
                    "# Tests\n");
            }
        }

        public void AddFeatureFile(string directoryName, string fileName)
        {
            var directory = Path.Combine(
                Root,
                "docs",
                "features",
                directoryName);
            Directory.CreateDirectory(directory);
            File.WriteAllText(Path.Combine(directory, fileName), "fixture\n");
        }

        public void AddDecision(string fileName, string content)
        {
            File.WriteAllText(
                Path.Combine(Root, "docs", "decisions", fileName),
                content);
        }

        public void AddDecisionBytes(string fileName, byte[] content)
        {
            File.WriteAllBytes(
                Path.Combine(Root, "docs", "decisions", fileName),
                content);
        }

        public string CreateRootLink()
        {
            var link = Path.Combine(container, "repository-link");
            Directory.CreateSymbolicLink(link, Root);
            return link;
        }

        public string CreateFeatureDirectoryLink(string directoryName)
        {
            var target = Path.Combine(container, "linked-feature-target");
            Directory.CreateDirectory(target);
            var link = Path.Combine(
                Root,
                "docs",
                "features",
                directoryName);
            Directory.CreateSymbolicLink(link, target);
            return Root;
        }

        public string CreateRequiredFileLink(bool dangling)
        {
            const string directoryName = "FEAT-0001-linked-file";
            AddFeature(
                directoryName,
                includeReadme: false,
                includeTests: true);
            var target = Path.Combine(container, "linked-readme-target.md");
            if (!dangling)
            {
                File.WriteAllText(target, "# Linked target\n");
            }

            var link = Path.Combine(
                Root,
                "docs",
                "features",
                directoryName,
                "README.md");
            File.CreateSymbolicLink(link, target);
            return Root;
        }

        public string CreateIntermediateLink(string name, bool dangling)
        {
            var link = string.Equals(name, "docs", StringComparison.Ordinal)
                ? Path.Combine(Root, "docs")
                : Path.Combine(Root, "docs", "features");
            Directory.Delete(link, recursive: true);
            var target = Path.Combine(container, $"{name}-link-target");
            if (!dangling)
            {
                File.WriteAllText(target, "not a directory\n");
            }

            File.CreateSymbolicLink(link, target);
            return Root;
        }

        public string CreateDecisionFileLink(bool dangling)
        {
            var target = Path.Combine(container, "linked-decision-target.md");
            if (!dangling)
            {
                File.WriteAllText(target, "# DEC-0001 - Linked target\n");
            }

            var link = Path.Combine(
                Root,
                "docs",
                "decisions",
                "DEC-0001-linked.md");
            File.CreateSymbolicLink(link, target);
            return Root;
        }

        public void Dispose()
        {
            if (Directory.Exists(container))
            {
                Directory.Delete(container, recursive: true);
            }
        }
    }
}
