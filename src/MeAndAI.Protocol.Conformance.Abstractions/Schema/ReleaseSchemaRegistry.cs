using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class ReleaseSchemaRegistry
{
    private ReleaseSchemaRegistry(
        IReadOnlyList<PayloadSchemaDeclaration> payloadSchemas,
        IReadOnlyList<SemanticModelParserDeclaration> parsers,
        IReadOnlyList<ContextIndexDeclaration> indexes,
        IReadOnlyList<AcquisitionDemandProjectorDeclaration> demandProjectors,
        IReadOnlyList<AdmissionProofContractDeclaration> admissionProofContracts,
        SessionCacheBudget cacheBudget)
    {
        PayloadSchemas = payloadSchemas;
        Parsers = parsers;
        Indexes = indexes;
        DemandProjectors = demandProjectors;
        AdmissionProofContracts = admissionProofContracts;
        CacheBudget = cacheBudget;
    }

    public IReadOnlyList<PayloadSchemaDeclaration> PayloadSchemas { get; }

    public IReadOnlyList<SemanticModelParserDeclaration> Parsers { get; }

    public IReadOnlyList<ContextIndexDeclaration> Indexes { get; }

    public IReadOnlyList<AcquisitionDemandProjectorDeclaration>
        DemandProjectors
    { get; }

    public IReadOnlyList<AdmissionProofContractDeclaration>
        AdmissionProofContracts
    { get; }

    public SessionCacheBudget CacheBudget { get; }

    public static ReleaseSchemaRegistry Create(
        IEnumerable<PayloadSchemaDeclaration> payloadSchemas,
        IEnumerable<SemanticModelParserDeclaration> parsers,
        IEnumerable<ContextIndexDeclaration> indexes,
        IEnumerable<AcquisitionDemandProjectorDeclaration> demandProjectors,
        IEnumerable<AdmissionProofContractDeclaration> admissionProofContracts,
        SessionCacheBudget cacheBudget)
    {
        ArgumentNullException.ThrowIfNull(cacheBudget);

        return new ReleaseSchemaRegistry(
            DeclarationValidation.Canonicalize(
                payloadSchemas,
                nameof(payloadSchemas),
                item => $"{item.SchemaKey}\0{item.SchemaVersion}",
                StringComparer.Ordinal),
            DeclarationValidation.Canonicalize(
                parsers,
                nameof(parsers),
                item => $"{item.ParserKey}\0{item.ParserVersion}",
                StringComparer.Ordinal),
            DeclarationValidation.Canonicalize(
                indexes,
                nameof(indexes),
                item => $"{item.IndexKey}\0{item.IndexVersion}",
                StringComparer.Ordinal),
            DeclarationValidation.Canonicalize(
                demandProjectors,
                nameof(demandProjectors),
                item => $"{item.ProjectorKey}\0{item.ProjectorVersion}",
                StringComparer.Ordinal),
            DeclarationValidation.Canonicalize(
                admissionProofContracts,
                nameof(admissionProofContracts),
                item =>
                    $"{item.ContractKey}\0{item.ContractVersion}\0" +
                    AdmissionProofRank(item.Kind),
                StringComparer.Ordinal),
            cacheBudget);
    }

    public bool TryGetPayloadSchema(
        string schemaKey,
        string schemaVersion,
        [NotNullWhen(true)] out PayloadSchemaDeclaration? declaration)
    {
        var key = DeclarationValidation.Token(schemaKey, nameof(schemaKey));
        var version = DeclarationValidation.Version(
            schemaVersion,
            nameof(schemaVersion));
        declaration = PayloadSchemas.SingleOrDefault(item =>
            string.Equals(item.SchemaKey, key, StringComparison.Ordinal) &&
            string.Equals(item.SchemaVersion, version, StringComparison.Ordinal));
        return declaration is not null;
    }

    public bool TryGetParser(
        string parserKey,
        string parserVersion,
        [NotNullWhen(true)] out SemanticModelParserDeclaration? declaration)
    {
        var key = DeclarationValidation.Token(parserKey, nameof(parserKey));
        var version = DeclarationValidation.Version(
            parserVersion,
            nameof(parserVersion));
        declaration = Parsers.SingleOrDefault(item =>
            string.Equals(item.ParserKey, key, StringComparison.Ordinal) &&
            string.Equals(item.ParserVersion, version, StringComparison.Ordinal));
        return declaration is not null;
    }

    public bool TryGetIndex(
        string indexKey,
        string indexVersion,
        [NotNullWhen(true)] out ContextIndexDeclaration? declaration)
    {
        var key = DeclarationValidation.Token(indexKey, nameof(indexKey));
        var version = DeclarationValidation.Version(
            indexVersion,
            nameof(indexVersion));
        declaration = Indexes.SingleOrDefault(item =>
            string.Equals(item.IndexKey, key, StringComparison.Ordinal) &&
            string.Equals(item.IndexVersion, version, StringComparison.Ordinal));
        return declaration is not null;
    }

    public bool TryGetDemandProjector(
        string projectorKey,
        string projectorVersion,
        [NotNullWhen(true)] out AcquisitionDemandProjectorDeclaration? declaration)
    {
        var key = DeclarationValidation.Token(
            projectorKey,
            nameof(projectorKey));
        var version = DeclarationValidation.Version(
            projectorVersion,
            nameof(projectorVersion));
        declaration = DemandProjectors.SingleOrDefault(item =>
            string.Equals(item.ProjectorKey, key, StringComparison.Ordinal) &&
            string.Equals(item.ProjectorVersion, version, StringComparison.Ordinal));
        return declaration is not null;
    }

    public bool TryGetAdmissionProofContract(
        string contractKey,
        string contractVersion,
        AdmissionProofKind kind,
        [NotNullWhen(true)] out AdmissionProofContractDeclaration? declaration)
    {
        var key = DeclarationValidation.Token(contractKey, nameof(contractKey));
        var version = DeclarationValidation.Version(
            contractVersion,
            nameof(contractVersion));
        ArgumentNullException.ThrowIfNull(kind);
        declaration = AdmissionProofContracts.SingleOrDefault(item =>
            string.Equals(item.ContractKey, key, StringComparison.Ordinal) &&
            string.Equals(item.ContractVersion, version, StringComparison.Ordinal) &&
            item.Kind.Equals(kind));
        return declaration is not null;
    }

    private static int AdmissionProofRank(AdmissionProofKind kind)
    {
        if (kind.Equals(AdmissionProofKind.Observed))
        {
            return 0;
        }

        if (kind.Equals(AdmissionProofKind.Failed))
        {
            return 1;
        }

        return 2;
    }
}
