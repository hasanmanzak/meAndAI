namespace MeAndAI.Operations.Domain.Protocol;

public sealed record InstructionGraphPolicyIdentity
{
    private InstructionGraphPolicyIdentity(
        int schema,
        int maximumTreeEntries,
        int maximumAggregateTreePathUtf8Bytes,
        int maximumNodes,
        int maximumEdges,
        int maximumDepth,
        int maximumParsedBlobBytes,
        int maximumAggregateParsedBytes,
        int maximumGraphPathUtf8Bytes)
    {
        Schema = schema;
        MaximumTreeEntries = maximumTreeEntries;
        MaximumAggregateTreePathUtf8Bytes =
            maximumAggregateTreePathUtf8Bytes;
        MaximumNodes = maximumNodes;
        MaximumEdges = maximumEdges;
        MaximumDepth = maximumDepth;
        MaximumParsedBlobBytes = maximumParsedBlobBytes;
        MaximumAggregateParsedBytes = maximumAggregateParsedBytes;
        MaximumGraphPathUtf8Bytes = maximumGraphPathUtf8Bytes;
    }

    public int Schema { get; }

    public int MaximumTreeEntries { get; }

    public int MaximumAggregateTreePathUtf8Bytes { get; }

    public int MaximumNodes { get; }

    public int MaximumEdges { get; }

    public int MaximumDepth { get; }

    public int MaximumParsedBlobBytes { get; }

    public int MaximumAggregateParsedBytes { get; }

    public int MaximumGraphPathUtf8Bytes { get; }

    public static InstructionGraphPolicyIdentity Create(
        int schema,
        int maximumTreeEntries,
        int maximumAggregateTreePathUtf8Bytes,
        int maximumNodes,
        int maximumEdges,
        int maximumDepth,
        int maximumParsedBlobBytes,
        int maximumAggregateParsedBytes,
        int maximumGraphPathUtf8Bytes)
    {
        ThrowIfNotPositive(schema, nameof(schema));
        ThrowIfNotPositive(maximumTreeEntries, nameof(maximumTreeEntries));
        ThrowIfNotPositive(
            maximumAggregateTreePathUtf8Bytes,
            nameof(maximumAggregateTreePathUtf8Bytes));
        ThrowIfNotPositive(maximumNodes, nameof(maximumNodes));
        ThrowIfNotPositive(maximumEdges, nameof(maximumEdges));
        ThrowIfNotPositive(maximumDepth, nameof(maximumDepth));
        ThrowIfNotPositive(
            maximumParsedBlobBytes,
            nameof(maximumParsedBlobBytes));
        ThrowIfNotPositive(
            maximumAggregateParsedBytes,
            nameof(maximumAggregateParsedBytes));
        ThrowIfNotPositive(
            maximumGraphPathUtf8Bytes,
            nameof(maximumGraphPathUtf8Bytes));

        return new InstructionGraphPolicyIdentity(
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

    private static void ThrowIfNotPositive(int value, string parameterName)
    {
        if (value <= 0)
        {
            throw new ArgumentOutOfRangeException(
                parameterName,
                value,
                "Instruction-graph limits and schema identities must be positive.");
        }
    }
}
