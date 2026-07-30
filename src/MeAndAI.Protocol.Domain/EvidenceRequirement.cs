namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceRequirement : IEquatable<EvidenceRequirement>
{
    private static readonly EvidenceConsistencyClass[] ConsistencyClassOrder =
    [
        EvidenceConsistencyClass.ExactSnapshot,
        EvidenceConsistencyClass.ObjectVersionBound,
        EvidenceConsistencyClass.BoundedNonAtomicObservation,
    ];

    private readonly IReadOnlyList<EvidenceConsistencyClass>
        _acceptedConsistencyClasses;

    private EvidenceRequirement(
        string key,
        SurfaceKind surface,
        string kind,
        string completenessContract,
        string payloadSchemaKey,
        string payloadSchemaVersion,
        IReadOnlyList<EvidenceConsistencyClass> acceptedConsistencyClasses)
    {
        Key = key;
        Surface = surface;
        Kind = kind;
        CompletenessContract = completenessContract;
        PayloadSchemaKey = payloadSchemaKey;
        PayloadSchemaVersion = payloadSchemaVersion;
        _acceptedConsistencyClasses = acceptedConsistencyClasses;
    }

    public string Key { get; }

    public SurfaceKind Surface { get; }

    public string Kind { get; }

    public string CompletenessContract { get; }

    public string PayloadSchemaKey { get; }

    public string PayloadSchemaVersion { get; }

    public IReadOnlyList<EvidenceConsistencyClass>
        AcceptedConsistencyClasses => _acceptedConsistencyClasses;

    public static EvidenceRequirement Create(
        string key,
        SurfaceKind surface,
        string kind,
        string completenessContract,
        string payloadSchemaKey,
        string payloadSchemaVersion,
        IEnumerable<EvidenceConsistencyClass> acceptedConsistencyClasses)
    {
        var validatedKey = EvidenceContractValidation.OpenToken(
            key,
            nameof(key));
        ArgumentNullException.ThrowIfNull(surface);
        var validatedKind = EvidenceContractValidation.OpenToken(
            kind,
            nameof(kind));
        var validatedCompletenessContract =
            EvidenceContractValidation.OpenToken(
                completenessContract,
                nameof(completenessContract));
        var validatedPayloadSchemaKey = EvidenceContractValidation.OpenToken(
            payloadSchemaKey,
            nameof(payloadSchemaKey));
        var validatedPayloadSchemaVersion = EvidenceContractValidation.Version(
            payloadSchemaVersion,
            nameof(payloadSchemaVersion));
        var materialized = EvidenceContractValidation.Materialize(
            acceptedConsistencyClasses,
            nameof(acceptedConsistencyClasses));
        EvidenceContractValidation.NoNullElements(
            materialized,
            nameof(acceptedConsistencyClasses));

        if (materialized.Length == 0)
        {
            throw new ArgumentException(
                "At least one accepted consistency class is required.",
                nameof(acceptedConsistencyClasses));
        }

        var unique = new HashSet<EvidenceConsistencyClass>();
        foreach (var consistencyClass in materialized)
        {
            if (consistencyClass.Equals(
                    EvidenceConsistencyClass.InsufficientConsistency))
            {
                throw new ArgumentException(
                    "Insufficient consistency cannot be accepted.",
                    nameof(acceptedConsistencyClasses));
            }

            if (!unique.Add(consistencyClass))
            {
                throw new ArgumentException(
                    "Duplicate consistency classes are not allowed.",
                    nameof(acceptedConsistencyClasses));
            }
        }

        var ordered = ConsistencyClassOrder
            .Where(unique.Contains)
            .ToArray();
        if (ordered.Length != materialized.Length)
        {
            throw new ArgumentException(
                "Every consistency class must be a declared schema value.",
                nameof(acceptedConsistencyClasses));
        }

        return new EvidenceRequirement(
            validatedKey,
            surface,
            validatedKind,
            validatedCompletenessContract,
            validatedPayloadSchemaKey,
            validatedPayloadSchemaVersion,
            EvidenceContractValidation.ReadOnly(ordered));
    }

    public bool Equals(EvidenceRequirement? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (StringComparer.Ordinal.Equals(Key, other.Key) &&
             Surface.Equals(other.Surface) &&
             StringComparer.Ordinal.Equals(Kind, other.Kind) &&
             StringComparer.Ordinal.Equals(
                 CompletenessContract,
                 other.CompletenessContract) &&
             StringComparer.Ordinal.Equals(
                 PayloadSchemaKey,
                 other.PayloadSchemaKey) &&
             StringComparer.Ordinal.Equals(
                 PayloadSchemaVersion,
                 other.PayloadSchemaVersion) &&
             _acceptedConsistencyClasses.SequenceEqual(
                 other._acceptedConsistencyClasses)));

    public override bool Equals(object? obj) =>
        obj is EvidenceRequirement other && Equals(other);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Key, StringComparer.Ordinal);
        hash.Add(Surface);
        hash.Add(Kind, StringComparer.Ordinal);
        hash.Add(CompletenessContract, StringComparer.Ordinal);
        hash.Add(PayloadSchemaKey, StringComparer.Ordinal);
        hash.Add(PayloadSchemaVersion, StringComparer.Ordinal);
        foreach (var consistencyClass in _acceptedConsistencyClasses)
        {
            hash.Add(consistencyClass);
        }

        return hash.ToHashCode();
    }
}
