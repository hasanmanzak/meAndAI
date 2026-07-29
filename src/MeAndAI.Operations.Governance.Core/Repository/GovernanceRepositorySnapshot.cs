using System.Collections.ObjectModel;
using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Repository;

public sealed class GovernanceRepositorySnapshot
{
    private const string CandidateMode = "candidate";

    private GovernanceRepositorySnapshot(
        GovernanceRepositoryEntry[] entries,
        string mode,
        ExactGitCommitId? subjectCommit,
        string digest)
    {
        Entries = new ReadOnlyCollection<GovernanceRepositoryEntry>(entries);
        Mode = mode;
        SubjectCommit = subjectCommit;
        EvidenceDigest = digest;
    }

    public string Mode { get; }

    public ExactGitCommitId? SubjectCommit { get; }

    public string EvidenceDigest { get; }

    public IReadOnlyList<GovernanceRepositoryEntry> Entries { get; }

    internal bool IsCandidate =>
        string.Equals(Mode, CandidateMode, StringComparison.Ordinal) &&
        SubjectCommit is null;

    internal bool IsExactCommit =>
        string.Equals(
            Mode,
            RepositorySnapshotMode.ExactCommit.Value,
            StringComparison.Ordinal) &&
        SubjectCommit is not null;

    internal static GovernanceRepositorySnapshot CreateCandidate(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        ArgumentNullException.ThrowIfNull(entries);

        var ordered = MaterializeEntries(entries);

        var digest = ComputeCandidateEvidenceDigest(ordered);

        return new GovernanceRepositorySnapshot(
            ordered,
            CandidateMode,
            subjectCommit: null,
            digest);
    }

    internal static GovernanceRepositorySnapshot CreateExact(
        ExactGitCommitId subjectCommit,
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        ArgumentNullException.ThrowIfNull(subjectCommit);
        ArgumentNullException.ThrowIfNull(entries);
        var ordered = MaterializeEntries(entries);
        var digest = ComputeExactEvidenceDigest(subjectCommit, ordered);

        return new GovernanceRepositorySnapshot(
            ordered,
            RepositorySnapshotMode.ExactCommit.Value,
            subjectCommit,
            digest);
    }

    private static GovernanceRepositoryEntry[] MaterializeEntries(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
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

        return ordered;
    }

    private static string ComputeCandidateEvidenceDigest(
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        using var evidence = IncrementalHash.CreateHash(
            HashAlgorithmName.SHA256);
        AppendFramed(
            evidence,
            "meandai-governance-repository-snapshot-v2"u8);

        AppendEntries(evidence, entries);

        return ExactSha256Digest
            .FromHashBytes(evidence.GetHashAndReset())
            .Value;
    }

    private static string ComputeExactEvidenceDigest(
        ExactGitCommitId subjectCommit,
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        using var evidence = IncrementalHash.CreateHash(
            HashAlgorithmName.SHA256);
        AppendFramed(
            evidence,
            "meandai-governance-exact-repository-snapshot-v1"u8);
        AppendFramed(
            evidence,
            Encoding.ASCII.GetBytes(subjectCommit.Value));
        AppendEntries(evidence, entries);

        return ExactSha256Digest
            .FromHashBytes(evidence.GetHashAndReset())
            .Value;
    }

    private static void AppendEntries(
        IncrementalHash evidence,
        IEnumerable<GovernanceRepositoryEntry> entries)
    {
        foreach (var entry in entries)
        {
            Span<byte> kind = [(byte)entry.Kind];
            AppendFramed(evidence, kind);
            AppendFramed(
                evidence,
                Encoding.UTF8.GetBytes(entry.RelativePath));
            AppendFramed(evidence, entry.CapturedContent);
        }
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
