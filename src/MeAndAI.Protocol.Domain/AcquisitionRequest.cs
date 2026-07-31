namespace MeAndAI.Protocol.Domain;

public sealed class AcquisitionRequest : IEquatable<AcquisitionRequest>
{
    private readonly IReadOnlyList<EvidenceRequirement> _requestedRequirements;

    private AcquisitionRequest(
        AcquisitionTarget target,
        string adapterKey,
        string adapterContractVersion,
        string sourceContractKey,
        string sourceContractVersion,
        IReadOnlyList<EvidenceRequirement> requestedRequirements)
    {
        Target = target;
        AdapterKey = adapterKey;
        AdapterContractVersion = adapterContractVersion;
        SourceContractKey = sourceContractKey;
        SourceContractVersion = sourceContractVersion;
        _requestedRequirements = requestedRequirements;
    }

    public AcquisitionTarget Target { get; }

    public string AdapterKey { get; }

    public string AdapterContractVersion { get; }

    public string SourceContractKey { get; }

    public string SourceContractVersion { get; }

    public IReadOnlyList<EvidenceRequirement> RequestedRequirements =>
        _requestedRequirements;

    public static AcquisitionRequest Create(
        AcquisitionTarget target,
        string adapterKey,
        string adapterContractVersion,
        string sourceContractKey,
        string sourceContractVersion,
        IEnumerable<EvidenceRequirement> requestedRequirements)
    {
        ArgumentNullException.ThrowIfNull(target);
        var validatedAdapterKey = EvidenceContractValidation.OpenToken(
            adapterKey,
            nameof(adapterKey));
        var validatedAdapterContractVersion =
            EvidenceContractValidation.Version(
                adapterContractVersion,
                nameof(adapterContractVersion));
        var validatedSourceContractKey = EvidenceContractValidation.OpenToken(
            sourceContractKey,
            nameof(sourceContractKey));
        var validatedSourceContractVersion =
            EvidenceContractValidation.Version(
                sourceContractVersion,
                nameof(sourceContractVersion));
        var materialized = EvidenceContractValidation.Materialize(
            requestedRequirements,
            nameof(requestedRequirements));
        EvidenceContractValidation.NoNullElements(
            materialized,
            nameof(requestedRequirements));

        if (materialized.Length == 0)
        {
            throw new ArgumentException(
                "At least one evidence requirement is required.",
                nameof(requestedRequirements));
        }

        var keys = new HashSet<string>(StringComparer.Ordinal);
        foreach (var requirement in materialized)
        {
            if (!requirement.Surface.Equals(target.Surface))
            {
                throw new ArgumentException(
                    "Every requirement surface must match the target surface.",
                    nameof(requestedRequirements));
            }

            if (!keys.Add(requirement.Key))
            {
                throw new ArgumentException(
                    "Requirement keys must be unique.",
                    nameof(requestedRequirements));
            }
        }

        Array.Sort(materialized, CompareRequirements);

        return new AcquisitionRequest(
            target,
            validatedAdapterKey,
            validatedAdapterContractVersion,
            validatedSourceContractKey,
            validatedSourceContractVersion,
            EvidenceContractValidation.ReadOnly(materialized));
    }

    public bool Equals(AcquisitionRequest? other) =>
        other is not null &&
        (ReferenceEquals(this, other) ||
            (Target.Equals(other.Target) &&
             StringComparer.Ordinal.Equals(AdapterKey, other.AdapterKey) &&
             StringComparer.Ordinal.Equals(
                 AdapterContractVersion,
                 other.AdapterContractVersion) &&
             StringComparer.Ordinal.Equals(
                 SourceContractKey,
                 other.SourceContractKey) &&
             StringComparer.Ordinal.Equals(
                 SourceContractVersion,
                 other.SourceContractVersion) &&
             _requestedRequirements.SequenceEqual(
                 other._requestedRequirements)));

    public override bool Equals(object? obj) =>
        obj is AcquisitionRequest other && Equals(other);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Target);
        hash.Add(AdapterKey, StringComparer.Ordinal);
        hash.Add(AdapterContractVersion, StringComparer.Ordinal);
        hash.Add(SourceContractKey, StringComparer.Ordinal);
        hash.Add(SourceContractVersion, StringComparer.Ordinal);
        foreach (var requirement in _requestedRequirements)
        {
            hash.Add(requirement);
        }

        return hash.ToHashCode();
    }

    private static int CompareRequirements(
        EvidenceRequirement left,
        EvidenceRequirement right)
    {
        var comparison = StringComparer.Ordinal.Compare(left.Key, right.Key);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Surface.Value,
            right.Surface.Value);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(left.Kind, right.Kind);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.CompletenessContract,
            right.CompletenessContract);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.PayloadSchemaKey,
            right.PayloadSchemaKey);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.PayloadSchemaVersion,
            right.PayloadSchemaVersion);
        if (comparison != 0)
        {
            return comparison;
        }

        return CompareConsistencyClasses(
            left.AcceptedConsistencyClasses,
            right.AcceptedConsistencyClasses);
    }

    private static int CompareConsistencyClasses(
        IReadOnlyList<EvidenceConsistencyClass> left,
        IReadOnlyList<EvidenceConsistencyClass> right)
    {
        var sharedLength = Math.Min(left.Count, right.Count);
        for (var index = 0; index < sharedLength; index++)
        {
            var comparison = StringComparer.Ordinal.Compare(
                left[index].Value,
                right[index].Value);
            if (comparison != 0)
            {
                return comparison;
            }
        }

        return left.Count.CompareTo(right.Count);
    }
}
