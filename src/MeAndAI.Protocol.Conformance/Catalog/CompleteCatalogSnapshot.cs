using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class CompleteCatalogSnapshot
{
    internal CompleteCatalogSnapshot(
        string protocolVersion,
        CatalogVersion catalogVersion,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest completeInventoryDigest,
        CatalogPredecessorBinding predecessor,
        string baselineProfileName,
        IEnumerable<RuleDeclaration> rules,
        IEnumerable<NamedProfileDeclaration> namedProfiles)
    {
        ProtocolVersion = DeclarationValidation.ProtocolVersion(
            protocolVersion,
            nameof(protocolVersion));
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(completeInventoryDigest);
        ArgumentNullException.ThrowIfNull(predecessor);

        CatalogVersion = catalogVersion;
        ManifestDigest = manifestDigest;
        CompleteInventoryDigest = completeInventoryDigest;
        Predecessor = predecessor;
        BaselineProfileName = DeclarationValidation.Token(
            baselineProfileName,
            nameof(baselineProfileName));
        Rules = DeclarationValidation.Snapshot(rules, nameof(rules));
        NamedProfiles = DeclarationValidation.Snapshot(
            namedProfiles,
            nameof(namedProfiles));
    }

    public string ProtocolVersion { get; }

    public CatalogVersion CatalogVersion { get; }

    public ExactSha256Digest ManifestDigest { get; }

    public ExactSha256Digest CompleteInventoryDigest { get; }

    public CatalogPredecessorBinding Predecessor { get; }

    public string BaselineProfileName { get; }

    public IReadOnlyList<RuleDeclaration> Rules { get; }

    public IReadOnlyList<NamedProfileDeclaration> NamedProfiles { get; }
}
