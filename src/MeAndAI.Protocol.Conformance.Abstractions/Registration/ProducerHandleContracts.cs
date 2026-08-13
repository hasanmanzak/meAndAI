using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface ICodecModelHandle
{
    ModelContractIdentity Contract { get; }
    EvidenceBinding Binding { get; }
    ComponentTypeIdentity Producer { get; }
    ExactSha256Digest InstructionDigest { get; }
    ExactSha256Digest DemandDigest { get; }
    IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    TResult Accept<TResult>(ICodecModelHandleVisitor<TResult> visitor);
}

internal interface ICodecModelHandleVisitor<TResult>
{
    TResult Visit<TModel>(CodecModelHandle<TModel> handle)
        where TModel : class, IProtocolSemanticModel;
}

internal sealed class CodecModelHandle<TModel> : ICodecModelHandle
    where TModel : class, IProtocolSemanticModel
{
    private CodecModelHandle(
        ModelTypeToken<TModel> modelType,
        EvidenceBinding binding,
        ComponentTypeIdentity producer,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems,
        TModel value,
        SemanticResourceLocalUsage claimedLocalUsage)
    {
        ModelType = modelType;
        Contract = modelType.Contract;
        Binding = binding;
        Producer = producer;
        InstructionDigest = instructionDigest;
        DemandDigest = demandDigest;
        DemandItems = demandItems;
        Value = value;
        ClaimedLocalUsage = claimedLocalUsage;
    }

    public ModelContractIdentity Contract { get; }
    public EvidenceBinding Binding { get; }
    public ComponentTypeIdentity Producer { get; }
    public ExactSha256Digest InstructionDigest { get; }
    public ExactSha256Digest DemandDigest { get; }
    public IReadOnlyList<RepositoryTargetResolutionDemandItem> DemandItems { get; }
    public SemanticResourceLocalUsage ClaimedLocalUsage { get; }
    internal ModelTypeToken<TModel> ModelType { get; }
    internal TModel Value { get; }

    internal static CodecModelHandle<TModel> Create(
        ModelTypeToken<TModel> modelType,
        EvidenceBinding binding,
        ComponentTypeIdentity producer,
        ExactSha256Digest instructionDigest,
        ExactSha256Digest demandDigest,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        TModel value,
        SemanticResourceLocalUsage claimedLocalUsage)
    {
        ArgumentNullException.ThrowIfNull(modelType);
        ArgumentNullException.ThrowIfNull(binding);
        ArgumentNullException.ThrowIfNull(producer);
        ArgumentNullException.ThrowIfNull(instructionDigest);
        ArgumentNullException.ThrowIfNull(demandDigest);
        ArgumentNullException.ThrowIfNull(demandItems);
        ArgumentNullException.ThrowIfNull(value);
        ArgumentNullException.ThrowIfNull(claimedLocalUsage);
        var items = demandItems.ToArray();
        if (items.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(demandItems));
        }

        return new CodecModelHandle<TModel>(
            modelType,
            binding,
            producer,
            instructionDigest,
            demandDigest,
            Array.AsReadOnly(items),
            value,
            claimedLocalUsage);
    }

    public TResult Accept<TResult>(ICodecModelHandleVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}

internal interface IObservedQualificationProofState
{
    IReadOnlyList<ICodecModelHandle> QualifiedModels { get; }
}

internal interface ISealedModelHandle
{
    ModelContractIdentity Contract { get; }
    QualifiedEvidenceHandle Evidence { get; }
    SemanticResourceUsage Usage { get; }
    SemanticResourceLedger Ledger { get; }
}

internal sealed class SealedModelHandle<TModel> : ISealedModelHandle
    where TModel : class, IProtocolSemanticModel
{
    private SealedModelHandle(
        ModelTypeToken<TModel> modelType,
        QualifiedEvidenceHandle evidence,
        TModel value,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger)
    {
        ModelType = modelType;
        Contract = modelType.Contract;
        Evidence = evidence;
        Value = value;
        Usage = usage;
        Ledger = ledger;
    }

    public ModelContractIdentity Contract { get; }
    public QualifiedEvidenceHandle Evidence { get; }
    public SemanticResourceUsage Usage { get; }
    public SemanticResourceLedger Ledger { get; }
    internal ModelTypeToken<TModel> ModelType { get; }
    internal TModel Value { get; }

    internal static SealedModelHandle<TModel> Create(
        ModelTypeToken<TModel> modelType,
        QualifiedEvidenceHandle evidence,
        TModel value,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger)
    {
        ArgumentNullException.ThrowIfNull(modelType);
        ArgumentNullException.ThrowIfNull(evidence);
        ArgumentNullException.ThrowIfNull(value);
        ArgumentNullException.ThrowIfNull(usage);
        ArgumentNullException.ThrowIfNull(ledger);
        return new SealedModelHandle<TModel>(modelType, evidence, value, usage, ledger);
    }
}

