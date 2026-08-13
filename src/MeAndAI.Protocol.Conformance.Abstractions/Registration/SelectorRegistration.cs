namespace MeAndAI.Protocol.Conformance.Abstractions;

internal interface ISelectorRegistration
{
    ComponentTypeIdentity Component { get; }

    string SelectorSchemaKey { get; }

    TResult Accept<TResult>(ISelectorRegistrationVisitor<TResult> visitor);
}

internal interface ISelectorRegistrationVisitor<TResult>
{
    TResult Visit<TResolver>(SelectorRegistration<TResolver> registration)
        where TResolver : class, IExpectedSelectorResolver;
}

internal sealed class SelectorRegistration<TResolver> : ISelectorRegistration
    where TResolver : class, IExpectedSelectorResolver
{
    private SelectorRegistration(
        ComponentTypeIdentity component,
        string selectorSchemaKey,
        TResolver resolver)
    {
        Component = component;
        SelectorSchemaKey = selectorSchemaKey;
        Resolver = resolver;
    }

    public ComponentTypeIdentity Component { get; }

    public string SelectorSchemaKey { get; }

    internal TResolver Resolver { get; }

    internal static SelectorRegistration<TResolver> Create(
        ComponentTypeIdentity component,
        string selectorSchemaKey,
        TResolver resolver)
    {
        ArgumentNullException.ThrowIfNull(component);
        ArgumentNullException.ThrowIfNull(resolver);
        return new SelectorRegistration<TResolver>(
            component,
            DeclarationValidation.Token(
                selectorSchemaKey,
                nameof(selectorSchemaKey)),
            resolver);
    }

    public TResult Accept<TResult>(ISelectorRegistrationVisitor<TResult> visitor)
    {
        ArgumentNullException.ThrowIfNull(visitor);
        return visitor.Visit(this);
    }
}
