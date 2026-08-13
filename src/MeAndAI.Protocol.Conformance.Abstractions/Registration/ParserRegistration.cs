namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IParserRegistration
{
    SemanticModelParserDeclaration Declaration { get; }

    TResult Accept<TResult>(IParserRegistrationVisitor<TResult> visitor);
}

internal interface IParserRegistrationVisitor<TResult>
{
    TResult Visit<TInput, TOutput>(
        ParserRegistration<TInput, TOutput> registration)
        where TInput : class, IComponentInput
        where TOutput : class, IProtocolSemanticModel;
}

internal sealed class ParserRegistration<TInput, TOutput> : IParserRegistration
    where TInput : class, IComponentInput
    where TOutput : class, IProtocolSemanticModel
{
    private ParserRegistration(
        SemanticModelParserDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        ModelTypeToken<TOutput> outputModel,
        ISemanticModelParser<TInput, TOutput> parser)
    {
        Declaration = declaration;
        Binder = binder;
        OutputModel = outputModel;
        Parser = parser;
    }

    public SemanticModelParserDeclaration Declaration { get; }

    internal IComponentInputBinder<TInput> Binder { get; }

    internal ModelTypeToken<TOutput> OutputModel { get; }

    internal ISemanticModelParser<TInput, TOutput> Parser { get; }

    internal static ParserRegistration<TInput, TOutput> Create(
        SemanticModelParserDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        ModelTypeToken<TOutput> outputModel,
        ISemanticModelParser<TInput, TOutput> parser)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(binder);
        ArgumentNullException.ThrowIfNull(outputModel);
        ArgumentNullException.ThrowIfNull(parser);
        if (!ReferenceEquals(declaration.OutputModel, outputModel.Contract))
        {
            throw new ArgumentException(
                "The model token must retain the parser output model.",
                nameof(outputModel));
        }

        return new ParserRegistration<TInput, TOutput>(
            declaration,
            binder,
            outputModel,
            parser);
    }

    public TResult Accept<TResult>(IParserRegistrationVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}
