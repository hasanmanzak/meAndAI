using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed class QualifiedEvidenceReference
{
    internal QualifiedEvidenceReference(
        QualifiedEvidenceReferenceKind kind,
        ExactSha256Digest manifestDigest,
        CatalogVersion catalogVersion,
        string slotKey,
        string requirementKey,
        EvidenceScope scope,
        ExactSha256Digest qualificationProofDigest,
        RootEvidenceReference? root,
        EvidenceLocation? location,
        IEnumerable<QualifiedEvidenceDerivation> derivations,
        QualifiedEvidenceReferenceKind? expectedSelectorParentKind,
        QualifiedEvidenceSelector? selector)
    {
        ArgumentNullException.ThrowIfNull(kind);
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(slotKey);
        ArgumentNullException.ThrowIfNull(requirementKey);
        ArgumentNullException.ThrowIfNull(scope);
        ArgumentNullException.ThrowIfNull(qualificationProofDigest);
        ArgumentNullException.ThrowIfNull(derivations);

        Kind = kind;
        ManifestDigest = manifestDigest;
        CatalogVersion = catalogVersion;
        SlotKey = slotKey;
        RequirementKey = requirementKey;
        Scope = scope;
        QualificationProofDigest = qualificationProofDigest;
        Root = root;
        Location = location;
        Derivations = derivations.ToArray();
        ExpectedSelectorParentKind = expectedSelectorParentKind;
        Selector = selector;
    }

    public QualifiedEvidenceReferenceKind Kind { get; }

    public ExactSha256Digest ManifestDigest { get; }

    public CatalogVersion CatalogVersion { get; }

    public string SlotKey { get; }

    public string RequirementKey { get; }

    public EvidenceScope Scope { get; }

    public ExactSha256Digest QualificationProofDigest { get; }

    public RootEvidenceReference? Root { get; }

    public EvidenceLocation? Location { get; }

    public IReadOnlyList<QualifiedEvidenceDerivation> Derivations { get; }

    public QualifiedEvidenceReferenceKind? ExpectedSelectorParentKind { get; }

    public QualifiedEvidenceSelector? Selector { get; }
}
