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
        var report = GovernanceEngine.CreateDefault().EvaluateCandidateShadow(
            GovernanceProfileId.ProtocolAuthority,
            Snapshot(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example"),
                GovernanceRepositoryEntry.File(
                    "docs/features/FEAT-0001-example/README.md"),
                GovernanceRepositoryEntry.File(
                    "docs/features/FEAT-0001-example/test-cases.md")));

        Assert.Same(GovernanceVerdict.Conforming, report.Verdict);
        Assert.Equal("csharp-shadow", report.EngineState.Value);
        Assert.Equal("powershell-authority", report.AuthorityState.Value);
        Assert.Equal("bounded-catalog", report.Coverage);
        Assert.Equal(
            [
                "protocol.decision-record.required-structure.v1",
                "protocol.feature-record.required-pair.v1",
            ],
            report.EvaluatedRuleIds);
        Assert.Equal(2, report.Counts.EvaluatedRules);
        Assert.Equal(0, report.Counts.MissingRules);
        Assert.Equal(0, report.Counts.UnmappedRules);
        Assert.Equal(0, report.Counts.BlockingFindings);
        Assert.Empty(report.Findings);
    }

    [Fact]
    [Trait("Scenario", "TEST-0004")]
    public void BlockingFindingIsNonconforming()
    {
        var report = GovernanceEngine.CreateDefault().EvaluateCandidateShadow(
            GovernanceProfileId.ProtocolAuthority,
            Snapshot(
                GovernanceRepositoryEntry.Directory(
                    "docs/features/FEAT-0001-example")));

        Assert.Same(GovernanceVerdict.Nonconforming, report.Verdict);
        Assert.Equal(2, report.Counts.EvaluatedRules);
        Assert.Equal(0, report.Counts.MissingRules);
        Assert.Equal(0, report.Counts.UnmappedRules);
        Assert.Equal(1, report.Counts.BlockingFindings);
        Assert.Single(report.Findings);
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
