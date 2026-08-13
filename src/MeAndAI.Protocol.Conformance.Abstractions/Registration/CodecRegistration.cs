namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IProtocolSemanticModel;

internal interface ICanonicalPayloadCodec<TModel> :
    ISemanticResourceMeter<CodecQualificationInput, TModel>
    where TModel : class, IProtocolSemanticModel
{
    CanonicalPayloadWriteIntent Write(
        CanonicalPayloadWriteInput input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered codec does not implement writing.");

    CodecQualificationIntent<TModel> Qualify(
        CodecQualificationInput input,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered codec does not implement qualification.");

    SemanticResourceLocalUsage ISemanticResourceMeter<CodecQualificationInput, TModel>.MeasureLocal(
        CodecQualificationInput input,
        TModel value,
        CancellationToken cancellationToken) =>
        throw new NotSupportedException("The registered codec does not implement resource metering.");
}

internal sealed class ModelTypeToken<TModel>
    where TModel : class, IProtocolSemanticModel
{
    private ModelTypeToken(ModelContractIdentity contract)
    {
        Contract = contract;
    }

    internal ModelContractIdentity Contract { get; }

    internal static ModelTypeToken<TModel> Create(
        ModelContractIdentity contract)
    {
        ArgumentNullException.ThrowIfNull(contract);
        return new ModelTypeToken<TModel>(contract);
    }
}

internal interface ICodecRegistration
{
    PayloadSchemaDeclaration Declaration { get; }

    TResult Accept<TResult>(ICodecRegistrationVisitor<TResult> visitor);
}

internal interface ICodecRegistrationVisitor<TResult>
{
    TResult Visit<TModel>(CodecRegistration<TModel> registration)
        where TModel : class, IProtocolSemanticModel;
}

internal sealed class CodecRegistration<TModel> : ICodecRegistration
    where TModel : class, IProtocolSemanticModel
{
    private CodecRegistration(
        PayloadSchemaDeclaration declaration,
        ModelTypeToken<TModel> outputModel,
        ICanonicalPayloadCodec<TModel> codec)
    {
        Declaration = declaration;
        OutputModel = outputModel;
        Codec = codec;
    }

    public PayloadSchemaDeclaration Declaration { get; }

    internal ModelTypeToken<TModel> OutputModel { get; }

    internal ICanonicalPayloadCodec<TModel> Codec { get; }

    internal static CodecRegistration<TModel> Create(
        PayloadSchemaDeclaration declaration,
        ModelTypeToken<TModel> outputModel,
        ICanonicalPayloadCodec<TModel> codec)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(outputModel);
        ArgumentNullException.ThrowIfNull(codec);

        if (!ReferenceEquals(declaration.OutputModel, outputModel.Contract))
        {
            throw new ArgumentException(
                "The model token must retain the declaration output model.",
                nameof(outputModel));
        }

        return new CodecRegistration<TModel>(declaration, outputModel, codec);
    }

    public TResult Accept<TResult>(
        ICodecRegistrationVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}
