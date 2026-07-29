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
            GovernanceProcessExitCode.Conforming,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    conforming)));
        Assert.Equal(
            GovernanceProcessExitCode.Nonconforming,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    nonconforming)));
        Assert.Equal(
            GovernanceProcessExitCode.Incomplete,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Succeeded(
                    stage,
                    incomplete)));
        Assert.Equal(
            GovernanceProcessExitCode.Rejected,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.MalformedInput)));
        Assert.Equal(
            GovernanceProcessExitCode.Rejected,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.CapabilityDenied)));
        Assert.Equal(
            GovernanceProcessExitCode.Failed,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Failed(
                    stage,
                    OperationFailureCode.DependencyFailed)));
        Assert.Equal(
            GovernanceProcessExitCode.Canceled,
            GovernanceExitCodeMapper.Map(
                OperationResult<GovernanceReport>.Canceled(stage)));
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public void ProcessExitAbiHasOneExactTypedValueSet()
    {
        Assert.Equal(
            [0, 1, 2, 64, 70, 130],
            Enum.GetValues<GovernanceProcessExitCode>()
                .Select(value => (int)value));
    }
}
