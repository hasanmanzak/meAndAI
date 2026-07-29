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

        return await RunExactAsync(
            arguments,
            standardOutput,
            standardError,
            PackagedGovernancePolicySource.Resolve,
            cancellationToken).ConfigureAwait(false);
    }

    internal static async Task<int> RunExactAsync(
        IReadOnlyList<string> arguments,
        TextWriter standardOutput,
        TextWriter standardError,
        Func<ExactGitCommitId> policySourceResolver,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(arguments);
        ArgumentNullException.ThrowIfNull(standardOutput);
        ArgumentNullException.ThrowIfNull(standardError);
        ArgumentNullException.ThrowIfNull(policySourceResolver);

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
                token => ValidateExactAsync(
                    arguments,
                    policySourceResolver,
                    token),
                standardOutput,
                standardError,
                cancellationToken)
            .ConfigureAwait(false);
        return (int)exitCode;
    }

    internal static async Task<int> RunCandidateShadowAsync(
        IReadOnlyList<string> arguments,
        TextWriter standardOutput,
        TextWriter standardError,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(arguments);
        ArgumentNullException.ThrowIfNull(standardOutput);
        ArgumentNullException.ThrowIfNull(standardError);

        var exitCode = await GovernanceProcessBoundary.ExecuteAsync(
                token => ValidateCandidateAsync(arguments, token),
                standardOutput,
                standardError,
                cancellationToken)
            .ConfigureAwait(false);
        return (int)exitCode;
    }

    private static async ValueTask<OperationResult<GovernanceReport>>
        ValidateCandidateAsync(
            IReadOnlyList<string> arguments,
            CancellationToken cancellationToken)
    {
        if (!TryParseCandidate(
                arguments,
                out var repository,
                out var profileValue))
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

    private static async ValueTask<OperationResult<GovernanceReport>>
        ValidateExactAsync(
            IReadOnlyList<string> arguments,
            Func<ExactGitCommitId> policySourceResolver,
            CancellationToken cancellationToken)
    {
        if (!TryParseExact(
                arguments,
                out var repository,
                out var profileValue,
                out var subjectCommitValue) ||
            !ExactGitCommitId.TryParse(
                subjectCommitValue,
                out var subjectCommit))
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

        var request = GovernanceRequest.Create(profile, subjectCommit);
        var policy = ProtocolPolicyIdentity.CreateCurrent(
            policySourceResolver());
        var engine = GovernanceEngine.CreateDefault();
        var authority = OperationalAuthorityCatalog
            .For(OperationalApplicationId.Governance)
            .For(OperationStageId.Validate);
        var snapshotPort = new ExactGitGovernanceRepositorySnapshotPort(
            repository,
            ExactRepositoryAcquisitionLimits.From(policy.InstructionGraph));
        var portScope = OperationalPortScope.Create(
            authority,
            OperationalPortRegistration
                .Create<IExactGovernanceRepositorySnapshotPort>(snapshotPort));
        return await OperationBoundary.ExecuteAsync(
            OperationStageId.Validate,
            async token =>
            {
                var port = portScope
                    .Require<IExactGovernanceRepositorySnapshotPort>();
                var capture = await port
                    .CaptureSubjectAsync(request, token)
                    .ConfigureAwait(false);
                var subjectResolution =
                    ExactGovernanceProfileResolver.ResolveSubject(
                        request,
                        capture,
                        policy);
                var profileEvidenceState = subjectResolution switch
                {
                    ExactGovernanceProfileSubjectResolution.Complete =>
                        GovernanceProfileEvidenceState.Complete,
                    ExactGovernanceProfileSubjectResolution.Incomplete =>
                        GovernanceProfileEvidenceState.Incomplete,
                    ExactGovernanceProfileSubjectResolution
                        .RequiresIntegratedPolicyVersion =>
                        ExactGovernanceProfileResolver.ResolveIntegratedPolicy(
                            subjectResolution,
                            policy,
                            await port.CaptureIntegratedPolicyVersionAsync(
                                    policy.SourceCommit,
                                    token)
                                .ConfigureAwait(false)),
                    _ => throw new InvalidOperationException(
                        "Unknown exact governance profile resolution."),
                };

                try
                {
                    return engine.EvaluateExactShadow(
                        profile,
                        capture.Snapshot,
                        policy,
                        profileEvidenceState);
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

    private static bool TryParseCandidate(
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

    private static bool TryParseExact(
        IReadOnlyList<string> arguments,
        out string repository,
        out string profile,
        out string subjectCommit)
    {
        repository = string.Empty;
        profile = string.Empty;
        subjectCommit = string.Empty;

        if (arguments.Count != 7 ||
            !string.Equals(arguments[0], "validate", StringComparison.Ordinal) ||
            !string.Equals(arguments[1], "--repository", StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(arguments[2]) ||
            !string.Equals(arguments[3], "--profile", StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(arguments[4]) ||
            !string.Equals(
                arguments[5],
                "--subject-commit",
                StringComparison.Ordinal) ||
            string.IsNullOrWhiteSpace(arguments[6]))
        {
            return false;
        }

        repository = arguments[2];
        profile = arguments[4];
        subjectCommit = arguments[6];
        return true;
    }
}
