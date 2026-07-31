namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class PayloadSchemaDeclaration
{
    private PayloadSchemaDeclaration(
        string schemaKey,
        string schemaVersion,
        ComponentTypeIdentity codec,
        ModelContractIdentity outputModel,
        int maxBindingsPerInstruction,
        long maxRetainedCanonicalBytesPerInstruction,
        SemanticResourceBudget budget,
        IReadOnlyList<string> codecFailureCodes)
    {
        SchemaKey = schemaKey;
        SchemaVersion = schemaVersion;
        Codec = codec;
        OutputModel = outputModel;
        MaxBindingsPerInstruction = maxBindingsPerInstruction;
        MaxRetainedCanonicalBytesPerInstruction =
            maxRetainedCanonicalBytesPerInstruction;
        Budget = budget;
        CodecFailureCodes = codecFailureCodes;
    }

    public string SchemaKey { get; }

    public string SchemaVersion { get; }

    public ComponentTypeIdentity Codec { get; }

    public ModelContractIdentity OutputModel { get; }

    public int MaxBindingsPerInstruction { get; }

    public long MaxRetainedCanonicalBytesPerInstruction { get; }

    public SemanticResourceBudget Budget { get; }

    public IReadOnlyList<string> CodecFailureCodes { get; }

    public static PayloadSchemaDeclaration Create(
        string schemaKey,
        string schemaVersion,
        ComponentTypeIdentity codec,
        ModelContractIdentity outputModel,
        int maxBindingsPerInstruction,
        long maxRetainedCanonicalBytesPerInstruction,
        SemanticResourceBudget budget,
        IEnumerable<string> codecFailureCodes)
    {
        var canonicalSchemaKey = DeclarationValidation.Token(
            schemaKey,
            nameof(schemaKey));
        var canonicalSchemaVersion = DeclarationValidation.Version(
            schemaVersion,
            nameof(schemaVersion));
        ArgumentNullException.ThrowIfNull(codec);
        ArgumentNullException.ThrowIfNull(outputModel);
        DeclarationValidation.Positive(
            maxBindingsPerInstruction,
            nameof(maxBindingsPerInstruction));
        DeclarationValidation.Positive(
            maxRetainedCanonicalBytesPerInstruction,
            nameof(maxRetainedCanonicalBytesPerInstruction));
        ArgumentNullException.ThrowIfNull(budget);

        return new PayloadSchemaDeclaration(
            canonicalSchemaKey,
            canonicalSchemaVersion,
            codec,
            outputModel,
            maxBindingsPerInstruction,
            maxRetainedCanonicalBytesPerInstruction,
            budget,
            DeclarationValidation.CanonicalTokens(
                codecFailureCodes,
                nameof(codecFailureCodes)));
    }
}
