using System.Collections.ObjectModel;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Core.Analysis;

public sealed partial class ProtocolRecordIndex
{
    private ProtocolRecordIndex(
        FeatureRecord[] featureRecords,
        DecisionRecord[] decisionRecords)
    {
        FeatureRecords = new ReadOnlyCollection<FeatureRecord>(
            featureRecords);
        DecisionRecords = new ReadOnlyCollection<DecisionRecord>(
            decisionRecords);
    }

    public IReadOnlyList<FeatureRecord> FeatureRecords { get; }

    public IReadOnlyList<DecisionRecord> DecisionRecords { get; }

    public static ProtocolRecordIndex Create(
        GovernanceRepositorySnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);

        var featureRecords = snapshot.Entries
            .Where(entry =>
                entry.Kind == GovernanceRepositoryEntryKind.Directory)
            .Select(entry => new
            {
                Entry = entry,
                Id = ProtocolRecordPath.GetFeatureRecordId(
                    entry.RelativePath),
            })
            .Where(candidate => candidate.Id is not null)
            .Select(candidate => new FeatureRecord(
                candidate.Entry,
                candidate.Id!))
            .OrderBy(record => record.RelativePath, StringComparer.Ordinal)
            .ToArray();
        var decisionRecords = snapshot.Entries
            .Where(entry => entry.Kind == GovernanceRepositoryEntryKind.File)
            .Select(entry => new
            {
                Entry = entry,
                Id = ProtocolRecordPath.GetDecisionRecordId(
                    entry.RelativePath),
            })
            .Where(candidate => candidate.Id is not null)
            .Select(candidate => new DecisionRecord(
                candidate.Entry,
                candidate.Id!))
            .OrderBy(record => record.RelativePath, StringComparer.Ordinal)
            .ToArray();

        return new ProtocolRecordIndex(featureRecords, decisionRecords);
    }
}

public abstract class ProtocolRecord
{
    private protected ProtocolRecord(
        GovernanceRepositoryEntry entry,
        string id)
    {
        Entry = entry;
        Id = id;
    }

    public GovernanceRepositoryEntry Entry { get; }

    public string Id { get; }

    public RepositoryRelativePath Path => Entry.Path;

    public string RelativePath => Entry.RelativePath;
}

public sealed class FeatureRecord : ProtocolRecord
{
    internal FeatureRecord(
        GovernanceRepositoryEntry entry,
        string featureId)
        : base(entry, featureId)
    {
    }

    public string FeatureId => Id;
}

public sealed class DecisionRecord : ProtocolRecord
{
    internal DecisionRecord(
        GovernanceRepositoryEntry entry,
        string decisionId)
        : base(entry, decisionId)
    {
    }

    public string DecisionId => Id;
}
