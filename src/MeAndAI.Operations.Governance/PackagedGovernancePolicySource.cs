using System.Reflection;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance;

internal static class PackagedGovernancePolicySource
{
    private const string MetadataKey =
        "MeAndAI.Governance.PolicySourceCommit";

    private const string ResolutionFailure =
        "The governance assembly does not contain one exact packaged policy source commit.";

    internal static ExactGitCommitId Resolve() =>
        Resolve(typeof(GovernanceCli).Assembly
            .GetCustomAttributes<AssemblyMetadataAttribute>());

    internal static ExactGitCommitId Resolve(
        IEnumerable<AssemblyMetadataAttribute> metadata)
    {
        ArgumentNullException.ThrowIfNull(metadata);

        var values = metadata
            .Where(attribute => string.Equals(
                attribute.Key,
                MetadataKey,
                StringComparison.Ordinal))
            .Select(attribute => attribute.Value)
            .ToArray();
        if (values.Length != 1 ||
            !ExactGitCommitId.TryParse(values[0], out var sourceCommit))
        {
            throw new InvalidOperationException(ResolutionFailure);
        }

        return sourceCommit;
    }
}
