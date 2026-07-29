namespace MeAndAI.Operations.Governance.Tests;

public sealed class HostedGovernanceEvidenceRouteTests
{
    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ProtocolWorkflowExecutesBoundedGovernanceTestsOnBothHostedPlatforms()
    {
        AssertHostedScenarioRoute("TEST-0194");
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ProtocolWorkflowExecutesReportProcessTestsOnBothHostedPlatforms()
    {
        AssertHostedScenarioRoute(GovernanceScenarios.ReportProcess);
    }

    private static void AssertHostedScenarioRoute(string scenarioId)
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
            filter =>
            {
                var firstToken = filter.IndexOf(
                    "Scenario=",
                    StringComparison.Ordinal);
                Assert.True(firstToken >= 0);
                var tokens = filter[firstToken..]
                    .TrimEnd('"')
                    .Split('|');
                Assert.Contains(
                    $"Scenario={scenarioId}",
                    tokens,
                    StringComparer.Ordinal);
            });
    }
}
