using System.Reflection;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class PackagedGovernancePolicySourceTests
{
    private const string MetadataKey =
        "MeAndAI.Governance.PolicySourceCommit";

    private const string SourceCommit =
        "0123456789abcdef0123456789abcdef01234567";

    private const string ResolutionFailure =
        "The governance assembly does not contain one exact packaged policy source commit.";

    [Fact]
    public void OneExactMetadataValueResolvesToTheTypedCommit()
    {
        var result = PackagedGovernancePolicySource.Resolve(
            [
                new AssemblyMetadataAttribute("Unrelated", "value"),
                new AssemblyMetadataAttribute(MetadataKey, SourceCommit),
            ]);

        Assert.Equal(SourceCommit, result.Value);
    }

    [Fact]
    public void MissingMalformedOrDuplicateBindingFailsDeterministically()
    {
        var invalidCases = new AssemblyMetadataAttribute[][]
        {
            [],
            [new AssemblyMetadataAttribute(MetadataKey, string.Empty)],
            [new AssemblyMetadataAttribute(MetadataKey, $" {SourceCommit}")],
            [new AssemblyMetadataAttribute(MetadataKey, SourceCommit.ToUpperInvariant())],
            [new AssemblyMetadataAttribute(MetadataKey.ToUpperInvariant(), SourceCommit)],
            [
                new AssemblyMetadataAttribute(MetadataKey, SourceCommit),
                new AssemblyMetadataAttribute(MetadataKey, SourceCommit),
            ],
        };

        foreach (var metadata in invalidCases)
        {
            var exception = Assert.Throws<InvalidOperationException>(() =>
                PackagedGovernancePolicySource.Resolve(metadata));

            Assert.Equal(ResolutionFailure, exception.Message);
            Assert.DoesNotContain(SourceCommit, exception.Message, StringComparison.OrdinalIgnoreCase);
        }
    }

    [Fact]
    public async Task UnboundDevelopmentAssemblyFailsWithoutAffectingDescriptor()
    {
        var exception = Assert.Throws<InvalidOperationException>(
            PackagedGovernancePolicySource.Resolve);
        Assert.Equal(ResolutionFailure, exception.Message);

        using var output = new StringWriter();
        using var error = new StringWriter();
        var exitCode = await GovernanceCli.RunAsync(
            ["--describe-contract"],
            output,
            error);

        Assert.Equal(0, exitCode);
        Assert.NotEqual(string.Empty, output.ToString());
        Assert.Equal(string.Empty, error.ToString());
    }
}
