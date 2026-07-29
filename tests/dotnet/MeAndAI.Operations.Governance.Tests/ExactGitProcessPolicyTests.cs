using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ExactGitProcessPolicyTests
{
    [Fact]
    public void ExactGitRequestsNeutralizePathspecAndTraceControls()
    {
        var request = ExactGitProcessPolicy.CreateTreeRequest(
            Path.GetFullPath(Path.GetTempPath()),
            ["ls-tree"],
            ExactRepositoryAcquisitionLimits.From(
                BoundedGovernanceContract.InstructionGraph));
        var environment = request.EnvironmentOverrides.ToDictionary(
            pair => pair.Key,
            pair => pair.Value,
            StringComparer.OrdinalIgnoreCase);

        foreach (var name in new[]
                 {
                     "GIT_GLOB_PATHSPECS",
                     "GIT_ICASE_PATHSPECS",
                     "GIT_LITERAL_PATHSPECS",
                     "GIT_NOGLOB_PATHSPECS",
                     "GIT_TRACE",
                     "GIT_TRACE2",
                     "GIT_TRACE2_EVENT",
                     "GIT_TRACE2_PERF",
                 })
        {
            Assert.True(environment.TryGetValue(name, out var value));
            Assert.Null(value);
        }
    }
}
