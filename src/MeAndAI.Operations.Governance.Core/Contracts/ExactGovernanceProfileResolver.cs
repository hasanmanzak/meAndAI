using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Contracts;

internal enum ExactGovernanceProfileSubjectResolution
{
    Complete,
    Incomplete,
    RequiresIntegratedPolicyVersion,
}

internal static class ExactGovernanceProfileResolver
{
    internal static ExactGovernanceProfileSubjectResolution ResolveSubject(
        GovernanceRequest request,
        ExactGovernanceRepositoryCapture capture,
        ProtocolPolicyIdentity policy)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(capture);
        ArgumentNullException.ThrowIfNull(policy);

        if (capture.SubjectCommit != request.SubjectCommit)
        {
            throw new ArgumentException(
                "The exact repository capture does not match the governance request.",
                nameof(capture));
        }

        return request.Profile == GovernanceProfileId.ProtocolAuthority
            ? ResolveAuthority(capture, policy)
            : request.Profile == GovernanceProfileId.Consumer
                ? ResolveConsumer(capture, policy)
                : throw new ArgumentOutOfRangeException(
                    nameof(request),
                    request.Profile,
                    "Unknown governance profile identity.");
    }

    internal static GovernanceProfileEvidenceState ResolveIntegratedPolicy(
        ExactGovernanceProfileSubjectResolution subjectResolution,
        ProtocolPolicyIdentity policy,
        ExactIntegratedPolicyVersionCapture capture)
    {
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentNullException.ThrowIfNull(capture);
        if (subjectResolution !=
            ExactGovernanceProfileSubjectResolution
                .RequiresIntegratedPolicyVersion)
        {
            throw new ArgumentOutOfRangeException(
                nameof(subjectResolution),
                subjectResolution,
                "Integrated policy evidence was not requested.");
        }

        return capture.PolicyCommit == policy.SourceCommit &&
            capture.IsAvailable &&
            capture.VersionEntry?.Mode == ExactGitTreeEntryMode.RegularFile &&
            capture.Content.Span.SequenceEqual(
                BoundedGovernanceContract.VersionFileBytes.Span)
            ? GovernanceProfileEvidenceState.Complete
            : GovernanceProfileEvidenceState.Incomplete;
    }

    private static ExactGovernanceProfileSubjectResolution ResolveAuthority(
        ExactGovernanceRepositoryCapture capture,
        ProtocolPolicyIdentity policy)
    {
        if (capture.SubjectCommit != policy.SourceCommit ||
            !HasCanonicalVersion(capture) ||
            HasProtocolTreeEvidence(capture) ||
            HasConflictingGitModulesEvidence(capture))
        {
            return ExactGovernanceProfileSubjectResolution.Incomplete;
        }

        return ExactGovernanceProfileSubjectResolution.Complete;
    }

    private static ExactGovernanceProfileSubjectResolution ResolveConsumer(
        ExactGovernanceRepositoryCapture capture,
        ProtocolPolicyIdentity policy)
    {
        if (capture.SubjectCommit == policy.SourceCommit)
        {
            return ExactGovernanceProfileSubjectResolution.Incomplete;
        }

        var protocolEntries = capture.TreeEntries
            .Where(entry => ProtocolIntegrationPath.IsExactOrCaseVariant(
                entry.RelativePath))
            .ToArray();
        if (protocolEntries.Length != 1 ||
            !string.Equals(
                protocolEntries[0].RelativePath,
                ProtocolIntegrationPath.Canonical,
                StringComparison.Ordinal) ||
            protocolEntries[0].Mode != ExactGitTreeEntryMode.GitLink ||
            protocolEntries[0].ObjectType != ExactGitObjectType.Commit ||
            !string.Equals(
                protocolEntries[0].ObjectId.Value,
                policy.SourceCommit.Value,
                StringComparison.Ordinal) ||
            !HasCanonicalGitModulesEvidence(capture))
        {
            return ExactGovernanceProfileSubjectResolution.Incomplete;
        }

        return ExactGovernanceProfileSubjectResolution
            .RequiresIntegratedPolicyVersion;
    }

    private static bool HasCanonicalVersion(
        ExactGovernanceRepositoryCapture capture) =>
        capture.TryGetTreeEntry(
            GovernanceRepositoryPath.Version,
            out var entry) &&
        entry?.Mode == ExactGitTreeEntryMode.RegularFile &&
        capture.TryGetSelectedBlob(
            GovernanceRepositoryPath.Version,
            out var content) &&
        content.Span.SequenceEqual(
            BoundedGovernanceContract.VersionFileBytes.Span);

    private static bool HasProtocolTreeEvidence(
        ExactGovernanceRepositoryCapture capture) =>
        capture.TreeEntries.Any(entry =>
            ProtocolIntegrationPath.IsExactOrCaseVariant(
                entry.RelativePath) ||
            (ProtocolIntegrationPath.CollidesWithReservedPath(
                    entry.RelativePath) &&
                entry.Mode != ExactGitTreeEntryMode.Directory));

    private static bool HasConflictingGitModulesEvidence(
        ExactGovernanceRepositoryCapture capture)
    {
        if (!capture.TryGetTreeEntry(
                GovernanceRepositoryPath.SubmoduleConfiguration,
                out var entry))
        {
            return false;
        }

        if (entry?.Mode != ExactGitTreeEntryMode.RegularFile ||
            !capture.TryGetSelectedBlob(
                GovernanceRepositoryPath.SubmoduleConfiguration,
                out var content))
        {
            return true;
        }

        var analysis = ProtocolSubmoduleConfiguration.Analyze(content);
        return !analysis.IsReadable || analysis.HasReservedProtocolReference;
    }

    private static bool HasCanonicalGitModulesEvidence(
        ExactGovernanceRepositoryCapture capture)
    {
        if (!capture.TryGetTreeEntry(
                GovernanceRepositoryPath.SubmoduleConfiguration,
                out var entry) ||
            entry?.Mode != ExactGitTreeEntryMode.RegularFile ||
            !capture.TryGetSelectedBlob(
                GovernanceRepositoryPath.SubmoduleConfiguration,
                out var content))
        {
            return false;
        }

        var analysis = ProtocolSubmoduleConfiguration.Analyze(content);
        return analysis.IsReadable &&
            analysis.HasCanonicalProtocolMapping;
    }
}
