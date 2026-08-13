using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal sealed class SemanticResourceUsage
{
    private SemanticResourceUsage(
        long bytes,
        int maxDepth,
        long nodes,
        long complexity)
    {
        Bytes = bytes;
        MaxDepth = maxDepth;
        Nodes = nodes;
        Complexity = complexity;
    }

    internal long Bytes { get; }
    internal int MaxDepth { get; }
    internal long Nodes { get; }
    internal long Complexity { get; }

    internal static SemanticResourceUsage Create(
        long bytes,
        int maxDepth,
        long nodes,
        long complexity)
    {
        RequireNonNegative(bytes, nameof(bytes));
        RequireNonNegative(maxDepth, nameof(maxDepth));
        RequireNonNegative(nodes, nameof(nodes));
        RequireNonNegative(complexity, nameof(complexity));
        return new SemanticResourceUsage(bytes, maxDepth, nodes, complexity);
    }

    internal bool Fits(SemanticResourceBudget budget)
    {
        ArgumentNullException.ThrowIfNull(budget);
        return Bytes <= budget.MaxBytes &&
            MaxDepth <= budget.MaxDepth &&
            Nodes <= budget.MaxNodes &&
            Complexity <= budget.MaxComplexity;
    }

    private static void RequireNonNegative(long value, string name)
    {
        if (value < 0)
        {
            throw new ArgumentOutOfRangeException(name);
        }
    }
}

internal sealed class SemanticResourceLocalUsage
{
    private SemanticResourceLocalUsage(
        long generatedBytes,
        int layerDepth,
        long layerNodes,
        long additionalComplexity)
    {
        GeneratedBytes = generatedBytes;
        LayerDepth = layerDepth;
        LayerNodes = layerNodes;
        AdditionalComplexity = additionalComplexity;
    }

    internal long GeneratedBytes { get; }
    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal long AdditionalComplexity { get; }

    internal static SemanticResourceLocalUsage Create(
        long generatedBytes,
        int layerDepth,
        long layerNodes,
        long additionalComplexity)
    {
        if (generatedBytes < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(generatedBytes));
        }

        if (layerDepth < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(layerDepth));
        }

        if (layerNodes < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(layerNodes));
        }

        if (additionalComplexity < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(additionalComplexity));
        }

        if ((layerDepth == 0) != (layerNodes == 0))
        {
            throw new ArgumentException(
                "Layer depth and nodes must both be zero or both be positive.");
        }

        return new SemanticResourceLocalUsage(
            generatedBytes,
            layerDepth,
            layerNodes,
            additionalComplexity);
    }
}

internal sealed class SemanticResourceAllowance
{
    private SemanticResourceAllowance(
        SemanticResourceBudget aggregateBudget,
        SemanticResourceUsage selectedBaseline)
    {
        AggregateBudget = aggregateBudget;
        SelectedBaseline = selectedBaseline;
    }

    internal SemanticResourceBudget AggregateBudget { get; }
    internal SemanticResourceUsage SelectedBaseline { get; }

    internal static SemanticResourceAllowance Create(
        SemanticResourceBudget aggregateBudget,
        SemanticResourceUsage selectedBaseline)
    {
        ArgumentNullException.ThrowIfNull(aggregateBudget);
        ArgumentNullException.ThrowIfNull(selectedBaseline);
        return new SemanticResourceAllowance(aggregateBudget, selectedBaseline);
    }

    internal bool FitsLocal(SemanticResourceLocalUsage localUsage)
    {
        ArgumentNullException.ThrowIfNull(localUsage);
        try
        {
            return checked(SelectedBaseline.Bytes + localUsage.GeneratedBytes) <=
                    AggregateBudget.MaxBytes &&
                Math.Max(SelectedBaseline.MaxDepth, localUsage.LayerDepth) <=
                    AggregateBudget.MaxDepth &&
                checked(SelectedBaseline.Nodes + localUsage.LayerNodes) <=
                    AggregateBudget.MaxNodes &&
                checked(SelectedBaseline.Complexity + localUsage.GeneratedBytes +
                    localUsage.LayerNodes + localUsage.AdditionalComplexity) <=
                    AggregateBudget.MaxComplexity;
        }
        catch (OverflowException)
        {
            return false;
        }
    }
}

internal sealed class SemanticResourceContribution
{
    private SemanticResourceContribution(
        int kindRank,
        IReadOnlyList<QualifiedEvidenceHandle> roots,
        string? payloadSchemaKey,
        string? payloadSchemaVersion,
        ComponentTypeIdentity? component,
        ExactSha256Digest? invocationDigest,
        SemanticResourceUsage usage)
    {
        KindRank = kindRank;
        Roots = roots;
        PayloadSchemaKey = payloadSchemaKey;
        PayloadSchemaVersion = payloadSchemaVersion;
        Component = component;
        InvocationDigest = invocationDigest;
        Usage = usage;
    }

