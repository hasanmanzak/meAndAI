using System.Collections.ObjectModel;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Analysis;

public sealed class GovernanceAnalysisContext
{
    private readonly IReadOnlyDictionary<string, GovernanceRepositoryEntry>
        _entriesByPath;

    private GovernanceAnalysisContext(
        GovernanceRepositorySnapshot snapshot,
        ProtocolRecordIndex protocolRecords,
        MarkdownDocumentIndex markdownDocuments)
    {
        Snapshot = snapshot;
        ProtocolRecords = protocolRecords;
        MarkdownDocuments = markdownDocuments;
        _entriesByPath = new ReadOnlyDictionary<
            string,
            GovernanceRepositoryEntry>(
            snapshot.Entries.ToDictionary(
                entry => entry.RelativePath,
                StringComparer.Ordinal));
    }

    public GovernanceRepositorySnapshot Snapshot { get; }

    public ProtocolRecordIndex ProtocolRecords { get; }

    public MarkdownDocumentIndex MarkdownDocuments { get; }

    public static GovernanceAnalysisContext Create(
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);
        var protocolRecords = ProtocolRecordIndex.Create(snapshot);
        return new GovernanceAnalysisContext(
            snapshot,
            protocolRecords,
            MarkdownDocumentIndex.Create(
                protocolRecords.DecisionRecords.Select(
                    record => record.Entry)));
    }

    public GovernanceRepositoryEntry GetRequiredEntry(string relativePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        return _entriesByPath.TryGetValue(relativePath, out var entry)
            ? entry
            : throw new KeyNotFoundException(
                $"Repository entry '{relativePath}' does not exist in the snapshot.");
    }

    public bool TryGetEntry(
        string relativePath,
        out GovernanceRepositoryEntry? entry)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(relativePath);
        return _entriesByPath.TryGetValue(relativePath, out entry);
    }
}
