namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ContextIndexDeclaration
{
    private ContextIndexDeclaration(
        string indexKey,
        string indexVersion,
        ComponentTypeIdentity indexer,
        IndexInvocationScope invocationScope,
        IReadOnlyList<ComponentInputDeclaration> inputs,
        CapabilityContractIdentity outputCapability,
        SemanticResourceBudget budget,
        IReadOnlyList<EvaluationFailureCode> failureCodes)
    {
        IndexKey = indexKey;
        IndexVersion = indexVersion;
        Indexer = indexer;
        InvocationScope = invocationScope;
        Inputs = inputs;
        OutputCapability = outputCapability;
        Budget = budget;
        FailureCodes = failureCodes;
    }

    public string IndexKey { get; }

    public string IndexVersion { get; }

    public ComponentTypeIdentity Indexer { get; }

    public IndexInvocationScope InvocationScope { get; }

    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }

    public CapabilityContractIdentity OutputCapability { get; }

    public SemanticResourceBudget Budget { get; }

    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }

    public static ContextIndexDeclaration Create(
        string indexKey,
        string indexVersion,
        ComponentTypeIdentity indexer,
        IndexInvocationScope invocationScope,
        IEnumerable<ComponentInputDeclaration> inputs,
        CapabilityContractIdentity outputCapability,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes)
    {
        ArgumentNullException.ThrowIfNull(indexer);
        ArgumentNullException.ThrowIfNull(invocationScope);
        ArgumentNullException.ThrowIfNull(outputCapability);
        ArgumentNullException.ThrowIfNull(budget);

        return new ContextIndexDeclaration(
            DeclarationValidation.Token(indexKey, nameof(indexKey)),
            DeclarationValidation.Version(indexVersion, nameof(indexVersion)),
            indexer,
            invocationScope,
            SemanticModelParserDeclaration.CanonicalInputs(
                inputs,
                nameof(inputs)),
            outputCapability,
            budget,
            SemanticModelParserDeclaration.CanonicalFailureCodes(
                failureCodes,
                nameof(failureCodes)));
    }
}
