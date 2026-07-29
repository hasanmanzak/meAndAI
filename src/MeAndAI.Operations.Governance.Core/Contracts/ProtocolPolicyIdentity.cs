using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Domain.Protocol;
using MeAndAI.Operations.Governance.Core.Rules;

namespace MeAndAI.Operations.Governance.Core.Contracts;

public sealed class ProtocolPolicyIdentity
{
    private ProtocolPolicyIdentity(
        ProtocolVersion version,
        ExactGitCommitId sourceCommit,
        GovernanceCatalogIdentity catalog,
        InstructionGraphPolicyIdentity instructionGraph)
    {
        Version = version;
        SourceCommit = sourceCommit;
        Catalog = catalog;
        InstructionGraph = instructionGraph;
    }

    public ProtocolVersion Version { get; }

    public ExactGitCommitId SourceCommit { get; }

    public GovernanceCatalogIdentity Catalog { get; }

    public InstructionGraphPolicyIdentity InstructionGraph { get; }

    internal static ProtocolPolicyIdentity CreateBounded(
        ProtocolVersion version,
        ExactGitCommitId sourceCommit,
        GovernanceCatalogIdentity catalog,
        InstructionGraphPolicyIdentity instructionGraph)
    {
        ArgumentNullException.ThrowIfNull(version);
        ArgumentNullException.ThrowIfNull(sourceCommit);
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(instructionGraph);

        if (version != BoundedGovernanceContract.Version ||
            !IsCurrentCatalog(catalog) ||
            !IsCurrentInstructionGraph(instructionGraph))
        {
            throw new ArgumentException(
                $"The protocol policy identity is outside the bounded v{BoundedGovernanceContract.Version.Value} contract.");
        }

        return new ProtocolPolicyIdentity(
            version,
            sourceCommit,
            catalog,
            instructionGraph);
    }

    private static bool IsCurrentCatalog(GovernanceCatalogIdentity catalog)
    {
        var current = GovernanceRuleCatalog.Current.Identity;

        return catalog.Schema == current.Schema &&
            catalog.MetadataDigest == current.MetadataDigest &&
            catalog.Rules.SequenceEqual(current.Rules);
    }

    private static bool IsCurrentInstructionGraph(
        InstructionGraphPolicyIdentity graph) =>
        graph.Schema == 2 &&
        graph.MaximumTreeEntries == 65536 &&
        graph.MaximumAggregateTreePathUtf8Bytes == 4194304 &&
        graph.MaximumNodes == 512 &&
        graph.MaximumEdges == 4096 &&
        graph.MaximumDepth == 32 &&
        graph.MaximumParsedBlobBytes == 524288 &&
        graph.MaximumAggregateParsedBytes == 4194304 &&
        graph.MaximumGraphPathUtf8Bytes == 32768;
}