internal interface ICapabilityHandle
{
    CapabilityContractIdentity Contract { get; }
    IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    SemanticResourceUsage Usage { get; }
    SemanticResourceLedger Ledger { get; }
}

internal sealed class CapabilityHandle<TCapability> : ICapabilityHandle
    where TCapability : class, IEvidenceCapability
{
    private CapabilityHandle(
        CapabilityTypeToken<TCapability> capabilityType,
        TCapability value,
        IReadOnlyList<QualifiedEvidenceHandle> evidence,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger)
    {
        CapabilityType = capabilityType;
        Contract = capabilityType.Contract;
        Value = value;
        Evidence = evidence;
        Usage = usage;
        Ledger = ledger;
    }

    public CapabilityContractIdentity Contract { get; }
    public IReadOnlyList<QualifiedEvidenceHandle> Evidence { get; }
    public SemanticResourceUsage Usage { get; }
    public SemanticResourceLedger Ledger { get; }
    internal CapabilityTypeToken<TCapability> CapabilityType { get; }
    internal TCapability Value { get; }

    internal static CapabilityHandle<TCapability> Create(
        CapabilityTypeToken<TCapability> capabilityType,
        TCapability value,
        IEnumerable<QualifiedEvidenceHandle> evidence,
        SemanticResourceUsage usage,
        SemanticResourceLedger ledger)
    {
        ArgumentNullException.ThrowIfNull(capabilityType);
        ArgumentNullException.ThrowIfNull(value);
        ArgumentNullException.ThrowIfNull(evidence);
        ArgumentNullException.ThrowIfNull(usage);
        ArgumentNullException.ThrowIfNull(ledger);
        var values = evidence.ToArray();
        if (values.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", nameof(evidence));
        }

        return new CapabilityHandle<TCapability>(
            capabilityType,
            value,
            Array.AsReadOnly(values),
            usage,
            ledger);
    }
}

internal interface IExpectedReferenceLookup
{
    QualifiedEvidenceHandle Require(
        string selectorKey,
        QualifiedEvidenceHandle parent);
}

internal sealed class DemandReferenceAuthorityBinding
{
    private DemandReferenceAuthorityBinding(
        int itemId,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity)
    {
        ItemId = itemId;
        SourceReference = sourceReference;
        SourceAuthority = sourceAuthority;
        CapturedSnapshotIdentity = capturedSnapshotIdentity;
        CapturedManifestRepositoryRelativePath = capturedManifestRepositoryRelativePath;
        CapturedManifestContentIdentity = capturedManifestContentIdentity;
    }

    internal int ItemId { get; }
    internal QualifiedEvidenceHandle SourceReference { get; }
    internal QualifiedEvidenceHandle SourceAuthority { get; }
    internal string? CapturedSnapshotIdentity { get; }
    internal string? CapturedManifestRepositoryRelativePath { get; }
    internal string? CapturedManifestContentIdentity { get; }

    internal static DemandReferenceAuthorityBinding Create(
        int itemId,
        QualifiedEvidenceHandle sourceReference,
        QualifiedEvidenceHandle sourceAuthority,
        string? capturedSnapshotIdentity,
        string? capturedManifestRepositoryRelativePath,
        string? capturedManifestContentIdentity)
    {
        if (itemId < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(itemId));
        }

        ArgumentNullException.ThrowIfNull(sourceReference);
        ArgumentNullException.ThrowIfNull(sourceAuthority);
        return new DemandReferenceAuthorityBinding(
            itemId,
            sourceReference,
            sourceAuthority,
            capturedSnapshotIdentity,
            capturedManifestRepositoryRelativePath,
            capturedManifestContentIdentity);
    }
}

