using System.Security.Cryptography;

namespace MeAndAI.Protocol.Domain;

public sealed class CanonicalEvidencePayload :
    IEquatable<CanonicalEvidencePayload>
{
    private CanonicalEvidencePayload(
        string schemaKey,
        string schemaVersion,
        ExactSha256Digest contentDigest,
        byte[] canonicalBytes)
    {
        SchemaKey = schemaKey;
        SchemaVersion = schemaVersion;
        ContentDigest = contentDigest;
        CanonicalBytes = EvidenceContractValidation.ReadOnly(canonicalBytes);
    }

    public string SchemaKey { get; }

    public string SchemaVersion { get; }

    public ExactSha256Digest ContentDigest { get; }

    public IReadOnlyList<byte> CanonicalBytes { get; }

    public static CanonicalEvidencePayload Create(
        string schemaKey,
        string schemaVersion,
        IEnumerable<byte> canonicalBytes)
    {
        var validatedSchemaKey = EvidenceContractValidation.OpenToken(
            schemaKey,
            nameof(schemaKey));
        var validatedSchemaVersion = EvidenceContractValidation.Version(
            schemaVersion,
            nameof(schemaVersion));
        var bytes = EvidenceContractValidation.Materialize(
            canonicalBytes,
            nameof(canonicalBytes));
        var digest = ExactSha256Digest.FromHashBytes(SHA256.HashData(bytes));

        return new CanonicalEvidencePayload(
            validatedSchemaKey,
            validatedSchemaVersion,
            digest,
            bytes);
    }

    public bool Equals(CanonicalEvidencePayload? other) =>
        other is not null &&
        string.Equals(SchemaKey, other.SchemaKey, StringComparison.Ordinal) &&
        string.Equals(SchemaVersion, other.SchemaVersion, StringComparison.Ordinal) &&
        ContentDigest.Equals(other.ContentDigest) &&
        CanonicalBytes.SequenceEqual(other.CanonicalBytes);

    public override bool Equals(object? obj) =>
        Equals(obj as CanonicalEvidencePayload);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(SchemaKey, StringComparer.Ordinal);
        hash.Add(SchemaVersion, StringComparer.Ordinal);
        hash.Add(ContentDigest);

        foreach (var value in CanonicalBytes)
        {
            hash.Add(value);
        }

        return hash.ToHashCode();
    }
}
