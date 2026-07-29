using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal sealed class ExactGovernanceRepositoryCapture
{
    private readonly IReadOnlyDictionary<string, ExactGitTreeEntry>
        entriesByPath;
    private readonly IReadOnlyDictionary<string, byte[]> selectedBlobsByPath;

    private ExactGovernanceRepositoryCapture(
        ExactGitCommitId subjectCommit,
        GovernanceRepositorySnapshot snapshot,
        ExactGitTreeEntry[] treeEntries,
        Dictionary<string, ExactGitTreeEntry> entriesByPath,
        Dictionary<string, byte[]> selectedBlobsByPath)
    {
        SubjectCommit = subjectCommit;
        Snapshot = snapshot;
        TreeEntries = new ReadOnlyCollection<ExactGitTreeEntry>(treeEntries);
        this.entriesByPath = new ReadOnlyDictionary<
            string,
            ExactGitTreeEntry>(entriesByPath);
        this.selectedBlobsByPath = new ReadOnlyDictionary<string, byte[]>(
            selectedBlobsByPath);
    }

    internal ExactGitCommitId SubjectCommit { get; }

    internal GovernanceRepositorySnapshot Snapshot { get; }

    internal IReadOnlyList<ExactGitTreeEntry> TreeEntries { get; }

    internal static ExactGovernanceRepositoryCapture Create(
        ExactGitCommitId subjectCommit,
        GovernanceRepositorySnapshot snapshot,
        IEnumerable<ExactGitTreeEntry> treeEntries,
        IEnumerable<KeyValuePair<string, ReadOnlyMemory<byte>>>
            selectedBlobsByPath)
    {
        ArgumentNullException.ThrowIfNull(subjectCommit);
        ArgumentNullException.ThrowIfNull(snapshot);
        ArgumentNullException.ThrowIfNull(treeEntries);
        ArgumentNullException.ThrowIfNull(selectedBlobsByPath);

        if (!snapshot.IsExactCommit ||
            snapshot.SubjectCommit != subjectCommit)
        {
            throw new ArgumentException(
                "The exact repository capture and snapshot identities must match.",
                nameof(snapshot));
        }

        var materializedEntries = treeEntries.ToArray();
        if (materializedEntries.Any(entry => entry is null))
        {
            throw new ArgumentException(
                "Exact Git trees cannot contain null entries.",
                nameof(treeEntries));
        }

        var entryMap = materializedEntries.ToDictionary(
            entry => entry.RelativePath,
            StringComparer.Ordinal);
        var contentMap = new Dictionary<string, byte[]>(StringComparer.Ordinal);
        foreach (var pair in selectedBlobsByPath)
        {
            if (!entryMap.TryGetValue(pair.Key, out var entry) ||
                !entry.IsFileBlob ||
                !contentMap.TryAdd(pair.Key, pair.Value.ToArray()))
            {
                throw new ArgumentException(
                    "Selected exact Git blob evidence must be unique and reference a regular tree blob.",
                    nameof(selectedBlobsByPath));
            }
        }

        return new ExactGovernanceRepositoryCapture(
            subjectCommit,
            snapshot,
            materializedEntries,
            entryMap,
            contentMap);
    }

    internal bool TryGetTreeEntry(
        string relativePath,
        out ExactGitTreeEntry? entry)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        return entriesByPath.TryGetValue(relativePath, out entry);
    }

    internal bool TryGetSelectedBlob(
        string relativePath,
        out ReadOnlyMemory<byte> content)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        if (selectedBlobsByPath.TryGetValue(relativePath, out var captured))
        {
            content = captured.ToArray();
            return true;
        }

        content = ReadOnlyMemory<byte>.Empty;
        return false;
    }
}

internal sealed class ExactIntegratedPolicyVersionCapture
{
    private readonly byte[] content;

    private ExactIntegratedPolicyVersionCapture(
        ExactGitCommitId policyCommit,
        ExactGitTreeEntry? versionEntry,
        byte[] content)
    {
        PolicyCommit = policyCommit;
        VersionEntry = versionEntry;
        this.content = content;
    }

    internal ExactGitCommitId PolicyCommit { get; }

    internal ExactGitTreeEntry? VersionEntry { get; }

    internal bool IsAvailable => VersionEntry is not null;

    internal ReadOnlyMemory<byte> Content => content.ToArray();

    internal static ExactIntegratedPolicyVersionCapture Unavailable(
        ExactGitCommitId policyCommit)
    {
        ArgumentNullException.ThrowIfNull(policyCommit);
        return new ExactIntegratedPolicyVersionCapture(
            policyCommit,
            versionEntry: null,
            []);
    }

    internal static ExactIntegratedPolicyVersionCapture Available(
        ExactGitCommitId policyCommit,
        ExactGitTreeEntry versionEntry,
        ReadOnlyMemory<byte> content)
    {
        ArgumentNullException.ThrowIfNull(policyCommit);
        ArgumentNullException.ThrowIfNull(versionEntry);
        if (!versionEntry.IsFileBlob ||
            versionEntry.RelativePath != GovernanceRepositoryPath.Version)
        {
            throw new ArgumentException(
                "Integrated policy version evidence must be the regular root VERSION blob.",
                nameof(versionEntry));
        }

        return new ExactIntegratedPolicyVersionCapture(
            policyCommit,
            versionEntry,
            content.ToArray());
    }
}
