namespace MeAndAI.Protocol.Domain;

public sealed class ReleaseAssetEvidenceLocation : EvidenceLocation
{
    private ReleaseAssetEvidenceLocation(
        EvidenceScope scope,
        string releaseObjectIdentity,
        string tag,
        string assetName,
        ExactSha256Digest assetDigest)
        : base(scope)
    {
        ReleaseObjectIdentity = releaseObjectIdentity;
        Tag = tag;
        AssetName = assetName;
        AssetDigest = assetDigest;
    }

    public string ReleaseObjectIdentity { get; }

    public string Tag { get; }

    public string AssetName { get; }

    public ExactSha256Digest AssetDigest { get; }

    public static ReleaseAssetEvidenceLocation Create(
        EvidenceScope scope,
        string releaseObjectIdentity,
        string tag,
        string assetName,
        ExactSha256Digest assetDigest)
    {
        ArgumentNullException.ThrowIfNull(scope);

        if (!scope.Target.Surface.Equals(SurfaceKind.Release))
        {
            throw new ArgumentException(
                "A release-asset location requires a release evidence scope.",
                nameof(scope));
        }

        ArgumentNullException.ThrowIfNull(assetDigest);

        return new ReleaseAssetEvidenceLocation(
            scope,
            EvidenceContractValidation.OpaqueIdentity(
                releaseObjectIdentity,
                nameof(releaseObjectIdentity)),
            EvidenceContractValidation.OpaqueIdentity(tag, nameof(tag)),
            EvidenceContractValidation.OpaqueIdentity(assetName, nameof(assetName)),
            assetDigest);
    }
}