    internal int KindRank { get; }
    internal IReadOnlyList<QualifiedEvidenceHandle> Roots { get; }
    internal string? PayloadSchemaKey { get; }
    internal string? PayloadSchemaVersion { get; }
    internal ComponentTypeIdentity? Component { get; }
    internal ExactSha256Digest? InvocationDigest { get; }
    internal SemanticResourceUsage Usage { get; }

    internal static SemanticResourceContribution Payload(
        QualifiedEvidenceHandle root,
        string payloadSchemaKey,
        string payloadSchemaVersion,
        SemanticResourceUsage usage) =>
        new(
            0,
            Snapshot([root ?? throw new ArgumentNullException(nameof(root))], nameof(root)),
            Token(payloadSchemaKey, nameof(payloadSchemaKey)),
            Token(payloadSchemaVersion, nameof(payloadSchemaVersion)),
            null,
            null,
            usage ?? throw new ArgumentNullException(nameof(usage)));

    internal static SemanticResourceContribution GeneratedBytes(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage) =>
        Producer(1, roots, component, invocationDigest, usage);

    internal static SemanticResourceContribution Layer(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage) =>
        Producer(2, roots, component, invocationDigest, usage);

    internal static SemanticResourceContribution ComplexityTerm(
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage) =>
        Producer(3, roots, component, invocationDigest, usage);

    private static SemanticResourceContribution Producer(
        int rank,
        IEnumerable<QualifiedEvidenceHandle> roots,
        ComponentTypeIdentity component,
        ExactSha256Digest invocationDigest,
        SemanticResourceUsage usage) =>
        new(
            rank,
            Snapshot(roots, nameof(roots)),
            null,
            null,
            component ?? throw new ArgumentNullException(nameof(component)),
            invocationDigest ?? throw new ArgumentNullException(nameof(invocationDigest)),
            usage ?? throw new ArgumentNullException(nameof(usage)));

    private static IReadOnlyList<QualifiedEvidenceHandle> Snapshot(
        IEnumerable<QualifiedEvidenceHandle>? roots,
        string parameterName)
    {
        ArgumentNullException.ThrowIfNull(roots, parameterName);
        var values = roots.ToArray();
        if (values.Any(value => value is null))
        {
            throw new ArgumentException("The collection contains null.", parameterName);
        }

        return Array.AsReadOnly(values);
    }

    private static string Token(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;
}

internal sealed class SemanticResourceLedger
{
    private SemanticResourceLedger(
        IReadOnlyList<SemanticResourceContribution> contributions,
        SemanticResourceUsage usage)
    {
        Contributions = contributions;
        Usage = usage;
    }

    internal IReadOnlyList<SemanticResourceContribution> Contributions { get; }
    internal SemanticResourceUsage Usage { get; }

    internal static SemanticResourceLedger Create(
        IEnumerable<SemanticResourceContribution> contributions)
    {
        ArgumentNullException.ThrowIfNull(contributions);
        var values = contributions.ToArray();
        if (values.Any(value => value is null))
        {
            throw new ArgumentException(
                "The collection contains null.",
                nameof(contributions));
        }

        var ordered = values
            .OrderBy(value => value.KindRank)
            .ThenBy(value => value.PayloadSchemaKey ?? value.Component!.ComponentKey,
                StringComparer.Ordinal)
            .ThenBy(value => value.PayloadSchemaVersion ?? value.Component!.ComponentVersion,
                StringComparer.Ordinal)
            .ToArray();

        long bytes = 0;
        var depth = 0;
        long nodes = 0;
        long additionalComplexity = 0;
        foreach (var value in ordered)
        {
            checked
            {
                if (value.KindRank is 0 or 1)
                {
                    bytes += value.Usage.Bytes;
                }
                else if (value.KindRank == 2)
                {
                    depth = Math.Max(depth, value.Usage.MaxDepth);
                    nodes += value.Usage.Nodes;
                }
                else if (value.KindRank == 3)
                {
                    additionalComplexity += value.Usage.Complexity;
                }
                else
                {
                    throw new ArgumentException(
                        "The contribution rank is invalid.",
                        nameof(contributions));
                }
            }
        }

        var usage = SemanticResourceUsage.Create(
            bytes,
            depth,
            nodes,
            checked(bytes + nodes + additionalComplexity));
        return new SemanticResourceLedger(Array.AsReadOnly(ordered), usage);
    }
}
