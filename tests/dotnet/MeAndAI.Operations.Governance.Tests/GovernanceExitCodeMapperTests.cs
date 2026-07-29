using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceExitCodeMapperTests
{
    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void OperationOutcomesAndGovernanceVerdictsHaveOneExactExitMap()
    {
        var stage = OperationStageId.Validate;
        var conforming = GovernanceReportTestData.ConformingReport();
        var incomplete = GovernanceReportTestData.IncompleteReport();
        var nonconforming = GovernanceReportTestData.NonconformingReport();

        Assert.Equal(
            0,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    conforming)));
        Assert.Equal(
            1,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    nonconforming)));
        Assert.Equal(
            2,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    incomplete)));
        Assert.Equal(
            64,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.MalformedInput)));
        Assert.Equal(
            64,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.CapabilityDenied)));
        Assert.Equal(
            70,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Failed(
                    stage,
                    OperationFailureCode.DependencyFailed)));
        Assert.Equal(
            130,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Canceled(stage)));
    }

}
