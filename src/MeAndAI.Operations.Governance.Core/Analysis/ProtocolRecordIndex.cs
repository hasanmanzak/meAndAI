using System.Collections.ObjectModel;
using System.Text.RegularExpressions;
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
                Match = FeatureRecordPathPattern().Match(
                    entry.RelativePath),
            })
            .Where(candidate => candidate.Match.Success)
            .Select(candidate => new FeatureRecord(
                candidate.Entry,
                candidate.Match.Groups["id"].Value))
            .OrderBy(record => record.RelativePath, StringComparer.Ordinal)
            .ToArray();
        var decisionRecords = snapshot.Entries
            .Where(entry => entry.Kind == GovernanceRepositoryEntryKind.File)
            .Select(entry => new
            {
                Entry = entry,
                Match = DecisionRecordPathPattern().Match(
                    entry.RelativePath),
            })
            .Where(candidate => candidate.Match.Success)
            .Select(candidate => new DecisionRecord(
                candidate.Entry,
                candidate.Match.Groups["id"].Value))
            .OrderBy(record => record.RelativePath, StringComparer.Ordinal)
            .ToArray();

        return new ProtocolRecordIndex(featureRecords, decisionRecords);
    }

    [GeneratedRegex(
        "^docs/features/(?<id>FEAT-[0-9]{4})-[^/]+$",
        RegexOptions.CultureInvariant)]
    private static partial Regex FeatureRecordPathPattern();

    [GeneratedRegex(
        "^docs/decisions/(?<id>DEC-[0-9]{4})-[^/]+\\.md$",
        RegexOptions.CultureInvariant)]
    private static partial Regex DecisionRecordPathPattern();
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
