using System.Text.Json;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class OperationBoundaryTests
{
    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task PreCanceledOperationIsNotInvoked()
    {
        using var cancellation = new CancellationTokenSource();
        await cancellation.CancelAsync();
        var invoked = false;

        var result = await OperationBoundary.ExecuteAsync(
            OperationStageId.Assess,
            _ =>
            {
                invoked = true;
                return ValueTask.FromResult(
                    new OperationResultTests.PublicReceipt("unexpected"));
            },
            cancellation.Token);

        Assert.False(invoked);
        Assert.Same(OperationOutcome.Canceled, result.Outcome);
        Assert.Same(OperationFailureCode.OperationCanceled, result.FailureCode);
        Assert.Null(result.Value);
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task RequestedInFlightCancellationHasOneCanceledShape()
    {
        using var cancellation = new CancellationTokenSource();
        var entered = new TaskCompletionSource(
            TaskCreationOptions.RunContinuationsAsynchronously);

        var pending = OperationBoundary.ExecuteAsync(
            OperationStageId.Discover,
            async token =>
            {
                entered.SetResult();
                await Task.Delay(Timeout.InfiniteTimeSpan, token);
                return new OperationResultTests.PublicReceipt("unexpected");
            },
            cancellation.Token);

        await entered.Task;
        await cancellation.CancelAsync();
        var result = await pending;

        Assert.Same(OperationOutcome.Canceled, result.Outcome);
        Assert.Same(OperationFailureCode.OperationCanceled, result.FailureCode);
        Assert.Equal("discover:canceled:operation.canceled", result.ToString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task DependencyFailureDropsRawExceptionAndSecretText()
    {
        const string secret = "private-token-value";

        var result = await OperationBoundary.ExecuteAsync(
            OperationStageId.Publish,
            _ => ValueTask.FromException<OperationResultTests.PublicReceipt>(
                new OperationalDependencyException(
                    $"Provider rejected {secret}.")),
            CancellationToken.None);

        var json = JsonSerializer.Serialize(result);

        Assert.Same(OperationOutcome.Failed, result.Outcome);
        Assert.Same(OperationFailureCode.DependencyFailed, result.FailureCode);
        Assert.Null(result.Value);
        Assert.DoesNotContain(secret, json, StringComparison.Ordinal);
        Assert.DoesNotContain("Provider rejected", json, StringComparison.Ordinal);
        Assert.Equal("publish:failed:dependency.failed", result.ToString());
    }

    [Fact]
    [Trait("Scenario", "TEST-0192")]
    public async Task UnexpectedProgrammingFailureIsNotRelabeled()
    {
        var failure = await Assert.ThrowsAsync<InvalidOperationException>(
            async () => await OperationBoundary.ExecuteAsync(
                OperationStageId.Apply,
                _ => ValueTask.FromException<OperationResultTests.PublicReceipt>(
                    new InvalidOperationException("programming defect")),
                CancellationToken.None));

        Assert.Equal("programming defect", failure.Message);
    }
}
