using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;

namespace MeAndAI.Protocol.Policy.Indexes;

internal sealed class PolicyIndexInput : IComponentInput
{
    internal PolicyIndexInput(TypedInputReader reader) =>
        Reader = reader ?? throw new ArgumentNullException(nameof(reader));

    internal TypedInputReader Reader { get; }
}

internal sealed class RepositoryTreeIndex :
    PolicyIndexer<IRepositoryTree>,
    IContextIndexer<PolicyIndexInput, IRepositoryTree>
{
    protected override IRepositoryTree CreateValue() =>
        new RepositoryTreeCapability([]);
}

internal sealed class ProtocolRecordIndex :
    PolicyIndexer<IProtocolRecordIndex>,
    IContextIndexer<PolicyIndexInput, IProtocolRecordIndex>
{
    protected override IProtocolRecordIndex CreateValue() =>
        new ProtocolRecordCapability([]);
}

internal sealed class GovernedReferenceIndex :
    PolicyIndexer<IGovernedReferenceIndex>,
    IContextIndexer<PolicyIndexInput, IGovernedReferenceIndex>
{
    protected override IGovernedReferenceIndex CreateValue() =>
        new GovernedReferenceCapability([]);
}

internal sealed class RepositoryTargetResolutionIndex :
    PolicyIndexer<IRepositoryTargetResolutionIndex>,
    IContextIndexer<PolicyIndexInput, IRepositoryTargetResolutionIndex>
{
    protected override IRepositoryTargetResolutionIndex CreateValue() =>
        new RepositoryTargetResolutionCapability([]);
}

internal abstract class PolicyIndexer<TCapability>
    where TCapability : class, IEvidenceCapability
{
    protected abstract TCapability CreateValue();

    public CapabilityIntent<TCapability> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var value = CreateValue();
        return CapabilityIntent<TCapability>.Produced(
            CapabilityProduct<TCapability>.Create(
                value,
                [],
                Usage(value)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        TCapability value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value);
    }

    private static SemanticResourceLocalUsage Usage(TCapability value)
    {
        var nodes = value switch
        {
            IRepositoryTree tree => tree.Entries.Count,
            IProtocolRecordIndex records => records.Records.Count,
            IGovernedReferenceIndex references => references.References.Count,
            IRepositoryTargetResolutionIndex targets => targets.Targets.Count,
            _ => 0,
        };
        return SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: nodes == 0 ? 0 : 1,
            layerNodes: nodes,
            additionalComplexity: nodes);
    }
}
