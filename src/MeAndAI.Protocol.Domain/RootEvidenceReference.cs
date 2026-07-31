namespace MeAndAI.Protocol.Domain;

public sealed class RootEvidenceReference :
    IEquatable<RootEvidenceReference>
{
    private RootEvidenceReference(
        EvidenceScope scope,
        string schemaKey,
        string schemaVersion,
        ExactSha256Digest contentDigest,
        EvidenceLocation location,
        string[] requirementKeys,
        DateTimeOffset capturedAtUtc)
    {
        Scope = scope;
        SchemaKey = schemaKey;
        SchemaVersion = schemaVersion;
        ContentDigest = contentDigest;
        Location = location;
        RequirementKeys = EvidenceContractValidation.ReadOnly(requirementKeys);
        CapturedAtUtc = capturedAtUtc;
    }

    public EvidenceScope Scope { get; }

    public string SchemaKey { get; }

    public string SchemaVersion { get; }

    public ExactSha256Digest ContentDigest { get; }

    public EvidenceLocation Location { get; }

    public IReadOnlyList<string> RequirementKeys { get; }

    public DateTimeOffset CapturedAtUtc { get; }

    internal static RootEvidenceReference Create(EvidenceBinding binding)
    {
        ArgumentNullException.ThrowIfNull(binding);

        return new RootEvidenceReference(
            binding.Location.Scope,
            binding.Payload.SchemaKey,
            binding.Payload.SchemaVersion,
            binding.Payload.ContentDigest,
            binding.Location,
            [.. binding.RequirementKeys],
            binding.CapturedAtUtc);
    }

    public bool Equals(RootEvidenceReference? other) =>
        other is not null &&
        Scope.Equals(other.Scope) &&
        string.Equals(SchemaKey, other.SchemaKey, StringComparison.Ordinal) &&
        string.Equals(SchemaVersion, other.SchemaVersion, StringComparison.Ordinal) &&
        ContentDigest.Equals(other.ContentDigest) &&
        Location.Equals(other.Location) &&
        RequirementKeys.SequenceEqual(
            other.RequirementKeys,
            StringComparer.Ordinal) &&
        CapturedAtUtc.Equals(other.CapturedAtUtc);

    public override bool Equals(object? obj) =>
        Equals(obj as RootEvidenceReference);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Scope);
        hash.Add(SchemaKey, StringComparer.Ordinal);
        hash.Add(SchemaVersion, StringComparer.Ordinal);
        hash.Add(ContentDigest);
        hash.Add(Location);

        foreach (var requirementKey in RequirementKeys)
        {
            hash.Add(requirementKey, StringComparer.Ordinal);
        }

        hash.Add(CapturedAtUtc);
        return hash.ToHashCode();
    }
}
