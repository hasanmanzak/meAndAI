namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface IIndexRegistration
{
    ContextIndexDeclaration Declaration { get; }

    TResult Accept<TResult>(IIndexRegistrationVisitor<TResult> visitor);
}

internal interface IIndexRegistrationVisitor<TResult>
{
    TResult Visit<TInput, TCapability>(
        IndexRegistration<TInput, TCapability> registration)
        where TInput : class, IComponentInput
        where TCapability : class, IEvidenceCapability;
}

internal sealed class IndexRegistration<TInput, TCapability> : IIndexRegistration
    where TInput : class, IComponentInput
    where TCapability : class, IEvidenceCapability
{
    private IndexRegistration(
        ContextIndexDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        CapabilityTypeToken<TCapability> outputCapability,
        IContextIndexer<TInput, TCapability> indexer)
    {
        Declaration = declaration;
        Binder = binder;
        OutputCapability = outputCapability;
        Indexer = indexer;
    }

    public ContextIndexDeclaration Declaration { get; }

    internal IComponentInputBinder<TInput> Binder { get; }

    internal CapabilityTypeToken<TCapability> OutputCapability { get; }

    internal IContextIndexer<TInput, TCapability> Indexer { get; }

    internal static IndexRegistration<TInput, TCapability> Create(
        ContextIndexDeclaration declaration,
        IComponentInputBinder<TInput> binder,
        CapabilityTypeToken<TCapability> outputCapability,
        IContextIndexer<TInput, TCapability> indexer)
    {
        ArgumentNullException.ThrowIfNull(declaration);
        ArgumentNullException.ThrowIfNull(binder);
        ArgumentNullException.ThrowIfNull(outputCapability);
        ArgumentNullException.ThrowIfNull(indexer);
        if (!ReferenceEquals(
                declaration.OutputCapability,
                outputCapability.Contract))
        {
            throw new ArgumentException(
                "The capability token must retain the index output capability.",
                nameof(outputCapability));
        }

        return new IndexRegistration<TInput, TCapability>(
            declaration,
            binder,
            outputCapability,
            indexer);
    }

    public TResult Accept<TResult>(IIndexRegistrationVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}
