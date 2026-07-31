namespace MeAndAI.Protocol.Domain;

public sealed class RequirementAcquisition :
    IEquatable<RequirementAcquisition>
{
    private readonly IReadOnlyList<AcquisitionFailure> _failures;

    private RequirementAcquisition(
        EvidenceRequirement requirement,
        EvidenceConsistencyClass consistencyClass,
        EvidenceRedaction redaction,
        AcquisitionFailure[] failures,
        AcquisitionStatus status)
    {
        Requirement = requirement;
        ConsistencyClass = consistencyClass;
        Redaction = redaction;
        _failures = EvidenceContractValidation.ReadOnly(failures);
        Status = status;
    }

    public EvidenceRequirement Requirement { get; }

    public EvidenceConsistencyClass ConsistencyClass { get; }

    public EvidenceRedaction Redaction { get; }

    public IReadOnlyList<AcquisitionFailure> Failures => _failures;

    public AcquisitionStatus Status { get; }

    public static RequirementAcquisition Create(
        EvidenceRequirement requirement,
        EvidenceConsistencyClass consistencyClass,
        EvidenceRedaction redaction,
        IEnumerable<AcquisitionFailure> failures)
    {
        ArgumentNullException.ThrowIfNull(requirement);
        ArgumentNullException.ThrowIfNull(consistencyClass);
        ArgumentNullException.ThrowIfNull(redaction);

        var materialized = EvidenceContractValidation.Materialize(
            failures,
            nameof(failures));
        EvidenceContractValidation.NoNullElements(
            materialized,
            nameof(failures));

        var failurePairs = new HashSet<(string RequirementKey, string Code)>();
        foreach (var failure in materialized)
        {
            if (!StringComparer.Ordinal.Equals(
                    failure.RequirementKey,
                    requirement.Key))
            {
                throw new ArgumentException(
                    "Every failure must belong to the owning requirement.",
                    nameof(failures));
            }

            if (!failurePairs.Add((failure.RequirementKey, failure.Code)))
            {
                throw new ArgumentException(
                    "Duplicate acquisition failures are not allowed.",
                    nameof(failures));
            }
        }

        Array.Sort(materialized, CompareFailures);

        var isAcceptedConsistency =
            !consistencyClass.Equals(
                EvidenceConsistencyClass.InsufficientConsistency) &&
            requirement.AcceptedConsistencyClasses.Contains(consistencyClass);
        var status = isAcceptedConsistency &&
            !redaction.RequiredValuesOmitted &&
            materialized.Length == 0
                ? AcquisitionStatus.Complete
                : AcquisitionStatus.Incomplete;

        return new RequirementAcquisition(
            requirement,
            consistencyClass,
            redaction,
            materialized,
            status);
    }

    public bool Equals(RequirementAcquisition? other) =>
        other is not null &&
        Requirement.Equals(other.Requirement) &&
        ConsistencyClass.Equals(other.ConsistencyClass) &&
        Redaction.Equals(other.Redaction) &&
        _failures.SequenceEqual(other._failures) &&
        Status.Equals(other.Status);

    public override bool Equals(object? obj) =>
        Equals(obj as RequirementAcquisition);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Requirement);
        hash.Add(ConsistencyClass);
        hash.Add(Redaction);
        foreach (var failure in _failures)
        {
            hash.Add(failure);
        }

        hash.Add(Status);
        return hash.ToHashCode();
    }

    private static int CompareFailures(
        AcquisitionFailure left,
        AcquisitionFailure right)
    {
        var comparison = StringComparer.Ordinal.Compare(
            left.RequirementKey,
            right.RequirementKey);
        return comparison != 0
            ? comparison
            : StringComparer.Ordinal.Compare(left.Code, right.Code);
    }
}
