using System.Collections.ObjectModel;
using System.Buffers.Binary;
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

        var digest = ComputeEvidenceDigest(ordered);

        return new GovernanceRepositorySnapshot(ordered, digest);
    }

    private static string ComputeEvidenceDigest(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        using var evidence = IncrementalHash.CreateHash(
            HashAlgorithmName.SHA256);
        AppendFramed(
            evidence,
            "meandai-governance-repository-snapshot-v2"u8);

        foreach (var entry in entries)
        {
            Span<byte> kind = [(byte)entry.Kind];
            AppendFramed(evidence, kind);
            AppendFramed(
                evidence,
                Encoding.UTF8.GetBytes(entry.RelativePath));
            AppendFramed(evidence, entry.CapturedContent);
        }

        return Convert.ToHexString(evidence.GetHashAndReset())
            .ToLowerInvariant();
    }

    private static void AppendFramed(
        IncrementalHash evidence,
        ReadOnlySpan<byte> value)
    {
        Span<byte> length = stackalloc byte[sizeof(int)];
        BinaryPrimitives.WriteInt32BigEndian(length, value.Length);
        evidence.AppendData(length);
        evidence.AppendData(value);
    }
}
