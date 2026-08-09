namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class AcquisitionDemandProjectorDeclaration
{
    private AcquisitionDemandProjectorDeclaration(
        string projectorKey,
        string projectorVersion,
        ComponentTypeIdentity projector,
        CapabilityContractIdentity inputCapability,
        IReadOnlyList<string> inputSlotKeys,
        string outputSlotKey,
        string demandSchemaKey,
        string demandSchemaVersion,
        SemanticResourceBudget budget,
        IReadOnlyList<EvaluationFailureCode> failureCodes)
    {
        ProjectorKey = projectorKey;
        ProjectorVersion = projectorVersion;
        Projector = projector;
        InputCapability = inputCapability;
        InputSlotKeys = inputSlotKeys;
        OutputSlotKey = outputSlotKey;
        DemandSchemaKey = demandSchemaKey;
        DemandSchemaVersion = demandSchemaVersion;
        Budget = budget;
        FailureCodes = failureCodes;
    }

    public string ProjectorKey { get; }

    public string ProjectorVersion { get; }

    public ComponentTypeIdentity Projector { get; }

    public CapabilityContractIdentity InputCapability { get; }

    public IReadOnlyList<string> InputSlotKeys { get; }

    public string OutputSlotKey { get; }

    public string DemandSchemaKey { get; }

    public string DemandSchemaVersion { get; }

    public SemanticResourceBudget Budget { get; }

    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }

    public static AcquisitionDemandProjectorDeclaration Create(
        string projectorKey,
        string projectorVersion,
        ComponentTypeIdentity projector,
        CapabilityContractIdentity inputCapability,
        IEnumerable<string> inputSlotKeys,
        string outputSlotKey,
        string demandSchemaKey,
        string demandSchemaVersion,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes)
    {
        ArgumentNullException.ThrowIfNull(projector);
        ArgumentNullException.ThrowIfNull(inputCapability);
        ArgumentNullException.ThrowIfNull(budget);

        var canonicalInputs = DeclarationValidation.CanonicalTokens(
            inputSlotKeys,
            nameof(inputSlotKeys),
            requireNonEmpty: true);
        var canonicalOutput = DeclarationValidation.Token(
            outputSlotKey,
            nameof(outputSlotKey));
        if (canonicalInputs.Contains(canonicalOutput, StringComparer.Ordinal))
        {
            throw new ArgumentException(
                "The output slot cannot also be an input slot.",
                nameof(outputSlotKey));
        }

        return new AcquisitionDemandProjectorDeclaration(
            DeclarationValidation.Token(projectorKey, nameof(projectorKey)),
            DeclarationValidation.Version(
                projectorVersion,
                nameof(projectorVersion)),
            projector,
            inputCapability,
            canonicalInputs,
            canonicalOutput,
            DeclarationValidation.Token(
                demandSchemaKey,
                nameof(demandSchemaKey)),
            DeclarationValidation.Version(
                demandSchemaVersion,
                nameof(demandSchemaVersion)),
            budget,
            SemanticModelParserDeclaration.CanonicalFailureCodes(
                failureCodes,
                nameof(failureCodes)));
    }
}
