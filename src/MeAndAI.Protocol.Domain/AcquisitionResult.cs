namespace MeAndAI.Protocol.Domain;

public abstract class AcquisitionResult : IEquatable<AcquisitionResult>
{
    private protected AcquisitionResult(
        AcquisitionRequest request,
        AcquisitionStatus status)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(status);

        Request = request;
        Status = status;
    }

    public AcquisitionRequest Request { get; }

    public AcquisitionStatus Status { get; }

    public bool Equals(AcquisitionResult? other)
    {
        if (ReferenceEquals(this, other))
        {
            return true;
        }

        if (other is null ||
            GetType() != other.GetType() ||
            !Request.Equals(other.Request) ||
            !Status.Equals(other.Status))
        {
            return false;
        }

        return (this, other) switch
        {
            (ObservedAcquisitionResult left,
                ObservedAcquisitionResult right) =>
                left.Context.Equals(right.Context),
            (AbsentAcquisitionResult, AbsentAcquisitionResult) => true,
            (FailedAcquisitionResult left, FailedAcquisitionResult right) =>
                left.StartedAtUtc.Equals(right.StartedAtUtc) &&
                left.FailedAtUtc.Equals(right.FailedAtUtc) &&
                left.Failures.SequenceEqual(right.Failures),
            _ => false,
        };
    }

    public sealed override bool Equals(object? obj) =>
        Equals(obj as AcquisitionResult);

    public sealed override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(GetType());
        hash.Add(Request);
        hash.Add(Status);

        switch (this)
        {
            case ObservedAcquisitionResult observed:
                hash.Add(observed.Context);
                break;
            case FailedAcquisitionResult failed:
                hash.Add(failed.StartedAtUtc);
                hash.Add(failed.FailedAtUtc);
                foreach (var failure in failed.Failures)
                {
                    hash.Add(failure);
                }

                break;
        }

        return hash.ToHashCode();
    }
}
