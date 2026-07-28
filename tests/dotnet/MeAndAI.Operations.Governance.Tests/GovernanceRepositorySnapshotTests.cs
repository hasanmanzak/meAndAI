using System.Text;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceRepositorySnapshotTests
{
    [Fact]
    public void FileEntryDefensivelyCopiesCapturedContent()
    {
        var source = Encoding.UTF8.GetBytes("original content\n");

        var entry = GovernanceRepositoryEntry.File(
            "docs/decisions/DEC-0001-example.md",
            source);
        source.AsSpan().Fill((byte)'x');

        Assert.Equal(
            "original content\n",
            Encoding.UTF8.GetString(entry.Content.Span));
    }

    [Fact]
    public void ContentOnlyChangeChangesSnapshotEvidenceDigest()
    {
        const string path = "docs/decisions/DEC-0001-example.md";
        var first = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, "first\n"));
        var second = GovernanceTestRepository.Candidate(
            GovernanceTestRepository.MarkdownFile(path, "second\n"));

        Assert.NotEqual(first.EvidenceDigest, second.EvidenceDigest);
    }

    [Fact]
    public void SnapshotContentCannotBeChangedThroughTheSourceBuffer()
    {
        var source = Encoding.UTF8.GetBytes("captured\n");
        var snapshot = GovernanceTestRepository.Candidate(
            GovernanceRepositoryEntry.File(
                "docs/decisions/DEC-0001-example.md",
                source));

        source.AsSpan().Clear();

        var captured = Assert.Single(snapshot.Entries);
        Assert.Equal(
            "captured\n",
            Encoding.UTF8.GetString(captured.Content.Span));
    }
}
