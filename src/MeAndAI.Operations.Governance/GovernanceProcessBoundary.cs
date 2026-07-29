using MeAndAI.Operations.Domain.Results;
using MeAndAI.Operations.Governance.Core.Contracts;

namespace MeAndAI.Operations.Governance;

internal static class GovernanceProcessBoundary
{
    private const string RejectedDiagnostic =
        "Governance validation rejected.";
    private const string FailedDiagnostic =
        "Governance validation failed.";
    private const string CanceledDiagnostic =
        "Governance validation canceled.";

    internal static async Task<GovernanceProcessExitCode> ExecuteAsync(
        Func<CancellationToken, ValueTask<OperationResult<GovernanceReport>>>
            operation,
        TextWriter standardOutput,
        TextWriter standardError,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(operation);
        ArgumentNullException.ThrowIfNull(standardOutput);
        ArgumentNullException.ThrowIfNull(standardError);

        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            var result = await operation(cancellationToken)
                .ConfigureAwait(false);
            cancellationToken.ThrowIfCancellationRequested();
            if (result.Outcome == OperationOutcome.Succeeded)
            {
                var report = result.Value
                    ?? throw new InvalidOperationException(
                        "A successful governance operation requires a report.");
                var serialized = GovernanceReportSerializer.Serialize(report);
                cancellationToken.ThrowIfCancellationRequested();
                await standardOutput.WriteAsync(serialized)
                    .ConfigureAwait(false);
            }
            else
            {
                cancellationToken.ThrowIfCancellationRequested();
                await standardError.WriteLineAsync(GetDiagnostic(result))
                    .ConfigureAwait(false);
            }

            return GovernanceExitCodeMapper.Map(result);
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            await standardError.WriteLineAsync(CanceledDiagnostic)
                .ConfigureAwait(false);
            return GovernanceProcessExitCode.Canceled;
        }
        catch (Exception)
        {
            await standardError.WriteLineAsync(FailedDiagnostic)
                .ConfigureAwait(false);
            return GovernanceProcessExitCode.Failed;
        }
    }

    private static string GetDiagnostic(
        OperationResult<GovernanceReport> result)
    {
        if (result.Outcome == OperationOutcome.Rejected)
        {
            return RejectedDiagnostic;
        }

        if (result.Outcome == OperationOutcome.Failed)
        {
            return FailedDiagnostic;
        }

        if (result.Outcome == OperationOutcome.Canceled)
        {
            return CanceledDiagnostic;
        }

        throw new InvalidOperationException(
            "Only non-successful governance results have diagnostics.");
    }
}
