using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Results;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal enum GovernanceProcessExitCode : int
{
    Conforming = 0,
    Nonconforming = 1,
    Incomplete = 2,
    Rejected = 64,
    Failed = 70,
    Canceled = 130,
}

internal static class GovernanceExitCodeMapper
{
    internal static GovernanceProcessExitCode Map(
        OperationResult<GovernanceReport> result)
    {
        ArgumentNullException.ThrowIfNull(result);

        if (result.Outcome == OperationOutcome.Succeeded)
        {
            var report = result.Value
                ?? throw new InvalidOperationException(
                    "A successful governance operation requires a report.");
            return report.Verdict == GovernanceVerdict.Conforming
                ? GovernanceProcessExitCode.Conforming
                : report.Verdict == GovernanceVerdict.Nonconforming
                    ? GovernanceProcessExitCode.Nonconforming
                    : report.Verdict == GovernanceVerdict.Incomplete
                        ? GovernanceProcessExitCode.Incomplete
                        : throw new InvalidOperationException(
                            "The governance report contains an unknown verdict.");
        }

        if (result.Outcome == OperationOutcome.Rejected)
        {
            return GovernanceProcessExitCode.Rejected;
        }

        if (result.Outcome == OperationOutcome.Failed)
        {
            return GovernanceProcessExitCode.Failed;
        }

        if (result.Outcome == OperationOutcome.Canceled)
        {
            return GovernanceProcessExitCode.Canceled;
        }

        throw new InvalidOperationException(
            "The governance operation contains an unknown outcome.");
    }
}