internal sealed class TypedInputReader
{
    private readonly IReadOnlyList<ISealedModelHandle> _models;
    private readonly IReadOnlyList<ICapabilityHandle> _capabilities;
    private readonly IReadOnlyDictionary<string, QualifiedEvidenceHandle> _contextProofs;
    private readonly IExpectedReferenceLookup _expectedReferences;
    private readonly IReadOnlyList<RepositoryTargetResolutionDemandItem> _demandItems;
    private readonly IReadOnlyDictionary<int, DemandReferenceAuthorityBinding> _demandBindings;

    private TypedInputReader(
        IReadOnlyList<ISealedModelHandle> models,
        IReadOnlyList<ICapabilityHandle> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences,
        IReadOnlyList<RepositoryTargetResolutionDemandItem> demandItems,
        IReadOnlyDictionary<int, DemandReferenceAuthorityBinding> demandBindings)
    {
        _models = models;
        _capabilities = capabilities;
        _contextProofs = contextProofs;
        _expectedReferences = expectedReferences;
        _demandItems = demandItems;
        _demandBindings = demandBindings;
    }

    internal static TypedInputReader Create(
        IEnumerable<ISealedModelHandle> models,
        IEnumerable<ICapabilityHandle> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences,
        IEnumerable<RepositoryTargetResolutionDemandItem> demandItems,
        IEnumerable<DemandReferenceAuthorityBinding> demandBindings)
    {
        var modelValues = Snapshot(models, nameof(models));
        var capabilityValues = Snapshot(capabilities, nameof(capabilities));
        ArgumentNullException.ThrowIfNull(contextProofs);
        ArgumentNullException.ThrowIfNull(expectedReferences);
        var itemValues = Snapshot(demandItems, nameof(demandItems));
        var bindingValues = Snapshot(demandBindings, nameof(demandBindings));
        if (contextProofs.Any(item =>
                string.IsNullOrWhiteSpace(item.Key) || item.Value is null))
        {
            throw new ArgumentException("The context proof map is invalid.", nameof(contextProofs));
        }

        var byItem = bindingValues.ToDictionary(item => item.ItemId);
        return new TypedInputReader(
            modelValues,
            capabilityValues,
            new Dictionary<string, QualifiedEvidenceHandle>(contextProofs, StringComparer.Ordinal),
            expectedReferences,
            itemValues,
            byItem);
    }

    internal SealedModelHandle<TModel> RequireModel<TModel>(
        ModelTypeToken<TModel> expected)
        where TModel : class, IProtocolSemanticModel =>
        RequireModels(expected).Single();

    internal IReadOnlyList<SealedModelHandle<TModel>> RequireModels<TModel>(
        ModelTypeToken<TModel> expected)
        where TModel : class, IProtocolSemanticModel
    {
        ArgumentNullException.ThrowIfNull(expected);
        return Array.AsReadOnly(_models
            .OfType<SealedModelHandle<TModel>>()
            .Where(item => ReferenceEquals(item.Contract, expected.Contract))
            .ToArray());
    }

    internal CapabilityHandle<TCapability> RequireCapability<TCapability>(
        CapabilityTypeToken<TCapability> expected)
        where TCapability : class, IEvidenceCapability =>
        RequireCapabilities(expected).Single();

    internal IReadOnlyList<CapabilityHandle<TCapability>> RequireCapabilities<TCapability>(
        CapabilityTypeToken<TCapability> expected)
        where TCapability : class, IEvidenceCapability
    {
        ArgumentNullException.ThrowIfNull(expected);
        return Array.AsReadOnly(_capabilities
            .OfType<CapabilityHandle<TCapability>>()
            .Where(item => ReferenceEquals(item.Contract, expected.Contract))
            .ToArray());
    }

    internal QualifiedEvidenceHandle RequireContextProof(string slotKey) =>
        _contextProofs.TryGetValue(RequiredToken(slotKey, nameof(slotKey)), out var value)
            ? value
            : throw new InvalidOperationException("The requested context proof is unavailable.");

