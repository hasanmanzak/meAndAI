using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class SealedEvaluationContext
{
    internal SealedEvaluationContext(
        CatalogAuthorityKind authorityKind,
        ExactSha256Digest manifestDigest,
        CatalogVersion catalogVersion,
        IEnumerable<string> admittedSlotKeys,
        IEnumerable<EvidenceScope> scopes)
    {
        ArgumentNullException.ThrowIfNull(authorityKind);
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(admittedSlotKeys);
        ArgumentNullException.ThrowIfNull(scopes);

        AuthorityKind = authorityKind;
        ManifestDigest = manifestDigest;
        CatalogVersion = catalogVersion;
        AdmittedSlotKeys = admittedSlotKeys.ToArray();
        Scopes = scopes.ToArray();
    }

    public CatalogAuthorityKind AuthorityKind { get; }

    public ExactSha256Digest ManifestDigest { get; }

    public CatalogVersion CatalogVersion { get; }

    public IReadOnlyList<string> AdmittedSlotKeys { get; }

    public IReadOnlyList<EvidenceScope> Scopes { get; }
}
