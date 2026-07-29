using System.Collections.ObjectModel;
using MeAndAI.Operations.Domain.Identity;

namespace MeAndAI.Operations.Governance.Core.Rules;

public sealed class GovernanceCatalogIdentity
{
    private const int CurrentSchema = 1;

    private readonly byte[] canonicalMetadataBytes;

    private GovernanceCatalogIdentity(
        GovernanceCatalogRuleIdentity[] rules,
        byte[] canonicalMetadataBytes,
        ExactSha256Digest metadataDigest)
    {
        Schema = CurrentSchema;
        Rules = new ReadOnlyCollection<GovernanceCatalogRuleIdentity>(
            [.. rules]);
        this.canonicalMetadataBytes = [.. canonicalMetadataBytes];
        MetadataDigest = metadataDigest;
    }

    public int Schema { get; }

    public IReadOnlyList<GovernanceCatalogRuleIdentity> Rules { get; }

    public ExactSha256Digest MetadataDigest { get; }

    internal static GovernanceCatalogIdentity CreateFromCatalog(
        GovernanceCatalogRuleIdentity[] rules,
        byte[] canonicalMetadataBytes,
        ExactSha256Digest metadataDigest)
    {
        ArgumentNullException.ThrowIfNull(rules);
        ArgumentNullException.ThrowIfNull(canonicalMetadataBytes);
        ArgumentNullException.ThrowIfNull(metadataDigest);

        if (rules.Length == 0 || canonicalMetadataBytes.Length == 0)
        {
            throw new ArgumentException(
                "Catalog identity values cannot be empty.",
                nameof(rules));
        }

        return new GovernanceCatalogIdentity(
            rules,
            canonicalMetadataBytes,
            metadataDigest);
    }

    internal byte[] GetCanonicalMetadataBytes() =>
        [.. canonicalMetadataBytes];

    internal void RequireMatchingDigest(ExactSha256Digest digest)
    {
        ArgumentNullException.ThrowIfNull(digest);

        if (digest != MetadataDigest)
        {
            throw new ArgumentException(
                "The supplied catalog metadata digest does not match the bounded catalog.",
                nameof(digest));
        }
    }
}
