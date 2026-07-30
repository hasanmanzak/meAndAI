namespace MeAndAI.Protocol.Domain;

public sealed class FailedAcquisitionResult : AcquisitionResult
{
    private readonly IReadOnlyList<AcquisitionFailure> _failures;

    private FailedAcquisitionResult(
        AcquisitionRequest request,
        DateTimeOffset startedAtUtc,
        DateTimeOffset failedAtUtc,
        AcquisitionFailure[] failures)
        : base(request, AcquisitionStatus.Failed)
    {
        StartedAtUtc = startedAtUtc;
        FailedAtUtc = failedAtUtc;
        _failures = EvidenceContractValidation.ReadOnly(failures);
    }

    public DateTimeOffset StartedAtUtc { get; }

    public DateTimeOffset FailedAtUtc { get; }

    public IReadOnlyList<AcquisitionFailure> Failures => _failures;

    public static FailedAcquisitionResult Create(
        AcquisitionRequest request,
        DateTimeOffset startedAtUtc,
        DateTimeOffset failedAtUtc,
        IEnumerable<AcquisitionFailure> failures)
    {
        ArgumentNullException.ThrowIfNull(request);
        EvidenceContractValidation.OrderedInterval(
            startedAtUtc,
            nameof(startedAtUtc),
            failedAtUtc,
            nameof(failedAtUtc));

        var materialized = EvidenceContractValidation.Materialize(
            failures,
            nameof(failures));
        EvidenceContractValidation.NoNullElements(
            materialized,
            nameof(failures));

        if (materialized.Length == 0)
        {
            throw new ArgumentException(
                "A failed result requires acquisition failures.",
                nameof(failures));
        }

        var requestedKeys = request.RequestedRequirements
            .Select(requirement => requirement.Key)
            .ToHashSet(StringComparer.Ordinal);
        var coveredKeys = new HashSet<string>(StringComparer.Ordinal);
        var failurePairs = new HashSet<(string RequirementKey, string Code)>();

        foreach (var failure in materialized)
        {
            if (!requestedKeys.Contains(failure.RequirementKey))
            {
                throw new ArgumentException(
                    "Every failure must belong to a requested requirement.",
                    nameof(failures));
            }

            if (!failurePairs.Add((failure.RequirementKey, failure.Code)))
            {
                throw new ArgumentException(
                    "Duplicate acquisition failures are not allowed.",
                    nameof(failures));
            }

            coveredKeys.Add(failure.RequirementKey);
        }

        if (!requestedKeys.SetEquals(coveredKeys))
        {
            throw new ArgumentException(
                "Failures must cover every requested requirement.",
                nameof(failures));
        }

        Array.Sort(materialized, CompareFailures);

        return new FailedAcquisitionResult(
            request,
            startedAtUtc,
            failedAtUtc,
            materialized);
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
