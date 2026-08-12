namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IComponentInput;

internal interface IComponentInputBinder<TInput>
    where TInput : class, IComponentInput;

internal interface ISemanticModelParser<TInput, TOutput>
    where TInput : class, IComponentInput
    where TOutput : class, IProtocolSemanticModel;

internal interface IContextIndexer<TInput, TCapability>
    where TInput : class, IComponentInput
    where TCapability : class, IEvidenceCapability;

internal interface IAcquisitionDemandProjector<TCapability>
    where TCapability : class, IEvidenceCapability;

internal interface IExpectedSelectorResolver;

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
