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
        var scenarioFilters = File.ReadLines(workflowPath)
            .Where(line => line.Contains(
                "--filter \"Scenario=",
                StringComparison.Ordinal))
            .ToArray();

        Assert.Equal(2, scenarioFilters.Length);
        Assert.All(
            scenarioFilters,
            filter => Assert.Contains(
                "Scenario=TEST-0194",
                filter,
                StringComparison.Ordinal));
    }
}
