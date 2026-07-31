namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class SemanticResourceBudget
{
    private SemanticResourceBudget(
        long maxBytes,
        int maxDepth,
        long maxNodes,
        long maxComplexity)
    {
        MaxBytes = maxBytes;
        MaxDepth = maxDepth;
        MaxNodes = maxNodes;
        MaxComplexity = maxComplexity;
    }

    public long MaxBytes { get; }

    public int MaxDepth { get; }

    public long MaxNodes { get; }

    public long MaxComplexity { get; }

    public static SemanticResourceBudget Create(
        long maxBytes,
        int maxDepth,
        long maxNodes,
        long maxComplexity)
    {
        DeclarationValidation.Positive(maxBytes, nameof(maxBytes));
        DeclarationValidation.Positive(maxDepth, nameof(maxDepth));
        DeclarationValidation.Positive(maxNodes, nameof(maxNodes));
        DeclarationValidation.Positive(maxComplexity, nameof(maxComplexity));

        return new SemanticResourceBudget(
            maxBytes,
            maxDepth,
            maxNodes,
            maxComplexity);
    }
}
