namespace MeAndAI.Operations.Governance.Tests;

public sealed class HostedGovernanceEvidenceRouteTests
{
    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ProtocolWorkflowExecutesBoundedGovernanceTestsOnBothHostedPlatforms()
    {
        var workflowPath = Path.Combine(
            AppContext.BaseDirectory,
            "protocol-tests.yml");
        var workflow = File.ReadAllText(workflowPath);

        const string expectedFilter =
            "--filter \"Scenario=TEST-0191|Scenario=TEST-0192|" +
            "Scenario=TEST-0193|Scenario=TEST-0194\"";
        const string obsoleteFilter =
            "--filter \"Scenario=TEST-0191|Scenario=TEST-0192|" +
            "Scenario=TEST-0193\"";

        Assert.Equal(2, CountOccurrences(workflow, expectedFilter));
        Assert.DoesNotContain(obsoleteFilter, workflow, StringComparison.Ordinal);
    }

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var offset = 0;

        while ((offset = source.IndexOf(value, offset, StringComparison.Ordinal)) >= 0)
        {
            count++;
            offset += value.Length;
        }

        return count;
    }
}
