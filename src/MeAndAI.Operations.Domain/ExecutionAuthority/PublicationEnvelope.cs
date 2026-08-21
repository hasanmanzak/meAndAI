namespace MeAndAI.Operations.Domain.ExecutionAuthority;

public sealed class PublicationEnvelope : IEquatable<PublicationEnvelope>
{
    private PublicationEnvelope(AuthorityDigest sealedReportDigest,
        AuthorityDigest publicationGrantDigest, AuthoritySetBinding authoritySet,
        ExecutionTarget providerTarget, IdempotencyKey idempotencyKey,
        string gateSnapshotIdentity, string resultName,
        string allowedEffectIdentity, AuthorityDigest digest) =>
        (SealedReportDigest, PublicationGrantDigest, AuthoritySet, ProviderTarget,
            IdempotencyKey, GateSnapshotIdentity, ResultName,
            AllowedEffectIdentity, Digest) =
        (sealedReportDigest, publicationGrantDigest, authoritySet, providerTarget,
            idempotencyKey, gateSnapshotIdentity, resultName,
            allowedEffectIdentity, digest);

    public AuthorityDigest SealedReportDigest { get; }
    public AuthorityDigest PublicationGrantDigest { get; }
    public AuthoritySetBinding AuthoritySet { get; }
    public ExecutionTarget ProviderTarget { get; }
    public IdempotencyKey IdempotencyKey { get; }
    public string GateSnapshotIdentity { get; }
    public string ResultName { get; }
    public string AllowedEffectIdentity { get; }
    public AuthorityDigest Digest { get; }

    public static PublicationEnvelope Create(
        ExecutionGrant publicationGrant, AuthorityDigest digest)
    {
        ArgumentNullException.ThrowIfNull(publicationGrant);
        ArgumentNullException.ThrowIfNull(digest);
        if (publicationGrant.Capability != ExecutionCapability.ReportPublish ||
            publicationGrant.Binding is not PublicationGrantBinding binding ||
            !publicationGrant.Target.Equals(binding.ProviderTarget) ||
            !publicationGrant.IdempotencyKey.Equals(binding.IdempotencyKey))
        {
            throw new ArgumentException(
                "The publication grant does not bind the envelope fields.",
                nameof(publicationGrant));
        }

        return new(binding.SealedReportDigest, publicationGrant.Digest,
            publicationGrant.AuthoritySet, binding.ProviderTarget,
            binding.IdempotencyKey, binding.GateSnapshotIdentity,
            binding.ResultName, binding.AllowedEffectIdentity, digest);
    }

    public bool Equals(PublicationEnvelope? other) => other is not null &&
        SealedReportDigest.Equals(other.SealedReportDigest) &&
        PublicationGrantDigest.Equals(other.PublicationGrantDigest) &&
        AuthoritySet.Equals(other.AuthoritySet) &&
        ProviderTarget.Equals(other.ProviderTarget) &&
        IdempotencyKey.Equals(other.IdempotencyKey) &&
        StringComparer.Ordinal.Equals(
            GateSnapshotIdentity, other.GateSnapshotIdentity) &&
        StringComparer.Ordinal.Equals(ResultName, other.ResultName) &&
        StringComparer.Ordinal.Equals(
            AllowedEffectIdentity, other.AllowedEffectIdentity) &&
        Digest.Equals(other.Digest);

    public override bool Equals(object? obj) =>
        Equals(obj as PublicationEnvelope);

    public override int GetHashCode() => HashCode.Combine(
        SealedReportDigest, PublicationGrantDigest, AuthoritySet, ProviderTarget,
        HashCode.Combine(IdempotencyKey, GateSnapshotIdentity, ResultName,
            AllowedEffectIdentity, Digest));
}
