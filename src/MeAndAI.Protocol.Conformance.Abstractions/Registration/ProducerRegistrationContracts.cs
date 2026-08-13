namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IComponentInput;

internal interface IComponentInputBinder<TInput>
    where TInput : class, IComponentInput
{
    IReadOnlyList<ComponentInputDeclaration> Inputs =>
        Array.Empty<ComponentInputDeclaration>();

    TInput Bind(TypedInputReader reader) =>
        throw new NotSupportedException("The registered binder does not implement binding.");
}

internal interface ISemanticModelParser<TInput, TOutput> :
    ISemanticResourceMeter<SemanticModelInput<TInput>, TOutput>
    where TInput : class, IComponentInput
    where TOutput : class, IProtocolSemanticModel
{
    SemanticModelIntent<TOutput> Parse(
        SemanticModelInput<TInput> input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered parser does not implement parsing.");

    SemanticResourceLocalUsage ISemanticResourceMeter<SemanticModelInput<TInput>, TOutput>.MeasureLocal(
        SemanticModelInput<TInput> input,
        TOutput value,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered parser does not implement resource metering.");
}

internal interface IContextIndexer<TInput, TCapability> :
    ISemanticResourceMeter<ContextIndexInput<TInput>, TCapability>
    where TInput : class, IComponentInput
    where TCapability : class, IEvidenceCapability
{
    CapabilityIntent<TCapability> Build(
        ContextIndexInput<TInput> input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered indexer does not implement indexing.");

    SemanticResourceLocalUsage ISemanticResourceMeter<ContextIndexInput<TInput>, TCapability>.MeasureLocal(
        ContextIndexInput<TInput> input,
        TCapability value,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered indexer does not implement resource metering.");
}

internal interface IAcquisitionDemandProjector<TCapability> :
    ISemanticResourceMeter<
        DemandProjectionInput<TCapability>,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>
    where TCapability : class, IEvidenceCapability
{
    DemandProjectionIntent Project(
        DemandProjectionInput<TCapability> input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered projector does not implement projection.");

    SemanticResourceLocalUsage ISemanticResourceMeter<
        DemandProjectionInput<TCapability>,
        IReadOnlyList<RepositoryTargetResolutionDemandCandidate>>.MeasureLocal(
            DemandProjectionInput<TCapability> input,
            IReadOnlyList<RepositoryTargetResolutionDemandCandidate> value,
            CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered projector does not implement resource metering.");
}

internal interface IExpectedSelectorResolver
{
    SelectorIntent Resolve(ExpectedSelectorInput input) =>
        throw new NotSupportedException("The registered selector does not implement resolution.");
}

internal interface IRuleInputAccess
{
    TCapability GetCapability<TCapability>(string slotKey)
        where TCapability : class, IEvidenceCapability;

    QualifiedEvidenceHandle GetContextProof(string slotKey);

    QualifiedEvidenceHandle GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle);
}

internal sealed class CapabilityTypeToken<TCapability>
    where TCapability : class, IEvidenceCapability
{
    private CapabilityTypeToken(CapabilityContractIdentity contract) =>
        Contract = contract;

    internal CapabilityContractIdentity Contract { get; }

    internal static CapabilityTypeToken<TCapability> Create(
        CapabilityContractIdentity contract)
    {
        ArgumentNullException.ThrowIfNull(contract);
        return new CapabilityTypeToken<TCapability>(contract);
    }
}
