namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CompletePolicyPackExport
{
    private CompletePolicyPackExport(
        string exportKey,
        string exportVersion,
        CompleteCatalogDeclaration catalog,
        ReleaseSchemaRegistry schemaRegistry,
        IEnumerable<ComponentTypeIdentity> components)
    {
        ExportKey = DeclarationValidation.Token(exportKey, nameof(exportKey));
        ExportVersion = DeclarationValidation.Version(
            exportVersion,
            nameof(exportVersion));
        ArgumentNullException.ThrowIfNull(catalog);
        ArgumentNullException.ThrowIfNull(schemaRegistry);

        Catalog = catalog;
        SchemaRegistry = schemaRegistry;
        Components = DeclarationValidation.Snapshot(
            components,
            nameof(components));
    }

    public string ExportKey { get; }

    public string ExportVersion { get; }

    public CompleteCatalogDeclaration Catalog { get; }

    public ReleaseSchemaRegistry SchemaRegistry { get; }

    public IReadOnlyList<ComponentTypeIdentity> Components { get; }
}
