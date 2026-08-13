namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CompletePolicyPackExport
{
    private CompletePolicyPackExport(
        string exportKey,
        string exportVersion,
        CompleteCatalogDeclaration catalog,
        ReleaseSchemaRegistry schemaRegistry,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IEnumerable<IParserRegistration> parserRegistrations,
        IEnumerable<IIndexRegistration> indexRegistrations,
        IEnumerable<IDemandProjectorRegistration> demandProjectorRegistrations,
        IEnumerable<ISelectorRegistration> selectorRegistrations,
        IEnumerable<RuleEvaluatorRegistration> evaluatorRegistrations)
    {
        ExportKey = DeclarationValidation.Token(exportKey, nameof(exportKey));
        ExportVersion = DeclarationValidation.Version(
            exportVersion,
            nameof(exportVersion));
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(schemaRegistry);

        Catalog = catalog;
        SchemaRegistry = schemaRegistry;
        CodecRegistrations = Snapshot(codecRegistrations, nameof(codecRegistrations));
        ParserRegistrations = Snapshot(parserRegistrations, nameof(parserRegistrations));
        IndexRegistrations = Snapshot(indexRegistrations, nameof(indexRegistrations));
        DemandProjectorRegistrations = Snapshot(
            demandProjectorRegistrations,
            nameof(demandProjectorRegistrations));
        SelectorRegistrations = Snapshot(selectorRegistrations, nameof(selectorRegistrations));
        EvaluatorRegistrations = Snapshot(evaluatorRegistrations, nameof(evaluatorRegistrations));
        Components = ComponentProjection.Create(
            CodecRegistrations,
            ParserRegistrations,
            IndexRegistrations,
            DemandProjectorRegistrations,
            SelectorRegistrations,
            EvaluatorRegistrations);
    }

    public string ExportKey { get; }

    public string ExportVersion { get; }

    public CompleteCatalogDeclaration Catalog { get; }

    public ReleaseSchemaRegistry SchemaRegistry { get; }

    public IReadOnlyList<ComponentTypeIdentity> Components { get; }

    internal IReadOnlyList<ICodecRegistration> CodecRegistrations { get; }

    internal IReadOnlyList<IParserRegistration> ParserRegistrations { get; }

    internal IReadOnlyList<IIndexRegistration> IndexRegistrations { get; }

    internal IReadOnlyList<IDemandProjectorRegistration>
        DemandProjectorRegistrations
    { get; }

    internal IReadOnlyList<ISelectorRegistration> SelectorRegistrations { get; }

    internal IReadOnlyList<RuleEvaluatorRegistration> EvaluatorRegistrations { get; }

    internal static CompletePolicyPackExport Create(
        string exportKey,
        string exportVersion,
        CompleteCatalogDeclaration catalog,
        ReleaseSchemaRegistry schemaRegistry,
        IEnumerable<ICodecRegistration> codecRegistrations,
        IEnumerable<IParserRegistration> parserRegistrations,
        IEnumerable<IIndexRegistration> indexRegistrations,
        IEnumerable<IDemandProjectorRegistration> demandProjectorRegistrations,
        IEnumerable<ISelectorRegistration> selectorRegistrations,
        IEnumerable<RuleEvaluatorRegistration> evaluatorRegistrations) =>
        new(
            exportKey,
            exportVersion,
            catalog,
            schemaRegistry,
            codecRegistrations,
            parserRegistrations,
            indexRegistrations,
            demandProjectorRegistrations,
            selectorRegistrations,
            evaluatorRegistrations);

    private static IReadOnlyList<T> Snapshot<T>(
        IEnumerable<T> values,
        string parameterName)
        where T : class =>
        DeclarationValidation.Snapshot(values, parameterName);
}

internal static class ComponentProjection
{
    internal static IReadOnlyList<ComponentTypeIdentity> Create(
        IReadOnlyList<ICodecRegistration> codecs,
        IReadOnlyList<IParserRegistration> parsers,
        IReadOnlyList<IIndexRegistration> indexes,
        IReadOnlyList<IDemandProjectorRegistration> projectors,
        IReadOnlyList<ISelectorRegistration> selectors,
        IReadOnlyList<RuleEvaluatorRegistration> evaluators) =>
        codecs.Select(item => item.Accept(CodecComponentVisitor.Instance))
            .Concat(parsers.Select(item => item.Accept(ParserComponentVisitor.Instance)))
            .Concat(indexes.Select(item => item.Accept(IndexComponentVisitor.Instance)))
            .Concat(projectors.Select(item => item.Accept(ProjectorComponentVisitor.Instance)))
            .Concat(selectors.Select(item => item.Accept(SelectorComponentVisitor.Instance)))
            .Concat(evaluators.Select(item => RuntimeComponent(
                item.Declaration.Evaluator,
                item.Evaluator)))
            .Distinct()
            .OrderBy(item => item.ComponentKey, StringComparer.Ordinal)
            .ThenBy(item => item.ComponentVersion, StringComparer.Ordinal)
            .ToArray();

    private static ComponentTypeIdentity RuntimeComponent(
        ComponentTypeIdentity declaration,
        object implementation)
    {
        var type = implementation.GetType();
        return ComponentTypeIdentity.Create(
            declaration.ComponentKey,
            declaration.ComponentVersion,
            type.Assembly.GetName().Name!,
            type.FullName!);
    }

    private sealed class CodecComponentVisitor :
        ICodecRegistrationVisitor<ComponentTypeIdentity>
    {
        internal static CodecComponentVisitor Instance { get; } = new();

        public ComponentTypeIdentity Visit<TModel>(CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel =>
            RuntimeComponent(registration.Declaration.Codec, registration.Codec);
    }

    private sealed class ParserComponentVisitor :
        IParserRegistrationVisitor<ComponentTypeIdentity>
    {
        internal static ParserComponentVisitor Instance { get; } = new();

        public ComponentTypeIdentity Visit<TInput, TOutput>(
            ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel =>
            RuntimeComponent(registration.Declaration.Parser, registration.Parser);
    }

    private sealed class IndexComponentVisitor :
        IIndexRegistrationVisitor<ComponentTypeIdentity>
    {
        internal static IndexComponentVisitor Instance { get; } = new();

        public ComponentTypeIdentity Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability =>
            RuntimeComponent(registration.Declaration.Indexer, registration.Indexer);
    }

    private sealed class ProjectorComponentVisitor :
        IDemandProjectorRegistrationVisitor<ComponentTypeIdentity>
    {
        internal static ProjectorComponentVisitor Instance { get; } = new();

        public ComponentTypeIdentity Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability =>
            RuntimeComponent(registration.Declaration.Projector, registration.Projector);
    }

    private sealed class SelectorComponentVisitor :
        ISelectorRegistrationVisitor<ComponentTypeIdentity>
    {
        internal static SelectorComponentVisitor Instance { get; } = new();

        public ComponentTypeIdentity Visit<TResolver>(
            SelectorRegistration<TResolver> registration)
            where TResolver : class, IExpectedSelectorResolver =>
            RuntimeComponent(registration.Component, registration.Resolver);
    }
}
