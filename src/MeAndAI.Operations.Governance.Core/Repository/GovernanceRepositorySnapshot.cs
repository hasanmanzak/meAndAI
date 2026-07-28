using System.Collections.ObjectModel;
using System.Security.Cryptography;
using System.Text;

namespace MeAndAI.Operations.Governance.Core.Repository;

public sealed class GovernanceRepositorySnapshot
{
    private GovernanceRepositorySnapshot(
        GovernanceRepositoryEntry[] entries,
        string digest)
    {
        Entries = new ReadOnlyCollection<GovernanceRepositoryEntry>(entries);
        EvidenceDigest = digest;
    }

    public string Mode => "candidate";

    public string EvidenceDigest { get; }

    public IReadOnlyList<GovernanceRepositoryEntry> Entries { get; }

    public static GovernanceRepositorySnapshot CreateCandidate(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        ArgumentNullException.ThrowIfNull(entries);

        var materialized = entries.ToArray();
        if (materialized.Any(entry => entry is null))
        {
            throw new ArgumentException(
                "Repository snapshots cannot contain null entries.",
                nameof(entries));
        }

        var ordered = materialized
            .OrderBy(entry => entry.RelativePath, StringComparer.Ordinal)
            .ThenBy(entry => entry.Kind)
            .ToArray();
        var duplicatePath = ordered
            .GroupBy(entry => entry.RelativePath, StringComparer.Ordinal)
            .FirstOrDefault(group => group.Count() > 1);
        if (duplicatePath is not null)
        {
            throw new ArgumentException(
                $"Repository snapshot path '{duplicatePath.Key}' is duplicated.",
                nameof(entries));
        }

        var digestInput = string.Concat(
            ordered.Select(entry =>
                $"{entry.Kind.ToString().ToLowerInvariant()}\0{entry.RelativePath}\n"));
        var digest = Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(digestInput)))
            .ToLowerInvariant();

        return new GovernanceRepositorySnapshot(ordered, digest);
    }
}
