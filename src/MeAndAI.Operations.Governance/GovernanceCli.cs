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

        return await GovernanceProcessBoundary.ExecuteAsync(
            token => ValidateAsync(arguments, token),
            standardOutput,
            standardError,
            cancellationToken).ConfigureAwait(false);
    }

    private static async ValueTask<OperationResult<GovernanceReport>>
        ValidateAsync(
            IReadOnlyList<string> arguments,
            CancellationToken cancellationToken)
    {
        if (!TryParse(arguments, out var repository, out var profileValue))
        {
            return OperationResult<GovernanceReport>.Rejected(
                OperationStageId.Validate,
                OperationFailureCode.MalformedInput);
        }

        GovernanceProfileId profile;
        try
        {
            profile = GovernanceProfileId.Parse(profileValue);
        }
        catch (ArgumentOutOfRangeException)
        {
            return OperationResult<GovernanceReport>.Rejected(
                OperationStageId.Validate,
                OperationFailureCode.MalformedInput);
        }

        var engine = GovernanceEngine.CreateDefault();
        try
        {
            engine.RequireCandidateProfile(profile);
        }
        catch (ArgumentOutOfRangeException)
        {
            return OperationResult<GovernanceReport>.Rejected(
                OperationStageId.Validate,
                OperationFailureCode.CapabilityDenied);
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
        return await OperationBoundary.ExecuteAsync(
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
            cancellationToken).ConfigureAwait(false);
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
