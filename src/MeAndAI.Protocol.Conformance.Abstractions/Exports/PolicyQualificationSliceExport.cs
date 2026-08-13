namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class PolicyQualificationSliceExport
{
    private PolicyQualificationSliceExport(
        string exportKey,
        string exportVersion,
        CatalogSliceDeclaration catalog,
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
        CodecRegistrations = DeclarationValidation.Snapshot(
            codecRegistrations,
            nameof(codecRegistrations));
        ParserRegistrations = DeclarationValidation.Snapshot(
            parserRegistrations,
            nameof(parserRegistrations));
        IndexRegistrations = DeclarationValidation.Snapshot(
            indexRegistrations,
            nameof(indexRegistrations));
        DemandProjectorRegistrations = DeclarationValidation.Snapshot(
            demandProjectorRegistrations,
            nameof(demandProjectorRegistrations));
        SelectorRegistrations = DeclarationValidation.Snapshot(
            selectorRegistrations,
            nameof(selectorRegistrations));
        EvaluatorRegistrations = DeclarationValidation.Snapshot(
            evaluatorRegistrations,
            nameof(evaluatorRegistrations));
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

    public CatalogSliceDeclaration Catalog { get; }

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

    internal static PolicyQualificationSliceExport Create(
        string exportKey,
        string exportVersion,
        CatalogSliceDeclaration catalog,
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
}
