namespace MeAndAI.Protocol.Domain;

public abstract class EvidenceLocation : IEquatable<EvidenceLocation>
{
    private protected EvidenceLocation(EvidenceScope scope)
    {
        ArgumentNullException.ThrowIfNull(scope);
        Scope = scope;
    }

    public EvidenceScope Scope { get; }

    public bool Equals(EvidenceLocation? other)
    {
        if (ReferenceEquals(this, other))
        {
            return true;
        }

        if (other is null || GetType() != other.GetType() || !Scope.Equals(other.Scope))
        {
            return false;
        }

        return (this, other) switch
        {
            (RepositoryEvidenceLocation left, RepositoryEvidenceLocation right) =>
                string.Equals(
                    left.RepositoryRelativePath,
                    right.RepositoryRelativePath,
                    StringComparison.Ordinal) &&
                string.Equals(
                    left.BlobIdentity,
                    right.BlobIdentity,
                    StringComparison.Ordinal) &&
                left.Line == right.Line &&
                string.Equals(left.Anchor, right.Anchor, StringComparison.Ordinal) &&
                string.Equals(left.Property, right.Property, StringComparison.Ordinal),
            (ProviderEvidenceLocation left, ProviderEvidenceLocation right) =>
                string.Equals(
                    left.ProviderServiceIdentity,
                    right.ProviderServiceIdentity,
                    StringComparison.Ordinal) &&
                string.Equals(left.ObjectType, right.ObjectType, StringComparison.Ordinal) &&
                string.Equals(
                    left.StableObjectIdentity,
                    right.StableObjectIdentity,
                    StringComparison.Ordinal) &&
                string.Equals(
                    left.VersionIdentity,
                    right.VersionIdentity,
                    StringComparison.Ordinal) &&
                string.Equals(left.Field, right.Field, StringComparison.Ordinal) &&
                left.Line == right.Line &&
                string.Equals(left.Fragment, right.Fragment, StringComparison.Ordinal),
            (ReleaseAssetEvidenceLocation left, ReleaseAssetEvidenceLocation right) =>
                string.Equals(
                    left.ReleaseObjectIdentity,
                    right.ReleaseObjectIdentity,
                    StringComparison.Ordinal) &&
                string.Equals(left.Tag, right.Tag, StringComparison.Ordinal) &&
                string.Equals(left.AssetName, right.AssetName, StringComparison.Ordinal) &&
                left.AssetDigest.Equals(right.AssetDigest),
            (SnapshotEvidenceLocation, SnapshotEvidenceLocation) => true,
            _ => false,
        };
    }

    public sealed override bool Equals(object? obj) =>
        Equals(obj as EvidenceLocation);

    public sealed override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(GetType());
        hash.Add(Scope);

        switch (this)
        {
            case RepositoryEvidenceLocation repository:
                hash.Add(repository.RepositoryRelativePath, StringComparer.Ordinal);
                hash.Add(repository.BlobIdentity, StringComparer.Ordinal);
                hash.Add(repository.Line);
                hash.Add(repository.Anchor, StringComparer.Ordinal);
                hash.Add(repository.Property, StringComparer.Ordinal);
                break;
            case ProviderEvidenceLocation provider:
                hash.Add(provider.ProviderServiceIdentity, StringComparer.Ordinal);
                hash.Add(provider.ObjectType, StringComparer.Ordinal);
                hash.Add(provider.StableObjectIdentity, StringComparer.Ordinal);
                hash.Add(provider.VersionIdentity, StringComparer.Ordinal);
                hash.Add(provider.Field, StringComparer.Ordinal);
                hash.Add(provider.Line);
                hash.Add(provider.Fragment, StringComparer.Ordinal);
                break;
            case ReleaseAssetEvidenceLocation releaseAsset:
                hash.Add(releaseAsset.ReleaseObjectIdentity, StringComparer.Ordinal);
                hash.Add(releaseAsset.Tag, StringComparer.Ordinal);
                hash.Add(releaseAsset.AssetName, StringComparer.Ordinal);
                hash.Add(releaseAsset.AssetDigest);
                break;
        }

        return hash.ToHashCode();
    }
}
