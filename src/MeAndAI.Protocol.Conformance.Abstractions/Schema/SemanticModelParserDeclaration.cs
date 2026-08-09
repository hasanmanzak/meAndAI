namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class SemanticModelParserDeclaration
{
    private SemanticModelParserDeclaration(
        string parserKey,
        string parserVersion,
        ComponentTypeIdentity parser,
        IReadOnlyList<ComponentInputDeclaration> inputs,
        ModelContractIdentity outputModel,
        SemanticResourceBudget budget,
        IReadOnlyList<EvaluationFailureCode> failureCodes)
    {
        ParserKey = parserKey;
        ParserVersion = parserVersion;
        Parser = parser;
        Inputs = inputs;
        OutputModel = outputModel;
        Budget = budget;
        FailureCodes = failureCodes;
    }

    public string ParserKey { get; }

    public string ParserVersion { get; }

    public ComponentTypeIdentity Parser { get; }

    public IReadOnlyList<ComponentInputDeclaration> Inputs { get; }

    public ModelContractIdentity OutputModel { get; }

    public SemanticResourceBudget Budget { get; }

    public IReadOnlyList<EvaluationFailureCode> FailureCodes { get; }

    public static SemanticModelParserDeclaration Create(
        string parserKey,
        string parserVersion,
        ComponentTypeIdentity parser,
        IEnumerable<ComponentInputDeclaration> inputs,
        ModelContractIdentity outputModel,
        SemanticResourceBudget budget,
        IEnumerable<EvaluationFailureCode> failureCodes)
    {
        ArgumentNullException.ThrowIfNull(parser);
        ArgumentNullException.ThrowIfNull(outputModel);
        ArgumentNullException.ThrowIfNull(budget);

        return new SemanticModelParserDeclaration(
            DeclarationValidation.Token(parserKey, nameof(parserKey)),
            DeclarationValidation.Version(parserVersion, nameof(parserVersion)),
            parser,
            CanonicalInputs(inputs, nameof(inputs)),
            outputModel,
            budget,
            CanonicalFailureCodes(failureCodes, nameof(failureCodes)));
    }

    internal static IReadOnlyList<ComponentInputDeclaration> CanonicalInputs(
        IEnumerable<ComponentInputDeclaration>? inputs,
        string parameterName)
    {
        var snapshot = DeclarationValidation.Snapshot(inputs, parameterName);
        var ordered = snapshot
            .OrderBy(InputRank)
            .ThenBy(InputKey, StringComparer.Ordinal)
            .ThenBy(InputVersion, StringComparer.Ordinal)
            .ToArray();
        var keys = ordered
            .Select(input => $"{InputRank(input)}|{InputKey(input)}|{InputVersion(input)}")
            .ToArray();
        if (keys.Distinct(StringComparer.Ordinal).Count() != keys.Length)
        {
            throw new ArgumentException(
                "The collection contains a duplicate component input.",
                parameterName);
        }

        return Array.AsReadOnly(ordered);
    }

    internal static IReadOnlyList<EvaluationFailureCode> CanonicalFailureCodes(
        IEnumerable<EvaluationFailureCode>? failureCodes,
        string parameterName)
    {
        return DeclarationValidation.Canonicalize(
            failureCodes,
            parameterName,
            code => code.Value,
            StringComparer.Ordinal);
    }

    private static int InputRank(ComponentInputDeclaration input) =>
        input.Model is null ? 1 : 0;

    private static string InputKey(ComponentInputDeclaration input) =>
        input.Model?.ModelKey ?? input.Capability!.CapabilityKey;

    private static string InputVersion(ComponentInputDeclaration input) =>
        input.Model?.ModelVersion ?? input.Capability!.CapabilityVersion;
}
