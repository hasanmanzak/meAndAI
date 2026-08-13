using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;

namespace MeAndAI.Protocol.Policy.Indexes;

internal sealed class PolicyIndexInput : IComponentInput
{
    internal PolicyIndexInput(TypedInputReader reader) =>
        Reader = reader ?? throw new ArgumentNullException(nameof(reader));

    internal TypedInputReader Reader { get; }
}

internal sealed class RepositoryTreeIndex(
    ModelTypeToken<RepositoryTreeModel> inputModel) :
    IContextIndexer<PolicyIndexInput, IRepositoryTree>
{
    private readonly ModelTypeToken<RepositoryTreeModel> _inputModel =
        inputModel ?? throw new ArgumentNullException(nameof(inputModel));

    public CapabilityIntent<IRepositoryTree> Build(
        ContextIndexInput<PolicyIndexInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var model = input.Value.Reader.RequireModel(_inputModel);
        var entries = model.Value.Entries.Select(entry => RepositoryEntryView.Create(
            entry.RepositoryRelativePath,
            entry.Kind,
            input.Derivations.Derive(
                model.Evidence,
                "repository-entry",
                entry.RepositoryRelativePath,
                model.Value.Binding.Location))).ToArray();
        return CapabilityIntent<IRepositoryTree>.Produced(
            CapabilityProduct<IRepositoryTree>.Create(
                new RepositoryTreeCapability(entries),
                entries.Select(entry => entry.Evidence),
                Usage(entries.Length)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        ContextIndexInput<PolicyIndexInput> input,
        IRepositoryTree value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value.Entries.Count);
    }

    private static SemanticResourceLocalUsage Usage(int nodes) =>
        SemanticResourceLocalUsage.Create(
            generatedBytes: 0,
            layerDepth: nodes == 0 ? 0 : 1,
            layerNodes: nodes,
            additionalComplexity: nodes);
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