    internal QualifiedEvidenceHandle RequireExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parent)
    {
        ArgumentNullException.ThrowIfNull(parent);
        return _expectedReferences.Require(
            RequiredToken(selectorKey, nameof(selectorKey)),
            parent);
    }

    internal IReadOnlyList<RepositoryTargetResolutionDemandItem> RequireDemandItems() =>
        _demandItems;

    internal DemandReferenceAuthorityBinding RequireDemandBinding(int itemId) =>
        _demandBindings.TryGetValue(itemId, out var value)
            ? value
            : throw new InvalidOperationException("The requested demand binding is unavailable.");

    private static IReadOnlyList<T> Snapshot<T>(
        IEnumerable<T>? values,
        string parameterName) where T : class
    {
        ArgumentNullException.ThrowIfNull(values, parameterName);
        var snapshot = values.ToArray();
        if (snapshot.Any(item => item is null))
        {
            throw new ArgumentException("The collection contains null.", parameterName);
        }

        return Array.AsReadOnly(snapshot);
    }

    private static string RequiredToken(string value, string parameterName) =>
        string.IsNullOrWhiteSpace(value)
            ? throw new ArgumentException("A token is required.", parameterName)
            : value;
}

internal sealed class SlotCapabilityBinding
{
    private SlotCapabilityBinding(string slotKey, ICapabilityHandle capability)
    {
        SlotKey = slotKey;
        Capability = capability;
    }

    internal string SlotKey { get; }
    internal ICapabilityHandle Capability { get; }

    internal static SlotCapabilityBinding Create(
        string slotKey,
        ICapabilityHandle capability)
    {
        ArgumentNullException.ThrowIfNull(capability);
        return new SlotCapabilityBinding(
            string.IsNullOrWhiteSpace(slotKey)
                ? throw new ArgumentException("A slot key is required.", nameof(slotKey))
                : slotKey,
            capability);
    }
}

internal sealed class RuleInputAccess : IRuleInputAccess
{
    private readonly IReadOnlyDictionary<string, ICapabilityHandle> _capabilities;
    private readonly IReadOnlyDictionary<string, QualifiedEvidenceHandle> _contextProofs;
    private readonly IExpectedReferenceLookup _expectedReferences;

    private RuleInputAccess(
        IReadOnlyDictionary<string, ICapabilityHandle> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences)
    {
        _capabilities = capabilities;
        _contextProofs = contextProofs;
        _expectedReferences = expectedReferences;
    }

    internal static RuleInputAccess Create(
        IEnumerable<SlotCapabilityBinding> capabilities,
        IReadOnlyDictionary<string, QualifiedEvidenceHandle> contextProofs,
        IExpectedReferenceLookup expectedReferences)
    {
        ArgumentNullException.ThrowIfNull(capabilities);
        ArgumentNullException.ThrowIfNull(contextProofs);
        ArgumentNullException.ThrowIfNull(expectedReferences);
        var values = capabilities.ToArray();
        if (values.Any(item => item is null) ||
            values.Select(item => item.SlotKey).Distinct(StringComparer.Ordinal).Count() != values.Length)
        {
            throw new ArgumentException("Capability bindings are invalid.", nameof(capabilities));
        }

        return new RuleInputAccess(
            values.ToDictionary(item => item.SlotKey, item => item.Capability, StringComparer.Ordinal),
            new Dictionary<string, QualifiedEvidenceHandle>(contextProofs, StringComparer.Ordinal),
            expectedReferences);
    }

    TCapability IRuleInputAccess.GetCapability<TCapability>(string slotKey)
    {
        if (!_capabilities.TryGetValue(slotKey, out var handle) ||
            handle is not CapabilityHandle<TCapability> typed)
        {
            throw new InvalidOperationException("The requested capability is unavailable.");
        }

        return typed.Value;
    }

    QualifiedEvidenceHandle IRuleInputAccess.GetContextProof(string slotKey) =>
        _contextProofs.TryGetValue(slotKey, out var value)
            ? value
            : throw new InvalidOperationException("The requested context proof is unavailable.");

    QualifiedEvidenceHandle IRuleInputAccess.GetExpectedReference(
        string selectorKey,
        QualifiedEvidenceHandle parentHandle) =>
        _expectedReferences.Require(selectorKey, parentHandle);
}

internal interface IQualifiedEvidenceDerivationFactory
{
    QualifiedEvidenceHandle Derive(
        QualifiedEvidenceHandle parent,
        string typedNodeKind,
        string typedNodeIdentity,
        EvidenceLocation location);
}
