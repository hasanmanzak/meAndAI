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
        Assert.Equal(CurrentGraph(), policy.InstructionGraph);
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
            Graph(schema: 3),
            Graph(maximumTreeEntries: 65535),
            Graph(maximumAggregateTreePathUtf8Bytes: 4194303),
            Graph(maximumNodes: 511),
            Graph(maximumEdges: 4095),
            Graph(maximumDepth: 31),
            Graph(maximumParsedBlobBytes: 524287),
            Graph(maximumAggregateParsedBytes: 4194303),
            Graph(maximumGraphPathUtf8Bytes: 32767),
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

    private static InstructionGraphPolicyIdentity CurrentGraph() => Graph();

    private static InstructionGraphPolicyIdentity Graph(
        int schema = 2,
        int maximumTreeEntries = 65536,
        int maximumAggregateTreePathUtf8Bytes = 4194304,
        int maximumNodes = 512,
        int maximumEdges = 4096,
        int maximumDepth = 32,
        int maximumParsedBlobBytes = 524288,
        int maximumAggregateParsedBytes = 4194304,
        int maximumGraphPathUtf8Bytes = 32768) =>
        InstructionGraphPolicyIdentity.Create(
            schema,
            maximumTreeEntries,
            maximumAggregateTreePathUtf8Bytes,
            maximumNodes,
            maximumEdges,
            maximumDepth,
            maximumParsedBlobBytes,
            maximumAggregateParsedBytes,
            maximumGraphPathUtf8Bytes);
}
