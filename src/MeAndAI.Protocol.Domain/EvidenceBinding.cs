namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceBinding : IEquatable<EvidenceBinding>
{
    private EvidenceBinding(
        CanonicalEvidencePayload payload,
        EvidenceLocation location,
        string[] requirementKeys,
        DateTimeOffset capturedAtUtc)
    {
        Payload = payload;
        Location = location;
        RequirementKeys = EvidenceContractValidation.ReadOnly(requirementKeys);
        CapturedAtUtc = capturedAtUtc;
    }

    public CanonicalEvidencePayload Payload { get; }

    public EvidenceLocation Location { get; }

    public IReadOnlyList<string> RequirementKeys { get; }

    public DateTimeOffset CapturedAtUtc { get; }

    public static EvidenceBinding Create(
        CanonicalEvidencePayload payload,
        EvidenceLocation location,
        IEnumerable<string> requirementKeys,
        DateTimeOffset capturedAtUtc)
    {
        ArgumentNullException.ThrowIfNull(payload);
        ArgumentNullException.ThrowIfNull(location);

        var keys = EvidenceContractValidation.Materialize(
            requirementKeys,
            nameof(requirementKeys));
        EvidenceContractValidation.NoNullElements(keys, nameof(requirementKeys));

        if (keys.Length == 0)
        {
            throw new ArgumentException(
                "An evidence binding requires at least one requirement key.",
                nameof(requirementKeys));
        }

        for (var index = 0; index < keys.Length; index++)
        {
            keys[index] = EvidenceContractValidation.OpenToken(
                keys[index],
                nameof(requirementKeys));
        }

        Array.Sort(keys, StringComparer.Ordinal);

        if (keys.Zip(keys.Skip(1)).Any(pair =>
                string.Equals(pair.First, pair.Second, StringComparison.Ordinal)))
        {
            throw new ArgumentException(
                "Requirement keys must be unique.",
                nameof(requirementKeys));
        }

        EvidenceContractValidation.Utc(capturedAtUtc, nameof(capturedAtUtc));

        if (capturedAtUtc < location.Scope.Boundary.StartedAtUtc ||
            capturedAtUtc > location.Scope.Boundary.CompletedAtUtc)
        {
            throw new ArgumentOutOfRangeException(
                nameof(capturedAtUtc),
                capturedAtUtc,
                "The capture timestamp must be inside the evidence boundary.");
        }

        return new EvidenceBinding(payload, location, keys, capturedAtUtc);
    }

    public bool Equals(EvidenceBinding? other) =>
        other is not null &&
        Payload.Equals(other.Payload) &&
        Location.Equals(other.Location) &&
        RequirementKeys.SequenceEqual(
            other.RequirementKeys,
            StringComparer.Ordinal) &&
        CapturedAtUtc.Equals(other.CapturedAtUtc);

    public override bool Equals(object? obj) =>
        Equals(obj as EvidenceBinding);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Payload);
        hash.Add(Location);

        foreach (var requirementKey in RequirementKeys)
        {
            hash.Add(requirementKey, StringComparer.Ordinal);
        }

        hash.Add(CapturedAtUtc);
        return hash.ToHashCode();
    }
}
