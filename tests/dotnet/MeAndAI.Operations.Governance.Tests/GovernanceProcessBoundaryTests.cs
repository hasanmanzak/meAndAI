using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceProcessBoundaryTests
{
    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task SuccessfulVerdictsEmitOnlyTheirCanonicalReport()
    {
        var stage = OperationStageId.Validate;
        var cases = new[]
        {
            (
                ExitCode: GovernanceProcessExitCode.Conforming,
                Report: GovernanceReportTestData.ConformingReport()),
            (
                ExitCode: GovernanceProcessExitCode.Nonconforming,
                Report: GovernanceReportTestData.NonconformingReport()),
            (
                ExitCode: GovernanceProcessExitCode.Incomplete,
                Report: GovernanceReportTestData.IncompleteReport()),
        };

        foreach (var item in cases)
        {
            var result = OperationResult<GovernanceReport>.Succeeded(
                stage,
                item.Report);
            using var output = new StringWriter();
            using var error = new StringWriter();

            var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
                _ => ValueTask.FromResult(result),
                output,
                error,
                CancellationToken.None);

            Assert.Same(OperationOutcome.Succeeded, result.Outcome);
            Assert.Null(result.FailureCode);
            Assert.Equal(item.ExitCode, exitCode);
            Assert.Equal(
                GovernanceReportSerializer.Serialize(item.Report),
                output.ToString());
            Assert.Equal(string.Empty, error.ToString());
        }
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task NonSuccessfulOutcomesEmitOnlyFixedDiagnostics()
    {
        var stage = OperationStageId.Validate;
        var cases = new[]
        {
            (
                ExitCode: GovernanceProcessExitCode.Rejected,
                Diagnostic: "Governance validation rejected.\n",
                Result: OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.MalformedInput)),
            (
                ExitCode: GovernanceProcessExitCode.Rejected,
                Diagnostic: "Governance validation rejected.\n",
                Result: OperationResult<GovernanceReport>.Rejected(
                    stage,
                    OperationFailureCode.CapabilityDenied)),
            (
                ExitCode: GovernanceProcessExitCode.Failed,
                Diagnostic: "Governance validation failed.\n",
                Result: OperationResult<GovernanceReport>.Failed(
                    stage,
                    OperationFailureCode.DependencyFailed)),
            (
                ExitCode: GovernanceProcessExitCode.Canceled,
                Diagnostic: "Governance validation canceled.\n",
                Result: OperationResult<GovernanceReport>.Canceled(stage)),
        };

        foreach (var item in cases)
        {
            using var output = new StringWriter();
            using var error = new StringWriter();

            var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
                _ => ValueTask.FromResult(item.Result),
                output,
                error,
                CancellationToken.None);

            Assert.Equal(item.ExitCode, exitCode);
            Assert.Equal(string.Empty, output.ToString());
            Assert.Equal(
                item.Diagnostic,
                NormalizeNewline(error.ToString()));
        }
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task UnexpectedProgrammingFailureIsRedactedAtTheOuterBoundary()
    {
        const string secret = "secret-fixture-value";
        using var output = new StringWriter();
        using var error = new StringWriter();

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
            _ => ValueTask.FromException<OperationResult<GovernanceReport>>(
                new InvalidOperationException(secret)),
            output,
            error,
            CancellationToken.None);

        var diagnostic = NormalizeNewline(error.ToString());
        Assert.Equal(GovernanceProcessExitCode.Failed, exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal("Governance validation failed.\n", diagnostic);
        Assert.DoesNotContain(secret, diagnostic, StringComparison.Ordinal);
        Assert.DoesNotContain(
            nameof(InvalidOperationException),
            diagnostic,
            StringComparison.Ordinal);
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task OuterCancellationUsesTheCanceledProcessContract()
    {
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();
        using var output = new StringWriter();
        using var error = new StringWriter();

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
            _ => ValueTask.FromException<OperationResult<GovernanceReport>>(
                new OperationCanceledException(cancellation.Token)),
            output,
            error,
            cancellation.Token);

        Assert.Equal(GovernanceProcessExitCode.Canceled, exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal(
            "Governance validation canceled.\n",
            NormalizeNewline(error.ToString()));
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task PreCanceledBoundaryDoesNotInvokeTheOperation()
    {
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();
        using var output = new StringWriter();
        using var error = new StringWriter();
        var invoked = false;

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
            _ =>
            {
                invoked = true;
                return ValueTask.FromResult(
                    OperationResult<GovernanceReport>.Rejected(
                        OperationStageId.Validate,
                        OperationFailureCode.MalformedInput));
            },
            output,
            error,
            cancellation.Token);

        Assert.False(invoked);
        Assert.Equal(GovernanceProcessExitCode.Canceled, exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal(
            "Governance validation canceled.\n",
            NormalizeNewline(error.ToString()));
    }

    [Fact]
    [Trait("Scenario", GovernanceScenarios.ReportProcess)]
    public async Task CancellationRequestedByTheOperationSuppressesItsReport()
    {
        using var cancellation = new CancellationTokenSource();
        using var output = new StringWriter();
        using var error = new StringWriter();

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
            _ =>
            {
                cancellation.Cancel();
                return ValueTask.FromResult(
                    OperationResult<GovernanceReport>.Succeeded(
                        OperationStageId.Validate,
                        GovernanceReportTestData.ConformingReport()));
            },
            output,
            error,
            cancellation.Token);

        Assert.Equal(GovernanceProcessExitCode.Canceled, exitCode);
        Assert.Equal(string.Empty, output.ToString());
        Assert.Equal(
            "Governance validation canceled.\n",
            NormalizeNewline(error.ToString()));
    }

    private static string NormalizeNewline(string value) =>
        value.Replace("\r\n", "\n", StringComparison.Ordinal);
}
