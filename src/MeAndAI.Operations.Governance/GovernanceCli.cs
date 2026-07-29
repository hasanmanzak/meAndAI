using MeAndAI.Operations.Application.Authority;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Results;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;
using MeAndAI.Operations.Infrastructure.Execution;
using MeAndAI.Operations.Infrastructure.Hosting;
using MeAndAI.Operations.Infrastructure.Ports;

namespace MeAndAI.Operations.Governance;

public static class GovernanceCli
{
    public static async Task<int> RunAsync(
        IReadOnlyList<string> arguments,
        TextWriter standardOutput,
        TextWriter standardError,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(arguments);
        ArgumentNullException.ThrowIfNull(standardOutput);
        ArgumentNullException.ThrowIfNull(standardError);

        if (arguments.Count == 1 &&
            string.Equals(
                arguments[0],
                "--describe-contract",
                StringComparison.Ordinal))
        {
            return OperationalApplicationHost.Run(
                OperationalApplicationId.Governance,
                arguments,
                standardOutput,
                standardError);
        }

        if (!TryParse(arguments, out var repository, out var profileValue))
        {
            await standardError.WriteLineAsync(
                "Usage: validate --repository <path> --profile protocol-authority.");
            return 64;
        }

        GovernanceProfileId profile;
        try
        {
            profile = GovernanceProfileId.Parse(profileValue);
        }
        catch (ArgumentOutOfRangeException)
        {
            await standardError.WriteLineAsync("Unknown governance profile.");
            return 64;
        }

        var engine = GovernanceEngine.CreateDefault();
        try
        {
            engine.RequireCandidateProfile(profile);
        }
        catch (ArgumentOutOfRangeException)
        {
            await standardError.WriteLineAsync(
                "Governance profile is unavailable for candidate validation.");
            return 64;
        }

        var authority = OperationalAuthorityCatalog
            .For(OperationalApplicationId.Governance)
            .For(OperationStageId.Validate);
        var snapshotPort = new FileSystemGovernanceRepositorySnapshotPort(
            repository);
        var portScope = OperationalPortScope.Create(
            authority,
            OperationalPortRegistration
                .Create<IGovernanceRepositorySnapshotPort>(snapshotPort));
        var result = await OperationBoundary.ExecuteAsync(
            OperationStageId.Validate,
            async token =>
            {
                var snapshot = await portScope
                    .Require<IGovernanceRepositorySnapshotPort>()
                    .CaptureCandidateAsync(token)
                    .ConfigureAwait(false);
                try
                {
                    return engine.EvaluateCandidateShadow(
                        profile,
                        snapshot);
                }
                catch (InvalidDataException exception)
                {
                    throw new OperationalDependencyException(
                        "Governance repository content could not be analyzed.",
                        exception);
                }
            },
            cancellationToken);

        if (result.Outcome == OperationOutcome.Succeeded)
        {
            var report = result.Value
                ?? throw new InvalidOperationException(
                    "A successful governance operation requires a report.");
            await standardOutput.WriteAsync(
                GovernanceReportSerializer.Serialize(report));
            return report.Verdict == GovernanceVerdict.Conforming
                ? 0
                : report.Verdict == GovernanceVerdict.Nonconforming
                    ? 1
                    : 2;
        }

        if (result.Outcome == OperationOutcome.Canceled)
        {
            await standardError.WriteLineAsync(
                "Governance validation canceled.");
            return 130;
        }

        if (result.Outcome == OperationOutcome.Failed)
        {
            await standardError.WriteLineAsync(
                "Repository snapshot capture failed.");
            return 70;
        }

        await standardError.WriteLineAsync("Governance validation rejected.");
        return 64;
    }

    private static bool TryParse(
        IReadOnlyList<string> arguments,
        out string repository,
        out string profile)
    {
        repository = string.Empty;
        profile = string.Empty;

        if (arguments.Count != 5 ||
            !string.Equals(arguments[0], "validate", StringComparison.Ordinal) ||
            !string.Equals(arguments[1], "--repository", StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(arguments[2]) ||
            !string.Equals(arguments[3], "--profile", StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(arguments[4]))
        {
            return false;
        }

        repository = arguments[2];
        profile = arguments[4];
        return true;
    }
}
