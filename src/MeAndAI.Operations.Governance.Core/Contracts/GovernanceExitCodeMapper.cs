using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Results;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal static class GovernanceExitCodeMapper
{
    internal const int Conforming = 0;
    internal const int Nonconforming = 1;
    internal const int Incomplete = 2;
    internal const int Rejected = 64;
    internal const int Failed = 70;
    internal const int Canceled = 130;

    internal static int Map(OperationResult<GovernanceReport> result)
    {
        ArgumentNullException.ThrowIfNull(result);

        if (result.Outcome == OperationOutcome.Succeeded)
        {
            var report = result.Value
                ?? throw new InvalidOperationException(
                    "A successful governance operation requires a report.");
            return report.Verdict == GovernanceVerdict.Conforming
                ? Conforming
                : report.Verdict == GovernanceVerdict.Nonconforming
                    ? Nonconforming
                    : report.Verdict == GovernanceVerdict.Incomplete
                        ? Incomplete
                        : throw new InvalidOperationException(
                            "The governance report contains an unknown verdict.");
        }

        if (result.Outcome == OperationOutcome.Rejected)
        {
            return Rejected;
        }

        if (result.Outcome == OperationOutcome.Failed)
        {
            return Failed;
        }

        if (result.Outcome == OperationOutcome.Canceled)
        {
            return Canceled;
        }

        throw new InvalidOperationException(
            "The governance operation contains an unknown outcome.");
    }
}
