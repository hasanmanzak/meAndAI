using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Analysis;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal static class BoundedGovernanceRepositoryProjection
{
    internal static IReadOnlyList<ExactGitTreeEntry> SelectBlobEntries(
        IReadOnlyList<ExactGitTreeEntry> treeEntries,
        GovernanceProfileId profile)
    {
        ArgumentNullException.ThrowIfNull(treeEntries);
        ArgumentNullException.ThrowIfNull(profile);
        if (profile != GovernanceProfileId.ProtocolAuthority &&
            profile != GovernanceProfileId.Consumer)
        {
            throw new ArgumentOutOfRangeException(
                nameof(profile),
                profile,
                "Unknown exact governance profile identity.");
        }

        var entriesByPath = treeEntries.ToDictionary(
            entry => entry.RelativePath,
            StringComparer.Ordinal);
        EnsureSafeGovernanceContainers(entriesByPath);

        var selected = treeEntries
            .Where(entry =>
                entry.IsFileBlob &&
                (IsProfileEvidenceFile(entry, profile) ||
                 IsGovernanceFile(entry, entriesByPath)))
            .OrderBy(entry => entry.RelativePath, StringComparer.Ordinal)
            .ToArray();

        EnsureNoSelectedLinks(treeEntries);
        return selected;
    }

    internal static IReadOnlyList<GovernanceRepositoryEntry> CreateEntries(
        IReadOnlyList<ExactGitTreeEntry> treeEntries,
        IReadOnlyDictionary<string, ReadOnlyMemory<byte>> selectedBlobsByPath)
    {
        ArgumentNullException.ThrowIfNull(treeEntries);
        ArgumentNullException.ThrowIfNull(selectedBlobsByPath);
        var entriesByPath = treeEntries.ToDictionary(
            entry => entry.RelativePath,
            StringComparer.Ordinal);
        EnsureSafeGovernanceContainers(entriesByPath);
        EnsureNoSelectedLinks(treeEntries);

        var projected = new List<GovernanceRepositoryEntry>();
        foreach (var entry in treeEntries)
        {
            if (IsFeatureRecordDirectory(entry, entriesByPath))
            {
                projected.Add(GovernanceRepositoryEntry.Directory(
                    entry.RelativePath));
                continue;
            }

            if (!entry.IsFileBlob ||
                !IsGovernanceFile(entry, entriesByPath))
            {
                continue;
            }

            if (!selectedBlobsByPath.TryGetValue(
                    entry.RelativePath,
                    out var content))
            {
                throw new InvalidDataException(
                    "A selected governance blob is absent from the exact object capture.");
            }

            projected.Add(GovernanceRepositoryEntry.File(
                entry.RelativePath,
                content));
        }

        return projected;
    }

    private static void EnsureSafeGovernanceContainers(
        IReadOnlyDictionary<string, ExactGitTreeEntry> entriesByPath)
    {
        foreach (var path in new[]
                 {
                     "docs",
                     "docs/features",
                     "docs/decisions",
                 })
        {
            if (entriesByPath.TryGetValue(path, out var entry) &&
                IsLink(entry))
            {
                throw new InvalidDataException(
                    "Governance repository containers cannot be links.");
            }
        }
    }

    private static void EnsureNoSelectedLinks(
        IEnumerable<ExactGitTreeEntry> treeEntries)
    {
        foreach (var entry in treeEntries)
        {
            var linkedFeatureRecord =
                ProtocolRecordPath.GetFeatureRecordId(entry.RelativePath)
                    is not null &&
                IsLink(entry);
            var linkedFeatureChild =
                ProtocolRecordPath.IsRequiredFeatureFile(
                    entry.RelativePath) &&
                IsLink(entry);
            var linkedDecision =
                ProtocolRecordPath.GetDecisionRecordId(entry.RelativePath)
                    is not null &&
                IsLink(entry);
            if (linkedFeatureRecord || linkedFeatureChild || linkedDecision)
            {
                throw new InvalidDataException(
                    "Selected governance entries cannot be links.");
            }
        }
    }

    private static bool IsLink(ExactGitTreeEntry entry) =>
        entry.Mode is ExactGitTreeEntryMode.SymbolicLink or
            ExactGitTreeEntryMode.GitLink;

    private static bool IsGovernanceFile(
        ExactGitTreeEntry entry,
        IReadOnlyDictionary<string, ExactGitTreeEntry> entriesByPath)
    {
        if (ProtocolRecordPath.IsRequiredFeatureFile(entry.RelativePath))
        {
            var parent = entry.RelativePath[..entry.RelativePath.LastIndexOf('/')];
            return HasDirectory(entriesByPath, "docs") &&
                HasDirectory(entriesByPath, "docs/features") &&
                HasDirectory(entriesByPath, parent);
        }

        return ProtocolRecordPath.GetDecisionRecordId(entry.RelativePath)
                is not null &&
            HasDirectory(entriesByPath, "docs") &&
            HasDirectory(entriesByPath, "docs/decisions");
    }

    private static bool IsFeatureRecordDirectory(
        ExactGitTreeEntry entry,
        IReadOnlyDictionary<string, ExactGitTreeEntry> entriesByPath)
    {
        return entry.Mode == ExactGitTreeEntryMode.Directory &&
            ProtocolRecordPath.GetFeatureRecordId(entry.RelativePath)
                is not null &&
            HasDirectory(entriesByPath, "docs") &&
            HasDirectory(entriesByPath, "docs/features");
    }

    private static bool IsProfileEvidenceFile(
        ExactGitTreeEntry entry,
        GovernanceProfileId profile) =>
        entry.RelativePath ==
            GovernanceRepositoryPath.SubmoduleConfiguration ||
        (profile == GovernanceProfileId.ProtocolAuthority &&
            entry.RelativePath == GovernanceRepositoryPath.Version);

    private static bool HasDirectory(
        IReadOnlyDictionary<string, ExactGitTreeEntry> entriesByPath,
        string relativePath) =>
        entriesByPath.TryGetValue(relativePath, out var entry) &&
        entry.Mode == ExactGitTreeEntryMode.Directory;
}
