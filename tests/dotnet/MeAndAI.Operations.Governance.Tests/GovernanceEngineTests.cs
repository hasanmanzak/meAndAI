using System.Security.Cryptography;
using System.Text;
using MeAndAI.Operations.Domain.Governance;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Repository;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class GovernanceEngineTests
{
    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public void CompletePairIsConformingWithinTheBoundedShadowCatalog()
    {
        var report = GovernanceEngine.CreateDefault().Evaluate(
            new GovernanceRequest(GovernanceProfileId.ProtocolAuthority),
            Snapshot(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example"),
                GovernanceRepositoryEntry.File(
                    "docs/features/FEAT-0001-example/README.md"),
                GovernanceRepositoryEntry.File(
                    "docs/features/FEAT-0001-example/test-cases.md")));

        Assert.Same(GovernanceVerdict.Conforming, report.Verdict);
        Assert.Equal("csharp-shadow", report.EngineState);
        Assert.Equal("powershell-authority", report.AuthorityState);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(0, report.Counts.BlockingFindings);
        Assert.Empty(report.Findings);
    }

    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public void BlockingFindingIsNonconforming()
    {
        var report = GovernanceEngine.CreateDefault().Evaluate(
            new GovernanceRequest(GovernanceProfileId.ProtocolAuthority),
            Snapshot(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example")));

        Assert.Same(GovernanceVerdict.Nonconforming, report.Verdict);
        Assert.Equal(1, report.Counts.EvaluatedRules);
        Assert.Equal(1, report.Counts.BlockingFindings);
        Assert.Single(report.Findings);
    }

    [Fact]
    public void ReportBytesAreStableAcrossSnapshotInputOrder()
    {
        var entries = new[]
        {
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0002-zeta"),
            GovernanceRepositoryEntry.File(
                "docs/features/FEAT-0002-zeta/README.md"),
            GovernanceRepositoryEntry.Directory(
                "docs/features/FEAT-0001-alpha"),
        };
        var engine = GovernanceEngine.CreateDefault();
        var request = new GovernanceRequest(
            GovernanceProfileId.ProtocolAuthority);

        var first = GovernanceReportSerializer.Serialize(
            engine.Evaluate(request, Snapshot(entries)));
        var second = GovernanceReportSerializer.Serialize(
            engine.Evaluate(request, Snapshot(entries.Reverse().ToArray())));

        Assert.Equal(first, second);
        Assert.EndsWith("\n", first, StringComparison.Ordinal);
        Assert.DoesNotContain("\\", first, StringComparison.Ordinal);
    }

    [Fact]
    public void ReportDigestBindsExactSemanticPayloadWithoutTransportLf()
    {
        var report = GovernanceEngine.CreateDefault().Evaluate(
            new GovernanceRequest(GovernanceProfileId.ProtocolAuthority),
            Snapshot(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example")));
        var serialized = GovernanceReportSerializer.Serialize(report);
        const string digestMarker = ",\"reportDigest\":\"";
        var markerIndex = serialized.LastIndexOf(
            digestMarker,
            StringComparison.Ordinal);

        Assert.True(markerIndex > 0);
        var digestStart = markerIndex + digestMarker.Length;
        var actualDigest = serialized.Substring(digestStart, 64);
        var semanticPayload = serialized[..markerIndex] + "}";
        var expectedDigest = Convert.ToHexString(
                SHA256.HashData(Encoding.UTF8.GetBytes(semanticPayload)))
            .ToLowerInvariant();

        Assert.Equal(expectedDigest, actualDigest);
        Assert.Equal('}', serialized[^2]);
        Assert.Equal('\n', serialized[^1]);
    }

    [Theory]
    [InlineData("../escape")]
    [InlineData("docs//features")]
    [InlineData("C:/outside")]
    [InlineData("C:outside")]
    [InlineData("/outside")]
    public void UnsafeRepositoryRelativeEntryIsRejected(string path)
    {
        Assert.Throws<ArgumentException>(() =>
            GovernanceRepositoryEntry.File(path));
    }

    private static GovernanceRepositorySnapshot Snapshot(
        params GovernanceRepositoryEntry[] entries) =>
        GovernanceRepositorySnapshot.CreateCandidate(entries);
}
