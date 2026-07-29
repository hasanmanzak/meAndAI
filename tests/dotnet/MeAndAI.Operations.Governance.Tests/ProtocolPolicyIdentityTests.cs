using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Protocol;
using MeAndAI.Operations.Governance.Core.Contracts;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Tests;

public sealed class ProtocolPolicyIdentityTests
{
    private static readonly ExactGitCommitId PolicyCommit =
        ExactGitCommitId.Parse(
            "0123456789abcdef0123456789abcdef01234567");

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void ExactBoundedPolicyIdentityIsAccepted()
    {
        var policy = ProtocolPolicyIdentity.CreateBounded(
            ProtocolVersion.Parse("0.17.0"),
            PolicyCommit,
            GovernanceRuleCatalog.Current.Identity,
            CurrentGraph());

        Assert.Equal("0.17.0", policy.Version.Value);
        Assert.Same(PolicyCommit, policy.SourceCommit);
        Assert.Same(GovernanceRuleCatalog.Current.Identity, policy.Catalog);
        Assert.Same(
            BoundedGovernanceContract.InstructionGraph,
            policy.InstructionGraph);
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void AnotherCanonicalVersionWithCurrentLimitsIsRejected()
    {
        Assert.Throws<ArgumentException>(() =>
            ProtocolPolicyIdentity.CreateBounded(
                ProtocolVersion.Parse("0.16.0"),
                PolicyCommit,
                GovernanceRuleCatalog.Current.Identity,
                CurrentGraph()));
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void CurrentVersionWithAnyChangedGraphLimitIsRejected()
    {
        var invalidGraphs = new[]
        {
            Graph(schema: CurrentGraph().Schema + 1),
            Graph(maximumTreeEntries: CurrentGraph().MaximumTreeEntries - 1),
            Graph(
                maximumAggregateTreePathUtf8Bytes:
                    CurrentGraph().MaximumAggregateTreePathUtf8Bytes - 1),
            Graph(maximumNodes: CurrentGraph().MaximumNodes - 1),
            Graph(maximumEdges: CurrentGraph().MaximumEdges - 1),
            Graph(maximumDepth: CurrentGraph().MaximumDepth - 1),
            Graph(
                maximumParsedBlobBytes:
                    CurrentGraph().MaximumParsedBlobBytes - 1),
            Graph(
                maximumAggregateParsedBytes:
                    CurrentGraph().MaximumAggregateParsedBytes - 1),
            Graph(
                maximumGraphPathUtf8Bytes:
                    CurrentGraph().MaximumGraphPathUtf8Bytes - 1),
        };

        foreach (var graph in invalidGraphs)
        {
            Assert.Throws<ArgumentException>(() =>
                ProtocolPolicyIdentity.CreateBounded(
                    ProtocolVersion.Parse("0.17.0"),
                    PolicyCommit,
                    GovernanceRuleCatalog.Current.Identity,
                    graph));
        }
    }

    [Fact]
    [Trait("Scenario", "TEST-0194")]
    public void PolicyIdentityRejectsNullCompositionParts()
    {
        Assert.Throws<ArgumentNullException>(() =>
            ProtocolPolicyIdentity.CreateBounded(
                null!,
                PolicyCommit,
                GovernanceRuleCatalog.Current.Identity,
                CurrentGraph()));
        Assert.Throws<ArgumentNullException>(() =>
            ProtocolPolicyIdentity.CreateBounded(
                ProtocolVersion.Parse("0.17.0"),
                null!,
                GovernanceRuleCatalog.Current.Identity,
                CurrentGraph()));
        Assert.Throws<ArgumentNullException>(() =>
            ProtocolPolicyIdentity.CreateBounded(
                ProtocolVersion.Parse("0.17.0"),
                PolicyCommit,
                null!,
                CurrentGraph()));
        Assert.Throws<ArgumentNullException>(() =>
            ProtocolPolicyIdentity.CreateBounded(
                ProtocolVersion.Parse("0.17.0"),
                PolicyCommit,
                GovernanceRuleCatalog.Current.Identity,
                null!));
    }

    private static InstructionGraphPolicyIdentity CurrentGraph() =>
        BoundedGovernanceContract.InstructionGraph;

    private static InstructionGraphPolicyIdentity Graph(
        int? schema = null,
        int? maximumTreeEntries = null,
        int? maximumAggregateTreePathUtf8Bytes = null,
        int? maximumNodes = null,
        int? maximumEdges = null,
        int? maximumDepth = null,
        int? maximumParsedBlobBytes = null,
        int? maximumAggregateParsedBytes = null,
        int? maximumGraphPathUtf8Bytes = null)
    {
        var current = CurrentGraph();
        return InstructionGraphPolicyIdentity.Create(
            schema ?? current.Schema,
            maximumTreeEntries ?? current.MaximumTreeEntries,
            maximumAggregateTreePathUtf8Bytes ??
                current.MaximumAggregateTreePathUtf8Bytes,
            maximumNodes ?? current.MaximumNodes,
            maximumEdges ?? current.MaximumEdges,
            maximumDepth ?? current.MaximumDepth,
            maximumParsedBlobBytes ?? current.MaximumParsedBlobBytes,
            maximumAggregateParsedBytes ?? current.MaximumAggregateParsedBytes,
            maximumGraphPathUtf8Bytes ?? current.MaximumGraphPathUtf8Bytes);
    }
}
