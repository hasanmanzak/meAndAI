using MeAndAI.Operations.Domain.Protocol;

namespace MeAndAI.Operations.Governance.Core.Repository;

internal sealed record ExactRepositoryAcquisitionLimits
{
    private ExactRepositoryAcquisitionLimits(
        int maximumTreeEntries,
        int maximumAggregateTreePathUtf8Bytes,
        int maximumPathUtf8Bytes,
        int maximumSelectedBlobBytes,
        int maximumAggregateSelectedBlobBytes)
    {
        MaximumTreeEntries = maximumTreeEntries;
        MaximumAggregateTreePathUtf8Bytes =
            maximumAggregateTreePathUtf8Bytes;
        MaximumPathUtf8Bytes = maximumPathUtf8Bytes;
        MaximumSelectedBlobBytes = maximumSelectedBlobBytes;
        MaximumAggregateSelectedBlobBytes =
            maximumAggregateSelectedBlobBytes;
    }

    internal int MaximumTreeEntries { get; }

    internal int MaximumAggregateTreePathUtf8Bytes { get; }

    internal int MaximumPathUtf8Bytes { get; }

    internal int MaximumSelectedBlobBytes { get; }

    internal int MaximumAggregateSelectedBlobBytes { get; }

    internal static ExactRepositoryAcquisitionLimits From(
        InstructionGraphPolicyIdentity instructionGraph)
    {
        ArgumentNullException.ThrowIfNull(instructionGraph);

        return new ExactRepositoryAcquisitionLimits(
            instructionGraph.MaximumTreeEntries,
            instructionGraph.MaximumAggregateTreePathUtf8Bytes,
            instructionGraph.MaximumGraphPathUtf8Bytes,
            instructionGraph.MaximumParsedBlobBytes,
            instructionGraph.MaximumAggregateParsedBytes);
    }
}
