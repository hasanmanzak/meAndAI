using System.Globalization;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

public sealed class CatalogPredecessorBinding :
    IEquatable<CatalogPredecessorBinding>
{
    private CatalogPredecessorBinding(
        CatalogPredecessorKind kind,
        CatalogVersion? catalogVersion,
        ExactSha256Digest? manifestDigest,
        ExactSha256Digest? completeInventoryDigest)
    {
        Kind = kind;
        CatalogVersion = catalogVersion;
        ManifestDigest = manifestDigest;
        CompleteInventoryDigest = completeInventoryDigest;
    }

    public CatalogPredecessorKind Kind { get; }

    public CatalogVersion? CatalogVersion { get; }

    public ExactSha256Digest? ManifestDigest { get; }

    public ExactSha256Digest? CompleteInventoryDigest { get; }

    public static CatalogPredecessorBinding Genesis() =>
        new(CatalogPredecessorKind.Genesis, null, null, null);

    public static CatalogPredecessorBinding Existing(
        CatalogVersion catalogVersion,
        ExactSha256Digest manifestDigest,
        ExactSha256Digest completeInventoryDigest)
    {
        ArgumentNullException.ThrowIfNull(catalogVersion);
        ArgumentNullException.ThrowIfNull(manifestDigest);
        ArgumentNullException.ThrowIfNull(completeInventoryDigest);

        return new CatalogPredecessorBinding(
            CatalogPredecessorKind.Existing,
            catalogVersion,
            manifestDigest,
            completeInventoryDigest);
    }

    public bool Equals(CatalogPredecessorBinding? other) =>
        other is not null &&
        Kind.Equals(other.Kind) &&
        Equals(CatalogVersion, other.CatalogVersion) &&
        Equals(ManifestDigest, other.ManifestDigest) &&
        Equals(CompleteInventoryDigest, other.CompleteInventoryDigest);

    public override bool Equals(object? obj) =>
        Equals(obj as CatalogPredecessorBinding);

    public override int GetHashCode() =>
        HashCode.Combine(
            Kind,
            CatalogVersion,
            ManifestDigest,
            CompleteInventoryDigest);

    public override string ToString() =>
        Kind.Equals(CatalogPredecessorKind.Genesis)
            ? "genesis"
            : $"existing:{CatalogVersion!.Value.ToString(CultureInfo.InvariantCulture)}:{ManifestDigest}:{CompleteInventoryDigest}";
}
